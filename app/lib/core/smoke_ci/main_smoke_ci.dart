// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/media/services/media_compressor_service.dart';
import '../../main.dart';
import '../services/banco_dados_local.dart';
import '../services/crypto_service.dart';
import 'configuracao_smoke_ci.dart';
import 'executor_jornada_smoke.dart';

/// Sobrescrita opcional apenas para testes de integração do entrypoint `main()`.
FutureOr<void> Function(Widget app) montadorAppPadraoSmoke = runApp;

/// Sobrescrita opcional do agendador de quadro pós-renderização.
void Function(FrameCallback callback) agendadorPosQuadroSmoke =
    _agendarPosQuadroPadrao;

void _agendarPosQuadroPadrao(FrameCallback callback) {
  WidgetsBinding.instance.addPostFrameCallback(callback);
}

/// Ponto de entrada exclusivo para artefatos descartáveis de Smoke Test no CI
/// (`--target=lib/core/smoke_ci/main_smoke_ci.dart`).
///
/// Jamais é importado por `lib/main.dart`, garantindo que os pacotes oficiais
/// de loja (`.aab` e `.ipa`) não contenham código de smoke test.
Future<void> main() async {
  await inicializarAplicativoSmokeCi();
}

/// Inicializa o [FixalogApp] real sem enviar telemetria externa ao Sentry, aguarda
/// a renderização do primeiro quadro e executa a jornada pós-build completa.
Future<ResultadoJornadaSmoke> inicializarAplicativoSmokeCi({
  Future<Directory> Function() provedorDiretorioBase =
      getApplicationDocumentsDirectory,
  Future<BancoDadosLocal> Function(String caminho) provedorBanco =
      BancoDadosLocal.abrirEmArquivo,
  CryptoService? cryptoServiceOverride,
  MediaCompressorService? mediaServiceOverride,
  Future<void> Function(File destino)? geradorVideoOverride,
  FutureOr<void> Function(Widget app)? montadorApp,
  void Function(FrameCallback callback)? agendadorPosQuadro,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await ConfiguracaoSmokeCi.exigirDoCanalNativo();
  final dir = await provedorDiretorioBase();
  final banco = await provedorBanco(dir.path);

  final executor = ExecutorJornadaSmoke(
    config: config,
    diretorioBase: dir,
    banco: banco,
    cryptoService: cryptoServiceOverride,
    mediaService: mediaServiceOverride,
    geradorVideoSintetico: geradorVideoOverride,
  );

  final completerQuadro = Completer<void>();
  final montar = montadorApp ?? montadorAppPadraoSmoke;
  final agendar = agendadorPosQuadro ?? agendadorPosQuadroSmoke;

  await inicializarObservabilidade(
    sentryDsn: '',
    appRunner: () async {
      await montar(
        ProviderScope(
          overrides: [
            bancoDadosLocalProvider.overrideWithValue(banco),
          ],
          child: const FixalogApp(),
        ),
      );
      agendar((_) {
        if (!completerQuadro.isCompleted) {
          completerQuadro.complete();
        }
      });
    },
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    executor.registrarErroAssincrono(
      'FlutterError: ${details.exceptionAsString()}\n${details.stack}',
    );
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    executor.registrarErroAssincrono('PlatformError: $error\n$stack');
    return true;
  };

  await completerQuadro.future;
  return executor.executar();
}
