// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/resolvedor_idioma.dart';
import '../../../core/models/local/identity_record.dart';
import '../../../core/services/autenticacao_nuvem_service.dart';
import '../../../core/services/banco_dados_local.dart';
import '../../../core/services/servico_configuracao_remota.dart';
import '../../feedback/views/botao_feedback.dart';
import '../../identity/viewmodels/identity_form_view_model.dart';
import '../../identity/views/identity_setup_screen.dart';
import '../../onboarding/views/tela_termos_de_uso.dart';

/// Assinatura de abertura de URL externa (injetável para testes determinísticos).
typedef AbridorUrlExternaCallback = Future<bool> Function(Uri uri);

/// Provedor assíncrono da sessão OIDC atual para exibição na [TelaConfiguracoes].
final sessaoOidcConfigProvider = FutureProvider<SessaoUsuarioNuvem?>((ref) {
  final auth = ref.watch(autenticacaoNuvemServiceProvider);
  return auth.obterSessaoAtual();
});

/// Tela de Configurações e Governança Pericial do Fixalog.
///
/// Reúne o seletor multilíngue (7 idiomas), resumo da identidade técnica e conta OIDC
/// (incluindo fingerprint ECDSA P-256), auditoria de aceite dos Termos de Uso,
/// acionamento do feedback in-app offline e links oficiais da comunidade Aresta Climb.
class TelaConfiguracoes extends ConsumerWidget {
  final AbridorUrlExternaCallback abridorUrlExterna;
  final ExibidorFeedbackCallback? exibidorFeedback;

  const TelaConfiguracoes({
    super.key,
    this.abridorUrlExterna = launchUrl,
    this.exibidorFeedback,
  });

  /// Formata o fingerprint hexadecimal em versão truncada legível (`a1b2c3d4...eeff00`).
  static String formatarFingerprintCurto(String fingerprint) {
    final limpo = fingerprint.trim();
    if (limpo.length <= 16) return limpo;
    return '${limpo.substring(0, 8)}...${limpo.substring(limpo.length - 6)}';
  }

