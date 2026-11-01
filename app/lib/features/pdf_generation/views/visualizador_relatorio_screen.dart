// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:isar_community/isar.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/core/services/epub_document_builder.dart';
import 'package:fixalog/core/services/pdf_print_summary_service.dart';
import 'package:fixalog/core/services/epub_extrator_service.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart'
    show isarProvider;

/// Tela para visualização no aplicativo do relatório técnico de manutenção gerado em EPUB 3 (XHTML responsivo).
///
/// Consome os arquivos descompactados do container EPUB 3 em cache local,
/// permitindo a reprodução de mídias (fotos e vídeos) via WebView,
/// além de oferecer opções de compartilhamento do arquivo `.epub` canônico e do `.pdf` resumido gerado sob demanda.
class VisualizadorRelatorioScreen extends ConsumerStatefulWidget {
  final String? caminhoEpub;
  final String? caminhoPdf;
  final String? caminhoXhtml;
  final String? idSessao;
  final String titulo;
  final EpubExtratorService? extratorService;
  final PdfPrintSummaryService? pdfSummaryService;
  final SessionBundleManager? sessionManager;
  final Isar? isar;
  final Future<void> Function(List<String> paths, {String? text, String? subject})?
      compartilharArquivosProxy;
  final Future<void> Function(String path)? abrirArquivoProxy;
  final void Function(Future<bool> Function(String url) tratarUrl)?
      aoRegistrarTratadorUrl;
  final Widget Function(BuildContext context, String caminhoXhtml)? webViewBuilder;
  final Future<String> Function({
    required String? caminhoEpub,
    required String? caminhoXhtml,
    required String? idSessao,
  })? geradorPdfSobDemandaProxy;

  const VisualizadorRelatorioScreen({
    super.key,
    this.caminhoEpub,
    this.caminhoPdf,
    this.caminhoXhtml,
    this.idSessao,
    this.titulo = 'Relatório Técnico',
    this.extratorService,
    this.pdfSummaryService,
    this.sessionManager,
    this.isar,
    this.compartilharArquivosProxy,
    this.abrirArquivoProxy,
    this.aoRegistrarTratadorUrl,
    this.webViewBuilder,
    this.geradorPdfSobDemandaProxy,
  });

  @override
  ConsumerState<VisualizadorRelatorioScreen> createState() =>
      _VisualizadorRelatorioScreenState();
}

