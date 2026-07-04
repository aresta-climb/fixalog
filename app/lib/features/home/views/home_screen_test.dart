import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/home/views/home_screen.dart';
import 'package:app/features/identity/controllers/identity_form_controller.dart';
import 'package:app/core/models/local/identity_record.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('Should render the main protocol cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentIdentityProvider.overrideWith(
              (ref) => IdentityRecord()..nome = 'Renato Silva',
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Verifica título principal da seção
      expect(find.text('NOVO REGISTRO DE MANUTENÇÃO'), findsOneWidget);

      // Verifica os cards de protocolo
      expect(find.text('Manutenção de\nProteções Fixas'), findsOneWidget);
      expect(find.text('Inspeção Visual de\nProteções Fixas'), findsOneWidget);
      expect(find.text('Abertura de Via'), findsOneWidget);
    });

    testWidgets('Should display user firstName', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentIdentityProvider.overrideWith(
              (ref) => IdentityRecord()..nome = 'Renato Silva',
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pump(); // Deixa os providers carregarem

      expect(find.text('Boa jornada, Renato.'), findsOneWidget);
      expect(find.text('FIXALOG'), findsOneWidget);
    });
  });
}
