// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/models/local/app_config_record.dart';

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

    test('Armazena e recupera dataHoraAceiteTermos com sucesso', () {
      final config = AppConfigRecord();
      final agora = DateTime.now();

      config.dataHoraAceiteTermos = agora;
      expect(config.dataHoraAceiteTermos, equals(agora));

      config.dataHoraAceiteTermos = null;
      expect(config.dataHoraAceiteTermos, isNull);
    });
  });
}
