import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/proto/protos/fixalog.pb.dart';

class WizardState {
  final Protocolo? protocol;
  final int currentStep;
  final Map<String, RespostaCampo> answers;

  WizardState({this.protocol, this.currentStep = 0, this.answers = const {}});

  WizardState copyWith({
    Protocolo? protocol,
    int? currentStep,
    Map<String, RespostaCampo>? answers,
  }) {
    return WizardState(
      protocol: protocol ?? this.protocol,
      currentStep: currentStep ?? this.currentStep,
      answers: answers ?? this.answers,
    );
  }
}

class WizardStateController extends Notifier<WizardState> {
  @override
  WizardState build() {
    return WizardState();
  }

  void loadProtocol(Protocolo protocol) {
    state = state.copyWith(protocol: protocol, currentStep: 0, answers: {});
  }

  bool nextStep() {
    if (state.protocol == null) return false;
    
    final currentField = state.protocol!.campos[state.currentStep];
    final hasAnswer = state.answers.containsKey(currentField.id);
    
    if (currentField.obrigatorio && !hasAnswer) {
      return false; // Bloqueia avanço
    }
    
    if (state.currentStep < state.protocol!.campos.length) {
      // Se chegamos no limite, estamos na "Tela de Conclusão e Resumo" (step extra igual a campos.length)
      state = state.copyWith(currentStep: state.currentStep + 1);
      return true;
    }
    return false;
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void answerCurrentField(RespostaCampo response) {
    if (state.protocol == null) return;
    if (state.currentStep >= state.protocol!.campos.length) return;
    
    final currentField = state.protocol!.campos[state.currentStep];
    final updatedAnswers = Map<String, RespostaCampo>.from(state.answers);
    
    // Garante que a reposta mapeia nativamente ao Id
    response.idCampo = currentField.id;
    updatedAnswers[currentField.id] = response;
    
    state = state.copyWith(answers: updatedAnswers);
  }
}

final wizardControllerProvider = NotifierProvider<WizardStateController, WizardState>(() {
  return WizardStateController();
});
