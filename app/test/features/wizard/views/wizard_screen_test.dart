import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixlog/features/wizard/views/wizard_screen.dart';

void main() {
  const testYaml = '''
id: "test_protocol"
nome: "Protocolo de Teste"
versao: "1.0.0"
blocos:
  - id: "b1"
    nome: "Bloco Inicial"
    steps:
      - id: "s1"
        nome: "Passo 1"
        conteudos:
          - id: "c1"
            tipo_componente: "CAMPO_SIMPLES"
            campo_simples:
              label: "Tipo de Chapeleta"
              tipo: "TEXT"
              obrigatorio: true
''';

  group('WizardScreen Widget Tests', () {
    testWidgets('renderiza o cabeçalho e campo de texto do protocolo YAML', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: testYaml),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('FIXLOG'), findsOneWidget);
      expect(find.text('Tipo de Chapeleta'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('botão de avanço habilita após preencher campo obrigatório', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: testYaml),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final nextButtonFinder = find.widgetWithText(
        ElevatedButton,
        'ASSINAR E CONCLUIR',
      );
      expect(nextButtonFinder, findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Bonier Inox');
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(nextButtonFinder);
      final color = button.style?.backgroundColor?.resolve({});
      expect(color, equals(const Color(0xFFFF6B00)));
    });
  });
}
