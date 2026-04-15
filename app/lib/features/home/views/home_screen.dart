import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../wizard/views/wizard_screen.dart';
import '../../identity/controllers/identity_form_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(currentIdentityProvider);
    
    // Obter o primeiro nome de forma síncrona se disponível (fallback para "Mantenedor")
    String firstName = '';
    identityAsync.whenData((identity) {
      if (identity != null && identity.nome.isNotEmpty) {
        firstName = identity.nome.split(' ').first;
      }
    });
    return Scaffold(
      backgroundColor: const Color(0xFF121416),
      body: Stack(
        children: [
          // Background Glow Effect
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: -100,
            right: -100,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4F6D44).withOpacity(0.15), // Moss Green glow
                    Colors.transparent,
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar / Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1C1E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shield_outlined, color: Colors.blueAccent, size: 20),
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
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white70),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Greeting Section
                  Text(
                    firstName.isNotEmpty ? 'Boa jornada, \$firstName.' : 'Boa jornada.',
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
                      const Text(
                        'EQUIPAMENTO CLUB ALPINO SINCRONIZADO',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Section Title
                  const Text(
                    'NOVO REGISTRO DE MANUTENÇÃO',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cards
                  _buildProtocolCard(
                    context: context,
                    tagText: 'PROTOCOLO TÉCNICO',
                    tagColor: const Color(0xFFFF6B00),
                    title: 'Rebolting Químico',
                    iconData: Icons.build,
                    isPrimaryButton: true,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WizardScreen()));
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildProtocolCard(
                    context: context,
                    tagText: 'PROTOCOLO PREVENTIVO',
                    tagColor: Colors.white54,
                    title: 'Inspeção Visual\nAnual',
                    iconData: Icons.remove_red_eye,
                    isPrimaryButton: false,
                    onTap: () {},
                  ),
                  const SizedBox(height: 32),

                  // Status Grid
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('LOGS TOTAIS', '128', Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('VIA MAIS ATIVA', 'Via do Sol', Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('TAXA SINCR.', '100%', const Color(0xFF00E676))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('ÚLTIMA SYNC', '2h atrás', Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // History Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'HISTÓRICO RECENTE',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'VER TUDO',
                          style: TextStyle(
                            color: Color(0xFFFF6B00),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCard({
    required BuildContext context,
    required String tagText,
    required Color tagColor,
    required String title,
    required IconData iconData,
    required bool isPrimaryButton,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2022), // Slightly lighter surface
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Icon Watermark
          Positioned(
            right: -10,
            top: 0,
            child: Icon(
              iconData,
              size: 80,
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          
          // Content
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              Align(
                alignment: Alignment.centerLeft,
                child: isPrimaryButton
                    ? ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size(120, 40),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('INICIAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      )
                    : OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size(120, 40),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('INICIAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 16),
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

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2022),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
