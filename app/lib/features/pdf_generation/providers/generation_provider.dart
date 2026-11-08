// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixalog/features/media/services/media_compressor_service.dart';
import 'package:fixalog/features/pdf_generation/services/generation_recovery_service.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/core/services/construtor_arvore_relatorio.dart';
import 'package:fixalog/core/services/epub_document_builder.dart';
import 'package:fixalog/core/services/epub_packager_service.dart';
import 'package:fixalog/core/services/xml_dsig_signer.dart';
import 'package:fixalog/core/services/pdf_print_summary_service.dart';
import 'package:fixalog/core/services/crypto_service.dart';
import 'package:fixalog/core/services/providers.dart';
import 'package:fixalog/features/pdf_generation/services/pdf_draft_service.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';

// Estado da Geração
class GenerationState {
  final double progress;
  final String status;
  final bool isComplete;
  final bool hasError;
  final String? errorMessage;
  final String? outputPath;
  final String? epubPath;
  final String? pdfPath;

  GenerationState({
    this.progress = 0.0,
    this.status = 'Iniciando...',
    this.isComplete = false,
    this.hasError = false,
    this.errorMessage,
    this.outputPath,
    this.epubPath,
    this.pdfPath,
  });

  GenerationState copyWith({
    double? progress,
    String? status,
    bool? isComplete,
    bool? hasError,
    String? errorMessage,
    String? outputPath,
    String? epubPath,
    String? pdfPath,
  }) {
    return GenerationState(
      progress: progress ?? this.progress,
      status: status ?? this.status,
      isComplete: isComplete ?? this.isComplete,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      outputPath: outputPath ?? this.outputPath,
      epubPath: epubPath ?? this.epubPath,
      pdfPath: pdfPath ?? this.pdfPath,
    );
  }
}

// Notifier do Riverpod
/// Orquestra a esteira completa de geração e assinatura de relatórios de vistoria em Dart puro:
/// - Processamento de mídias (fotos em WebP 4MP q=85 e vídeos em H.264 720p CRF 26 com poster frames).
/// - Construtor de marcação XHTML semântica e CSS responsivo (@media print).
/// - Incorporação de materiais assinados do catálogo local em `OEBPS/materiais/<uuid>/`.
/// - Assinatura digital no padrão W3C XML-DSig (ECDSA secp256r1 com SHA-256 e certificado X.509).
/// - Empacotamento de container canônico EPUB 3 em ZIP/OCF com Protobuf embutido.
/// - Emissão de PDF Resumido de Protocolo com QR Codes.
/// - Persistência do registro de submissão no banco de dados local (SQLite).
class GenerationNotifier extends StateNotifier<GenerationState> {
  // Mantido no construtor para compatibilidade de assinatura nos provedores
  // ignore: unused_field
  final PdfDraftService? _draftService;
  final MediaCompressorService _mediaService;
  final GenerationRecoveryService _recoveryService;
  final SessionBundleManager _sessionManager;
  final BancoDadosLocal? _banco;
  final EpubDocumentBuilder _epubBuilder;
  final EpubPackagerService _epubPackager;
  final XmlDsigSigner _xmlSigner;
  final PdfPrintSummaryService _pdfSummaryService;
  final CryptoService _cryptoService;

  PdfPrintSummaryService get pdfSummaryService => _pdfSummaryService;

  GenerationNotifier(
    this._draftService,
    this._mediaService,
    this._recoveryService,
    this._sessionManager, [
    this._banco,
    EpubDocumentBuilder? epubBuilder,
    EpubPackagerService? epubPackager,
    XmlDsigSigner? xmlSigner,
    PdfPrintSummaryService? pdfSummaryService,
    CryptoService? cryptoService,
  ])  : _epubBuilder = epubBuilder ?? EpubDocumentBuilder(),
        _epubPackager = epubPackager ?? EpubPackagerService(),
        _xmlSigner = xmlSigner ?? XmlDsigSigner(),
        _pdfSummaryService = pdfSummaryService ?? PdfPrintSummaryService(),
        _cryptoService = cryptoService ?? CryptoService(),
        super(GenerationState());

  String? _localizarCaminhoEpubDeRegistro(SubmissionRecord record) {
    if (record.protobufPath.endsWith('.epub') &&
        File(record.protobufPath).existsSync()) {
      return record.protobufPath;
    }
    return null;
  }

