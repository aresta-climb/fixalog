// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/models/local/identity_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';

void main() {
  group('IdentityRecord Model Tests', () {
    test('instancia, serializa e persiste no SQLite em memoria corretamente', () async {
      final banco = await BancoDadosLocal.abrirEmMemoria();
      addTearDown(() async => await banco.fechar());

      final now = DateTime(2026, 11, 2, 10, 15);
      final record = IdentityRecord()
        ..nome = 'Renato Silva'
        ..clubeAssociacao = 'Aresta Climb'
        ..dataRegistro = now;

      final idGerado = await banco.salvarIdentidade(record);
      expect(idGerado, greaterThan(0));
      expect(record.id, equals(idGerado));

      final mapaComId = record.toMap();
      expect(mapaComId['id'], equals(idGerado));

      final recuperado = await banco.obterIdentidadeAtual();
      expect(recuperado, isNotNull);
      expect(recuperado!.id, equals(idGerado));
      expect(recuperado.nome, equals('Renato Silva'));
      expect(recuperado.clubeAssociacao, equals('Aresta Climb'));
      expect(recuperado.dataRegistro, equals(now));
    });
  });
}
