// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:fixalog/core/services/registro_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  setUp(() {
    RegistroLogger.resetarParaTestes();
  });

  tearDown(() {
    RegistroLogger.resetarParaTestes();
  });

  group('RegistroLogger — Envio Dual de Logs e Exceções', () {
    test(
      'logInfo envia breadcrumb informativo para Sentry e log textual para Crashlytics',
      () {
        final logsCrashlytics = <String>[];
        final breadcrumbsSentry = <Breadcrumb>[];
        final saidasConsole = <String>[];

        final logger = RegistroLogger(
          emModoDesenvolvimento: true,
          impressorConsole: saidasConsole.add,
          enviarLogCrashlytics: logsCrashlytics.add,
          enviarBreadcrumbSentry: breadcrumbsSentry.add,
        );

        logger.logInfo('Iniciando perícia na via Paredão');

        expect(
          saidasConsole,
          contains(contains('Iniciando perícia na via Paredão')),
        );
        expect(logsCrashlytics, equals(['Iniciando perícia na via Paredão']));
        expect(breadcrumbsSentry, hasLength(1));
        expect(
          breadcrumbsSentry.single.message,
          equals('Iniciando perícia na via Paredão'),
        );
        expect(breadcrumbsSentry.single.level, equals(SentryLevel.info));
      },
    );

    test(
      'logAviso registra breadcrumb de nível warning no Sentry e Crashlytics sem abrir erro fatal',
      () {
        final logsCrashlytics = <String>[];
        final breadcrumbsSentry = <Breadcrumb>[];
        var errosCapturados = 0;

        final logger = RegistroLogger(
          emModoDesenvolvimento: false,
          enviarLogCrashlytics: logsCrashlytics.add,
          enviarBreadcrumbSentry: breadcrumbsSentry.add,
          enviarErroCrashlytics: (
            erro,
            stack, {
            required String motivo,
            required bool fatal,
          }) async {
            errosCapturados++;
          },
        );

        logger.logAviso('Sinal de GPS fraco na base da parede');

        expect(errosCapturados, equals(0));
        expect(
          logsCrashlytics.single,
          contains('AVISO: Sinal de GPS fraco na base da parede'),
        );
        expect(breadcrumbsSentry.single.level, equals(SentryLevel.warning));
      },
    );

    test(
      'logError e logCrash enviam exceção com StackTrace e contextos extras para Sentry e Crashlytics',
      () {
        final errosCrashlytics = <Map<String, Object?>>[];
        final errosSentry = <Map<String, Object?>>[];

        final logger = RegistroLogger(
          emModoDesenvolvimento: true,
          impressorConsole: (_) {},
          enviarErroCrashlytics: (
            erro,
            stack, {
            required String motivo,
            required bool fatal,
          }) async {
            errosCrashlytics.add({
              'erro': erro,
              'stack': stack,
              'motivo': motivo,
              'fatal': fatal,
            });
          },
          enviarExcecaoSentry: (
            erro, {
            required StackTrace stackTrace,
            required String motivo,
            required bool fatal,
            Map<String, Map<String, Object?>>? contextosExtras,
          }) async {
            errosSentry.add({
              'erro': erro,
              'stack': stackTrace,
              'motivo': motivo,
              'fatal': fatal,
              'contextos': contextosExtras,
            });
          },
        );

        final trilha = StackTrace.current;
        logger.logError(
          'Falha ao assinar XML-DSig',
          error: StateError('Chave inválida'),
          stackTrace: trilha,
        );

        logger.logCrash(
          'Crash crítico no Wizard',
          stackTrace: trilha,
          contextosExtras: {
            'receita_robo_caotico': {'seed': 42},
          },
        );

        expect(errosCrashlytics, hasLength(2));
        expect(errosCrashlytics[0]['motivo'], equals('Falha ao assinar XML-DSig'));
        expect(errosCrashlytics[0]['fatal'], isFalse);
        expect(errosCrashlytics[1]['motivo'], equals('Crash crítico no Wizard'));
        expect(errosCrashlytics[1]['fatal'], isTrue);

        expect(errosSentry, hasLength(2));
        expect(errosSentry[0]['fatal'], isFalse);
        expect(errosSentry[1]['fatal'], isTrue);
        expect(
          errosSentry[1]['contextos'],
          equals({
            'receita_robo_caotico': {'seed': 42},
          }),
        );
      },
    );

    test(
      'aoRegistrarErroOuCrash é notificado sincronamente tanto em logError quanto em logCrash',
      () {
        final notificacoes = <Map<String, Object?>>[];
        final logger = RegistroLogger(
          emModoDesenvolvimento: false,
          impressorConsole: (_) {},
          enviarErroCrashlytics: (
            erro,
            stack, {
            required String motivo,
            required bool fatal,
          }) async {},
          enviarExcecaoSentry: (
            erro, {
            required StackTrace stackTrace,
            required String motivo,
            required bool fatal,
            Map<String, Map<String, Object?>>? contextosExtras,
          }) async {},
        );
        logger.aoRegistrarErroOuCrash = (
          erro,
          stackTrace,
          mensagem, {
          required fatal,
        }) {
          notificacoes.add({
            'erro': erro,
            'stack': stackTrace,
            'mensagem': mensagem,
            'fatal': fatal,
          });
        };

        final trilha = StackTrace.current;
        logger.logError(
          'Erro tratado em try/catch',
          error: const FormatException('JSON inválido'),
          stackTrace: trilha,
        );
        logger.logCrash(
          'Crash crítico',
          stackTrace: trilha,
        );

        expect(notificacoes, hasLength(2));
        expect(notificacoes[0]['erro'], isA<FormatException>());
        expect(notificacoes[0]['mensagem'], equals('Erro tratado em try/catch'));
        expect(notificacoes[0]['fatal'], isFalse);
        expect(notificacoes[1]['mensagem'], equals('Crash crítico'));
        expect(notificacoes[1]['fatal'], isTrue);
      },
    );

    test(
      'configurarEscopoSentry preenche nível e contextos estruturados no Scope do Sentry',
      () {
        final escopoErro = Scope(SentryOptions(dsn: ''));
        RegistroLogger.configurarEscopoSentry(
          escopoErro,
          'Erro operacional',
          fatal: false,
          contextosExtras: {
            'protocolo': {'id': 'bolt_maintenance'},
          },
        );
        expect(escopoErro.level, equals(SentryLevel.error));
        expect(escopoErro.contexts['contexto_erro'], isNotNull);
        expect(escopoErro.contexts['protocolo'], isNotNull);

        final escopoFatal = Scope(SentryOptions(dsn: ''));
        RegistroLogger.configurarEscopoSentry(
          escopoFatal,
          'Falha fatal',
          fatal: true,
        );
        expect(escopoFatal.level, equals(SentryLevel.fatal));
      },
    );

    test(
      'opera com resiliência sem lançar exceção quando delegates padrão ou customizados (síncronos e assíncronos) falham',
      () async {
        final saidas = <String>[];
        expect(RegistroLogger.firebaseInicializado, isFalse);

        // 1. Instância padrão com Sentry inicializado em memória e sem Firebase
        await Sentry.init((options) {
          options.dsn = 'https://chave@o1.ingest.sentry.io/1';
        });
        addTearDown(Sentry.close);
        RegistroLogger.instancia.logInfo('Teste padrão info');
        RegistroLogger.instancia.logAviso('Teste padrão aviso');
        RegistroLogger.instancia.logError(
          'Teste padrão erro',
          stackTrace: StackTrace.current,
        );

        // 2. Delegates que lançam exceção síncrona ou retornam Future com erro não derrubam a aplicação
        final loggerComFalha = RegistroLogger(
          emModoDesenvolvimento: true,
          impressorConsole: saidas.add,
          enviarLogCrashlytics: (_) => throw StateError('Crashlytics indisponível'),
          enviarBreadcrumbSentry: (_) => throw StateError('Sentry indisponível'),
          enviarErroCrashlytics: (
            erro,
            stack, {
            required String motivo,
            required bool fatal,
          }) => Future<void>.error(StateError('Falha async Crashlytics')),
          enviarExcecaoSentry: (
            erro, {
            required StackTrace stackTrace,
            required String motivo,
            required bool fatal,
            Map<String, Map<String, Object?>>? contextosExtras,
          }) => throw StateError('Falha sync Sentry'),
        );

        expect(() => loggerComFalha.logInfo('Mensagem'), returnsNormally);
        expect(() => loggerComFalha.logAviso('Aviso'), returnsNormally);
        expect(
          () => loggerComFalha.logError(
            'Erro',
            stackTrace: StackTrace.current,
          ),
          returnsNormally,
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          saidas,
          contains(contains('Falha async Crashlytics')),
        );
      },
    );
  });

  group('RegistroLogger — Filtro de Desconexão em Montanha', () {
    test(
      'isFalhaConexaoOuTimeout identifica exceções de rede, timeouts, códigos HTTP transitórios e erros Firebase offline',
      () {
        expect(RegistroLogger.isFalhaConexaoOuTimeout(null), isFalse);
        expect(RegistroLogger.isFalhaConexaoOuTimeout(502), isTrue);
        expect(RegistroLogger.isFalhaConexaoOuTimeout(503), isTrue);
        expect(RegistroLogger.isFalhaConexaoOuTimeout(504), isTrue);
        expect(RegistroLogger.isFalhaConexaoOuTimeout(429), isTrue);
        expect(RegistroLogger.isFalhaConexaoOuTimeout(500), isFalse);

        expect(
          RegistroLogger.isFalhaConexaoOuTimeout(
            TimeoutException('Tempo esgotado'),
          ),
          isTrue,
        );
        expect(
          RegistroLogger.isFalhaConexaoOuTimeout(
            const SocketException('Failed host lookup: fixalog.app'),
          ),
          isTrue,
        );
        expect(
          RegistroLogger.isFalhaConexaoOuTimeout(
            const HttpException('Connection closed before full header'),
          ),
          isTrue,
        );
        expect(
          RegistroLogger.isFalhaConexaoOuTimeout(
            const HandshakeException('Connection terminated during handshake'),
          ),
          isTrue,
        );
        expect(
          RegistroLogger.isFalhaConexaoOuTimeout(
            FirebaseException(
              plugin: 'firebase_remote_config',
              code: 'unavailable',
              message: 'Unable to connect to the server',
            ),
          ),
          isTrue,
        );
        expect(
          RegistroLogger.isFalhaConexaoOuTimeout(
            FirebaseException(
              plugin: 'firebase_auth',
              code: 'invalid-credential',
              message: 'Token expirado',
            ),
          ),
          isFalse,
        );
        expect(
          RegistroLogger.isFalhaConexaoOuTimeout(
            Exception('HTTP 503 Service Unavailable'),
          ),
          isTrue,
        );
        expect(
          RegistroLogger.isFalhaConexaoOuTimeout(
            Exception('Firebase Installations failed to get installation auth token'),
          ),
          isTrue,
        );
        expect(
          RegistroLogger.isFalhaConexaoOuTimeout(
            Exception('ClientException with SocketException: Sem conexão'),
          ),
          isTrue,
        );
        expect(
          RegistroLogger.isFalhaConexaoOuTimeout(
            FormatException('YAML malformado no protocolo'),
          ),
          isFalse,
        );
      },
    );

    test(
      'logFalhaSyncOuDownload rebaixa falhas de conexão para logAviso e eleva erros de integridade para logCrash',
      () {
        final avisos = <String>[];
        final crashes = <String>[];

        final logger = RegistroLogger(
          emModoDesenvolvimento: false,
          enviarLogCrashlytics: avisos.add,
          enviarBreadcrumbSentry: (_) {},
          enviarErroCrashlytics: (
            erro,
            stack, {
            required String motivo,
            required bool fatal,
          }) async {
            if (fatal) crashes.add(motivo);
          },
          enviarExcecaoSentry: (
            erro, {
            required StackTrace stackTrace,
            required String motivo,
            required bool fatal,
            Map<String, Map<String, Object?>>? contextosExtras,
          }) async {},
        );

        logger.logFalhaSyncOuDownload(
          'Falha ao sincronizar EPUB com fixalog.app',
          error: const SocketException('Network is unreachable'),
          stackTrace: StackTrace.current,
        );

        expect(crashes, isEmpty);
        expect(
          avisos.single,
          contains('Falha ao sincronizar EPUB com fixalog.app'),
        );

        logger.logFalhaSyncOuDownload(
          'Pacote EPUB rejeitado por assinatura inválida (HTTP 400)',
          error: StateError('Assinatura XML-DSig corrompida'),
          stackTrace: StackTrace.current,
        );

        expect(
          crashes,
          equals(['Pacote EPUB rejeitado por assinatura inválida (HTTP 400)']),
        );
      },
    );
  });
}
