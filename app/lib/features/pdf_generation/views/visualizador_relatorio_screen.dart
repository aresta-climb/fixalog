// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fixlog/core/services/epub_extrator_service.dart';

/// Tela para visualização no aplicativo do relatório técnico de manutenção gerado em EPUB 3 (XHTML responsivo).
///
/// Consome os arquivos descompactados do container EPUB 3 em cache local,
/// permitindo a reprodução de mídias (fotos e vídeos) via WebView,
/// além de oferecer opções de compartilhamento do arquivo `.epub` canônico e do `.pdf` resumido.
class VisualizadorRelatorioScreen extends StatefulWidget {
  final String? caminhoEpub;
  final String? caminhoPdf;
  final String? caminhoXhtml;
  final String titulo;
  final EpubExtratorService? extratorService;
  final Future<void> Function(List<String> paths, {String? text, String? subject})?
      compartilharArquivosProxy;
  final Future<void> Function(String path)? abrirArquivoProxy;
  final Widget Function(BuildContext context, String caminhoXhtml)? webViewBuilder;

  const VisualizadorRelatorioScreen({
    super.key,
    this.caminhoEpub,
    this.caminhoPdf,
    this.caminhoXhtml,
    this.titulo = 'Relatório Técnico',
    this.extratorService,
    this.compartilharArquivosProxy,
    this.abrirArquivoProxy,
    this.webViewBuilder,
  });

  @override
  State<VisualizadorRelatorioScreen> createState() =>
      _VisualizadorRelatorioScreenState();
}

class _VisualizadorRelatorioScreenState
    extends State<VisualizadorRelatorioScreen> {
  bool _carregando = true;
  String? _mensagemErro;
  String? _caminhoXhtmlFinal;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _carregarRelatorio();
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
          subject: 'Relatório Técnico FixLog (EPUB 3)',
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(widget.caminhoEpub!)],
            subject: 'Relatório Técnico FixLog (EPUB 3)',
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

  Future<void> _compartilharPdf() async {
    if (widget.caminhoPdf == null) return;
    try {
      if (widget.compartilharArquivosProxy != null) {
        await widget.compartilharArquivosProxy!(
          [widget.caminhoPdf!],
          subject: 'Relatório Técnico Resumido FixLog (PDF)',
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(widget.caminhoPdf!)],
            subject: 'Relatório Técnico Resumido FixLog (PDF)',
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
    final alvo = widget.caminhoEpub ?? widget.caminhoPdf ?? _caminhoXhtmlFinal;
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

  void _mostrarModalCompartilhamento(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      ? () {
                          Navigator.of(modalContext).pop();
                          _compartilharEpub();
                        }
                      : null,
                ),
                ListTile(
                  key: const Key('opcao_compartilhar_pdf'),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF3E0),
                    child: Icon(Icons.picture_as_pdf, color: Color(0xFFFF6B00)),
                  ),
                  title: const Text('Versão Resumida (PDF)'),
                  subtitle: Text(
                    widget.caminhoPdf != null
                        ? 'Para impressão rápida e protocolo com QR Codes'
                        : 'Versão em PDF não gerada para este relatório',
                  ),
                  enabled: widget.caminhoPdf != null,
                  onTap: widget.caminhoPdf != null
                      ? () {
                          Navigator.of(modalContext).pop();
                          _compartilharPdf();
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
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
      body: _buildBody(),
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
