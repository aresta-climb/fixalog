// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:fixalog/features/home/views/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fabrica_dataset_caos.dart';
import 'receita_crash_robo.dart';

void main() {
  group('FabricaDatasetCaos e AmbienteAppCaos', () {
    late AmbienteAppCaos ambiente;

    setUp(() async {
      ambiente = await AmbienteAppCaos.inicializar();
    });

    tearDown(() async {
      await ambiente.limpar();
    });

    testWidgets(
      'montarApp monta o FixalogApp completo sobre SQLite em memória nos perfis normal e toxico',
      (tester) async {
        await ambiente.montarApp(tester, TipoDatasetCaos.normal);

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(ambiente.bancoAtivo, isNotNull);
        final submissoesNormal = ambiente.bancoAtivo!.listarSubmissoesSync();
        expect(submissoesNormal.length, equals(3));

        await ambiente.montarApp(tester, TipoDatasetCaos.toxico);

        expect(find.byType(HomeScreen), findsOneWidget);
        final submissoesToxico = ambiente.bancoAtivo!.listarSubmissoesSync();
        expect(submissoesToxico.length, equals(4));
      },
    );
  });
}
