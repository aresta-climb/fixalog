import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    String clubName = 'MANTENEDOR INDEPENDENTE';
    identityAsync.whenData((identity) {
      if (identity != null) {
        if (identity.nome.isNotEmpty) {
          firstName = identity.nome.split(' ').first;
        }
        if (identity.clubeAssociacao.isNotEmpty && identity.clubeAssociacao.trim().toUpperCase() != 'N/A') {
          clubName = identity.clubeAssociacao.trim().toUpperCase();
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF060908),
      body: Stack(
        children: [
          // 1. Camada de Gradiente de Base
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A1F16),
                  Color(0xFF060908),
                ],
              ),
            ),
          ),
          
          // 2. Blobs de Cor (Grandes e sólidos para o Blur processar)
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                color: const Color(0xFF1B3D2F).withOpacity(0.5),
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
                color: const Color(0xFF1B3D2F).withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // 3. Efeito de Desfoque Atmosférico (Elimina bandas de cor e bordas)
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              color: const Color(0xFF121416),
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
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Greeting Section
                  Text(
                    firstName.isNotEmpty ? 'Boa jornada, $firstName.' : 'Boa jornada.',
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
                          color: Colors.white.withOpacity(0.8),
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
                      color: Colors.white.withOpacity(0.7),
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
                    title: 'Manutenção de\nProteções Fixas',
                    iconData: Icons.handyman,
                    onTap: () async {
                      final yamlContent = await rootBundle.loadString('assets/protocols/manutencao_ferragens.yaml');
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WizardScreen(initialYaml: yamlContent),
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
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildProtocolCard(
                    context: context,
                    tagText: 'PROTOCOLO TÉCNICO',
                    tagColor: const Color(0xFFFF6B00),
                    title: 'Abertura de Via',
                    iconData: Icons.terrain,
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
                  const SizedBox(height: 48),

                  // History Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HISTÓRICO RECENTE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
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
                  const SizedBox(height: 16),
                  _buildHistoryItem(
                    title: 'Via do Sol',
                    date: '12 OUT 2023',
                    tag: 'QUÍMICO',
                    tagColor: const Color(0xFFFF6B00).withOpacity(0.2),
                    textColor: const Color(0xFFFF6B00),
                    icon: Icons.cloud_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryItem(
                    title: 'Fenda do Pânico',
                    date: '08 OUT 2023',
                    tag: 'INSPEÇÃO',
                    tagColor: Colors.white10,
                    textColor: Colors.white70,
                    icon: Icons.remove_red_eye_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryItem(
                    title: 'Cristal Rock',
                    date: '25 SET 2023',
                    tag: 'QUÍMICO',
                    tagColor: const Color(0xFFFF6B00).withOpacity(0.2),
                    textColor: const Color(0xFFFF6B00),
                    icon: Icons.sync,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper para o filtro de desfoque atmosférico
  static final blurFilter = ui.ImageFilter.blur(sigmaX: 120, sigmaY: 120);

  // Removido _buildGlowBlob original...

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
        color: const Color(0xFF121416).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(
              iconData,
              size: 54,
              color: Colors.white.withOpacity(0.12), // Mais claro conforme pedido
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
                alignment: Alignment.centerLeft, // Mantém botão pequeno
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('INICIAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121416),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7), // Mais claro
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

  Widget _buildHistoryItem({
    required String title,
    required String date,
    required String tag,
    required Color tagColor,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121416),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.history, color: Color(0xFFFF6B00), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6), // Mais claro
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(color: textColor, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.cloud_done_outlined, color: Color(0xFF4F6D44), size: 16),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }
}


