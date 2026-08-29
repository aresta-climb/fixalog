import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/wizard/views/wizard_screen.dart';
import 'package:app/features/wizard/controllers/wizard_state_controller.dart';
import 'package:app/core/services/protocol_parser.dart';
import 'package:app/core/models/proto/protos/registro.pb.dart';
void main() {
  const testYaml = '''
id: "test_pt"
nome: "Test Wizard"
versao: "1.0"
blocos:
  - id: "b1"
    nome: "Bloco 1"
    steps:
      - id: "s1"
        nome: "PASSO 1"
        conteudos:
          - id: "q1"
            tipo_componente: "CAMPO_SIMPLES"
            campo_simples:
              label: "What is the material?"
              tipo: "TEXT"
              obrigatorio: true
''';

  group('WizardScreen Widget Tests', () {
    testWidgets('Should render the first step from YAML', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: WizardScreen(initialYaml: testYaml)),
        ),
      );

      // Aguarda o processamento do YAML no initState (WidgetBinding.addPostFrameCallback)
      await tester.pumpAndSettle();

      expect(find.text('FIXALOG'), findsOneWidget);
      expect(find.text('PASSO 1'), findsOneWidget);
      expect(find.text('What is the material?'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets(
      'Next button should be grey when incomplete and orange when filled',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: WizardScreen(initialYaml: testYaml)),
          ),
        );

        await tester.pumpAndSettle();

        final nextButtonFinder = find.widgetWithText(
          ElevatedButton,
          'ASSINAR E CONCLUIR',
        );

        // Verifica se o botão está presente
        expect(nextButtonFinder, findsOneWidget);

        // Digita algo no campo para ativar o botão
        await tester.enterText(find.byType(TextFormField), 'Inox 316');
        await tester.pumpAndSettle();

        // Verifica se o botão ficou laranja (#FF6B00)
        final button = tester.widget<ElevatedButton>(nextButtonFinder);
        final color = button.style?.backgroundColor?.resolve({});
        expect(color, equals(const Color(0xFFFF6B00)));
      },
    );

    testWidgets('If isEditing is true, does not override existing state', (WidgetTester tester) async {
      final container = ProviderContainer();
      
      // Load a different protocol manually
      final controller = container.read(wizardControllerProvider.notifier);
      final dummyYaml = 'id: "old_proto"\nversao: "1"';
      controller.loadProtocol(ProtocolParser.fromYaml(dummyYaml), rawYaml: dummyYaml);
      controller.answerConteudo('some_q', Resposta(texto: 'Old Value'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WizardScreen(
              initialYaml: testYaml, // Passing testYaml, but it shouldn't load it
              isEditing: true, // This should prevent loadProtocol from overriding
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state = container.read(wizardControllerProvider);
      
      // It should still have the old protocol id, NOT test_pt
      expect(state.protocol?.id, 'old_proto');
      expect(state.answers['some_q']?.texto, 'Old Value');
    });
  });
}
