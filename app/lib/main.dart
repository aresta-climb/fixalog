// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'features/home/views/home_screen.dart';
import 'features/identity/views/identity_setup_screen.dart';
import 'features/identity/viewmodels/identity_form_view_model.dart';
import 'features/onboarding/views/tela_termos_de_uso.dart' as fixalog_onboarding;
import 'core/constantes/versao_legal.g.dart';
import 'core/services/banco_dados_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final banco = await BancoDadosLocal.abrirEmArquivo(dir.path);

  runApp(
    ProviderScope(
      overrides: [
        bancoDadosLocalProvider.overrideWithValue(banco),
      ],
      child: const FixalogApp(),
    ),
  );
}

class FixalogApp extends StatelessWidget {
  const FixalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixalog',
      themeMode: ThemeMode.dark,
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
          headlineLarge: const TextStyle(fontFamily: 'SpaceGrotesk', letterSpacing: -0.02),
          bodyMedium: const TextStyle(fontFamily: 'Inter'),
          labelMedium: const TextStyle(fontFamily: 'SpaceGrotesk', textBaseline: TextBaseline.alphabetic),
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
