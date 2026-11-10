// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Gerenciador de notificações locais *sticky* para o envio de pacotes `.epub`
/// e verificação assíncrona de mídias no servidor Fixalog.
///
/// Mantém uma notificação persistente (`ongoing: true`) com barra de progresso
/// combinada (0–50% envio de blocos + 50–100% verificação de mídias) e, ao
/// concluir (`status_moderacao == 'ativo'`), substitui por uma notificação
/// clicável que reabre o relatório na tela de visualização para compartilhamento.
class GerenciadorNotificacaoUploadLaudo {
  /// Instância compartilhada padrão do gerenciador.
  static final GerenciadorNotificacaoUploadLaudo instancia =
      GerenciadorNotificacaoUploadLaudo._interno();

  FlutterLocalNotificationsPlugin _plugin;
  bool _inicializado = false;
  bool _permissaoSolicitada = false;
  bool _servicoPrimeiroPlanoAtivo = false;
  String? _idSessaoTocadoPendente;

  final StreamController<String> _controladorLaudosSelecionados =
      StreamController<String>.broadcast();

  /// Callback opcional invocado imediatamente quando o usuário toca na notificação de conclusão.
  void Function(String idSessao)? aoSelecionarLaudoConcluido;

  /// Canal de eventos emitido sempre que o usuário toca em uma notificação de laudo concluído.
  Stream<String> get streamLaudosSelecionados =>
      _controladorLaudosSelecionados.stream;

  static const String _idCanalProgresso = 'fixalog_uploads_progresso';
  static const String _nomeCanalProgresso = 'Publicação de Laudos Fixalog';
  static const String _descricaoCanalProgresso =
      'Progresso de envio em blocos e verificação de integridade de laudos periciais';

  static const String _idCanalConclusao = 'fixalog_uploads_concluidos';
  static const String _nomeCanalConclusao = 'Laudos Publicados';
  static const String _descricaoCanalConclusao =
      'Avisos de conclusão da verificação de laudos prontos para compartilhamento';

