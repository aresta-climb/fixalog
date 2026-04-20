import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/wizard_state_controller.dart';
import '../../../core/models/proto/protos/wizard.pb.dart';
import '../../../core/models/proto/protos/wizard.pbenum.dart';
import '../../../core/utils/protocol_icons.dart';
import '../../../core/services/protocol_parser.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tela principal do Wizard
// ─────────────────────────────────────────────────────────────────────────────

class WizardScreen extends ConsumerStatefulWidget {
  final String initialYaml;
  const WizardScreen({super.key, required this.initialYaml});

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
      final protocol = ProtocolParser.fromYaml(widget.initialYaml);
      ref.read(wizardControllerProvider.notifier).loadProtocol(protocol);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Valida step atual e avança se possível
  void _onNextPressed(WizardState state) {
    HapticFeedback.lightImpact();
    final flowStep = state.currentFlowStep;
    if (flowStep == null) return;

    final step = flowStep.step;
    final kind = step.whichConteudo();

    // StepListaAcoes: verificar mínimo
    if (kind == Step_Conteudo.listaAcoes) {
      final minimo = step.listaAcoes.minimo;
      final count = state.lists[flowStep.answerKey]?.length ?? 0;
      if (minimo > 0 && count < minimo) {
        _showSnack('Adicione pelo menos $minimo item(ns) para continuar.');
        return;
      }
      final success = ref.read(wizardControllerProvider.notifier).nextStep();
      if (success) _scrollToIndex(state.currentIndex + 1);
      return;
    }

    // StepInstrucao: sem validação
    if (kind == Step_Conteudo.instrucao) {
      final success = ref.read(wizardControllerProvider.notifier).nextStep();
      if (success) _scrollToIndex(state.currentIndex + 1);
      return;
    }

    final success = ref.read(wizardControllerProvider.notifier).nextStep();
    if (success) {
      _scrollToIndex(state.currentIndex + 1);
    } else {
      _showSnack('Por favor, preencha este campo antes de prosseguir.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFF5A1E1E),
    ));
  }

  void _scrollToIndex(int index) {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!_scrollController.hasClients) return;
      final state = ref.read(wizardControllerProvider);
      final isSummary = index >= state.queue.length;
      if (isSummary && _summaryKey.currentContext == null) return;
      if (!isSummary && (index >= _cardKeys.length || _cardKeys[index].currentContext == null)) return;

