// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../tool/release_tools/servidor_smoke_ci.dart';

void main() {
  group('ServidorSmokeCi', () {
    ServidorSmokeCi? servidor;

    tearDown(() async {
      await servidor?.encerrar();
      servidor = null;
    });

    Future<({int status, Map<String, dynamic> json})> enviarJson(
      Uri uri, {
      String metodo = 'POST',
      Map<String, dynamic>? corpo,
    }) async {
      final client = HttpClient();
      try {
        final req = await client.openUrl(metodo, uri);
        req.headers.contentType = ContentType.json;
        if (corpo != null) {
          req.add(utf8.encode(jsonEncode(corpo)));
        }
        final res = await req.close();
        final texto = await utf8.decoder.bind(res).join();
        final decodificado = texto.isEmpty
            ? <String, dynamic>{}
            : (jsonDecode(texto) is Map<String, dynamic>
                  ? jsonDecode(texto) as Map<String, dynamic>
                  : <String, dynamic>{'lista': jsonDecode(texto)});
        return (status: res.statusCode, json: decodificado);
      } finally {
        client.close(force: true);
      }
    }

    test('deve emitir id_token OIDC com nonceHash e validar SHA-256(rawNonce) na troca GoTrue', () async {
      servidor = await ServidorSmokeCi.iniciar(tokenEsperado: 'tok-abc');
      const rawNonce = 'fingerprint_ecdsa_teste_12345';
      final nonceHash = sha256.convert(utf8.encode(rawNonce)).toString();

      final oidcResp = await enviarJson(
        servidor!.uriLocalHost.replace(path: '/__smoke__/oidc-token'),
        corpo: <String, dynamic>{
          'nonceHash': nonceHash,
          'provedor': 'google',
        },
      );

      expect(oidcResp.status, equals(200));
      final idToken = oidcResp.json['idToken'] as String;
      expect(idToken.split('.'), hasLength(3));

      final gotrueOk = await enviarJson(
        servidor!.uriLocalHost.replace(
          path: '/auth/v1/token',
          queryParameters: <String, String>{'grant_type': 'id_token'},
        ),
        corpo: <String, dynamic>{
          'provider': 'google',
          'id_token': idToken,
          'nonce': rawNonce,
        },
      );

      expect(gotrueOk.status, equals(200));
      expect(gotrueOk.json['access_token'], isNotEmpty);
      expect((gotrueOk.json['user'] as Map<String, dynamic>)['id'], isNotEmpty);
    });

    test('deve rejeitar troca GoTrue com HTTP 401 quando rawNonce não corresponder ao id_token', () async {
      servidor = await ServidorSmokeCi.iniciar(tokenEsperado: 'tok-abc');
      final nonceHash = sha256.convert(utf8.encode('nonce_correto')).toString();

      final oidcResp = await enviarJson(
        servidor!.uriLocalHost.replace(path: '/__smoke__/oidc-token'),
        corpo: <String, dynamic>{'nonceHash': nonceHash},
      );

      final gotrueErro = await enviarJson(
        servidor!.uriLocalHost.replace(
          path: '/auth/v1/token',
          queryParameters: <String, String>{'grant_type': 'id_token'},
        ),
        corpo: <String, dynamic>{
          'provider': 'google',
          'id_token': oidcResp.json['idToken'],
          'nonce': 'nonce_adulterado',
        },
      );

      expect(gotrueErro.status, equals(401));
    });

    test('deve responder rotas auxiliares de perfil Supabase (/rest/v1/perfis e /auth/v1/user)', () async {
      servidor = await ServidorSmokeCi.iniciar(tokenEsperado: 'tok-abc');

      final getPerfis = await enviarJson(
        servidor!.uriLocalHost.replace(
          path: '/rest/v1/perfis',
          queryParameters: <String, String>{'user_id': 'eq.usr_smoke_ci'},
        ),
        metodo: 'GET',
      );
      expect(getPerfis.status, equals(200));
      expect(getPerfis.json['lista'], isA<List<dynamic>>());

      final putUser = await enviarJson(
        servidor!.uriLocalHost.replace(path: '/auth/v1/user'),
        metodo: 'PUT',
        corpo: <String, dynamic>{
          'data': <String, dynamic>{'nome_completo_fixalog': 'Teste'},
        },
      );
      expect(putUser.status, equals(200));

      final patchPerfil = await enviarJson(
        servidor!.uriLocalHost.replace(path: '/rest/v1/perfis'),
        metodo: 'PATCH',
        corpo: <String, dynamic>{'autor_nome_publico': 'Teste'},
      );
      expect(patchPerfil.status, equals(200));
    });

    test('deve registrar relatório final apenas com token válido e resolver aguardarRelatorio', () async {
      servidor = await ServidorSmokeCi.iniciar(tokenEsperado: 'segredo-ci-77');

      final invalido = await enviarJson(
        servidor!.uriLocalHost.replace(path: '/__smoke__/relatorio'),
        corpo: <String, dynamic>{
          'token': 'token-errado',
          'sucesso': true,
        },
      );
      expect(invalido.status, equals(403));

      final futuroRelatorio = servidor!.aguardarRelatorio(
        timeout: const Duration(seconds: 5),
      );

      final valido = await enviarJson(
        servidor!.uriLocalHost.replace(path: '/__smoke__/relatorio'),
        corpo: <String, dynamic>{
          'token': 'segredo-ci-77',
          'sucesso': true,
          'etapas': <String>['termos_legais', 'identidade_oidc_ecdsa'],
          'erros': <String>[],
          'metricas': <String, dynamic>{'epubBytes': 4096},
        },
      );
      expect(valido.status, equals(200));

      final recebido = await futuroRelatorio;
      expect(recebido['sucesso'], isTrue);
      expect(recebido['etapas'], contains('identidade_oidc_ecdsa'));
    });
  });
}
