// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/wizard_state_controller.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/resolvedor_idioma.dart';
import '../../../core/models/proto/protos/wizard.pb.dart';
import '../../../core/models/proto/protos/registro.pb.dart';
import '../../../core/utils/protocol_icons.dart';
import '../../../core/services/protocol_parser.dart';
import '../../../core/services/servico_telemetria.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/session_bundle_manager.dart';

import 'package:path/path.dart' as p;
import '../../media/services/seletor_documento_service.dart';
import '../../media/services/servico_galeria_dispositivo.dart';
import '../../media/services/video_transcoder_service.dart';
import '../../media/widgets/seletor_trecho_video_dialog.dart';
import '../../pdf_generation/providers/generation_provider.dart';
import '../../pdf_generation/ui/generation_progress_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tela principal
// ─────────────────────────────────────────────────────────────────────────────

class WizardScreen extends ConsumerStatefulWidget {
  final String initialYaml;
  final bool isEditing;
  final bool retornarAoConcluir;

  const WizardScreen({
    super.key,
    required this.initialYaml,
    this.isEditing = false,
    this.retornarAoConcluir = false,
  });

  /// Abre uma nova sessão do [WizardScreen] empilhada em um [ProviderScope] isolado,
  /// preservando integralmente o estado de qualquer [WizardScreen] pai ativo.
  static Future<String?> abrirSessaoIsolada(
    BuildContext context, {
    required String initialYaml,
    bool retornarAoConcluir = true,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          overrides: [
            wizardControllerProvider.overrideWith(WizardStateController.new),
          ],
          child: WizardScreen(
            initialYaml: initialYaml,
            retornarAoConcluir: retornarAoConcluir,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _cardKeys = [];
  final GlobalKey _summaryKey = GlobalKey();
  late bool _protocoloInicializado;

  @override
  void initState() {
    super.initState();
    _protocoloInicializado = widget.isEditing;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isEditing && mounted) {
        _cardKeys.clear();
        final locale = ResolvedorIdioma.obterLocaleEfetivo(context, ref);
        if (locale.languageCode == 'pt' &&
            ProtocolParser.obterTraducoesLocais('visual_inspection', 'pt') !=
                null) {
          final protocol = ProtocolParser.fromYaml(widget.initialYaml);
          ref
              .read(wizardControllerProvider.notifier)
              .loadProtocol(protocol, rawYaml: widget.initialYaml);
          setState(() {
            _protocoloInicializado = true;
          });
        } else {
          _carregarProtocoloLocalizado(locale.languageCode);
        }
      }
    });
  }

