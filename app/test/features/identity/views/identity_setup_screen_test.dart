// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/crypto_service.dart';
import 'package:fixalog/core/services/providers.dart';
import 'package:fixalog/features/home/views/home_screen.dart';
import 'package:fixalog/features/identity/views/identity_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../core/services/autenticacao_nuvem_service_fake.dart';
import '../../../fakes/crypto_service_fake.dart';

void main() {
  Widget createWidgetUnderTest({
    BancoDadosLocal? banco,
    Locale? locale,
    CryptoService? cryptoService,
    AutenticacaoNuvemService? autenticacaoService,
  }) {
    return ProviderScope(
      overrides: [
        if (banco != null) bancoDadosLocalProvider.overrideWithValue(banco),
        if (locale != null) localeSistemaProvider.overrideWithValue(locale),
        if (cryptoService != null)
          cryptoServiceProvider.overrideWithValue(cryptoService),
        if (autenticacaoService != null)
          autenticacaoNuvemServiceProvider.overrideWithValue(
            autenticacaoService,
          ),
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
    testWidgets('renderiza botões Google e Apple, campos de formulário e elementos visuais', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('FIX'), findsOneWidget);
      expect(find.text('LOG'), findsOneWidget);
      expect(find.byKey(const Key('botao_login_google')), findsOneWidget);
      expect(find.byKey(const Key('botao_login_apple')), findsOneWidget);
      expect(find.text('NOME COMPLETO'), findsOneWidget);
      expect(find.text('GERAR CHAVES E ENTRAR'), findsOneWidget);
    });

    testWidgets('exibe SnackBar quando nome está vazio ou quando falta autenticação OIDC Google/Apple', (
      tester,
    ) async {
      final crypto = CryptoServiceFake();
      final auth = AutenticacaoNuvemServiceFake(crypto: crypto);
      await tester.pumpWidget(
        createWidgetUnderTest(
          cryptoService: crypto,
          autenticacaoService: auth,
        ),
      );
      await tester.pump();

      final botao = find.byType(ElevatedButton);
      await tester.ensureVisible(botao);
      await tester.tap(botao);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Atenção. O nome não pode estar vazio.'),
        findsOneWidget,
      );

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.first, 'Renato Silva');
      await tester.enterText(textFields.last, 'Clube Paulista');
      await tester.pump();

      ScaffoldMessenger.of(tester.element(botao)).clearSnackBars();
      await tester.pumpAndSettle();

      await tester.ensureVisible(botao);
      await tester.tap(botao);
      await tester.pumpAndSettle();

      expect(
        find.text('Autentique-se com Google ou Apple antes de continuar.'),
        findsOneWidget,
      );
    });

    testWidgets('autentica com Google ou Apple, pré-preenche Nome/Clube e navega para HomeScreen ao concluir', (
      tester,
    ) async {
      late BancoDadosLocal banco;
      await tester.runAsync(() async {
        banco = await BancoDadosLocal.abrirEmMemoria();
      });
      addTearDown(() async {
        await tester.runAsync(() async {
          await banco.fechar();
        });
      });

      final crypto = CryptoServiceFake();
      final auth = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        nomeRetornadoOidc: 'Renato Ferreira',
        clubeRetornadoOidc: 'FEMERJ',
        emailRetornadoOidc: 'renato@arestaclimb.com',
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          banco: banco,
          cryptoService: crypto,
          autenticacaoService: auth,
        ),
      );
      await tester.pump();

      final botaoGoogle = find.byKey(const Key('botao_login_google'));
      await tester.ensureVisible(botaoGoogle);
      await tester.tap(botaoGoogle);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('badge_sessao_oidc')), findsOneWidget);
      expect(find.text('Renato Ferreira'), findsOneWidget);
      expect(find.text('FEMERJ'), findsOneWidget);

      final botaoApple = find.byKey(const Key('botao_login_apple'));
      await tester.ensureVisible(botaoApple);
      await tester.tap(botaoApple);
      await tester.pumpAndSettle();
      expect(auth.loginsRealizados, contains(ProvedorOidc.apple));

      final botaoConfirmar = find.byType(ElevatedButton);
      await tester.ensureVisible(botaoConfirmar);
      await tester.runAsync(() async {
        await tester.tap(botaoConfirmar);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
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
