// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixalog/main.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/core/models/local/app_config_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';

void main() {
  group('FixalogApp Root Widget Tests', () {
    testWidgets('instancia FixalogApp com tema dark, família NotoSans e delegates dos 7 idiomas', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bancoDadosLocalProvider.overrideWithValue(null),
          ],
          child: const FixalogApp(),
        ),
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'Fixalog');
      expect(materialApp.themeMode, ThemeMode.dark);
      expect(materialApp.darkTheme?.colorScheme.primary, const Color(0xFFFF6B00));
      expect(
        materialApp.supportedLocales,
        equals(ResolvedorIdioma.localesSuportados),
      );
      expect(materialApp.localizationsDelegates, isNotNull);
      expect(
        materialApp.darkTheme?.textTheme.headlineLarge?.fontFamily,
        equals('NotoSans'),
      );
      expect(
        materialApp.darkTheme?.textTheme.bodyMedium?.fontFamily,
        equals('NotoSans'),
      );
    });

    testWidgets('aplica idioma preferido do banco e direcionalidade RTL em árabe (ar)', (tester) async {
      final banco = await BancoDadosLocal.abrirEmMemoria();
      addTearDown(banco.fechar);
      await banco.salvarConfiguracao(
        AppConfigRecord()..idiomaPreferido = 'ar',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bancoDadosLocalProvider.overrideWithValue(banco),
          ],
          child: const FixalogApp(),
        ),
      );
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.locale, equals(const Locale('ar')));
      final scaffoldContext = tester.element(find.byType(Scaffold).first);
      expect(Directionality.of(scaffoldContext), equals(TextDirection.rtl));
    });
  });
}
