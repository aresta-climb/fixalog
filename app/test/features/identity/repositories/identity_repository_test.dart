// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/features/identity/repositories/identity_repository.dart';
import 'package:fixalog/core/models/local/identity_record.dart';

// Como o Isar não roda facilmente em testes unitários puros sem carregar a lib binária,
// testamos aqui a lógica de nullability do nosso Repository atual
// ou fazemos um mock do Isar (o que é complexo para Isar).
// O verdadeiro ganho do Repository é podermos testar o ViewModel!
// De qualquer forma, garantimos a estrutura do Repository.

void main() {
  group('IsarIdentityRepository', () {
    test('hasIdentity retorna false quando isar é nulo', () async {
      final repository = IsarIdentityRepository(null);
      final hasId = await repository.hasIdentity();
      expect(hasId, isFalse);
    });

    test('getCurrentIdentity retorna nulo quando isar é nulo', () async {
      final repository = IsarIdentityRepository(null);
      final identity = await repository.getCurrentIdentity();
      expect(identity, isNull);
    });

    test('saveIdentity lança exceção quando isar é nulo', () async {
      final repository = IsarIdentityRepository(null);
      final identity = IdentityRecord()..nome = 'Teste';
      expect(
        () => repository.saveIdentity(identity),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Isar instance is null'),
          ),
        ),
      );
    });
  });
}
