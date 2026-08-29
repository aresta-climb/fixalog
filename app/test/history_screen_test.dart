import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/home/views/history_screen.dart';
import 'package:app/features/home/providers/history_provider.dart';
import 'package:app/core/models/local/submission_record.dart';

Widget _buildScreen() {
  return ProviderScope(
    overrides: [
      historyProvider.overrideWith((ref) {
        final logs = List.generate(15, (index) {
          return SubmissionRecord()
            ..nomeProtocolo = 'Protocolo $index'
            ..dataInclusao = index == 0 ? DateTime(2023, 10, 12) : DateTime(2023, 9, 25);
        });
        return Stream.value(logs);
      }),
    ],
    child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
  );
}

void main() {
  group('HistoryScreen Widget Tests', () {
    testWidgets('Exibe o header FIXALOG', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('FIXALOG'), findsOneWidget);
    });

    testWidgets('Exibe título da página "Histórico"', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Histórico'), findsOneWidget);
    });

    testWidgets('Exibe subtítulo descritivo', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Registros de manutenção preenchidos'), findsOneWidget);
    });

    testWidgets('Exibe os dois stat cards com valores dinâmicos', (WidgetTester tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('LOGS TOTAIS'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('ÚLTIMO LOG'), findsOneWidget);
      expect(find.text('12/10/2023').first, findsOneWidget);
    });

    testWidgets('Exibe apenas 10 itens inicialmente e pagina para 15', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      // "HISTÓRICO RECENTE" e "VER TUDO" não devem existir
      expect(find.text('HISTÓRICO RECENTE'), findsNothing);
      expect(find.text('VER TUDO'), findsNothing);

      // Deve mostrar 10 itens (index 0 a 9)
      expect(find.text('Protocolo 0'), findsOneWidget);
      expect(find.text('Protocolo 9'), findsOneWidget);
      expect(find.text('Protocolo 10'), findsNothing);

      // Botão "Carregar mais" deve estar visível
      final carregarMaisFinder = find.text('CARREGAR MAIS');
      expect(carregarMaisFinder, findsOneWidget);

      // Toca para carregar mais
      await tester.ensureVisible(carregarMaisFinder);
      await tester.tap(carregarMaisFinder);
      await tester.pumpAndSettle();

      // Agora deve mostrar os 15
      expect(find.text('Protocolo 10'), findsOneWidget);
      expect(find.text('Protocolo 14'), findsOneWidget);

      // O botão "Carregar mais" deve sumir, pois 15 <= limit (20)
      expect(carregarMaisFinder, findsNothing);
    });
  });
}
