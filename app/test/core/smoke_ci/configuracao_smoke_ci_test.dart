// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/smoke_ci/configuracao_smoke_ci.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canalTeste = MethodChannel('com.arestaclimb.fixalog/smoke_ci_teste');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalTeste, null);
  });

  group('ConfiguracaoSmokeCi', () {
    test('deve aceitar endereços de loopback válidos (127.0.0.1, localhost e 10.0.2.2) e montar rotas', () {
      for (final url in [
        'http://127.0.0.1:41234/',
        'http://localhost:8080',
        'http://10.0.2.2:55111',
      ]) {
        final config = ConfiguracaoSmokeCi.validar(
          servidorUrl: url,
          token: 'tok-efemero-123',
        );

        expect(config.token, equals('tok-efemero-123'));
        expect(
          config.construirUriRelatorio().path,
          equals('/__smoke__/relatorio'),
        );
        expect(
          config.construirUriOidcToken().path,
          equals('/__smoke__/oidc-token'),
        );
      }
    });

    test('deve rejeitar com FormatException qualquer host fora de loopback ou porta ausente', () {
      for (final invalida in [
        '',
        'nao-e-uri',
        'https://malicioso.exemplo.com:8080',
        'http://192.168.0.15:8080',
        'ftp://127.0.0.1:8080',
        'http://127.0.0.1',
      ]) {
        expect(
          () => ConfiguracaoSmokeCi.validar(
            servidorUrl: invalida,
            token: 'tok-123',
          ),
          throwsFormatException,
          reason: 'Deveria rejeitar URL inválida ou não-loopback: $invalida',
        );
      }
    });

    test('deve rejeitar com FormatException quando o token efêmero estiver vazio', () {
      expect(
        () => ConfiguracaoSmokeCi.validar(
          servidorUrl: 'http://127.0.0.1:9000',
          token: '   ',
        ),
        throwsFormatException,
      );
    });

    test('deve carregar configuração válida a partir do MethodChannel nativo', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canalTeste, (call) async {
        expect(call.method, equals('obterConfiguracaoSmoke'));
        return <String, dynamic>{
          'ativo': true,
          'servidorUrl': 'http://10.0.2.2:49152',
          'token': 'token-ci-999',
        };
      });

      final config = await ConfiguracaoSmokeCi.exigirDoCanalNativo(
        canal: canalTeste,
      );

      expect(config.uriBase.toString(), equals('http://10.0.2.2:49152'));
      expect(config.token, equals('token-ci-999'));
    });

    test('deve lançar StateError quando canal nativo indicar smoke inativo ou ausente', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canalTeste, (_) async {
        return <String, dynamic>{'ativo': false};
      });

      await expectLater(
        ConfiguracaoSmokeCi.exigirDoCanalNativo(canal: canalTeste),
        throwsStateError,
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canalTeste, null);

      await expectLater(
        ConfiguracaoSmokeCi.exigirDoCanalNativo(canal: canalTeste),
        throwsStateError,
      );
    });
  });
}
