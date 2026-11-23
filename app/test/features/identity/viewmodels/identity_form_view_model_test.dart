// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:ui';
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
import '../../../fakes/registro_logger_fake.dart';

void main() {
  late BancoDadosLocal banco;

  setUp(() async {
    banco = await BancoDadosLocal.abrirEmMemoria();
  });

  tearDown(() async {
    await banco.fechar();
  });

  group('IdentityFormViewModel e Providers', () {
    test('submitIdentity com nome vazio define errorMessage sem gravar no banco nem acionar logError', () async {
      final repo = SqliteIdentityRepository(banco);
      final crypto = CryptoServiceFake();
      final auth = AutenticacaoNuvemServiceFake(crypto: crypto);
      final logger = RegistroLoggerFake();
      final viewModel = IdentityFormViewModel(repo, crypto, auth, logger);

      await viewModel.submitIdentity('', 'Clube');

      expect(
        viewModel.state.errorMessage,
        'Atenção. O nome não pode estar vazio.',
      );
      expect(await repo.hasIdentity(), isFalse);
      expect(logger.errosRegistrados, isEmpty);
    });

    test('submitIdentity exige autenticação Google ou Apple quando exigirAutenticacaoOidc=true', () async {
      final repo = SqliteIdentityRepository(banco);
      final crypto = CryptoServiceFake();
      final auth = AutenticacaoNuvemServiceFake(crypto: crypto);
      final logger = RegistroLoggerFake();
      final viewModel = IdentityFormViewModel(repo, crypto, auth, logger);

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
      expect(logger.errosRegistrados, isEmpty);
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

    test('autenticarComProvedor trata cancelamento silenciosamente, rebaixa falta de sinal para logAviso e registra erros definitivos no RegistroLogger sem vazar JSON', () async {
      final repo = SqliteIdentityRepository(banco);
      final crypto = CryptoServiceFake(deveFalharGeracaoChaves: true);
      final logger = RegistroLoggerFake();

      // 1. Cancelamento voluntário pelo usuário: sem erro na UI e sem Sentry
      final authCancelado = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        deveCancelarLogin: true,
      );
      final vmCancelado = IdentityFormViewModel(
        repo,
        crypto,
        authCancelado,
        logger,
      );
      await vmCancelado.autenticarComProvedor(ProvedorOidc.apple);
      expect(vmCancelado.state.isLoading, isFalse);
      expect(vmCancelado.state.errorMessage, isNull);
      expect(logger.errosRegistrados, isEmpty);
      expect(logger.avisosRegistrados, isEmpty);

      // 2. Falta de sinal na montanha: apenas logAviso e mensagem amigável offline
      final authOffline = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        erroCustomizadoLogin: const SocketException('Network is unreachable'),
      );
      final vmOffline = IdentityFormViewModel(
        repo,
        crypto,
        authOffline,
        logger,
      );
      await vmOffline.autenticarComProvedor(
        ProvedorOidc.google,
        locale: const Locale('en'),
      );
      expect(logger.errosRegistrados, isEmpty);
      expect(logger.avisosRegistrados, hasLength(1));
      expect(
        vmOffline.state.errorMessage,
        equals(
          'No internet connection. Connect to the internet to link your account.',
        ),
      );

      // 2.5. Ausência de conta Google cadastrada no aparelho: apenas logAviso (zero logError) e mensagem orientativa localizada
      final authSemConta = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        deveSimularSemCredencialDispositivo: true,
      );
      final vmSemConta = IdentityFormViewModel(
        repo,
        crypto,
        authSemConta,
        logger,
      );
      await vmSemConta.autenticarComProvedor(
        ProvedorOidc.google,
        locale: const Locale('pt'),
      );
      expect(logger.errosRegistrados, isEmpty);
      expect(logger.avisosRegistrados, hasLength(2));
      expect(
        vmSemConta.state.errorMessage,
        equals(
          'Nenhuma conta Google encontrada neste aparelho. Adicione uma conta Google nas configurações do dispositivo e tente novamente.',
        ),
      );

      // 3. Erro HTTP 400 (provider_disabled) e falha ao salvar: logError com StackTrace e mensagem limpa sem JSON/URI
      final authErro400 = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        deveFalharLogin: true,
      );
      final viewModel = IdentityFormViewModel(
        repo,
        crypto,
        authErro400,
        logger,
      );

      await viewModel.autenticarComProvedor(
        ProvedorOidc.apple,
        locale: const Locale('en'),
      );
      expect(logger.errosRegistrados, hasLength(1));
      expect(
        logger.errosRegistrados.first.erro,
        isA<ExcecaoAutenticacaoOidc>(),
      );
      expect(
        viewModel.state.errorMessage,
        equals('Could not complete sign-in. Please try again.'),
      );
      expect(viewModel.state.errorMessage, isNot(contains('provider_disabled')));

      await viewModel.submitIdentity('Tommy Caldwell', 'El Cap');
      expect(viewModel.state.isSuccess, isFalse);
      expect(viewModel.state.isLoading, isFalse);
      expect(logger.errosRegistrados, hasLength(2));
      expect(
        viewModel.state.errorMessage,
        equals('Não foi possível salvar a identidade. Tente novamente.'),
      );
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