  /// Formata um [DateTime] no padrão auditável `YYYY-MM-DD HH:mm`.
  static String formatarDataHoraAceite(DateTime dataHora) {
    final ano = dataHora.year.toString().padLeft(4, '0');
    final mes = dataHora.month.toString().padLeft(2, '0');
    final dia = dataHora.day.toString().padLeft(2, '0');
    final hora = dataHora.hour.toString().padLeft(2, '0');
    final minuto = dataHora.minute.toString().padLeft(2, '0');
    return '$ano-$mes-$dia $hora:$minuto';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ResolvedorIdioma.obterLocaleEfetivo(context, ref);
    final l10n = ResolvedorIdioma.obterTraducoes(locale);
    final ehPt = locale.languageCode == 'pt';

    final banco = ref.watch(bancoDadosLocalProvider);
    final configApp = banco?.obterConfiguracaoSync(1);
    final identidadeAsync = ref.watch(currentIdentityProvider);
    final sessaoOidcAsync = ref.watch(sessaoOidcConfigProvider);

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1F16), Color(0xFF060908)],
            ),
          ),
        ),
        Positioned(
          top: -150,
          right: -150,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              color: const Color(0xFF1B3D2F).withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 150, sigmaY: 150),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121416),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'FIXALOG',
                      style: TextStyle(
                        color: Color(0xFFFF6B00),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  ehPt ? 'Configurações' : l10n.homeAbaConfig,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                _construirCardSeletorIdioma(ref, locale, l10n),
                const SizedBox(height: 16),
                _construirCardIdentidade(
                  context,
                  ehPt: ehPt,
                  l10n: l10n,
                  identidade: identidadeAsync.valueOrNull,
                  sessaoOidc: sessaoOidcAsync.valueOrNull,
                ),
                const SizedBox(height: 16),
                _construirCardGovernancaTermos(
                  context,
                  l10n: l10n,
                  versaoAceita: configApp?.versaoTermosAceita ?? 0,
                  dataHoraAceite: configApp?.dataHoraAceiteTermos,
                ),
                const SizedBox(height: 16),
                _construirCardComunidadeEFeedback(
                  l10n: l10n,
                  abrirUrl: abridorUrlExterna,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirCardSeletorIdioma(
    WidgetRef ref,
    Locale locale,
    AppLocalizations l10n,
  ) {
    return Container(
      key: const Key('seletor_idioma_config'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.language,
                color: Color(0xFFFF6B00),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.seletorIdiomaTitulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.seletorIdiomaSubtitulo,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('dropdown_idioma_config'),
                value: locale.languageCode,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1C1E),
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFFFF6B00),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                onChanged: (novoCodigo) {
                  if (novoCodigo != null) {
                    ref
                        .read(idiomaAtivoProvider.notifier)
                        .selecionarIdioma(novoCodigo);
                  }
                },
                items: ResolvedorIdioma.idiomasSuportados.map((opcao) {
                  final selecionado = opcao.codigo == locale.languageCode;
                  return DropdownMenuItem<String>(
                    key: Key('opcao_idioma_${opcao.codigo}'),
                    value: opcao.codigo,
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: selecionado
                                ? const Color(0xFFFF6B00)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            opcao.codigo.toUpperCase(),
                            style: TextStyle(
                              color:
                                  selecionado ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            opcao.nomeNativo,
                            style: TextStyle(
                              color:
                                  selecionado ? Colors.white : Colors.white70,
                              fontWeight: selecionado
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCardIdentidade(
    BuildContext context, {
    required bool ehPt,
    required AppLocalizations l10n,
    required IdentityRecord? identidade,
    required SessaoUsuarioNuvem? sessaoOidc,
  }) {
    final nomeExibicao =
        (identidade?.nome ?? sessaoOidc?.nomeCompleto ?? '').trim();
    final clubeExibicao =
        (identidade?.clubeAssociacao ?? sessaoOidc?.clubeAssociacao ?? '')
            .trim();

    final textoContaOidc = sessaoOidc != null
        ? '${sessaoOidc.provedor.valor.toUpperCase()} (${sessaoOidc.email})'
        : l10n.configContaOidcNaoVinculada;

    final fingerprintBruto = sessaoOidc?.fingerprintChavePublica ?? '';

    return Container(
      key: const Key('card_identidade_config'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFFFF6B00),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ehPt
                      ? 'Conta e Identidade Criptográfica'
                      : 'Cryptographic Identity & Account',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (nomeExibicao.isNotEmpty) ...[
            _construirLinhaMetadado(l10n.laudoRotuloNome, nomeExibicao),
            const SizedBox(height: 6),
          ],
          if (clubeExibicao.isNotEmpty) ...[
            _construirLinhaMetadado(l10n.laudoRotuloAssociacao, clubeExibicao),
            const SizedBox(height: 6),
          ],
          _construirLinhaMetadado(l10n.configRotuloContaOidc, textoContaOidc),
          if (fingerprintBruto.isNotEmpty) ...[
            const SizedBox(height: 6),
            _construirLinhaMetadado(
              l10n.configRotuloFingerprintChave,
              formatarFingerprintCurto(fingerprintBruto),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('botao_gerenciar_identidade_config'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const IdentitySetupScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFFF6B00)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.key, size: 18),
              label: Text(
                ehPt
                    ? 'VINCULAR / EDITAR CONTA OIDC'
                    : 'LINK / EDIT OIDC ACCOUNT',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCardGovernancaTermos(
    BuildContext context, {
    required AppLocalizations l10n,
    required int versaoAceita,
    required DateTime? dataHoraAceite,
  }) {
    return Container(
      key: const Key('card_governanca_termos_config'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gavel_outlined,
                color: Color(0xFFFF6B00),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.configSecaoGovernancaTitulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (versaoAceita > 0) ...[
            Text(
              l10n.configTermosVersaoAceita(versaoAceita),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (dataHoraAceite != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.configTermosDataAceite(
                  formatarDataHoraAceite(dataHoraAceite),
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ] else
            Text(
              l10n.configTermosPendente,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('botao_consultar_termos_config'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (routeContext) => TelaTermosDeUso(
                      aoAceitar: Navigator.of(routeContext).pop,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: Text(
                l10n.configBotaoConsultarTermos,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCardComunidadeEFeedback({
    required AppLocalizations l10n,
    required AbridorUrlExternaCallback abrirUrl,
  }) {
    final configRemota = ServicoConfiguracaoRemota.instancia;

    return Container(
      key: const Key('card_comunidade_feedback_config'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.forum_outlined,
                color: Color(0xFFFF6B00),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.configSecaoComunidadeTitulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BotaoFeedback(exibidorFeedback: exibidorFeedback),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('botao_whatsapp_comunidade_config'),
              onPressed: () {
                abrirUrl(Uri.parse(configRemota.urlComunidadeWhatsapp));
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.groups_outlined, size: 18),
              label: Text(
                l10n.configBotaoWhatsapp,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('botao_portal_web_config'),
              onPressed: () {
                abrirUrl(Uri.parse(configRemota.urlPortalAresta));
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.language_outlined, size: 18),
              label: Text(
                l10n.configBotaoPortalWeb,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirLinhaMetadado(String rotulo, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$rotulo: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
