import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/wizard_state_controller.dart';
import '../../../core/models/proto/protos/wizard.pb.dart';
import '../../../core/utils/protocol_icons.dart';
import '../../../core/services/protocol_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'widgets/signature_modal.dart';
import '../../pdf_generation/providers/generation_provider.dart';
import '../../pdf_generation/ui/generation_progress_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tela principal
// ─────────────────────────────────────────────────────────────────────────────

class WizardScreen extends ConsumerStatefulWidget {
  final String initialYaml;
  final bool isEditing;
  const WizardScreen({super.key, required this.initialYaml, this.isEditing = false});

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _cardKeys = [];
  final GlobalKey _summaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isEditing) {
        final protocol = ProtocolParser.fromYaml(widget.initialYaml);
        ref.read(wizardControllerProvider.notifier).loadProtocol(protocol, rawYaml: widget.initialYaml);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    HapticFeedback.lightImpact();
    final state = ref.read(wizardControllerProvider);
    final success = ref.read(wizardControllerProvider.notifier).nextStep();
    if (success) {
      _scrollToIndex(state.currentIndex + 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Preencha todos os campos obrigatórios para prosseguir.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF5A1E1E),
        ),
      );
    }
  }

  void _scrollToIndex(int index) {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!_scrollController.hasClients) return;
      final state = ref.read(wizardControllerProvider);
      final isSummary = index >= state.queue.length;
      GlobalKey key;
      if (isSummary) {
        key = _summaryKey;
      } else if (index < _cardKeys.length) {
        key = _cardKeys[index];
      } else {
        return;
      }
      final ctx = key.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox;
      final pos = box.localToGlobal(
        Offset.zero,
        ancestor: _scrollController.position.context.storageContext
            .findRenderObject(),
      );
      final target = _scrollController.offset + pos.dy - 90;
      _scrollController.animateTo(
        target.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 800),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wizardControllerProvider);

    if (state.protocol == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF060908),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
      );
    }

    while (_cardKeys.length < state.queue.length) {
      _cardKeys.add(GlobalKey());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF060908),
      body: Stack(
        children: [
          // Fundo decorativo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A1F16), Color(0xFF060908)],
              ),
            ),
          ),
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 700,
              height: 700,
              decoration: BoxDecoration(
                color: const Color(0xFF1B3D2F).withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 140, sigmaY: 140),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'FIXALOG',
                        style: TextStyle(
                          color: Color(0xFFFF6B00),
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Spacer(),
                      if (state.queue.isNotEmpty)
                        Text(
                          '${state.currentIndex + 1}/${state.queue.length}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                // Barra de progresso
                if (state.queue.isNotEmpty)
                  LinearProgressIndicator(
                    value: (state.currentIndex + 1) / state.queue.length,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B00)),
                    minHeight: 2,
                  ),
                // Cards
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height / 2,
                    ),
                    child: Column(
                      children: [
                        ...state.queue.asMap().entries.map((entry) {
                          final index = entry.key;
                          final flowStep = entry.value;
                          final isLocked = index > state.currentIndex;
                          final isCompleted = index < state.currentIndex;

                          return _StepCard(
                            key: _cardKeys[index],
                            flowStep: flowStep,
                            stepIndex: index + 1,
                            isLocked: isLocked,
                            isCompleted: isCompleted,
                            isLastStep: index == state.queue.length - 1,
                            onNext: _onNextPressed,
                            onBackToStep: () {
                              ref
                                  .read(wizardControllerProvider.notifier)
                                  .goToStep(index);
                              _scrollToIndex(index);
                            },
                          );
                        }),
                        if (state.isFinished)
                          SummaryConclusionCard(key: _summaryKey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card genérico — itera sobre os conteudos do step
// ─────────────────────────────────────────────────────────────────────────────

class _StepCard extends ConsumerWidget {
  final FlowStep flowStep;
  final int stepIndex;
  final bool isLocked;
  final bool isCompleted;
  final bool isLastStep;
  final VoidCallback onNext;
  final VoidCallback onBackToStep;

  const _StepCard({
    super.key,
    required this.flowStep,
    required this.stepIndex,
    required this.isLocked,
    required this.isCompleted,
    required this.isLastStep,
    required this.onNext,
    required this.onBackToStep,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = !isLocked && !isCompleted;
    final opacity = isCompleted ? 0.65 : (isLocked ? 0.45 : 1.0);

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: isCurrent ? 1.2 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PASSO $stepIndex',
                style: TextStyle(
                  color: isCurrent
                      ? const Color(0xFFFF6B00)
                      : Colors.white.withValues(alpha: 0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // Renderiza todos os conteudos em sequência
              IgnorePointer(
                ignoring: !isCurrent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: flowStep.step.conteudos.asMap().entries.map((e) {
                    final index = e.key;
                    final conteudo = e.value;
                    final isFirst = index == 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isFirst) ...[
                          const SizedBox(height: 20),
                          Divider(color: Colors.white.withValues(alpha: 0.06)),
                          const SizedBox(height: 12),
                        ],
                        _ConteudoWidget(conteudo: conteudo),
                      ],
                    );
                  }).toList(),
                ),
              ),
              // Botões de ação
              if (isCompleted) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onBackToStep,
                    icon: const Icon(Icons.history, size: 14),
                    label: const Text(
                      'VOLTAR A ESTE PASSO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              if (isCurrent) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: _NextButton(
                    flowStep: flowStep,
                    isLastStep: isLastStep,
                    onNext: onNext,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Despacho de ConteudoStep → widget correto
// ─────────────────────────────────────────────────────────────────────────────

class _ConteudoWidget extends ConsumerWidget {
  final ConteudoStep conteudo;
  const _ConteudoWidget({required this.conteudo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (conteudo.whichTipo()) {
      ConteudoStep_Tipo.instrucao => InstrucaoWidget(
        instrucao: conteudo.instrucao,
      ),
      ConteudoStep_Tipo.campoSimples => CampoSimplesWidget(conteudo: conteudo),
      ConteudoStep_Tipo.selecaoRamo => SelecaoRamoWidget(conteudo: conteudo),
      ConteudoStep_Tipo.listaAcoes => ListaAcoesWidget(conteudo: conteudo),
      ConteudoStep_Tipo.refMateriais => RefMateriaisWidget(conteudo: conteudo),
      _ => const Text(
        'Tipo de conteúdo não suportado',
        style: TextStyle(color: Colors.white24),
      ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botão Próximo
// ─────────────────────────────────────────────────────────────────────────────

class _NextButton extends ConsumerWidget {
  final FlowStep flowStep;
  final bool isLastStep;
  final VoidCallback onNext;
  const _NextButton({
    required this.flowStep,
    required this.isLastStep,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardControllerProvider);

    // Verificar se todos os conteudos obrigatórios estão satisfeitos
    bool allSatisfied = true;
    String label = isLastStep ? 'ASSINAR E CONCLUIR' : 'SEGUINTE';

    for (final c in flowStep.step.conteudos) {
      final kind = c.whichTipo();
      if (kind == ConteudoStep_Tipo.instrucao) continue;

      if (kind == ConteudoStep_Tipo.listaAcoes) {
        final count = state.lists[c.id]?.length ?? 0;
        final minimo = c.listaAcoes.minimo;
        if (minimo > 0 && count < minimo) allSatisfied = false;
        label = count > 0
            ? 'CONCLUIR LISTA ($count)'
            : (minimo == 0 ? 'PULAR' : 'SEGUINTE');
        continue;
      }

      if (kind == ConteudoStep_Tipo.campoSimples &&
          c.campoSimples.obrigatorio &&
          !state.answers.containsKey(c.id)) {
        allSatisfied = false;
      }
      if (kind == ConteudoStep_Tipo.selecaoRamo &&
          c.selecaoRamo.obrigatorio &&
          !state.answers.containsKey(c.id)) {
        allSatisfied = false;
      }
      if (kind == ConteudoStep_Tipo.refMateriais &&
          c.refMateriais.obrigatorio &&
          !state.answers.containsKey(c.id)) {
        allSatisfied = false;
      }
    }

    return ElevatedButton(
      onPressed: onNext,
      style: ElevatedButton.styleFrom(
        backgroundColor: allSatisfied
            ? const Color(0xFFFF6B00)
            : Colors.white.withValues(alpha: 0.08),
        foregroundColor: allSatisfied ? Colors.white : Colors.white24,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WIDGETS DE CONTEÚDO — Fluxo principal
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// StepInstrucao
// ─────────────────────────────────────────────────────────────────────────────

class InstrucaoWidget extends StatelessWidget {
  final StepInstrucao instrucao;
  const InstrucaoWidget({super.key, required this.instrucao});

  @override
  Widget build(BuildContext context) {
    final Color alertColor = switch (instrucao.nivelAlerta) {
      StepInstrucao_NivelAlerta.PERIGO => const Color(0xFFFF3D3D),
      StepInstrucao_NivelAlerta.ATENCAO => const Color(0xFFFFB800),
      _ => const Color(0xFF4FC3F7),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: alertColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                ProtocolIcons.get(instrucao.iconName),
                color: alertColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                instrucao.titulo,
                style: TextStyle(
                  color: alertColor,
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (instrucao.corpo.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: alertColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              instrucao.corpo,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StepCampoSimples (fluxo principal)
// ─────────────────────────────────────────────────────────────────────────────

class CampoSimplesWidget extends ConsumerWidget {
  final ConteudoStep conteudo;
  const CampoSimplesWidget({super.key, required this.conteudo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campo = conteudo.campoSimples;
    final answerObj = ref.watch(wizardControllerProvider).answers[conteudo.id];
    
    String? answer;
    if (answerObj != null) {
      if (answerObj.hasMidia()) {
        answer = 'media';
      } else if (answerObj.hasTexto() && answerObj.texto.isNotEmpty) {
        answer = answerObj.texto;
      } else if (answerObj.hasInteiro()) {
        answer = answerObj.inteiro.toString();
      } else if (answerObj.hasNumero()) {
        answer = answerObj.numero.toString();
      }
    }

    return _CampoSimplesContent(
      conteudoId: conteudo.id,
      campo: campo,
      answer: answer,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StepSelecaoRamo (fluxo principal — injeta steps na fila)
// ─────────────────────────────────────────────────────────────────────────────

class SelecaoRamoWidget extends ConsumerWidget {
  final ConteudoStep conteudo;
  const SelecaoRamoWidget({super.key, required this.conteudo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selecao = conteudo.selecaoRamo;
    final selectedObj = ref.watch(wizardControllerProvider).answers[conteudo.id];
    final selected = selectedObj?.texto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          selecao.label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (selecao.sublabel.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            selecao.sublabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 16),
        ...selecao.ramos.map(
          (ramo) => _SelectionTile(
            title: ramo.label,
            subtitle: ramo.sublabel,
            icon: ProtocolIcons.get(ramo.iconName),
            isSelected: selected == ramo.id,
            onTap: () => ref
                .read(wizardControllerProvider.notifier)
                .chooseRamo(conteudo.id, ramo.id),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StepListaAcoes — itens como cards expansíveis dentro do card pai
// ─────────────────────────────────────────────────────────────────────────────

class ListaAcoesWidget extends ConsumerWidget {
  final ConteudoStep conteudo;
  const ListaAcoesWidget({super.key, required this.conteudo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardControllerProvider);
    final lista = conteudo.listaAcoes;
    final items = state.lists[conteudo.id] ?? [];
    final expandedId = state.expandedListItems[conteudo.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lista.label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (lista.sublabel.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            lista.sublabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Itens da lista
        ...items.map(
          (item) => InlineItemCard(
            key: ValueKey(item.id),
            item: item,
            listConteudoId: conteudo.id,
            isExpanded: expandedId == item.id,
          ),
        ),

        const SizedBox(height: 8),

        // Botão adicionar
        if (lista.maximo == 0 || items.length < lista.maximo)
          OutlinedButton.icon(
            onPressed: () => _showAddItemSheet(context, ref, lista),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              items.isEmpty ? 'ADICIONAR ITEM' : 'ADICIONAR OUTRO',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B00),
              side: BorderSide(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
              ),
              backgroundColor: const Color(0xFFFF6B00).withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

        if (lista.minimo > 0 && items.length < lista.minimo) ...[
          const SizedBox(height: 8),
          Text(
            'Mínimo ${lista.minimo} item(ns) obrigatório(s).',
            style: TextStyle(
              color: Colors.orange.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  void _showAddItemSheet(
    BuildContext context,
    WidgetRef ref,
    StepListaAcoes lista,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181A1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SELECIONE O TIPO',
              style: TextStyle(
                color: Color(0xFFFF6B00),
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ...lista.tiposDisponiveis.map(
              (tipo) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(wizardControllerProvider.notifier)
                      .addListItem(listConteudoId: conteudo.id, tipo: tipo);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D1C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          ProtocolIcons.get(tipo.iconName),
                          color: Colors.white54,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tipo.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (tipo.sublabel.isNotEmpty)
                              Text(
                                tipo.sublabel,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StepRefMateriais (fluxo principal)
// ─────────────────────────────────────────────────────────────────────────────

class RefMateriaisWidget extends ConsumerWidget {
  final ConteudoStep conteudo;
  const RefMateriaisWidget({super.key, required this.conteudo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardControllerProvider);
    final refStep = conteudo.refMateriais;
    final allItems = state.lists[refStep.idStepMateriais] ?? [];
    final selectedIds = state.refSelections[conteudo.id] ?? [];

    return _RefMateriaisContent(
      label: refStep.label,
      sublabel: refStep.sublabel,
      allItems: allItems,
      selectedIds: selectedIds,
      onToggle: (itemId) {
        final newIds = List<String>.from(selectedIds);
        newIds.contains(itemId) ? newIds.remove(itemId) : newIds.add(itemId);
        ref
            .read(wizardControllerProvider.notifier)
            .setRefMateriais(conteudo.id, newIds);
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INLINE ITEM CARD — card expansível dentro de ListaAcoesWidget
// ═════════════════════════════════════════════════════════════════════════════

class InlineItemCard extends ConsumerWidget {
  final ListItemRecord item;
  final String listConteudoId;
  final bool isExpanded;

  const InlineItemCard({
    super.key,
    required this.item,
    required this.listConteudoId,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isExpanded ? const Color(0xFF0D1F15) : const Color(0xFF0F1210),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
          width: isExpanded ? 1.5 : 1.0,
        ),
      ),
      child: isExpanded
          ? _buildExpanded(context, ref)
          : _buildCollapsed(context, ref),
    );
  }

  Widget _buildCollapsed(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => ref
          .read(wizardControllerProvider.notifier)
          .expandListItem(listConteudoId, item.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2E1E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                ProtocolIcons.get(item.tipoIconName),
                color: const Color(0xFF4CAF50),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.tipoLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.expand_more,
              color: Colors.white.withValues(alpha: 0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header do item expandido
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Icon(
                ProtocolIcons.get(item.tipoIconName),
                color: const Color(0xFF4CAF50),
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                item.tipoLabel.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              // Botão para colapsar sem confirmar
              InkWell(
                onTap: () => ref
                    .read(wizardControllerProvider.notifier)
                    .expandListItem(listConteudoId, ''), // colapsa
                child: Icon(
                  Icons.expand_less,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              // Remover item
              InkWell(
                onTap: () => _confirmDelete(context, ref),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        Divider(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
          height: 20,
        ),
        // Conteúdos do item (renderização recursiva inline)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InlineStepsRenderer(steps: item.tipo.steps, itemId: item.id),
        ),
        const SizedBox(height: 16),
        // Botão Confirmar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ElevatedButton.icon(
            onPressed: () {
              final success = ref
                  .read(wizardControllerProvider.notifier)
                  .confirmListItem(listConteudoId, item.id);
              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Preencha os campos obrigatórios do item.',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Color(0xFF5A1E1E),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text(
              'CONFIRMAR ITEM',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C1E),
        title: const Text(
          'Remover item?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remover "${item.tipoLabel}"?',
          style: const TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(wizardControllerProvider.notifier)
                  .removeListItem(listConteudoId, item.id);
            },
            child: const Text('REMOVER', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Renderização recursiva dos steps inline de um item de lista
// ─────────────────────────────────────────────────────────────────────────────

class InlineStepsRenderer extends StatelessWidget {
  final List<Step> steps;
  final String itemId;

  const InlineStepsRenderer({
    super.key,
    required this.steps,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: steps.expand((step) {
        return step.conteudos.asMap().entries.map((e) {
          final idx = e.key;
          final conteudo = e.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (idx > 0 || steps.indexOf(step) > 0) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.04)),
                const SizedBox(height: 10),
              ],
              InlineConteudoRenderer(conteudo: conteudo, itemId: itemId),
            ],
          );
        });
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Renderização de um ConteudoStep inline (dentro de um item de lista)
// ─────────────────────────────────────────────────────────────────────────────

class InlineConteudoRenderer extends ConsumerWidget {
  final ConteudoStep conteudo;
  final String itemId;

  const InlineConteudoRenderer({
    super.key,
    required this.conteudo,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answerKey = '${conteudo.id}__$itemId';

    switch (conteudo.whichTipo()) {
      case ConteudoStep_Tipo.instrucao:
        return InstrucaoWidget(instrucao: conteudo.instrucao);

      case ConteudoStep_Tipo.campoSimples:
        final campo = conteudo.campoSimples;
        final answerKey = '${conteudo.id}__$itemId';
        final answerObj = ref.watch(wizardControllerProvider).answers[answerKey];
        
        String? answer;
        if (answerObj != null) {
          if (answerObj.hasMidia()) {
            answer = 'media';
          } else if (answerObj.hasTexto() && answerObj.texto.isNotEmpty) {
            answer = answerObj.texto;
          } else if (answerObj.hasInteiro()) {
            answer = answerObj.inteiro.toString();
          } else if (answerObj.hasNumero()) {
            answer = answerObj.numero.toString();
          }
        }

        return _CampoSimplesContent(
          conteudoId: conteudo.id,
          listItemId: itemId,
          campo: campo,
          answer: answer,
        );

      case ConteudoStep_Tipo.selecaoRamo:
        final selecao = conteudo.selecaoRamo;
        final selectedRamoObj = ref
            .watch(wizardControllerProvider)
            .answers[answerKey];
        final selectedRamoId = selectedRamoObj?.texto;
        final selectedRamo = selectedRamoId != null
            ? selecao.ramos.cast<Ramo?>().firstWhere(
                (r) => r?.id == selectedRamoId,
                orElse: () => null,
              )
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seleção de ramo (puro UI — sem queue injection)
            _InlineSelecaoRamoWidget(
              selecao: selecao,
              selectedId: selectedRamoId,
              onChoose: (ramoId) => ref
                  .read(wizardControllerProvider.notifier)
                  .answerInlineConteudoString(conteudo.id, ramoId, itemId),
            ),
            // Sub-steps do ramo escolhido (recursivo)
            if (selectedRamo != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
                child: InlineStepsRenderer(
                  steps: selectedRamo.steps,
                  itemId: itemId,
                ),
              ),
            ],
          ],
        );

      case ConteudoStep_Tipo.refMateriais:
        final refStep = conteudo.refMateriais;
        final state = ref.watch(wizardControllerProvider);
        final allItems = state.lists[refStep.idStepMateriais] ?? [];
        final selectedIds = state.refSelections[answerKey] ?? [];

        return _RefMateriaisContent(
          label: refStep.label,
          sublabel: refStep.sublabel,
          allItems: allItems,
          selectedIds: selectedIds,
          onToggle: (mid) {
            final newIds = List<String>.from(selectedIds);
            newIds.contains(mid) ? newIds.remove(mid) : newIds.add(mid);
            ref
                .read(wizardControllerProvider.notifier)
                .setRefMateriais(conteudo.id, newIds, listItemId: itemId);
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selecao de ramo inline (sem queue injection — puro UI)
// ─────────────────────────────────────────────────────────────────────────────

class _InlineSelecaoRamoWidget extends StatelessWidget {
  final StepSelecaoRamo selecao;
  final String? selectedId;
  final void Function(String ramoId) onChoose;

  const _InlineSelecaoRamoWidget({
    required this.selecao,
    required this.selectedId,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          selecao.label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        ...selecao.ramos.map(
          (ramo) => _SelectionTile(
            title: ramo.label,
            subtitle: ramo.sublabel,
            icon: ProtocolIcons.get(ramo.iconName),
            isSelected: selectedId == ramo.id,
            onTap: () => onChoose(ramo.id),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WIDGETS REUTILIZÁVEIS (internos)
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// CampoSimples — conteúdo compartilhado entre inline e principal
// ─────────────────────────────────────────────────────────────────────────────

class _CampoSimplesContent extends ConsumerWidget {
  final String conteudoId;
  final String? listItemId;
  final StepCampoSimples campo;
  final String? answer;

  const _CampoSimplesContent({
    required this.conteudoId,
    this.listItemId,
    required this.campo,
    required this.answer,
  });

  void _saveString(WidgetRef ref, String v) {
    if (listItemId != null) {
      ref.read(wizardControllerProvider.notifier).answerInlineConteudoString(conteudoId, v, listItemId!);
    } else {
      ref.read(wizardControllerProvider.notifier).answerConteudoString(conteudoId, v);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  campo.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (campo.obrigatorio)
                const Text(
                  '*',
                  style: TextStyle(color: Color(0xFFFF6B00), fontSize: 20),
                ),
            ],
          ),
          if (campo.sublabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              campo.sublabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildInput(context, ref, campo, answer),
        ],
      ),
    );
  }

  Widget _buildInput(
    BuildContext context,
    WidgetRef ref,
    StepCampoSimples campo,
    String? answer,
  ) {
    switch (campo.tipo) {
      case StepCampoSimples_TipoCampo.TEXT:
      case StepCampoSimples_TipoCampo.DATE:
        return TextFormField(
          initialValue: answer,
          keyboardType: TextInputType.text,
          onChanged: (v) => _saveString(ref, v),
          maxLines: campo.uiHint == StepCampoSimples_UiHint.TEXT_AREA ? 4 : 1,
          decoration: const InputDecoration(
            hintText: 'Digite aqui...',
          ),
        );

      case StepCampoSimples_TipoCampo.NUMBER:
        return TextFormField(
          initialValue: answer,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => _saveString(ref, v),
          decoration: const InputDecoration(
            hintText: 'Apenas números',
          ),
        );

      case StepCampoSimples_TipoCampo.BOOLEAN:
        return Row(
          children: [
            Expanded(
              child: _SelectionTile(
                title: 'Sim',
                subtitle: '',
                icon: Icons.check_circle_outline,
                isSelected: answer == 'true',
                onTap: () => _saveString(ref, 'true'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SelectionTile(
                title: 'Não',
                subtitle: '',
                icon: Icons.cancel_outlined,
                isSelected: answer == 'false',
                onTap: () => _saveString(ref, 'false'),
              ),
            ),
          ],
        );

      case StepCampoSimples_TipoCampo.DROPDOWN:
        return Column(
          children: campo.opcoes.map((o) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _SelectionTile(
                title: o.label,
                subtitle: o.sublabel,
                icon: ProtocolIcons.get(o.iconName),
                isSelected: answer == o.valor,
                onTap: () => _saveString(ref, o.valor),
              ),
            );
          }).toList(),
        );

      case StepCampoSimples_TipoCampo.GPS:
        final has = answer != null && answer.isNotEmpty;
        return GestureDetector(
          onTap: () async {
            bool serviceEnabled;
            LocationPermission permission;

            serviceEnabled = await Geolocator.isLocationServiceEnabled();
            if (!serviceEnabled) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Serviço de localização desativado.')),
                );
              }
              return;
            }

            permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
              if (permission == LocationPermission.denied) {
                return;
              }
            }

            if (permission == LocationPermission.deniedForever) {
              return;
            }

            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            _saveString(ref, '${position.latitude}, ${position.longitude}');
          },
          child: _actionTile(
            icon: has ? Icons.location_on : Icons.gps_fixed,
            label: has ? 'COORDENADAS CAPTURADAS' : 'CAPTURAR POSIÇÃO GPS',
            sub: has ? answer : '',
            active: has,
          ),
        );

      case StepCampoSimples_TipoCampo.IMAGE:
      case StepCampoSimples_TipoCampo.VIDEO:
        final has = answer != null && answer.isNotEmpty;
        final isVid = campo.tipo == StepCampoSimples_TipoCampo.VIDEO;
        return GestureDetector(
          onTap: () async {
            final picker = ImagePicker();
            if (isVid) {
              final video = await picker.pickVideo(source: ImageSource.camera);
              if (video != null) {
                await ref.read(wizardControllerProvider.notifier).saveMediaAnswer(
                      conteudoId,
                      video.path,
                      campo.tipo,
                      listItemId: listItemId,
                    );
              }
            } else {
              final image = await picker.pickImage(source: ImageSource.camera);
              if (image != null) {
                await ref.read(wizardControllerProvider.notifier).saveMediaAnswer(
                      conteudoId,
                      image.path,
                      campo.tipo,
                      listItemId: listItemId,
                    );
              }
            }
          },
          child: _actionTile(
            icon: has
                ? Icons.check_circle
                : (isVid ? Icons.videocam_outlined : Icons.camera_alt_outlined),
            label: has
                ? (isVid ? 'VÍDEO GRAVADO' : 'FOTO CAPTURADA')
                : (isVid ? 'GRAVAR VÍDEO' : 'ABRIR CÂMERA'),
            sub: '',
            active: has,
          ),
        );

      case StepCampoSimples_TipoCampo.SIGNATURE:
        final has = answer != null && answer.isNotEmpty;
        return GestureDetector(
          onTap: () async {
            final Uint8List? signatureBytes = await showDialog<Uint8List>(
              context: context,
              builder: (ctx) => const SignatureModal(),
            );

            if (signatureBytes != null) {
              await ref.read(wizardControllerProvider.notifier).saveMediaAnswerBytes(
                    conteudoId,
                    signatureBytes,
                    '.png',
                    campo.tipo,
                    listItemId: listItemId,
                  );
            }
          },
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: has
                    ? const Color(0xFFFF6B00).withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    has ? Icons.check_circle : Icons.gesture,
                    color: has ? const Color(0xFFFF6B00) : Colors.white12,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    has ? 'ASSINATURA REGISTRADA' : 'TOQUE PARA ASSINAR',
                    style: TextStyle(
                      color: has
                          ? const Color(0xFFFF6B00)
                          : Colors.white.withValues(alpha: 0.2),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      default:
        return Text(
          'Tipo não implementado: ${campo.tipo}',
          style: const TextStyle(color: Colors.white24),
        );
    }
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required String sub,
    required bool active,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D1C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: active ? const Color(0xFFFF6B00) : Colors.white24,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    style: const TextStyle(
                      color: Color(0xFFFF6B00),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    filled: true,
    fillColor: Colors.black26,
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// RefMateriais — conteúdo compartilhado entre inline e principal
// ─────────────────────────────────────────────────────────────────────────────

class _RefMateriaisContent extends StatelessWidget {
  final String label;
  final String sublabel;
  final List<ListItemRecord> allItems;
  final List<String> selectedIds;
  final void Function(String itemId) onToggle;

  const _RefMateriaisContent({
    required this.label,
    required this.sublabel,
    required this.allItems,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        if (sublabel.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            sublabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (allItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Text(
              'Nenhum material registrado no Bloco 1.\nVolte e adicione os materiais primeiro.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...allItems.map((item) {
            final isSel = selectedIds.contains(item.id);
            return GestureDetector(
              onTap: () => onToggle(item.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSel
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel
                        ? const Color(0xFFFF6B00).withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      ProtocolIcons.get(item.tipoIconName),
                      color: isSel ? const Color(0xFFFF6B00) : Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.tipoLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel
                              ? const Color(0xFFFF6B00)
                              : Colors.white24,
                          width: 2,
                        ),
                      ),
                      child: isSel
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF6B00),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile de seleção reutilizável
// ─────────────────────────────────────────────────────────────────────────────

class _SelectionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SelectionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.black26,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6B00).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF121416),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFFFF6B00) : Colors.white38,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF6B00) : Colors.white12,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B00),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tela de conclusão
// ─────────────────────────────────────────────────────────────────────────────

class SummaryConclusionCard extends ConsumerWidget {
  const SummaryConclusionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.verified, color: Color(0xFFFF6B00), size: 48),
          const SizedBox(height: 20),
          const Text(
            'PROTOCOLO CONCLUÍDO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Todos os dados foram coletados offline.\nO registro está pronto para ser assinado e exportado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                // 1. Salvar sessão
                final controller = ref.read(wizardControllerProvider.notifier);
                final sessionId = await controller.saveSession();

                if (!context.mounted) return;

                // 2. Mostrar loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const GenerationProgressDialog(),
                );

                // 3. Iniciar geração
                final appDir = await getApplicationDocumentsDirectory();
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                final outputPath = p.join(appDir.path, 'fixalog_report_$timestamp.pdf');

                final protocol = ref.read(wizardControllerProvider).protocol;

                await ref.read(generationProvider.notifier).startGeneration(
                  protocol?.nome ?? 'Relatório FixaLog',
                  outputPath,
                  sessionId: sessionId,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao gerar relatório: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text(
              'GERAR RELATÓRIO',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
