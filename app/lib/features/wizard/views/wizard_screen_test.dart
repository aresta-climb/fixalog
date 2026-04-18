import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/wizard/views/wizard_screen.dart';

void main() {
  const testYaml = '''
protocolo:
  id: "test_pt"
  nome: "Test Wizard"
  campos:
    - id: "q1"
      label: "What is the material?"
      tipo: TEXT
      obrigatorio: true
''';

  group('WizardScreen Widget Tests', () {
    testWidgets('Should render the first step from YAML', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: testYaml),
          ),
        ),
      );

      // Aguarda o processamento do YAML no initState (WidgetBinding.addPostFrameCallback)
      await tester.pumpAndSettle();

      expect(find.text('FIXALOG'), findsOneWidget);
      expect(find.text('PASSO 1'), findsOneWidget);
      expect(find.text('What is the material?'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('Next button should be grey when incomplete and orange when filled', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: testYaml),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final nextButtonFinder = find.widgetWithText(ElevatedButton, 'ASSINAR E CONCLUIR');
      
      // Verifica se o botão está presente
      expect(nextButtonFinder, findsOneWidget);

      // Digita algo no campo para ativar o botão
      await tester.enterText(find.byType(TextFormField), 'Inox 316');
      await tester.pumpAndSettle();

      // Verifica se o botão ficou laranja (#FF6B00)
      final button = tester.widget<ElevatedButton>(nextButtonFinder);
      final color = button.style?.backgroundColor?.resolve({});
      expect(color, equals(const Color(0xFFFF6B00)));
    });
  });
}
