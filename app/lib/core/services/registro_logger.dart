// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Indica se a compilação em modo release foi marcada como execução local (`--dart-define=RELEASE_LOCAL=true`).
const bool kReleaseLocal = bool.fromEnvironment('RELEASE_LOCAL');

/// Indica se o aplicativo está rodando em modo de produção oficial (`kReleaseMode` ativo e fora de [kReleaseLocal]).
const bool kModoReleaseOficial = kReleaseMode && !kReleaseLocal;

/// Indica se o aplicativo está em modo de desenvolvimento ou validação local (`!kReleaseMode` ou [kReleaseLocal]).
const bool kModoDesenvolvimento = !kModoReleaseOficial;

/// Assinatura para envio de log textual/breadcrumb ao Firebase Crashlytics.
typedef EnviarLogCrashlyticsCallback = void Function(String mensagem);

/// Assinatura para envio de erro ou falha fatal ao Firebase Crashlytics.
typedef EnviarErroCrashlyticsCallback = FutureOr<void> Function(
  Object erro,
  StackTrace stackTrace, {
  required String motivo,
  required bool fatal,
});

/// Assinatura para adição de breadcrumb estruturado ao Sentry.
typedef EnviarBreadcrumbSentryCallback = void Function(Breadcrumb breadcrumb);

/// Assinatura para captura de exceção estruturada no Sentry.
typedef EnviarExcecaoSentryCallback = FutureOr<void> Function(
  Object erro, {
  required StackTrace stackTrace,
  required String motivo,
  required bool fatal,
  Map<String, Map<String, Object?>>? contextosExtras,
});

/// Serviço centralizado para registro de logs informativos, avisos operacionais e
/// captura dual de exceções (Firebase Crashlytics + Sentry) com filtro inteligente
/// de instabilidades transitórias de rede em ambientes remotos de montanha.
class RegistroLogger {
  /// Indica se as mensagens informativas e de aviso devem ser impressas no console local.
  final bool emModoDesenvolvimento;

  final void Function(String mensagem) _impressorConsole;
  final EnviarLogCrashlyticsCallback _enviarLogCrashlytics;
  final EnviarErroCrashlyticsCallback _enviarErroCrashlytics;
  final EnviarBreadcrumbSentryCallback _enviarBreadcrumbSentry;
  final EnviarExcecaoSentryCallback _enviarExcecaoSentry;

  /// Cria uma instância do [RegistroLogger] permitindo injeção determinística de delegates.
  RegistroLogger({
    this.emModoDesenvolvimento = kModoDesenvolvimento,
    void Function(String mensagem)? impressorConsole,
    EnviarLogCrashlyticsCallback? enviarLogCrashlytics,
    EnviarErroCrashlyticsCallback? enviarErroCrashlytics,
    EnviarBreadcrumbSentryCallback? enviarBreadcrumbSentry,
    EnviarExcecaoSentryCallback? enviarExcecaoSentry,
  })  : _impressorConsole = impressorConsole ?? debugPrint,
        _enviarLogCrashlytics =
            enviarLogCrashlytics ?? _enviarLogCrashlyticsPadrao,
        _enviarErroCrashlytics =
            enviarErroCrashlytics ?? _enviarErroCrashlyticsPadrao,
        _enviarBreadcrumbSentry =
            enviarBreadcrumbSentry ?? _enviarBreadcrumbSentryPadrao,
        _enviarExcecaoSentry =
            enviarExcecaoSentry ?? _enviarExcecaoSentryPadrao;

  /// Instância global padrão utilizada pelos serviços da aplicação.
  static RegistroLogger instancia = RegistroLogger();

  /// Restaura a instância global padrão para isolamento entre testes.
  @visibleForTesting
  static void resetarParaTestes() {
    instancia = RegistroLogger();
  }

