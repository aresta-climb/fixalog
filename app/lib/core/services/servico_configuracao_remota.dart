// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'registro_logger.dart';

/// Assinatura de delegação para sincronizar parâmetros com o provedor remoto.
typedef SincronizarConfiguracaoRemotaCallback = Future<Map<String, Object>>
    Function(Map<String, Object> valoresPadrao);

/// Serviço responsável por gerenciar o Firebase Remote Config de forma reativa e 100% offline-first.
///
/// Carrega imediatamente valores padrão estáticos em memória e sincroniza parâmetros
/// em segundo plano sem bloquear a inicialização do aplicativo na montanha.
class ServicoConfiguracaoRemota extends ChangeNotifier {
  static const String kUrlWhatsappPadrao =
      'https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv';
  static const String kUrlPortalArestaPadrao = 'https://arestaclimb.com';
  static const String kUrlWorkerFixalogPadrao = 'https://fixalog.app';
  static const String kUrlFeedbackEdgeFunctionPadrao =
      'https://yzkhiaoqtxvvcyyuwmqg.supabase.co/functions/v1/app-feedback';

  /// Valores padrão estáticos garantidos em modo offline.
  static const Map<String, Object> valoresPadrao = {
    'versao_recomendada': 0,
    'versao_minima_aviso': 0,
    'versao_minima_bloqueio': 0,
    'modo_manutencao': false,
    'url_comunidade_whatsapp': kUrlWhatsappPadrao,
    'url_portal_aresta': kUrlPortalArestaPadrao,
    'url_worker_fixalog': kUrlWorkerFixalogPadrao,
    'url_feedback_edge_function': kUrlFeedbackEdgeFunctionPadrao,
  };

  final RegistroLogger _logger;
  final SincronizarConfiguracaoRemotaCallback _sincronizarRemoto;
  final Map<String, Object> _valoresAtivos =
      Map<String, Object>.from(valoresPadrao);

  Future<void>? _futuroInicializacao;

  /// Cria uma instância de [ServicoConfiguracaoRemota] com suporte a injeção para testes.
  ServicoConfiguracaoRemota({
    RegistroLogger? logger,
    SincronizarConfiguracaoRemotaCallback? sincronizarRemoto,
  })  : _logger = logger ?? RegistroLogger.instancia,
        _sincronizarRemoto = sincronizarRemoto ?? sincronizarPadrao;

  /// Instância global padrão utilizada pela aplicação.
  static ServicoConfiguracaoRemota instancia = ServicoConfiguracaoRemota();

  /// Restaura a instância global padrão para isolamento entre testes.
  @visibleForTesting
  static void resetarParaTestes() {
    instancia = ServicoConfiguracaoRemota();
  }

  /// Converte um mapa de [RemoteConfigValue] nos tipos primitivos esperados por [valoresPadrao].
  @visibleForTesting
  static Map<String, Object> converterValoresRemotos(
    Map<String, RemoteConfigValue> valoresBrutos,
  ) {
    final resultado = <String, Object>{};
    for (final entrada in valoresBrutos.entries) {
      final padrao = valoresPadrao[entrada.key];
      if (padrao is int) {
        resultado[entrada.key] = entrada.value.asInt();
      } else if (padrao is bool) {
        resultado[entrada.key] = entrada.value.asBool();
      } else {
        resultado[entrada.key] = entrada.value.asString();
      }
    }
    return resultado;
  }

  /// Sincroniza os parâmetros com o SDK nativo do Firebase Remote Config.
  @visibleForTesting
  static Future<Map<String, Object>> sincronizarPadrao(
    Map<String, Object> padroes, {
    Future<void> Function(Map<String, Object>)? definirPadroes,
    Future<bool> Function()? buscarEAtivar,
    Map<String, RemoteConfigValue> Function()? obterTodos,
  }) async {
    await (definirPadroes ?? FirebaseRemoteConfig.instance.setDefaults)(padroes);
    await (buscarEAtivar ?? FirebaseRemoteConfig.instance.fetchAndActivate)();
    final brutos = (obterTodos ?? FirebaseRemoteConfig.instance.getAll)();
    return converterValoresRemotos(brutos);
  }

  /// Inicializa e sincroniza os parâmetros remotos em segundo plano.
  Future<void> inicializar() {
    _futuroInicializacao ??= _inicializarInterno();
    return _futuroInicializacao!;
  }

  Future<void> _inicializarInterno() async {
    try {
      final novosValores = await _sincronizarRemoto(valoresPadrao);
      _valoresAtivos.addAll(novosValores);
      _logger.logInfo(
        '🔧 [ServicoConfiguracaoRemota] Configuração remota sincronizada com sucesso.',
      );
      notifyListeners();
    } catch (e, stackTrace) {
      if (RegistroLogger.isFalhaConexaoOuTimeout(e)) {
        _futuroInicializacao = null;
        _logger.logAviso(
          '🔧 [ServicoConfiguracaoRemota] Offline/timeout ao buscar configuração remota. Usando valores padrão: $e',
        );
      } else {
        _logger.logError(
          '🔧 [ServicoConfiguracaoRemota] Erro ao buscar configurações remotas',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Cria um [RemoteConfigValue] a partir de string UTF-8 para testes determinísticos de conversão.
  @visibleForTesting
  static RemoteConfigValue criarValorRemotoTexto(String texto) {
    return RemoteConfigValue(utf8.encode(texto), ValueSource.valueRemote);
  }

  /// Retorna um valor booleano da configuração ativa ou `false` como fallback.
  bool obterBool(String chave) {
    final valor = _valoresAtivos[chave];
    return valor is bool ? valor : false;
  }

  /// Retorna um valor inteiro da configuração ativa ou `0` como fallback.
  int obterInt(String chave) {
    final valor = _valoresAtivos[chave];
    return valor is int ? valor : 0;
  }

  /// Retorna uma string da configuração ativa ou `""` como fallback.
  String obterString(String chave) {
    final valor = _valoresAtivos[chave];
    return valor is String ? valor : '';
  }

  /// Versão recomendada do aplicativo para aviso informativo.
  int get versaoRecomendada => obterInt('versao_recomendada');

  /// Versão mínima recomendada antes de exibir alerta de atualização.
  int get versaoMinimaAviso => obterInt('versao_minima_aviso');

  /// Versão mínima obrigatória para operação.
  int get versaoMinimaBloqueio => obterInt('versao_minima_bloqueio');

  /// URL oficial da comunidade Aresta Climb no WhatsApp.
  String get urlComunidadeWhatsapp {
    final valor = obterString('url_comunidade_whatsapp').trim();
    return valor.isNotEmpty ? valor : kUrlWhatsappPadrao;
  }

  /// URL oficial do portal institucional Aresta Climb.
  String get urlPortalAresta {
    final valor = obterString('url_portal_aresta').trim();
    return valor.isNotEmpty ? valor : kUrlPortalArestaPadrao;
  }

  /// URL base do Cloudflare Worker do Fixalog.
  String get urlWorkerFixalog {
    final valor = obterString('url_worker_fixalog').trim();
    return valor.isNotEmpty ? valor : kUrlWorkerFixalogPadrao;
  }

  /// URL da Edge Function de recebimento de feedbacks in-app.
  String get urlFeedbackEdgeFunction {
    final valor = obterString('url_feedback_edge_function').trim();
    return valor.isNotEmpty ? valor : kUrlFeedbackEdgeFunctionPadrao;
  }
}
