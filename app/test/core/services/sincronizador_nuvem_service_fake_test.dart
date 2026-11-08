// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:typed_data';
import 'package:fixalog/core/services/sincronizador_nuvem_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'sincronizador_nuvem_service_fake.dart';

void main() {
  group('ClienteHttpFixalogNuvemFake', () {
    test('Armazena versões enviadas em memória, lista laudos remotos e simula falhas de rede', () async {
      final fake = ClienteHttpFixalogNuvemFake();
      final status = await fake.enviarVersaoEpub(
        idSessao: 's1',
        epubBytes: Uint8List.fromList([1, 2, 3]),
        jwtSupabase: 'jwt',
        tokenAppCheck: 'appcheck',
      );
      expect(status, equals(201));
      expect(fake.ordemIdsEnviados, equals(['s1']));
      expect(fake.versoesRecebidasPorSessao['s1']?.length, equals(1));
      expect(await fake.baixarEpubPublico(idSessao: 's1'), isNotNull);

      fake.laudosRemotosConta.add(
        MetadadosLaudoRemoto(
          idSessao: 's1',
          categoria: 'MANUTENCAO',
          idProtocolo: 'manutencao_ferragens',
          titulo: 'Via 1',
          versaoAtual: 1,
          atualizadoEm: DateTime.utc(2026, 11, 8),
        ),
      );
      final lista = await fake.listarLaudosConta(
        jwtSupabase: 'jwt',
        tokenAppCheck: 'appcheck',
      );
      expect(lista.length, equals(1));

      fake.deveLancarErroRede = true;
      await expectLater(
        fake.enviarVersaoEpub(
          idSessao: 's1',
          epubBytes: Uint8List(0),
          jwtSupabase: 'jwt',
          tokenAppCheck: 'appcheck',
        ),
        throwsException,
      );
      await expectLater(
        fake.listarLaudosConta(jwtSupabase: 'jwt', tokenAppCheck: 'appcheck'),
        throwsException,
      );
      await expectLater(
        fake.baixarEpubPublico(idSessao: 's1'),
        throwsException,
      );
    });
  });
}
