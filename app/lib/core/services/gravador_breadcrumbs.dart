// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Serviço responsável por manter um buffer circular FIFO em memória com as últimas
/// ações e eventos de telemetria disparados pelo auditor no aplicativo.
///
/// Este histórico (breadcrumbs) é anexado automaticamente aos metadados dos relatos
/// de feedback offline no `ServicoFilaFeedback` para diagnóstico e reprodução de falhas.
class GravadorBreadcrumbs {
  /// Capacidade padrão de retenção em memória (últimas 50 ações).
  static const int capacidadePadrao = 50;

  /// Limite máximo de entradas retidas no buffer circular.
  final int capacidadeMaxima;

  final ListQueue<Map<String, Object?>> _breadcrumbs =
      ListQueue<Map<String, Object?>>();

  /// Cria uma instância de [GravadorBreadcrumbs] com [capacidadeMaxima] configurável.
  GravadorBreadcrumbs({this.capacidadeMaxima = capacidadePadrao});

  /// Instância global padrão utilizada pelo aplicativo.
  static GravadorBreadcrumbs instancia = GravadorBreadcrumbs();

  /// Restaura a instância global padrão para isolamento entre testes.
  @visibleForTesting
  static void resetarParaTestes() {
    instancia = GravadorBreadcrumbs();
  }

  /// Quantidade total de eventos atualmente retidos no buffer.
  int get total => _breadcrumbs.length;

  /// Registra um novo [evento] no buffer circular com [parametros] e [timestamp] UTC.
  ///
  /// Quando o buffer atinge [capacidadeMaxima], o registro mais antigo é removido (FIFO).
  void registrar({
    required String evento,
    Map<String, Object?>? parametros,
    DateTime? timestamp,
  }) {
    final momento = (timestamp ?? DateTime.now()).toUtc();
    final entrada = <String, Object?>{
      'timestamp': momento.toIso8601String(),
      'evento': evento,
      'parametros': parametros != null
          ? Map<String, Object?>.unmodifiable(parametros)
          : const <String, Object?>{},
    };

    if (_breadcrumbs.length >= capacidadeMaxima) {
      _breadcrumbs.removeFirst();
    }
    _breadcrumbs.addLast(Map<String, Object?>.unmodifiable(entrada));
  }

  /// Retorna uma lista imutável com todos os eventos retidos em ordem cronológica.
  List<Map<String, Object?>> obterBreadcrumbs() {
    return List<Map<String, Object?>>.unmodifiable(_breadcrumbs);
  }

  /// Remove todos os registros acumulados no buffer.
  void limpar() {
    _breadcrumbs.clear();
  }
}