  /// Verifica se o SDK do Firebase foi inicializado na execução atual.
  static bool get firebaseInicializado {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static void _enviarLogCrashlyticsPadrao(String mensagem) {
    FirebaseCrashlytics.instance.log(mensagem);
  }

  static Future<void> _enviarErroCrashlyticsPadrao(
    Object erro,
    StackTrace stackTrace, {
    required String motivo,
    required bool fatal,
  }) {
    return FirebaseCrashlytics.instance.recordError(
      erro,
      stackTrace,
      reason: motivo,
      printDetails: false,
      fatal: fatal,
    );
  }

  static void _enviarBreadcrumbSentryPadrao(Breadcrumb breadcrumb) {
    Sentry.addBreadcrumb(breadcrumb);
  }

  static Future<void> _enviarExcecaoSentryPadrao(
    Object erro, {
    required StackTrace stackTrace,
    required String motivo,
    required bool fatal,
    Map<String, Map<String, Object?>>? contextosExtras,
  }) {
    return Sentry.captureException(
      erro,
      stackTrace: stackTrace,
      withScope: (scope) => configurarEscopoSentry(
        scope,
        motivo,
        fatal: fatal,
        contextosExtras: contextosExtras,
      ),
    );
  }

  /// Configura o escopo do evento Sentry com nível de severidade, contexto da falha
  /// e eventuais contextos estruturados extras (como `receita_robo_caotico`).
  @visibleForTesting
  static void configurarEscopoSentry(
    Scope scope,
    String mensagemContexto, {
    required bool fatal,
    Map<String, Map<String, Object?>>? contextosExtras,
  }) {
    scope.level = fatal ? SentryLevel.fatal : SentryLevel.error;
    scope.setContexts('contexto_erro', {
      'mensagem': mensagemContexto,
      'fatal': fatal,
    });
    if (contextosExtras != null) {
      for (final entrada in contextosExtras.entries) {
        scope.setContexts(entrada.key, entrada.value);
      }
    }
  }

  void _executarComProtecao(
    FutureOr<void> Function() acao,
    String contextoFalha,
  ) {
    try {
      final resultado = acao();
      if (resultado is Future<void>) {
        unawaited(
          resultado.catchError((Object e) {
            _impressorConsole('⚠️ [RegistroLogger] $contextoFalha: $e');
          }),
        );
      }
    } catch (e) {
      _impressorConsole('⚠️ [RegistroLogger] $contextoFalha: $e');
    }
  }

  void _registrarBreadcrumbSentry(String mensagem, SentryLevel nivel) {
    _executarComProtecao(
      () {
        final breadcrumb = Breadcrumb(
          message: mensagem,
          level: nivel,
          timestamp: DateTime.now().toUtc(),
        );
        _enviarBreadcrumbSentry(breadcrumb);
      },
      'Erro ao enviar breadcrumb para Sentry',
    );
  }

  /// Registra uma mensagem informativa de ciclo de vida ou operação como breadcrumb
  /// no Sentry e no Firebase Crashlytics.
  void logInfo(String mensagem) {
    if (emModoDesenvolvimento) {
      _impressorConsole('ℹ️ [RegistroLogger] $mensagem');
    }

    _registrarBreadcrumbSentry(mensagem, SentryLevel.info);
    _executarComProtecao(
      () => _enviarLogCrashlytics(mensagem),
      'Erro ao enviar log para Crashlytics',
    );
  }

  /// Registra uma mensagem de aviso operacional exclusivamente como breadcrumb
  /// contextual no Sentry (`warning`) e no Firebase Crashlytics, sem abrir alertas fatais.
  void logAviso(String mensagem) {
    if (emModoDesenvolvimento) {
      _impressorConsole('⚠️ [RegistroLogger AVISO] $mensagem');
    }

    final textoLog = '⚠️ AVISO: $mensagem';
    _registrarBreadcrumbSentry(textoLog, SentryLevel.warning);
    _executarComProtecao(
      () => _enviarLogCrashlytics(textoLog),
      'Erro ao enviar aviso para Crashlytics',
    );
  }

  /// Verifica se o erro ou mensagem descreve uma falha transitória de conectividade,
  /// timeout de socket, instabilidade de gateway/servidor (HTTP 502, 503, 504, 429) ou
  /// falha de transporte nos SDKs do Firebase quando o dispositivo encontra-se offline na montanha.
  static bool isFalhaConexaoOuTimeout(Object? error) {
    if (error == null) return false;

    if (error is int) {
      return error == 502 || error == 503 || error == 504 || error == 429;
    }

    if (error is TimeoutException ||
        error is SocketException ||
        error is HttpException ||
        error is HandshakeException ||
        error is CertificateException) {
      return true;
    }

    if (error is FirebaseException) {
      final codigo = error.code.toLowerCase();
      if (codigo == 'unavailable' ||
          codigo == 'network-request-failed' ||
          codigo == 'network_error' ||
          codigo == 'deadline-exceeded' ||
          codigo == 'throttled') {
        return true;
      }
    }

    final msg = error.toString().toLowerCase();

    if (msg.contains('504') ||
        msg.contains('502') ||
        msg.contains('503') ||
        msg.contains('429') ||
        msg.contains('gateway timeout') ||
        msg.contains('bad gateway') ||
        msg.contains('service unavailable') ||
        msg.contains('too many requests')) {
      return true;
    }

    if (msg.contains(
          'firebase installations failed to get installation auth token',
        ) ||
        msg.contains('error while calling the backend') ||
        msg.contains('unable to connect to the server') ||
        msg.contains('fetch failed') ||
        msg.contains('fetch throttled') ||
        msg.contains('network-request-failed') ||
        msg.contains('network_error') ||
        msg.contains('network error') ||
        msg.contains('unavailable')) {
      return true;
    }

    return msg.contains('timeout') ||
        msg.contains('timed out') ||
        msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('connection reset') ||
        msg.contains('connection closed') ||
        msg.contains('connection abort') ||
        msg.contains('no route to host') ||
        msg.contains('handshake') ||
        msg.contains('clientexception') ||
        msg.contains('falha de rede') ||
        msg.contains('sem conexão') ||
        msg.contains('sem conexao');
  }

  /// Registra um erro operacional no Firebase Crashlytics e no Sentry com [stackTrace] obrigatório.
  void logError(
    String mensagemContexto, {
    Object? error,
    required StackTrace stackTrace,
    bool fatal = false,
    Map<String, Map<String, Object?>>? contextosExtras,
  }) {
    final prefixo = fatal ? '💥 [RegistroLogger CRASH]' : '🛑 [RegistroLogger]';
    _impressorConsole('$prefixo $mensagemContexto');
    if (error != null) _impressorConsole('Exception: $error');
    _impressorConsole('Stack: $stackTrace');

    final excecaoEfetiva = error ?? Exception(mensagemContexto);

    _executarComProtecao(
      () => _enviarExcecaoSentry(
        excecaoEfetiva,
        stackTrace: stackTrace,
        motivo: mensagemContexto,
        fatal: fatal,
        contextosExtras: contextosExtras,
      ),
      'Erro ao enviar exceção para Sentry',
    );

    _executarComProtecao(
      () => _enviarErroCrashlytics(
        excecaoEfetiva,
        stackTrace,
        motivo: mensagemContexto,
        fatal: fatal,
      ),
      'Erro ao enviar erro para Crashlytics',
    );
  }

  /// Registra uma falha crítica no nível de crash (`fatal: true`) no Firebase Crashlytics e no Sentry.
  void logCrash(
    String mensagemContexto, {
    Object? error,
    required StackTrace stackTrace,
    Map<String, Map<String, Object?>>? contextosExtras,
  }) {
    logError(
      mensagemContexto,
      error: error,
      stackTrace: stackTrace,
      fatal: true,
      contextosExtras: contextosExtras,
    );
  }

  /// Registra uma falha de sincronização na nuvem ou comunicação de rede.
  /// Caso a falha seja decorrente de desconexão transitória ou timeout em montanha,
  /// rebaixa o evento para [logAviso] (breadcrumb). Caso contrário, registra como [logCrash].
  void logFalhaSyncOuDownload(
    String mensagemContexto, {
    Object? error,
    required StackTrace stackTrace,
  }) {
    final ehConexaoOuTimeout = isFalhaConexaoOuTimeout(error) ||
        isFalhaConexaoOuTimeout(mensagemContexto);

    if (ehConexaoOuTimeout) {
      final detalhe = error != null ? ' ($error)' : '';
      logAviso('$mensagemContexto$detalhe');
    } else {
      logCrash(
        mensagemContexto,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
