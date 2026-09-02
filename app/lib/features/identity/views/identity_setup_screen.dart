// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/identity_form_view_model.dart';
import '../../home/views/home_screen.dart';

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

    // React to success
    ref.listen<IdentityFormState>(identityFormViewModelProvider, (
      previous,
      next,
    ) {
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
      backgroundColor:
          Colors.transparent, // Permite que o container de fora mostre o fundo
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [
              Color(0xFF2D3328), // Dark moss
              Color(0xFF9CB892), // Lighter moss green
              Color(0xFF455A46), // Dark greenish bottom
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
                // Ícones de topo superior
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

                // Typography 'FIX LOG'
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
                const SizedBox(height: 48),

                // Campo Nome
                Text(
                  'NOME COMPLETO',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(
                      0xFFFFB693,
                    ), // primary_dim ou orange claro
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
                    hintText: 'EX: ALEX HONNOLD',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    fillColor: const Color(
                      0xFF1A1C1E,
                    ), // Fundo ainda mais escuro para campos
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
                  'CLUBE / ASSOCIAÇÃO DE ESCALADA (OPCIONAL)',
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
                    hintText: 'EX: ACEC-MG',
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
                    color: const Color(0xFF1A1C1E), // Fundo técnico escuro
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
                          Text(
                            'SEGURANÇA DE HARDWARE',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: const Color(
                                    0xFFAED09F,
                                  ), // Verde técnico do mock
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ao prosseguir, uma chave privada RSA-4096 será gerada no Secure Enclave deste dispositivo. Suas manutenções serão assinadas digitalmente, garantindo integridade técnica inquestionável.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(
                            0xFFFFB693,
                          ), // Texto salmão/laranja claro
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
                        'Ao clicar em gerar chaves, você concorda com os termos de responsabilidade técnica e segurança ambiental da FixLog v2.4.',
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
                  height: 64, // Touch target gigante
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
                              const Text(
                                'GERAR CHAVES E ENTRAR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
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
