// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'features/home/views/home_screen.dart';
import 'features/identity/views/identity_setup_screen.dart';
import 'features/identity/viewmodels/identity_form_view_model.dart';
import 'features/onboarding/views/tela_termos_de_uso.dart' as fixalog_onboarding;
import 'core/constantes/versao_legal.g.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/l10n/resolvedor_idioma.dart';
import 'core/services/banco_dados_local.dart';
import 'core/services/classificador_dispositivo.dart';
import 'core/services/registro_logger.dart';
import 'core/services/servico_app_check.dart';
import 'core/services/servico_configuracao_remota.dart';
import 'core/services/servico_telemetria.dart';

/// DSN do projeto `fixalog` no Sentry (pode ser sobrescrito via `--dart-define=SENTRY_DSN=...`).
const String kSentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue:
      'https://40a871e3f8b31e36201e4825ce94ad0c@o4511980548849664.ingest.us.sentry.io/4512399433269248',
);

/// Inicializa de forma resiliente e não-bloqueante a gestão adaptativa de memória,
/// os serviços do Firebase (Core, App Check, Telemetria e Configuração Remota),
/// os tratadores globais de erro e o Sentry, executando [appRunner] ao final.
Future<void> inicializarObservabilidade({
  required FutureOr<void> Function() appRunner,
  String sentryDsn = kSentryDsn,
  Future<void> Function()? inicializadorFirebaseCore,
  ServicoAppCheck? servicoAppCheck,
  ServicoTelemetria? servicoTelemetria,
  ServicoConfiguracaoRemota? servicoConfiguracaoRemota,
  RegistroLogger? logger,
  Future<void> Function(
    void Function(SentryFlutterOptions) configuradorOpcoes,
    FutureOr<void> Function() runner,
  )? inicializadorSentry,
}) async {
  ClassificadorDispositivo.configurarGestaoMemoria();

  final log = logger ?? RegistroLogger.instancia;
  final appCheck = servicoAppCheck ?? ServicoAppCheck.instancia;
  final telemetria = servicoTelemetria ?? ServicoTelemetria.instancia;
  final configRemota =
      servicoConfiguracaoRemota ?? ServicoConfiguracaoRemota.instancia;

  try {
    if (inicializadorFirebaseCore != null) {
      await inicializadorFirebaseCore();
    } else if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    log.logAviso(
      '🔥 [Inicializacao] Firebase Core indisponível no boot (operando 100% offline): $e',
    );
  }

  await Future.wait([
    appCheck.ativar(),
    telemetria.inicializar(),
  ]);

  unawaited(configRemota.inicializar());

  FlutterError.onError = (FlutterErrorDetails details) {
    log.logCrash(
      'Erro não tratado do Flutter Framework: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack ?? StackTrace.current,
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    log.logCrash(
      'Erro assíncrono não tratado na plataforma',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  void configurarOpcoesSentry(SentryFlutterOptions options) {
    options.dsn = sentryDsn;
    options.sendDefaultPii = false;
    options.maxBreadcrumbs = 100;
  }

  if (sentryDsn.trim().isNotEmpty) {
    final initSentry = inicializadorSentry ??
        (configurador, runner) => SentryFlutter.init(
              configurador,
              appRunner: runner,
            );
    await initSentry(configurarOpcoesSentry, appRunner);
  } else {
    await appRunner();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final banco = await BancoDadosLocal.abrirEmArquivo(dir.path);

  await inicializarObservabilidade(
    appRunner: () {
      runApp(
        ProviderScope(
          overrides: [
            bancoDadosLocalProvider.overrideWithValue(banco),
          ],
          child: const FixalogApp(),
        ),
      );
    },
  );
}

class FixalogApp extends ConsumerWidget {
  const FixalogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAtivo = ref.watch(idiomaAtivoProvider);

    return MaterialApp(
      title: 'Fixalog',
      themeMode: ThemeMode.dark,
      locale: localeAtivo,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: ResolvedorIdioma.localesSuportados,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(mediaQueryData.textScaler.scale(1) * 1.25),
          ),
          child: child!,
        );
      },
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'NotoSans',
        fontFamilyFallback: const ['NotoSansArabic', 'NotoSansJP'],
        scaffoldBackgroundColor: const Color(0xFF121416), // Surface Noise Background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B00), // Rescue Orange
          primaryContainer: Color(0xFFFF6B00),
          onPrimaryContainer: Colors.black, // High contrast text on orange
          secondary: Color(0xFF4F6D44), // Moss Green
          surface: Color(0xFF1A1C1E), // Surface-container-low
          surfaceContainerHighest: Color(0xFF333537),
        ),
        textTheme: ThemeData.dark().textTheme.copyWith(
          headlineLarge: const TextStyle(
            fontFamily: 'NotoSans',
            fontFamilyFallback: ['NotoSansArabic', 'NotoSansJP'],
            letterSpacing: -0.02,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'NotoSans',
            fontFamilyFallback: ['NotoSansArabic', 'NotoSansJP'],
          ),
          labelMedium: const TextStyle(
            fontFamily: 'NotoSans',
            fontFamilyFallback: ['NotoSansArabic', 'NotoSansJP'],
            textBaseline: TextBaseline.alphabetic,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B00),
            foregroundColor: Colors.black, // on_primary_container
            minimumSize: const Size(double.infinity, 56), // Hit area for gloved hands
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // xl radius
            elevation: 0,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF333537), // surface_container_highest
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF6B00), width: 2),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
      home: _StartupRouter(),
    );
  }
}

class _StartupRouter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banco = ref.watch(bancoDadosLocalProvider);
    if (banco == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final config = banco.obterConfiguracaoSync(1);
    final acceptedTerms = (config?.acceptedTermsVersion ?? 0) >= kVersaoLegal;

    if (!acceptedTerms) {
      return const fixalog_onboarding.TelaTermosDeUso();
    }

    final hasIdentityAsync = ref.watch(hasIdentityProvider);

    return hasIdentityAsync.when(
      data: (hasIdentity) {
        if (hasIdentity) {
          return const HomeScreen();
        } else {
          return const IdentitySetupScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) => Scaffold(
        body: Center(
          child: Text('Erro fatal ao ler banco: $e'),
        ),
      ),
    );
  }
}
