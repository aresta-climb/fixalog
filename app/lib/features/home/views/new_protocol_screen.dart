import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../wizard/views/wizard_screen.dart';
import '../../identity/viewmodels/identity_form_view_model.dart';
import '../../express_form/views/express_form_screen.dart';

class NewProtocolScreen extends ConsumerWidget {
  const NewProtocolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(currentIdentityProvider);

    String firstName = '';
    String clubName = 'MANTENEDOR INDEPENDENTE';
    identityAsync.whenData((identity) {
      if (identity != null) {
        if (identity.nome.isNotEmpty) {
          firstName = identity.nome.split(' ').first;
        }
        if (identity.clubeAssociacao.isNotEmpty &&
            identity.clubeAssociacao.trim().toUpperCase() != 'N/A') {
          clubName = identity.clubeAssociacao.trim().toUpperCase();
        }
      }
    });

    return Stack(
      children: [
        // 1. Gradiente de Base
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1F16), Color(0xFF060908)],
            ),
          ),
        ),

        // 2. Blobs de Cor
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
        Positioned(
          bottom: 100,
          left: -200,
          child: Container(
            width: 800,
            height: 800,
            decoration: BoxDecoration(
              color: const Color(0xFF1B3D2F).withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // 3. Desfoque Atmosférico
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Bar / Header
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
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Greeting
                Text(
                  firstName.isNotEmpty
                      ? 'Boa jornada, $firstName.'
                      : 'Boa jornada.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B00),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      clubName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Section Title
                Text(
                  'NOVO REGISTRO DE MANUTENÇÃO',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Protocol Cards
                _buildProtocolCard(
                  context: context,
                  tagText: 'NOVO RECURSO',
                  tagColor: const Color(0xFF00FF00), // Verde pra destacar
                  title: 'Registro Expresso\n(Fotos + Local)',
                  iconData: Icons.bolt,
                  onTap: () {
                    // Navigate to Express Form Screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ExpressFormScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildProtocolCard(
                  context: context,
                  tagText: 'PROTOCOLO TÉCNICO',
                  tagColor: const Color(0xFFFF6B00),
                  title: 'Manutenção de\nProteções Fixas',
                  iconData: Icons.handyman,
                  onTap: () async {
                    final yamlContent = await rootBundle.loadString(
                      'assets/protocols/manutencao_ferragens.yaml',
                    );
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WizardScreen(initialYaml: yamlContent),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildProtocolCard(
                  context: context,
                  tagText: 'PROTOCOLO PREVENTIVO',
                  tagColor: const Color(0xFFFF6B00),
                  title: 'Inspeção Visual de\nProteções Fixas',
                  iconData: Icons.remove_red_eye,
                  onTap: () async {
                    final yamlContent = await rootBundle.loadString(
                      'assets/protocols/inspecao_visual.yaml',
                    );
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WizardScreen(initialYaml: yamlContent),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildProtocolCard(
                  context: context,
                  tagText: 'PROTOCOLO TÉCNICO',
                  tagColor: const Color(0xFFFF6B00),
                  title: 'Abertura de Via',
                  iconData: Icons.terrain,
                  onTap: () async {
                    final yamlContent = await rootBundle.loadString(
                      'assets/protocols/abertura_vias.yaml',
                    );
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WizardScreen(initialYaml: yamlContent),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProtocolCard({
    required BuildContext context,
    required String tagText,
    required Color tagColor,
    required String title,
    required IconData iconData,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121416).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(
              iconData,
              size: 54,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tagText,
                style: TextStyle(
                  color: tagColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'INICIAR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
