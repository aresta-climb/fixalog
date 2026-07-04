import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/home/views/new_protocol_screen.dart';
import 'package:app/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:app/core/models/local/identity_record.dart';
import 'package:app/features/express_form/views/express_form_screen.dart';

// Helper: monta a tela com um provider de identidade mockado.
Widget _buildScreen({IdentityRecord? identity}) {
  return ProviderScope(
    overrides: [
      currentIdentityProvider.overrideWith(
        (ref) async => identity ?? IdentityRecord(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: NewProtocolScreen())),
  );
}

void main() {
  group('NewProtocolScreen Widget Tests', () {
    testWidgets('Exibe o header FIXALOG', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('FIXALOG'), findsOneWidget);
    });

    testWidgets('Exibe saudação genérica quando identidade está vazia', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Boa jornada.'), findsOneWidget);
    });

    testWidgets('Exibe saudação com primeiro nome quando identidade tem nome', (
      tester,
    ) async {
      final identity = IdentityRecord()..nome = 'Renato Silva';
      await tester.pumpWidget(_buildScreen(identity: identity));
      await tester.pump();

      expect(find.text('Boa jornada, Renato.'), findsOneWidget);
    });

    testWidgets('Exibe nome do clube quando preenchido e diferente de N/A', (
      tester,
    ) async {
      final identity = IdentityRecord()
        ..nome = 'Ana'
        ..clubeAssociacao = 'Clube Alpino Paulista';
      await tester.pumpWidget(_buildScreen(identity: identity));
      await tester.pump();

      expect(find.text('CLUBE ALPINO PAULISTA'), findsOneWidget);
    });

    testWidgets('Exibe fallback MANTENEDOR INDEPENDENTE quando clube é N/A', (
      tester,
    ) async {
      final identity = IdentityRecord()
        ..nome = 'Ana'
        ..clubeAssociacao = 'N/A';
      await tester.pumpWidget(_buildScreen(identity: identity));
      await tester.pump();

      expect(find.text('MANTENEDOR INDEPENDENTE'), findsOneWidget);
    });

    testWidgets('Exibe título da seção de protocolos', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('NOVO REGISTRO DE MANUTENÇÃO'), findsOneWidget);
    });

    testWidgets('Exibe os três cards de protocolo', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Manutenção de\nProteções Fixas'), findsOneWidget);
      expect(find.text('Inspeção Visual de\nProteções Fixas'), findsOneWidget);
      expect(find.text('Abertura de Via'), findsOneWidget);
    });

    testWidgets('Exibe tags de protocolo corretas', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('PROTOCOLO TÉCNICO'), findsNWidgets(2));
      expect(find.text('PROTOCOLO PREVENTIVO'), findsOneWidget);
    });

    testWidgets('Exibe três botões INICIAR', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('INICIAR'), findsNWidgets(4));
    });
    testWidgets('Navega para Express Form ao tocar em Registro Expresso', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('INICIAR').first);
      await tester.pumpAndSettle();

      // ExpressFormScreen is shown
      expect(find.byType(ExpressFormScreen), findsOneWidget);
    });

    testWidgets('Tenta navegar para Manutenção de Proteções Fixas', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final finder = find.text('INICIAR').at(1);
      await tester.dragUntilVisible(
        finder,
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pump();
    });

    testWidgets('Tenta navegar para Inspeção Visual', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final finder = find.text('INICIAR').at(2);
      await tester.dragUntilVisible(
        finder,
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pump();
    });

    testWidgets('Tenta navegar para Abertura de Via', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final finder = find.text('INICIAR').at(3);
      await tester.dragUntilVisible(
        finder,
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pump();
    });
  });
}
