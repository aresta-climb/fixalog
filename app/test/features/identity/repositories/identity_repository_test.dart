// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/features/identity/repositories/identity_repository.dart';
import 'package:fixalog/core/models/local/identity_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';

void main() {
  group('SqliteIdentityRepository', () {
    test('retorna falso/nulo e lanca excecao quando banco for nulo', () async {
      final repository = SqliteIdentityRepository(null);
      expect(await repository.hasIdentity(), isFalse);
      expect(await repository.getCurrentIdentity(), isNull);

      final identity = IdentityRecord()
        ..nome = 'Teste'
        ..clubeAssociacao = 'Aresta'
        ..dataRegistro = DateTime.now();
      expect(
        () => repository.saveIdentity(identity),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('BancoDadosLocal instance is null'),
          ),
        ),
      );
    });

    test('persiste e recupera identidade real no banco SQLite em memoria', () async {
      final banco = await BancoDadosLocal.abrirEmMemoria();
      addTearDown(() async => await banco.fechar());

      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(identityRepositoryProvider);
      expect(await repository.hasIdentity(), isFalse);
      expect(await repository.getCurrentIdentity(), isNull);

      final identity = IdentityRecord()
        ..nome = 'Renato Utsch'
        ..clubeAssociacao = 'Aresta Climb'
        ..dataRegistro = DateTime(2026, 11, 2, 11, 0);

      await repository.saveIdentity(identity);

      expect(await repository.hasIdentity(), isTrue);
      final recuperada = await repository.getCurrentIdentity();
      expect(recuperada, isNotNull);
      expect(recuperada!.nome, equals('Renato Utsch'));
      expect(recuperada.clubeAssociacao, equals('Aresta Climb'));
    });
  });
}
