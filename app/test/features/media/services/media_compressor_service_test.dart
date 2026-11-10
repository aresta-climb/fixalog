// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_image_compress_platform_interface/flutter_image_compress_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:printing/printing.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/features/media/services/media_compressor_service.dart';
import 'package:fixalog/features/media/services/video_transcoder_service.dart';
import 'package:ffmpeg_kit_flutter_platform_interface/ffmpeg_kit_flutter_platform_interface.dart';

class FakeFlutterImageCompressPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FlutterImageCompressPlatform {
  bool shouldFail = false;
  bool shouldThrow = false;
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

    if (shouldThrow) throw Exception('Falha simulada nativa');
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

    test('compressThumbnail comprime para JPEG qualidade 80 e 2MP (1440x1440)', () async {
      final imgOriginal = File('${tempDir.path}/foto.webp');
      await imgOriginal.writeAsBytes([10, 20, 30]);

      final outPath = '${tempDir.path}/foto_thumb.jpg';
      final resultado = await service.compressThumbnail(imgOriginal, outPath);

      expect(resultado, isNotNull);
      expect(resultado!.path, equals(outPath));
      expect(fakeImageCompress.lastFormat, equals(CompressFormat.jpeg));
      expect(fakeImageCompress.lastQuality, equals(80));
      expect(fakeImageCompress.lastMinWidth, equals(1440));
      expect(fakeImageCompress.lastMinHeight, equals(1440));
    });

    test('compressThumbnail retorna null quando arquivo de entrada não existe', () async {
      final imgInexistente = File('${tempDir.path}/inexistente.jpg');
      final outPath = '${tempDir.path}/foto_thumb.webp';

      final resultado = await service.compressThumbnail(imgInexistente, outPath);
      expect(resultado, isNull);
    });

    test('compressThumbnail retorna null quando compressAndGetFile falha', () async {
      fakeImageCompress.shouldFail = true;
      final imgOriginal = File('${tempDir.path}/foto.jpg');
      await imgOriginal.writeAsBytes([10, 20, 30]);

      final outPath = '${tempDir.path}/foto_thumb.webp';
      final resultado = await service.compressThumbnail(imgOriginal, outPath);
      expect(resultado, isNull);
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

    test('comprimirImagemSessao preserva arquivo original intacto e gera webp 4MP e miniatura _thumb.jpg 2MP sem gerar _thumb.webp', () async {
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

      // Miniatura de impressão deve ser gerada em _thumb.jpg (2MP JPEG)
      final thumbJpgPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '${mediaUuid}_thumb',
        extension: '.jpg',
      );
      expect(await File(thumbJpgPath).exists(), isTrue);

      // E não deve gerar o legado _thumb.webp
      final thumbWebpPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '${mediaUuid}_thumb',
        extension: '.webp',
      );
      expect(await File(thumbWebpPath).exists(), isFalse);
    });

    test('comprimirFotoSessao delega para comprimirImagemSessao gerando imagem e miniatura _thumb.jpg', () async {
      const sessionId = 'sessao-alias';
      const mediaUuid = 'foto-alias-uuid';

      await sessionManager.saveOriginalMedia(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.jpg',
        bytes: Uint8List.fromList([10, 20, 30]),
      );

      final resultado = await service.comprimirFotoSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );

      expect(resultado, isNotNull);
      expect(resultado!.path, endsWith('$mediaUuid.webp'));

      final thumbPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '${mediaUuid}_thumb',
        extension: '.jpg',
      );
      expect(await File(thumbPath).exists(), isTrue);
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

    test('transcodificarVideoSessao preserva vídeo original e extrai poster frame em .jpg', () async {
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
      expect(resultado.poster!.path, endsWith('${mediaUuid}_poster.jpg'));
      // Arquivo original intacto
      expect(await originalFile.exists(), isTrue);
    });

    test('transcodificarVideoSessao le metadado _corte.json quando presente e aplica -ss e -t', () async {
      const sessionId = 'sessao-video-corte';
      const mediaUuid = 'video-longo-uuid';

      await sessionManager.saveOriginalMedia(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.mp4',
        bytes: Uint8List.fromList([5, 6, 7, 8]),
      );

      final cortePath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '${mediaUuid}_corte',
        extension: '.json',
      );
      await File(cortePath).writeAsString('{"inicio": 12.0, "duracao": 60.0}');

      final resultado = await service.transcodificarVideoSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );

