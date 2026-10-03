// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/src/interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/core/services/epub_document_builder.dart';
import 'package:fixalog/core/services/epub_packager_service.dart';
import 'package:fixalog/core/services/xml_dsig_signer.dart';
import 'package:fixalog/core/services/crypto_service.dart';
import 'package:fixalog/core/services/pdf_print_summary_service.dart';
import 'package:fixalog/features/media/services/media_compressor_service.dart';
import 'package:fixalog/features/pdf_generation/providers/generation_provider.dart';
import 'package:fixalog/features/pdf_generation/services/generation_recovery_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class FakePrintingPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PrintingPlatform {
  @override
  Future<Uint8List> convertHtml(
    String html,
    String? baseUrl,
    PdfPageFormat format,
  ) async {
    return Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]); // %PDF-1.4
  }
}

class FakeMediaCompressorService extends MediaCompressorService {
  final Directory dir;
  FakeMediaCompressorService(this.dir);

  @override
  Future<File?> comprimirImagemSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
    int maxDimension = 2048,
    int quality = 85,
  }) async {
    final file = File('${dir.path}/$mediaUuid.webp');
    await file.writeAsBytes(Uint8List.fromList([1, 2, 3]));
    return file;
  }

  @override
  Future<({File? video, File? poster})> transcodificarVideoSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
  }) async {
    final video = File('${dir.path}/$mediaUuid.mp4');
    final poster = File('${dir.path}/${mediaUuid}_poster.webp');
    await video.writeAsBytes(Uint8List.fromList([4, 5, 6]));
    await poster.writeAsBytes(Uint8List.fromList([7, 8, 9]));
    return (video: video, poster: poster);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo Completo de Geração de Relatório EPUB 3 e PDF Resumido (Dart Puro)', () {
    late Directory tempDir;
    late SessionBundleManager sessionManager;
    late GenerationRecoveryService recoveryService;
    late MockFlutterSecureStorage mockSecureStorage;
    late CryptoService cryptoService;
    late GenerationNotifier notifier;
    final Map<String, String> memoriaSecureStorage = {};

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('generation_flow_test_');

      PrintingPlatform.instance = FakePrintingPlatform();

      sessionManager = SessionBundleManager(
        baseDirectoryGetter: () async => tempDir,
      );
      recoveryService = GenerationRecoveryService(
        tempDirGetter: () async => tempDir,
      );

      mockSecureStorage = MockFlutterSecureStorage();
      memoriaSecureStorage.clear();

      final keyPair = CryptoUtils.generateEcKeyPair();
      final privateKeyPem = CryptoUtils.encodeEcPrivateKeyToPem(
        keyPair.privateKey as ECPrivateKey,
      );
      final publicKeyPem = CryptoUtils.encodeEcPublicKeyToPem(
        keyPair.publicKey as ECPublicKey,
      );
      memoriaSecureStorage['private_key'] = privateKeyPem;
      memoriaSecureStorage['public_key'] = publicKeyPem;

      when(() => mockSecureStorage.read(key: any(named: 'key'))).thenAnswer((inv) async {
        final k = inv.namedArguments[#key] as String;
        return memoriaSecureStorage[k];
      });

      when(() => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((inv) async {
        final k = inv.namedArguments[#key] as String;
        final v = inv.namedArguments[#value] as String;
        memoriaSecureStorage[k] = v;
      });

      cryptoService = CryptoService(secureStorage: mockSecureStorage);

      notifier = GenerationNotifier(
        null,
        FakeMediaCompressorService(tempDir),
        recoveryService,
        sessionManager,
        null,
        EpubDocumentBuilder(),
        EpubPackagerService(),
        XmlDsigSigner(),
        PdfPrintSummaryService(),
        cryptoService,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Geração ponta a ponta do relatório EPUB 3 e PDF', () async {
      final sid = 'sessao_fluxo_123';
      final registro = Registro()
        ..idProtocolo = 'PROT-2026-99'
        ..respostas['foto_1'] = (Resposta()
          ..midia = (ReferenciaMidia()..imagem = (ArquivoImagem()..uuid = 'foto_p1')))
        ..respostas['video_1'] = (Resposta()
          ..midia = (ReferenciaMidia()..video = (ArquivoVideo()..uuid = 'video_p1')));

      // Salva o manifesto na sessão para ser lido
      await sessionManager.saveManifest(
        sessionId: sid,
        binarypb: Uint8List.fromList(registro.writeToBuffer()),
      );

      final outputPathPdf = '${tempDir.path}/relatorio_final.pdf';

      await notifier.startGeneration(
        'Relatório de Integração',
        outputPathPdf,
        sessionId: sid,
      );

      final state = notifier.state;
      expect(state.hasError, isFalse, reason: state.errorMessage);
      expect(state.isComplete, isTrue);
      expect(state.progress, equals(1.0));

      // Validar existência do arquivo PDF
      expect(state.pdfPath, isNotNull);
      final pdfFile = File(state.pdfPath!);
      expect(await pdfFile.exists(), isTrue);
      expect(await pdfFile.length(), greaterThan(0));

      // Validar existência do arquivo EPUB 3
      expect(state.epubPath, isNotNull);
      final epubFile = File(state.epubPath!);
      expect(await epubFile.exists(), isTrue);
      expect(await epubFile.length(), greaterThan(0));

      // Validar integridade interna do container EPUB 3
      final epubBytes = await epubFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(epubBytes);

      final nomesArquivos = archive.map((f) => f.name).toSet();
      expect(nomesArquivos, contains('mimetype'));
      expect(nomesArquivos, contains('META-INF/container.xml'));
      expect(nomesArquivos, contains('META-INF/signatures.xml'));
      expect(nomesArquivos, contains('OEBPS/content.opf'));
      expect(nomesArquivos, contains('OEBPS/relatorio.xhtml'));
      expect(nomesArquivos, contains('OEBPS/estilo.css'));
      expect(nomesArquivos, contains('OEBPS/dados/registro.binarypb'));
      expect(nomesArquivos, contains('OEBPS/midias/foto_p1.webp'));
      expect(nomesArquivos, contains('OEBPS/midias/video_p1.mp4'));
      expect(nomesArquivos, contains('OEBPS/midias/video_p1_poster.webp'));
    });
  });
}
