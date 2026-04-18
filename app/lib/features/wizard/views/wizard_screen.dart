import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/wizard_state_controller.dart';
import '../../../core/models/proto/protos/fixalog.pb.dart';

class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key});

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Protocolo Mock atualizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mockProtocol = Protocolo(
        id: "acec_mg_protecoes_v1",
        nome: "Manutenção de Ferragens - ACEC-MG",
        campos: [
          Campo(
            id: 'liga_metalica', 
            label: 'Qual a liga metálica usada?', 
            tipo: Campo_Tipo.DROPDOWN, 
            obrigatorio: true, 
            opcoes: ["Inox 304", "Inox 316L", "Titânio"],
          ),
          Campo(
            id: 'foto_instalacao', 
            label: 'Tirar Foto da Instalação', 
            tipo: Campo_Tipo.IMAGE, 
            obrigatorio: true,
          ),
        ],
      );
      ref.read(wizardControllerProvider.notifier).loadProtocol(mockProtocol);
    });
  }

  void _onNextPressed(WizardState state, int fieldIndex) {
    HapticFeedback.lightImpact(); 
    
    // Validar se o campo atual está preenchido
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
      // Scroll para o próximo card
      _scrollToIndex(state.currentStep + 1);
    }
  }

  void _scrollToIndex(int index) {
    // Pequeno delay para garantir que o teclado (se houver) não atrapalhe e que o estado atualize
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        // Encontrar o offset aproximado ou usar chaves (GlobalKeys) seria o ideal, 
        // mas para um mock fixo usaremos um offset estimado por card.
        _scrollController.animateTo(
          index * 450.0, // Estimativa da altura média do card
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
          
          // 2. Blobs de Cor
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 700,
              height: 700,
              decoration: BoxDecoration(
                color: const Color(0xFF1B3D2F).withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // 3. Efeito de Desfoque Atmosférico
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
                // Header Customizado
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

                // Lista de Cards Sequenciais
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
                        
                        // Resumo Final (Apenas visível se completar tudo)
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
        ignoring: isLocked, // Removido isCompleted para permitir clicar no botão "Voltar"
        child: Container(
          margin: const EdgeInsets.all(12.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1C1E), // Cinza sólido para contraste
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.04),
              width: isCurrent ? 1.2 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step Indicator
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
              
              // Question
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
              const SizedBox(height: 8),
              
              // Description
              if (campo.id == 'liga_metalica')
                Text(
                  'Selecione o material principal dos grampos e ancoragens instalados.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              
              const SizedBox(height: 32),

              // Inputs
              _buildInputContent(context, ref, answer),

              // Botão VOLTAR: Apenas em passos CONCLUÍDOS
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
                        Text(
                          'VOLTAR A ESTE PASSO',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Botão SEGUINTE: Apenas no passo ATUAL
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastField ? 'ASSINAR E CONCLUIR' : 'SEGUINTE',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
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
    if (campo.tipo == Campo_Tipo.DROPDOWN) {
      return Column(
        children: campo.opcoes.map((opcao) {
          final isSelected = answer?.valorTexto == opcao;
          return _SelectionTile(
            title: opcao,
            subtitle: _getSubtitleForOpcao(opcao),
            icon: _getIconForOpcao(opcao),
            isSelected: isSelected,
            onTap: () {
              ref.read(wizardControllerProvider.notifier).answerCurrentField(
                RespostaCampo(valorTexto: opcao),
              );
            },
          );
        }).toList(),
      );
    }

    if (campo.tipo == Campo_Tipo.IMAGE) {
      return Column(
        children: [
          _PhotoActionBox(
            isCaptured: answer != null && answer.valorTexto.isNotEmpty,
            onTap: () {
              ref.read(wizardControllerProvider.notifier).answerCurrentField(
                RespostaCampo(valorTexto: 'image_captured.png'),
              );
            },
          ),
        ],
      );
    }

    return TextFormField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (val) {
        ref.read(wizardControllerProvider.notifier).answerCurrentField(
          RespostaCampo(valorTexto: val),
        );
      },
    );
  }

  String _getSubtitleForOpcao(String opcao) {
    if (opcao == 'Inox 304') return 'USO GERAL';
    if (opcao == 'Inox 316L') return 'ALTA RESISTÊNCIA';
    if (opcao == 'Titânio') return 'EXTREMO';
    return '';
  }

  IconData _getIconForOpcao(String opcao) {
    if (opcao == 'Titânio') return Icons.diamond_outlined;
    return Icons.layers_outlined;
  }
}

class _SelectionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

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
            color: isSelected ? const Color(0xFFFF6B00).withOpacity(0.6) : Colors.white.withOpacity(0.05),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF121416),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isSelected ? const Color(0xFFFF6B00) : Colors.white38, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
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
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFFFF6B00), shape: BoxShape.circle),
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

class _PhotoActionBox extends StatelessWidget {
  final bool isCaptured;
  final VoidCallback onTap;

  const _PhotoActionBox({required this.isCaptured, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D1C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCaptured ? Icons.check_circle : Icons.camera_alt_outlined, 
                color: isCaptured ? Colors.greenAccent : Colors.white24, 
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCaptured ? 'FOTO CAPTURADA' : 'ABRIR CÂMERA',
              style: TextStyle(
                color: isCaptured ? Colors.greenAccent : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
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
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF333537),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("PRONTO PARA ASSINAR", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'SpaceGrotesk')),
          SizedBox(height: 16),
          Text("Todos os campos coletados offline.\nDeslize o dedo abaixo para registrar termo de responsabilizade técnica."),
          SizedBox(height: 16),
          Expanded(child: Placeholder(color: Color(0xFFFF6B00))), // Fake Canvas
        ],
      )
    );
  }
}
