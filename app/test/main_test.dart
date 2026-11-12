// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:ui';

import 'package:feedback/feedback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:fixalog/main.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/core/models/local/app_config_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/registro_logger.dart';
import 'package:fixalog/core/services/servico_app_check.dart';
import 'package:fixalog/core/services/servico_configuracao_remota.dart';
import 'package:fixalog/core/services/servico_telemetria.dart';

import 'fakes/registro_logger_fake.dart';

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
      expect(find.byType(BetterFeedback), findsOneWidget);
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

    test(
      'inicializarObservabilidade opera com resiliência sem rede, configura Sentry quando DSN presente e encaminha erros globais ao RegistroLogger',
      () async {
        final handlerFlutterAnterior = FlutterError.onError;
        final handlerPlatformAnterior = PlatformDispatcher.instance.onError;
        addTearDown(() {
          FlutterError.onError = handlerFlutterAnterior;
          PlatformDispatcher.instance.onError = handlerPlatformAnterior;
        });

        final loggerFake = RegistroLoggerFake();
        var appRunnerExecutado = 0;

        final appCheck = ServicoAppCheck(
          logger: loggerFake,
          ativarAppCheck: ({
            required providerAndroid,
            required providerApple,
          }) async {},
        );
        final telemetria = ServicoTelemetria(
          logger: loggerFake,
          configurarColetaAnalytics: (_) async {},
        );
        final configRemota = ServicoConfiguracaoRemota(
          logger: loggerFake,
          sincronizarRemoto: (padroes) async => padroes,
        );

        RegistroLogger.instancia = loggerFake;
        ServicoAppCheck.instancia = appCheck;
        ServicoTelemetria.instancia = telemetria;
        ServicoConfiguracaoRemota.instancia = configRemota;

        // 1. Inicialização sem DSN usando instâncias globais padrão
        await inicializarObservabilidade(
          appRunner: () {
            appRunnerExecutado++;
          },
          sentryDsn: '',
        );

        RegistroLogger.resetarParaTestes();
        ServicoAppCheck.resetarParaTestes();
        ServicoTelemetria.resetarParaTestes();
        ServicoConfiguracaoRemota.resetarParaTestes();

        expect(appRunnerExecutado, equals(1));
        expect(
          loggerFake.avisosRegistrados,
          contains(contains('Firebase Core indisponível no boot')),
        );

        // 2. Verifica tratadores globais de erro instalados
        FlutterError.onError?.call(
          FlutterErrorDetails(
            exception: StateError('Erro de widget simulado'),
            stack: StackTrace.current,
          ),
        );
        final tratouPlatform = PlatformDispatcher.instance.onError?.call(
          StateError('Erro assíncrono simulado'),
          StackTrace.current,
        );
        expect(tratouPlatform, isTrue);
        expect(loggerFake.crashesRegistrados, hasLength(2));

        // 3. Inicialização com DSN do Sentry configurado
        final opcoesSentry = SentryFlutterOptions();
        await inicializarObservabilidade(
          appRunner: () {
            appRunnerExecutado++;
          },
          sentryDsn: 'https://chave@o1.ingest.sentry.io/123',
          inicializadorFirebaseCore: () async {},
          servicoAppCheck: appCheck,
          servicoTelemetria: telemetria,
          servicoConfiguracaoRemota: configRemota,
          logger: loggerFake,
          inicializadorSentry: (configurador, runner) async {
            configurador(opcoesSentry);
            await runner();
          },
        );

        expect(appRunnerExecutado, equals(2));
        expect(
          opcoesSentry.dsn,
          equals('https://chave@o1.ingest.sentry.io/123'),
        );
        expect(opcoesSentry.sendDefaultPii, isFalse);
        expect(opcoesSentry.maxBreadcrumbs, equals(100));
      },
    );
  });
}
