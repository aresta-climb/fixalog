import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/identity/views/identity_setup_screen.dart';
import 'package:app/features/identity/controllers/identity_form_controller.dart';

void main() {
  group('IdentitySetupScreen Widget Tests', () {
    testWidgets('Should render identity form fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [isarProvider.overrideWithValue(null)],
          child: const MaterialApp(home: IdentitySetupScreen()),
        ),
      );

      expect(
        find.text('IDENTIDADE DIGITAL'),
        findsNothing,
      ); // It used Typography 'FIXA LOG'
      expect(find.text('FIXA'), findsOneWidget);
      expect(find.text('LOG'), findsOneWidget);
      expect(find.text('NOME COMPLETO'), findsOneWidget);
      expect(find.text('GERAR CHAVES E ENTRAR'), findsOneWidget);
    });

    testWidgets('Should allow typing in the name field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [isarProvider.overrideWithValue(null)],
          child: const MaterialApp(home: IdentitySetupScreen()),
        ),
      );

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Renato Silva');

      expect(find.text('Renato Silva'), findsOneWidget);
    });
  });
}
