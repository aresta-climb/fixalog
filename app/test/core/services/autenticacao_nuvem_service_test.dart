// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'package:basic_utils/basic_utils.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/crypto_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  late CryptoService cryptoService;
  late FlutterSecureStorage secureStorage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    secureStorage = const FlutterSecureStorage();
    cryptoService = CryptoService(secureStorage: secureStorage);
  });

  group('AutenticacaoNuvemService — OpenPubkey OIDC e App Check', () {
    test('entrarComProvedorOidc gera chave ECDSA local, injeta rawNonce no id_token OIDC e persiste sessão e X.509', () async {
      final service = AutenticacaoNuvemService(
        cryptoService: cryptoService,
        secureStorage: secureStorage,
      );

      final sessaoGoogle = await service.entrarComProvedorOidc(
        ProvedorOidc.google,
      );
      expect(sessaoGoogle.provedor, equals(ProvedorOidc.google));
      expect(sessaoGoogle.email, equals('escalador@gmail.com'));
      expect(sessaoGoogle.fingerprintChavePublica.length, equals(64));
      expect(
        await cryptoService.obterAtestadoOidcJwt(),
        equals(sessaoGoogle.atestadoOidcJwt),
      );
      expect(
        AutenticacaoNuvemService.validarNonceNoIdToken(
          idTokenOidc: sessaoGoogle.atestadoOidcJwt,
          rawNonceEsperado: sessaoGoogle.fingerprintChavePublica,
        ),
        isTrue,
      );

      final sessaoSalva = await service.obterSessaoAtual();
      expect(sessaoSalva, isNotNull);
      expect(sessaoSalva!.userId, equals(sessaoGoogle.userId));
      expect(sessaoSalva.provedor, equals(ProvedorOidc.google));

      final sessaoApple = await service.vincularChaveLocalAoProvedorOidc(
        ProvedorOidc.apple,
      );
      expect(sessaoApple.provedor, equals(ProvedorOidc.apple));
      expect(
        sessaoApple.fingerprintChavePublica,
        equals(sessaoGoogle.fingerprintChavePublica),
      );
    });

    test('Rejeita id_token OIDC cujo nonce não corresponde à chave pública local', () async {
      final service = AutenticacaoNuvemService(
        cryptoService: cryptoService,
        secureStorage: secureStorage,
        autenticadorOidc: (provedor, rawNonce) async {
          final idTokenInvalido =
              AutenticacaoNuvemService.construirIdTokenOidcComNonce(
                provedor: provedor,
                sub: 'sub_1',
                email: 'a@b.com',
                nomeCompleto: 'Hacker',
                rawNonce: 'nonce_diferente_da_chave_local',
              );
          return CredencialOidcBruta(
            userId: 'u1',
            email: 'a@b.com',
            provedor: provedor,
            nomeCompleto: 'Hacker',
            jwtSupabase: 'jwt',
            idTokenOidc: idTokenInvalido,
          );
        },
      );

      await expectLater(
        service.entrarComProvedorOidc(ProvedorOidc.google),
        throwsA(isA<FormatException>()),
      );
    });

    test('validarNonceNoIdToken trata tokens malformados, sem nonce ou com rawNonce direto', () {
      expect(
        AutenticacaoNuvemService.validarNonceNoIdToken(
          idTokenOidc: 'token_invalido',
          rawNonceEsperado: 'abc',
        ),
        isFalse,
      );
      expect(
        AutenticacaoNuvemService.validarNonceNoIdToken(
          idTokenOidc: 'a.@@@.c',
          rawNonceEsperado: 'abc',
        ),
        isFalse,
      );
      final payloadLista = base64Url
          .encode(utf8.encode(jsonEncode([1, 2, 3])))
          .replaceAll('=', '');
      expect(
        AutenticacaoNuvemService.validarNonceNoIdToken(
          idTokenOidc: 'a.$payloadLista.c',
          rawNonceEsperado: 'abc',
        ),
        isFalse,
      );
      final payloadSemNonce = base64Url
          .encode(utf8.encode(jsonEncode({'sub': '123'})))
          .replaceAll('=', '');
      expect(
        AutenticacaoNuvemService.validarNonceNoIdToken(
          idTokenOidc: 'a.$payloadSemNonce.c',
          rawNonceEsperado: 'abc',
        ),
        isFalse,
      );
      final payloadNonceDireto = base64Url
          .encode(utf8.encode(jsonEncode({'nonce': 'meu_raw_nonce'})))
          .replaceAll('=', '');
      expect(
        AutenticacaoNuvemService.validarNonceNoIdToken(
          idTokenOidc: 'a.$payloadNonceDireto.c',
          rawNonceEsperado: 'meu_raw_nonce',
        ),
        isTrue,
      );
    });

    test('atualizarPerfilConta sincroniza Nome e Clube e re-emite X.509 sem alterar a chave ECDSA', () async {
      String? nomeSincronizado;
      String? clubeSincronizado;

      final service = AutenticacaoNuvemService(
        cryptoService: cryptoService,
        secureStorage: secureStorage,
        sincronizadorPerfilRemoto: (nome, clube) async {
          nomeSincronizado = nome;
          clubeSincronizado = clube;
        },
      );

      expect(
        await service.atualizarPerfilConta(
          nomeCompleto: 'Renato Sem Sessão',
          clubeAssociacao: 'FEMERJ',
        ),
        isNull,
      );
      expect(nomeSincronizado, equals('Renato Sem Sessão'));
      expect(clubeSincronizado, equals('FEMERJ'));

      final sessaoInicial = await service.entrarComProvedorOidc(
        ProvedorOidc.google,
      );
      final sessaoAtualizada = await service.atualizarPerfilConta(
        nomeCompleto: 'Renato Novo Nome',
        clubeAssociacao: 'AGUIA',
      );

      expect(sessaoAtualizada, isNotNull);
      expect(sessaoAtualizada!.nomeCompleto, equals('Renato Novo Nome'));
      expect(sessaoAtualizada.clubeAssociacao, equals('AGUIA'));
      expect(
        sessaoAtualizada.fingerprintChavePublica,
        equals(sessaoInicial.fingerprintChavePublica),
      );

      final certPem = await cryptoService.obterCertificadoX509Pem();
      final x509 = X509Utils.x509CertificateFromPem(certPem!);
      expect(
        x509.tbsCertificate?.subject['2.5.4.3'],
        equals('Renato Novo Nome'),
      );
      expect(x509.tbsCertificate?.subject['2.5.4.11'], equals('AGUIA'));
    });

    test('obterTokenAppCheck, encerrarSessao, JSON corrompido e provider Riverpod funcionam corretamente', () async {
      final service = AutenticacaoNuvemService(
        cryptoService: cryptoService,
        secureStorage: secureStorage,
      );

      expect(
        await service.obterTokenAppCheck(),
        equals('app_check_token_fixalog_padrao'),
      );

      await secureStorage.write(
        key: 'fixalog_sessao_nuvem_json',
        value: '{json_invalido',
      );
      expect(await service.obterSessaoAtual(), isNull);

      await service.entrarComProvedorOidc(ProvedorOidc.google);
      expect(await service.obterSessaoAtual(), isNotNull);
      await service.encerrarSessao();
      expect(await service.obterSessaoAtual(), isNull);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(autenticacaoNuvemServiceProvider),
        isA<AutenticacaoNuvemService>(),
      );
      expect(AutenticacaoNuvemService(), isA<AutenticacaoNuvemService>());
      expect(ProvedorOidc.deString('desconhecido'), equals(ProvedorOidc.google));
      const sessaoBase = SessaoUsuarioNuvem(
        userId: 'u',
        email: 'e',
        provedor: ProvedorOidc.google,
        nomeCompleto: 'N',
        clubeAssociacao: 'C',
        jwtSupabase: 'j',
        atestadoOidcJwt: 'a',
        fingerprintChavePublica: 'f',
      );
      expect(sessaoBase.copiarCom().nomeCompleto, equals('N'));
    });

    test('canalAutenticacaoNativa e trocarIdTokenNoSupabase realizam handshake HTTP com Supabase GoTrue', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        AutenticacaoNuvemService.urlSupabaseAtiva =
            AutenticacaoNuvemService.urlSupabasePadrao;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              AutenticacaoNuvemService.canalAutenticacaoNativa,
              null,
            );
        await server.close(force: true);
      });

      int statusResposta = 200;
      Map<String, dynamic> ultimoCorpoRecebido = {};
      Map<String, dynamic> ultimoUserUpdate = {};
      Map<String, dynamic>? ultimoPerfilPatch;

      server.listen((HttpRequest req) async {
        final caminho = req.uri.path;
        final texto = await utf8.decoder.bind(req).join();
        req.response.headers.contentType = ContentType.json;

        if (caminho.endsWith('/rest/v1/perfis') && req.method == 'GET') {
          req.response.statusCode = 200;
          req.response.write(
            jsonEncode([
              {'autor_nome_publico': 'Renato Perfil Aresta'},
            ]),
          );
          await req.response.close();
          return;
        }

        if (caminho.endsWith('/auth/v1/user') && req.method == 'PUT') {
          ultimoUserUpdate = jsonDecode(texto) as Map<String, dynamic>;
          req.response.statusCode = 200;
          req.response.write(jsonEncode({'id': 'uuid_supabase_999'}));
          await req.response.close();
          return;
        }

        if (caminho.endsWith('/rest/v1/perfis') && req.method == 'PATCH') {
          ultimoPerfilPatch = jsonDecode(texto) as Map<String, dynamic>;
          req.response.statusCode = 204;
          await req.response.close();
          return;
        }

        ultimoCorpoRecebido = jsonDecode(texto) as Map<String, dynamic>;
        req.response.statusCode = statusResposta;
        if (statusResposta == 200) {
          final usarNomeMeta = ultimoCorpoRecebido['provider'] == 'google';
          req.response.write(
            jsonEncode({
              'access_token': 'jwt_supabase_real_123',
              'user': {
                'id': 'uuid_supabase_999',
                if (usarNomeMeta) 'email': 'renato.supabase@gmail.com',
                'user_metadata': usarNomeMeta
                    ? {
                        'name': 'Renato via Metadata',
                        'clube_associacao_fixalog': 'FEMERJ',
                      }
                    : <String, dynamic>{},
              },
            }),
          );
        } else {
          req.response.write(jsonEncode({'error': 'invalid_grant'}));
        }
        await req.response.close();
      });

      AutenticacaoNuvemService.urlSupabaseAtiva =
          'http://127.0.0.1:${server.port}';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            AutenticacaoNuvemService.canalAutenticacaoNativa,
            (MethodCall call) async {
              final args = Map<String, dynamic>.from(call.arguments as Map);
              final rawNonce = args['rawNonce'] as String;
              final provedor = call.method == 'solicitarIdTokenApple'
                  ? ProvedorOidc.apple
                  : ProvedorOidc.google;
              final idToken =
                  AutenticacaoNuvemService.construirIdTokenOidcComNonce(
                    provedor: provedor,
                    sub: 'sub_nativo',
                    email: 'nativo@aresta.com',
                    nomeCompleto: 'Renato Nativo',
                    rawNonce: rawNonce,
                  );
              return <String, dynamic>{
                'idToken': idToken,
                'nomeCompleto': provedor == ProvedorOidc.apple
                    ? 'Renato Apple Nativo'
                    : '',
                'email': 'fallback.apple@privaterelay.appleid.com',
              };
            },
          );

      final service = AutenticacaoNuvemService(
        cryptoService: cryptoService,
        secureStorage: secureStorage,
      );

      final sessaoGoogle = await service.entrarComProvedorOidc(
        ProvedorOidc.google,
      );
      expect(sessaoGoogle.userId, equals('uuid_supabase_999'));
      expect(sessaoGoogle.jwtSupabase, equals('jwt_supabase_real_123'));
      expect(sessaoGoogle.email, equals('renato.supabase@gmail.com'));
      expect(sessaoGoogle.nomeCompleto, equals('Renato Perfil Aresta'));
      expect(sessaoGoogle.clubeAssociacao, equals('FEMERJ'));
      expect(ultimoCorpoRecebido['provider'], equals('google'));
      expect(
        ultimoCorpoRecebido['nonce'],
        equals(sessaoGoogle.fingerprintChavePublica),
      );

      await service.atualizarPerfilConta(
        nomeCompleto: 'Renato Civil Fixalog',
        clubeAssociacao: 'CEC',
        atualizarNomeNoAresta: false,
      );
      expect(
        (ultimoUserUpdate['data'] as Map<String, dynamic>)['nome_completo_fixalog'],
        equals('Renato Civil Fixalog'),
      );
      expect(
        (ultimoUserUpdate['data'] as Map<String, dynamic>).containsKey('autor_nome_publico'),
        isFalse,
      );
      expect(ultimoPerfilPatch, isNull);

      await service.atualizarPerfilConta(
        nomeCompleto: 'Renato Unificado',
        clubeAssociacao: 'CEC',
        atualizarNomeNoAresta: true,
      );
      expect(
        (ultimoUserUpdate['data'] as Map<String, dynamic>)['autor_nome_publico'],
        equals('Renato Unificado'),
      );
      expect(ultimoPerfilPatch?['autor_nome_publico'], equals('Renato Unificado'));

      final sessaoApple = await service.entrarComProvedorOidc(
        ProvedorOidc.apple,
      );
      expect(sessaoApple.nomeCompleto, equals('Renato Perfil Aresta'));
      expect(
        sessaoApple.email,
        equals('fallback.apple@privaterelay.appleid.com'),
      );
      expect(ultimoCorpoRecebido['provider'], equals('apple'));

      statusResposta = 401;
      await expectLater(
        service.entrarComProvedorOidc(ProvedorOidc.google),
        throwsA(isA<HttpException>()),
      );
    });
  });
}
