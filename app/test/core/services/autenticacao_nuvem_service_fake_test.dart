// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../fakes/crypto_service_fake.dart';
import 'autenticacao_nuvem_service_fake.dart';

void main() {
  group('AutenticacaoNuvemServiceFake', () {
    test('Realiza login OIDC Google/Apple vinculando rawNonce da chave pública e atualiza perfil mantendo chave', () async {
      final crypto = CryptoServiceFake();
      final fake = AutenticacaoNuvemServiceFake(crypto: crypto);

      final sessao = await fake.entrarComProvedorOidc(ProvedorOidc.google);
      expect(sessao.provedor, equals(ProvedorOidc.google));
      expect(sessao.nomeCompleto, equals('Renato Ferreira'));
      expect(sessao.clubeAssociacao, equals('FEMERJ'));
      expect(
        AutenticacaoNuvemService.validarNonceNoIdToken(
          idTokenOidc: sessao.atestadoOidcJwt,
          rawNonceEsperado: sessao.fingerprintChavePublica,
        ),
        isTrue,
      );
      expect(await crypto.obterAtestadoOidcJwt(), equals(sessao.atestadoOidcJwt));

      final sessaoAtualizada = await fake.atualizarPerfilConta(
        nomeCompleto: 'Renato Silva',
        clubeAssociacao: 'CEC',
        atualizarNomeNoAresta: false,
      );
      expect(sessaoAtualizada?.nomeCompleto, equals('Renato Silva'));
      expect(sessaoAtualizada?.clubeAssociacao, equals('CEC'));
      expect(fake.ultimoAtualizarNomeNoAresta, isFalse);
      expect(
        sessaoAtualizada?.fingerprintChavePublica,
        equals(sessao.fingerprintChavePublica),
      );

      final reatestado = await fake.vincularChaveLocalAoProvedorOidc(
        ProvedorOidc.apple,
      );
      expect(reatestado.provedor, equals(ProvedorOidc.apple));
      expect(await fake.obterTokenAppCheck(), equals('app_check_token_valido'));

      await fake.encerrarSessao();
      expect(await fake.obterSessaoAtual(), isNull);
    });

    test('Simula cancelamento voluntário, falhas tipadas OIDC, erro customizado e falha no App Check', () async {
      final crypto = CryptoServiceFake();
      final fakeCancelado = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        deveCancelarLogin: true,
      );
      await expectLater(
        fakeCancelado.entrarComProvedorOidc(ProvedorOidc.apple),
        throwsA(isA<ExcecaoAutenticacaoCancelada>()),
      );

      final fakeErroCustomizado = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        erroCustomizadoLogin: const SocketException('Sem sinal na montanha'),
      );
      await expectLater(
        fakeErroCustomizado.entrarComProvedorOidc(ProvedorOidc.google),
        throwsA(isA<SocketException>()),
      );

      final fakeSemConta = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        deveSimularSemCredencialDispositivo: true,
        tokenAppCheckRetornado: null,
      );
      await expectLater(
        fakeSemConta.entrarComProvedorOidc(ProvedorOidc.google),
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
      expect(await fakeSemConta.obterTokenAppCheck(), isNull);

      final fake = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        deveFalharLogin: true,
        deveFalharAppCheck: true,
      );

      await expectLater(
        fake.entrarComProvedorOidc(ProvedorOidc.google),
        throwsA(
          isA<ExcecaoAutenticacaoOidc>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.codigoErroServidor,
                'codigoErroServidor',
                'provider_disabled',
              ),
        ),
      );
      await expectLater(fake.obterTokenAppCheck(), throwsException);
      expect(
        await fake.atualizarPerfilConta(
          nomeCompleto: 'Sem Sessao',
          clubeAssociacao: '',
        ),
        isNull,
      );
    });
  });
}
