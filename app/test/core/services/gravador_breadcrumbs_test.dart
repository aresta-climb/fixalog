// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:fixalog/core/services/gravador_breadcrumbs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    GravadorBreadcrumbs.resetarParaTestes();
  });

  tearDown(() {
    GravadorBreadcrumbs.resetarParaTestes();
  });

  group('GravadorBreadcrumbs — Buffer Circular FIFO em Memória', () {
    test(
      'registra eventos em ordem cronológica com timestamp UTC e parâmetros imutáveis',
      () {
        final gravador = GravadorBreadcrumbs.instancia;
        expect(gravador.total, equals(0));
        expect(gravador.obterBreadcrumbs(), isEmpty);

        final t1 = DateTime.utc(2026, 11, 9, 12, 0, 0);
        final t2 = DateTime.utc(2026, 11, 9, 12, 0, 5);

        gravador.registrar(
          evento: 'navegar_aba',
          parametros: {'aba': 'historico'},
          timestamp: t1,
        );
        gravador.registrar(
          evento: 'iniciar_protocolo',
          timestamp: t2,
        );

        expect(gravador.total, equals(2));
        final lista = gravador.obterBreadcrumbs();
        expect(lista, hasLength(2));
        expect(lista[0]['timestamp'], equals('2026-11-09T12:00:00.000Z'));
        expect(lista[0]['evento'], equals('navegar_aba'));
        expect(lista[0]['parametros'], equals({'aba': 'historico'}));
        expect(lista[1]['timestamp'], equals('2026-11-09T12:00:05.000Z'));
        expect(lista[1]['evento'], equals('iniciar_protocolo'));
        expect(lista[1]['parametros'], isEmpty);
      },
    );

    test(
      'descarta automaticamente o evento mais antigo ao atingir a capacidade máxima (FIFO) e permite limpar',
      () {
        final gravador = GravadorBreadcrumbs(capacidadeMaxima: 3);

        gravador.registrar(evento: 'ev_1');
        gravador.registrar(evento: 'ev_2');
        gravador.registrar(evento: 'ev_3');
        gravador.registrar(evento: 'ev_4');

        expect(gravador.total, equals(3));
        final eventos = gravador
            .obterBreadcrumbs()
            .map((item) => item['evento'])
            .toList();
        expect(eventos, equals(['ev_2', 'ev_3', 'ev_4']));

        gravador.limpar();
        expect(gravador.total, equals(0));
        expect(gravador.obterBreadcrumbs(), isEmpty);
      },
    );
  });
}
