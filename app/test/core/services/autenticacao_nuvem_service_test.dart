// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'package:basic_utils/basic_utils.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/crypto_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      expect(x509.subject['2.5.4.3'], equals('Renato Novo Nome'));
      expect(x509.subject['2.5.4.11'], equals('AGUIA'));
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
    });
  });
}
