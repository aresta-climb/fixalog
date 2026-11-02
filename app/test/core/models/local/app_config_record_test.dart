// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/models/local/app_config_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';

void main() {
  group('AppConfigRecord', () {
    test('Inicializa com valores padrao corretos', () {
      final config = AppConfigRecord();
      expect(config.id, equals(1));
      expect(config.acceptedTermsVersion, equals(0));
      expect(config.versaoTermosAceita, equals(0));
      expect(config.dataHoraAceiteTermos, isNull);
    });

    test('Sincroniza versaoTermosAceita com acceptedTermsVersion', () {
      final config = AppConfigRecord();

      config.versaoTermosAceita = 5;
      expect(config.acceptedTermsVersion, equals(5));
      expect(config.versaoTermosAceita, equals(5));

      config.acceptedTermsVersion = 10;
      expect(config.versaoTermosAceita, equals(10));
    });

    test('Serializa e desserializa via toMap/fromMap e banco SQLite em memoria', () async {
      final banco = await BancoDadosLocal.abrirEmMemoria();
      addTearDown(() async => await banco.fechar());

      final agora = DateTime(2026, 11, 2, 12, 30);
      final config = AppConfigRecord(
        id: 1,
        acceptedTermsVersion: 3,
        dataHoraAceiteTermos: agora,
      );

      await banco.salvarConfiguracao(config);
      final recuperado = await banco.obterConfiguracao(1);

      expect(recuperado, isNotNull);
      expect(recuperado!.id, equals(1));
      expect(recuperado.versaoTermosAceita, equals(3));
      expect(recuperado.dataHoraAceiteTermos, equals(agora));

      final semData = AppConfigRecord.fromMap({'id': 1, 'versao_termos_aceita': 2});
      expect(semData.dataHoraAceiteTermos, isNull);
      expect(semData.versaoTermosAceita, equals(2));
    });
  });
}
