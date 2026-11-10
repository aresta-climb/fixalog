// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Registro de uma chamada de exibição ou início de serviço em primeiro plano
/// capturada pelo [PluginNotificacoesLocaisFake].
class RegistroNotificacaoExibidaFake {
  /// Identificador numérico da notificação.
  final int id;

  /// Título exibido na notificação.
  final String? titulo;

  /// Corpo de texto exibido na notificação.
  final String? corpo;

  /// Payload de navegação associado à notificação.
  final String? payload;

  /// Detalhes gerais da notificação (quando exibida via `show`).
  final NotificationDetails? detalhes;

  /// Detalhes específicos do Android (quando exibida via `startForegroundService`).
  final AndroidNotificationDetails? detalhesAndroid;

  /// Tipos de serviço em primeiro plano solicitados no Android.
  final Set<AndroidServiceForegroundType>? tiposServicoPrimeiroPlano;

  /// Cria um registro imutável da notificação capturada em memória.
  const RegistroNotificacaoExibidaFake({
    required this.id,
    this.titulo,
    this.corpo,
    this.payload,
    this.detalhes,
    this.detalhesAndroid,
    this.tiposServicoPrimeiroPlano,
  });
}

/// Implementação Fake em memória do [AndroidFlutterLocalNotificationsPlugin]
/// para testes determinísticos de notificações e Foreground Service no Android.
class ImplementacaoAndroidNotificacoesFake
    implements AndroidFlutterLocalNotificationsPlugin {
  /// Canais de notificação criados durante o teste.
  final List<AndroidNotificationChannel> canaisCriados = [];

  /// Serviços em primeiro plano iniciados ou atualizados durante o teste.
  final List<RegistroNotificacaoExibidaFake> servicosIniciados = [];

  /// Quantidade de vezes que a permissão de notificações foi solicitada.
  int chamadasSolicitarPermissao = 0;

  /// Quantidade de vezes que `stopForegroundService` foi invocado.
  int chamadasPararServicoPrimeiroPlano = 0;

  /// Resultado configurável para `requestNotificationsPermission`.
  bool? resultadoPermissao = true;

  /// Erro opcional a ser lançado ao criar canal de notificação.
  Object? erroAoCriarCanal;

  /// Erro opcional a ser lançado ao solicitar permissão.
  Object? erroAoSolicitarPermissao;

  /// Erro opcional a ser lançado ao iniciar o serviço em primeiro plano.
  Object? erroAoIniciarServicoPrimeiroPlano;

  /// Erro opcional a ser lançado ao parar o serviço em primeiro plano.
  Object? erroAoPararServicoPrimeiroPlano;

  @override
  Future<void> createNotificationChannel(
    AndroidNotificationChannel channel,
  ) async {
    if (erroAoCriarCanal != null) {
      throw erroAoCriarCanal!;
    }
    canaisCriados.add(channel);
  }

  @override
  Future<bool?> requestNotificationsPermission() async {
    if (erroAoSolicitarPermissao != null) {
      throw erroAoSolicitarPermissao!;
    }
    chamadasSolicitarPermissao++;
    return resultadoPermissao;
  }

  @override
  Future<void> startForegroundService({
    required int id,
    String? title,
    String? body,
    AndroidNotificationDetails? notificationDetails,
    String? payload,
    AndroidServiceStartType startType = AndroidServiceStartType.startSticky,
    Set<AndroidServiceForegroundType>? foregroundServiceTypes,
  }) async {
    if (erroAoIniciarServicoPrimeiroPlano != null) {
      throw erroAoIniciarServicoPrimeiroPlano!;
    }
    servicosIniciados.add(
      RegistroNotificacaoExibidaFake(
        id: id,
        titulo: title,
        corpo: body,
        payload: payload,
        detalhesAndroid: notificationDetails,
        tiposServicoPrimeiroPlano: foregroundServiceTypes,
      ),
    );
  }

  @override
  Future<void> stopForegroundService() async {
    if (erroAoPararServicoPrimeiroPlano != null) {
      throw erroAoPararServicoPrimeiroPlano!;
    }
    chamadasPararServicoPrimeiroPlano++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Implementação Fake em memória do [IOSFlutterLocalNotificationsPlugin]
/// para testes determinísticos de permissões de notificação no iOS.
class ImplementacaoIOSNotificacoesFake
    implements IOSFlutterLocalNotificationsPlugin {
  /// Quantidade de vezes que `requestPermissions` foi chamado.
  int chamadasSolicitarPermissao = 0;

  /// Último valor de `alert` recebido em `requestPermissions`.
  bool? ultimoAlertaSolicitado;

  /// Último valor de `badge` recebido em `requestPermissions`.
  bool? ultimoBadgeSolicitado;

  /// Último valor de `sound` recebido em `requestPermissions`.
  bool? ultimoSomSolicitado;

  /// Resultado configurável para `requestPermissions`.
  bool? resultadoPermissao = true;

  /// Erro opcional a ser lançado ao solicitar permissões no iOS.
  Object? erroAoSolicitarPermissao;

  @override
  Future<bool?> requestPermissions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
    bool critical = false,
    bool provisional = false,
    bool carPlay = false,
    bool providesAppNotificationSettings = false,
  }) async {
    if (erroAoSolicitarPermissao != null) {
      throw erroAoSolicitarPermissao!;
    }
    chamadasSolicitarPermissao++;
    ultimoAlertaSolicitado = alert;
    ultimoBadgeSolicitado = badge;
    ultimoSomSolicitado = sound;
    return resultadoPermissao;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Implementação Fake determinística em memória de [FlutterLocalNotificationsPlugin].
class PluginNotificacoesLocaisFake implements FlutterLocalNotificationsPlugin {
  /// Implementação Android Fake associada (ou `null` quando simulando ausência).
  ImplementacaoAndroidNotificacoesFake? androidFake;

  /// Implementação iOS Fake associada (ou `null` quando simulando ausência).
  ImplementacaoIOSNotificacoesFake? iosFake;

  /// Configurações recebidas na chamada `initialize`.
  InitializationSettings? configuracoesInicializadas;

  /// Callback registrado em `initialize` para cliques em notificações.
  DidReceiveNotificationResponseCallback? callbackRespostaNotificacao;

  /// Lista de todas as notificações exibidas via `show`.
  final List<RegistroNotificacaoExibidaFake> notificacoesExibidas = [];

  /// Lista de IDs de notificações canceladas via `cancel`.
  final List<int> idsCancelados = [];

  /// Resultado configurável de `initialize`.
  bool? resultadoInicializacao = true;

  /// Erro opcional a ser lançado em `initialize`.
  Object? erroAoInicializar;

  /// Erro opcional a ser lançado em `show`.
  Object? erroAoExibir;

  /// Erro opcional a ser lançado em `cancel`.
  Object? erroAoCancelar;

  /// Cria uma instância Fake com implementações Android e iOS habilitadas por padrão.
  PluginNotificacoesLocaisFake({
    ImplementacaoAndroidNotificacoesFake? android,
    ImplementacaoIOSNotificacoesFake? ios,
    bool habilitarAndroidPorPadrao = true,
    bool habilitarIOSPorPadrao = true,
  }) : androidFake =
           android ??
           (habilitarAndroidPorPadrao
               ? ImplementacaoAndroidNotificacoesFake()
               : null),
       iosFake =
           ios ??
           (habilitarIOSPorPadrao ? ImplementacaoIOSNotificacoesFake() : null);

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    if (erroAoInicializar != null) {
      throw erroAoInicializar!;
    }
    configuracoesInicializadas = settings;
    callbackRespostaNotificacao = onDidReceiveNotificationResponse;
    return resultadoInicializacao;
  }

  /// Simula o toque do usuário em uma notificação exibida ou em uma ação da notificação, disparando o callback registrado.
  void simularToqueNotificacao({
    int id = 1,
    String? payload,
    String? actionId,
  }) {
    callbackRespostaNotificacao?.call(
      NotificationResponse(
        notificationResponseType: actionId != null
            ? NotificationResponseType.selectedNotificationAction
            : NotificationResponseType.selectedNotification,
        id: id,
        payload: payload,
        actionId: actionId,
      ),
    );
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() {
    if (T == AndroidFlutterLocalNotificationsPlugin) {
      return androidFake as T?;
    }
    if (T == IOSFlutterLocalNotificationsPlugin) {
      return iosFake as T?;
    }
    return null;
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    if (erroAoExibir != null) {
      throw erroAoExibir!;
    }
    notificacoesExibidas.add(
      RegistroNotificacaoExibidaFake(
        id: id,
        titulo: title,
        corpo: body,
        payload: payload,
        detalhes: notificationDetails,
      ),
    );
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    if (erroAoCancelar != null) {
      throw erroAoCancelar!;
    }
    idsCancelados.add(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
