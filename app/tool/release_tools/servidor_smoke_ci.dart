// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Micro-servidor HTTP local vinculado exclusivamente ao loopback (`127.0.0.1`)
/// para orquestrar autenticação OIDC/GoTrue e coleta de evidências do Smoke Test no CI.
class ServidorSmokeCi {
  final HttpServer _servidor;

  /// Token efêmero exigido para aceitar o relatório final em `/__smoke__/relatorio`.
  final String tokenEsperado;

  final Completer<Map<String, dynamic>> _completerRelatorio =
      Completer<Map<String, dynamic>>();

  String _nomePerfilAtual = 'Mantenedor Smoke CI';
  String _clubePerfilAtual = 'Aresta Climb';

  ServidorSmokeCi._(this._servidor, this.tokenEsperado);

  /// Porta TCP efêmera alocada em `127.0.0.1`.
  int get porta => _servidor.port;

  /// URI base acessível no próprio host ou iOS Simulator (`http://127.0.0.1:<porta>`).
  Uri get uriLocalHost => Uri.parse('http://127.0.0.1:$porta');

  /// URI base acessível a partir do Android Emulator (`http://10.0.2.2:<porta>`).
  Uri get uriEmuladorAndroid => Uri.parse('http://10.0.2.2:$porta');

  /// Inicia o servidor em `127.0.0.1` (porta `0` efêmera por padrão).
  static Future<ServidorSmokeCi> iniciar({
    required String tokenEsperado,
    int porta = 0,
  }) async {
    final httpServer = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      porta,
    );
    final instancia = ServidorSmokeCi._(httpServer, tokenEsperado.trim());
    httpServer.listen(instancia._tratarRequisicao);
    return instancia;
  }

  /// Aguarda a chegada do relatório estruturado enviado pelo aplicativo sob teste.
  Future<Map<String, dynamic>> aguardarRelatorio({
    Duration timeout = const Duration(seconds: 120),
  }) {
    return _completerRelatorio.future.timeout(timeout);
  }

  /// Encerra imediatamente o socket de escuta HTTP.
  Future<void> encerrar() async {
    await _servidor.close(force: true);
  }

  static String _codificarBase64UrlSemPadding(Map<String, dynamic> jsonMap) {
    return base64Url
        .encode(utf8.encode(jsonEncode(jsonMap)))
        .replaceAll('=', '');
  }

  Future<Map<String, dynamic>> _lerJsonCorpo(HttpRequest req) async {
    final texto = await utf8.decoder.bind(req).join();
    if (texto.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decodificado = jsonDecode(texto);
    if (decodificado is Map<String, dynamic>) {
      return decodificado;
    }
    return <String, dynamic>{};
  }

  Future<void> _responderJson(
    HttpResponse res,
    int statusCode,
    Object corpo,
  ) async {
    res.statusCode = statusCode;
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(corpo));
    await res.close();
  }

  Future<void> _tratarRequisicao(HttpRequest req) async {
    final caminho = req.uri.path;
    try {
      if (req.method == 'POST' && caminho == '/__smoke__/oidc-token') {
        final corpo = await _lerJsonCorpo(req);
        final rawNonce = (corpo['rawNonce'] as String?)?.trim() ?? '';
        var nonceHash = (corpo['nonceHash'] as String?)?.trim() ?? '';
        if (nonceHash.isEmpty && rawNonce.isNotEmpty) {
          nonceHash = sha256.convert(utf8.encode(rawNonce)).toString();
        }
        final agoraSeg = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final headerB64 = _codificarBase64UrlSemPadding(<String, dynamic>{
          'alg': 'HS256',
          'typ': 'JWT',
        });
        final payloadB64 = _codificarBase64UrlSemPadding(<String, dynamic>{
          'iss': 'https://accounts.google.com',
          'sub': 'google-smoke-uid-001',
          'aud': (corpo['webClientId'] as String?) ?? 'smoke-client-id',
          'email': 'smoke-ci@arestaclimb.com',
          'email_verified': true,
          'name': _nomePerfilAtual,
          'nonce': nonceHash,
          'iat': agoraSeg,
          'exp': agoraSeg + 3600,
        });
        final assinaturaB64 = base64Url
            .encode(sha256.convert(utf8.encode('$headerB64.$payloadB64')).bytes)
            .replaceAll('=', '');
        final jwt = '$headerB64.$payloadB64.$assinaturaB64';
        await _responderJson(req.response, 200, <String, dynamic>{
          'idToken': jwt,
          'email': 'smoke-ci@arestaclimb.com',
          'nomeExibicao': _nomePerfilAtual,
          'nomeCompleto': _nomePerfilAtual,
          'cancelado': false,
        });
        return;
      }

      if (req.method == 'POST' && caminho == '/auth/v1/token') {
        final corpo = await _lerJsonCorpo(req);
        final idToken = (corpo['id_token'] as String?)?.trim() ?? '';
        final rawNonce = (corpo['nonce'] as String?)?.trim() ?? '';
        final partes = idToken.split('.');
        if (partes.length != 3) {
          await _responderJson(req.response, 401, <String, dynamic>{
            'error_code': 'bad_jwt',
            'msg': 'Formato de id_token inválido.',
          });
          return;
        }
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
        ) as Map<String, dynamic>;
        final nonceClaim = (payload['nonce'] as String?) ?? '';
        final hashEsperado = sha256.convert(utf8.encode(rawNonce)).toString();
        if (nonceClaim.isEmpty ||
            (nonceClaim != rawNonce && nonceClaim != hashEsperado)) {
          await _responderJson(req.response, 401, <String, dynamic>{
            'error_code': 'bad_jwt',
            'msg': 'Vínculo criptográfico de nonce inválido.',
          });
          return;
        }

        await _responderJson(req.response, 200, <String, dynamic>{
          'access_token': 'jwt-supabase-smoke-sessao',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': <String, dynamic>{
            'id': 'usr_smoke_ci',
            'email': 'smoke-ci@arestaclimb.com',
            'user_metadata': <String, dynamic>{
              'nome_completo_fixalog': _nomePerfilAtual,
              'clube_associacao_fixalog': _clubePerfilAtual,
              'autor_nome_publico': _nomePerfilAtual,
              'full_name': _nomePerfilAtual,
            },
          },
        });
        return;
      }

      if (caminho == '/rest/v1/perfis') {
        if (req.method == 'GET') {
          await _responderJson(req.response, 200, <Map<String, dynamic>>[
            <String, dynamic>{
              'user_id': 'usr_smoke_ci',
              'autor_nome_publico': _nomePerfilAtual,
            },
          ]);
          return;
        }
        final corpo = await _lerJsonCorpo(req);
        final novoNome = (corpo['autor_nome_publico'] as String?)?.trim();
        if (novoNome != null && novoNome.isNotEmpty) {
          _nomePerfilAtual = novoNome;
        }
        await _responderJson(req.response, 200, <dynamic>[]);
        return;
      }

      if (caminho == '/auth/v1/user') {
        final corpo = await _lerJsonCorpo(req);
        final data = corpo['data'];
        if (data is Map<String, dynamic>) {
          final nome = (data['nome_completo_fixalog'] as String?)?.trim();
          final clube = (data['clube_associacao_fixalog'] as String?)?.trim();
          if (nome != null && nome.isNotEmpty) {
            _nomePerfilAtual = nome;
          }
          if (clube != null && clube.isNotEmpty) {
            _clubePerfilAtual = clube;
          }
        }
        await _responderJson(req.response, 200, <String, dynamic>{
          'id': 'usr_smoke_ci',
        });
        return;
      }

      if (req.method == 'POST' && caminho == '/__smoke__/relatorio') {
        final corpo = await _lerJsonCorpo(req);
        if (corpo['token'] != tokenEsperado) {
          await _responderJson(req.response, 403, <String, dynamic>{
            'erro': 'Token de smoke inválido.',
          });
          return;
        }
        if (!_completerRelatorio.isCompleted) {
          _completerRelatorio.complete(corpo);
        }
        await _responderJson(req.response, 200, <String, dynamic>{'ok': true});
        return;
      }

      await req.drain<void>();
      await _responderJson(req.response, 200, <String, dynamic>{'ok': true});
    } catch (e) {
      await _responderJson(req.response, 500, <String, dynamic>{
        'erro': e.toString(),
      });
    }
  }
}
