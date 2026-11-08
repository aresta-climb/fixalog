// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:basic_utils/basic_utils.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/features/identity/repositories/identity_repository.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../core/services/autenticacao_nuvem_service_fake.dart';
import '../../../fakes/crypto_service_fake.dart';

void main() {
  late BancoDadosLocal banco;

  setUp(() async {
    banco = await BancoDadosLocal.abrirEmMemoria();
  });

  tearDown(() async {
    await banco.fechar();
  });

  group('IdentityFormViewModel e Providers', () {
    test('submitIdentity com nome vazio define errorMessage sem gravar no banco', () async {
      final repo = SqliteIdentityRepository(banco);
      final crypto = CryptoServiceFake();
      final auth = AutenticacaoNuvemServiceFake(crypto: crypto);
      final viewModel = IdentityFormViewModel(repo, crypto, auth);

      await viewModel.submitIdentity('', 'Clube');

      expect(
        viewModel.state.errorMessage,
        'Atenção. O nome não pode estar vazio.',
      );
      expect(await repo.hasIdentity(), isFalse);
    });

    test('submitIdentity exige autenticação Google ou Apple quando exigirAutenticacaoOidc=true', () async {
      final repo = SqliteIdentityRepository(banco);
      final crypto = CryptoServiceFake();
      final auth = AutenticacaoNuvemServiceFake(crypto: crypto);
      final viewModel = IdentityFormViewModel(repo, crypto, auth);

      await viewModel.submitIdentity(
        'Alex Honnold',
        'Yosemite',
        exigirAutenticacaoOidc: true,
      );

      expect(viewModel.state.isSuccess, isFalse);
      expect(
        viewModel.state.errorMessage,
        'Autentique-se com Google ou Apple antes de continuar.',
      );
      expect(await repo.hasIdentity(), isFalse);
    });

    test('autenticarComProvedor vincula chave ECDSA ao nonce OIDC, pré-preenche Nome/Clube e submitIdentity atualiza X.509 sem regerar chaves', () async {
      final repo = SqliteIdentityRepository(banco);
      final crypto = CryptoServiceFake();
      final auth = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        nomeRetornadoOidc: 'Renato Ferreira',
        clubeRetornadoOidc: 'FEMERJ',
      );
      final viewModel = IdentityFormViewModel(repo, crypto, auth);

      await viewModel.autenticarComProvedor(ProvedorOidc.google);

      expect(viewModel.state.sessaoNuvem, isNotNull);
      expect(viewModel.state.nomeSugerido, equals('Renato Ferreira'));
      expect(viewModel.state.clubeSugerido, equals('FEMERJ'));
      final fingerprintOriginal =
          viewModel.state.sessaoNuvem!.fingerprintChavePublica;

      await viewModel.submitIdentity(
        'Renato Editado',
        'CEC',
        exigirAutenticacaoOidc: true,
      );

      expect(viewModel.state.isSuccess, isTrue);
      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.errorMessage, isNull);
      expect(await repo.hasIdentity(), isTrue);
      expect((await repo.getCurrentIdentity())?.nome, equals('Renato Editado'));
      expect((await repo.getCurrentIdentity())?.clubeAssociacao, equals('CEC'));

      expect(
        await crypto.calcularFingerprintChavePublica(),
        equals(fingerprintOriginal),
      );
      final x509 = X509Utils.x509CertificateFromPem(
        (await crypto.obterCertificadoX509Pem())!,
      );
      expect(x509.subject['2.5.4.3'], equals('Renato Editado'));
      expect(x509.subject['2.5.4.11'], equals('CEC'));
    });

    test('submitIdentity recupera sessão OIDC já persistida no cofre quando exigirAutenticacaoOidc=true', () async {
      final repo = SqliteIdentityRepository(banco);
      final crypto = CryptoServiceFake();
      final auth = AutenticacaoNuvemServiceFake(crypto: crypto);
      await auth.entrarComProvedorOidc(ProvedorOidc.apple);

      final viewModel = IdentityFormViewModel(repo, crypto, auth);
      await viewModel.submitIdentity(
        'Tommy Caldwell',
        '',
        exigirAutenticacaoOidc: true,
      );

      expect(viewModel.state.isSuccess, isTrue);
      expect((await repo.getCurrentIdentity())?.clubeAssociacao, equals('N/A'));
    });

    test('autenticarComProvedor e submitIdentity capturam exceções e definem errorMessage', () async {
      final repo = SqliteIdentityRepository(banco);
      final crypto = CryptoServiceFake(deveFalharGeracaoChaves: true);
      final auth = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        deveFalharLogin: true,
      );
      final viewModel = IdentityFormViewModel(repo, crypto, auth);

      await viewModel.autenticarComProvedor(ProvedorOidc.google);
      expect(
        viewModel.state.errorMessage,
        contains('Falha na autenticação OIDC'),
      );

      await viewModel.submitIdentity('Tommy Caldwell', 'El Cap');
      expect(viewModel.state.isSuccess, isFalse);
      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.errorMessage, contains('Falha durante registro'));
    });

    test('identityFormViewModelProvider, hasIdentityProvider e currentIdentityProvider operam com BancoDadosLocal', () async {
      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(identityFormViewModelProvider),
        isA<IdentityFormState>(),
      );
      expect(await container.read(hasIdentityProvider.future), isFalse);
      expect(await container.read(currentIdentityProvider.future), isNull);
    });
  });
}
