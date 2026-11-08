// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

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
      );
      expect(sessaoAtualizada?.nomeCompleto, equals('Renato Silva'));
      expect(sessaoAtualizada?.clubeAssociacao, equals('CEC'));
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

    test('Simula falhas determinísticas no login OIDC e no App Check', () async {
      final crypto = CryptoServiceFake();
      final fake = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        deveFalharLogin: true,
        deveFalharAppCheck: true,
      );

      await expectLater(
        fake.entrarComProvedorOidc(ProvedorOidc.google),
        throwsException,
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
