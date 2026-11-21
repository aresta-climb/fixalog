// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'media_compressor_service_fake.dart';

void main() {
  group('MediaCompressorServiceFake', () {
    late Directory tempDir;
    late SessionBundleManager sessionManager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('media_compressor_fake_test_');
      sessionManager = SessionBundleManager(
        baseDirectoryGetter: () async => tempDir,
      );
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('deve gerar imagem WebP determinística na sessão quando não estiver configurada para falhar', () async {
      final fake = MediaCompressorServiceFake(diretorioSaida: tempDir);

      final arquivo = await fake.comprimirImagemSessao(
        sessionManager: sessionManager,
        sessionId: 'sessao_1',
        mediaUuid: 'foto_1',
      );

      expect(arquivo, isNotNull);
      expect(arquivo!.existsSync(), isTrue);
      expect(arquivo.readAsBytesSync(), isNotEmpty);
      expect(fake.fotosSolicitadas, equals(['foto_1']));
    });

    test('deve retornar nulo ao comprimir imagem quando configurado para falhar', () async {
      final fake = MediaCompressorServiceFake(
        diretorioSaida: tempDir,
        falharCompressaoImagem: true,
      );

      final arquivo = await fake.comprimirImagemSessao(
        sessionManager: sessionManager,
        sessionId: 'sessao_1',
        mediaUuid: 'foto_erro',
      );

      expect(arquivo, isNull);
    });

    test('deve gerar vídeo MP4 e poster JPEG determinísticos quando não falhar', () async {
      final fake = MediaCompressorServiceFake(diretorioSaida: tempDir);

      final resultado = await fake.transcodificarVideoSessao(
        sessionManager: sessionManager,
        sessionId: 'sessao_1',
        mediaUuid: 'video_1',
      );

      expect(resultado.video, isNotNull);
      expect(resultado.poster, isNotNull);
      expect(resultado.video!.existsSync(), isTrue);
      expect(resultado.poster!.existsSync(), isTrue);
      expect(fake.videosSolicitados, equals(['video_1']));
    });

    test('deve retornar vídeo e poster nulos quando transcodificação estiver configurada para falhar', () async {
      final fake = MediaCompressorServiceFake(
        diretorioSaida: tempDir,
        falharTranscodificacaoVideo: true,
      );

      final resultado = await fake.transcodificarVideoSessao(
        sessionManager: sessionManager,
        sessionId: 'sessao_1',
        mediaUuid: 'video_erro',
      );

      expect(resultado.video, isNull);
      expect(resultado.poster, isNull);
    });

    test('deve gerar páginas WebP determinísticas ao rasterizar documento PDF', () async {
      final fake = MediaCompressorServiceFake(
        diretorioSaida: tempDir,
        quantidadePaginasPdfPadrao: 2,
      );

      final paginas = await fake.rasterizarDocumentoPdfSessao(
        sessionManager: sessionManager,
        sessionId: 'sessao_1',
        mediaUuid: 'doc_1',
      );

      expect(paginas, hasLength(2));
      expect(paginas.every((f) => f.existsSync()), isTrue);
      expect(fake.documentosSolicitados, equals(['doc_1']));
    });
  });
}
