// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/local/app_config_record.dart';
import '../../../core/constantes/versao_legal.g.dart';
import '../../identity/views/identity_setup_screen.dart';
import '../../identity/viewmodels/identity_form_view_model.dart';
import '../../home/views/home_screen.dart';

/// Tela obrigatória de consentimento e aceite dos Termos de Uso e Política de Privacidade do FixLog.
class TelaTermosDeUso extends ConsumerStatefulWidget {
  final AssetBundle? assetBundle;
  final VoidCallback? aoAceitar;
  final bool solicitarPermissoesNativas;

  const TelaTermosDeUso({
    super.key,
    this.assetBundle,
    this.aoAceitar,
    this.solicitarPermissoesNativas = true,
  });

  @override
  ConsumerState<TelaTermosDeUso> createState() => _TelaTermosDeUsoState();
}

class _TelaTermosDeUsoState extends ConsumerState<TelaTermosDeUso> {
  bool _estaCarregando = false;
  bool _concordou = false;
  String? _termosMarkdown;
  String? _politicaMarkdown;
  String? _erroCarregamento;

  @override
  void initState() {
    super.initState();
    _carregarDocumentos();
  }

  Future<void> _carregarDocumentos() async {
    try {
      final pacote = widget.assetBundle ?? DefaultAssetBundle.of(context);

      final termos = await pacote.loadString('legal/repo/public/docs/termos-de-uso-fixlog.md');
      final politica = await pacote.loadString('legal/repo/public/docs/politica-de-privacidade-fixlog.md');

      if (mounted) {
        setState(() {
          _termosMarkdown = termos;
          _politicaMarkdown = politica;
          _erroCarregamento = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erroCarregamento = 'Não foi possível carregar os termos de uso locais. Por favor, tente novamente.';
        });
      }
    }
  }

  void _abrirModalPoliticaPrivacidade() {
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
            title: const Text(
              'Política de Privacidade - FixLog',
              style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 16),
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

  Future<void> _tratarLink(String texto, String? link, String titulo) async {
    if (link == null) return;

    if (link.toLowerCase().contains('privacidade')) {
      _abrirModalPoliticaPrivacidade();
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _aoAceitarTermos() async {
    setState(() => _estaCarregando = true);

    try {
      if (widget.solicitarPermissoesNativas) {
        await [Permission.camera, Permission.locationWhenInUse].request();
      }

      final isar = ref.read(isarProvider);
      if (isar != null) {
        await isar.writeTxn(() async {
          var config = await isar.appConfigRecords.get(1);
          config ??= AppConfigRecord();
          config.acceptedTermsVersion = kVersaoLegal;
          config.dataHoraAceiteTermos = DateTime.now();
          await isar.appConfigRecords.put(config);
        });
      }

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
        fontFamily: 'Inter',
        color: Colors.white70,
        fontSize: 15,
        height: 1.6,
      ),
      h1: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: Color(0xFFFF6B00),
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      h2: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: Color(0xFFFF6B00),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      h3: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      strong: const TextStyle(
        fontFamily: 'Inter',
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
    return Scaffold(
      backgroundColor: const Color(0xFF121416),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121416),
        elevation: 0,
        title: const Text(
          'Termos de Uso e Auditoria Técnica',
          style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _erroCarregamento != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFFF6B00), size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _erroCarregamento!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarDocumentos,
                        child: const Text('Tentar Novamente'),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MarkdownBody(
                                data: _termosMarkdown!,
                                onTapLink: _tratarLink,
                                styleSheet: _obterEstiloMarkdown(context),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _abrirModalPoliticaPrivacidade,
                                icon: const Icon(Icons.privacy_tip_outlined, size: 18, color: Color(0xFFFF6B00)),
                                label: const Text(
                                  'Ler Política de Privacidade',
                                  style: TextStyle(color: Colors.white, fontFamily: 'SpaceGrotesk'),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFF6B00)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CheckboxListTile(
                                title: const Text(
                                  'Li e concordo com os Termos de Uso e a Política de Privacidade.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                  ),
                                ),
                                value: _concordou,
                                onChanged: (bool? valor) {
                                  setState(() {
                                    _concordou = valor ?? false;
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                activeColor: const Color(0xFFFF6B00),
                                checkColor: Colors.black,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 56, // Área de toque acessível para mãos com luvas
                                child: FilledButton(
                                  onPressed: (_concordou && !_estaCarregando) ? _aoAceitarTermos : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B00),
                                    disabledBackgroundColor: Colors.white10,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _estaCarregando
                                      ? const CircularProgressIndicator(color: Colors.black)
                                      : const Text(
                                          'Aceitar Termos e Continuar',
                                          style: TextStyle(
                                            fontFamily: 'SpaceGrotesk',
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
