// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fixlog/core/services/providers.dart';
import 'package:fixlog/features/pdf_generation/providers/generation_provider.dart';
import 'package:fixlog/features/pdf_generation/services/pdf_draft_service.dart';
import 'package:fixlog/features/media/services/media_compressor_service.dart';
import 'package:fixlog/features/pdf_generation/services/generation_recovery_service.dart';
import 'package:fixlog/core/services/session_bundle_manager.dart';
import 'package:fixlog/core/services/epub_document_builder.dart';
import 'package:fixlog/core/services/epub_packager_service.dart';
import 'package:fixlog/core/services/xml_dsig_signer.dart';
import 'package:fixlog/core/services/pdf_print_summary_service.dart';
import 'package:fixlog/core/services/crypto_service.dart';
import 'package:fixlog/core/models/proto/protos/registro.pb.dart';
import 'package:isar_community/isar.dart';
import 'package:fixlog/core/models/local/submission_record.dart';

class MockPdfDraftService extends Mock implements PdfDraftService {}
class MockMediaCompressorService extends Mock implements MediaCompressorService {}
class MockGenerationRecoveryService extends Mock implements GenerationRecoveryService {}
class MockSessionBundleManager extends Mock implements SessionBundleManager {}
class MockCryptoService extends Mock implements CryptoService {}
class MockPdfPrintSummaryService extends Mock implements PdfPrintSummaryService {}
class MockEpubDocumentBuilder extends Mock implements EpubDocumentBuilder {}
class MockEpubPackagerService extends Mock implements EpubPackagerService {}
class MockXmlDsigSigner extends Mock implements XmlDsigSigner {}

class FakeSubmissionCollection extends Fake implements IsarCollection<SubmissionRecord> {
  int putCalls = 0;
  SubmissionRecord? lastSavedRecord;

  @override
  Future<int> put(SubmissionRecord object) async {
    putCalls++;
    lastSavedRecord = object;
    return 1;
  }

  @override
  QueryBuilder<SubmissionRecord, SubmissionRecord, QFilterCondition> filter() {
    throw UnsupportedError('Mock filter');
  }
}

class FakeIsar extends Fake implements Isar {
  final FakeSubmissionCollection fakeCollection = FakeSubmissionCollection();

