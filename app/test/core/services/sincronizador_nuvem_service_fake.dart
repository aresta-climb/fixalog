// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:typed_data';
import 'package:fixalog/core/services/sincronizador_nuvem_service.dart';

/// Implementação Fake determinística em memória de [ClienteHttpFixalogNuvem]
/// para testes de sincronização, ordenação de materiais e restauração de conta.
class ClienteHttpFixalogNuvemFake implements ClienteHttpFixalogNuvem {
  int statusEnvioPadrao;
  final Map<String, int> statusPorSessao = {};
  final List<String> ordemIdsEnviados = [];
  final Map<String, List<Uint8List>> versoesRecebidasPorSessao = {};
  final List<MetadadosLaudoRemoto> laudosRemotosConta = [];
  final Map<String, Uint8List> epubsPublicosPorSessao = {};
  bool deveLancarErroRede;

  ClienteHttpFixalogNuvemFake({
    this.statusEnvioPadrao = 201,
    this.deveLancarErroRede = false,
  });

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
      versoesRecebidasPorSessao
          .putIfAbsent(idSessao, () => <Uint8List>[])
          .add(Uint8List.fromList(epubBytes));
      epubsPublicosPorSessao[idSessao] = Uint8List.fromList(epubBytes);
    }
    return status;
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
