// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:typed_data';
import 'package:fixalog/core/services/sincronizador_nuvem_service.dart';

/// Implementação Fake determinística em memória de [ClienteHttpFixalogNuvem]
/// para testes de sincronização retomável em blocos, moderação, ordenação de materiais e restauração.
class ClienteHttpFixalogNuvemFake implements ClienteHttpFixalogNuvem {
  int statusEnvioPadrao;
  final Map<String, int> statusPorSessao = {};
  final List<String> ordemIdsEnviados = [];
  final List<int> indicesChunksEnviados = [];
  final Map<String, List<Uint8List>> versoesRecebidasPorSessao = {};
  final Map<String, Map<String, int>> versaoPorSessaoESha256 = {};
  final Map<String, Map<int, Uint8List>> _stagingChunksPorChave = {};
  final Map<String, int> consultasEmAnaliseAntesDeAtivar = {};
  final Map<String, String> statusModeracaoForcadoPorSessao = {};
  final List<MetadadosLaudoRemoto> laudosRemotosConta = [];
  final Map<String, Uint8List> epubsPublicosPorSessao = {};
  bool deveLancarErroRede;
  Duration? atrasoEnvioChunk;

  ClienteHttpFixalogNuvemFake({
    this.statusEnvioPadrao = 201,
    this.deveLancarErroRede = false,
    this.atrasoEnvioChunk,
  });

  String _chaveStaging(String idSessao, String sha256) => '$idSessao::$sha256';

  @override
  Future<int> enviarVersaoEpub({
    required String idSessao,
    required Uint8List epubBytes,
    required String jwtSupabase,
    required String tokenAppCheck,
  }) async {
    if (deveLancarErroRede) {
      throw Exception('Falha simulada de rede ao enviar EPUB.');
    }
    ordemIdsEnviados.add(idSessao);
    final status = statusPorSessao[idSessao] ?? statusEnvioPadrao;
    if (status == 200 || status == 201) {
      final hash = SincronizadorNuvemService.calcularSha256Hex(epubBytes);
      final mapaVersoes = versaoPorSessaoESha256.putIfAbsent(
        idSessao,
        () => <String, int>{},
      );
      if (!mapaVersoes.containsKey(hash)) {
        final lista = versoesRecebidasPorSessao.putIfAbsent(
          idSessao,
          () => <Uint8List>[],
        );
        lista.add(Uint8List.fromList(epubBytes));
        mapaVersoes[hash] = lista.length;
        epubsPublicosPorSessao[idSessao] = Uint8List.fromList(epubBytes);
      }
    }
    return status;
  }

  @override
  Future<StatusLaudoRemoto> consultarStatusLaudo({
    required String idSessao,
    String? sha256,
    required String jwtSupabase,
    required String tokenAppCheck,
  }) async {
    if (deveLancarErroRede) {
      throw Exception('Falha simulada de rede ao consultar status do laudo.');
    }
    final mapaVersoes = versaoPorSessaoESha256[idSessao] ?? const {};
    int? versaoEncontrada;
    if (sha256 != null && sha256.isNotEmpty) {
      versaoEncontrada = mapaVersoes[sha256];
    } else if (mapaVersoes.isNotEmpty) {
      versaoEncontrada = mapaVersoes.values.last;
    }

    final temShaEspecifico = sha256 != null && sha256.isNotEmpty;
    if (temShaEspecifico
        ? versaoEncontrada != null
        : (versaoEncontrada != null ||
              epubsPublicosPorSessao.containsKey(idSessao))) {
      final restantesEmAnalise = consultasEmAnaliseAntesDeAtivar[idSessao] ?? 0;
      String statusMod = statusModeracaoForcadoPorSessao[idSessao] ?? 'ativo';
      if (restantesEmAnalise > 0) {
        consultasEmAnaliseAntesDeAtivar[idSessao] = restantesEmAnalise - 1;
        statusMod = 'em_analise';
      }
      return StatusLaudoRemoto(
        idSessao: idSessao,
        sha256: sha256,
        jaEnviado: true,
        versao: versaoEncontrada ?? 1,
        statusModeracao: statusMod,
        chunksRecebidos: const [],
      );
    }

    final chave = _chaveStaging(idSessao, sha256 ?? '');
    final chunks = _stagingChunksPorChave[chave]?.keys.toList() ?? <int>[];
    chunks.sort();
    return StatusLaudoRemoto(
      idSessao: idSessao,
      sha256: sha256,
      jaEnviado: false,
      versao: null,
      statusModeracao: null,
      chunksRecebidos: chunks,
    );
  }

  @override
  Future<RespostaChunkLaudoRemoto> enviarChunkEpub({
    required String idSessao,
    required String sha256,
    required int index,
    required int total,
    required Uint8List chunkBytes,
    required String jwtSupabase,
    required String tokenAppCheck,
  }) async {
    if (atrasoEnvioChunk != null) {
      await Future<void>.delayed(atrasoEnvioChunk!);
    }
    if (deveLancarErroRede) {
      throw Exception('Falha simulada de rede ao enviar chunk de EPUB.');
    }
    indicesChunksEnviados.add(index);
    final chave = _chaveStaging(idSessao, sha256);
    final staging = _stagingChunksPorChave.putIfAbsent(
      chave,
      () => <int, Uint8List>{},
    );
    staging[index] = Uint8List.fromList(chunkBytes);

    final recebidos = staging.keys.toList()..sort();
    if (recebidos.length < total) {
      return RespostaChunkLaudoRemoto(
        statusHttp: 202,
        finalizado: false,
        jaEnviado: false,
        versao: null,
        statusModeracao: null,
        chunksRecebidos: recebidos,
      );
    }

    final builder = BytesBuilder(copy: false);
    for (int i = 0; i < total; i++) {
      builder.add(staging[i]!);
    }
    final completo = builder.takeBytes();
    _stagingChunksPorChave.remove(chave);

    ordemIdsEnviados.add(idSessao);
    final lista = versoesRecebidasPorSessao.putIfAbsent(
      idSessao,
      () => <Uint8List>[],
    );
    lista.add(completo);
    final novaVersao = lista.length;
    versaoPorSessaoESha256.putIfAbsent(
      idSessao,
      () => <String, int>{},
    )[sha256] = novaVersao;
    epubsPublicosPorSessao[idSessao] = completo;

    final statusMod =
        (consultasEmAnaliseAntesDeAtivar[idSessao] ?? 0) > 0
            ? 'em_analise'
            : (statusModeracaoForcadoPorSessao[idSessao] ?? 'ativo');

    return RespostaChunkLaudoRemoto(
      statusHttp: statusPorSessao[idSessao] ?? statusEnvioPadrao,
      finalizado: true,
      jaEnviado: true,
      versao: novaVersao,
      statusModeracao: statusMod,
      chunksRecebidos: const [],
    );
  }

  @override
  Future<List<MetadadosLaudoRemoto>> listarLaudosConta({
    required String jwtSupabase,
    required String tokenAppCheck,
  }) async {
    if (deveLancarErroRede) {
      throw Exception('Falha simulada de rede ao listar laudos.');
    }
    return List<MetadadosLaudoRemoto>.from(laudosRemotosConta);
  }

  @override
  Future<Uint8List?> baixarEpubPublico({required String idSessao}) async {
    if (deveLancarErroRede) {
      throw Exception('Falha simulada de rede ao baixar EPUB.');
    }
    return epubsPublicosPorSessao[idSessao];
  }
}
