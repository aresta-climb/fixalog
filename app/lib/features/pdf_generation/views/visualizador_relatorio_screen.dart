// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/core/services/epub_extrator_service.dart';
import 'package:fixalog/core/services/servico_telemetria.dart';
import 'package:fixalog/core/services/sincronizador_nuvem_service.dart';

/// Tela para visualização no aplicativo do relatório técnico de manutenção gerado em EPUB 3 (XHTML responsivo).
///
/// Consome os arquivos descompactados do container EPUB 3 em cache local,
/// permitindo a reprodução de mídias (fotos e vídeos) via WebView,
/// além de oferecer compartilhamento seguro do link público web (após upload retomável
/// em blocos e verificação de moderação no servidor) e exportação do arquivo `.epub` assinado.
class VisualizadorRelatorioScreen extends ConsumerStatefulWidget {
  final String? caminhoEpub;
  final String? caminhoPdf;
  final String? caminhoXhtml;
  final String? idSessao;
  final String titulo;
  final EpubExtratorService? extratorService;
  final SessionBundleManager? sessionManager;
  final BancoDadosLocal? bancoDados;
  final SincronizadorNuvemService? sincronizadorNuvem;
  final Future<void> Function(
    List<String> paths, {
    String? text,
    String? subject,
  }) compartilharArquivosProxy;
  final Future<void> Function(String path) abrirArquivoProxy;
  final void Function(Future<bool> Function(String url) tratarUrl)?
      aoRegistrarTratadorUrl;
  final Widget Function(BuildContext context, String caminhoXhtml)
      webViewBuilder;

  const VisualizadorRelatorioScreen({
    super.key,
    this.caminhoEpub,
    this.caminhoPdf,
    this.caminhoXhtml,
    this.idSessao,
    this.titulo = 'Relatório Técnico',
    this.extratorService,
    this.sessionManager,
    this.bancoDados,
    this.sincronizadorNuvem,
    Future<void> Function(List<String> paths, {String? text, String? subject})?
        compartilharArquivosProxy,
    Future<void> Function(String path)? abrirArquivoProxy,
    this.aoRegistrarTratadorUrl,
    Widget Function(BuildContext context, String caminhoXhtml)? webViewBuilder,
  })  : compartilharArquivosProxy =
            compartilharArquivosProxy ?? compartilharPadrao,
        abrirArquivoProxy = abrirArquivoProxy ?? abrirArquivoPadrao,
        webViewBuilder = webViewBuilder ?? construirWebViewPadrao;

  /// Executor estático padrão para `SharePlus` (substituível em testes para evitar chamadas nativas do SO).
  static Future<Object?> Function(ShareParams) executorSharePlus =
      SharePlus.instance.share;

  /// Executor estático padrão para `OpenFilex` (substituível em testes para evitar chamadas nativas do SO).
  static Future<Object?> Function(String) executorOpenFilex = OpenFilex.open;

  /// Implementação padrão de compartilhamento via `SharePlus`.
  static Future<void> compartilharPadrao(
    List<String> paths, {
    String? text,
    String? subject,
  }) async {
    await executorSharePlus(
      ShareParams(
        files: paths.isEmpty ? null : paths.map(XFile.new).toList(),
        text: text,
        subject: subject,
      ),
    );
  }

  /// Implementação padrão de abertura externa via `OpenFilex`.
  static Future<void> abrirArquivoPadrao(String path) async {
    await executorOpenFilex(path);
  }

  /// Construtor padrão de `WebViewWidget` carregando o arquivo XHTML local.
  static Widget construirWebViewPadrao(
    BuildContext context,
    String caminhoXhtml,
  ) => WebViewWidget(controller: WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..loadFile(caminhoXhtml));

  @override
  ConsumerState<VisualizadorRelatorioScreen> createState() =>
      _VisualizadorRelatorioScreenState();
}

