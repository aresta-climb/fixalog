// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:fixlog/features/home/providers/history_provider.dart';
import 'package:fixlog/core/models/local/submission_record.dart';
import 'package:fixlog/core/services/pdf_viewer_service.dart';
import 'package:fixlog/features/wizard/views/wizard_screen.dart';
import 'package:fixlog/features/wizard/controllers/wizard_state_controller.dart';
import 'package:fixlog/features/pdf_generation/views/visualizador_relatorio_screen.dart';


class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _limit = 10;

  String? _localizarCaminhoEpub(SubmissionRecord record) {
    if (record.protobufPath.endsWith('.epub')) {
      return record.protobufPath;
    }
    if (record.pdfPath.endsWith('.epub')) {
      return record.pdfPath;
    }
    if (record.pdfPath.endsWith('.pdf')) {
      final irmao = record.pdfPath.replaceAll(RegExp(r'\.pdf$'), '.epub');
      if (File(irmao).existsSync()) {
        return irmao;
      }
    }
    return null;
  }

  Future<void> _abrirRelatorio(SubmissionRecord record) async {
    final caminhoEpub = _localizarCaminhoEpub(record);
    final caminhoPdf = record.pdfPath.isNotEmpty ? record.pdfPath : null;

    if (caminhoEpub != null) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VisualizadorRelatorioScreen(
              caminhoEpub: caminhoEpub,
              caminhoPdf: caminhoPdf,
              titulo: record.nomeProtocolo.isEmpty
                  ? 'Relatório Técnico'
                  : record.nomeProtocolo,
            ),
          ),
        );
      }
      return;
    }

    if (caminhoPdf != null) {
      try {
        await ref.read(pdfViewerServiceProvider).openPdf(caminhoPdf);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao abrir relatório: $e')),
          );
        }
      }
    }
  }

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
                      'FIXLOG',
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
                          "${record.dataInclusao.day.toString().padLeft(2, '0')}/${record.dataInclusao.month.toString().padLeft(2, '0')}/${record.dataInclusao.year}";
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

                              final loadAndEdit = () async {
                                try {
                                  final controller = ref.read(wizardControllerProvider.notifier);
                                  await controller.loadSession(record.idSessao);
                                  
                                  // Pegar o YAML recuperado para passar pro WizardScreen
                                  final state = ref.read(wizardControllerProvider);
                                  final yamlStr = state.protocolRawYaml;

                                  if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => WizardScreen(
                                          initialYaml: yamlStr,
                                          isEditing: true,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro ao carregar sessão: $e')),
                                    );
                                  }
                                }
                              };

                              final isEmProgresso = record.isEmProgresso;
                              final tag = isEmProgresso ? 'EM PROGRESSO' : 'GERADO';
                              final tagColor = isEmProgresso
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                  : const Color(0xFF10B981).withValues(alpha: 0.2);
                              final textColor = isEmProgresso
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF10B981);
                              final cloudIcon = isEmProgresso
                                  ? Icons.pending_actions_outlined
                                  : Icons.cloud_done_outlined;
                              final cloudIconColor = isEmProgresso
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF4F6D44);

                              return _buildHistoryItem(
                                title: record.nomeProtocolo.isEmpty
                                    ? 'Protocolo'
                                    : record.nomeProtocolo,
                                date: dataFormatada,
                                tag: tag,
                                tagColor: tagColor,
                                textColor: textColor,
                                icon: Icons.history,
                                cloudIcon: cloudIcon,
                                cloudIconColor: cloudIconColor,
                                isEmProgresso: isEmProgresso,
                                onTap: () async {
                                  if (!isEmProgresso) {
                                    await _abrirRelatorio(record);
                                  } else {
                                    loadAndEdit();
                                  }
                                },
                                onEdit: loadAndEdit,
                                onViewRelatorio: () async {
                                  await _abrirRelatorio(record);
                                },
                                onDelete: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Excluir Protocolo'),
                                      content: const Text('Tem certeza que deseja excluir permanentemente este protocolo?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref.read(historyRepositoryProvider).deleteRecord(record);
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
    required IconData cloudIcon,
    required Color cloudIconColor,
    required bool isEmProgresso,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onViewRelatorio,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
              Icon(
                cloudIcon,
                color: cloudIconColor,
                size: 18,
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                onSelected: (value) {
                  if (value == 'edit' && onEdit != null) onEdit();
                  if (value == 'viewRelatorio' && onViewRelatorio != null) {
                    onViewRelatorio();
                  }
                  if (value == 'delete' && onDelete != null) onDelete();
                },
                itemBuilder: (context) => [
                  if (isEmProgresso) ...[
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Continuar preenchimento'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Excluir'),
                    ),
                  ] else ...[
                    const PopupMenuItem(
                      value: 'viewRelatorio',
                      child: Text('Abrir Relatório'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Excluir'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
