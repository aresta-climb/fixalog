// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/resolvedor_idioma.dart';
import '../../../core/services/autenticacao_nuvem_service.dart';
import '../../home/views/home_screen.dart';
import '../viewmodels/identity_form_view_model.dart';

class IdentitySetupScreen extends ConsumerStatefulWidget {
  const IdentitySetupScreen({super.key});

  @override
  ConsumerState<IdentitySetupScreen> createState() =>
      _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends ConsumerState<IdentitySetupScreen> {
  final _nomeController = TextEditingController();
  final _clubeController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _clubeController.dispose();
    super.dispose();
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
      if (next.isSuccess) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
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
                  'FIX',
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

                if (state.sessaoNuvem != null)
                  Container(
                    key: const Key('badge_sessao_oidc'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
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
                      ],
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('botao_login_google'),
                        onPressed: state.isLoading
                            ? null
                            : () {
                                ref
                                    .read(
                                      identityFormViewModelProvider.notifier,
                                    )
                                    .autenticarComProvedor(ProvedorOidc.google);
                              },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1C1E),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFFF6B00)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 22),
                        label: Text(
                          ehPt ? 'GOOGLE' : 'GOOGLE',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('botao_login_apple'),
                        onPressed: state.isLoading
                            ? null
                            : () {
                                ref
                                    .read(
                                      identityFormViewModelProvider.notifier,
                                    )
                                    .autenticarComProvedor(ProvedorOidc.apple);
                              },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1C1E),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFFF6B00)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.apple, size: 20),
                        label: Text(
                          ehPt ? 'APPLE' : 'APPLE',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

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
                    hintText: ehPt ? 'EX: ALEX HONNOLD' : l10n.identidadeHintNome,
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

                const SizedBox(height: 24),

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

                const SizedBox(height: 32),

                // Card de Segurança de Hardware
                Container(
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFFFB693),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
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
                          Text(
                            'ACESSO CÂMERA',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: const Color(0xFFFF6B00),
                                  fontWeight: FontWeight.bold,
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
                              Icons.folder_outlined,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'ARMAZENAMENTO',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: const Color(0xFFFF6B00),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Ao clicar em gerar chaves, você concorda com os termos de responsabilidade técnica e segurança ambiental da Fixalog v2.4.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                          fontSize: 11,
                          height: 1.4,
                        ),
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
                    onPressed: state.isLoading
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            ref
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
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Row(
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