      final key = isSummary ? _summaryKey : _cardKeys[index];
      final ctx = key.currentContext!;
      final box = ctx.findRenderObject() as RenderBox;
      final pos = box.localToGlobal(
        Offset.zero,
        ancestor: _scrollController.position.context.storageContext.findRenderObject(),
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
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
      );
    }

    // Sincronia das GlobalKeys com a fila
    while (_cardKeys.length < state.queue.length) {
      _cardKeys.add(GlobalKey());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF060908),
      body: Stack(
        children: [
          // Fundo
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
            top: -150, left: -100,
            child: Container(
              width: 700, height: 700,
              decoration: BoxDecoration(
                color: const Color(0xFF1B3D2F).withOpacity(0.4),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      // Progresso
                      if (state.queue.isNotEmpty)
                        Text(
                          '${state.currentIndex + 1}/${state.queue.length}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
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
                    backgroundColor: Colors.white.withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B00)),
                    minHeight: 2,
                  ),
                // Conteúdo scrollável
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
                            onNext: () => _onNextPressed(state),
                            onBackToStep: () {
                              ref.read(wizardControllerProvider.notifier).goToStep(index);
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
// Card genérico de step — despacha para o widget correto
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
    final step = flowStep.step;
    final kind = step.whichConteudo();
    final isCurrent = !isLocked && !isCompleted;

    double opacity = 1.0;
    if (isCompleted) opacity = 0.65;
    if (isLocked) opacity = 0.45;

    // Contexto de lista: badge opcional
    final inListContext = flowStep.listItemId != null;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? Colors.white.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
            width: isCurrent ? 1.2 : 1.0,
          ),
        ),
        child: Column(
          children: [
            // Indicador de contexto de lista
            if (inListContext)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2318),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Text(
                  'Item da lista',
                  style: TextStyle(
                    color: const Color(0xFF4CAF50).withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Label do passo
                  Text(
                    'PASSO $stepIndex',
                    style: TextStyle(
                      color: isCurrent
                          ? const Color(0xFFFF6B00)
                          : Colors.white.withOpacity(0.35),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Conteúdo do step
                  IgnorePointer(
                    ignoring: !isCurrent,
                    child: _buildStepContent(context, ref, step, kind, isCurrent),
                  ),
                  // Botões de navegação
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
                              letterSpacing: 0.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.1)),
                          backgroundColor: Colors.white.withOpacity(0.04),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    WidgetRef ref,
    Step step,
    Step_Conteudo kind,
    bool isCurrent,
  ) {
    return switch (kind) {
      Step_Conteudo.instrucao    => InstrucaoWidget(step: step),
      Step_Conteudo.campoSimples => CampoSimplesWidget(flowStep: flowStep, isCurrent: isCurrent),
      Step_Conteudo.selecaoRamo  => SelecaoRamoWidget(flowStep: flowStep, isCurrent: isCurrent),
      Step_Conteudo.listaAcoes   => ListaAcoesWidget(flowStep: flowStep, isCurrent: isCurrent),
      Step_Conteudo.refMateriais => RefMateriaisWidget(flowStep: flowStep, isCurrent: isCurrent),
      _ => const Text('Tipo de step não suportado', style: TextStyle(color: Colors.white24)),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botão "Próximo" adaptável
// ─────────────────────────────────────────────────────────────────────────────

class _NextButton extends ConsumerWidget {
  final FlowStep flowStep;
  final bool isLastStep;
  final VoidCallback onNext;
  const _NextButton({required this.flowStep, required this.isLastStep, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardControllerProvider);
    final hasAnswer = state.answers.containsKey(flowStep.answerKey);
    final step = flowStep.step;
    final kind = step.whichConteudo();

    // StepInstrucao e StepListaAcoes sempre habilitados
    final alwaysEnabled =
        kind == Step_Conteudo.instrucao || kind == Step_Conteudo.listaAcoes;
    final isEnabled = alwaysEnabled || hasAnswer;

    String label;
    if (kind == Step_Conteudo.instrucao) {
      label = 'ENTENDIDO';
    } else if (kind == Step_Conteudo.listaAcoes) {
      final count = state.lists[flowStep.answerKey]?.length ?? 0;
      label = count > 0 ? 'CONCLUIR LISTA ($count)' : 'PULAR';
    } else if (isLastStep) {
      label = 'ASSINAR E CONCLUIR';
    } else {
      label = 'SEGUINTE';
    }

    return ElevatedButton(
      onPressed: onNext,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isEnabled ? const Color(0xFFFF6B00) : Colors.white.withOpacity(0.08),
        foregroundColor: isEnabled ? Colors.white : Colors.white24,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StepInstrucao
// ─────────────────────────────────────────────────────────────────────────────

class InstrucaoWidget extends StatelessWidget {
  final Step step;
  const InstrucaoWidget({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final inst = step.instrucao;
    final Color alertColor = switch (inst.nivelAlerta) {
      StepInstrucao_NivelAlerta.PERIGO  => const Color(0xFFFF3D3D),
      StepInstrucao_NivelAlerta.ATENCAO => const Color(0xFFFFB800),
      _                                  => const Color(0xFF4FC3F7),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Título
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                ProtocolIcons.get(inst.iconName),
                color: alertColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                inst.titulo,
                style: TextStyle(
                  color: alertColor,
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (inst.corpo.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: alertColor.withOpacity(0.2)),
            ),
            child: Text(
              inst.corpo,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
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
// StepCampoSimples
// ─────────────────────────────────────────────────────────────────────────────

class CampoSimplesWidget extends ConsumerWidget {
  final FlowStep flowStep;
  final bool isCurrent;
  const CampoSimplesWidget({super.key, required this.flowStep, required this.isCurrent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(wizardControllerProvider);
    final campo  = flowStep.step.campoSimples;
    final answer = state.answers[flowStep.answerKey];

    void saveAnswer(String val) =>
        ref.read(wizardControllerProvider.notifier).answerCurrentStep(val);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          campo.label,
          style: TextStyle(
            color: isCurrent ? Colors.white : Colors.white70,
            fontFamily: 'SpaceGrotesk',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        if (campo.sublabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(campo.sublabel,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.4)),
        ],
        const SizedBox(height: 24),
        _buildInput(campo, answer, isCurrent, saveAnswer),
      ],
    );
  }

  Widget _buildInput(StepCampoSimples campo, String? answer, bool isCurrent,
      void Function(String) save) {
    switch (campo.tipo) {
      case StepCampoSimples_TipoCampo.TEXT:
      case StepCampoSimples_TipoCampo.NUMBER:
      case StepCampoSimples_TipoCampo.DATE:
        final isMultiline = campo.uiHint == StepCampoSimples_UiHint.TEXT_AREA;
        return TextFormField(
          initialValue: answer,
          readOnly: !isCurrent,
          maxLines: isMultiline ? 4 : 1,
          keyboardType: campo.tipo == StepCampoSimples_TipoCampo.NUMBER
              ? TextInputType.number
              : TextInputType.text,
          style: TextStyle(
              color: isCurrent ? Colors.white : Colors.white24, fontSize: 16),
          decoration: _inputDecoration(
            campo.tipo == StepCampoSimples_TipoCampo.DATE
                ? 'DD/MM/AAAA'
                : 'DIGITE AQUI...',
          ),
          onChanged: save,
        );

      case StepCampoSimples_TipoCampo.BOOLEAN:
        return Row(
          children: [
            Expanded(
              child: _SelectionTile(
                title: 'SIM',
                subtitle: '',
                icon: Icons.check_circle_outline,
                isSelected: answer == 'true',
                onTap: () => save('true'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SelectionTile(
                title: 'NÃO',
                subtitle: '',
                icon: Icons.cancel_outlined,
                isSelected: answer == 'false',
                onTap: () => save('false'),
              ),
            ),
          ],
        );

      case StepCampoSimples_TipoCampo.DROPDOWN:
        if (campo.uiHint == StepCampoSimples_UiHint.LARGE_TILES) {
          return Column(
            children: campo.opcoes.map((opcao) {
              return _SelectionTile(
                title: opcao.label,
                subtitle: opcao.sublabel,
                icon: ProtocolIcons.get(opcao.iconName),
                isSelected: answer == opcao.valor,
                onTap: () => save(opcao.valor),
              );
            }).toList(),
          );
        }
        // Dropdown padrão
        return DropdownButtonFormField<String>(
          value: answer,
          dropdownColor: const Color(0xFF1A1C1E),
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('SELECIONE...'),
          items: campo.opcoes
              .map((o) => DropdownMenuItem(value: o.valor, child: Text(o.label)))
              .toList(),
          onChanged: isCurrent ? (v) => save(v ?? '') : null,
        );

      case StepCampoSimples_TipoCampo.GPS:
        final hasCoord = answer != null && answer.isNotEmpty;
        return GestureDetector(
          onTap: isCurrent
              ? () => save('-19.9218, -43.9366') // mock
              : null,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1D1C),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(
                  hasCoord ? Icons.location_on : Icons.gps_fixed,
                  color: hasCoord ? const Color(0xFFFF6B00) : Colors.white24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    hasCoord ? 'COORDENADAS CAPTURADAS' : 'CAPTURAR POSIÇÃO',
                    style: TextStyle(
                        color: hasCoord ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.0),
                  ),
                  if (hasCoord)
                    Text(answer,
                        style: TextStyle(
                            color: const Color(0xFFFF6B00).withOpacity(0.7),
                            fontSize: 10,
                            fontFamily: 'monospace')),
                ]),
              ),
            ]),
          ),
        );

      case StepCampoSimples_TipoCampo.IMAGE:
      case StepCampoSimples_TipoCampo.VIDEO:
        final isCaptured = answer != null && answer.isNotEmpty;
        final isVideo = campo.tipo == StepCampoSimples_TipoCampo.VIDEO;
        return GestureDetector(
          onTap: isCurrent ? () => save(isVideo ? 'video_captured.mp4' : 'image_captured.jpg') : null,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1D1C),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(
                  isCaptured
                      ? Icons.check_circle
                      : (isVideo ? Icons.videocam_outlined : Icons.camera_alt_outlined),
                  color: isCaptured ? Colors.greenAccent : Colors.white24,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isCaptured ? (isVideo ? 'VÍDEO GRAVADO' : 'FOTO CAPTURADA') : (isVideo ? 'GRAVAR VÍDEO' : 'ABRIR CÂMERA'),
                style: TextStyle(
                    color: isCaptured ? Colors.greenAccent : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.0),
              ),
            ]),
          ),
        );

      case StepCampoSimples_TipoCampo.SIGNATURE:
        final hasSig = answer != null && answer.isNotEmpty;
        return GestureDetector(
          onTap: isCurrent ? () => save('signature_data') : null,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: hasSig
                        ? const Color(0xFFFF6B00).withOpacity(0.4)
                        : Colors.white.withOpacity(0.05))),
            child: Center(
              child: hasSig
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle, color: Color(0xFFFF6B00), size: 40),
                      const SizedBox(height: 8),
                      const Text('ASSINATURA REGISTRADA',
                          style: TextStyle(
                              color: Color(0xFFFF6B00),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1.0)),
                    ])
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.gesture, color: Colors.white.withOpacity(0.12), size: 48),
                      const SizedBox(height: 8),
                      Text('TOQUE PARA ASSINAR',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.25),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1.0)),
                    ]),
            ),
          ),
        );

      default:
        return Text('Tipo de campo não implementado: ${campo.tipo}',
            style: const TextStyle(color: Colors.white24));
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        filled: true,
        fillColor: Colors.black26,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFFFF6B00).withOpacity(0.5))),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// StepSelecaoRamo