  String _extrairTituloExibicaoDoRegistro(
    Registro registro, {
    required String fallback,
  }) {
    return ConstrutorArvoreRelatorio.extrairTituloExibicao(
      registro,
      fallback: fallback,
    );
  }

  /// Inicia a esteira de geração assíncrona do relatório técnico.
  Future<void> startGeneration(
    String title,
    String outputPath, {
    String? sessionId,
  }) async {
    try {
      await _recoveryService.markAsProcessing(true);
      state =
          GenerationState(progress: 0.1, status: 'Lendo dados da sessão...');

      final sid = sessionId ?? DateTime.now().millisecondsSinceEpoch.toString();

      Registro registro;
      if (sessionId != null) {
        final bytes = await _sessionManager.readManifest(sessionId: sessionId);
        registro = Registro.fromBuffer(bytes);
      } else {
        registro = Registro()..idProtocolo = title;
      }

      state = state.copyWith(progress: 0.2, status: 'Processando mídias...');

      // 1. Coletar mídias referenciadas no Registro
      final Set<String> fotosUuids = {};
      final Set<String> videosUuids = {};
      final Map<String, ArquivoDocumento> documentosPorUuid = {};

      final todasRespostas = [
        ...registro.respostas.values,
        ...registro.listas.expand((g) => g.respostasItem.values),
      ];
      for (final resp in todasRespostas) {
        for (final midia in EpubDocumentBuilder.extrairMidiasDeResposta(resp)) {
          if (midia.hasImagem()) {
            fotosUuids.add(midia.imagem.uuid);
          } else if (midia.hasVideo()) {
            videosUuids.add(midia.video.uuid);
          } else if (midia.hasDocumento()) {
            documentosPorUuid[midia.documento.uuid] = midia.documento;
          }
        }
      }

      final totalMidias =
          fotosUuids.length + videosUuids.length + documentosPorUuid.length;
      int processadas = 0;

      final Map<String, List<int>> arquivosMidias = {};
      final Map<String, String> mapeamentoMidias = {};
      final Map<String, String> posterFrames = {};
      final Map<String, String> qrCodesVideos = {};
      final urlCanonica = 'https://fixalog.app/v/$sid';

      // 2. Comprimir Fotos em WebP 4MP q85 (em paralelo; o pool do MediaCompressorService limita a concorrência)
      await Future.wait(
        fotosUuids.map((uuid) async {
          final fotoFile = await _mediaService.comprimirImagemSessao(
            sessionManager: _sessionManager,
            sessionId: sid,
            mediaUuid: uuid,
          );
          if (fotoFile != null && await fotoFile.exists()) {
            final bytes = await fotoFile.readAsBytes();
            arquivosMidias['midias/$uuid.webp'] = bytes;
            mapeamentoMidias[uuid] = 'midias/$uuid.webp';
          }
          processadas++;
          state = state.copyWith(
            progress:
                0.2 + (processadas / (totalMidias > 0 ? totalMidias : 1) * 0.3),
            status: 'Comprimindo fotos e vídeos ($processadas/$totalMidias)...',
          );
        }),
      );

      // 3. Transcodificar Vídeos para H.264 720p CRF 26 + poster frame em JPEG
      for (final uuid in videosUuids) {
        final res = await _mediaService.transcodificarVideoSessao(
          sessionManager: _sessionManager,
          sessionId: sid,
          mediaUuid: uuid,
        );
        if (res.video != null && await res.video!.exists()) {
          final bytes = await res.video!.readAsBytes();
          arquivosMidias['midias/$uuid.mp4'] = bytes;
          mapeamentoMidias[uuid] = 'midias/$uuid.mp4';
        }
        if (res.poster != null && await res.poster!.exists()) {
          final bytes = await res.poster!.readAsBytes();
          arquivosMidias['midias/${uuid}_poster.jpg'] = bytes;
          posterFrames[uuid] = 'midias/${uuid}_poster.jpg';
        }
        final qrSvg = PdfPrintSummaryService.gerarQrCodeSvg('$urlCanonica#video-$uuid');
        qrCodesVideos[uuid] =
            'data:image/svg+xml;utf8,${Uri.encodeComponent(qrSvg)}';

        processadas++;
        state = state.copyWith(
          progress:
              0.2 + (processadas / (totalMidias > 0 ? totalMidias : 1) * 0.3),
          status: 'Transcodificando vídeos ($processadas/$totalMidias)...',
        );
      }

      // 3a. Empacotar Documentos PDF originais e rasterizar páginas WebP em paralelo
      await Future.wait(
        documentosPorUuid.entries.map((entradaDoc) async {
          final uuid = entradaDoc.key;
          final doc = entradaDoc.value;

          final caminhoPdfOriginal = await _sessionManager.getMediaFilePath(
            sessionId: sid,
            mediaUuid: '${uuid}_original',
            extension: '.pdf',
          );
          final pdfOriginalFile = File(caminhoPdfOriginal);
          if (pdfOriginalFile.existsSync()) {
            final bytesPdf = pdfOriginalFile.readAsBytesSync();
            arquivosMidias['midias/$uuid.pdf'] = bytesPdf;
            mapeamentoMidias[uuid] = 'midias/$uuid.pdf';
          }

          final paginasFiles = await _mediaService.rasterizarDocumentoPdfSessao(
            sessionManager: _sessionManager,
            sessionId: sid,
            mediaUuid: uuid,
          );
          for (var i = 0; i < paginasFiles.length; i++) {
            final numPag = i + 1;
            final pagFile = paginasFiles[i];
            if (pagFile.existsSync()) {
              final bytesPag = pagFile.readAsBytesSync();
              arquivosMidias['midias/${uuid}_p$numPag.webp'] = bytesPag;
              mapeamentoMidias['${uuid}_p$numPag'] =
                  'midias/${uuid}_p$numPag.webp';
            }
          }
          if (doc.quantidadePaginas == 0 && paginasFiles.isNotEmpty) {
            doc.quantidadePaginas = paginasFiles.length;
          }

          processadas++;
          state = state.copyWith(
            progress:
                0.2 + (processadas / (totalMidias > 0 ? totalMidias : 1) * 0.3),
            status: 'Processando documentos PDF ($processadas/$totalMidias)...',
          );
        }),
      );

      final epubPath = outputPath.endsWith('.epub')
          ? outputPath
          : outputPath.replaceAll(RegExp(r'\.pdf$'), '.epub');

      // 3b. Resolver materiais do catálogo referenciados na manutenção (com fallback para EPUB anterior)
      final uuidsMateriais =
          EpubDocumentBuilder.extrairUuidsMateriaisReferenciados(registro);
      final Map<String, Map<String, Uint8List>> materiaisAninhados = {};
      final Map<String, String> titulosMateriais = {};

      Map<String, Uint8List>? arquivosEpubAnterior;
      final epubFileExistente = File(epubPath);
      if (uuidsMateriais.isNotEmpty && epubFileExistente.existsSync()) {
        try {
          final bytesAntigos = await epubFileExistente.readAsBytes();
          arquivosEpubAnterior =
              _epubPackager.extrairArquivosDeEpubAninhado(bytesAntigos);
        } catch (_) {}
      }

      for (final uuidMat in uuidsMateriais) {
        if (uuidMat == sid) continue;

        SubmissionRecord? matRecord;
        if (_banco != null) {
          try {
            matRecord = await _banco.obterSubmissaoPorIdSessao(uuidMat);
          } catch (_) {}
        }

        if (matRecord != null) {
          final caminhoEpubMat = _localizarCaminhoEpubDeRegistro(matRecord);
          if (caminhoEpubMat != null) {
            try {
              final bytesMat = await File(caminhoEpubMat).readAsBytes();
              materiaisAninhados[uuidMat] =
                  _epubPackager.extrairArquivosDeEpubAninhado(bytesMat);
              titulosMateriais[uuidMat] =
                  matRecord.tituloExibicao.trim().isNotEmpty
                      ? matRecord.tituloExibicao.trim()
                      : uuidMat;
            } catch (_) {}
          }
        }

        // Fallback para cópia já embutida no EPUB anterior caso o material tenha sido removido do catálogo
        if (!materiaisAninhados.containsKey(uuidMat) &&
            arquivosEpubAnterior != null) {
          final prefixo = 'OEBPS/materiais/$uuidMat/';
          final recuperados = <String, Uint8List>{};
          for (final entradaAntiga in arquivosEpubAnterior.entries) {
            if (entradaAntiga.key.startsWith(prefixo)) {
              recuperados[entradaAntiga.key.substring(prefixo.length)] =
                  entradaAntiga.value;
            }
          }
          if (recuperados.isNotEmpty) {
            materiaisAninhados[uuidMat] = recuperados;
          }
        }

        // Se ainda não temos o título amigável do material, lê do registro.binarypb embutido
        if (!titulosMateriais.containsKey(uuidMat) &&
            materiaisAninhados.containsKey(uuidMat)) {
          final pbBytes =
              materiaisAninhados[uuidMat]!['OEBPS/dados/registro.binarypb']!;
          final regMat = Registro.fromBuffer(pbBytes);
          titulosMateriais[uuidMat] = _extrairTituloExibicaoDoRegistro(
            regMat,
            fallback: uuidMat,
          );
        }
      }

      // 4. Construir Documento EPUB 3
      state =
          state.copyWith(progress: 0.6, status: 'Construindo relatório EPUB 3...');

      String? idiomaPreferido;
      if (_banco != null) {
        try {
          final config = await _banco.obterConfiguracao();
          idiomaPreferido = config?.idiomaPreferido;
        } catch (_) {}
      }
      final codigoIdioma = (idiomaPreferido != null && idiomaPreferido.trim().isNotEmpty)
          ? idiomaPreferido.trim()
          : 'pt-BR';

      final estiloCss = _epubBuilder.gerarCss(codigoIdioma: codigoIdioma);
      final qrPrincipalSvg = PdfPrintSummaryService.gerarQrCodeSvg(urlCanonica);
      final qrPrincipalDataUri =
          'data:image/svg+xml;utf8,${Uri.encodeComponent(qrPrincipalSvg)}';

      final relatorioXhtml = _epubBuilder.gerarXhtml(
        registro: registro,
        idSessao: sid,
        urlCanonica: urlCanonica,
        mapeamentoMidias: mapeamentoMidias,
        posterFrames: posterFrames,
        qrCodesVideos: qrCodesVideos,
        qrCodeCanonica: qrPrincipalDataUri,
        titulosMateriais: titulosMateriais,
        codigoIdioma: idiomaPreferido != null && idiomaPreferido.trim().isNotEmpty
            ? idiomaPreferido.trim()
            : null,
      );

      // 5. Assinatura Digital XML-DSig
      state = state.copyWith(
          progress: 0.7, status: 'Assinando digitalmente com XML-DSig...');
      await _cryptoService.generateAndStoreKeysIfNeeded();
      final privateKeyPem = await _cryptoService.getPrivateKeyPem();
      final publicKeyPem = await _cryptoService.getPublicKeyPem();

      String x509CertPem;
      try {
        final certSalvo = await _cryptoService.obterCertificadoX509Pem();
        if (certSalvo != null && certSalvo.trim().isNotEmpty) {
          x509CertPem = certSalvo;
        } else {
          x509CertPem = await _cryptoService.generateX509Certificate(
            registro.idProtocolo.isNotEmpty
                ? registro.idProtocolo
                : 'Fixalog',
          );
        }
      } catch (_) {
        x509CertPem = publicKeyPem;
      }

      final binarypbBytes = Uint8List.fromList(registro.writeToBuffer());
      final fontesIdioma =
          _epubPackager.obterFontesNotoSansParaIdioma(codigoIdioma);

      final Map<String, List<int>> recursosAssinatura = {
        'OEBPS/relatorio.xhtml': utf8.encode(relatorioXhtml),
        'OEBPS/estilo.css': utf8.encode(estiloCss),
        'OEBPS/dados/registro.binarypb': binarypbBytes,
      };
      for (final entradaFonte in fontesIdioma.entries) {
        recursosAssinatura['OEBPS/${entradaFonte.key}'] = entradaFonte.value;
      }
      final Map<String, Uint8List> arquivosMidiaBytes = {};
      for (final entrada in arquivosMidias.entries) {
        recursosAssinatura['OEBPS/${entrada.key}'] = entrada.value;
        arquivosMidiaBytes[entrada.key] = Uint8List.fromList(entrada.value);
      }
      for (final entradaMat in materiaisAninhados.entries) {
        final uuidMat = entradaMat.key;
        for (final arqMat in entradaMat.value.entries) {
          recursosAssinatura['OEBPS/materiais/$uuidMat/${arqMat.key}'] =
              arqMat.value;
        }
      }

      final atestadoOidcJwt = await _cryptoService.obterAtestadoOidcJwt();
      final signaturesXml = await _xmlSigner.gerarAssinaturaXml(
        arquivos: recursosAssinatura,
        privateKeyPem: privateKeyPem,
        certificadoX509Pem: x509CertPem,
        atestadoOidcJwt: atestadoOidcJwt,
      );

      // 6. Empacotamento do Container EPUB 3
      state = state.copyWith(
          progress: 0.8, status: 'Empacotando container EPUB 3...');

      final epubBytes = _epubPackager.empacotarEpub(
        idSessao: sid,
        idProtocolo: registro.idProtocolo,
        xhtmlConteudo: relatorioXhtml,
        cssConteudo: estiloCss,
        binarypb: binarypbBytes,
        arquivosMidia: arquivosMidiaBytes,
        materiaisAninhados: materiaisAninhados,
        titulosMateriais: titulosMateriais,
        signaturesXml: signaturesXml,
        codigoIdioma: codigoIdioma,
        arquivosFonte: fontesIdioma,
      );

      final epubFile = File(epubPath);
      await epubFile.create(recursive: true);
      await epubFile.writeAsBytes(epubBytes);

      // 7. Gravação no banco local SQLite
      String? pdfExistente;
      final banco = _banco;
      if (banco != null) {
        SubmissionRecord? existingRecord;
        try {
          existingRecord = await banco.obterSubmissaoPorIdSessao(sid);
        } catch (_) {}

        pdfExistente = existingRecord?.pdfPath;
        final ehMaterial = registro.idProtocolo == 'material_registration' ||
            registro.idProtocolo == 'cadastro_material' ||
            (existingRecord?.isMaterial ?? false);
        final tituloExtraido = _extrairTituloExibicaoDoRegistro(
          registro,
          fallback: (existingRecord?.tituloExibicao.isNotEmpty ?? false)
              ? existingRecord!.tituloExibicao
              : title,
        );

        final record = existingRecord ?? SubmissionRecord()
          ..idSessao = sid
          ..idProtocolo = registro.idProtocolo.isNotEmpty
              ? registro.idProtocolo
              : sid
          ..nomeProtocolo = title
          ..dataInclusao = DateTime.now()
          ..enviadoNuvem = false;

        record
          ..pdfPath = pdfExistente ?? ''
          ..protobufPath = epubFile.path
          ..status = SubmissionStatus.gerado
          ..tipoRegistro = ehMaterial
              ? SubmissionTipoRegistro.material
              : SubmissionTipoRegistro.manutencao
          ..tituloExibicao = tituloExtraido;

        await banco.salvarSubmissao(record);
      }

      state = state.copyWith(
        progress: 1.0,
        status: 'Relatório gerado e assinado com sucesso!',
        isComplete: true,
        outputPath: epubFile.path,
        epubPath: epubFile.path,
        pdfPath: pdfExistente,
      );
      await _recoveryService.markAsProcessing(false);
    } catch (e) {
      state = state.copyWith(hasError: true, errorMessage: e.toString());
      await _recoveryService.markAsProcessing(false);
    }
  }
}

// Providers
final draftServiceProvider = Provider((ref) => PdfDraftService());
final generationRecoveryProvider =
    Provider((ref) => GenerationRecoveryService());
final epubDocumentBuilderProvider = Provider((ref) => EpubDocumentBuilder());
final epubPackagerServiceProvider = Provider((ref) => EpubPackagerService());
final xmlDsigSignerProvider = Provider((ref) => XmlDsigSigner());

final generationProvider =
    StateNotifierProvider<GenerationNotifier, GenerationState>((ref) {
  final sessionManager = SessionBundleManager();
  BancoDadosLocal? banco;
  try {
    banco = ref.watch(bancoDadosLocalProvider);
  } catch (_) {}

  return GenerationNotifier(
    ref.read(draftServiceProvider),
    ref.read(mediaCompressorProvider),
    ref.read(generationRecoveryProvider),
    sessionManager,
    banco,
    ref.read(epubDocumentBuilderProvider),
    ref.read(epubPackagerServiceProvider),
    ref.read(xmlDsigSignerProvider),
    ref.read(pdfPrintSummaryServiceProvider),
    ref.read(cryptoServiceProvider),
  );
});
