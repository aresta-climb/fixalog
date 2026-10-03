// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:ffmpeg_kit_flutter_platform_interface/ffmpeg_kit_flutter_platform_interface.dart';
import 'package:fixalog/features/media/services/video_transcoder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File videoOriginal;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('video_transcoder_test_');
    videoOriginal = File('${tempDir.path}/video_original.mp4');
    await videoOriginal.writeAsBytes([0, 1, 2, 3]);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('VideoTranscoderService - Testes Unitários', () {
    test('transcodificarVideo gera comando otimizado para H.264 720p CRF 26 mono 64k faststart', () async {
      String? comandoExecutado;
      final service = VideoTranscoderService(
        executador: (cmd) async {
          comandoExecutado = cmd;
          return true;
        },
      );

      final outputPath = '${tempDir.path}/video_comprimido.mp4';
      final resultado = await service.transcodificarVideo(
        arquivoEntrada: videoOriginal,
        caminhoSaida: outputPath,
      );

      expect(resultado, isNotNull);
      expect(resultado!.path, equals(outputPath));
      expect(comandoExecutado, isNotNull);
      expect(comandoExecutado, contains('-i "${videoOriginal.path}"'));
      expect(comandoExecutado, contains('scale=-2:720'));
      expect(comandoExecutado, contains('-c:v libx264'));
      expect(comandoExecutado, contains('-crf 26'));
      expect(comandoExecutado, contains('-preset fast'));
      expect(comandoExecutado, contains('-c:a aac'));
      expect(comandoExecutado, contains('-ac 1'));
      expect(comandoExecutado, contains('-b:a 64k'));
      expect(comandoExecutado, contains('-movflags +faststart'));
      expect(comandoExecutado, contains('-y "$outputPath"'));
    });

    test('transcodificarVideo retorna null quando o comando falha', () async {
      final service = VideoTranscoderService(
        executador: (cmd) async => false,
      );

      final outputPath = '${tempDir.path}/video_falha.mp4';
      final resultado = await service.transcodificarVideo(
        arquivoEntrada: videoOriginal,
        caminhoSaida: outputPath,
      );

      expect(resultado, isNull);
    });

    test('transcodificarVideo retorna null quando o arquivo de entrada não existe', () async {
      final service = VideoTranscoderService(
        executador: (cmd) async => true,
      );

      final arquivoInexistente = File('${tempDir.path}/inexistente.mp4');
      final outputPath = '${tempDir.path}/saida.mp4';
      final resultado = await service.transcodificarVideo(
        arquivoEntrada: arquivoInexistente,
        caminhoSaida: outputPath,
      );

      expect(resultado, isNull);
    });

    test('extrairPosterFrame gera comando FFmpeg correto no segundo 0.5', () async {
      String? comandoExecutado;
      final service = VideoTranscoderService(
        executador: (cmd) async {
          comandoExecutado = cmd;
          return true;
        },
      );

      final posterPath = '${tempDir.path}/poster.webp';
      final resultado = await service.extrairPosterFrame(
        arquivoEntrada: videoOriginal,
        caminhoSaida: posterPath,
      );

      expect(resultado, isNotNull);
      expect(resultado!.path, equals(posterPath));
      expect(comandoExecutado, isNotNull);
      expect(comandoExecutado, contains('-ss 0.5'));
      expect(comandoExecutado, contains('-i "${videoOriginal.path}"'));
      expect(comandoExecutado, contains('-vframes 1'));
      expect(comandoExecutado, contains('-y "$posterPath"'));
    });

    test('extrairPosterFrame aceita tempo customizado em segundos', () async {
      String? comandoExecutado;
      final service = VideoTranscoderService(
        executador: (cmd) async {
          comandoExecutado = cmd;
          return true;
        },
      );

      final posterPath = '${tempDir.path}/poster_custom.webp';
      final resultado = await service.extrairPosterFrame(
        arquivoEntrada: videoOriginal,
        caminhoSaida: posterPath,
        tempoSegundos: 2.5,
      );

      expect(resultado, isNotNull);
      expect(comandoExecutado, contains('-ss 2.5'));
    });

    test('extrairPosterFrame retorna null quando o arquivo de entrada não existe', () async {
      final service = VideoTranscoderService(
        executador: (cmd) async => true,
      );

      final arquivoInexistente = File('${tempDir.path}/inexistente.mp4');
      final posterPath = '${tempDir.path}/poster.webp';
      final resultado = await service.extrairPosterFrame(
        arquivoEntrada: arquivoInexistente,
        caminhoSaida: posterPath,
      );

      expect(resultado, isNull);
    });

    test('extrairPosterFrame retorna null quando o comando falha', () async {
      final service = VideoTranscoderService(
        executador: (cmd) async => false,
      );

      final posterPath = '${tempDir.path}/poster_falha.webp';
      final resultado = await service.extrairPosterFrame(
        arquivoEntrada: videoOriginal,
        caminhoSaida: posterPath,
      );

      expect(resultado, isNull);
    });

    test('VideoTranscoderService pode ser instanciado sem executador customizado', () {
      final service = VideoTranscoderService();
      expect(service, isNotNull);
    });

    test('videoTranscoderServiceProvider provê instância válida de VideoTranscoderService', () {
      final container = ProviderContainer();
      final service = container.read(videoTranscoderServiceProvider);
      expect(service, isA<VideoTranscoderService>());
    });

    test('executarFfmpeg utiliza FFmpegKit através da plataforma mockada', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.arthenica.com/ffmpeg_kit_event'),
        (MethodCall call) async => null,
      );

      FFmpegKitPlatform.instance = FakeFFmpegKitPlatform();

      final sucesso = await VideoTranscoderService.executarFfmpeg('-version');
      expect(sucesso, isTrue);
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
