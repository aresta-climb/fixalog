// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/l10n/resolvedor_idioma.dart';
import '../../../core/services/autenticacao_nuvem_service.dart';
import '../../home/views/home_screen.dart';
import '../viewmodels/identity_form_view_model.dart';

/// Tela de configuração de identidade em 2 etapas:
/// 1. Autenticação OIDC (Google / Apple) no estilo clássico.
/// 2. Confirmação de Nome/Clube (com opção de atualizar o Aresta Climb),
///    explicação da chave ECDSA P-256 e solicitação de permissões nativas.
class IdentitySetupScreen extends ConsumerStatefulWidget {
  final Future<void> Function()? solicitadorPermissoes;

  const IdentitySetupScreen({super.key, this.solicitadorPermissoes});

  @override
  ConsumerState<IdentitySetupScreen> createState() =>
      _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends ConsumerState<IdentitySetupScreen> {
  final _nomeController = TextEditingController();
  final _clubeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(identityFormViewModelProvider.notifier)
          .carregarSessaoExistente();
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _clubeController.dispose();
    super.dispose();
  }

  Future<void> _solicitarPermissoesDispositivo() async {
    final solicitador = widget.solicitadorPermissoes;
    if (solicitador != null) {
      await solicitador();
      return;
    }
    await [Permission.camera, Permission.locationWhenInUse].request();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(identityFormViewModelProvider);
    final locale = ResolvedorIdioma.obterLocaleEfetivo(context, ref);
    final l10n = ResolvedorIdioma.obterTraducoes(locale);
    final ehPt = locale.languageCode == 'pt';

    ref.listen<IdentityFormState>(identityFormViewModelProvider, (
      previous,
      next,
    ) {
      if (next.nomeSugerido != null &&
          next.nomeSugerido!.isNotEmpty &&
          _nomeController.text.trim().isEmpty) {
        _nomeController.text = next.nomeSugerido!;
      }
      if (next.clubeSugerido != null &&
          next.clubeSugerido!.isNotEmpty &&
          _clubeController.text.trim().isEmpty) {
        _clubeController.text = next.clubeSugerido!;
      }
      if (!(previous?.isSuccess ?? false) && next.isSuccess) {
        ref.invalidate(currentIdentityProvider);
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          navigator.pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
      if (next.errorMessage != null &&
          (previous?.errorMessage != next.errorMessage)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [
              Color(0xFF2D3328),
              Color(0xFF9CB892),
              Color(0xFF455A46),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.credit_card_outlined,
                      color: Color(0xFFFF6B00),
                      size: 28,
                    ),
                    Icon(
                      Icons.shield_outlined,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Text(
                  'FIXA',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 72,
                    height: 0.9,
                    color: const Color(0xFFFF6B00),
                  ),
                ),
                Text(
                  'LOG',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 72,
                    height: 0.9,
                    color: const Color(0xFFFF6B00),
                  ),
                ),
                const SizedBox(height: 12),
                Container(width: 60, height: 4, color: const Color(0xFFFF6B00)),
                const SizedBox(height: 32),

                if (state.sessaoNuvem == null) ...[
                  Text(
                    ehPt
                        ? 'CONTA DE IDENTIDADE CRIPTOGRÁFICA (OBRIGATÓRIO)'
                        : 'CRYPTOGRAPHIC IDENTITY ACCOUNT (REQUIRED)',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFFFB693),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ehPt
                        ? 'Entre com sua conta Google ou Apple para vincular sua identidade pericial e carregar seu perfil do Aresta Climb.'
                        : 'Sign in with your Google or Apple account to bind your forensic identity and load your Aresta Climb profile.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      key: const Key('botao_login_google'),
                      onPressed: () {
                        ref
                            .read(identityFormViewModelProvider.notifier)
                            .autenticarComProvedor(ProvedorOidc.google);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1F1F1F),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(
                        Icons.g_mobiledata,
                        size: 28,
                        color: Color(0xFF4285F4),
                      ),
                      label: Text(
                        ehPt
                            ? 'Continuar com o Google'
                            : 'Continue with Google',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      key: const Key('botao_login_apple'),
                      onPressed: () {
                        ref
                            .read(identityFormViewModelProvider.notifier)
                            .autenticarComProvedor(ProvedorOidc.apple);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(
                        Icons.apple,
                        size: 24,
                        color: Colors.white,
                      ),
                      label: Text(
                        ehPt
                            ? 'Continuar com a Apple'
                            : 'Continue with Apple',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    key: const Key('badge_sessao_oidc'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1C1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFAED09F)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          color: Color(0xFFAED09F),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${state.sessaoNuvem!.provedor.valor.toUpperCase()} • ${state.sessaoNuvem!.email}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          key: const Key('botao_trocar_conta_oidc'),
                          onPressed: () {
                            _nomeController.clear();
                            _clubeController.clear();
                            ref
                                .read(identityFormViewModelProvider.notifier)
                                .trocarConta();
                          },
                          child: Text(
                            ehPt ? 'Trocar' : 'Switch',
                            style: const TextStyle(
                              color: Color(0xFFFF6B00),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Campo Nome
                  Text(
                    ehPt ? 'NOME COMPLETO' : l10n.identidadeLabelNome,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFFFB693),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: ehPt
                          ? 'EX: ALEX HONNOLD'
                          : l10n.identidadeHintNome,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      fillColor: const Color(0xFF1A1C1E),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFFFF6B00),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                    ),
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    key: const Key('checkbox_atualizar_nome_aresta'),
                    value: state.atualizarNomeNoAresta,
                    onChanged: (valor) {
                      ref
                          .read(identityFormViewModelProvider.notifier)
                          .definirAtualizarNomeNoAresta(valor ?? true);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFFFF6B00),
                    checkColor: Colors.black,
                    title: Text(
                      ehPt
                          ? 'Atualizar também meu nome de exibição no Aresta Climb'
                          : 'Also update my display name on Aresta Climb',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Campo Clube
                  Text(
                    ehPt
                        ? 'CLUBE / ASSOCIAÇÃO DE ESCALADA (OPCIONAL)'
                        : l10n.identidadeLabelAssociacao,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFFFB693),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _clubeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: ehPt
                          ? 'EX: ACEC-MG'
                          : l10n.identidadeHintAssociacao,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      fillColor: const Color(0xFF1A1C1E),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFFFF6B00),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                    ),
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),

                  const SizedBox(height: 28),

                  // Card de Segurança de Hardware (Chave Criptográfica)
                  Container(
                    key: const Key('card_seguranca_hardware'),
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1C1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFFAED09F),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ehPt
                                    ? 'SEGURANÇA DE HARDWARE'
                                    : l10n.identidadeTituloInicial,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: const Color(0xFFAED09F),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ehPt
                              ? 'Ao prosseguir, uma chave privada ECDSA P-256 será gerada no cofre criptografado deste dispositivo e vinculada ao seu login Google ou Apple (OpenPubkey). Suas manutenções serão assinadas digitalmente com autoria verificável.'
                              : l10n.identidadeSubtituloInicial,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFFFFB693),
                                fontSize: 14,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Card de Permissões do Dispositivo
                  Container(
                    key: const Key('card_permissoes_dispositivo'),
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1C1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.perm_device_information_outlined,
                              color: Color(0xFFAED09F),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ehPt
                                    ? 'PERMISSÕES DO DISPOSITIVO'
                                    : 'DEVICE PERMISSIONS',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: const Color(0xFFAED09F),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF282A2C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                ehPt ? 'ACESSO À CÂMERA' : 'CAMERA ACCESS',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: const Color(0xFFFF6B00),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF282A2C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                ehPt ? 'LOCALIZAÇÃO (GPS)' : 'LOCATION (GPS)',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: const Color(0xFFFF6B00),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botão Tátil de Ação
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      key: const Key('botao_gerar_chaves_entrar'),
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        await _solicitarPermissoesDispositivo();
                        await ref
                            .read(identityFormViewModelProvider.notifier)
                            .submitIdentity(
                              _nomeController.text,
                              _clubeController.text,
                              exigirAutenticacaoOidc: true,
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              ehPt
                                  ? 'GERAR CHAVES E ENTRAR'
                                  : l10n.identidadeBotaoGerarChaves,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.key, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
