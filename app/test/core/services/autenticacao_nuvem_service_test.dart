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
import 'autenticacao_nuvem_service_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  late CryptoService cryptoService;
  late FlutterSecureStorage secureStorage;

  Future<CredencialOidcBruta> autenticadorTesteValido(
    ProvedorOidc provedor,
    String rawNonce,
  ) async {
    final email = provedor == ProvedorOidc.apple
        ? 'escalador@privaterelay.appleid.com'
        : 'escalador@gmail.com';
    final idToken = AutenticacaoNuvemServiceFake.construirIdTokenOidcComNonce(
      provedor: provedor,
      sub: 'sub_${provedor.valor}',
      email: email,
      nomeCompleto: 'Escalador Aresta',
      rawNonce: rawNonce,
    );
    return CredencialOidcBruta(
      userId: 'usr_${provedor.valor}',
      email: email,
      provedor: provedor,
      nomeCompleto: 'Escalador Aresta',
      jwtSupabase: 'jwt_supabase_${provedor.valor}',
      idTokenOidc: idToken,
    );
  }

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
        autenticadorOidc: autenticadorTesteValido,
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

    test('Rejeita canal nativo ausente, nulo, com idToken vazio ou PlatformException sem cair em fallback sintético', () async {
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              AutenticacaoNuvemService.canalAutenticacaoNativa,
              null,
            );
      });

      final service = AutenticacaoNuvemService(
        cryptoService: cryptoService,
        secureStorage: secureStorage,
      );

      // 1. Sem handler registrado (MissingPluginException)
      await expectLater(
        service.entrarComProvedorOidc(ProvedorOidc.apple),
        throwsA(isA<ExcecaoAutenticacaoOidc>()),
      );
      expect(await service.obterSessaoAtual(), isNull);

      // 2. Handler nativo retorna null (ex: Android sem suporte nativo a Apple)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            AutenticacaoNuvemService.canalAutenticacaoNativa,
            (MethodCall call) async => null,
          );
      await expectLater(
        service.entrarComProvedorOidc(ProvedorOidc.apple),
        throwsA(isA<ExcecaoAutenticacaoOidc>()),
      );
      expect(await service.obterSessaoAtual(), isNull);

      // 3. Handler nativo retorna idToken em branco
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            AutenticacaoNuvemService.canalAutenticacaoNativa,
            (MethodCall call) async => <String, dynamic>{
              'idToken': '   ',
              'cancelado': false,
            },
          );
      await expectLater(
        service.entrarComProvedorOidc(ProvedorOidc.google),
        throwsA(isA<ExcecaoAutenticacaoOidc>()),
      );

      // 4. Handler nativo lança PlatformException
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            AutenticacaoNuvemService.canalAutenticacaoNativa,
            (MethodCall call) async {
              throw PlatformException(
                code: 'AUTH_ERR',
                message: 'Falha nativa no CredentialManager',
              );
            },
          );
      await expectLater(
        service.entrarComProvedorOidc(ProvedorOidc.google),
        throwsA(
          isA<ExcecaoAutenticacaoOidc>().having(
            (e) => e.toString(),
            'toString',
            contains('Falha nativa no CredentialManager'),
          ),
        ),
      );

      // 5. PlatformException sem message usa code
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            AutenticacaoNuvemService.canalAutenticacaoNativa,
            (MethodCall call) async {
              throw PlatformException(code: 'CODIGO_PURO');
            },
          );
      await expectLater(
        service.entrarComProvedorOidc(ProvedorOidc.google),
        throwsA(
          isA<ExcecaoAutenticacaoOidc>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('CODIGO_PURO'),
          ),
        ),
      );

      // 6. Handler nativo retorna ausência de conta no dispositivo (NoCredentialException)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            AutenticacaoNuvemService.canalAutenticacaoNativa,
            (MethodCall call) async => <String, dynamic>{
              'erroCodigo': 'sem_credencial_dispositivo',
              'erroMensagem': 'No credentials available',
            },
          );
      await expectLater(
        service.entrarComProvedorOidc(ProvedorOidc.google),
        throwsA(
          isA<ExcecaoAutenticacaoOidc>()
              .having(
                (e) => e.semCredencialDispositivo,
                'semCredencialDispositivo',
                isTrue,
              )
              .having(
                (e) => e.codigoErroNativo,
                'codigoErroNativo',
                'sem_credencial_dispositivo',
              ),
        ),
      );

      // 7. Handler nativo retorna outro código estruturado de erro nativo (sem mensagem)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            AutenticacaoNuvemService.canalAutenticacaoNativa,
            (MethodCall call) async => <String, dynamic>{
              'erroCodigo': 'ASAuthorizationErrorDomain:1004',
            },
          );
      await expectLater(
        service.entrarComProvedorOidc(ProvedorOidc.apple),
        throwsA(
          isA<ExcecaoAutenticacaoOidc>()
              .having(
                (e) => e.semCredencialDispositivo,
                'semCredencialDispositivo',
                isFalse,
              )
              .having(
                (e) => e.codigoErroNativo,
                'codigoErroNativo',
                'ASAuthorizationErrorDomain:1004',
              )
              .having(
                (e) => e.mensagem,
                'mensagem',
                contains('ASAuthorizationErrorDomain:1004'),
              ),
        ),
      );
    });

    test('Lança ExcecaoAutenticacaoCancelada quando usuário cancela modal nativo sem disparar requisição HTTP ao Supabase', () async {
      var requisicoesHttpRecebidas = 0;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        requisicoesHttpRecebidas++;
        req.response.statusCode = 500;
        await req.response.close();
      });

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

      AutenticacaoNuvemService.urlSupabaseAtiva =
          'http://127.0.0.1:${server.port}';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            AutenticacaoNuvemService.canalAutenticacaoNativa,
            (MethodCall call) async => <String, dynamic>{'cancelado': true},
          );

      final service = AutenticacaoNuvemService(
        cryptoService: cryptoService,
        secureStorage: secureStorage,
      );

      await expectLater(
        service.entrarComProvedorOidc(ProvedorOidc.apple),
        throwsA(
          isA<ExcecaoAutenticacaoCancelada>().having(
            (e) => e.toString(),
            'toString',
            contains('cancelada'),
          ),
        ),
      );
      expect(requisicoesHttpRecebidas, equals(0));
      expect(await service.obterSessaoAtual(), isNull);
    });

    test('Rejeita id_token OIDC cujo nonce não corresponde à chave pública local', () async {
      final service = AutenticacaoNuvemService(
        cryptoService: cryptoService,
        secureStorage: secureStorage,
        autenticadorOidc: (provedor, rawNonce) async {
          final idTokenInvalido =
              AutenticacaoNuvemServiceFake.construirIdTokenOidcComNonce(
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
        autenticadorOidc: autenticadorTesteValido,
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
        autenticadorOidc: autenticadorTesteValido,
      );

      expect(await service.obterTokenAppCheck(), isNull);
      expect(
        AutenticacaoNuvemService.possuiTokenAppCheckReal(null),
        isFalse,
      );
      expect(
        AutenticacaoNuvemService.possuiTokenAppCheckReal('   '),
        isFalse,
      );
      expect(
        AutenticacaoNuvemService.possuiTokenAppCheckReal('jwt.appcheck.real'),
        isTrue,
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

    test('canalAutenticacaoNativa lê nomeExibicao/nomeCompleto e trocarIdTokenNoSupabase lança ExcecaoAutenticacaoOidc com statusCode em erros HTTP', () async {
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
      String corpoErroCustomizado = jsonEncode({
        'code': 400,
        'error_code': 'provider_disabled',
        'msg': 'Provider is not enabled',
      });
      List<Map<String, dynamic>> perfisRetornados = [
        {'autor_nome_publico': 'Renato Perfil Aresta'},
      ];
      Map<String, dynamic> ultimoCorpoRecebido = {};
      Map<String, dynamic> ultimoUserUpdate = {};
      Map<String, dynamic>? ultimoPerfilPatch;

      server.listen((HttpRequest req) async {
        final caminho = req.uri.path;
        final texto = await utf8.decoder.bind(req).join();
        req.response.headers.contentType = ContentType.json;

        if (caminho.endsWith('/rest/v1/perfis') && req.method == 'GET') {
          req.response.statusCode = 200;
          req.response.write(jsonEncode(perfisRetornados));
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
                        'clube_associacao_fixalog': 'FEMERJ',
                      }
                    : <String, dynamic>{},
              },
            }),
          );
        } else {
          req.response.write(corpoErroCustomizado);
        }
        await req.response.close();
      });

      expect(
        AutenticacaoNuvemService.chaveAnonSupabasePadrao,
        equals('sb_publishable_-pmZpZIRey5ukpGubgzVwg_fT_qKRJN'),
      );
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
                  AutenticacaoNuvemServiceFake.construirIdTokenOidcComNonce(
                    provedor: provedor,
                    sub: 'sub_nativo',
                    email: 'nativo@aresta.com',
                    nomeCompleto: 'Renato Nativo',
                    rawNonce: rawNonce,
                  );
              return <String, dynamic>{
                'idToken': idToken,
                if (provedor == ProvedorOidc.apple)
                  'nomeCompleto': 'Renato Apple Nativo'
                else
                  'nomeExibicao': 'Renato Android Exibicao',
                'email': 'fallback.apple@privaterelay.appleid.com',
              };
            },
          );

      final service = AutenticacaoNuvemService(
        cryptoService: cryptoService,
        secureStorage: secureStorage,
      );

      // Quando perfis está vazio, deve aproveitar nomeExibicao vindo do Android
      perfisRetornados = [];
      final sessaoGoogleAndroid = await service.entrarComProvedorOidc(
        ProvedorOidc.google,
      );
      expect(
        sessaoGoogleAndroid.nomeCompleto,
        equals('Renato Android Exibicao'),
      );

      perfisRetornados = [
        {'autor_nome_publico': 'Renato Perfil Aresta'},
      ];
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

      // Erro 400 JSON estruturado do GoTrue (ex: provider_disabled)
      statusResposta = 400;
      await expectLater(
        service.entrarComProvedorOidc(ProvedorOidc.apple),
        throwsA(
          isA<ExcecaoAutenticacaoOidc>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.codigoErroServidor,
                'codigoErroServidor',
                'provider_disabled',
              )
              .having((e) => e.toString(), 'toString', contains('uri = http')),
        ),
      );

      // Erro 502 texto puro sem JSON
      statusResposta = 502;
      corpoErroCustomizado = 'Bad Gateway';
      await expectLater(
        service.entrarComProvedorOidc(ProvedorOidc.google),
        throwsA(
          isA<ExcecaoAutenticacaoOidc>()
              .having((e) => e.statusCode, 'statusCode', 502)
              .having((e) => e.codigoErroServidor, 'codigoErroServidor', isNull),
        ),
      );
    });
  });
}
