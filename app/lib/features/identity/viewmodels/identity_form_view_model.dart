// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import '../../../core/models/local/identity_record.dart';
import '../../../core/services/crypto_service.dart';
import '../repositories/identity_repository.dart';

class IdentityFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  IdentityFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  IdentityFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return IdentityFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class IdentityFormViewModel extends StateNotifier<IdentityFormState> {
  final IdentityRepository _repository;
  final CryptoService _cryptoService;

  IdentityFormViewModel(this._repository, this._cryptoService)
    : super(IdentityFormState());

  Future<void> submitIdentity(String nome, String clube) async {
    if (nome.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Atenção. O nome não pode estar vazio.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. Gera e guarda assimetricamente usando flutter_secure_storage
      await _cryptoService.generateAndStoreKeysIfNeeded();

      // 2. Persiste a Identidade usando o Repository
      final identity = IdentityRecord()
        ..nome = nome
        ..clubeAssociacao = clube.isEmpty ? 'N/A' : clube
        ..dataRegistro = DateTime.now();

      await _repository.saveIdentity(identity);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Falha durante registro: \$e',
      );
    }
  }
}

// TODO: isarProvider moved to identity_repository.dart. We must define it here if we want to keep it here,
// but it's better to export it from identity_repository.dart since other providers depend on it.
// Actually, it's already in identity_repository.dart and we imported it there. But `hasIdentityProvider` needs `isarProvider` or `identityRepositoryProvider`.

final identityFormViewModelProvider =
    StateNotifierProvider<IdentityFormViewModel, IdentityFormState>((ref) {
      final repository = ref.watch(identityRepositoryProvider);
      final cryptoService = CryptoService();
      return IdentityFormViewModel(repository, cryptoService);
    });

// Refactored to use repository instead of isar directly
final hasIdentityProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(identityRepositoryProvider);
  return await repository.hasIdentity();
});

final currentIdentityProvider = FutureProvider<IdentityRecord?>((ref) async {
  final repository = ref.watch(identityRepositoryProvider);
  return await repository.getCurrentIdentity();
});

// Exposing isarProvider here for backward compatibility during refactoring
// if any other file imports it from here.

final isarProvider = Provider<Isar?>((ref) => throw UnimplementedError());
