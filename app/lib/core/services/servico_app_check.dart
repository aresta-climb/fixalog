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
  final bool _emModoDesenvolvimento;
  final DateTime Function() _relogio;
  final Duration _duracaoCooldownFalha;
  DateTime? _cooldownAte;

  /// Cria uma instância de [ServicoAppCheck] permitindo injeção determinística de dependências.
  ServicoAppCheck({
    RegistroLogger? logger,
    AtivarAppCheckCallback? ativarAppCheck,
    ObterTokenAppCheckCallback? obterTokenAppCheck,
    bool emModoDesenvolvimento = kModoDesenvolvimento,
    DateTime Function()? relogio,
    Duration duracaoCooldownFalha = const Duration(minutes: 5),
  })  : _logger = logger ?? RegistroLogger.instancia,
        _ativarAppCheck = ativarAppCheck ?? _ativarPadrao,
        _obterTokenAppCheck = obterTokenAppCheck ?? _obterTokenPadrao,
        _emModoDesenvolvimento = emModoDesenvolvimento,
        _relogio = relogio ?? DateTime.now,
        _duracaoCooldownFalha = duracaoCooldownFalha;

  /// Identifica se o [erro] corresponde a rate-limit (`Too many attempts`) ou
  /// rejeição de atestação (`DecodeIntegrityToken` / `App attestation failed`)
  /// comum em emuladores de Pre-Launch Report.
  static bool isFalhaAtestacaoOuRateLimit(Object erro) {
    final texto = erro.toString().toLowerCase();
    return texto.contains('too many attempts') ||
        texto.contains('decodeintegritytoken') ||
        texto.contains('app attestation failed');
  }

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
  /// esteja offline, em *cooldown* após falha prévia ou em ambiente não atestado.
  Future<String?> obterToken([bool forcarAtualizacao = false]) async {
    if (!forcarAtualizacao &&
        _cooldownAte != null &&
        _relogio().isBefore(_cooldownAte!)) {
      return null;
    }
    try {
      final token = await _obterTokenAppCheck(forcarAtualizacao);
      _cooldownAte = null;
      return token;
    } catch (e, stackTrace) {
      if (RegistroLogger.isFalhaConexaoOuTimeout(e)) {
        _logger.logAviso(
          '🛡️ [ServicoAppCheck] Falha de conexão ao obter token do App Check (offline/timeout): $e',
        );
      } else {
        _cooldownAte = _relogio().add(_duracaoCooldownFalha);
        if (_emModoDesenvolvimento) {
          _logger.logAviso(
            '🛡️ [ServicoAppCheck] Token do App Check indisponível em modo de desenvolvimento (UUID de debug não registrado): $e',
          );
        } else if (isFalhaAtestacaoOuRateLimit(e)) {
          _logger.logAviso(
            '🛡️ [ServicoAppCheck] Limite de tentativas ou atestação recusada no App Check (cooldown ativo): $e',
          );
        } else {
          _logger.logError(
            '🛡️ [ServicoAppCheck] Não foi possível obter o token do App Check',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
      return null;
    }
  }
}
