// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/crypto_service.dart';
import 'package:fixalog/core/services/epub_document_builder.dart';
import 'package:fixalog/core/services/epub_packager_service.dart';
import 'package:fixalog/core/services/pdf_print_summary_service.dart';
import 'package:fixalog/core/services/providers.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/core/services/xml_dsig_signer.dart';
import 'package:fixalog/features/media/services/media_compressor_service.dart';
import 'package:fixalog/features/pdf_generation/providers/generation_provider.dart';
import 'package:fixalog/features/pdf_generation/services/generation_recovery_service.dart';
import 'package:fixalog/features/pdf_generation/services/pdf_draft_service.dart';

class _FakeGenerationRecoveryService extends GenerationRecoveryService {
  final Directory workspaceDir;
  final bool falharAoIniciar;
  bool processando = false;

  _FakeGenerationRecoveryService(
    this.workspaceDir, {
    this.falharAoIniciar = false,
  }) : super(tempDirGetter: () async => workspaceDir);

  @override
  Future<Directory> getWorkspaceDir() async => workspaceDir;

  @override
  Future<void> markAsProcessing(bool isProcessing) async {
    if (isProcessing && falharAoIniciar) {
      throw Exception('Falha catastrófica de inicialização');
    }
    processando = isProcessing;
  }

  @override
  Future<bool> wasInterrupted() async => processando;
}

class _FakeMediaCompressorService extends MediaCompressorService {
  final Map<String, File> imagensComprimidas;
  final Map<String, ({File? video, File? poster})> videosTranscodificados;
  final Map<String, List<File>> documentosRasterizados;
  final List<String> fotosSolicitadas = [];
  final List<String> videosSolicitados = [];
  final List<String> documentosSolicitados = [];

  _FakeMediaCompressorService({
    this.imagensComprimidas = const {},
    this.videosTranscodificados = const {},
    this.documentosRasterizados = const {},
  });

  @override
  Future<File?> comprimirImagemSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
  }) async {
    fotosSolicitadas.add(mediaUuid);
    return imagensComprimidas[mediaUuid];
  }

  @override
  Future<({File? video, File? poster})> transcodificarVideoSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
  }) async {
    videosSolicitados.add(mediaUuid);
    return videosTranscodificados[mediaUuid] ?? (video: null, poster: null);
  }

  @override
  Future<List<File>> rasterizarDocumentoPdfSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
    double dpi = 150,
  }) async {
    documentosSolicitados.add(mediaUuid);
    return documentosRasterizados[mediaUuid] ?? const [];
  }
}

class _FakePdfDraftService extends PdfDraftService {
  int chamadas = 0;