class _VisualizadorRelatorioScreenState
    extends ConsumerState<VisualizadorRelatorioScreen> {
  bool _carregando = true;
  bool _gerandoPdf = false;
  String? _mensagemErro;
  String? _caminhoXhtmlFinal;
  String? _caminhoPdfFinal;
  WebViewController? _webViewController;

  Isar? _isar;

  @override
  void initState() {
    super.initState();
    _caminhoPdfFinal = widget.caminhoPdf;
    _carregarRelatorio();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.isar != null) {
      _isar = widget.isar;
    } else {
      try {
        _isar = ref.read(isarProvider);
      } catch (_) {
        _isar = null;
      }
    }
  }

  Future<void> _carregarRelatorio() async {
    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });

    try {
      if (widget.caminhoXhtml != null && widget.caminhoXhtml!.isNotEmpty) {
        _caminhoXhtmlFinal = widget.caminhoXhtml;
      } else if (widget.caminhoEpub != null &&
          widget.caminhoEpub!.isNotEmpty) {
        final extrator = widget.extratorService ?? EpubExtratorService();
        _caminhoXhtmlFinal = await extrator.extrairEpub(
          caminhoEpub: widget.caminhoEpub!,
        );
      } else {
        throw ArgumentError(
          'Nenhum caminho de arquivo EPUB ou XHTML informado para visualização.',
        );
      }

      if (widget.webViewBuilder == null && _caminhoXhtmlFinal != null) {
        _webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadFile(_caminhoXhtmlFinal!);
      }

      widget.aoRegistrarTratadorUrl?.call(_tratarCliqueUrlRelatorio);

      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _mensagemErro = e.toString();
        });
      }
    }
  }

  Future<void> _compartilharEpub() async {
    if (widget.caminhoEpub == null) return;
    try {
      if (widget.compartilharArquivosProxy != null) {
        await widget.compartilharArquivosProxy!(
          [widget.caminhoEpub!],
          subject: 'Relatório Técnico Fixalog (EPUB 3)',
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(widget.caminhoEpub!)],
            subject: 'Relatório Técnico Fixalog (EPUB 3)',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar EPUB: $e')),
        );
      }
    }
  }

  Future<String?> _gerarPdfSobDemanda() async {
    if (!mounted) return null;

    setState(() {
      _gerandoPdf = true;
    });

    try {
      final String novoPdf;
      if (widget.geradorPdfSobDemandaProxy != null) {
        novoPdf = await widget.geradorPdfSobDemandaProxy!(
          caminhoEpub: widget.caminhoEpub,
          caminhoXhtml: _caminhoXhtmlFinal ?? widget.caminhoXhtml,
          idSessao: widget.idSessao,
        );
      } else {
        novoPdf = await _executarGeracaoPdfPadrao();
      }

      _caminhoPdfFinal = novoPdf;
      return novoPdf;
    } finally {
      if (mounted) {
        setState(() {
          _gerandoPdf = false;
        });
      }
    }
  }

  Future<bool> _tratarCliqueUrlRelatorio(String url) async {
    final semQuery = url.split('?').first.split('#').first;
    if (!semQuery.toLowerCase().endsWith('.pdf')) {
      return false;
    }

    String caminhoAlvo = semQuery;
    if (semQuery.startsWith('file://')) {
      caminhoAlvo = Uri.parse(semQuery).toFilePath();
    } else if (_caminhoXhtmlFinal != null && !p.isAbsolute(semQuery)) {
      caminhoAlvo = p.normalize(
        p.join(File(_caminhoXhtmlFinal!).parent.path, semQuery),
      );
    }

    if (widget.abrirArquivoProxy != null) {
      await widget.abrirArquivoProxy!(caminhoAlvo);
    } else {
      await OpenFilex.open(caminhoAlvo);
    }
    return true;
  }

  void _coletarUuidsMidia(
    Registro reg,
    Set<String> fotosUuids,
    Set<String> videosUuids,
    Map<String, ArquivoDocumento> documentosPorUuid,
  ) {
    for (final resp in reg.respostas.values) {
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
    for (final grupo in reg.listas) {
      for (final resp in grupo.respostasItem.values) {
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
    }
  }

  Future<({Map<String, String> midiasDataUri, Map<String, String> posterDataUri})>
      _carregarMidiasDataUri({
    required Registro registro,
    required String idSessaoAlvo,
    required SessionBundleManager sessionManager,
    Directory? oebpsDirAlvo,
  }) async {
    final Set<String> fotosUuids = {};
    final Set<String> videosUuids = {};
    final Map<String, ArquivoDocumento> documentosPorUuid = {};
    _coletarUuidsMidia(
      registro,
      fotosUuids,
      videosUuids,
      documentosPorUuid,
    );

    final Map<String, String> midiasDataUri = {};
    final Map<String, String> posterDataUri = {};

    Future<Uint8List?> lerBytesWebpPorChave(String chaveMidia) async {
      final thumbPath = await sessionManager.getMediaFilePath(
        sessionId: idSessaoAlvo,
        mediaUuid: '${chaveMidia}_thumb',
        extension: '.webp',
      );
      final thumbFile = File(thumbPath);
      if (thumbFile.existsSync()) {
        return thumbFile.readAsBytesSync();
      }

      final mainPath = await sessionManager.getMediaFilePath(
        sessionId: idSessaoAlvo,
        mediaUuid: chaveMidia,
        extension: '.webp',
      );
      final mainFile = File(mainPath);
      if (mainFile.existsSync()) {
        return mainFile.readAsBytesSync();
      }

      if (oebpsDirAlvo != null) {
        final imgEpub =
            File(p.join(oebpsDirAlvo.path, 'midias', '$chaveMidia.webp'));
        if (imgEpub.existsSync()) {
          return imgEpub.readAsBytesSync();
        }
      }
      return null;
    }

    for (final uuid in fotosUuids) {
      final bytes = await lerBytesWebpPorChave(uuid);
      if (bytes != null) {
        midiasDataUri[uuid] = 'data:image/webp;base64,${base64Encode(bytes)}';
      }
    }

    for (final doc in documentosPorUuid.values) {
      final limitePaginas =
          doc.quantidadePaginas > 0 ? doc.quantidadePaginas : 999;
      for (var i = 1; i <= limitePaginas; i++) {
        final chavePagina = '${doc.uuid}_p$i';
        final bytes = await lerBytesWebpPorChave(chavePagina);
        if (bytes != null) {
          midiasDataUri[chavePagina] =
              'data:image/webp;base64,${base64Encode(bytes)}';
        } else if (doc.quantidadePaginas == 0) {
          break;
        }
      }
    }

    for (final uuid in videosUuids) {
      Uint8List? bytes;

      final posterPath = await sessionManager.getMediaFilePath(
        sessionId: idSessaoAlvo,
        mediaUuid: '${uuid}_poster',
        extension: '.webp',
      );
      final posterFile = File(posterPath);
      if (posterFile.existsSync()) {
        bytes = posterFile.readAsBytesSync();
      }

      if (bytes == null && oebpsDirAlvo != null) {
        final posterEpub =
            File(p.join(oebpsDirAlvo.path, 'midias', '${uuid}_poster.webp'));
        if (posterEpub.existsSync()) {
          bytes = posterEpub.readAsBytesSync();
        }
      }

      if (bytes != null) {
        posterDataUri[uuid] = 'data:image/webp;base64,${base64Encode(bytes)}';
      }
    }

    return (midiasDataUri: midiasDataUri, posterDataUri: posterDataUri);
  }

  Future<String> _executarGeracaoPdfPadrao() async {
    final sessionManager = widget.sessionManager ?? SessionBundleManager();
    final isar = _isar;

    String? sid = widget.idSessao;
    SubmissionRecord? record;

    if (isar != null) {
      if (sid != null && sid.isNotEmpty) {
        try {
          record = await isar.submissionRecords
              .filter()
              .idSessaoEqualTo(sid)
              .findFirst();
        } catch (_) {}
      }
      if (record == null && widget.caminhoEpub != null) {
        try {
          record = await isar.submissionRecords
              .filter()
              .protobufPathEqualTo(widget.caminhoEpub!)
              .findFirst();
          if (record != null && (sid == null || sid.isEmpty)) {
            sid = record.idSessao;
          }
        } catch (_) {}
      }
    }

    if (sid == null || sid.isEmpty) {
      if (widget.caminhoEpub != null) {
        sid = p.basenameWithoutExtension(widget.caminhoEpub!);
      } else {
        sid = DateTime.now().millisecondsSinceEpoch.toString();
      }
    }

    Directory? oebpsDir;
    Registro? registro;
    if (_caminhoXhtmlFinal != null) {
      oebpsDir = File(_caminhoXhtmlFinal!).parent;
      final pbFile = File(p.join(oebpsDir.path, 'dados', 'registro.binarypb'));
      if (pbFile.existsSync()) {
        try {
          final bytes = pbFile.readAsBytesSync();
          registro = Registro.fromBuffer(bytes);
        } catch (_) {}
      }
    }

    if (registro == null) {
      try {
        final bytes = await sessionManager.readManifest(sessionId: sid);
        registro = Registro.fromBuffer(bytes);
      } catch (_) {}
    }

    registro ??= (Registro()..idProtocolo = widget.titulo);

    final midiasPrincipais = await _carregarMidiasDataUri(
      registro: registro,
      idSessaoAlvo: sid,
      sessionManager: sessionManager,
      oebpsDirAlvo: oebpsDir,
    );

    // Coletar materiais embutidos em OEBPS/materiais/<uuid>/ ou referenciados no Registro
    final Set<String> uuidsMateriais = {
      ...EpubDocumentBuilder.extrairUuidsMateriaisReferenciados(registro),
    };
    if (oebpsDir != null) {
      final dirMateriais = Directory(p.join(oebpsDir.path, 'materiais'));
      if (dirMateriais.existsSync()) {
        for (final entidade in dirMateriais.listSync()) {
          if (entidade is Directory) {
            uuidsMateriais.add(p.basename(entidade.path));
          }
        }
      }
    }

    final List<RelatorioMaterialAnexo> materiaisAnexos = [];
    for (final uuidMat in uuidsMateriais) {
      if (uuidMat == sid) continue;

      Directory? oebpsMatDir;
      Registro? regMat;

      if (oebpsDir != null) {
        final candidatoOebpsMat =
            Directory(p.join(oebpsDir.path, 'materiais', uuidMat, 'OEBPS'));
        final pbMatFile = File(
          p.join(candidatoOebpsMat.path, 'dados', 'registro.binarypb'),
        );
        if (pbMatFile.existsSync()) {
          oebpsMatDir = candidatoOebpsMat;
          try {
            regMat = Registro.fromBuffer(pbMatFile.readAsBytesSync());
          } catch (_) {}
        }
      }

      if (regMat == null) {
        try {
          final bytesMat = await sessionManager.readManifest(sessionId: uuidMat);
          regMat = Registro.fromBuffer(bytesMat);
        } catch (_) {}
      }

      if (regMat != null) {
        final midiasMat = await _carregarMidiasDataUri(
          registro: regMat,
          idSessaoAlvo: uuidMat,
          sessionManager: sessionManager,
          oebpsDirAlvo: oebpsMatDir,
        );
        materiaisAnexos.add(
          RelatorioMaterialAnexo(
            idSessao: uuidMat,
            registro: regMat,
            urlCanonica: 'https://fixalog.app/v/$uuidMat',
            mapeamentoMidias: midiasMat.midiasDataUri,
            posterFrames: midiasMat.posterDataUri,
          ),
        );
      }
    }

    final pdfService = widget.pdfSummaryService ?? PdfPrintSummaryService();
    final caminhoPdfSaida =
        await sessionManager.getReportFilePath(sessionId: sid);
    final urlCanonica = 'https://fixalog.app/v/$sid';

    final pdfFile = await pdfService.exportarPdfResumido(
      caminhoSaida: caminhoPdfSaida,
      registro: registro,
      idSessao: sid,
      urlCanonica: urlCanonica,
      mapeamentoMidias: midiasPrincipais.midiasDataUri,
      posterFrames: midiasPrincipais.posterDataUri,
      materiaisAnexos: materiaisAnexos,
    );

    if (isar != null) {
      record ??= await isar.submissionRecords
          .filter()
          .idSessaoEqualTo(sid)
          .findFirst();
      if (record != null) {
        record.pdfPath = pdfFile.path;
        await isar.writeTxn(() async {
          await isar.submissionRecords.put(record!);
        });
      }
    }

    return pdfFile.path;
  }

  Future<void> _compartilharPdf() async {
    String? caminhoPdf = _caminhoPdfFinal ?? widget.caminhoPdf;

    if (caminhoPdf == null || caminhoPdf.isEmpty) {
      try {
        caminhoPdf = await _gerarPdfSobDemanda();
        if (caminhoPdf == null) return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao gerar PDF resumido: $e')),
          );
        }
        return;
      }
    }

    try {
      if (widget.compartilharArquivosProxy != null) {
        await widget.compartilharArquivosProxy!(
          [caminhoPdf],
          subject: 'Relatório Técnico Resumido Fixalog (PDF)',
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(caminhoPdf)],
            subject: 'Relatório Técnico Resumido Fixalog (PDF)',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar PDF: $e')),
        );
      }
    }
  }

  Future<void> _abrirExternamente() async {
    final alvo = widget.caminhoEpub ??
        _caminhoPdfFinal ??
        widget.caminhoPdf ??
        _caminhoXhtmlFinal;
    if (alvo == null) return;

    try {
      if (widget.abrirArquivoProxy != null) {
        await widget.abrirArquivoProxy!(alvo);
      } else {
        await OpenFilex.open(alvo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir aplicativo externo: $e')),
        );
      }
    }
  }

  Future<void> _mostrarModalCompartilhamento(BuildContext context) async {
    final opcao = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Compartilhar Relatório',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                ListTile(
                  key: const Key('opcao_compartilhar_epub'),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.menu_book, color: Colors.green),
                  ),
                  title: const Text('Relatório Completo (EPUB)'),
                  subtitle: const Text(
                    'Com vídeos em alta definição, fotos e dados canônicos assinados',
                  ),
                  enabled: widget.caminhoEpub != null,
                  onTap: widget.caminhoEpub != null
                      ? () => Navigator.of(modalContext).pop('epub')
                      : null,
                ),
                ListTile(
                  key: const Key('opcao_compartilhar_pdf'),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF3E0),
                    child: Icon(Icons.picture_as_pdf, color: Color(0xFFFF6B00)),
                  ),
                  title: const Text('Versão Resumida (PDF)'),
                  subtitle: const Text(
                    'Para impressão rápida e protocolo com QR Codes',
                  ),
                  enabled: true,
                  onTap: () => Navigator.of(modalContext).pop('pdf'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (opcao == 'epub') {
      await _compartilharEpub();
    } else if (opcao == 'pdf') {
      await _compartilharPdf();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          IconButton(
            key: const Key('btn_appbar_compartilhar'),
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar',
            onPressed: () => _mostrarModalCompartilhamento(context),
          ),
          IconButton(
            key: const Key('btn_appbar_abrir_externo'),
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Abrir Externamente',
            onPressed: _abrirExternamente,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_gerandoPdf) ...[
            const ModalBarrier(
              color: Colors.black54,
              dismissible: false,
            ),
            const Center(
              child: AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Expanded(
                      child: Text('Gerando PDF resumido...'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando relatório...'),
          ],
        ),
      );
    }

    if (_mensagemErro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 54),
              const SizedBox(height: 16),
              Text(
                'Não foi possível carregar o relatório:\n$_mensagemErro',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _carregarRelatorio,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.webViewBuilder != null) {
      return widget.webViewBuilder!(context, _caminhoXhtmlFinal!);
    }

    if (_webViewController != null) {
      return WebViewWidget(controller: _webViewController!);
    }

    return const Center(child: Text('Nenhum visualizador disponível.'));
  }

  Widget? _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('btn_compartilhar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.share, size: 20),
                label: const Text(
                  'COMPARTILHAR',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                onPressed: () => _mostrarModalCompartilhamento(context),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              key: const Key('btn_abrir_externo'),
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Abrir em app externo',
              onPressed: _abrirExternamente,
            ),
          ],
        ),
      ),
    );
  }
}
