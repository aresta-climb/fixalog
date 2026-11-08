// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/features/identity/views/identity_setup_screen.dart';

void main() {
  Widget createWidgetUnderTest({BancoDadosLocal? banco, Locale? locale}) {
    return ProviderScope(
      overrides: [
        if (banco != null) bancoDadosLocalProvider.overrideWithValue(banco),
        if (locale != null) localeSistemaProvider.overrideWithValue(locale),
      ],
      child: MaterialApp(
        localizationsDelegates: locale != null
            ? AppLocalizations.localizationsDelegates
            : null,
        supportedLocales: ResolvedorIdioma.localesSuportados,
        home: const IdentitySetupScreen(),
      ),
    );
  }

  group('IdentitySetupScreen Widget Tests', () {
    testWidgets('renderiza campos de formulário e elementos visuais', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('FIX'), findsOneWidget);
      expect(find.text('LOG'), findsOneWidget);
      expect(find.text('NOME COMPLETO'), findsOneWidget);
      expect(find.text('GERAR CHAVES E ENTRAR'), findsOneWidget);
    });

    testWidgets('permite digitar nos campos de texto e exibe SnackBar quando nome está vazio', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Submeter vazio exibe erro
      final botao = find.byType(ElevatedButton);
      await tester.ensureVisible(botao);
      await tester.tap(botao);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.first, 'Renato Silva');
      await tester.enterText(textFields.last, 'Clube Paulista');
      await tester.pump();

      expect(find.text('Renato Silva'), findsOneWidget);
      expect(find.text('Clube Paulista'), findsOneWidget);
    });

    testWidgets(
      'renderiza textos localizados em Inglês, Árabe e Japonês sem overflow visual',
      (tester) async {
        late WidgetRef refCapturado;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localeSistemaProvider.overrideWithValue(const Locale('en')),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: ResolvedorIdioma.localesSuportados,
              home: Consumer(
                builder: (context, ref, _) {
                  refCapturado = ref;
                  return const IdentitySetupScreen();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Full Name *'), findsOneWidget);
        expect(find.text('GENERATE KEYS AND CONTINUE'), findsOneWidget);

        await refCapturado
            .read(idiomaAtivoProvider.notifier)
            .selecionarIdioma('ar');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('الاسم الكامل *'), findsOneWidget);

        await refCapturado
            .read(idiomaAtivoProvider.notifier)
            .selecionarIdioma('ja');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('氏名 *'), findsOneWidget);
        expect(find.text('鍵を生成して続行'), findsOneWidget);
      },
    );
  });
}
