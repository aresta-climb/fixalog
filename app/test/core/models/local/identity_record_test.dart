// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'package:flutter_test/flutter_test.dart';
import 'package:fixlog/core/models/local/identity_record.dart';

void main() {
  group('IdentityRecord Model Tests', () {
    test('instancia e atribui propriedades corretamente', () {
      final now = DateTime.now();
      final record = IdentityRecord()
        ..id = 1
        ..nome = 'Renato Silva'
        ..clubeAssociacao = 'Aresta Climb'
        ..dataRegistro = now;

      expect(record.id, 1);
      expect(record.nome, 'Renato Silva');
      expect(record.clubeAssociacao, 'Aresta Climb');
      expect(record.dataRegistro, now);
    });
  });
}
