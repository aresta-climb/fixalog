import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixlog/main.dart';
import 'package:fixlog/features/identity/viewmodels/identity_form_view_model.dart';

void main() {
  group('FixLogApp Root Widget Tests', () {
    testWidgets('instancia FixLogApp com tema dark e título FixLog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isarProvider.overrideWithValue(null),
          ],
          child: const FixLogApp(),
        ),
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'FixLog');
      expect(materialApp.themeMode, ThemeMode.dark);
      expect(materialApp.darkTheme?.colorScheme.primary, const Color(0xFFFF6B00));
    });
  });
}
