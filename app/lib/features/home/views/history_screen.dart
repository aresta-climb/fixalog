// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/features/home/providers/history_provider.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/services/pdf_viewer_service.dart';
import 'package:fixalog/features/wizard/views/wizard_screen.dart';
import 'package:fixalog/features/wizard/controllers/wizard_state_controller.dart';
import 'package:fixalog/features/pdf_generation/views/visualizador_relatorio_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _limit = 10;
  bool _mostrarMateriais = false;

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

  String _obterTituloRegistro(
    SubmissionRecord record, {
    String padrao = 'Protocolo',
  }) {
    if (record.tituloExibicao.trim().isNotEmpty) {
      return record.tituloExibicao.trim();
    }
    if (record.nomeProtocolo.trim().isNotEmpty) {
      return record.nomeProtocolo.trim();
    }
    return padrao;
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
              idSessao: record.idSessao,
              titulo: _obterTituloRegistro(record, padrao: 'Relatório Técnico'),
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
    final locale = ResolvedorIdioma.obterLocaleEfetivo(context, ref);
    final l10n = ResolvedorIdioma.obterTraducoes(locale);
    final ehPt = locale.languageCode == 'pt';

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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Text(
                  ehPt ? 'Histórico' : l10n.historicoTitulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ehPt
                      ? 'Registros de manutenção preenchidos'
                      : l10n.historicoSubtitulo,
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

                    final qtdManut =
                        history.where((r) => r.isManutencao).length;
                    final qtdMat = history.where((r) => r.isMaterial).length;

                    final registrosFiltrados = history
                        .where(
                          (r) =>
                              _mostrarMateriais ? r.isMaterial : r.isManutencao,
                        )
                        .toList();

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
                        const SizedBox(height: 24),
                        _buildSeletorCategoria(
                          ehPt: ehPt,
                          l10n: l10n,
                          qtdManut: qtdManut,
                          qtdMat: qtdMat,
                        ),
                        const SizedBox(height: 24),
                        if (registrosFiltrados.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                ehPt
                                    ? (_mostrarMateriais
                                          ? 'Nenhum material cadastrado.'
                                          : 'Nenhum relatório preenchido.')
                                    : (_mostrarMateriais
                                          ? l10n.historicoVazioMateriaisTitulo
                                          : l10n.historicoVazioRelatoriosTitulo),
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ),
                          )
                        else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: registrosFiltrados.length > _limit
                                ? _limit
                                : registrosFiltrados.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final record = registrosFiltrados[index];
                              final dataFormatada =
                                  "${record.dataInclusao.day.toString().padLeft(2, '0')}/${record.dataInclusao.month.toString().padLeft(2, '0')}/${record.dataInclusao.year}";

                              Future<void> loadAndEdit() async {
                                try {
                                  final controller = ref.read(
                                    wizardControllerProvider.notifier,
                                  );
                                  await controller.loadSession(record.idSessao);

                                  final state = ref.read(
                                    wizardControllerProvider,
                                  );
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
                                      SnackBar(
                                        content: Text(
                                          'Erro ao carregar sessão: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }

                              Future<void> duplicateAndEdit() async {
                                if (!context.mounted) return;
                                showDialog<void>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const AlertDialog(
                                    backgroundColor: Color(0xFF161A1E),
                                    content: Row(
                                      children: [
                                        CircularProgressIndicator(
                                          color: Color(0xFFFF6B00),
                                        ),
                                        SizedBox(width: 20),
                                        Expanded(
                                          child: Text(
                                            'Criando cópia do relatório...',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                try {
                                  await Future<void>.delayed(Duration.zero);
                                  final controller = ref.read(
                                    wizardControllerProvider.notifier,
                                  );
                                  await controller.duplicarSessao(
                                    record.idSessao,
                                  );

                                  final state = ref.read(
                                    wizardControllerProvider,
                                  );
                                  final yamlStr = state.protocolRawYaml;

                                  if (context.mounted) {
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
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
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao criar cópia: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }

                              final isEmProgresso = record.isEmProgresso;
                              final tag = ehPt
                                  ? (isEmProgresso
                                        ? 'EM PROGRESSO'
                                        : 'GERADO')
                                  : (isEmProgresso
                                        ? l10n.historicoStatusEmProgresso
                                        : l10n.historicoStatusConcluido);
                              final tagColor = isEmProgresso
                                  ? const Color(0xFFF59E0B).withValues(
                                      alpha: 0.2,
                                    )
                                  : const Color(0xFF10B981).withValues(
                                      alpha: 0.2,
                                    );
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
                                title: _obterTituloRegistro(record),
                                date: dataFormatada,
                                tag: tag,
                                tagColor: tagColor,
                                textColor: textColor,
                                icon: record.isMaterial
                                    ? Icons.inventory_2_outlined
                                    : Icons.history,
                                cloudIcon: cloudIcon,
                                cloudIconColor: cloudIconColor,
                                isEmProgresso: isEmProgresso,
                                ehPt: ehPt,
                                l10n: l10n,
                                onTap: () async {
                                  if (!isEmProgresso) {
                                    await _abrirRelatorio(record);
                                  } else {
                                    await loadAndEdit();
                                  }
                                },
                                onEdit: loadAndEdit,
                                onDuplicate: duplicateAndEdit,
                                onViewRelatorio: () async {
                                  await _abrirRelatorio(record);
                                },
                                onDelete: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(
                                        ehPt
                                            ? 'Excluir Protocolo'
                                            : l10n
                                                  .historicoConfirmarExclusaoTitulo,
                                      ),
                                      content: Text(
                                        ehPt
                                            ? 'Tem certeza que deseja excluir permanentemente este protocolo?'
                                            : l10n
                                                  .historicoConfirmarExclusaoCorpo(
                                                    _obterTituloRegistro(
                                                      record,
                                                    ),
                                                  ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text(
                                            ehPt
                                                ? 'Cancelar'
                                                : l10n.comumCancelar,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: Text(
                                            ehPt
                                                ? 'Excluir'
                                                : l10n.historicoBotaoExcluir,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref
                                        .read(historyRepositoryProvider)
                                        .deleteRecord(record);
                                  }
                                },
                              );
                            },
                          ),
                          if (registrosFiltrados.length > _limit) ...[
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
                      l10n.comumErro('$e'),
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

  Widget _buildSeletorCategoria({
    required bool ehPt,
    required AppLocalizations l10n,
    required int qtdManut,
    required int qtdMat,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF121416),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (_mostrarMateriais) {
                  setState(() {
                    _mostrarMateriais = false;
                    _limit = 10;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_mostrarMateriais
                      ? const Color(0xFFFF6B00)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  ehPt
                      ? 'MANUTENÇÕES'
                      : l10n.historicoAbaRelatorios(qtdManut),
                  style: TextStyle(
                    color: !_mostrarMateriais ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (!_mostrarMateriais) {
                  setState(() {
                    _mostrarMateriais = true;
                    _limit = 10;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _mostrarMateriais
                      ? const Color(0xFFFF6B00)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  ehPt ? 'MATERIAIS' : l10n.historicoAbaMateriais(qtdMat),
                  style: TextStyle(
                    color: _mostrarMateriais ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
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
    required bool ehPt,
    required AppLocalizations l10n,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDuplicate,
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
                  child: Icon(
                    icon,
                    color: const Color(0xFFFF6B00),
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
                    if (value == 'duplicate' && onDuplicate != null) {
                      onDuplicate();
                    }
                    if (value == 'viewRelatorio' && onViewRelatorio != null) {
                      onViewRelatorio();
                    }
                    if (value == 'delete' && onDelete != null) onDelete();
                  },
                  itemBuilder: (context) => [
                    if (isEmProgresso) ...[
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          ehPt
                              ? 'Continuar preenchimento'
                              : l10n.historicoBotaoContinuar,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text(
                          ehPt ? 'Criar cópia' : l10n.historicoBotaoDuplicar,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          ehPt ? 'Excluir' : l10n.historicoBotaoExcluir,
                        ),
                      ),
                    ] else ...[
                      PopupMenuItem(
                        value: 'viewRelatorio',
                        child: Text(
                          ehPt
                              ? 'Abrir Relatório'
                              : l10n.historicoBotaoVerRelatorio,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          ehPt ? 'Editar' : l10n.historicoBotaoEditar,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text(
                          ehPt ? 'Criar cópia' : l10n.historicoBotaoDuplicar,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          ehPt ? 'Excluir' : l10n.historicoBotaoExcluir,
                        ),
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
