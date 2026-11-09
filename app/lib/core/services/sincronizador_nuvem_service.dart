// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/local/submission_record.dart';
import 'autenticacao_nuvem_service.dart';
import 'banco_dados_local.dart';
import 'registro_logger.dart';

/// Metadados resumidos de um laudo remoto retornado por `GET /api/v1/laudos`.
class MetadadosLaudoRemoto {
  final String idSessao;
  final String categoria;
  final String idProtocolo;
  final String titulo;
  final int versaoAtual;
  final DateTime atualizadoEm;

  const MetadadosLaudoRemoto({
    required this.idSessao,
    required this.categoria,
    required this.idProtocolo,
    required this.titulo,
    required this.versaoAtual,
    required this.atualizadoEm,
  });

  factory MetadadosLaudoRemoto.deJson(Map<String, dynamic> json) {
    return MetadadosLaudoRemoto(
      idSessao: (json['id_sessao'] as String?) ?? '',
      categoria:
          (json['categoria'] as String?) ?? SubmissionTipoRegistro.manutencao,
      idProtocolo: (json['id_protocolo'] as String?) ?? 'manutencao_ferragens',
      titulo: (json['titulo'] as String?) ?? 'Laudo Técnico',
      versaoAtual: (json['versao_atual'] as num?)?.toInt() ?? 1,
      atualizadoEm:
          DateTime.tryParse((json['atualizado_em'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

/// Resultado de uma execução da fila de sincronização de laudos com a nuvem.
class ResultadoSincronizacaoNuvem {
  final int enviados;
  final int falhas;
  final List<String> idsEnviados;

  const ResultadoSincronizacaoNuvem({
    required this.enviados,
    required this.falhas,
    required this.idsEnviados,
  });
}

/// Interface de transporte HTTP para comunicação com o Cloudflare Worker `fixalog.app`.
abstract class ClienteHttpFixalogNuvem {
  Future<int> enviarVersaoEpub({
    required String idSessao,
    required Uint8List epubBytes,
    required String jwtSupabase,
    required String tokenAppCheck,
  });

  Future<List<MetadadosLaudoRemoto>> listarLaudosConta({
    required String jwtSupabase,
    required String tokenAppCheck,
  });

  Future<Uint8List?> baixarEpubPublico({required String idSessao});
}

/// Implementação padrão de [ClienteHttpFixalogNuvem] usando `HttpClient` nativo (`dart:io`).
class ClienteHttpFixalogNuvemPadrao implements ClienteHttpFixalogNuvem {
  final String urlBase;
  final HttpClient Function() _criadorHttpClient;

  ClienteHttpFixalogNuvemPadrao({
    this.urlBase = 'https://fixalog.app',
    HttpClient Function()? criadorHttpClient,
  }) : _criadorHttpClient = criadorHttpClient ?? HttpClient.new;

  @override
  Future<int> enviarVersaoEpub({
    required String idSessao,
    required Uint8List epubBytes,
    required String jwtSupabase,
    required String tokenAppCheck,
  }) async {
    final client = _criadorHttpClient();
    try {
      final uri = Uri.parse(
        '$urlBase/api/v1/laudos/${Uri.encodeComponent(idSessao)}',
      );
      final req = await client.putUrl(uri);
      req.headers.set('Content-Type', 'application/epub+zip');
      req.headers.set('Authorization', 'Bearer $jwtSupabase');
      req.headers.set('X-Firebase-AppCheck', tokenAppCheck);
      req.add(epubBytes);
      final res = await req.close();
      await res.drain<void>();
      return res.statusCode;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<List<MetadadosLaudoRemoto>> listarLaudosConta({
    required String jwtSupabase,
    required String tokenAppCheck,
  }) async {
    final client = _criadorHttpClient();
    try {
      final uri = Uri.parse('$urlBase/api/v1/laudos');
      final req = await client.getUrl(uri);
      req.headers.set('Authorization', 'Bearer $jwtSupabase');
      req.headers.set('X-Firebase-AppCheck', tokenAppCheck);
      final res = await req.close();
      final texto = await utf8.decoder.bind(res).join();
      if (res.statusCode != 200) {
        return const [];
      }
      final mapa = jsonDecode(texto) as Map<String, dynamic>;
      final lista = (mapa['laudos'] as List<dynamic>?) ?? const [];
      return lista
          .whereType<Map<String, dynamic>>()
          .map(MetadadosLaudoRemoto.deJson)
          .toList();
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<Uint8List?> baixarEpubPublico({required String idSessao}) async {
    final client = _criadorHttpClient();
    try {
      final uri = Uri.parse(
        '$urlBase/v/${Uri.encodeComponent(idSessao)}/epub',
      );
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) {
        await res.drain<void>();
        return null;
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in res) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
  }
}

/// Serviço offline-first de sincronização em segundo plano e restauração de pacotes
/// periciais `.epub` 3 com o Cloudflare Worker `fixalog.app`.
class SincronizadorNuvemService {
  final BancoDadosLocal? _banco;
  final AutenticacaoNuvemService _autenticacaoService;
  final ClienteHttpFixalogNuvem _clienteHttp;
  final RegistroLogger _logger;

  SincronizadorNuvemService({
    required BancoDadosLocal? banco,
    required AutenticacaoNuvemService autenticacaoService,
    ClienteHttpFixalogNuvem? clienteHttp,
    RegistroLogger? logger,
  })  : _banco = banco,
        _autenticacaoService = autenticacaoService,
        _clienteHttp = clienteHttp ?? ClienteHttpFixalogNuvemPadrao(),
        _logger = logger ?? RegistroLogger.instancia;

  /// Constrói a URL canônica pública de compartilhamento web de uma sessão.
  static String obterUrlCompartilhamentoPublico(String idSessao) {
    return 'https://fixalog.app/v/${Uri.encodeComponent(idSessao.trim())}';
  }

  /// Extrai os IDs de materiais aninhados (`OEBPS/materiais/<uuid>/`) de dentro de um `.epub`.
  static List<String> extrairIdsMateriaisAninhadosDoEpub(Uint8List epubBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(epubBytes);
      final ids = <String>{};
      final regex = RegExp(r'^OEBPS/materiais/([^/]+)/');
      for (final file in archive.files) {
        final match = regex.firstMatch(file.name);
        if (match != null) {
          ids.add(match.group(1)!);
        }
      }
      return ids.toList();
    } catch (_) {
      return const [];
    }
  }

  /// Envia todas as submissões geradas (`status == GERADO`) ainda pendentes (`enviadoNuvem == false`),
  /// garantindo que todos os pacotes `.epub` de `MATERIAL` sejam enviados antes das `MANUTENCAO`.
  Future<ResultadoSincronizacaoNuvem> sincronizarPendentes() async {
    final banco = _banco;
    if (banco == null) {
      return const ResultadoSincronizacaoNuvem(
        enviados: 0,
        falhas: 0,
        idsEnviados: [],
      );
    }

    final sessao = await _autenticacaoService.obterSessaoAtual();
    if (sessao == null) {
      return const ResultadoSincronizacaoNuvem(
        enviados: 0,
        falhas: 0,
        idsEnviados: [],
      );
    }

    final todas = await banco.listarSubmissoes();
    final pendentes = todas
        .where((r) => r.isGerado && !r.enviadoNuvem)
        .toList();

    // Ordena materiais primeiro, depois manutenções
    pendentes.sort((a, b) {
      if (a.isMaterial && !b.isMaterial) return -1;
      if (!a.isMaterial && b.isMaterial) return 1;
      return a.dataInclusao.compareTo(b.dataInclusao);
    });

    int enviados = 0;
    int falhas = 0;
    final idsEnviados = <String>[];

    for (final registro in pendentes) {
      final sucesso = await enviarSubmissao(registro);
      if (sucesso) {
        enviados++;
        idsEnviados.add(registro.idSessao);
      } else {
        falhas++;
      }
    }

    return ResultadoSincronizacaoNuvem(
      enviados: enviados,
      falhas: falhas,
      idsEnviados: idsEnviados,
    );
  }

  /// Envia uma submissão específica para a nuvem (enviando antes quaisquer materiais
  /// referenciados ainda não sincronizados) e marca `enviadoNuvem = true` no SQLite.
  Future<bool> enviarSubmissao(SubmissionRecord record) async {
    final banco = _banco;
    if (banco == null || !record.isGerado) {
      return false;
    }

    final sessao = await _autenticacaoService.obterSessaoAtual();
    if (sessao == null) {
      return false;
    }

    final caminhoEpub = record.epubPath.isNotEmpty
        ? record.epubPath
        : record.protobufPath;
    if (caminhoEpub.isEmpty) {
      return false;
    }
    final arquivoEpub = File(caminhoEpub);
    if (!arquivoEpub.existsSync()) {
      return false;
    }

    final epubBytes = arquivoEpub.readAsBytesSync();

    // Se for manutenção, garante que materiais referenciados locais sejam enviados antes
    if (record.isManutencao) {
      final idsMateriais = extrairIdsMateriaisAninhadosDoEpub(epubBytes);
      for (final idMat in idsMateriais) {
        final regMat = await banco.obterSubmissaoPorIdSessao(idMat);
        if (regMat != null && regMat.isGerado && !regMat.enviadoNuvem) {
          await enviarSubmissao(regMat);
        }
      }
    }

    try {
      final tokenAppCheck = await _autenticacaoService.obterTokenAppCheck();
      final status = await _clienteHttp.enviarVersaoEpub(
        idSessao: record.idSessao,
        epubBytes: epubBytes,
        jwtSupabase: sessao.jwtSupabase,
        tokenAppCheck: tokenAppCheck,
      );

      if (status == 200 || status == 201) {
        record.enviadoNuvem = true;
        await banco.salvarSubmissao(record);
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.logFalhaSyncOuDownload(
        'Falha ao enviar pacote EPUB (${record.idSessao}) para a nuvem',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Restaura do servidor todos os laudos e materiais da conta autenticada que
  /// ainda não existam localmente no dispositivo, salvando o `.epub` e o `registro.binarypb`.
  Future<int> restaurarRelatoriosDaConta({
    required Directory diretorioBase,
  }) async {
    final banco = _banco;
    if (banco == null) {
      return 0;
    }

    final sessao = await _autenticacaoService.obterSessaoAtual();
    if (sessao == null) {
      return 0;
    }

    try {
      final tokenAppCheck = await _autenticacaoService.obterTokenAppCheck();
      final remotos = await _clienteHttp.listarLaudosConta(
        jwtSupabase: sessao.jwtSupabase,
        tokenAppCheck: tokenAppCheck,
      );

      int restaurados = 0;
      for (final remoto in remotos) {
        final existente = await banco.obterSubmissaoPorIdSessao(
          remoto.idSessao,
        );
        if (existente != null && existente.enviadoNuvem) {
          continue;
        }

        final epubBytes = await _clienteHttp.baixarEpubPublico(
          idSessao: remoto.idSessao,
        );
        if (epubBytes == null || epubBytes.isEmpty) {
          continue;
        }

        final dirSessao = Directory(
          p.join(diretorioBase.path, 'sessoes', remoto.idSessao),
        );
        if (!dirSessao.existsSync()) {
          dirSessao.createSync(recursive: true);
        }

        final arquivoEpub = File(p.join(dirSessao.path, 'relatorio.epub'));
        arquivoEpub.writeAsBytesSync(epubBytes);

        // Extrai OEBPS/dados/registro.binarypb se presente no pacote EPUB
        try {
          final archive = ZipDecoder().decodeBytes(epubBytes);
          for (final arq in archive.files) {
            if (arq.name == 'OEBPS/dados/registro.binarypb' && arq.isFile) {
              final pbFile = File(p.join(dirSessao.path, 'registro.binarypb'));
              pbFile.writeAsBytesSync(arq.content as List<int>);
              break;
            }
          }
        } catch (_) {}

        final novo = existente ?? SubmissionRecord();
        novo
          ..idSessao = remoto.idSessao
          ..idProtocolo = remoto.idProtocolo
          ..nomeProtocolo = remoto.titulo
          ..tituloExibicao = remoto.titulo
          ..tipoRegistro = remoto.categoria
          ..dataInclusao = remoto.atualizadoEm
          ..epubPath = arquivoEpub.path
          ..protobufPath = p.join(dirSessao.path, 'registro.binarypb')
          ..enviadoNuvem = true
          ..status = SubmissionStatus.gerado;

        await banco.salvarSubmissao(novo);
        restaurados++;
      }

      return restaurados;
    } catch (e, stackTrace) {
      _logger.logFalhaSyncOuDownload(
        'Falha ao restaurar relatórios da conta na nuvem',
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }
}

final sincronizadorNuvemServiceProvider = Provider<SincronizadorNuvemService>((
  ref,
) {
  final banco = ref.watch(bancoDadosLocalProvider);
  final autenticacao = ref.watch(autenticacaoNuvemServiceProvider);
  return SincronizadorNuvemService(
    banco: banco,
    autenticacaoService: autenticacao,
  );
});
