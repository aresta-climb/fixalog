// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:basic_utils/basic_utils.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/providers.dart';
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
      expect(viewModel.state.atualizarNomeNoAresta, isTrue);
      final fingerprintOriginal =
          viewModel.state.sessaoNuvem!.fingerprintChavePublica;

      viewModel.definirAtualizarNomeNoAresta(false);
      expect(viewModel.state.atualizarNomeNoAresta, isFalse);

      await viewModel.submitIdentity(
        'Renato Editado',
        'CEC',
        exigirAutenticacaoOidc: true,
      );

      expect(viewModel.state.isSuccess, isTrue);
      expect(auth.ultimoAtualizarNomeNoAresta, isFalse);
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
      expect(x509.tbsCertificate?.subject['2.5.4.3'], equals('Renato Editado'));
      expect(x509.tbsCertificate?.subject['2.5.4.11'], equals('CEC'));

      await viewModel.trocarConta();
      expect(viewModel.state.sessaoNuvem, isNull);
      expect(await auth.obterSessaoAtual(), isNull);
    });

    test('carregarSessaoExistente restaura sessão OIDC, reinicia isSuccess e limpa errorMessage de submissão anterior', () async {
      final repo = SqliteIdentityRepository(banco);
      final crypto = CryptoServiceFake();
      final auth = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        nomeRetornadoOidc: 'Nome OIDC',
        clubeRetornadoOidc: 'Clube OIDC',
      );
      await auth.entrarComProvedorOidc(ProvedorOidc.google);

      final viewModel = IdentityFormViewModel(repo, crypto, auth);
      await viewModel.submitIdentity(
        'Nome Inicial',
        'Clube Inicial',
        exigirAutenticacaoOidc: true,
      );
      expect(viewModel.state.isSuccess, isTrue);

      await viewModel.carregarSessaoExistente();

      expect(viewModel.state.isSuccess, isFalse);
      expect(viewModel.state.errorMessage, isNull);
      expect(viewModel.state.sessaoNuvem, isNotNull);
      expect(viewModel.state.nomeSugerido, equals('Nome Inicial'));
      expect(viewModel.state.clubeSugerido, equals('Clube Inicial'));

      // Quando a sessão OIDC possui nome/clube em branco, usa o IdentityRecord local como fallback
      final authSemPerfil = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        sessaoArmazenada: const SessaoUsuarioNuvem(
          userId: 'usr_sem_perfil',
          email: 'semperfil@arestaclimb.com',
          provedor: ProvedorOidc.apple,
          nomeCompleto: '',
          clubeAssociacao: '',
          jwtSupabase: 'jwt_1',
          atestadoOidcJwt: 'oidc_1',
          fingerprintChavePublica: 'fp_1',
        ),
      );
      final vmFallback = IdentityFormViewModel(repo, crypto, authSemPerfil);
      await vmFallback.carregarSessaoExistente();
      expect(vmFallback.state.nomeSugerido, equals('Nome Inicial'));
      expect(vmFallback.state.clubeSugerido, equals('Clube Inicial'));
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
      final crypto = CryptoServiceFake();
      final auth = AutenticacaoNuvemServiceFake(crypto: crypto);
      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          cryptoServiceProvider.overrideWithValue(crypto),
          autenticacaoNuvemServiceProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);

      expect(
        IdentityFormViewModel(SqliteIdentityRepository(banco), crypto),
        isA<IdentityFormViewModel>(),
      );
      expect(
        container.read(identityFormViewModelProvider),
        isA<IdentityFormState>(),
      );
      expect(await container.read(hasIdentityProvider.future), isFalse);
      expect(await container.read(currentIdentityProvider.future), isNull);

      final repo = container.read(identityRepositoryProvider);
      await container
          .read(identityFormViewModelProvider.notifier)
          .submitIdentity('Escalador Local', 'Clube');
      expect(await repo.hasIdentity(), isTrue);
      container.invalidate(hasIdentityProvider);
      // Sem sessão OIDC autenticada, hasIdentityProvider retorna false para exigir login
      expect(await container.read(hasIdentityProvider.future), isFalse);

      await auth.entrarComProvedorOidc(ProvedorOidc.google);
      container.invalidate(hasIdentityProvider);
      expect(await container.read(hasIdentityProvider.future), isTrue);
    });
  });
}
