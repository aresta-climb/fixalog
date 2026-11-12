// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/resolvedor_idioma.dart';
import '../../../core/models/local/app_config_record.dart';
import '../../../core/constantes/versao_legal.g.dart';
import '../../../core/services/banco_dados_local.dart';
import '../../../core/services/servico_telemetria.dart';
import '../../identity/views/identity_setup_screen.dart';
import '../../identity/viewmodels/identity_form_view_model.dart';
import '../../home/views/home_screen.dart';

/// Tela obrigatória de consentimento e aceite dos Termos de Uso e Política de Privacidade do Fixalog.
class TelaTermosDeUso extends ConsumerStatefulWidget {
  final AssetBundle? assetBundle;
  final VoidCallback? aoAceitar;

  const TelaTermosDeUso({
    super.key,
    this.assetBundle,
    this.aoAceitar,
  });

  @override
  ConsumerState<TelaTermosDeUso> createState() => _TelaTermosDeUsoState();
}

class _TelaTermosDeUsoState extends ConsumerState<TelaTermosDeUso> {
  bool _estaCarregando = false;
  bool _concordou = false;
  bool _inicializado = false;
  String? _termosMarkdown;
  String? _politicaMarkdown;
  bool _teveErroCarregamento = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      _inicializado = true;
      _carregarDocumentos();
    }
  }

  Future<String> _carregarArquivoLegal(
    AssetBundle pacote,
    String codigoIdioma,
    String nomeArquivo,
  ) async {
    final candidatos = <String>[
      'legal/repo/public/docs/$codigoIdioma/$nomeArquivo',
      if (codigoIdioma != 'en') 'legal/repo/public/docs/en/$nomeArquivo',
      'legal/repo/public/docs/$nomeArquivo',
    ];
    Object? ultimoErro;
    for (final caminho in candidatos) {
      try {
        return await pacote.loadString(caminho);
      } catch (e) {
        ultimoErro = e;
      }
    }
    throw ultimoErro!;
  }

  Future<void> _carregarDocumentos([String? codigoIdioma]) async {
    try {
      final pacote = widget.assetBundle ?? DefaultAssetBundle.of(context);
      final codigo =
          codigoIdioma ?? ref.read(idiomaAtivoProvider).languageCode;

      final termos = await _carregarArquivoLegal(
        pacote,
        codigo,
        'termos-de-uso-fixalog.md',
      );
      final politica = await _carregarArquivoLegal(
        pacote,
        codigo,
        'politica-de-privacidade-fixalog.md',
      );

      if (mounted) {
        setState(() {
          _termosMarkdown = termos;
          _politicaMarkdown = politica;
          _teveErroCarregamento = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _teveErroCarregamento = true;
        });
      }
    }
  }

  void _abrirModalPoliticaPrivacidade(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF1A1C1E),
      builder: (context) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A1C1E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF121416),
            title: Text(
              l10n.politicaPrivacidadeTitulo,
              style: const TextStyle(fontSize: 16),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: _politicaMarkdown != null
                ? MarkdownBody(
                    data: _politicaMarkdown!,
                    styleSheet: _obterEstiloMarkdown(context),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  void _tratarLink(
    String texto,
    String? link,
    String titulo,
    AppLocalizations l10n,
  ) {
    final linkNormalizado = (link ?? '').toLowerCase().trim();
    if (linkNormalizado == '#privacy-policy' || linkNormalizado.contains('privacidade') || linkNormalizado.contains('privacy')) {
      _abrirModalPoliticaPrivacidade(l10n);
    }
  }

  Future<void> _aoAceitarTermos() async {
    setState(() => _estaCarregando = true);

    try {
      final banco = ref.read(bancoDadosLocalProvider);
      if (banco != null) {
        var config = await banco.obterConfiguracao(1);
        config ??= AppConfigRecord();
        config.acceptedTermsVersion = kVersaoLegal;
        config.dataHoraAceiteTermos = DateTime.now();
        await banco.salvarConfiguracao(config);
      }
      unawaited(
        ServicoTelemetria.instancia.registrarAceiteTermosUso('$kVersaoLegal'),
      );

      if (!mounted) return;

      if (widget.aoAceitar != null) {
        widget.aoAceitar!();
        return;
      }

      final temIdentidade = await ref.read(hasIdentityProvider.future);
      if (!mounted) return;

      if (temIdentidade) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const IdentitySetupScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _estaCarregando = false);
      }
    }
  }

  MarkdownStyleSheet _obterEstiloMarkdown(BuildContext context) {
    return MarkdownStyleSheet(
      p: const TextStyle(
        color: Colors.white70,
        fontSize: 15,
        height: 1.6,
      ),
      h1: const TextStyle(
        color: Color(0xFFFF6B00),
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      h2: const TextStyle(
        color: Color(0xFFFF6B00),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      h3: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      strong: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      a: const TextStyle(
        color: Color(0xFFFF6B00),
        decoration: TextDecoration.underline,
      ),
      blockSpacing: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeAtivo = ref.watch(idiomaAtivoProvider);
    final l10n = ResolvedorIdioma.obterTraducoes(localeAtivo);

    return Scaffold(
      backgroundColor: const Color(0xFF121416),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121416),
        elevation: 0,
        title: Text(
          l10n.termosTituloTela,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            key: const Key('seletor_idioma_termos'),
            tooltip: l10n.seletorIdiomaTitulo,
            color: const Color(0xFF1A1C1E),
            onSelected: (codigo) async {
              await ref
                  .read(idiomaAtivoProvider.notifier)
                  .selecionarIdioma(codigo);
              await _carregarDocumentos(codigo);
            },
            itemBuilder: (_) => ResolvedorIdioma.idiomasSuportados
                .map(
                  (opcao) => PopupMenuItem<String>(
                    value: opcao.codigo,
                    child: Row(
                      children: [
                        Text(
                          opcao.codigo.toUpperCase(),
                          style: TextStyle(
                            color: opcao.codigo == localeAtivo.languageCode
                                ? const Color(0xFFFF6B00)
                                : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          opcao.nomeNativo,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language,
                    color: Color(0xFFFF6B00),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    localeAtivo.languageCode.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _teveErroCarregamento
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFFF6B00),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.termosErroCarregar,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarDocumentos,
                        child: Text(l10n.termosBotaoTentarNovamente),
                      ),
                    ],
                  ),
                ),
              )
            : _termosMarkdown == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 12.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MarkdownBody(
                                data: _termosMarkdown!,
                                onTapLink: (texto, link, titulo) =>
                                    _tratarLink(texto, link, titulo, l10n),
                                styleSheet: _obterEstiloMarkdown(context),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _abrirModalPoliticaPrivacidade(l10n),
                                icon: const Icon(
                                  Icons.privacy_tip_outlined,
                                  size: 18,
                                  color: Color(0xFFFF6B00),
                                ),
                                label: Text(
                                  l10n.termosBotaoLerPolitica,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFFF6B00),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Material(
                        color: const Color(0xFF1A1C1E),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CheckboxListTile(
                                title: Text(
                                  l10n.termosCheckboxDeclaro,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                value: _concordou,
                                onChanged: (bool? valor) {
                                  setState(() {
                                    _concordou = valor ?? false;
                                  });
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                activeColor: const Color(0xFFFF6B00),
                                checkColor: Colors.black,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: FilledButton(
                                  onPressed: (_concordou && !_estaCarregando)
                                      ? _aoAceitarTermos
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B00),
                                    disabledBackgroundColor: Colors.white10,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _estaCarregando
                                      ? const CircularProgressIndicator(
                                          color: Colors.black,
                                        )
                                      : Text(
                                          l10n.termosBotaoAceitar,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

/// Alias para manter compatibilidade retroativa com código existente.
typedef TermsOfUseScreen = TelaTermosDeUso;