  Future<void> _carregarProtocoloLocalizado(String codigoIdioma) async {
    await ProtocolParser.garantirTraducoesCarregadas(codigoIdioma);
    if (!mounted) return;
    final protocol = ProtocolParser.fromYaml(
      widget.initialYaml,
      codigoIdioma: codigoIdioma,
    );
    ref
        .read(wizardControllerProvider.notifier)
        .loadProtocol(protocol, rawYaml: widget.initialYaml);
    setState(() {
      _protocoloInicializado = true;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onNextPressed() async {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.lightImpact();
    final notifier = ref.read(wizardControllerProvider.notifier);

    final idxBefore = ref.read(wizardControllerProvider).currentIndex;
    final success = notifier.nextStep();
    if (success) {
      _scrollToIndex(idxBefore + 1);
    } else if (mounted) {
      final l10n = ResolvedorIdioma.obterTraducoesContexto(context, ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.wizardAvisoCamposObrigatorios,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF5A1E1E),
        ),
      );
    }
  }

  void _scrollToIndex(int index) {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || !_scrollController.hasClients) return;
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
      // ignore: use_build_context_synchronously
      final ctx = key.currentContext;
      if (ctx == null) return;
      // ignore: use_build_context_synchronously
      final box = ctx.findRenderObject() as RenderBox;
      // ignore: use_build_context_synchronously
      final ancestorObj = _scrollController.position.context.storageContext
          .findRenderObject();
      final pos = box.localToGlobal(
        Offset.zero,
        ancestor: ancestorObj,
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

    if (!_protocoloInicializado || state.protocol == null) {
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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(wizardControllerProvider.notifier).flushAutoSave();
        }
      },
      child: Scaffold(
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x661B3D2F), Color(0x001B3D2F)],
                  ),
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
                          onPressed: () {
                            ref.read(wizardControllerProvider.notifier).flushAutoSave();
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'FIXALOG',
                          style: TextStyle(
                            color: Color(0xFFFF6B00),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 2.0,
                          ),
                        ),
                      const Spacer(),
                      if (state.queue.isNotEmpty)
                        Text(
                          '${(state.currentIndex + 1).clamp(1, state.queue.length)}/${state.queue.length}',
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
                    value: (state.currentIndex + 1).clamp(1, state.queue.length) /
                        state.queue.length,
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
                              FocusManager.instance.primaryFocus?.unfocus();
                              ref
                                  .read(wizardControllerProvider.notifier)
                                  .goToStep(index);
                              _scrollToIndex(index);
                            },
                          );
                        }),
                        if (state.isFinished)
                          SummaryConclusionCard(
                            key: _summaryKey,
                            retornarAoConcluir: widget.retornarAoConcluir,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    ref.watch(wizardControllerProvider);
    final l10n = ResolvedorIdioma.obterTraducoesContexto(context, ref);
    final notifier = ref.read(wizardControllerProvider.notifier);
    final zeroBasedIndex = stepIndex - 1;
    final podeAcessar = notifier.podeAcessarStep(zeroBasedIndex);
    final isCurrent = !isLocked && !isCompleted;
    final podeInteragir = isCurrent || (isLocked && podeAcessar);
    final opacity =
        isCompleted ? 0.65 : ((isLocked && !podeAcessar) ? 0.45 : 1.0);

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
                l10n.wizardPassoNumero(stepIndex),
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
              Listener(
                onPointerDown: (_) {
                  if (!isCurrent && podeAcessar && isLocked) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    notifier.goToStep(zeroBasedIndex);
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: (!podeInteragir && isLocked)
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.wizardAvisoPassoAnteriorObrigatorio,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: const Color(0xFF5A1E1E),
                            ),
                          );
                        }
                      : null,
                  child: ExcludeFocus(
                    excluding: !podeInteragir,
                    child: IgnorePointer(
                      ignoring: !podeInteragir,
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
                  ),
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
                    label: Text(
                      l10n.wizardBotaoVoltarPasso,
                      style: const TextStyle(
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
    final l10n = ResolvedorIdioma.obterTraducoesContexto(context, ref);

    // Verificar se todos os conteudos obrigatórios estão satisfeitos
    bool allSatisfied = true;
    String label = isLastStep ? l10n.wizardBotaoConcluir : l10n.wizardBotaoSeguinte;

    for (final c in flowStep.step.conteudos) {
      final kind = c.whichTipo();
      if (kind == ConteudoStep_Tipo.instrucao) continue;

      if (kind == ConteudoStep_Tipo.listaAcoes) {
        final count = state.lists[c.id]?.length ?? 0;
        final minimo = c.listaAcoes.minimo;
        if (minimo > 0 && count < minimo) allSatisfied = false;
        label = count > 0
            ? l10n.wizardBotaoConcluirLista(count)
            : (minimo == 0 ? l10n.wizardBotaoPular : l10n.wizardBotaoSeguinte);
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
      if (WizardStateController.extrairMidiasDeResposta(answerObj).isNotEmpty) {
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
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              ref
                  .read(wizardControllerProvider.notifier)
                  .chooseRamo(conteudo.id, ramo.id);
            },
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
  final String? parentItemId;
  const ListaAcoesWidget({super.key, required this.conteudo, this.parentItemId});

  String get _listKey =>
      parentItemId != null ? '${conteudo.id}__$parentItemId' : conteudo.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardControllerProvider);
    final l10n = ResolvedorIdioma.obterTraducoesContexto(context, ref);
    final lista = conteudo.listaAcoes;
    final listKey = _listKey;
    final items = state.lists[listKey] ?? [];
    final expandedId = state.expandedListItems[listKey];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lista.label,
          style: const TextStyle(
            color: Colors.white,
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
            listConteudoId: listKey,
            isExpanded: expandedId == item.id,
          ),
        ),

        const SizedBox(height: 8),

        // Botão adicionar
        if (lista.maximo == 0 || items.length < lista.maximo)
          OutlinedButton.icon(
            onPressed: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
              _showAddItemSheet(context, ref, lista, listKey, l10n);
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              items.isEmpty
                  ? l10n.wizardBotaoAdicionarItem
                  : l10n.wizardBotaoAdicionarOutro,
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
            l10n.wizardMinimoItensObrigatorios(lista.minimo),
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
    String listKey,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181A1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final recuoInferiorSo = _obterRecuoInferiorModal(context, sheetContext);
        return SafeArea(
          bottom: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + recuoInferiorSo),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.wizardSelecioneTipo,
                    style: const TextStyle(
                      color: Color(0xFFFF6B00),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      key: const Key('scroll_selecao_tipo'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...lista.tiposDisponiveis.map(
                            (tipo) => GestureDetector(
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                Navigator.pop(sheetContext);
                                FocusManager.instance.primaryFocus?.unfocus();
                                ref
                                    .read(wizardControllerProvider.notifier)
                                    .addListItem(
                                      listConteudoId: listKey,
                                      tipo: tipo,
                                    );
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }
}

double _obterRecuoInferiorModal(
  BuildContext origemContext,
  BuildContext sheetContext,
) {
  final mqOrigem = MediaQuery.maybeOf(origemContext);
  final mqSheet = MediaQuery.maybeOf(sheetContext);
  final view = View.maybeOf(sheetContext);
  final viewPaddingBottom =
      view != null ? view.viewPadding.bottom / view.devicePixelRatio : 0.0;
  final gestureBottom = view != null
      ? view.systemGestureInsets.bottom / view.devicePixelRatio
      : 0.0;

  final candidatos = <double>[
    mqSheet?.padding.bottom ?? 0.0,
    mqSheet?.viewPadding.bottom ?? 0.0,
    mqSheet?.systemGestureInsets.bottom ?? 0.0,
    mqOrigem?.padding.bottom ?? 0.0,
    mqOrigem?.viewPadding.bottom ?? 0.0,
    mqOrigem?.systemGestureInsets.bottom ?? 0.0,
    viewPaddingBottom,
    gestureBottom,
  ];

  double maior = 0.0;
  for (final valor in candidatos) {
    if (valor > maior) maior = valor;
  }
  return maior;
}

Future<String> _carregarYamlCadastroMaterial() {
  return rootBundle.loadString(
    'assets/protocols/cadastro_material.yaml',
    cache: false,
  );
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
    final notifier = ref.read(wizardControllerProvider.notifier);
    final refStep = conteudo.refMateriais;
    final allItems = notifier.obterItensParaRefMateriais(refStep);
    final selectedIds = state.refSelections[conteudo.id] ?? [];

    return _RefMateriaisContent(
      label: refStep.label,
      sublabel: refStep.sublabel,
      allItems: allItems,
      selectedIds: selectedIds,
      origemCatalogo: refStep.origemCatalogo,
      onToggle: (itemId) {
        final newIds = List<String>.from(selectedIds);
        newIds.contains(itemId) ? newIds.remove(itemId) : newIds.add(itemId);
        notifier.setRefMateriais(conteudo.id, newIds);
      },
      onCadastrarNovoMaterial: refStep.origemCatalogo
          ? () async {
              final yaml = await _carregarYamlCadastroMaterial();
              if (!context.mounted) return;
              final novoId = await WizardScreen.abrirSessaoIsolada(
                context,
                initialYaml: yaml,
              );
              if (novoId != null && novoId.isNotEmpty) {
                final newIds = List<String>.from(selectedIds);
                if (!newIds.contains(novoId)) {
                  newIds.add(novoId);
                }
                notifier.setRefMateriais(conteudo.id, newIds);
              }
            }
          : null,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INLINE ITEM CARD — card expansível dentro de ListaAcoesWidget
// ═════════════════════════════════════════════════════════════════════════════

class InlineItemCard extends ConsumerStatefulWidget {
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
  ConsumerState<InlineItemCard> createState() => _InlineItemCardState();
}

class _InlineItemCardState extends ConsumerState<InlineItemCard> {
  final GlobalKey _cabecalhoExpandidoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.isExpanded) {
      _rolarParaSecaoAberta();
    }
  }

  @override
  void didUpdateWidget(covariant InlineItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isExpanded && widget.isExpanded) {
      _rolarParaSecaoAberta();
    } else if (oldWidget.isExpanded && !widget.isExpanded) {
      _rolarParaSecaoColapsada();
    }
  }

  void _rolarParaSecaoAberta() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      final alvoContext = _cabecalhoExpandidoKey.currentContext ?? context;
      Scrollable.ensureVisible(
        alvoContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  void _rolarParaSecaoColapsada() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final expandidoAtual = ref
          .read(wizardControllerProvider)
          .expandedListItems[widget.listConteudoId];
      if (expandidoAtual != null && expandidoAtual.isNotEmpty) {
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: 0.25,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = widget.isExpanded;
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
    final item = widget.item;
    final listConteudoId = widget.listConteudoId;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        ref
            .read(wizardControllerProvider.notifier)
            .expandListItem(listConteudoId, item.id);
      },
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
                  Flexible(
                    child: Text(
                      item.tipoLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
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
    final item = widget.item;
    final listConteudoId = widget.listConteudoId;
    final l10n = ResolvedorIdioma.obterTraducoesContexto(context, ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header do item expandido
        Padding(
          key: _cabecalhoExpandidoKey,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Icon(
                ProtocolIcons.get(item.tipoIconName),
                color: const Color(0xFF4CAF50),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.tipoLabel.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botão para colapsar sem confirmar
              InkWell(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  ref
                      .read(wizardControllerProvider.notifier)
                      .expandListItem(listConteudoId, ''); // colapsa
                },
                child: Icon(
                  Icons.expand_less,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              // Remover item
              InkWell(
                onTap: () => _confirmDelete(context, ref, l10n),
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
              FocusManager.instance.primaryFocus?.unfocus();
              final success = ref
                  .read(wizardControllerProvider.notifier)
                  .confirmListItem(listConteudoId, item.id);
              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.wizardAvisoCamposItemObrigatorios,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF5A1E1E),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: Text(
              l10n.wizardBotaoConfirmarItem,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final item = widget.item;
    final listConteudoId = widget.listConteudoId;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C1E),
        title: Text(
          l10n.wizardRemoverItemTitulo,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.wizardRemoverItemCorpo(item.tipoLabel),
          style: const TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.comumCancelar,
              style: const TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(wizardControllerProvider.notifier)
                  .removeListItem(listConteudoId, item.id);
            },
            child: Text(
              l10n.comumRemover,
              style: const TextStyle(color: Colors.red),
            ),
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
          if (WizardStateController.extrairMidiasDeResposta(answerObj).isNotEmpty) {
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
              onChoose: (ramoId) {
                FocusManager.instance.primaryFocus?.unfocus();
                ref
                    .read(wizardControllerProvider.notifier)
                    .answerInlineConteudoString(conteudo.id, ramoId, itemId);
              },
            ),
            // Sub-steps do ramo escolhido (recursivo)
            if (selectedRamo != null) ...[
              const SizedBox(height: 12),
              _SubSecaoRamoAutoScroll(
                key: ValueKey('ramo_${conteudo.id}_${itemId}_${selectedRamo.id}'),
                child: Container(
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
              ),
            ],
          ],
        );

      case ConteudoStep_Tipo.refMateriais:
        final refStep = conteudo.refMateriais;
        final state = ref.watch(wizardControllerProvider);
        final notifier = ref.read(wizardControllerProvider.notifier);
        final allItems = notifier.obterItensParaRefMateriais(refStep);
        final selectedIds = state.refSelections[answerKey] ?? [];

        return _RefMateriaisContent(
          label: refStep.label,
          sublabel: refStep.sublabel,
          allItems: allItems,
          selectedIds: selectedIds,
          origemCatalogo: refStep.origemCatalogo,
          onToggle: (mid) {
            final newIds = List<String>.from(selectedIds);
            newIds.contains(mid) ? newIds.remove(mid) : newIds.add(mid);
            notifier.setRefMateriais(conteudo.id, newIds, listItemId: itemId);
          },
          onCadastrarNovoMaterial: refStep.origemCatalogo
              ? () async {
                  final yaml = await _carregarYamlCadastroMaterial();
                  if (!context.mounted) return;
                  final novoId = await WizardScreen.abrirSessaoIsolada(
                    context,
                    initialYaml: yaml,
                  );
                  if (novoId != null && novoId.isNotEmpty) {
                    final newIds = List<String>.from(selectedIds);
                    if (!newIds.contains(novoId)) {
                      newIds.add(novoId);
                    }
                    notifier.setRefMateriais(
                      conteudo.id,
                      newIds,
                      listItemId: itemId,
                    );
                  }
                }
              : null,
        );

      case ConteudoStep_Tipo.listaAcoes:
        return ListaAcoesWidget(conteudo: conteudo, parentItemId: itemId);

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

class _SubSecaoRamoAutoScroll extends StatefulWidget {
  final Widget child;
  const _SubSecaoRamoAutoScroll({super.key, required this.child});

  @override
  State<_SubSecaoRamoAutoScroll> createState() => _SubSecaoRamoAutoScrollState();
}

class _SubSecaoRamoAutoScrollState extends State<_SubSecaoRamoAutoScroll> {
  final GlobalKey _topoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      final alvo = _topoKey.currentContext ?? context;
      Scrollable.ensureVisible(
        alvo,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: 0.15,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(key: _topoKey, height: 1),
        widget.child,
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
    final l10n = ResolvedorIdioma.obterTraducoesContexto(context, ref);
    final sessionId = ref.watch(
      wizardControllerProvider.select((s) => s.sessionId),
    );
    final fullKey = listItemId != null
        ? '${conteudoId}__$listItemId'
        : conteudoId;
    final inputKey = ValueKey('input_${sessionId}_$fullKey');
    switch (campo.tipo) {
      case StepCampoSimples_TipoCampo.TEXT:
      case StepCampoSimples_TipoCampo.DATE:
        if (campo.uiHint == StepCampoSimples_UiHint.TEXT_AREA) {
          return _CampoTextoMarkdownArea(
            key: inputKey,
            initialValue: answer,
            hintText: l10n.wizardHintTextoArea,
            onChanged: (v) => _saveString(ref, v),
          );
        }
        return TextFormField(
          key: inputKey,
          initialValue: answer,
          keyboardType: TextInputType.text,
          onChanged: (v) => _saveString(ref, v),
          maxLines: 1,
          decoration: InputDecoration(
            hintText: l10n.wizardHintTexto,
          ),
        );

      case StepCampoSimples_TipoCampo.NUMBER:
        return TextFormField(
          key: inputKey,
          initialValue: answer,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => _saveString(ref, v),
          decoration: InputDecoration(
            hintText: l10n.wizardHintNumeros,
          ),
        );

      case StepCampoSimples_TipoCampo.BOOLEAN:
        return Row(
          children: [
            Expanded(
              child: _SelectionTile(
                title: l10n.comumSim,
                subtitle: '',
                icon: Icons.check_circle_outline,
                isSelected: answer == 'true',
                onTap: () => _saveString(ref, 'true'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SelectionTile(
                title: l10n.comumNao,
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
                  SnackBar(content: Text(l10n.wizardGpsDesativado)),
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
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            );
            _saveString(ref, '${position.latitude}, ${position.longitude}');
            unawaited(
              ServicoTelemetria.instancia.registrarAcaoMidiaWizard(
                acao: 'capturar_gps',
                tipoMidia: 'gps',
                campoId: conteudoId,
              ),
            );
          },
          child: _actionTile(
            icon: has ? Icons.location_on : Icons.gps_fixed,
            label: has ? l10n.wizardGpsCapturado : l10n.wizardGpsCapturar,
            sub: has ? answer : '',
            active: has,
          ),
        );

      case StepCampoSimples_TipoCampo.IMAGE:
      case StepCampoSimples_TipoCampo.VIDEO:
        final isVid = campo.tipo == StepCampoSimples_TipoCampo.VIDEO;
        final fullKey = listItemId != null ? '${conteudoId}__$listItemId' : conteudoId;
        final wizardState = ref.watch(wizardControllerProvider);
        final answerObj = wizardState.answers[fullKey];
        final midias = WizardStateController.extrairMidiasDeResposta(answerObj);
        final qtdProcessando = wizardState.processandoMidiasPorCampo[fullKey] ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < midias.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _midiaAnexadaTile(
                  midia: midias[i],
                  indice: i,
                  chaveCampo: fullKey,
                  l10n: l10n,
                  onRemover: () async {
                    await ref
                        .read(wizardControllerProvider.notifier)
                        .removerMidiaDaResposta(
                          conteudoId,
                          i,
                          listItemId: listItemId,
                        );
                  },
                ),
              ),
            if (qtdProcessando > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _loadingMidiaTile(
                  chaveCampo: fullKey,
                  quantidade: qtdProcessando,
                  l10n: l10n,
                ),
              ),
            GestureDetector(
              onTap: () async {
                final origem = await _selecionarOrigemMidia(
                  context,
                  isVid,
                  l10n,
                );
                if (origem == null) return;

                if (origem == _OrigemMidia.arquivoPdf) {
                  final seletor = ref.read(seletorDocumentoServiceProvider);
                  final doc = await seletor.selecionarPdf();
                  if (doc != null) {
                    await ref
                        .read(wizardControllerProvider.notifier)
                        .saveDocumentAnswerBytes(
                          conteudoId,
                          doc.bytes,
                          nomeOriginal: doc.nome,
                          listItemId: listItemId,
                        );
                  }
                  return;
                }

                final picker = ImagePicker();
                if (origem == _OrigemMidia.fotoCamera) {
                  final image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    await ref
                        .read(wizardControllerProvider.notifier)
                        .saveMediaAnswer(
                          conteudoId,
                          image.path,
                          StepCampoSimples_TipoCampo.IMAGE,
                          listItemId: listItemId,
                        );
                    try {
                      await ref
                          .read(servicoGaleriaDispositivoProvider)
                          .salvarFotoNoRoloDaCamera(image.path);
                    } catch (_) {}
                  }
                } else if (origem == _OrigemMidia.videoCamera) {
                  final video = await picker.pickVideo(source: ImageSource.camera);
                  if (video != null) {
                    try {
                      await ref
                          .read(servicoGaleriaDispositivoProvider)
                          .salvarVideoNoRoloDaCamera(video.path);
                    } catch (_) {}

                    double? inicioCorte;
                    double? duracaoCorte;
                    final duracaoTotal = await ref
                        .read(videoTranscoderServiceProvider)
                        .obterDuracaoSegundos(File(video.path));
                    if (duracaoTotal != null &&
                        duracaoTotal > limiteMaximoDuracaoVideoSegundos) {
                      if (!context.mounted) return;
                      final trecho = await SeletorTrechoVideoDialog.exibir(
                        context,
                        duracaoTotalSegundos: duracaoTotal,
                      );
                      if (trecho == null) return;
                      inicioCorte = trecho.inicioSegundos;
                      duracaoCorte = trecho.duracaoSegundos;
                    }

                    await ref
                        .read(wizardControllerProvider.notifier)
                        .saveMediaAnswer(
                          conteudoId,
                          video.path,
                          StepCampoSimples_TipoCampo.VIDEO,
                          listItemId: listItemId,
                          inicioCorteSegundos: inicioCorte,
                          duracaoCorteSegundos: duracaoCorte,
                        );
                  }
                } else if (origem == _OrigemMidia.galeria) {
                  final arquivos = await picker.pickMultipleMedia();
                  if (arquivos.isEmpty) return;
                  final itensSelecionados = <({
                    String filePath,
                    StepCampoSimples_TipoCampo tipo,
                    double? inicioCorteSegundos,
                    double? duracaoCorteSegundos,
                  })>[];
                  for (final arquivo in arquivos) {
                    final ext = p.extension(arquivo.path).toLowerCase();
                    final mime = arquivo.mimeType?.toLowerCase() ?? '';
                    final ehVideo = mime.startsWith('video/') ||
                        const {
                          '.mp4',
                          '.mov',
                          '.avi',
                          '.mkv',
                          '.webm',
                          '.3gp',
                          '.m4v',
                        }.contains(ext);
                    double? inicioCorte;
                    double? duracaoCorte;
                    if (ehVideo) {
                      final duracaoTotal = await ref
                          .read(videoTranscoderServiceProvider)
                          .obterDuracaoSegundos(File(arquivo.path));
                      if (duracaoTotal != null &&
                          duracaoTotal > limiteMaximoDuracaoVideoSegundos) {
                        if (!context.mounted) return;
                        final trecho = await SeletorTrechoVideoDialog.exibir(
                          context,
                          duracaoTotalSegundos: duracaoTotal,
                        );
                        if (trecho == null) continue;
                        inicioCorte = trecho.inicioSegundos;
                        duracaoCorte = trecho.duracaoSegundos;
                      }
                    }
                    itensSelecionados.add((
                      filePath: arquivo.path,
                      tipo: ehVideo
                          ? StepCampoSimples_TipoCampo.VIDEO
                          : StepCampoSimples_TipoCampo.IMAGE,
                      inicioCorteSegundos: inicioCorte,
                      duracaoCorteSegundos: duracaoCorte,
                    ));
                  }
                  if (itensSelecionados.isEmpty) return;
                  await ref
                      .read(wizardControllerProvider.notifier)
                      .saveMultipleMediaAnswers(
                        conteudoId,
                        itensSelecionados,
                        listItemId: listItemId,
                      );
                }
              },
              child: _actionTile(
                icon: midias.isEmpty
                    ? (isVid ? Icons.videocam_outlined : Icons.camera_alt_outlined)
                    : Icons.add_circle_outline,
                label: l10n.wizardMidiaAdicionar,
                sub: midias.isEmpty
                    ? l10n.wizardMidiaSubVazio
                    : l10n.wizardMidiaSubMais,
                active: false,
              ),
            ),
          ],
        );

      default:
        return Text(
          'Tipo não implementado: ${campo.tipo}',
          style: const TextStyle(color: Colors.white24),
        );
    }
  }

  Widget _midiaAnexadaTile({
    required ReferenciaMidia midia,
    required int indice,
    required String chaveCampo,
    required AppLocalizations l10n,
    required VoidCallback onRemover,
  }) {
    final bool ehPdf = midia.hasDocumento();
    final bool ehVideo = midia.hasVideo();
    final IconData icone = ehPdf
        ? Icons.picture_as_pdf
        : (ehVideo ? Icons.videocam : Icons.check_circle);
    final String rotulo = ehPdf
        ? l10n.wizardMidiaPdfAnexado
        : (ehVideo ? l10n.wizardMidiaVideoGravado : l10n.wizardMidiaFotoCapturada);
    final String subtitulo = ehPdf
        ? '${midia.documento.nomeOriginal} (${midia.documento.quantidadePaginas} pág.)'
        : (ehVideo
            ? 'Anexo #${indice + 1} (${midia.video.tipoOriginal})'
            : 'Anexo #${indice + 1} (${midia.imagem.tipoOriginal})');

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
              icone,
              color: const Color(0xFFFF6B00),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
                if (subtitulo.isNotEmpty)
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: Color(0xFFFF6B00),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: Key('btn_remover_midia_${chaveCampo}_$indice'),
            onPressed: onRemover,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            tooltip: 'Remover mídia',
          ),
        ],
      ),
    );
  }

  Widget _loadingMidiaTile({
    required String chaveCampo,
    required int quantidade,
    required AppLocalizations l10n,
  }) {
    final texto = quantidade > 1
        ? l10n.wizardMidiaProcessandoVarios(quantidade)
        : l10n.wizardMidiaProcessandoUm;
    return Container(
      key: Key('loading_midia_$chaveCampo'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
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
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Color(0xFFFF6B00),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  l10n.wizardMidiaProcessandoSub,
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

  Future<_OrigemMidia?> _selecionarOrigemMidia(
    BuildContext context,
    bool isVideo,
    AppLocalizations l10n,
  ) {
    FocusManager.instance.primaryFocus?.unfocus();
    return showModalBottomSheet<_OrigemMidia>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181A1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final recuoInferiorSo = _obterRecuoInferiorModal(context, ctx);
        return SafeArea(
          bottom: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + recuoInferiorSo),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.wizardMidiaModalTitulo,
                      style: const TextStyle(
                        color: Color(0xFFFF6B00),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF00FF66),
                      ),
                      title: Text(
                        l10n.wizardMidiaTirarFoto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      tileColor: const Color(0xFF22252A),
                      onTap: () => Navigator.pop(ctx, _OrigemMidia.fotoCamera),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(
                        Icons.videocam,
                        color: Color(0xFF4FC3F7),
                      ),
                      title: Text(
                        l10n.wizardMidiaGravarVideo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      tileColor: const Color(0xFF22252A),
                      onTap: () => Navigator.pop(ctx, _OrigemMidia.videoCamera),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(
                        Icons.perm_media,
                        color: Color(0xFF00FF66),
                      ),
                      title: Text(
                        l10n.wizardMidiaEscolherGaleria,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        l10n.wizardMidiaEscolherGaleriaSub,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      tileColor: const Color(0xFF22252A),
                      onTap: () => Navigator.pop(ctx, _OrigemMidia.galeria),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(
                        Icons.picture_as_pdf,
                        color: Color(0xFFFF6B00),
                      ),
                      title: Text(
                        l10n.wizardMidiaSelecionarPdf,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      tileColor: const Color(0xFF22252A),
                      onTap: () => Navigator.pop(ctx, _OrigemMidia.arquivoPdf),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _OrigemMidia {
  fotoCamera,
  videoCamera,
  galeria,
  arquivoPdf,
}

// ─────────────────────────────────────────────────────────────────────────────
// RefMateriais — conteúdo compartilhado entre inline e principal
// ─────────────────────────────────────────────────────────────────────────────

class _RefMateriaisContent extends ConsumerWidget {
  final String label;
  final String sublabel;
  final List<ListItemRecord> allItems;
  final List<String> selectedIds;
  final void Function(String itemId) onToggle;
  final bool origemCatalogo;
  final VoidCallback? onCadastrarNovoMaterial;

  const _RefMateriaisContent({
    required this.label,
    required this.sublabel,
    required this.allItems,
    required this.selectedIds,
    required this.onToggle,
    this.origemCatalogo = false,
    this.onCadastrarNovoMaterial,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ResolvedorIdioma.obterTraducoesContexto(context, ref);
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
              origemCatalogo
                  ? l10n.wizardRefMatVazioCatalogo
                  : l10n.wizardRefMatVazioBloco,
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
        if (onCadastrarNovoMaterial != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onCadastrarNovoMaterial,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              l10n.wizardBotaoCadastrarNovoMaterial,
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
        ],
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
  final bool retornarAoConcluir;
  const SummaryConclusionCard({super.key, this.retornarAoConcluir = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ResolvedorIdioma.obterTraducoesContexto(context, ref);
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
          Text(
            l10n.wizardConclusaoTitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.wizardConclusaoSubtitulo,
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

                // 2. Mostrar loading dialog (apenas quando não retorna direto para sessão pai)
                if (!retornarAoConcluir) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => const GenerationProgressDialog(),
                  );
                }

                // 3. Iniciar geração
                final outputPath = await ref
                    .read(sessionBundleManagerProvider)
                    .getEpubFilePath(sessionId: sessionId);

                final protocol = ref.read(wizardControllerProvider).protocol;

                await ref.read(generationProvider.notifier).startGeneration(
                  protocol?.nome ?? 'Relatório Fixalog',
                  outputPath,
                  sessionId: sessionId,
                );
                ref.read(wizardControllerProvider.notifier).marcarComoSalvo();

                if (retornarAoConcluir && context.mounted) {
                  Navigator.of(context).pop(sessionId);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao gerar relatório: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.description_outlined),
            label: Text(
              l10n.wizardBotaoGerarRelatorio,
              style: const TextStyle(fontWeight: FontWeight.bold),
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

/// Caixa de texto multilinha (`TEXT_AREA`) que suporta quebras de linha/linhas em branco
/// via tecla Enter e estiliza sintaxe Markdown in-place (estilo WhatsApp/Telegram)
/// sem alterar o texto bruto digitado.
class _CampoTextoMarkdownArea extends StatefulWidget {
  final String? initialValue;
  final String? hintText;
  final ValueChanged<String> onChanged;

  const _CampoTextoMarkdownArea({
    super.key,
    required this.initialValue,
    this.hintText,
    required this.onChanged,
  });

  @override
  State<_CampoTextoMarkdownArea> createState() => _CampoTextoMarkdownAreaState();
}

class _CampoTextoMarkdownAreaState extends State<_CampoTextoMarkdownArea> {
  late final _ControladorTextoMarkdown _controller;

  @override
  void initState() {
    super.initState();
    _controller = _ControladorTextoMarkdown(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant _CampoTextoMarkdownArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    final novoValor = widget.initialValue ?? '';
    if (novoValor != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: novoValor,
        selection: TextSelection.collapsed(offset: novoValor.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      minLines: 4,
      maxLines: null,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText:
            widget.hintText ??
            'Digite aqui... (suporta **negrito**, *itálico*, # título e listas)',
      ),
    );
  }
}

/// Controlador de edição que aplica estilização visual in-place para sintaxe
/// Markdown (`# título`, `- lista`, `**negrito**`, `*itálico*`, `` `código` ``, `~~tachado~~`)
/// preservando 100% dos caracteres originais no buffer de texto.
class _ControladorTextoMarkdown extends TextEditingController {
  _ControladorTextoMarkdown({super.text});

  static final RegExp _regexCabecalho = RegExp(r'^(#{1,6}\s+)(.*)$');
  static final RegExp _regexLista = RegExp(r'^(\s*[-*]\s+)(.*)$');
  static final RegExp _regexInline = RegExp(
    r'\*\*(.+?)\*\*|~~(.+?)~~|`([^`]+)`|\*(?!\s)(.+?)(?<!\s)\*',
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final estiloBase = style ?? const TextStyle();
    if (text.isEmpty) {
      return TextSpan(style: estiloBase, text: '');
    }

    final spans = <InlineSpan>[];
    final linhas = text.split('\n');

    for (var i = 0; i < linhas.length; i++) {
      final linha = linhas[i];
      final matchCab = _regexCabecalho.firstMatch(linha);
      if (matchCab != null) {
        final prefixo = matchCab.group(1)!;
        final conteudo = matchCab.group(2)!;
        final estiloTitulo = estiloBase.copyWith(
          color: const Color(0xFFFF6B00),
          fontWeight: FontWeight.bold,
        );
        spans.add(
          TextSpan(
            text: prefixo,
            style: estiloTitulo.copyWith(color: const Color(0x99FF6B00)),
          ),
        );
        spans.addAll(_gerarSpansInline(conteudo, estiloTitulo));
      } else {
        final matchLista = _regexLista.firstMatch(linha);
        if (matchLista != null) {
          final prefixo = matchLista.group(1)!;
          final conteudo = matchLista.group(2)!;
          spans.add(
            TextSpan(
              text: prefixo,
              style: estiloBase.copyWith(
                color: const Color(0xFFFF6B00),
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          spans.addAll(_gerarSpansInline(conteudo, estiloBase));
        } else {
          spans.addAll(_gerarSpansInline(linha, estiloBase));
        }
      }

      if (i < linhas.length - 1) {
        spans.add(TextSpan(text: '\n', style: estiloBase));
      }
    }

    return TextSpan(style: estiloBase, children: spans);
  }

  List<InlineSpan> _gerarSpansInline(String trecho, TextStyle estiloBase) {
    if (trecho.isEmpty) {
      return const [];
    }

    final spans = <InlineSpan>[];
    final estiloDelimitador = estiloBase.copyWith(
      color: (estiloBase.color ?? Colors.white).withValues(alpha: 0.45),
    );
    var cursor = 0;

    for (final match in _regexInline.allMatches(trecho)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: trecho.substring(cursor, match.start),
            style: estiloBase,
          ),
        );
      }

      if (match.group(1) != null) {
        spans.add(TextSpan(text: '**', style: estiloDelimitador));
        spans.add(
          TextSpan(
            text: match.group(1)!,
            style: estiloBase.copyWith(fontWeight: FontWeight.bold),
          ),
        );
        spans.add(TextSpan(text: '**', style: estiloDelimitador));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(text: '~~', style: estiloDelimitador));
        spans.add(
          TextSpan(
            text: match.group(2)!,
            style: estiloBase.copyWith(decoration: TextDecoration.lineThrough),
          ),
        );
        spans.add(TextSpan(text: '~~', style: estiloDelimitador));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(text: '`', style: estiloDelimitador));
        spans.add(
          TextSpan(
            text: match.group(3)!,
            style: estiloBase.copyWith(
              fontFamily: 'monospace',
              color: const Color(0xFF4FC3F7),
            ),
          ),
        );
        spans.add(TextSpan(text: '`', style: estiloDelimitador));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(text: '*', style: estiloDelimitador));
        spans.add(
          TextSpan(
            text: match.group(4)!,
            style: estiloBase.copyWith(fontStyle: FontStyle.italic),
          ),
        );
        spans.add(TextSpan(text: '*', style: estiloDelimitador));
      }

      cursor = match.end;
    }

    if (cursor < trecho.length) {
      spans.add(
        TextSpan(
          text: trecho.substring(cursor),
          style: estiloBase,
        ),
      );
    }

    return spans;
  }
}