  @override
  IsarCollection<T> collection<T>() {
    if (T == SubmissionRecord) {
      return fakeCollection as IsarCollection<T>;
    }
    throw UnimplementedError();
  }

  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) {
    return callback();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(File(''));
    registerFallbackValue(Registro());
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(MockSessionBundleManager());
  });

  late MockPdfDraftService mockDraftService;
  late MockMediaCompressorService mockMediaService;
  late MockGenerationRecoveryService mockRecoveryService;
  late MockSessionBundleManager mockSessionManager;
  late MockCryptoService mockCryptoService;
  late MockPdfPrintSummaryService mockPdfSummaryService;
  late MockEpubDocumentBuilder mockEpubBuilder;
  late MockEpubPackagerService mockEpubPackager;
  late MockXmlDsigSigner mockXmlSigner;
  late FakeIsar fakeIsar;
  late GenerationNotifier notifier;

  setUp(() {
    mockDraftService = MockPdfDraftService();
    mockMediaService = MockMediaCompressorService();
    mockRecoveryService = MockGenerationRecoveryService();
    mockSessionManager = MockSessionBundleManager();
    mockCryptoService = MockCryptoService();
    mockPdfSummaryService = MockPdfPrintSummaryService();
    mockEpubBuilder = MockEpubDocumentBuilder();
    mockEpubPackager = MockEpubPackagerService();
    mockXmlSigner = MockXmlDsigSigner();
    fakeIsar = FakeIsar();

    when(() => mockCryptoService.generateAndStoreKeysIfNeeded()).thenAnswer((_) async {});
    when(() => mockCryptoService.getPrivateKeyPem()).thenAnswer((_) async => 'fake_priv_key');
    when(() => mockCryptoService.getPublicKeyPem()).thenAnswer((_) async => 'fake_pub_key');
    when(() => mockCryptoService.generateX509Certificate(any())).thenAnswer((_) async => 'fake_cert');

    when(() => mockEpubBuilder.gerarCss()).thenReturn('body {}');
    when(() => mockEpubBuilder.gerarXhtml(
      registro: any(named: 'registro'),
      idSessao: any(named: 'idSessao'),
      urlCanonica: any(named: 'urlCanonica'),
      mapeamentoMidias: any(named: 'mapeamentoMidias'),
      posterFrames: any(named: 'posterFrames'),
      qrCodesVideos: any(named: 'qrCodesVideos'),
      qrCodeCanonica: any(named: 'qrCodeCanonica'),
    )).thenReturn('<html></html>');

    when(() => mockXmlSigner.gerarAssinaturaXml(
      arquivos: any(named: 'arquivos'),
      privateKeyPem: any(named: 'privateKeyPem'),
      certificadoX509Pem: any(named: 'certificadoX509Pem'),
    )).thenAnswer((_) async => '<signatures/>');

    when(() => mockEpubPackager.empacotarEpub(
      idSessao: any(named: 'idSessao'),
      idProtocolo: any(named: 'idProtocolo'),
      xhtmlConteudo: any(named: 'xhtmlConteudo'),
      cssConteudo: any(named: 'cssConteudo'),
      binarypb: any(named: 'binarypb'),
      arquivosMidia: any(named: 'arquivosMidia'),
      signaturesXml: any(named: 'signaturesXml'),
    )).thenReturn(Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]));

    when(() => mockPdfSummaryService.exportarPdfResumido(
      caminhoSaida: any(named: 'caminhoSaida'),
      registro: any(named: 'registro'),
      idSessao: any(named: 'idSessao'),
      urlCanonica: any(named: 'urlCanonica'),
      mapeamentoMidias: any(named: 'mapeamentoMidias'),
      posterFrames: any(named: 'posterFrames'),
    )).thenAnswer((invocation) async {
      final caminho = invocation.namedArguments[#caminhoSaida] as String;
      final file = File(caminho);
      await file.create(recursive: true);
      await file.writeAsString('pdf fake');
      return file;
    });

    notifier = GenerationNotifier(
      mockDraftService,
      mockMediaService,
      mockRecoveryService,
      mockSessionManager,
      fakeIsar,
      mockEpubBuilder,
      mockEpubPackager,
      mockXmlSigner,
      mockPdfSummaryService,
      mockCryptoService,
    );
  });

  test('Deve processar manifest e gerar relatório canônico em EPUB 3 assinado sem chamada síncrona de PDF', () async {
    final fakeWorkspace = Directory.systemTemp.createTempSync('workspace');
    when(() => mockRecoveryService.getWorkspaceDir()).thenAnswer((_) async => fakeWorkspace);
    when(() => mockRecoveryService.markAsProcessing(any())).thenAnswer((_) async {});

    final registro = Registro()..idProtocolo = 'Test Protocol';
    when(() => mockSessionManager.readManifest(sessionId: any(named: 'sessionId')))
        .thenAnswer((_) async => registro.writeToBuffer());

    when(() => mockDraftService.drawDraft(any(), any(), any()))
        .thenAnswer((_) async => File('${fakeWorkspace.path}/draft.pdf')..writeAsStringSync('draft'));

    final outPath = '${fakeWorkspace.path}/output.epub';

    await notifier.startGeneration('Teste', outPath, sessionId: '123');

    expect(notifier.state.isComplete, isTrue);
    expect(notifier.state.hasError, isFalse);
    expect(notifier.state.progress, 1.0);
    expect(notifier.state.epubPath, isNotNull);
    expect(notifier.state.pdfPath, isNull);

    verify(() => mockEpubPackager.empacotarEpub(
      idSessao: '123',
      idProtocolo: 'Test Protocol',
      xhtmlConteudo: any(named: 'xhtmlConteudo'),
      cssConteudo: any(named: 'cssConteudo'),
      binarypb: any(named: 'binarypb'),
      arquivosMidia: any(named: 'arquivosMidia'),
      signaturesXml: any(named: 'signaturesXml'),
    )).called(1);

    verifyNever(() => mockPdfSummaryService.exportarPdfResumido(
      caminhoSaida: any(named: 'caminhoSaida'),
      registro: any(named: 'registro'),
      idSessao: any(named: 'idSessao'),
      urlCanonica: any(named: 'urlCanonica'),
      mapeamentoMidias: any(named: 'mapeamentoMidias'),
      posterFrames: any(named: 'posterFrames'),
    ));

    fakeWorkspace.deleteSync(recursive: true);
  });

  test('Deve gravar um SubmissionRecord no Isar após a geração do relatório', () async {
    final fakeWorkspace = Directory.systemTemp.createTempSync('workspace');
    when(() => mockRecoveryService.getWorkspaceDir()).thenAnswer((_) async => fakeWorkspace);
    when(() => mockRecoveryService.markAsProcessing(any())).thenAnswer((_) async {});

    when(() => mockSessionManager.readManifest(sessionId: any(named: 'sessionId')))
        .thenAnswer((_) async => (Registro()..idProtocolo = 'Test Protocol').writeToBuffer());

    when(() => mockDraftService.drawDraft(any(), any(), any()))
        .thenAnswer((_) async => File('${fakeWorkspace.path}/draft.pdf')..writeAsStringSync('draft'));

    final outPath = '${fakeWorkspace.path}/output_final.pdf';

    await notifier.startGeneration('Teste Protocolo', outPath, sessionId: '123');

    expect(fakeIsar.fakeCollection.putCalls, 1);
    final savedRecord = fakeIsar.fakeCollection.lastSavedRecord!;
    expect(savedRecord.nomeProtocolo, 'Teste Protocolo');
    expect(savedRecord.pdfPath, '');
    expect(savedRecord.idSessao, '123');
    expect(savedRecord.protobufPath, endsWith('.epub'));

    fakeWorkspace.deleteSync(recursive: true);
  });

  test('Deve processar fotos e vídeos referenciados no Registro', () async {
    final fakeWorkspace = Directory.systemTemp.createTempSync('workspace');
    when(() => mockRecoveryService.getWorkspaceDir()).thenAnswer((_) async => fakeWorkspace);
    when(() => mockRecoveryService.markAsProcessing(any())).thenAnswer((_) async {});

    final fotoFile = File('${fakeWorkspace.path}/foto.webp')..writeAsBytesSync([1, 2]);
    final videoFile = File('${fakeWorkspace.path}/video.mp4')..writeAsBytesSync([3, 4]);
    final posterFile = File('${fakeWorkspace.path}/poster.webp')..writeAsBytesSync([5, 6]);

    when(() => mockMediaService.comprimirImagemSessao(
      sessionManager: any(named: 'sessionManager'),
      sessionId: any(named: 'sessionId'),
      mediaUuid: 'uuid-foto',
    )).thenAnswer((_) async => fotoFile);

    when(() => mockMediaService.transcodificarVideoSessao(
      sessionManager: any(named: 'sessionManager'),
      sessionId: any(named: 'sessionId'),
      mediaUuid: 'uuid-video',
    )).thenAnswer((_) async => (video: videoFile, poster: posterFile));

    final registroComMidias = Registro()
      ..idProtocolo = 'Via com Fotos e Vídeos'
      ..respostas['foto'] = (Resposta()..midia = (ReferenciaMidia()..imagem = (ArquivoImagem()..uuid = 'uuid-foto')))
      ..respostas['video'] = (Resposta()..midia = (ReferenciaMidia()..video = (ArquivoVideo()..uuid = 'uuid-video')));

    when(() => mockSessionManager.readManifest(sessionId: 'sessao-midia'))
        .thenAnswer((_) async => registroComMidias.writeToBuffer());

    final outPath = '${fakeWorkspace.path}/relatorio.epub';
    await notifier.startGeneration('Via com Fotos e Vídeos', outPath, sessionId: 'sessao-midia');

    expect(notifier.state.isComplete, isTrue);
    expect(notifier.state.hasError, isFalse);

    verify(() => mockMediaService.comprimirImagemSessao(
      sessionManager: any(named: 'sessionManager'),
      sessionId: 'sessao-midia',
      mediaUuid: 'uuid-foto',
    )).called(1);

    verify(() => mockMediaService.transcodificarVideoSessao(
      sessionManager: any(named: 'sessionManager'),
      sessionId: 'sessao-midia',
      mediaUuid: 'uuid-video',
    )).called(1);

    fakeWorkspace.deleteSync(recursive: true);
  });

  test('Deve registrar estado de erro quando ocorre falha durante a esteira', () async {
    when(() => mockRecoveryService.markAsProcessing(false))
        .thenAnswer((_) async {});
    when(() => mockRecoveryService.markAsProcessing(true))
        .thenThrow(Exception('Falha catastrófica de inicialização'));

    await notifier.startGeneration('Teste Falha', '/saida/invalida/teste.pdf', sessionId: 'sessao-falha');

    expect(notifier.state.hasError, isTrue);
    expect(notifier.state.isComplete, isFalse);
    expect(notifier.state.errorMessage, contains('Falha catastrófica'));
  });

  test('GenerationState copyWith atualiza todos os campos corretamente', () {
    final estado = GenerationState();
    final atualizado = estado.copyWith(
      progress: 0.5,
      status: 'Status teste',
      isComplete: true,
      hasError: true,
      errorMessage: 'Erro teste',
      outputPath: '/saida.pdf',
      epubPath: '/saida.epub',
      pdfPath: '/saida.pdf',
    );

    expect(atualizado.progress, 0.5);
    expect(atualizado.status, 'Status teste');
    expect(atualizado.isComplete, isTrue);
    expect(atualizado.hasError, isTrue);
    expect(atualizado.errorMessage, 'Erro teste');
    expect(atualizado.outputPath, '/saida.pdf');
    expect(atualizado.epubPath, '/saida.epub');
    expect(atualizado.pdfPath, '/saida.pdf');
  });

  test('startGeneration com sessionId nulo gera id dinâmico e processa mídias em listas', () async {
    final fakeWorkspace = Directory.systemTemp.createTempSync('workspace_null_session');
    when(() => mockRecoveryService.getWorkspaceDir()).thenAnswer((_) async => fakeWorkspace);
    when(() => mockRecoveryService.markAsProcessing(any())).thenAnswer((_) async {});

    final fotoFile = File('${fakeWorkspace.path}/foto_lista.webp')..writeAsBytesSync([1]);
    final videoFile = File('${fakeWorkspace.path}/video_lista.mp4')..writeAsBytesSync([2]);

    when(() => mockMediaService.comprimirImagemSessao(
      sessionManager: any(named: 'sessionManager'),
      sessionId: any(named: 'sessionId'),
      mediaUuid: 'uuid-img-list',
    )).thenAnswer((_) async => fotoFile);

    when(() => mockMediaService.transcodificarVideoSessao(
      sessionManager: any(named: 'sessionManager'),
      sessionId: any(named: 'sessionId'),
      mediaUuid: 'uuid-vid-list',
    )).thenAnswer((_) async => (video: videoFile, poster: null));

    final outPath = '${fakeWorkspace.path}/relatorio.pdf';

    await notifier.startGeneration('Vistoria sem Sessao', outPath);

    expect(notifier.state.isComplete, isTrue);
    fakeWorkspace.deleteSync(recursive: true);
  });

  test('GenerationNotifier pode ser instanciado com construtor padrão sem parâmetros opcionais', () {
    final n = GenerationNotifier(
      mockDraftService,
      mockMediaService,
      mockRecoveryService,
      mockSessionManager,
    );
    expect(n, isNotNull);
  });

  test('Providers do generation_provider provêm instâncias válidas', () {
    final container = ProviderContainer(
      overrides: [
        generationRecoveryProvider.overrideWithValue(mockRecoveryService),
        mediaCompressorProvider.overrideWithValue(mockMediaService),
        cryptoServiceProvider.overrideWithValue(mockCryptoService),
      ],
    );

    expect(container.read(draftServiceProvider), isNotNull);
    expect(container.read(mediaCompressorProvider), isNotNull);
    expect(container.read(generationRecoveryProvider), isNotNull);
    expect(container.read(epubDocumentBuilderProvider), isNotNull);
    expect(container.read(epubPackagerServiceProvider), isNotNull);
    expect(container.read(xmlDsigSignerProvider), isNotNull);
    expect(container.read(generationProvider), isA<GenerationState>());
  });
}