// ─────────────────────────────────────────────────────────────────────────────

class SelecaoRamoWidget extends ConsumerWidget {
  final FlowStep flowStep;
  final bool isCurrent;
  const SelecaoRamoWidget({super.key, required this.flowStep, required this.isCurrent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(wizardControllerProvider);
    final selecao  = flowStep.step.selecaoRamo;
    final selected = state.answers[flowStep.answerKey];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          selecao.label,
          style: TextStyle(
            color: isCurrent ? Colors.white : Colors.white70,
            fontFamily: 'SpaceGrotesk',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (selecao.sublabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(selecao.sublabel,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.4)),
        ],
        const SizedBox(height: 20),
        ...selecao.ramos.map((ramo) => _SelectionTile(
              title: ramo.label,
              subtitle: ramo.sublabel,
              icon: ProtocolIcons.get(ramo.iconName),
              isSelected: selected == ramo.id,
              onTap: isCurrent
                  ? () => ref
                      .read(wizardControllerProvider.notifier)
                      .chooseRamo(ramo.id)
                  : null,
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StepListaAcoes
// ─────────────────────────────────────────────────────────────────────────────

class ListaAcoesWidget extends ConsumerWidget {
  final FlowStep flowStep;
  final bool isCurrent;
  const ListaAcoesWidget({super.key, required this.flowStep, required this.isCurrent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(wizardControllerProvider);
    final lista    = flowStep.step.listaAcoes;
    final items    = state.lists[flowStep.answerKey] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lista.label,
          style: TextStyle(
              color: isCurrent ? Colors.white : Colors.white70,
              fontFamily: 'SpaceGrotesk',
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        if (lista.sublabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(lista.sublabel,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.4)),
        ],
        const SizedBox(height: 20),
        // Itens já adicionados
        if (items.isNotEmpty) ...[
          ...items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2318),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(ProtocolIcons.get(item.tipoIconName),
                      color: const Color(0xFF4CAF50), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item.tipoLabel,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Icon(Icons.check_circle, color: const Color(0xFF4CAF50).withOpacity(0.6), size: 16),
                ]),
              )),
          const SizedBox(height: 12),
        ],
        // Botão de adicionar
        if (isCurrent && (lista.maximo == 0 || items.length < lista.maximo))
          OutlinedButton.icon(
            onPressed: () => _showAddItemSheet(context, ref, lista),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              items.isEmpty ? 'ADICIONAR ITEM' : 'ADICIONAR OUTRO',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B00),
              side: BorderSide(color: const Color(0xFFFF6B00).withOpacity(0.4)),
              backgroundColor: const Color(0xFFFF6B00).withOpacity(0.05),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        if (lista.minimo > 0 && items.length < lista.minimo) ...[
          const SizedBox(height: 8),
          Text(
            'Mínimo ${lista.minimo} item(ns) necessário(s).',
            style: TextStyle(color: Colors.orange.withOpacity(0.6), fontSize: 11),
          ),
        ],
      ],
    );
  }

