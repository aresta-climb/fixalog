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
    test('transcodificarVideo gera comando otimizado com -g 300 para I-Frames a cada 10s', () async {
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
      expect(comandoExecutado, contains('-preset veryfast'));
      expect(comandoExecutado, contains('-g 300'));
      expect(comandoExecutado, contains('-c:a aac'));
      expect(comandoExecutado, contains('-ac 1'));
      expect(comandoExecutado, contains('-b:a 64k'));
      expect(comandoExecutado, contains('-movflags +faststart'));
      expect(comandoExecutado, contains('-y "$outputPath"'));
    });

    test('transcodificarVideo aplica -ss e -t quando inicioSegundos e duracaoSegundos sao informados', () async {
      String? comandoExecutado;
      final service = VideoTranscoderService(
        executador: (cmd) async {
          comandoExecutado = cmd;
          return true;
        },
      );

      final outputPath = '${tempDir.path}/video_cortado.mp4';
      final resultado = await service.transcodificarVideo(
        arquivoEntrada: videoOriginal,
        caminhoSaida: outputPath,
        inicioSegundos: 15.0,
        duracaoSegundos: 60.0,
      );

      expect(resultado, isNotNull);
      expect(comandoExecutado, startsWith('-ss 15.0 -t 60.0 -i '));
      expect(comandoExecutado, contains('-g 300'));
    });

    test('obterDuracaoSegundos retorna duracao do inspetor ou null quando arquivo nao existe', () async {
      final service = VideoTranscoderService(
        inspetorDuracao: (_) async => 82.5,
      );

      expect(await service.obterDuracaoSegundos(videoOriginal), equals(82.5));
      expect(
        await service.obterDuracaoSegundos(File('${tempDir.path}/inexistente.mp4')),
        isNull,
      );
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

      final posterPath = '${tempDir.path}/poster.jpg';
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

      final posterPath = '${tempDir.path}/poster_custom.jpg';
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

    test('executarFfmpeg e inspecionarDuracaoPadrao utilizam FFmpegKit/FFprobeKit através da plataforma', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.arthenica.com/ffmpeg_kit_event'),
        (MethodCall call) async => null,
      );

      final fakePlatform = FakeFFmpegKitPlatform(duracaoSimulada: '75.4');
      FFmpegKitPlatform.instance = fakePlatform;

      final sucesso = await VideoTranscoderService.executarFfmpeg('-version');
      expect(sucesso, isTrue);

      final duracao = await VideoTranscoderService.inspecionarDuracaoPadrao(videoOriginal);
      expect(duracao, equals(75.4));

      fakePlatform.duracaoSimulada = null;
      final duracaoNula = await VideoTranscoderService.inspecionarDuracaoPadrao(videoOriginal);
      expect(duracaoNula, isNull);
    });
  });
}

class FakeFFmpegKitPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FFmpegKitPlatform {
  String? duracaoSimulada;

  FakeFFmpegKitPlatform({this.duracaoSimulada});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.contains('ffmpegKitConfigGetSession') ||
        name.contains('createMediaInformationSession')) {
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
    if (name.contains('mediaInformationSessionGetMediaInformation')) {
      if (duracaoSimulada == null) return Future.value(null);
      return Future.value({
        'format': {'duration': duracaoSimulada},
      });
    }
    if (name.contains('mediaInformationJsonParserFrom')) {
      if (duracaoSimulada == null) return Future.value(null);
      return Future.value({
        'format': {'duration': duracaoSimulada},
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