class _VisualizadorRelatorioScreenState
    extends ConsumerState<VisualizadorRelatorioScreen> {
  bool _carregando = true;
  String? _mensagemErro;
  String? _caminhoXhtmlFinal;
  ProgressoPublicacaoLaudo? _progressoUpload;
  Widget? _webViewConstruido;

  @override
  void initState() {
    super.initState();
    _carregarRelatorio();
  }

  Future<void> _carregarRelatorio() async {
    setState(() {
      _carregando = true;
      _mensagemErro = null;
      _webViewConstruido = null;
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

  String _obterIdSessaoEfetivo() {
    if (widget.idSessao != null && widget.idSessao!.trim().isNotEmpty) {
      return widget.idSessao!.trim();
    }
    return p.basenameWithoutExtension(
      widget.caminhoEpub ?? _caminhoXhtmlFinal ?? 'relatorio',
    );
  }

  Future<void> _compartilharEpub() async {
    if (widget.caminhoEpub == null) return;
    unawaited(
      ServicoTelemetria.instancia.registrarAcaoVisualizadorRelatorio(
        acao: 'exportar_epub',
        idSessao: _obterIdSessaoEfetivo(),
      ),
    );
    try {
      await widget.compartilharArquivosProxy(
        [widget.caminhoEpub!],
        subject: 'Relatório Técnico Fixalog (EPUB 3)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar EPUB: $e')),
        );
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

    await widget.abrirArquivoProxy(caminhoAlvo);
    return true;
  }

  Future<void> _abrirExternamente() async {
    final alvo = widget.caminhoEpub ?? _caminhoXhtmlFinal;
    if (alvo == null) return;
    unawaited(
      ServicoTelemetria.instancia.registrarAcaoVisualizadorRelatorio(
        acao: 'abrir_externo',
        idSessao: _obterIdSessaoEfetivo(),
      ),
    );

    try {
      await widget.abrirArquivoProxy(alvo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir aplicativo externo: $e')),
        );
      }
    }
  }

  Future<void> _compartilharLinkPublicoComVerificacao() async {
    final idSessao = _obterIdSessaoEfetivo();
    unawaited(
      ServicoTelemetria.instancia.registrarAcaoVisualizadorRelatorio(
        acao: 'compartilhar_link_web',
        idSessao: idSessao,
      ),
    );
    final SincronizadorNuvemService sincronizador =
        widget.sincronizadorNuvem ?? ref.read(sincronizadorNuvemServiceProvider);

    setState(() {
      _progressoUpload =
          sincronizador.obterProgressoAtual(idSessao) ??
          ProgressoPublicacaoLaudo(
            idSessao: idSessao,
            etapa: EtapaPublicacaoLaudo.enviandoBlocos,
            blocosEnviados: 0,
            totalBlocos: 1,
          );
    });

    final resultado = await sincronizador.publicarEAguardarLiberacao(
      idSessao: idSessao,
      epubPath: widget.caminhoEpub,
      aoProgredir: (p) {
        if (mounted) {
          setState(() {
            _progressoUpload =
                p.etapa == EtapaPublicacaoLaudo.concluidoAtivo ? null : p;
          });
        }
      },
    );

    if (!mounted) return;

    if (resultado.etapa != EtapaPublicacaoLaudo.concluidoAtivo) {
      setState(() {
        _progressoUpload = resultado;
      });
      return;
    }

    setState(() {
      _progressoUpload = null;
    });

    Uint8List? epubBytes;
    if (widget.caminhoEpub != null && File(widget.caminhoEpub!).existsSync()) {
      epubBytes = File(widget.caminhoEpub!).readAsBytesSync();
    }

    final textoCompartilhamento =
        SincronizadorNuvemService.construirResumoCompartilhamento(
          idSessao: idSessao,
          titulo: widget.titulo,
          epubBytes: epubBytes,
        );

    try {
      await widget.compartilharArquivosProxy(
        const [],
        text: textoCompartilhamento,
        subject: widget.titulo,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar link web: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ResolvedorIdioma.obterLocaleEfetivo(context, ref);
    final l10n = ResolvedorIdioma.obterTraducoes(locale);
    final ehPt = locale.languageCode == 'pt';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          IconButton(
            key: const Key('btn_appbar_compartilhar'),
            icon: const Icon(Icons.share),
            tooltip: ehPt ? 'Compartilhar' : l10n.visualizadorBotaoCompartilhar,
            onPressed: _compartilharLinkPublicoComVerificacao,
          ),
          if (widget.caminhoEpub != null)
            IconButton(
              key: const Key('btn_appbar_exportar_epub'),
              icon: const Icon(Icons.menu_book_outlined),
              tooltip: ehPt ? 'Exportar arquivo EPUB' : l10n.visualizadorAbaEpub,
              onPressed: _compartilharEpub,
            ),
          IconButton(
            key: const Key('btn_appbar_abrir_externo'),
            icon: const Icon(Icons.open_in_new),
            tooltip: ehPt
                ? 'Abrir Externamente'
                : l10n.visualizadorBotaoAbrirExterno,
            onPressed: _abrirExternamente,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_progressoUpload != null)
            _buildModalProgressoUpload(_progressoUpload!),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(ehPt: ehPt, l10n: l10n),
    );
  }

  Widget _buildModalProgressoUpload(ProgressoPublicacaoLaudo progresso) {
    final bool ehSemInternet =
        progresso.etapa == EtapaPublicacaoLaudo.semInternet;
    final bool ehFalha =
        progresso.etapa == EtapaPublicacaoLaudo.rejeitadoOuFalha;
    final bool etapa1Concluida =
        progresso.etapa == EtapaPublicacaoLaudo.aguardandoVerificacaoServidor ||
        progresso.etapa == EtapaPublicacaoLaudo.concluidoAtivo;

    return Stack(
      children: [
        const ModalBarrier(color: Colors.black54, dismissible: false),
        Center(
          child: AlertDialog(
            key: const Key('modal_progresso_upload_laudo'),
            title: Text(
              ehSemInternet
                  ? 'Sem conexão com a internet'
                  : (ehFalha
                        ? 'Verificação pendente'
                        : 'Publicando laudo no Fixalog'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ehSemInternet)
                  const Text(
                    'É necessária conexão com a internet para publicar o laudo na nuvem e gerar o link de compartilhamento. O envio continuará automaticamente em segundo plano assim que houver sinal.',
                  )
                else if (ehFalha)
                  Text(
                    progresso.mensagemErro ??
                        'Não foi possível concluir a verificação do laudo no servidor.',
                  )
                else ...[
                  Row(
                    children: [
                      Icon(
                        etapa1Concluida
                            ? Icons.check_circle
                            : Icons.cloud_upload_outlined,
                        color: etapa1Concluida
                            ? Colors.green
                            : const Color(0xFFFF6B00),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '1. Enviando blocos do laudo (${progresso.blocosEnviados}/${progresso.totalBlocos})',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: etapa1Concluida ? 1.0 : progresso.fracaoBlocos,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (etapa1Concluida)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      else
                        const Icon(
                          Icons.verified_user_outlined,
                          color: Colors.grey,
                        ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '2. Verificando integridade e mídias no servidor',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              if (ehSemInternet || ehFalha)
                TextButton(
                  key: const Key('btn_fechar_modal_upload'),
                  onPressed: () {
                    setState(() {
                      _progressoUpload = null;
                    });
                  },
                  child: const Text('FECHAR'),
                ),
            ],
          ),
        ),
      ],
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

    return _webViewConstruido ??= widget.webViewBuilder(
      context,
      _caminhoXhtmlFinal!,
    );
  }

  Widget _buildBottomBar({
    required bool ehPt,
    required AppLocalizations l10n,
  }) {
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
                label: Text(
                  l10n.visualizadorBotaoCompartilhar,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                onPressed: _compartilharLinkPublicoComVerificacao,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              key: const Key('btn_abrir_externo'),
              icon: const Icon(Icons.open_in_new),
              tooltip: ehPt
                  ? 'Abrir em app externo'
                  : l10n.visualizadorBotaoAbrirExterno,
              onPressed: _abrirExternamente,
            ),
          ],
        ),
      ),
    );
  }
}
