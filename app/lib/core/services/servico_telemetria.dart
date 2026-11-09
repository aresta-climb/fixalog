// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'classificador_dispositivo.dart';
import 'gravador_breadcrumbs.dart';
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

/// Serviço responsável por disparar eventos de telemetria anônima para o Firebase Analytics,
/// alimentar o buffer circular [GravadorBreadcrumbs] e emitir breadcrumbs estruturados
/// no terminal, Sentry e Crashlytics via [RegistroLogger].
class ServicoTelemetria {
  final RegistroLogger? _loggerOverride;
  final GravadorBreadcrumbs? _gravadorBreadcrumbsOverride;
  final ConfigurarColetaAnalyticsCallback _configurarColetaAnalytics;
  final EnviarEventoAnalyticsCallback _enviarEventoAnalytics;

  RegistroLogger get _logger => _loggerOverride ?? RegistroLogger.instancia;
  GravadorBreadcrumbs get _gravadorBreadcrumbs =>
      _gravadorBreadcrumbsOverride ?? GravadorBreadcrumbs.instancia;

  /// Cria uma instância de [ServicoTelemetria] permitindo injeção determinística em testes.
  ServicoTelemetria({
    RegistroLogger? logger,
    GravadorBreadcrumbs? gravadorBreadcrumbs,
    ConfigurarColetaAnalyticsCallback? configurarColetaAnalytics,
    EnviarEventoAnalyticsCallback? enviarEventoAnalytics,
  })  : _loggerOverride = logger,
        _gravadorBreadcrumbsOverride = gravadorBreadcrumbs,
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
      if (!e.toString().contains('no-app')) {
        _logger.logError(
          '⚠️ [ServicoTelemetria] Erro ao configurar coleta do Firebase Analytics',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Dispara um evento de telemetria, enriquecendo automaticamente métricas de duração (`duracao_ms`)
  /// com as dimensões de hardware (`tier_dispositivo` e `ram_gb`), gravando no [GravadorBreadcrumbs]
  /// e emitindo log/breadcrumb no [RegistroLogger].
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

    _gravadorBreadcrumbs.registrar(
      evento: nome,
      parametros: parametrosEnriquecidos,
    );

    _logger.logInfo(
      '📈 [ServicoTelemetria] Evento: $nome | Parâmetros: $parametrosEnriquecidos',
    );

    try {
      await _enviarEventoAnalytics(nome, parametrosEnriquecidos);
    } catch (e, stackTrace) {
      if (!e.toString().contains('no-app')) {
        _logger.logError(
          '⚠️ [ServicoTelemetria] Erro ao enviar evento analítico ($nome)',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Registra a troca de aba na barra de navegação inferior da `HomeScreen`.
  Future<void> registrarNavegacaoAba(String aba) {
    return registrarEvento('navegar_aba', parametros: {'aba': aba});
  }

  /// Registra o início de preenchimento ou edição de um protocolo pericial no Wizard.
  Future<void> registrarInicioProtocolo(
    String idProtocolo, {
    required String idioma,
    String modo = 'novo',
  }) {
    return registrarEvento(
      'iniciar_protocolo',
      parametros: {
        'id_protocolo': idProtocolo,
        'idioma': idioma,
        'modo': modo,
      },
    );
  }

  /// Registra o avanço ou retorno entre etapas do Wizard.
  Future<void> registrarEtapaWizard({
    required String acao,
    required String idProtocolo,
    required String stepId,
    required int indice,
  }) {
    return registrarEvento(
      'etapa_wizard',
      parametros: {
        'acao': acao,
        'id_protocolo': idProtocolo,
        'step_id': stepId,
        'indice': indice,
      },
    );
  }

  /// Registra a escolha de uma ramificação condicional (`SelecaoRamo`) no Wizard.
  Future<void> registrarEscolhaRamoWizard({
    required String idProtocolo,
    required String conteudoId,
    required String opcao,
  }) {
    return registrarEvento(
      'escolher_ramo_wizard',
      parametros: {
        'id_protocolo': idProtocolo,
        'conteudo_id': conteudoId,
        'opcao': opcao,
      },
    );
  }

  /// Registra a adição, remoção ou expansão de um item em uma `StepListaAcoes` do Wizard.
  Future<void> registrarAcaoListaWizard({
    required String acao,
    required String conteudoId,
    String? tipoId,
  }) {
    return registrarEvento(
      'acao_lista_wizard',
      parametros: {
        'acao': acao,
        'conteudo_id': conteudoId,
        'tipo_id': ?tipoId,
      },
    );
  }

  /// Registra a captura, seleção ou remoção de mídia/GPS no Wizard.
  Future<void> registrarAcaoMidiaWizard({
    required String acao,
    required String tipoMidia,
    String? campoId,
  }) {
    return registrarEvento(
      'acao_midia_wizard',
      parametros: {
        'acao': acao,
        'tipo_midia': tipoMidia,
        'campo_id': ?campoId,
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

  /// Registra interações na tela de Histórico (`abrir_relatorio`, `editar_rascunho`, `excluir_registro`, `filtrar_materiais`).
  Future<void> registrarAcaoHistorico({
    required String acao,
    String? idProtocolo,
    String? status,
  }) {
    return registrarEvento(
      'acao_historico',
      parametros: {
        'acao': acao,
        'id_protocolo': ?idProtocolo,
        'status': ?status,
      },
    );
  }

  /// Registra interações no Visualizador de Relatório (`compartilhar_link_web`, `exportar_epub`, `abrir_externo`, `publicar_nuvem`).
  Future<void> registrarAcaoVisualizadorRelatorio({
    required String acao,
    String? idSessao,
  }) {
    return registrarEvento(
      'acao_visualizador_relatorio',
      parametros: {
        'acao': acao,
        'id_sessao': ?idSessao,
      },
    );
  }

  /// Registra o aceite dos Termos de Uso no Onboarding.
  Future<void> registrarAceiteTermosUso(String versaoLegal) {
    return registrarEvento(
      'aceitar_termos_uso',
      parametros: {'versao_legal': versaoLegal},
    );
  }

  /// Registra o salvamento da identidade técnica do auditor.
  Future<void> registrarSalvarIdentidade({required bool possuiClube}) {
    return registrarEvento(
      'salvar_identidade',
      parametros: {'possui_clube': possuiClube ? 'true' : 'false'},
    );
  }

  /// Registra ações na tela de Configurações (`alterar_idioma`, `login_oidc`, `logout_oidc`, `abrir_termos`, `editar_identidade`).
  Future<void> registrarAcaoConfiguracoes(
    String acao, {
    String? detalhe,
  }) {
    return registrarEvento(
      'acao_configuracoes',
      parametros: {
        'acao': acao,
        'detalhe': ?detalhe,
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

  /// Registra interações do fluxo de feedback in-app offline (`enfileirar_feedback`, `enviar_feedback`).
  Future<void> registrarAcaoFeedback(
    String acao, {
    String? categoria,
    String? idFeedback,
  }) {
    return registrarEvento(
      'acao_feedback',
      parametros: {
        'acao': acao,
        'categoria': ?categoria,
        'id_feedback': ?idFeedback,
      },
    );
  }
}
