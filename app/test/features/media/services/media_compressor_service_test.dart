// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_image_compress_platform_interface/flutter_image_compress_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:fixlog/core/services/session_bundle_manager.dart';
import 'package:fixlog/features/media/services/media_compressor_service.dart';
import 'package:fixlog/features/media/services/video_transcoder_service.dart';
import 'package:ffmpeg_kit_flutter_platform_interface/ffmpeg_kit_flutter_platform_interface.dart';

class FakeFlutterImageCompressPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FlutterImageCompressPlatform {
  bool shouldFail = false;
  CompressFormat? lastFormat;
  int? lastQuality;
  int? lastMinWidth;
  int? lastMinHeight;

  @override
  FlutterImageCompressValidator get validator =>
      FlutterImageCompressValidator(const MethodChannel('flutter_image_compress'));

  @override
  Future<XFile?> compressAndGetFile(
    String path,
    String targetPath, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async {
    lastFormat = format;
    lastQuality = quality;
    lastMinWidth = minWidth;
    lastMinHeight = minHeight;

    if (shouldFail) return null;
    final file = File(targetPath);
    await file.create(recursive: true);
    await file.writeAsBytes([1, 2, 3, 4]);
    return XFile(targetPath);
  }
}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;
  FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FakeFlutterImageCompressPlatform fakeImageCompress;
  late SessionBundleManager sessionManager;
  late MediaCompressorService service;
  late List<String> comandosExecutados;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('media_compressor_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    fakeImageCompress = FakeFlutterImageCompressPlatform();
    FlutterImageCompressPlatform.instance = fakeImageCompress;

    comandosExecutados = [];
    final transcoder = VideoTranscoderService(
      executador: (cmd) async {
        comandosExecutados.add(cmd);
        return !cmd.contains('FAIL');
      },
    );

    sessionManager = SessionBundleManager();
    service = MediaCompressorService(
      videoTranscoderService: transcoder,
      audioExecutador: (cmd) async {
        comandosExecutados.add(cmd);
        return !cmd.contains('FAIL');
      },
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MediaCompressorService Tests', () {
    test('compressImage comprime para WebP qualidade 85 e 4MP (2048x2048)', () async {
      final imgOriginal = File('${tempDir.path}/foto.jpg');
      await imgOriginal.writeAsBytes([10, 20, 30]);

      final outPath = '${tempDir.path}/foto.webp';
      final resultado = await service.compressImage(imgOriginal, outPath);

      expect(resultado, isNotNull);
      expect(resultado!.path, equals(outPath));
      expect(fakeImageCompress.lastFormat, equals(CompressFormat.webp));
      expect(fakeImageCompress.lastQuality, equals(85));
      expect(fakeImageCompress.lastMinWidth, equals(2048));
      expect(fakeImageCompress.lastMinHeight, equals(2048));
    });

    test('compressImage retorna null quando arquivo de entrada não existe', () async {
      final imgInexistente = File('${tempDir.path}/inexistente.jpg');
      final outPath = '${tempDir.path}/foto.webp';

      final resultado = await service.compressImage(imgInexistente, outPath);
      expect(resultado, isNull);
    });

    test('compressImage retorna null quando compressAndGetFile falha', () async {
      fakeImageCompress.shouldFail = true;
      final imgOriginal = File('${tempDir.path}/foto.jpg');
      await imgOriginal.writeAsBytes([10, 20, 30]);

      final outPath = '${tempDir.path}/foto.webp';
      final resultado = await service.compressImage(imgOriginal, outPath);
      expect(resultado, isNull);
    });

    test('compressVideo delega para VideoTranscoderService gerando H.264 720p', () async {
      final videoOriginal = File('${tempDir.path}/video.mp4');
      await videoOriginal.writeAsBytes([1, 2, 3]);

      final outPath = '${tempDir.path}/video_otimizado.mp4';
      final resultado = await service.compressVideo(videoOriginal, outPath);

      expect(resultado, isNotNull);
      expect(resultado!.path, equals(outPath));
      expect(comandosExecutados.any((cmd) => cmd.contains('scale=-2:720')), isTrue);
      expect(comandosExecutados.any((cmd) => cmd.contains('-crf 26')), isTrue);
    });

    test('compressVideo retorna null quando arquivo não existe', () async {
      final videoInexistente = File('${tempDir.path}/inexistente.mp4');
      final outPath = '${tempDir.path}/saida.mp4';

      final resultado = await service.compressVideo(videoInexistente, outPath);
      expect(resultado, isNull);
    });

    test('compressAudio transcodifica áudio para aac/m4a', () async {
      final audioOriginal = File('${tempDir.path}/audio.wav');
      await audioOriginal.writeAsBytes([1, 2, 3]);

      final outPath = '${tempDir.path}/audio.m4a';
      final resultado = await service.compressAudio(audioOriginal, outPath);

      expect(resultado, isNotNull);
      expect(resultado!.path, equals(outPath));
      expect(comandosExecutados.any((cmd) => cmd.contains('-c:a aac -b:a 96k')), isTrue);
    });

    test('compressAudio retorna null quando arquivo de entrada não existe', () async {
      final audioInexistente = File('${tempDir.path}/inexistente.wav');
      final outPath = '${tempDir.path}/audio.m4a';

      final resultado = await service.compressAudio(audioInexistente, outPath);
      expect(resultado, isNull);
    });

    test('compressAudio retorna null quando comando falha', () async {
      final audioOriginal = File('${tempDir.path}/audio.wav');
      await audioOriginal.writeAsBytes([1, 2, 3]);

      final outPath = '${tempDir.path}/audio_FAIL.m4a';
      final resultado = await service.compressAudio(audioOriginal, outPath);
      expect(resultado, isNull);
    });

    test('comprimirImagemSessao preserva arquivo original intacto e gera webp', () async {
      const sessionId = 'sessao-1';
      const mediaUuid = 'foto-uuid';

      // Salva arquivo original via SessionBundleManager
      final originalFile = await sessionManager.saveOriginalMedia(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.jpg',
        bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
      );

      final resultado = await service.comprimirImagemSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );

      expect(resultado, isNotNull);
      expect(resultado!.path, endsWith('$mediaUuid.webp'));
      // Arquivo original continua existindo intacto
      expect(await originalFile.exists(), isTrue);
      expect(await originalFile.readAsBytes(), equals([1, 2, 3, 4, 5]));
    });

    test('comprimirImagemSessao suporta fallback para png se jpg original não existir', () async {
      const sessionId = 'sessao-2';
      const mediaUuid = 'foto-png-uuid';

      final originalFile = await sessionManager.saveOriginalMedia(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.png',
        bytes: Uint8List.fromList([9, 8, 7]),
      );

      final resultado = await service.comprimirImagemSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );

      expect(resultado, isNotNull);
      expect(await originalFile.exists(), isTrue);
    });

