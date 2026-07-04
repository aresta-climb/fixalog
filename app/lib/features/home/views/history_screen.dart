import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                // Header da página
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

                Text(
                  'Histórico',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registros de manutenção preenchidos',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),

                // Status Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('LOGS TOTAIS', '128', Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'VIA MAIS ATIVA',
                        'Via do Sol',
                        Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HISTÓRICO RECENTE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHistoryItem(
                  title: 'Via do Sol',
                  date: '12 OUT 2023',
                  tag: 'QUÍMICO',
                  tagColor: const Color(0xFFFF6B00).withValues(alpha: 0.2),
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
                  tagColor: const Color(0xFFFF6B00).withValues(alpha: 0.2),
                  textColor: const Color(0xFFFF6B00),
                  icon: Icons.sync,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
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
              color: Colors.white.withValues(alpha: 0.7),
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
            child: const Icon(
              Icons.history,
              color: Color(0xFFFF6B00),
              size: 18,
            ),
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
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.cloud_done_outlined,
            color: Color(0xFF4F6D44),
            size: 16,
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }
}
