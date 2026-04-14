import 'package:app/features/wizard/controllers/wizard_state_controller.dart';
import 'package:app/core/models/proto/protos/fixalog.pb.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WizardStateController Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is empty', () {
      final state = container.read(wizardControllerProvider);
      expect(state.protocol, isNull);
      expect(state.currentStep, 0);
      expect(state.answers.isEmpty, true);
    });

    test('Load protocol updates state correctly', () {
      final controller = container.read(wizardControllerProvider.notifier);
      final proto = Protocolo(
        id: '123',
        nome: 'Test Protocol',
        campos: [
          Campo(id: 'c1', obrigatorio: true, tipo: Campo_Tipo.TEXT),
          Campo(id: 'c2', obrigatorio: false, tipo: Campo_Tipo.BOOLEAN),
        ],
      );

      controller.loadProtocol(proto);

      final state = container.read(wizardControllerProvider);
      expect(state.protocol?.id, '123');
      expect(state.answers.isEmpty, true);
    });

    test('nextStep blocks if required field has no answer', () {
      final controller = container.read(wizardControllerProvider.notifier);
      final proto = Protocolo(
        id: '123',
        campos: [
          Campo(id: 'c1', obrigatorio: true, tipo: Campo_Tipo.TEXT),
        ],
      );

      controller.loadProtocol(proto);
      bool success = controller.nextStep();
      
      expect(success, false, reason: "Deve barrar porque o campo obrigatório está limpo.");
      
      final state = container.read(wizardControllerProvider);
      expect(state.currentStep, 0);
    });

    test('answerCurrentField records response and nextStep works', () {
      final controller = container.read(wizardControllerProvider.notifier);
      final proto = Protocolo(
        campos: [
          Campo(id: 'c1', obrigatorio: true, tipo: Campo_Tipo.TEXT),
        ],
      );

      controller.loadProtocol(proto);
      
      // Responde
      final answer = RespostaCampo(valorTexto: "Tudo OK");
      controller.answerCurrentField(answer);
      
      var state = container.read(wizardControllerProvider);
      expect(state.answers.containsKey('c1'), true);
      
      // Avança
      bool success = controller.nextStep();
      expect(success, true);
      
      state = container.read(wizardControllerProvider);
      expect(state.currentStep, 1);
    });
  });
}