  @override
  Future<File> drawDraft(
    Registro registro,
    String outputPath,
    String Function(String uuid) mediaPathResolver,
  ) async {
    chamadas++;
    final file = File(outputPath);
    await file.create(recursive: true);
    await file.writeAsString('draft');
    return file;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Isar isar;
  late SessionBundleManager sessionManager;
  late _FakeGenerationRecoveryService recoveryService;
  late _FakeMediaCompressorService mediaService;
  late _FakePdfDraftService draftService;
  late CryptoService cryptoService;
  late EpubDocumentBuilder epubBuilder;
  late EpubPackagerService epubPackager;
  late XmlDsigSigner xmlSigner;
  late PdfPrintSummaryService pdfSummaryService;
  late GenerationNotifier notifier;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('fixalog_gen_provider_test_');
    isar = await Isar.open(
      [SubmissionRecordSchema],
      directory: tempDir.path,
      name: 'test_gen_${DateTime.now().microsecondsSinceEpoch}',
    );
    sessionManager = SessionBundleManager(
      baseDirectoryGetter: () async => tempDir,
    );
    recoveryService = _FakeGenerationRecoveryService(tempDir);
    mediaService = _FakeMediaCompressorService();
    draftService = _FakePdfDraftService();
    cryptoService = CryptoService();
    epubBuilder = EpubDocumentBuilder();
    epubPackager = EpubPackagerService();
    xmlSigner = XmlDsigSigner();
    pdfSummaryService = PdfPrintSummaryService(
      documentBuilder: epubBuilder,
    );

    notifier = GenerationNotifier(
      draftService,
      mediaService,
      recoveryService,
      sessionManager,
      isar,
      epubBuilder,
      epubPackager,
      xmlSigner,
      pdfSummaryService,
      cryptoService,
    );
  });

  tearDown(() async {
    if (isar.isOpen) {
      await isar.close(deleteFromDisk: true);
    }
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  test('Deve processar manifest e gerar relatório canônico em EPUB 3 assinado sem chamada síncrona de PDF', () async {
    final registro = Registro()..idProtocolo = 'Test Protocol';
    await sessionManager.saveManifest(
      sessionId: '123',
      binarypb: Uint8List.fromList(registro.writeToBuffer()),
    );

    final outPath = '${tempDir.path}/output.epub';
    await notifier.startGeneration('Teste', outPath, sessionId: '123');

    expect(notifier.state.isComplete, isTrue);
    expect(notifier.state.hasError, isFalse);
    expect(notifier.state.progress, 1.0);
    expect(notifier.state.epubPath, isNotNull);
    expect(File(notifier.state.epubPath!).existsSync(), isTrue);
    expect(notifier.state.pdfPath, isNull);
    expect(draftService.chamadas, equals(0));
  });

  test('Deve gravar um SubmissionRecord no Isar após a geração do relatório', () async {
    final registro = Registro()..idProtocolo = 'Test Protocol';
    await sessionManager.saveManifest(
      sessionId: '123',
      binarypb: Uint8List.fromList(registro.writeToBuffer()),
    );

    final outPath = '${tempDir.path}/output_final.pdf';
    await notifier.startGeneration('Teste Protocolo', outPath, sessionId: '123');

    final savedRecord = await isar.submissionRecords
        .filter()
        .idSessaoEqualTo('123')
        .findFirst();
    expect(savedRecord, isNotNull);
    expect(savedRecord!.nomeProtocolo, 'Teste Protocolo');
    expect(savedRecord.pdfPath, '');
    expect(savedRecord.idSessao, '123');
    expect(savedRecord.protobufPath, endsWith('.epub'));
    expect(savedRecord.status, SubmissionStatus.gerado);
  });

  test('Deve processar fotos e vídeos referenciados no Registro empacotando poster em .jpg', () async {
    final fotoFile = File('${tempDir.path}/foto.webp')..writeAsBytesSync([1, 2]);
    final videoFile = File('${tempDir.path}/video.mp4')..writeAsBytesSync([3, 4]);
    final posterFile = File('${tempDir.path}/poster.jpg')..writeAsBytesSync([5, 6]);

    mediaService = _FakeMediaCompressorService(
      imagensComprimidas: {'uuid-foto': fotoFile},
      videosTranscodificados: {
        'uuid-video': (video: videoFile, poster: posterFile),
      },
    );
    notifier = GenerationNotifier(
      draftService,
      mediaService,
      recoveryService,
      sessionManager,
      isar,
      epubBuilder,
      epubPackager,
      xmlSigner,
      pdfSummaryService,
      cryptoService,
    );

    final registroComMidias = Registro()
      ..idProtocolo = 'Via com Fotos e Vídeos'
      ..respostas['foto'] = (Resposta()
        ..midia = (ReferenciaMidia()
          ..imagem = (ArquivoImagem()..uuid = 'uuid-foto')))
      ..respostas['video'] = (Resposta()
        ..midia = (ReferenciaMidia()
          ..video = (ArquivoVideo()..uuid = 'uuid-video')));

    await sessionManager.saveManifest(
      sessionId: 'sessao-midia',
      binarypb: Uint8List.fromList(registroComMidias.writeToBuffer()),
    );

    final outPath = '${tempDir.path}/relatorio.epub';
    await notifier.startGeneration(
      'Via com Fotos e Vídeos',
      outPath,
      sessionId: 'sessao-midia',
    );

    expect(notifier.state.isComplete, isTrue);
    expect(notifier.state.hasError, isFalse);
    expect(mediaService.fotosSolicitadas, contains('uuid-foto'));
    expect(mediaService.videosSolicitados, contains('uuid-video'));

    final zip = ZipDecoder().decodeBytes(File(outPath).readAsBytesSync());
    final nomes = zip.files.map((f) => f.name).toSet();
    expect(nomes, contains('OEBPS/midias/uuid-video_poster.jpg'));
  });

  test('Deve empacotar documento PDF original bit-a-bit e páginas WebP rasterizadas no EPUB 3 com assinatura XML-DSig válida', () async {
    final bytesPdfAssinadoGovBr = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37, 0xAA, 0xBB]);
    await sessionManager.saveOriginalMedia(
      sessionId: 'sessao-doc-pdf',
      mediaUuid: 'uuid-nf-pdf',
      extension: '.pdf',
      bytes: bytesPdfAssinadoGovBr,
    );

    final pag1File = File('${tempDir.path}/p1.webp')..writeAsBytesSync([10, 11, 12]);
    final pag2File = File('${tempDir.path}/p2.webp')..writeAsBytesSync([20, 21, 22]);

    mediaService = _FakeMediaCompressorService(
      documentosRasterizados: {
        'uuid-nf-pdf': [pag1File, pag2File],
      },
    );
    notifier = GenerationNotifier(
      draftService,
      mediaService,
      recoveryService,
      sessionManager,
      isar,
      epubBuilder,
      epubPackager,
      xmlSigner,
      pdfSummaryService,
      cryptoService,
    );

    final grupoMat = GrupoRepetido()
      ..idLista = 'lista_materiais_cadastro'
      ..idItem = 'item_mat_1'
      ..idTipo = 'chumbador_mecanico'
      ..respostasItem['mat_nota_fiscal'] = (Resposta()
        ..midia = (ReferenciaMidia()
          ..documento = (ArquivoDocumento()
            ..uuid = 'uuid-nf-pdf'
            ..tipoOriginal = 'application/pdf'
            ..nomeOriginal = 'nota_fiscal_govbr.pdf'
            ..quantidadePaginas = 0)));

    final registroComPdf = Registro()
      ..idProtocolo = 'cadastro_material'
      ..respostas['mat_nome'] = (Resposta()..texto = 'Chumbador com NF em PDF')
      ..listas.add(grupoMat);

    await sessionManager.saveManifest(
      sessionId: 'sessao-doc-pdf',
      binarypb: Uint8List.fromList(registroComPdf.writeToBuffer()),
    );

    final outPath = '${tempDir.path}/relatorio_com_pdf.epub';
    await notifier.startGeneration(
      'Cadastro de Material',
      outPath,
      sessionId: 'sessao-doc-pdf',
    );

    expect(notifier.state.isComplete, isTrue);
    expect(notifier.state.hasError, isFalse);
    expect(mediaService.documentosSolicitados, contains('uuid-nf-pdf'));

    final zip = ZipDecoder().decodeBytes(File(outPath).readAsBytesSync());
    final mapaArquivos = <String, List<int>>{};
    for (final f in zip.files) {
      if (f.isFile) {
        mapaArquivos[f.name] = f.content as List<int>;
      }
    }

    // Verifica preservação bit-a-bit do PDF original e das páginas WebP
    expect(mapaArquivos['OEBPS/midias/uuid-nf-pdf.pdf'], equals(bytesPdfAssinadoGovBr));
    expect(mapaArquivos['OEBPS/midias/uuid-nf-pdf_p1.webp'], equals([10, 11, 12]));
    expect(mapaArquivos['OEBPS/midias/uuid-nf-pdf_p2.webp'], equals([20, 21, 22]));

    // Verifica declaração no content.opf
    final opfXml = utf8.decode(mapaArquivos['OEBPS/content.opf']!);
    expect(opfXml, contains('href="midias/uuid-nf-pdf.pdf" media-type="application/pdf"'));
    expect(opfXml, contains('href="midias/uuid-nf-pdf_p1.webp" media-type="image/webp"'));
    expect(opfXml, contains('href="midias/uuid-nf-pdf_p2.webp" media-type="image/webp"'));

    // Verifica que o relatorio.xhtml referencia o PDF original e ambas as páginas
    final xhtml = utf8.decode(mapaArquivos['OEBPS/relatorio.xhtml']!);
    expect(xhtml, contains('href="midias/uuid-nf-pdf.pdf" download="nota_fiscal_govbr.pdf"'));
    expect(xhtml, contains('src="midias/uuid-nf-pdf_p1.webp"'));
    expect(xhtml, contains('src="midias/uuid-nf-pdf_p2.webp"'));

    // Verifica que a assinatura XML-DSig cobre o PDF e as páginas WebP
    final publicKeyPem = await cryptoService.getPublicKeyPem();
    final sigXml = utf8.decode(mapaArquivos['META-INF/signatures.xml']!);
    expect(sigXml, contains('URI="OEBPS/midias/uuid-nf-pdf.pdf"'));
    expect(sigXml, contains('URI="OEBPS/midias/uuid-nf-pdf_p1.webp"'));
    expect(sigXml, contains('URI="OEBPS/midias/uuid-nf-pdf_p2.webp"'));
    expect(
      xmlSigner.verificarAssinatura(
        signaturesXml: sigXml,
        arquivos: mapaArquivos,
        publicKeyPem: publicKeyPem,
      ),
      isTrue,
    );
  });

  test('Deve incorporar materiais assinados em OEBPS/materiais/<uuid>/, validar ambas as assinaturas XML-DSig, atualizar na re-geração e manter fallback se removido do catálogo', () async {
    // 1. Gerar e assinar um material v1 no catálogo
    final registroMatV1 = Registro()
      ..idProtocolo = 'cadastro_material'
      ..respostas['mat_nome'] = (Resposta()..texto = 'Chumbador Químico Inox 316 v1')
      ..respostas['mat_codigo_associacao'] = (Resposta()..texto = 'LOTE-001');
    await sessionManager.saveManifest(
      sessionId: 'uuid-mat-inox',
      binarypb: Uint8List.fromList(registroMatV1.writeToBuffer()),
    );

    final caminhoEpubMat = '${tempDir.path}/mat_inox.epub';
    await notifier.startGeneration(
      'Cadastro de Material',
      caminhoEpubMat,
      sessionId: 'uuid-mat-inox',
    );
    expect(notifier.state.isComplete, isTrue);

    final matRecordV1 = await isar.submissionRecords
        .filter()
        .idSessaoEqualTo('uuid-mat-inox')
        .findFirst();
    expect(matRecordV1, isNotNull);
    expect(matRecordV1!.isMaterial, isTrue);
    expect(matRecordV1.tituloExibicao, 'Chumbador Químico Inox 316 v1');

    // 2. Gerar relatório de manutenção que utiliza 'uuid-mat-inox'
    final grupoAcao = GrupoRepetido()
      ..idLista = 'lista_acoes_via_c'
      ..idItem = 'item_acao_1'
      ..idTipo = 'grampo'
      ..respostasItem['ref_mat_grampo'] = (Resposta()..texto = 'uuid-mat-inox');

    final registroManut = Registro()
      ..idProtocolo = 'manutencao_ferragens'
      ..respostas['via_nome'] = (Resposta()..texto = 'Via Paredão Sul')
      ..respostas['lista_materiais_c'] = (Resposta()..texto = 'uuid-mat-inox')
      ..listas.add(grupoAcao);

    await sessionManager.saveManifest(
      sessionId: 'sessao-manut-1',
      binarypb: Uint8List.fromList(registroManut.writeToBuffer()),
    );

    final caminhoEpubManut = '${tempDir.path}/manut_1.epub';
    await notifier.startGeneration(
      'Manutenção de Ferragens',
      caminhoEpubManut,
      sessionId: 'sessao-manut-1',
    );
    expect(notifier.state.isComplete, isTrue);

    // 3. Verificar estrutura do EPUB da manutenção e validade das assinaturas XML-DSig
    final publicKeyPem = await cryptoService.getPublicKeyPem();
    final zipManut1 = ZipDecoder().decodeBytes(File(caminhoEpubManut).readAsBytesSync());
    final mapaArquivosManut1 = <String, List<int>>{};
    for (final f in zipManut1.files) {
      if (f.isFile) {
        mapaArquivosManut1[f.name] = f.content as List<int>;
      }
    }

    // Verifica que o material v1 está em OEBPS/materiais/uuid-mat-inox/
    expect(
      mapaArquivosManut1.containsKey('OEBPS/materiais/uuid-mat-inox/META-INF/signatures.xml'),
      isTrue,
    );
    expect(
      mapaArquivosManut1.containsKey('OEBPS/materiais/uuid-mat-inox/OEBPS/dados/registro.binarypb'),
      isTrue,
    );
    final xhtmlMatEmbutidoV1 = utf8.decode(
      mapaArquivosManut1['OEBPS/materiais/uuid-mat-inox/OEBPS/relatorio.xhtml']!,
    );
    expect(xhtmlMatEmbutidoV1, contains('Chumbador Químico Inox 316 v1'));

    // Verifica que o relatorio.xhtml da manutenção aponta para materiais/uuid-mat-inox/OEBPS/relatorio.xhtml
    final xhtmlManut1 = utf8.decode(mapaArquivosManut1['OEBPS/relatorio.xhtml']!);
    expect(
      xhtmlManut1,
      contains('href="materiais/uuid-mat-inox/OEBPS/relatorio.xhtml"'),
    );
    expect(xhtmlManut1, contains('Chumbador Químico Inox 316 v1'));

    // Valida assinatura XML-DSig principal da manutenção
    final sigManutXml = utf8.decode(mapaArquivosManut1['META-INF/signatures.xml']!);
    expect(
      xmlSigner.verificarAssinatura(
        signaturesXml: sigManutXml,
        arquivos: mapaArquivosManut1,
        publicKeyPem: publicKeyPem,
      ),
      isTrue,
    );

    // Valida assinatura XML-DSig original do material isoladamente a partir da subpasta OEBPS/materiais/uuid-mat-inox/
    const prefixoSubpasta = 'OEBPS/materiais/uuid-mat-inox/';
    final arquivosSubpastaMat = <String, List<int>>{};
    for (final entrada in mapaArquivosManut1.entries) {
      if (entrada.key.startsWith(prefixoSubpasta)) {
        arquivosSubpastaMat[entrada.key.substring(prefixoSubpasta.length)] =
            entrada.value;
      }
    }
    final sigMatOriginalXml = utf8.decode(
      arquivosSubpastaMat['META-INF/signatures.xml']!,
    );
    expect(
      xmlSigner.verificarAssinatura(
        signaturesXml: sigMatOriginalXml,
        arquivos: arquivosSubpastaMat,
        publicKeyPem: publicKeyPem,
      ),
      isTrue,
    );

    // 4. Editar e re-assinar o material no catálogo (v2) e re-gerar a manutenção -> deve atualizar para v2!
    final registroMatV2 = Registro()
      ..idProtocolo = 'cadastro_material'
      ..respostas['mat_nome'] = (Resposta()..texto = 'Chumbador Químico Inox 316 v2 Repassivado')
      ..respostas['mat_codigo_associacao'] = (Resposta()..texto = 'LOTE-002');
    await sessionManager.saveManifest(
      sessionId: 'uuid-mat-inox',
      binarypb: Uint8List.fromList(registroMatV2.writeToBuffer()),
    );
    await notifier.startGeneration(
      'Cadastro de Material',
      caminhoEpubMat,
      sessionId: 'uuid-mat-inox',
    );

    // Re-gerar a manutenção
    await notifier.startGeneration(
      'Manutenção de Ferragens',
      caminhoEpubManut,
      sessionId: 'sessao-manut-1',
    );

    final zipManut2 = ZipDecoder().decodeBytes(File(caminhoEpubManut).readAsBytesSync());
    final xhtmlMatEmbutidoV2 = utf8.decode(
      zipManut2.files
          .firstWhere((f) => f.name == 'OEBPS/materiais/uuid-mat-inox/OEBPS/relatorio.xhtml')
          .content as List<int>,
    );
    expect(xhtmlMatEmbutidoV2, contains('Chumbador Químico Inox 316 v2 Repassivado'));

    // 5. Excluir o material do catálogo local e re-gerar a manutenção -> deve manter fallback da cópia v2 já embutida!
    await isar.writeTxn(() async {
      await isar.submissionRecords.deleteByIdSessao('uuid-mat-inox');
    });
    File(caminhoEpubMat).deleteSync();

    await notifier.startGeneration(
      'Manutenção de Ferragens',
      caminhoEpubManut,
      sessionId: 'sessao-manut-1',
    );
    expect(notifier.state.isComplete, isTrue);

    final zipManut3 = ZipDecoder().decodeBytes(File(caminhoEpubManut).readAsBytesSync());
    final xhtmlMatFallback = utf8.decode(
      zipManut3.files
          .firstWhere((f) => f.name == 'OEBPS/materiais/uuid-mat-inox/OEBPS/relatorio.xhtml')
          .content as List<int>,
    );
    expect(xhtmlMatFallback, contains('Chumbador Químico Inox 316 v2 Repassivado'));
  });

  test('Deve registrar estado de erro quando ocorre falha durante a esteira', () async {
    final recoveryComFalha = _FakeGenerationRecoveryService(
      tempDir,
      falharAoIniciar: true,
    );
    final notifierFalha = GenerationNotifier(
      draftService,
      mediaService,
      recoveryComFalha,
      sessionManager,
      isar,
      epubBuilder,
      epubPackager,
      xmlSigner,
      pdfSummaryService,
      cryptoService,
    );

    await notifierFalha.startGeneration(
      'Teste Falha',
      '${tempDir.path}/invalida/teste.pdf',
      sessionId: 'sessao-falha',
    );

    expect(notifierFalha.state.hasError, isTrue);
    expect(notifierFalha.state.isComplete, isFalse);
    expect(notifierFalha.state.errorMessage, contains('Falha catastrófica'));
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

  test('startGeneration com sessionId nulo gera id dinâmico', () async {
    final outPath = '${tempDir.path}/relatorio_sem_sessao.pdf';
    await notifier.startGeneration('Vistoria sem Sessao', outPath);
    expect(notifier.state.isComplete, isTrue);
  });

  test('GenerationNotifier pode ser instanciado com construtor padrão sem parâmetros opcionais', () {
    final n = GenerationNotifier(
      draftService,
      mediaService,
      recoveryService,
      sessionManager,
    );
    expect(n, isNotNull);
    expect(n.pdfSummaryService, isNotNull);
  });

  test('Providers do generation_provider provêm instâncias válidas', () {
    final container = ProviderContainer(
      overrides: [
        generationRecoveryProvider.overrideWithValue(recoveryService),
        mediaCompressorProvider.overrideWithValue(mediaService),
        cryptoServiceProvider.overrideWithValue(cryptoService),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(draftServiceProvider), isNotNull);
    expect(container.read(mediaCompressorProvider), isNotNull);
    expect(container.read(generationRecoveryProvider), isNotNull);
    expect(container.read(epubDocumentBuilderProvider), isNotNull);
    expect(container.read(epubPackagerServiceProvider), isNotNull);
    expect(container.read(xmlDsigSignerProvider), isNotNull);
    expect(container.read(generationProvider), isA<GenerationState>());
  });

  test('Deve processar múltiplas mídias (fotos, vídeos e PDFs) contidas na mesma Resposta.lista', () async {
    final fotoFile = File('${tempDir.path}/foto_multi.webp')..writeAsBytesSync([1, 2]);
    final videoFile = File('${tempDir.path}/video_multi.mp4')..writeAsBytesSync([3, 4]);
    final posterFile = File('${tempDir.path}/poster_multi.webp')..writeAsBytesSync([5, 6]);
    final pag1File = File('${tempDir.path}/doc_multi_p1.webp')..writeAsBytesSync([7, 8]);

    await sessionManager.saveOriginalMedia(
      sessionId: 'sessao-multi-midia',
      mediaUuid: 'uuid-doc-multi',
      extension: '.pdf',
      bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
    );

    mediaService = _FakeMediaCompressorService(
      imagensComprimidas: {'uuid-foto-multi': fotoFile},
      videosTranscodificados: {
        'uuid-video-multi': (video: videoFile, poster: posterFile),
      },
      documentosRasterizados: {
        'uuid-doc-multi': [pag1File],
      },
    );
    notifier = GenerationNotifier(
      draftService,
      mediaService,
      recoveryService,
      sessionManager,
      isar,
      epubBuilder,
      epubPackager,
      xmlSigner,
      pdfSummaryService,
      cryptoService,
    );

    final respostaMulti = Resposta(
      lista: ListaRespostas(
        valores: [
          Resposta(
            midia: ReferenciaMidia(
              imagem: ArquivoImagem(uuid: 'uuid-foto-multi'),
            ),
          ),
          Resposta(
            midia: ReferenciaMidia(
              video: ArquivoVideo(uuid: 'uuid-video-multi'),
            ),
          ),
          Resposta(
            midia: ReferenciaMidia(
              documento: ArquivoDocumento(
                uuid: 'uuid-doc-multi',
                nomeOriginal: 'ensaios.pdf',
                quantidadePaginas: 1,
              ),
            ),
          ),
        ],
      ),
    );

    final registroMulti = Registro()
      ..idProtocolo = 'cadastro_material'
      ..respostas['etapa_midias'] = respostaMulti;

    await sessionManager.saveManifest(
      sessionId: 'sessao-multi-midia',
      binarypb: Uint8List.fromList(registroMulti.writeToBuffer()),
    );

    final outPath = '${tempDir.path}/relatorio_multi.epub';
    await notifier.startGeneration(
      'Cadastro Multi Mídias',
      outPath,
      sessionId: 'sessao-multi-midia',
    );

    expect(notifier.state.isComplete, isTrue);
    expect(mediaService.fotosSolicitadas, contains('uuid-foto-multi'));
    expect(mediaService.videosSolicitados, contains('uuid-video-multi'));
    expect(mediaService.documentosSolicitados, contains('uuid-doc-multi'));
  });
}
