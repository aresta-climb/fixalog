// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'registro_logger.dart';

/// Assinatura de delegação para ativar o provedor nativo do Firebase App Check.
typedef AtivarAppCheckCallback = Future<void> Function({
  required AndroidAppCheckProvider providerAndroid,
  required AppleAppCheckProvider providerApple,
});

/// Assinatura de delegação para solicitar token JWT do Firebase App Check.
typedef ObterTokenAppCheckCallback = Future<String?> Function(
  bool forcarAtualizacao,
);

/// Serviço responsável por gerenciar a atestação de integridade do aplicativo via Firebase App Check.
///
/// Encapsula a inicialização e obtenção de tokens JWT do Play Integrity (Android),
/// App Attest (iOS) e Debug Provider durante o desenvolvimento, degradando
/// graciosamente quando o dispositivo opera offline na montanha.
class ServicoAppCheck {
  final RegistroLogger _logger;
  final AtivarAppCheckCallback _ativarAppCheck;
  final ObterTokenAppCheckCallback _obterTokenAppCheck;

  /// Cria uma instância de [ServicoAppCheck] permitindo injeção determinística de dependências.
  ServicoAppCheck({
    RegistroLogger? logger,
    AtivarAppCheckCallback? ativarAppCheck,
    ObterTokenAppCheckCallback? obterTokenAppCheck,
  })  : _logger = logger ?? RegistroLogger.instancia,
        _ativarAppCheck = ativarAppCheck ?? _ativarPadrao,
        _obterTokenAppCheck = obterTokenAppCheck ?? _obterTokenPadrao;

  /// Instância global padrão utilizada pela aplicação.
  static ServicoAppCheck instancia = ServicoAppCheck();

  /// Restaura a instância global padrão para isolamento entre testes.
  @visibleForTesting
  static void resetarParaTestes() {
    instancia = ServicoAppCheck();
  }

  static Future<void> _ativarPadrao({
    required AndroidAppCheckProvider providerAndroid,
    required AppleAppCheckProvider providerApple,
  }) {
    return FirebaseAppCheck.instance.activate(
      providerAndroid: providerAndroid,
      providerApple: providerApple,
    );
  }

  static Future<String?> _obterTokenPadrao(bool forcarAtualizacao) {
    return FirebaseAppCheck.instance.getToken(forcarAtualizacao);
  }

  /// Inicializa e ativa o Firebase App Check com os provedores adequados para release e desenvolvimento.
  Future<void> ativar({
    AndroidAppCheckProvider? providerAndroid,
    AppleAppCheckProvider? providerApple,
    bool? emModoRelease,
  }) async {
    final isRelease = emModoRelease ?? kModoReleaseOficial;
    try {
      await _ativarAppCheck(
        providerAndroid: providerAndroid ??
            (isRelease
                ? const AndroidPlayIntegrityProvider()
                : const AndroidDebugProvider()),
        providerApple: providerApple ??
            (isRelease
                ? const AppleAppAttestProvider()
                : const AppleDebugProvider()),
      );
      _logger.logInfo(
        '🛡️ [ServicoAppCheck] Firebase App Check ativado com sucesso.',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        '🛡️ [ServicoAppCheck] Erro ao ativar Firebase App Check',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Obtém o token JWT atual do App Check, retornando `null` caso o dispositivo
  /// esteja offline ou em ambiente não atestado.
  Future<String?> obterToken([bool forcarAtualizacao = false]) async {
    try {
      return await _obterTokenAppCheck(forcarAtualizacao);
    } catch (e, stackTrace) {
      if (RegistroLogger.isFalhaConexaoOuTimeout(e)) {
        _logger.logAviso(
          '🛡️ [ServicoAppCheck] Falha de conexão ao obter token do App Check (offline/timeout): $e',
        );
      } else {
        _logger.logError(
          '🛡️ [ServicoAppCheck] Não foi possível obter o token do App Check',
          error: e,
          stackTrace: stackTrace,
        );
      }
      return null;
    }
  }
}
