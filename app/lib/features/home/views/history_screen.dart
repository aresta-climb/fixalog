import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/home/providers/history_provider.dart';
import 'package:app/core/services/pdf_viewer_service.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _limit = 10;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);

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

                // Status Grid and History List
                historyAsync.when(
                  data: (history) {
                    final totalLogs = history.length.toString();

                    // Encontrar a data do último log
                    String ultimoLog = '-';
                    if (history.isNotEmpty) {
                      final record =
                          history.first; // Já vem ordenado desc pelo provider
                      ultimoLog =
                          "\${record.dataInclusao.day.toString().padLeft(2, '0')}/\${record.dataInclusao.month.toString().padLeft(2, '0')}/\${record.dataInclusao.year}";
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'LOGS TOTAIS',
                                totalLogs,
                                Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'ÚLTIMO LOG',
                                ultimoLog,
                                Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        const SizedBox(height: 16),
                        if (history.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'Nenhum relatório preenchido.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          )
                        else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: history.length > _limit
                                ? _limit
                                : history.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final record = history[index];
                              final dataFormatada =
                                  "${record.dataInclusao.day.toString().padLeft(2, '0')}/${record.dataInclusao.month.toString().padLeft(2, '0')}/${record.dataInclusao.year}";

                              return _buildHistoryItem(
                                title: record.nomeProtocolo.isEmpty
                                    ? 'Protocolo'
                                    : record.nomeProtocolo,
                                date: dataFormatada,
                                tag: 'PREENCHIDO',
                                tagColor: const Color(
                                  0xFFFF6B00,
                                ).withValues(alpha: 0.2),
                                textColor: const Color(0xFFFF6B00),
                                icon: Icons.cloud_outlined,
                                onTap: () async {
                                  try {
                                    await ref
                                        .read(pdfViewerServiceProvider)
                                        .openPdf(record.pdfPath);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Erro ao abrir PDF: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
                          if (history.length > _limit) ...[
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _limit += 10;
                                });
                              },
                              child: const Text(
                                'CARREGAR MAIS',
                                style: TextStyle(
                                  color: Color(0xFFFF6B00),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
                  ),
                  error: (e, st) => Center(
                    child: Text(
                      'Erro: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
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
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121416),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
        ),
      ),
    );
  }
}
