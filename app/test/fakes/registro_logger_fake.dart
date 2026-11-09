// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:fixalog/core/services/registro_logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Representa um evento de erro ou crash capturado em memória pelo [RegistroLoggerFake].
class EventoErroRegistrado {
  final String mensagemContexto;
  final Object? erro;
  final StackTrace stackTrace;
  final bool fatal;
  final Map<String, Map<String, Object?>>? contextosExtras;

  const EventoErroRegistrado({
    required this.mensagemContexto,
    required this.erro,
    required this.stackTrace,
    required this.fatal,
    this.contextosExtras,
  });
}

/// Implementação Fake determinística em memória de [RegistroLogger] para testes
/// de integração e fronteira sem invocação de canais nativos do Firebase ou Sentry.
class RegistroLoggerFake extends RegistroLogger {
  /// Mensagens informativas registradas via [logInfo].
  final List<String> infosRegistrados = [];

  /// Mensagens de aviso registradas via [logAviso] (ou rebaixadas por [logFalhaSyncOuDownload]).
  final List<String> avisosRegistrados = [];

  /// Todos os eventos de erro registrados via [logError] e [logCrash].
  final List<EventoErroRegistrado> errosRegistrados = [];

  /// Breadcrumbs estruturados enviados ao pipeline do Sentry.
  final List<Breadcrumb> breadcrumbsSentry = [];

  /// Filtra apenas os eventos marcados como fatais (`fatal == true`).
  List<EventoErroRegistrado> get crashesRegistrados =>
      errosRegistrados.where((e) => e.fatal).toList(growable: false);

  RegistroLoggerFake({super.emModoDesenvolvimento = false})
      : super(
          impressorConsole: (_) {},
        );

  @override
  void logInfo(String mensagem) {
    infosRegistrados.add(mensagem);
    breadcrumbsSentry.add(
      Breadcrumb(
        message: mensagem,
        level: SentryLevel.info,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  void logAviso(String mensagem) {
    avisosRegistrados.add(mensagem);
    breadcrumbsSentry.add(
      Breadcrumb(
        message: '⚠️ AVISO: $mensagem',
        level: SentryLevel.warning,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  void logError(
    String mensagemContexto, {
    Object? error,
    required StackTrace stackTrace,
    bool fatal = false,
    Map<String, Map<String, Object?>>? contextosExtras,
  }) {
    final excecaoEfetiva = error ?? Exception(mensagemContexto);
    aoRegistrarErroOuCrash?.call(
      excecaoEfetiva,
      stackTrace,
      mensagemContexto,
      fatal: fatal,
    );
    errosRegistrados.add(
      EventoErroRegistrado(
        mensagemContexto: mensagemContexto,
        erro: error,
        stackTrace: stackTrace,
        fatal: fatal,
        contextosExtras: contextosExtras,
      ),
    );
  }

  /// Limpa todos os registros acumulados em memória.
  void limpar() {
    infosRegistrados.clear();
    avisosRegistrados.clear();
    errosRegistrados.clear();
    breadcrumbsSentry.clear();
  }
}
