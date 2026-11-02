// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:fixalog/features/identity/repositories/identity_repository.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/crypto_service.dart';

class _FakeCryptoService extends CryptoService {
  final bool deveFalhar;

  _FakeCryptoService({this.deveFalhar = false});

  @override
  Future<void> generateAndStoreKeysIfNeeded() async {
    if (deveFalhar) {
      throw Exception('Erro simulado no Keystore');
    }
  }
}

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
      final crypto = _FakeCryptoService();
      final viewModel = IdentityFormViewModel(repo, crypto);

      await viewModel.submitIdentity('', 'Clube');

      expect(
        viewModel.state.errorMessage,
        'Atenção. O nome não pode estar vazio.',
      );
      expect(await repo.hasIdentity(), isFalse);
    });

    test('submitIdentity com sucesso define isSuccess e persiste identidade no SQLite', () async {
      final repo = SqliteIdentityRepository(banco);
      final crypto = _FakeCryptoService();
      final viewModel = IdentityFormViewModel(repo, crypto);

      await viewModel.submitIdentity('Alex Honnold', 'Yosemite');

      expect(viewModel.state.isSuccess, isTrue);
      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.errorMessage, isNull);
      expect(await repo.hasIdentity(), isTrue);
      expect((await repo.getCurrentIdentity())?.nome, equals('Alex Honnold'));
    });

    test('submitIdentity captura excecoes do servico criptografico e define errorMessage', () async {
      final repo = SqliteIdentityRepository(banco);
      final crypto = _FakeCryptoService(deveFalhar: true);
      final viewModel = IdentityFormViewModel(repo, crypto);

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

      expect(container.read(identityFormViewModelProvider), isA<IdentityFormState>());
      expect(await container.read(hasIdentityProvider.future), isFalse);
      expect(await container.read(currentIdentityProvider.future), isNull);
    });
  });
}
