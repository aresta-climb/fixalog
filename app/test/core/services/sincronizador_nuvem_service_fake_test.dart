// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:typed_data';
import 'package:fixalog/core/services/sincronizador_nuvem_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'sincronizador_nuvem_service_fake.dart';

void main() {
  group('ClienteHttpFixalogNuvemFake', () {
    test('Armazena versões enviadas em memória, suporta upload retomável em chunks, consulta status e simula falhas de rede', () async {
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

      // Testa consultarStatusLaudo e enviarChunkEpub
      final statusInicial = await fake.consultarStatusLaudo(
        idSessao: 's_chunk',
        sha256: 'abc123',
        jwtSupabase: 'jwt',
        tokenAppCheck: 'appcheck',
      );
      expect(statusInicial.jaEnviado, isFalse);
      expect(statusInicial.chunksRecebidos, isEmpty);

      final resChunk0 = await fake.enviarChunkEpub(
        idSessao: 's_chunk',
        sha256: 'abc123',
        index: 0,
        total: 2,
        chunkBytes: Uint8List.fromList([10, 20]),
        jwtSupabase: 'jwt',
        tokenAppCheck: 'appcheck',
      );
      expect(resChunk0.finalizado, isFalse);
      expect(resChunk0.chunksRecebidos, equals([0]));

      final statusParcial = await fake.consultarStatusLaudo(
        idSessao: 's_chunk',
        sha256: 'abc123',
        jwtSupabase: 'jwt',
        tokenAppCheck: 'appcheck',
      );
      expect(statusParcial.jaEnviado, isFalse);
      expect(statusParcial.chunksRecebidos, equals([0]));

      final resChunk1 = await fake.enviarChunkEpub(
        idSessao: 's_chunk',
        sha256: 'abc123',
        index: 1,
        total: 2,
        chunkBytes: Uint8List.fromList([30, 40]),
        jwtSupabase: 'jwt',
        tokenAppCheck: 'appcheck',
      );
      expect(resChunk1.finalizado, isTrue);
      expect(resChunk1.versao, equals(1));

      final statusFinal = await fake.consultarStatusLaudo(
        idSessao: 's_chunk',
        sha256: 'abc123',
        jwtSupabase: 'jwt',
        tokenAppCheck: 'appcheck',
      );
      expect(statusFinal.jaEnviado, isTrue);
      expect(statusFinal.estaAtivo, isTrue);
      expect(statusFinal.verificacaoConcluida, greaterThan(0));
      expect(
        statusFinal.verificacaoConcluida,
        equals(statusFinal.verificacaoTotal),
      );

      // Simula erro HTTP >= 400 configurado por sessão
      fake.erroHttpPorSessao['s_erro_400'] = const ExcecaoApiFixalogNuvem(
        400,
        'Assinatura XML-DSig inválida.',
      );
      await expectLater(
        fake.consultarStatusLaudo(
          idSessao: 's_erro_400',
          jwtSupabase: 'jwt',
          tokenAppCheck: 'appcheck',
        ),
        throwsA(isA<ExcecaoApiFixalogNuvem>()),
      );
      await expectLater(
        fake.enviarChunkEpub(
          idSessao: 's_erro_400',
          sha256: 'abc',
          index: 0,
          total: 1,
          chunkBytes: Uint8List.fromList([1]),
          jwtSupabase: 'jwt',
          tokenAppCheck: 'appcheck',
        ),
        throwsA(isA<ExcecaoApiFixalogNuvem>()),
      );

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

      final fakeComAtraso = ClienteHttpFixalogNuvemFake(
        atrasoEnvioChunk: const Duration(milliseconds: 1),
      );
      final resComAtraso = await fakeComAtraso.enviarChunkEpub(
        idSessao: 's_atraso',
        sha256: 'hash_atraso',
        index: 0,
        total: 1,
        chunkBytes: Uint8List.fromList([1, 2]),
        jwtSupabase: 'jwt',
        tokenAppCheck: 'appcheck',
      );
      expect(resComAtraso.finalizado, isTrue);

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
        fake.consultarStatusLaudo(
          idSessao: 's1',
          sha256: 'h',
          jwtSupabase: 'jwt',
          tokenAppCheck: 'appcheck',
        ),
        throwsException,
      );
      await expectLater(
        fake.enviarChunkEpub(
          idSessao: 's1',
          sha256: 'h',
          index: 0,
          total: 1,
          chunkBytes: Uint8List(0),
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
