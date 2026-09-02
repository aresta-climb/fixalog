// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'package:flutter_test/flutter_test.dart';
import 'package:fixlog/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:fixlog/features/identity/repositories/identity_repository.dart';
import 'package:fixlog/core/models/local/identity_record.dart';
import 'package:fixlog/core/services/crypto_service.dart';

class MockIdentityRepository implements IdentityRepository {
  bool saveCalled = false;

  @override
  Future<bool> hasIdentity() async => false;

  @override
  Future<IdentityRecord?> getCurrentIdentity() async => null;

  @override
  Future<void> saveIdentity(IdentityRecord identity) async {
    saveCalled = true;
  }
}

// O CryptoService real tenta instanciar MethodChannels que falham nos testes.
// Em um app real usaríamos mocktail para criar um MockCryptoService.
class MockCryptoService extends CryptoService {
  @override
  Future<void> generateAndStoreKeysIfNeeded() async {
    // Simula a geração de chaves com sucesso sem invocar nativos
    return;
  }
}

void main() {
  group('IdentityFormViewModel', () {
    test('submitIdentity com nome vazio define errorMessage', () async {
      final repo = MockIdentityRepository();
      final crypto = MockCryptoService();
      final viewModel = IdentityFormViewModel(repo, crypto);

      await viewModel.submitIdentity('', 'Clube');

      expect(
        viewModel.state.errorMessage,
        'Atenção. O nome não pode estar vazio.',
      );
      expect(repo.saveCalled, isFalse);
    });

    test(
      'submitIdentity com sucesso define isSuccess e salva no repo',
      () async {
        final repo = MockIdentityRepository();
        final crypto = MockCryptoService();
        final viewModel = IdentityFormViewModel(repo, crypto);

        await viewModel.submitIdentity('Alex Honnold', 'Yosemite');

        expect(viewModel.state.isSuccess, isTrue);
        expect(viewModel.state.isLoading, isFalse);
        expect(viewModel.state.errorMessage, isNull);
        expect(repo.saveCalled, isTrue);
      },
    );
  });
}
