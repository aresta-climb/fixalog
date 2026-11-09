// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:fixalog/core/services/servico_app_check.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/registro_logger_fake.dart';

void main() {
  late RegistroLoggerFake loggerFake;

  setUp(() {
    ServicoAppCheck.resetarParaTestes();
    loggerFake = RegistroLoggerFake();
  });

  tearDown(() {
    ServicoAppCheck.resetarParaTestes();
  });

  group('ServicoAppCheck — Ativação e Obtenção de Token', () {
    test(
      'ativar seleciona PlayIntegrity e AppAttest em modo release oficial e DebugProvider em modo desenvolvimento',
      () async {
        AndroidAppCheckProvider? androidRecebido;
        AppleAppCheckProvider? appleRecebido;

        final servico = ServicoAppCheck(
          logger: loggerFake,
          ativarAppCheck: ({
            required providerAndroid,
            required providerApple,
          }) async {
            androidRecebido = providerAndroid;
            appleRecebido = providerApple;
          },
        );

        await servico.ativar(emModoRelease: true);
        expect(androidRecebido, isA<AndroidPlayIntegrityProvider>());
        expect(appleRecebido, isA<AppleAppAttestProvider>());
        expect(
          loggerFake.infosRegistrados.single,
          contains('Firebase App Check ativado com sucesso'),
        );

        await servico.ativar(emModoRelease: false);
        expect(androidRecebido, isA<AndroidDebugProvider>());
        expect(appleRecebido, isA<AppleDebugProvider>());
      },
    );

    test(
      'ativar registra erro no RegistroLogger caso ocorra falha inesperada sem derrubar o app',
      () async {
        final servico = ServicoAppCheck(
          logger: loggerFake,
          ativarAppCheck: ({
            required providerAndroid,
            required providerApple,
          }) async {
            throw StateError('Falha ao configurar provedor nativo');
          },
        );

        await expectLater(servico.ativar(), completes);
        expect(loggerFake.errosRegistrados, hasLength(1));
        expect(
          loggerFake.errosRegistrados.single.mensagemContexto,
          contains('Erro ao ativar Firebase App Check'),
        );
      },
    );

    test(
      'obterToken retorna JWT quando disponível e degrada para null com logAviso quando offline na montanha',
      () async {
        var offline = false;
        var forcouRefresh = false;

        final servico = ServicoAppCheck(
          logger: loggerFake,
          obterTokenAppCheck: (forcarAtualizacao) async {
            forcouRefresh = forcarAtualizacao;
            if (offline) {
              throw const SocketException('Failed host lookup: firebaseappcheck.googleapis.com');
            }
            return 'jwt_app_check_valido';
          },
        );

        final tokenOnline = await servico.obterToken(true);
        expect(tokenOnline, equals('jwt_app_check_valido'));
        expect(forcouRefresh, isTrue);
        expect(loggerFake.avisosRegistrados, isEmpty);
        expect(loggerFake.errosRegistrados, isEmpty);

        offline = true;
        final tokenOffline = await servico.obterToken();
        expect(tokenOffline, isNull);
        expect(loggerFake.errosRegistrados, isEmpty);
        expect(loggerFake.avisosRegistrados, hasLength(1));
        expect(
          loggerFake.avisosRegistrados.single,
          contains('Falha de conexão ao obter token do App Check'),
        );
      },
    );

    test(
      'obterToken registra logAviso em modo de desenvolvimento quando o UUID de debug não está cadastrado e logError apenas em modo release',
      () async {
        final servicoDevSemUuid = ServicoAppCheck(
          logger: loggerFake,
          emModoDesenvolvimento: true,
          obterTokenAppCheck: (_) async {
            throw Exception(
              '[firebase_app_check/unknown] Error returned from API. code: 403 body: App attestation failed.',
            );
          },
        );

        final tokenDev = await servicoDevSemUuid.obterToken();
        expect(tokenDev, isNull);
        expect(loggerFake.errosRegistrados, isEmpty);
        expect(loggerFake.avisosRegistrados, hasLength(1));
        expect(
          loggerFake.avisosRegistrados.single,
          contains('modo de desenvolvimento'),
        );

        final servicoReleaseComErro = ServicoAppCheck(
          logger: loggerFake,
          emModoDesenvolvimento: false,
          obterTokenAppCheck: (_) async {
            throw StateError('App Check bloqueado');
          },
        );

        final token = await servicoReleaseComErro.obterToken();
        expect(token, isNull);
        expect(loggerFake.errosRegistrados, hasLength(1));
        expect(
          loggerFake.errosRegistrados.single.mensagemContexto,
          contains('Não foi possível obter o token do App Check'),
        );

        // Exercita delegates padrão sem Firebase inicializado
        await expectLater(ServicoAppCheck.instancia.ativar(), completes);
        expect(await ServicoAppCheck.instancia.obterToken(), isNull);
      },
    );
  });
}
