import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixlog/features/identity/views/identity_setup_screen.dart';
import 'package:fixlog/features/identity/repositories/identity_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockIdentityRepository extends Mock implements IdentityRepository {}

void main() {
  late MockIdentityRepository mockRepository;

  setUp(() {
    mockRepository = MockIdentityRepository();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        identityRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(
        home: IdentitySetupScreen(),
      ),
    );
  }

  group('IdentitySetupScreen Widget Tests', () {
    testWidgets('renderiza campos de formulário e elementos visuais', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('FIX'), findsOneWidget);
      expect(find.text('LOG'), findsOneWidget);
      expect(find.text('NOME COMPLETO'), findsOneWidget);
      expect(find.text('GERAR CHAVES E ENTRAR'), findsOneWidget);
    });

    testWidgets('permite digitar nos campos de texto', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.first, 'Renato Silva');
      await tester.enterText(textFields.last, 'Clube Paulista');
      await tester.pump();

      expect(find.text('Renato Silva'), findsOneWidget);
      expect(find.text('Clube Paulista'), findsOneWidget);
    });
  });
}
