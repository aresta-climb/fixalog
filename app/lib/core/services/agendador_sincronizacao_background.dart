// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/feedback/services/servico_fila_feedback.dart';
import 'banco_dados_local.dart';
import 'sincronizador_nuvem_service.dart';

/// Agendador periódico e reativo ao ciclo de vida do aplicativo para processamento
/// em segundo plano das filas locais pendentes de laudos ([SincronizadorNuvemService])
/// e de feedbacks ([ServicoFilaFeedback]).
///
/// Preserva bateria verificando em `0ms` a existência de interfaces de rede não-loopback
/// (`NetworkInterface.list(includeLoopback: false)`) para abortar instantaneamente em Modo Avião,
/// e desliga o temporizador assim que não houver itens pendentes no SQLite.
class AgendadorSincronizacaoBackground {
  static const List<Duration> intervalosBackoffPadrao = [
    Duration(seconds: 30),
    Duration(seconds: 60),
    Duration(seconds: 120),
  ];

  final BancoDadosLocal? _banco;
  final SincronizadorNuvemService _sincronizadorNuvem;
  final ServicoFilaFeedback _servicoFilaFeedback;
  final Future<bool> Function() _verificadorRedeAtiva;
  final List<Duration> _intervalosBackoff;

  Timer? _timer;
  bool _executando = false;
  int _indiceBackoff = 0;

  AgendadorSincronizacaoBackground({
    required BancoDadosLocal? banco,
    required SincronizadorNuvemService sincronizadorNuvem,
    required ServicoFilaFeedback servicoFilaFeedback,
    Future<bool> Function()? verificadorRedeAtiva,
    List<Duration> intervalosBackoff = intervalosBackoffPadrao,
  })  : _banco = banco,
        _sincronizadorNuvem = sincronizadorNuvem,
        _servicoFilaFeedback = servicoFilaFeedback,
        _verificadorRedeAtiva =
            verificadorRedeAtiva ?? verificarInterfaceRedeAtivaPadrao,
        _intervalosBackoff = intervalosBackoff;

  /// Verifica no sistema operacional se há ao menos uma interface de rede não-loopback ativa.
  /// Retorna `false` instantaneamente (`0ms`) quando o dispositivo está em Modo Avião.
  static Future<bool> verificarInterfaceRedeAtivaPadrao() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.any,
    );
    return interfaces.isNotEmpty;
  }

  /// Indica se o temporizador periódico de *retry* está ativo no momento.
  bool get timerAtivo => _timer?.isActive ?? false;

  /// Retorna o índice atual da progressão de *backoff*.
  int get indiceBackoffAtual => _indiceBackoff;

  /// Verifica no banco SQLite se existem laudos gerados ou feedbacks aguardando envio.
  Future<bool> possuiItensPendentes() async {
    final banco = _banco;
    if (banco == null) {
      return false;
    }
    final submissoes = await banco.listarSubmissoes();
    if (submissoes.any((s) => s.isGerado && !s.enviadoNuvem)) {
      return true;
    }
    final feedbacks = await banco.listarFeedbacksPendentes();
    return feedbacks.isNotEmpty;
  }

  /// Inicia o monitoramento (na abertura do app ou após selar um laudo).
  Future<bool> iniciarMonitoramento() {
    return executarCicloSeNecessario();
  }

  /// Acionado quando o aplicativo retorna ao primeiro plano (`AppLifecycleState.resumed`).
  Future<bool> aoRetomarAplicativo() {
    return executarCicloSeNecessario();
  }

  /// Executa um ciclo de sincronização caso existam itens pendentes e interface de rede ativa.
  Future<bool> executarCicloSeNecessario() async {
    if (_executando) {
      return false;
    }
    _executando = true;
    try {
      if (!await possuiItensPendentes()) {
        _indiceBackoff = 0;
        cancelarTimer();
        return false;
      }

      final temRede = await _verificadorRedeAtiva();
      if (!temRede) {
        _agendarProximaTentativaComBackoff();
        return false;
      }

      await _sincronizadorNuvem.sincronizarPendentes();
      await _servicoFilaFeedback.processarFilaPendentes();

      if (await possuiItensPendentes()) {
        _agendarProximaTentativaComBackoff();
        return true;
      }

      _indiceBackoff = 0;
      cancelarTimer();
      return true;
    } finally {
      _executando = false;
    }
  }

  void _agendarProximaTentativaComBackoff() {
    cancelarTimer();
    final duracao = _intervalosBackoff[_indiceBackoff];
    if (_indiceBackoff < _intervalosBackoff.length - 1) {
      _indiceBackoff++;
    }
    _timer = Timer(duracao, () {
      unawaited(executarCicloSeNecessario());
    });
  }

  /// Cancela o temporizador periódico ativo, se houver.
  void cancelarTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

final agendadorSincronizacaoBackgroundProvider =
    Provider<AgendadorSincronizacaoBackground>((ref) {
      final banco = ref.watch(bancoDadosLocalProvider);
      final sincronizador = ref.watch(sincronizadorNuvemServiceProvider);
      final feedback = ref.watch(servicoFilaFeedbackProvider);
      final agendador = AgendadorSincronizacaoBackground(
        banco: banco,
        sincronizadorNuvem: sincronizador,
        servicoFilaFeedback: feedback,
      );
      ref.onDispose(agendador.cancelarTimer);
      return agendador;
    });
