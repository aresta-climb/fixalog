import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/home/views/history_screen.dart';

// HistoryScreen não depende de providers — sem overrides necessários.
Widget _buildScreen() {
  return const MaterialApp(home: Scaffold(body: HistoryScreen()));
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

      // O texto "Histórico" aparece no título grande da página
      expect(find.text('Histórico'), findsOneWidget);
    });

    testWidgets('Exibe subtítulo descritivo', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Registros de manutenção preenchidos'), findsOneWidget);
    });

    testWidgets('Exibe os dois stat cards', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('LOGS TOTAIS'), findsOneWidget);
      expect(find.text('VIA MAIS ATIVA'), findsOneWidget);
    });

    testWidgets('Exibe valores dos stat cards', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('128'), findsOneWidget);
      // 'Via do Sol' aparece no stat card E como primeiro item do histórico
      expect(find.text('Via do Sol'), findsNWidgets(2));
    });

    testWidgets('Exibe título da seção de histórico recente', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('HISTÓRICO RECENTE'), findsOneWidget);
    });

    testWidgets('Exibe botão VER TUDO', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('VER TUDO'), findsOneWidget);
    });

    testWidgets('Exibe os três itens do histórico', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      // 'Via do Sol' aparece também no stat card "VIA MAIS ATIVA"
      expect(find.text('Via do Sol'), findsNWidgets(2));
      expect(find.text('Fenda do Pânico'), findsOneWidget);
      expect(find.text('Cristal Rock'), findsOneWidget);
    });

    testWidgets('Exibe as datas dos itens de histórico', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('12 OUT 2023'), findsOneWidget);
      expect(find.text('08 OUT 2023'), findsOneWidget);
      expect(find.text('25 SET 2023'), findsOneWidget);
    });

    testWidgets('Exibe as tags de tipo dos itens do histórico', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('QUÍMICO'), findsNWidgets(2));
      expect(find.text('INSPEÇÃO'), findsOneWidget);
    });
  });
}
