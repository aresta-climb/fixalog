// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/local/identity_record.dart';
import '../../../core/services/banco_dados_local.dart';

abstract class IdentityRepository {
  Future<bool> hasIdentity();
  Future<IdentityRecord?> getCurrentIdentity();
  Future<void> saveIdentity(IdentityRecord identity);
}

/// Implementação do repositório de identidade persistida em SQLite via [BancoDadosLocal].
class SqliteIdentityRepository implements IdentityRepository {
  final BancoDadosLocal? _banco;

  SqliteIdentityRepository(this._banco);

  @override
  Future<bool> hasIdentity() async {
    if (_banco == null) return false;
    return await _banco.possuiIdentidade();
  }

  @override
  Future<IdentityRecord?> getCurrentIdentity() async {
    if (_banco == null) return null;
    return await _banco.obterIdentidadeAtual();
  }

  @override
  Future<void> saveIdentity(IdentityRecord identity) async {
    if (_banco == null) throw Exception('BancoDadosLocal instance is null');
    await _banco.salvarIdentidade(identity);
  }
}

final identityRepositoryProvider = Provider<IdentityRepository>((ref) {
  final banco = ref.watch(bancoDadosLocalProvider);
  return SqliteIdentityRepository(banco);
});
