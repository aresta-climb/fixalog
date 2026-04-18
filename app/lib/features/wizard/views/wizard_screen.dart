import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/wizard_state_controller.dart';
import '../../../core/models/proto/protos/fixalog.pb.dart';
import '../../../core/utils/protocol_icons.dart';
import '../../../core/services/protocol_parser.dart';

class WizardScreen extends ConsumerStatefulWidget {
  final String initialYaml;
  const WizardScreen({super.key, required this.initialYaml});

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mockProtocol = ProtocolParser.fromYaml(widget.initialYaml);
      ref.read(wizardControllerProvider.notifier).loadProtocol(mockProtocol);
    });
  }

  void _onNextPressed(WizardState state, int fieldIndex) {
    HapticFeedback.lightImpact(); 
    final field = state.protocol!.campos[fieldIndex];
    if (field.obrigatorio && !state.answers.containsKey(field.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha este campo antes de prosseguir.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFF5A1E1E),
        ),
      );
      return;
    }

    final success = ref.read(wizardControllerProvider.notifier).nextStep();
    if (success) {
      _scrollToIndex(state.currentStep + 1);
    }
  }

  void _scrollToIndex(int index) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          index * 450.0, 
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: const Color(0xFF060908),
      body: Stack(
        children: [
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: [
                        ...state.protocol!.campos.asMap().entries.map((entry) {
                          final index = entry.key;
                          final campo = entry.value;
                          final isLocked = index > state.currentStep;
                          final isCompleted = index < state.currentStep;

                          return FieldInputCard(
                            campo: campo,
                            stepIndex: index + 1,
                            isLastField: index == state.protocol!.campos.length - 1,
                            onNext: () => _onNextPressed(state, index),
                            onBackToStep: () {
                              ref.read(wizardControllerProvider.notifier).goToStep(index);
                              _scrollToIndex(index);
                            },
                            isLocked: isLocked,
                            isCompleted: isCompleted,
                          );
                        }),
                        if (state.currentStep == state.protocol!.campos.length)
                          const SummaryConclusionCard(),
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

class FieldInputCard extends ConsumerWidget {
  final Campo campo;
  final int stepIndex;
  final bool isLastField;
  final VoidCallback onNext;
  final VoidCallback onBackToStep;
  final bool isLocked;
  final bool isCompleted;

  const FieldInputCard({
    super.key, 
    required this.campo, 
    required this.stepIndex,
    required this.isLastField,
    required this.onNext,
    required this.onBackToStep,
    required this.isLocked,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardControllerProvider);
    final answer = state.answers[campo.id];
    final isCurrent = !isLocked && !isCompleted;

    double opacity = 1.0;
    if (isCompleted) opacity = 0.65;
    if (isLocked) opacity = 0.45;

    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
        ignoring: isLocked,
        child: Container(
          margin: const EdgeInsets.all(12.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1C1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.04),
              width: isCurrent ? 1.2 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PASSO $stepIndex',
                style: TextStyle(
                  color: isCurrent ? const Color(0xFFFF6B00) : Colors.white.withOpacity(0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                campo.label,
                style: TextStyle(
                  color: isCurrent ? Colors.white : Colors.white70,
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              if (campo.sublabel.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  campo.sublabel,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.4),
                ),
              ],
              const SizedBox(height: 32),
              _buildInputContent(context, ref, answer),
              if (isCompleted) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onBackToStep,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white38,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 14),
                        SizedBox(width: 6),
                        Text('VOLTAR A ESTE PASSO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
              if (isCurrent) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(isLastField ? 'ASSINAR E CONCLUIR' : 'SEGUINTE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputContent(BuildContext context, WidgetRef ref, RespostaCampo? answer) {
    switch (campo.tipo) {
      case Campo_Tipo.DROPDOWN:
        if (campo.uiHint == Campo_UIHint.LARGE_TILES) {
          return Column(
            children: campo.opcoes.map((opcao) {
              final isSelected = answer?.valorTexto == opcao.valor;
              return _SelectionTile(
                title: opcao.label,
                subtitle: opcao.sublabel,
                icon: ProtocolIcons.get(opcao.iconName),
                isSelected: isSelected,
                onTap: () {
                  ref.read(wizardControllerProvider.notifier).answerCurrentField(
                    RespostaCampo(valorTexto: opcao.valor),
                  );
                },
              );
            }).toList(),
          );
        }
        return const Text('Dropdown padrão não implementado', style: TextStyle(color: Colors.white24));
        
      case Campo_Tipo.IMAGE:
        if (campo.uiHint == Campo_UIHint.CAMERA_ACTION) {
          return _PhotoActionBox(
            isCaptured: answer != null && answer.valorTexto.isNotEmpty,
            onTap: () {
              ref.read(wizardControllerProvider.notifier).answerCurrentField(
                RespostaCampo(valorTexto: 'image_captured.png'),
              );
            },
          );
        }
        return const Text('Uploader padrão não implementado', style: TextStyle(color: Colors.white24));
        
      default:
        return Text('Input para ${campo.tipo} não implementado', style: const TextStyle(color: Colors.white24));
    }
  }
}

class _SelectionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionTile({required this.title, required this.subtitle, required this.icon, required this.isSelected, required this.onTap});

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
            color: isSelected ? const Color(0xFFFF6B00).withOpacity(0.6) : Colors.white.withOpacity(0.05),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF121416), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: isSelected ? const Color(0xFFFF6B00) : Colors.white38, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
            ),
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFFFF6B00) : Colors.white12, width: 2),
              ),
              child: isSelected ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF6B00), shape: BoxShape.circle))) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoActionBox extends StatelessWidget {
  final bool isCaptured;
  final VoidCallback onTap;

  const _PhotoActionBox({required this.isCaptured, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 180,
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1A1D1C), borderRadius: BorderRadius.circular(12)),
              child: Icon(isCaptured ? Icons.check_circle : Icons.camera_alt_outlined, color: isCaptured ? Colors.greenAccent : Colors.white24, size: 32),
            ),
            const SizedBox(height: 16),
            Text(isCaptured ? 'FOTO CAPTURADA' : 'ABRIR CÂMERA', style: TextStyle(color: isCaptured ? Colors.greenAccent : Colors.white38, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }
}

class SummaryConclusionCard extends StatelessWidget {
  const SummaryConclusionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400, margin: const EdgeInsets.all(16.0), padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(color: const Color(0xFF1A1C1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("PRONTO PARA ASSINAR", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'SpaceGrotesk')),
          const SizedBox(height: 16),
          Text("Todos os campos coletados offline.\nDeslize o dedo abaixo para registrar o termo de responsabilidade.", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 32),
          Expanded(child: Container(decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.02))), child: const Center(child: Icon(Icons.gesture, color: Colors.white10, size: 48)))),
        ],
      )
    );
  }
}
