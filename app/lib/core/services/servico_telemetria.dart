// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'classificador_dispositivo.dart';
import 'registro_logger.dart';

/// Assinatura de delegação para ativar ou desativar a coleta do Firebase Analytics.
typedef ConfigurarColetaAnalyticsCallback = Future<void> Function(
  bool habilitado,
);

/// Assinatura de delegação para envio de evento ao Firebase Analytics.
typedef EnviarEventoAnalyticsCallback = Future<void> Function(
  String nome,
  Map<String, Object>? parametros,
);

/// Serviço responsável por disparar eventos de telemetria anônima para o Firebase Analytics
/// e enriquecer os breadcrumbs de diagnóstico no [RegistroLogger].
class ServicoTelemetria {
  final RegistroLogger _logger;
  final ConfigurarColetaAnalyticsCallback _configurarColetaAnalytics;
  final EnviarEventoAnalyticsCallback _enviarEventoAnalytics;

  /// Cria uma instância de [ServicoTelemetria] permitindo injeção determinística em testes.
  ServicoTelemetria({
    RegistroLogger? logger,
    ConfigurarColetaAnalyticsCallback? configurarColetaAnalytics,
    EnviarEventoAnalyticsCallback? enviarEventoAnalytics,
  })  : _logger = logger ?? RegistroLogger.instancia,
        _configurarColetaAnalytics =
            configurarColetaAnalytics ?? _configurarColetaPadrao,
        _enviarEventoAnalytics =
            enviarEventoAnalytics ?? _enviarEventoPadrao;

  /// Instância global padrão utilizada pela aplicação.
  static ServicoTelemetria instancia = ServicoTelemetria();

  /// Restaura a instância global padrão para isolamento entre testes.
  @visibleForTesting
  static void resetarParaTestes() {
    instancia = ServicoTelemetria();
  }

  static Future<void> _configurarColetaPadrao(bool habilitado) {
    return FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(habilitado);
  }

  static Future<void> _enviarEventoPadrao(
    String nome,
    Map<String, Object>? parametros,
  ) {
    return FirebaseAnalytics.instance.logEvent(
      name: nome,
      parameters: parametros,
    );
  }

  /// Inicializa e configura a coleta do Firebase Analytics, desativando-a fora de builds de release oficial.
  Future<void> inicializar({bool? emModoDesenvolvimento}) async {
    final isDebug = emModoDesenvolvimento ?? kModoDesenvolvimento;
    final habilitarColeta = !isDebug;
    try {
      await _configurarColetaAnalytics(habilitarColeta);
      _logger.logInfo(
        '📊 [ServicoTelemetria] Coleta do Firebase Analytics configurada (habilitada: $habilitarColeta).',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        '⚠️ [ServicoTelemetria] Erro ao configurar coleta do Firebase Analytics',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Dispara um evento de telemetria, enriquecendo automaticamente métricas de duração (`duracao_ms`)
  /// com as dimensões de hardware (`tier_dispositivo` e `ram_gb`).
  Future<void> registrarEvento(
    String nome, {
    Map<String, Object>? parametros,
  }) async {
    final Map<String, Object>? parametrosEnriquecidos;
    if (parametros != null && parametros.containsKey('duracao_ms')) {
      parametrosEnriquecidos = <String, Object>{
        'tier_dispositivo': ClassificadorDispositivo.instancia.tierDispositivo,
        'ram_gb': ClassificadorDispositivo.instancia.ramGb,
        ...parametros,
      };
    } else {
      parametrosEnriquecidos = parametros;
    }

    _logger.logInfo(
      '📈 [ServicoTelemetria] Evento: $nome | Parâmetros: $parametrosEnriquecidos',
    );

    try {
      await _enviarEventoAnalytics(nome, parametrosEnriquecidos);
    } catch (e, stackTrace) {
      _logger.logError(
        '⚠️ [ServicoTelemetria] Erro ao enviar evento analítico ($nome)',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Registra o início de preenchimento de um protocolo pericial no Wizard.
  Future<void> registrarInicioProtocolo(
    String idProtocolo, {
    required String idioma,
  }) {
    return registrarEvento(
      'iniciar_protocolo',
      parametros: {
        'id_protocolo': idProtocolo,
        'idioma': idioma,
      },
    );
  }

  /// Registra a conclusão e o tempo de empacotamento/assinatura de um laudo EPUB 3.
  Future<void> registrarGeracaoLaudoEpub({
    required String idProtocolo,
    required int duracaoMs,
    required bool assinado,
  }) {
    return registrarEvento(
      'gerar_laudo_epub',
      parametros: {
        'id_protocolo': idProtocolo,
        'duracao_ms': duracaoMs,
        'assinado': assinado ? 'true' : 'false',
      },
    );
  }

  /// Registra o resultado de um ciclo de sincronização com a nuvem.
  Future<void> registrarSincronizacaoNuvem({
    required int enviados,
    required int falhas,
  }) {
    return registrarEvento(
      'sincronizar_nuvem',
      parametros: {
        'enviados': enviados,
        'falhas': falhas,
      },
    );
  }

  /// Registra a abertura de links externos oficiais (WhatsApp, Portal Aresta Climb).
  Future<void> registrarAberturaLinkExterno(
    String url, {
    required String origem,
  }) {
    return registrarEvento(
      'link_externo',
      parametros: {
        'url': url,
        'origem': origem,
      },
    );
  }
}
