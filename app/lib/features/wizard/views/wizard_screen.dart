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
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Stub: Iniciar protocolo Mock apenas para teste/montagem do UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mockProtocol = Protocolo(
        id: "acec_mg_rebolting_v1",
        nome: "Manutenção de Ferragens - ACEC-MG",
        campos: [
          Campo(id: 'tipo_ancoragem', label: 'Tipo de Ancoragem', tipo: Campo_Tipo.DROPDOWN, obrigatorio: true, opcoes: ["Parabolt", "Resina"]),
          Campo(id: 'qtd_grampos', label: 'Quantidade Instalada', tipo: Campo_Tipo.NUMBER, obrigatorio: true),
          Campo(id: 'foto_evidencia', label: 'Foto (Evidência Obrigatória)', tipo: Campo_Tipo.IMAGE, obrigatorio: true),
        ],
      );
      ref.read(wizardControllerProvider.notifier).loadProtocol(mockProtocol);
    });
  }

  void _onNextPressed(WizardState state) {
    HapticFeedback.lightImpact(); // Efeito haptico Outdoor
    final success = ref.read(wizardControllerProvider.notifier).nextStep();
    if (success) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // Input Validation UI feedback (bloqueado)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campo obrigatório não preenchido', style: TextStyle(color: Colors.white))),
      );
    }
  }

  void _onPrevPressed() {
    HapticFeedback.selectionClick();
    ref.read(wizardControllerProvider.notifier).previousStep();
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wizardControllerProvider);

    if (state.protocol == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121416), // Floor
      appBar: AppBar(
        title: Text(state.protocol!.nome),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ViewPager (Thermomix Cards)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Bloqueia swipe livre
              itemCount: state.protocol!.campos.length + 1, // +1 para a tela de conclusão final
              itemBuilder: (context, index) {
                if (index == state.protocol!.campos.length) {
                  return const SummaryConclusionCard();
                }
                return FieldInputCard(campo: state.protocol!.campos[index]);
              },
            ),
          ),
          
          // Barra fixa inferior (Navegação)
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1C1E), // Content Section elev
            child: Row(
              children: [
                if (state.currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF5A4136), width: 1), // Ghost border
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _onPrevPressed,
                      child: const Text('ANTERIOR', style: TextStyle(color: Color(0xFFAED09F))), // Moss Green
                    ),
                  ),
                if (state.currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _onNextPressed(state),
                    child: Text(state.currentStep == state.protocol!.campos.length ? 'ASSINAR E CONCLUIR' : 'PRÓXIMO'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class FieldInputCard extends ConsumerWidget {
  final Campo campo;
  const FieldInputCard({super.key, required this.campo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF333537), // Interactive Cards
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(campo.label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'SpaceGrotesk')),
          const SizedBox(height: 32),
          if (campo.tipo == Campo_Tipo.TEXT || campo.tipo == Campo_Tipo.NUMBER)
             TextFormField(
              keyboardType: campo.tipo == Campo_Tipo.NUMBER ? TextInputType.number : TextInputType.text,
              onChanged: (val) {
                final resposta = RespostaCampo(valorTexto: val);
                ref.read(wizardControllerProvider.notifier).answerCurrentField(resposta);
              },
            ),
          if (campo.tipo == Campo_Tipo.IMAGE)
             Container(
               height: 150,
               decoration: BoxDecoration(border: Border.all(color: const Color(0xFFFF6B00))),
               child: const Center(child: Icon(Icons.camera_alt, color: Color(0xFFFF6B00), size: 48)),
             ), // UI Mock
             const SizedBox(height: 10),
             if(campo.tipo == Campo_Tipo.IMAGE)
               ElevatedButton(
                 onPressed: () {
                    // MOCK answer to clear dependency
                    ref.read(wizardControllerProvider.notifier).answerCurrentField(RespostaCampo(valorTexto: 'image_captured.png'));
                 }, 
                 child: const Text("TIRAR FOTO (MOCK PARA TESTE)")
               ),
        ],
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