    test('comprimirImagemSessao retorna null se nenhum arquivo original existir', () async {
      const sessionId = 'sessao-vazia';
      const mediaUuid = 'foto-inexistente';

      final resultado = await service.comprimirImagemSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );

      expect(resultado, isNull);
    });

    test('transcodificarVideoSessao preserva vídeo original e extrai poster frame', () async {
      const sessionId = 'sessao-video-1';
      const mediaUuid = 'video-uuid';

      final originalFile = await sessionManager.saveOriginalMedia(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.mp4',
        bytes: Uint8List.fromList([5, 6, 7, 8]),
      );

      final resultado = await service.transcodificarVideoSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );

      expect(resultado.video, isNotNull);
      expect(resultado.poster, isNotNull);
      expect(resultado.video!.path, endsWith('$mediaUuid.mp4'));
      expect(resultado.poster!.path, endsWith('${mediaUuid}_poster.webp'));
      // Arquivo original intacto
      expect(await originalFile.exists(), isTrue);
    });

    test('transcodificarVideoSessao retorna nulos se arquivo original não existir', () async {
      const sessionId = 'sessao-video-vazia';
      const mediaUuid = 'video-inexistente';

      final resultado = await service.transcodificarVideoSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );

      expect(resultado.video, isNull);
      expect(resultado.poster, isNull);
    });

    test('mediaCompressorProvider provê instância funcional', () {
      final container = ProviderContainer();
      final inst = container.read(mediaCompressorProvider);
      expect(inst, isA<MediaCompressorService>());
    });

    test('MediaCompressorService com construtor padrão executa compressAudio via VideoTranscoderService.executarFfmpeg', () async {
      final defaultService = MediaCompressorService();
      expect(defaultService, isNotNull);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.arthenica.com/ffmpeg_kit_event'),
        (MethodCall call) async => null,
      );
      FFmpegKitPlatform.instance = FakeFFmpegKitPlatform();

      final audioFile = File('${tempDir.path}/audio_padrao.wav');
      await audioFile.writeAsBytes([1, 2]);

      final outPath = '${tempDir.path}/audio_padrao.m4a';
      final resultado = await defaultService.compressAudio(audioFile, outPath);
      expect(resultado, isNotNull);
    });
  });
}

class FakeFFmpegKitPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FFmpegKitPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.contains('ffmpegKitConfigGetSession')) {
      return Future.value({
        'sessionId': 1,
        'createTime': 0,
        'startTime': 0,
        'endTime': 100,
        'duration': 100,
        'command': '-version',
        'state': 2,
        'returnCode': 0,
      });
    }
    if (name.contains('abstractSessionGetReturnCode')) {
      return Future.value(0);
    }
    if (name.contains('GetLogLevel')) {
      return Future.value(0);
    }
    if (name.contains('GetPlatform') || name.contains('GetArch') || name.contains('getPackageName')) {
      return Future.value('test');
    }
    if (name.contains('IsLTSBuild')) {
      return Future.value(false);
    }
    return Future.value(null);
  }
}
