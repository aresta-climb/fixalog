// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixalog/main.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart';

void main() {
  group('FixalogApp Root Widget Tests', () {
    testWidgets('instancia FixalogApp com tema dark e título Fixalog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isarProvider.overrideWithValue(null),
          ],
          child: const FixalogApp(),
        ),
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'Fixalog');
      expect(materialApp.themeMode, ThemeMode.dark);
      expect(materialApp.darkTheme?.colorScheme.primary, const Color(0xFFFF6B00));
    });
  });
}
