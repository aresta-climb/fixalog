// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/epub_document_builder.dart';
import 'package:fixalog/core/services/epub_packager_service.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/core/services/xml_dsig_signer.dart';
import 'package:fixalog/features/pdf_generation/providers/generation_provider.dart';
import 'package:fixalog/features/pdf_generation/services/generation_recovery_service.dart';
import '../test/fakes/crypto_service_fake.dart';
import '../test/fakes/media_compressor_service_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo Completo de Geração de Relatório EPUB 3 Assinado', () {
    late Directory tempDir;
    late BancoDadosLocal banco;
    late SessionBundleManager sessionManager;
    late GenerationRecoveryService recoveryService;
    late CryptoServiceFake cryptoService;
    late MediaCompressorServiceFake mediaService;
    late GenerationNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('generation_flow_test_');
      banco = await BancoDadosLocal.abrirEmMemoria();

      sessionManager = SessionBundleManager(
        baseDirectoryGetter: () async => tempDir,
      );
      recoveryService = GenerationRecoveryService(
        tempDirGetter: () async => tempDir,
      );

      cryptoService = CryptoServiceFake();
      await cryptoService.generateAndStoreKeysIfNeeded();
      await cryptoService.generateX509Certificate('Mantenedor Integração');

      mediaService = MediaCompressorServiceFake(diretorioSaida: tempDir);

      notifier = GenerationNotifier(
        mediaService,
        recoveryService,
        sessionManager,
        banco,
        const EpubDocumentBuilder(),
        EpubPackagerService(),
        XmlDsigSigner(),
        cryptoService,
      );
    });

    tearDown(() async {
      await banco.fechar();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('deve gerar e assinar ponta a ponta o container EPUB 3 persistindo submissão no SQLite', () async {
      const sid = 'sessao_fluxo_123';
      final yamlProtocolo = await rootBundle.loadString(
        'assets/protocols/registro_expresso.yaml',
      );
      final registro = Registro()
        ..idProtocolo = 'express_log'
        ..yamlConteudo = yamlProtocolo
        ..respostas['route_name'] = (Resposta()..texto = 'Relatório de Integração')
        ..respostas['foto_1'] = (Resposta()
          ..midia = (ReferenciaMidia()..imagem = (ArquivoImagem()..uuid = 'foto_p1')))
        ..respostas['video_1'] = (Resposta()
          ..midia = (ReferenciaMidia()..video = (ArquivoVideo()..uuid = 'video_p1')));

      await sessionManager.saveManifest(
        sessionId: sid,
        binarypb: Uint8List.fromList(registro.writeToBuffer()),
      );

      final outputPathEpub = '${tempDir.path}/relatorio_final.epub';

      await notifier.startGeneration(
        'Relatório de Integração',
        outputPathEpub,
        sessionId: sid,
      );

      final state = notifier.state;
      expect(state.hasError, isFalse, reason: state.errorMessage);
      expect(state.isComplete, isTrue);
      expect(state.progress, equals(1.0));

      expect(state.epubPath, isNotNull);
      final epubFile = File(state.epubPath!);
      expect(await epubFile.exists(), isTrue);
      expect(await epubFile.length(), greaterThan(0));

      final epubBytes = await epubFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(epubBytes);

      final nomesArquivos = archive.map((f) => f.name).toSet();
      expect(nomesArquivos, contains('mimetype'));
      expect(nomesArquivos, contains('META-INF/container.xml'));
      expect(nomesArquivos, contains('META-INF/signatures.xml'));
      expect(nomesArquivos, contains('OEBPS/content.opf'));
      expect(nomesArquivos, contains('OEBPS/relatorio.xhtml'));
      expect(nomesArquivos, contains('OEBPS/estilo.css'));
      expect(nomesArquivos, contains('OEBPS/dados/registro.yaml'));
      expect(nomesArquivos, contains('OEBPS/midias/foto_p1.webp'));
      expect(nomesArquivos, contains('OEBPS/midias/video_p1.mp4'));
      expect(nomesArquivos, contains('OEBPS/midias/video_p1_poster.jpg'));

      final submissaoSalva = await banco.obterSubmissaoPorIdSessao(sid);
      expect(submissaoSalva, isNotNull);
      expect(submissaoSalva!.epubPath, equals(epubFile.path));
    });
  });
}
