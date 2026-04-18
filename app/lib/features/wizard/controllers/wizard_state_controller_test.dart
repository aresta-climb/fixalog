import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/wizard/controllers/wizard_state_controller.dart';
import 'package:app/core/models/proto/protos/fixalog.pb.dart';

void main() {
  group('WizardStateController Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state should have null protocol and currentStep 0', () {
      final state = container.read(wizardControllerProvider);
      expect(state.protocol, isNull);
      expect(state.currentStep, equals(0));
      expect(state.answers, isEmpty);
    });

    test('loadProtocol should update the protocol in state', () {
      final protocol = Protocolo(id: 'test', nome: 'Test Protocol');
      container.read(wizardControllerProvider.notifier).loadProtocol(protocol);
      
      final state = container.read(wizardControllerProvider);
      expect(state.protocol, equals(protocol));
    });

    test('answerCurrentField should store the answer', () {
      final protocol = Protocolo(
        id: 'test', 
        campos: [Campo(id: 'f1')]
      );
      container.read(wizardControllerProvider.notifier).loadProtocol(protocol);
      
      final answer = RespostaCampo(valorTexto: 'hello');
      container.read(wizardControllerProvider.notifier).answerCurrentField(answer);
      
      final state = container.read(wizardControllerProvider);
      expect(state.answers['f1'], equals(answer));
    });

    test('nextStep should increment currentStep', () {
      final protocol = Protocolo(
        id: 'test', 
        campos: [Campo(id: 'f1'), Campo(id: 'f2')]
      );
      container.read(wizardControllerProvider.notifier).loadProtocol(protocol);
      
      // Simula resposta para permitir avanço se fosse obrigatório
      container.read(wizardControllerProvider.notifier).answerCurrentField(RespostaCampo(valorTexto: 'ok'));
      
      final success = container.read(wizardControllerProvider.notifier).nextStep();
      
      expect(success, isTrue);
      expect(container.read(wizardControllerProvider).currentStep, equals(1));
    });

    test('prevStep should decrement currentStep', () {
      final protocol = Protocolo(
        id: 'test', 
        campos: [Campo(id: 'f1'), Campo(id: 'f2')]
      );
      container.read(wizardControllerProvider.notifier).loadProtocol(protocol);
      container.read(wizardControllerProvider.notifier).goToStep(1);
      
      container.read(wizardControllerProvider.notifier).previousStep();
      expect(container.read(wizardControllerProvider).currentStep, equals(0));
    });
  });
}