  GerenciadorNotificacaoUploadLaudo._interno({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Construtor dedicado para testes com injeção explícita do plugin de notificações.
  @visibleForTesting
  factory GerenciadorNotificacaoUploadLaudo.paraTestes({
    required FlutterLocalNotificationsPlugin plugin,
  }) {
    return GerenciadorNotificacaoUploadLaudo._interno(plugin: plugin);
  }

  /// Reinicia o estado interno do gerenciador para testes isolados.
  @visibleForTesting
  void reiniciarParaTestes({FlutterLocalNotificationsPlugin? novoPlugin}) {
    if (novoPlugin != null) {
      _plugin = novoPlugin;
    }
    _inicializado = false;
    _permissaoSolicitada = false;
    _servicoPrimeiroPlanoAtivo = false;
    _idSessaoTocadoPendente = null;
  }

  /// Consome e limpa o `idSessao` da última notificação tocada pelo usuário, se houver.
  String? consumirIdSessaoTocadoPendente() {
    final pendente = _idSessaoTocadoPendente;
    _idSessaoTocadoPendente = null;
    return pendente;
  }

  void _aoReceberToqueNotificacao(NotificationResponse resposta) {
    final payload = resposta.payload?.trim();
    if (payload == null || payload.isEmpty) {
      return;
    }
    _idSessaoTocadoPendente = payload;
    aoSelecionarLaudoConcluido?.call(payload);
    _controladorLaudosSelecionados.add(payload);
  }

  /// Inicializa os canais de notificação no Android e registra o handler de clique.
  Future<void> inicializar() async {
    if (_inicializado) return;
    try {
      const configAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const configIOS = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const configuracoes = InitializationSettings(
        android: configAndroid,
        iOS: configIOS,
      );

      await _plugin.initialize(
        settings: configuracoes,
        onDidReceiveNotificationResponse: _aoReceberToqueNotificacao,
      );

      final implAndroid = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (implAndroid != null) {
        await implAndroid.createNotificationChannel(
          const AndroidNotificationChannel(
            _idCanalProgresso,
            _nomeCanalProgresso,
            description: _descricaoCanalProgresso,
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
            showBadge: false,
          ),
        );
        await implAndroid.createNotificationChannel(
          const AndroidNotificationChannel(
            _idCanalConclusao,
            _nomeCanalConclusao,
            description: _descricaoCanalConclusao,
            importance: Importance.defaultImportance,
          ),
        );
      }
      _inicializado = true;
    } catch (_) {
      // Ambiente sem suporte nativo a notificações
    }
  }

  Future<void> _garantirPermissaoSolicitada() async {
    if (_permissaoSolicitada) return;
    _permissaoSolicitada = true;
    try {
      await inicializar();
      final implAndroid = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await implAndroid?.requestNotificationsPermission();

      final implIOS = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await implIOS?.requestPermissions(
        alert: true,
        badge: true,
        sound: false,
      );
    } catch (_) {}
  }

  int _idNotificacaoParaSessao(String idSessao) =>
      (idSessao.hashCode & 0x7fffffff) % 100000 + 2000;

  Future<void> _pararServicoPrimeiroPlanoSeAtivo() async {
    if (!_servicoPrimeiroPlanoAtivo) return;
    _servicoPrimeiroPlanoAtivo = false;
    try {
      final implAndroid = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await implAndroid?.stopForegroundService();
    } catch (_) {}
  }

  /// Exibe ou atualiza a notificação *sticky* (`ongoing: true`) com barra de progresso.
  Future<void> exibirProgresso({
    required String idSessao,
    required String tituloLaudo,
    required String etapaDescricao,
    required double progresso,
  }) async {
    try {
      await _garantirPermissaoSolicitada();
      final id = _idNotificacaoParaSessao(idSessao);
      final percentual = (progresso * 100).round().clamp(0, 100);
      final corpo = '$etapaDescricao ($percentual%)';

      final detalhesAndroid = AndroidNotificationDetails(
        _idCanalProgresso,
        _nomeCanalProgresso,
        channelDescription: _descricaoCanalProgresso,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showProgress: true,
        maxProgress: 100,
        progress: percentual,
        playSound: false,
        enableVibration: false,
        category: AndroidNotificationCategory.progress,
      );

      final implAndroid = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      var exibiuEmPrimeiroPlano = false;
      if (implAndroid != null) {
        try {
          await implAndroid.startForegroundService(
            id: id,
            title: tituloLaudo,
            body: corpo,
            payload: idSessao,
            notificationDetails: detalhesAndroid,
            foregroundServiceTypes: {
              AndroidServiceForegroundType.foregroundServiceTypeDataSync,
            },
          );
          _servicoPrimeiroPlanoAtivo = true;
          exibiuEmPrimeiroPlano = true;
        } catch (_) {
          exibiuEmPrimeiroPlano = false;
        }
      }

      if (!exibiuEmPrimeiroPlano) {
        const detalhesIOS = DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        );
        await _plugin.show(
          id: id,
          title: tituloLaudo,
          body: corpo,
          payload: idSessao,
          notificationDetails: NotificationDetails(
            android: detalhesAndroid,
            iOS: detalhesIOS,
          ),
        );
      }
    } catch (_) {}
  }

  /// Substitui a notificação *sticky* por uma notificação de conclusão clicável
  /// (`ongoing: false`, `autoCancel: true`) com `payload: idSessao`.
  Future<void> exibirConcluido({
    required String idSessao,
    required String tituloLaudo,
  }) async {
    try {
      await inicializar();
      await _pararServicoPrimeiroPlanoSeAtivo();
      final id = _idNotificacaoParaSessao(idSessao);

      const detalhesAndroid = AndroidNotificationDetails(
        _idCanalConclusao,
        _nomeCanalConclusao,
        channelDescription: _descricaoCanalConclusao,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ongoing: false,
        autoCancel: true,
      );
      const detalhesIOS = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );

      await _plugin.show(
        id: id,
        title: tituloLaudo,
        body:
            'Verificação concluída! Toque para abrir o laudo e compartilhar o link.',
        payload: idSessao,
        notificationDetails: const NotificationDetails(
          android: detalhesAndroid,
          iOS: detalhesIOS,
        ),
      );
    } catch (_) {}
  }

  /// Substitui a notificação *sticky* por um aviso de falha dispensável (`ongoing: false`).
  Future<void> exibirFalha({
    required String idSessao,
    required String tituloLaudo,
    required String motivo,
  }) async {
    try {
      await inicializar();
      await _pararServicoPrimeiroPlanoSeAtivo();
      final id = _idNotificacaoParaSessao(idSessao);

      const detalhesAndroid = AndroidNotificationDetails(
        _idCanalConclusao,
        _nomeCanalConclusao,
        channelDescription: _descricaoCanalConclusao,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ongoing: false,
        autoCancel: true,
      );
      const detalhesIOS = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      );

      await _plugin.show(
        id: id,
        title: tituloLaudo,
        body: motivo,
        payload: idSessao,
        notificationDetails: const NotificationDetails(
          android: detalhesAndroid,
          iOS: detalhesIOS,
        ),
      );
    } catch (_) {}
  }

  /// Remove a notificação associada a [idSessao] e encerra o Foreground Service se ativo.
  Future<void> cancelar(String idSessao) async {
    try {
      await inicializar();
      await _pararServicoPrimeiroPlanoSeAtivo();
      await _plugin.cancel(id: _idNotificacaoParaSessao(idSessao));
    } catch (_) {}
  }
}