  void _showAddItemSheet(BuildContext context, WidgetRef ref, StepListaAcoes lista) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181A1C),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 16),
            ...lista.tiposDisponiveis.map((tipo) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(wizardControllerProvider.notifier).addListItem(
                          listStepId: flowStep.answerKey,
                          tipo: tipo,
                        );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.08))),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1A1D1C),
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(ProtocolIcons.get(tipo.iconName),
                            color: Colors.white54, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tipo.label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            if (tipo.sublabel.isNotEmpty)
                              Text(tipo.sublabel,
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white24),
                    ]),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StepRefMateriais
// ─────────────────────────────────────────────────────────────────────────────

class RefMateriaisWidget extends ConsumerWidget {
  final FlowStep flowStep;
  final bool isCurrent;
  const RefMateriaisWidget({super.key, required this.flowStep, required this.isCurrent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state       = ref.watch(wizardControllerProvider);
    final refStep     = flowStep.step.refMateriais;
    final allItems    = state.lists[refStep.idStepMateriais] ?? [];
    final selectedIds = state.refSelections[flowStep.answerKey] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          refStep.label,
          style: TextStyle(
              color: isCurrent ? Colors.white : Colors.white70,
              fontFamily: 'SpaceGrotesk',
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        if (refStep.sublabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(refStep.sublabel,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.4)),
        ],
        const SizedBox(height: 20),
        if (allItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Text(
              'Nenhum material registrado no Bloco 1.\nVolte e adicione os materiais primeiro.',
              style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...allItems.map((item) {
            final isSelected = selectedIds.contains(item.id);
            return GestureDetector(
              onTap: isCurrent
                  ? () {
                      final newIds = List<String>.from(selectedIds);
                      if (isSelected) {
                        newIds.remove(item.id);
                      } else {
                        newIds.add(item.id);
                      }
                      ref.read(wizardControllerProvider.notifier).setRefMateriais(newIds);
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.02) : Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF6B00).withOpacity(0.5)
                        : Colors.white.withOpacity(0.06),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Icon(ProtocolIcons.get(item.tipoIconName),
                      color: isSelected ? const Color(0xFFFF6B00) : Colors.white38,
                      size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item.tipoLabel,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF6B00)
                              : Colors.white24,
                          width: 2),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.check, color: Color(0xFFFF6B00), size: 12))
                        : null,
                  ),
                ]),
              ),
            );
          }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utilitários compartilhados
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.02) : Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6B00).withOpacity(0.6)
                : Colors.white.withOpacity(0.05),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFF121416),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon,
                color: isSelected ? const Color(0xFFFF6B00) : Colors.white38,
                size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              if (subtitle.isNotEmpty)
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
            ]),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: isSelected ? const Color(0xFFFF6B00) : Colors.white12,
                  width: 2),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFFFF6B00), shape: BoxShape.circle)))
                : null,
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tela de conclusão
// ─────────────────────────────────────────────────────────────────────────────

class SummaryConclusionCard extends StatelessWidget {
  const SummaryConclusionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05))),
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
                fontFamily: 'SpaceGrotesk'),
          ),
          const SizedBox(height: 12),
          Text(
            'Todos os dados foram coletados offline.\nO registro está pronto para ser assinado e exportado.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check),
            label: const Text('FECHAR',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