      expect(resultado.video, isNotNull);
      expect(
        comandosExecutados.any((cmd) => cmd.contains('-ss 12.0 -t 60.0')),
        isTrue,
      );
      expect(
        comandosExecutados.any((cmd) => cmd.contains('-ss 12.5')),
        isTrue,
      );
      expect(
        comandosExecutados.any((cmd) => cmd.contains('_kf_10s.jpg')),
        isTrue,
      );
      expect(
        comandosExecutados.any((cmd) => cmd.contains('_kf_60s.jpg')),
        isTrue,
      );
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

    test('rasterizarDocumentoPdfSessao gera um arquivo WebP para PDF de 1 página preservando o PDF original', () async {
      const sessionId = 'sessao-pdf-1';
      const mediaUuid = 'doc-1p-uuid';

      final servicoComPdf = MediaCompressorService(
        rasterizadorPdf: (pdfBytes, {double dpi = 150.0}) async {
          return [
            Uint8List.fromList([137, 80, 78, 71, 1]),
          ];
        },
      );

      final pdfOriginal = await sessionManager.saveOriginalMedia(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.pdf',
        bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]),
      );

      final paginas = await servicoComPdf.rasterizarDocumentoPdfSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );

      expect(paginas.length, equals(1));
      expect(paginas[0].path, endsWith('${mediaUuid}_p1.webp'));
      expect(await paginas[0].exists(), isTrue);
      expect(await pdfOriginal.exists(), isTrue);
    });

    test('rasterizarDocumentoPdfSessao gera arquivos WebP numerados para PDF de múltiplas páginas', () async {
      const sessionId = 'sessao-pdf-multi';
      const mediaUuid = 'doc-3p-uuid';

      final servicoComPdf = MediaCompressorService(
        rasterizadorPdf: (pdfBytes, {double dpi = 150.0}) async {
          return [
            Uint8List.fromList([137, 80, 78, 71, 1]),
            Uint8List.fromList([137, 80, 78, 71, 2]),
            Uint8List.fromList([137, 80, 78, 71, 3]),
          ];
        },
      );

      await sessionManager.saveOriginalMedia(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.pdf',
        bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]),
      );

      final paginas = await servicoComPdf.rasterizarDocumentoPdfSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );

      expect(paginas.length, equals(3));
      expect(paginas[0].path, endsWith('${mediaUuid}_p1.webp'));
      expect(paginas[1].path, endsWith('${mediaUuid}_p2.webp'));
      expect(paginas[2].path, endsWith('${mediaUuid}_p3.webp'));
      for (final p in paginas) {
        expect(await p.exists(), isTrue);
      }
    });

    test('rasterizarDocumentoPdfSessao retorna lista vazia se arquivo PDF original não existir', () async {
      final paginas = await service.rasterizarDocumentoPdfSessao(
        sessionManager: sessionManager,
        sessionId: 'sessao-inexistente',
        mediaUuid: 'pdf-inexistente',
      );

      expect(paginas, isEmpty);
    });

    test('comprimirImagemSessao reutiliza arquivos .webp e _thumb.jpg já prontos sem recomprimir e ignora arquivos .tmp incompletos', () async {
      const sessionId = 'sessao-cache';
      const mediaUuid = 'foto-cache';

      await sessionManager.saveOriginalMedia(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      // Cria um arquivo .tmp órfão para simular interrupção anterior
      final tmpOrfaoPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '$mediaUuid.tmp',
        extension: '.webp',
      );
      File(tmpOrfaoPath).writeAsBytesSync([99]);

      // 1ª execução gera os artefatos finais
      final res1 = await service.comprimirImagemSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );
      expect(res1, isNotNull);
      expect(File(tmpOrfaoPath).existsSync(), isFalse);

      // Se a compressão fosse chamada de novo, falharia porque ligamos shouldFail = true
      fakeImageCompress.shouldFail = true;

      // 2ª execução deve reutilizar o que já está pronto em disco!
      final res2 = await service.comprimirImagemSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );
      expect(res2, isNotNull);
      expect(res2!.path, equals(res1!.path));
    });

    test('rasterizarDocumentoPdfSessao reaproveita páginas <uuid>_p<N>_original.jpg já extraídas sem re-executar rasterizadorPdf', () async {
      const sessionId = 'sessao-pdf-ja-extraido';
      const mediaUuid = 'doc-rapido';

      var rasterizadorChamado = false;
      final servicoComPdf = MediaCompressorService(
        rasterizadorPdf: (pdfBytes, {double dpi = 150.0}) async {
          rasterizadorChamado = true;
          return [Uint8List.fromList([1, 2, 3])];
        },
      );

      await sessionManager.saveOriginalMedia(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.pdf',
        bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
      );

      // Páginas já extraídas pelo SeletorDocumentoService no momento do anexo
      await sessionManager.saveOriginalMedia(
        sessionId: sessionId,
        mediaUuid: '${mediaUuid}_p1',
        extension: '.jpg',
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
      );
      await sessionManager.saveOriginalMedia(
        sessionId: sessionId,
        mediaUuid: '${mediaUuid}_p2',
        extension: '.jpg',
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
      );

      final paginas = await servicoComPdf.rasterizarDocumentoPdfSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );

      expect(rasterizadorChamado, isFalse);
      expect(paginas.length, equals(2));
      expect(paginas[0].path, endsWith('${mediaUuid}_p1.webp'));
      expect(paginas[1].path, endsWith('${mediaUuid}_p2.webp'));

      final thumb1 = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '${mediaUuid}_p1_thumb',
        extension: '.jpg',
      );
      expect(File(thumb1).existsSync(), isTrue);

      // 2ª chamada sem páginas _original.jpg reaproveita <uuid>_p<N>.webp já prontos em disco (e regera thumb se ausente)
      File(
        await sessionManager.getMediaFilePath(
          sessionId: sessionId,
          mediaUuid: '${mediaUuid}_p1_original',
          extension: '.jpg',
        ),
      ).deleteSync();
      File(
        await sessionManager.getMediaFilePath(
          sessionId: sessionId,
          mediaUuid: '${mediaUuid}_p2_original',
          extension: '.jpg',
        ),
      ).deleteSync();
      File(thumb1).deleteSync();

      final paginasCacheWebp = await servicoComPdf.rasterizarDocumentoPdfSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );
      expect(paginasCacheWebp.length, equals(2));
      expect(File(thumb1).existsSync(), isTrue);
    });

    test('filas de concorrencia, sobrescrita atomica, cache de video pronto, fallback PDF e excecoes funcionam com seguranca', () async {
      final imgOriginal = File('${tempDir.path}/foto_over.jpg')
        ..writeAsBytesSync([1, 2, 3]);
      final outImg = '${tempDir.path}/foto_over.webp';
      final outThumb = '${tempDir.path}/foto_over_thumb.jpg';
      File(outImg).writeAsBytesSync([0]);
      File(outThumb).writeAsBytesSync([0]);

      // Sobrescreve destino existente
      expect(await service.compressImage(imgOriginal, outImg), isNotNull);
      expect(await service.compressThumbnail(imgOriginal, outThumb), isNotNull);

      // Trata exceção lançada pelo compressor nativo
      fakeImageCompress.shouldThrow = true;
      expect(await service.compressImage(imgOriginal, outImg), isNull);
      expect(await service.compressThumbnail(imgOriginal, outThumb), isNull);
      fakeImageCompress.shouldThrow = false;

      // Pool de imagens (>2 simultâneas)
      for (int i = 1; i <= 4; i++) {
        await sessionManager.saveOriginalMedia(
          sessionId: 's_pool',
          mediaUuid: 'img_$i',
          extension: '.jpg',
          bytes: Uint8List.fromList([i]),
        );
      }
      final resPool = await Future.wait([
        service.comprimirImagemSessao(
          sessionManager: sessionManager,
          sessionId: 's_pool',
          mediaUuid: 'img_1',
        ),
        service.comprimirImagemSessao(
          sessionManager: sessionManager,
          sessionId: 's_pool',
          mediaUuid: 'img_2',
        ),
        service.comprimirImagemSessao(
          sessionManager: sessionManager,
          sessionId: 's_pool',
          mediaUuid: 'img_3',
        ),
        service.comprimirImagemSessao(
          sessionManager: sessionManager,
          sessionId: 's_pool',
          mediaUuid: 'img_4',
        ),
      ]);
      expect(resPool.whereType<File>().length, equals(4));

      // Fila de vídeos (2 vídeos diferentes em paralelo) + cache de vídeo/poster já existentes em disco
      final transcoderCriador = VideoTranscoderService(
        executador: (cmd) async {
          final m = RegExp(r'"([^"]+\.(?:mp4|jpg))"$').firstMatch(cmd);
          if (m != null) {
            File(m.group(1)!).writeAsBytesSync([1, 2, 3]);
          }
          return true;
        },
      );
      final serviceCriador = MediaCompressorService(
        videoTranscoderService: transcoderCriador,
      );
      await sessionManager.saveOriginalMedia(
        sessionId: 's_vpool',
        mediaUuid: 'v1',
        extension: '.mp4',
        bytes: Uint8List.fromList([1]),
      );
      await sessionManager.saveOriginalMedia(
        sessionId: 's_vpool',
        mediaUuid: 'v2',
        extension: '.mp4',
        bytes: Uint8List.fromList([2]),
      );
      await Future.wait([
        serviceCriador.transcodificarVideoSessao(
          sessionManager: sessionManager,
          sessionId: 's_vpool',
          mediaUuid: 'v1',
        ),
        serviceCriador.transcodificarVideoSessao(
          sessionManager: sessionManager,
          sessionId: 's_vpool',
          mediaUuid: 'v2',
        ),
      ]);
      // 2ª chamada para v1 retorna imediatamente do cache em disco
      final cacheVideo = await serviceCriador.transcodificarVideoSessao(
        sessionManager: sessionManager,
        sessionId: 's_vpool',
        mediaUuid: 'v1',
      );
      expect(cacheVideo.video, isNotNull);
      expect(cacheVideo.poster, isNotNull);

      // Fallback PDF quando compressImage falha e quando rasterizador lança erro
      await sessionManager.saveOriginalMedia(
        sessionId: 's_pdf_fb',
        mediaUuid: 'doc_fb',
        extension: '.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      fakeImageCompress.shouldFail = true;
      final servicoPdfFallback = MediaCompressorService(
        rasterizadorPdf: (bytes, {double dpi = 150.0}) async => [
          Uint8List.fromList([10, 20, 30]),
        ],
      );
      final pagsFb = await servicoPdfFallback.rasterizarDocumentoPdfSessao(
        sessionManager: sessionManager,
        sessionId: 's_pdf_fb',
        mediaUuid: 'doc_fb',
      );
      expect(pagsFb.length, equals(1));
      fakeImageCompress.shouldFail = false;

      final servicoPdfErro = MediaCompressorService(
        rasterizadorPdf: (bytes, {double dpi = 150.0}) async {
          throw Exception('PDF inválido');
        },
      );
      await sessionManager.saveOriginalMedia(
        sessionId: 's_pdf_err',
        mediaUuid: 'doc_err',
        extension: '.pdf',
        bytes: Uint8List.fromList([1]),
      );
      expect(
        await servicoPdfErro.rasterizarDocumentoPdfSessao(
          sessionManager: sessionManager,
          sessionId: 's_pdf_err',
          mediaUuid: 'doc_err',
        ),
        isEmpty,
      );

      final executorOriginal = MediaCompressorService.executorPrintingRaster;
      MediaCompressorService.executorPrintingRaster =
          (pdfBytes, {double dpi = 150.0}) => Stream.fromIterable([
            PdfRaster(1, 1, Uint8List.fromList([255, 0, 0, 255])),
          ]);
      final pngsGerados = await MediaCompressorService.rasterizarPdfPadrao(
        Uint8List.fromList([1, 2, 3]),
      );
      MediaCompressorService.executorPrintingRaster = executorOriginal;
      expect(pngsGerados.length, equals(1));
      expect(pngsGerados.first, isNotEmpty);
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
