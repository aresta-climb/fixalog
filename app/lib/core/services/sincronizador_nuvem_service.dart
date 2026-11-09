// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/local/submission_record.dart';
import 'autenticacao_nuvem_service.dart';
import 'banco_dados_local.dart';
import 'registro_logger.dart';
import 'servico_telemetria.dart';

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

/// Status remoto de uma versão ou upload retomável retornado por `GET /api/v1/laudos/:id/status`.
class StatusLaudoRemoto {
  final String idSessao;
  final String? sha256;
  final bool jaEnviado;
  final int? versao;
  final String? statusModeracao;
  final List<int> chunksRecebidos;

  const StatusLaudoRemoto({
    required this.idSessao,
    required this.sha256,
    required this.jaEnviado,
    required this.versao,
    required this.statusModeracao,
    required this.chunksRecebidos,
  });

  bool get estaAtivo => statusModeracao == 'ativo';

  factory StatusLaudoRemoto.deJson(Map<String, dynamic> json) {
    final chunks = (json['chunks_recebidos'] as List<dynamic>?) ?? const [];
    return StatusLaudoRemoto(
      idSessao: (json['id_sessao'] as String?) ?? '',
      sha256: json['sha256'] as String?,
      jaEnviado: (json['ja_enviado'] as bool?) ?? false,
      versao: (json['versao'] as num?)?.toInt(),
      statusModeracao: json['status_moderacao'] as String?,
      chunksRecebidos: chunks.whereType<num>().map((e) => e.toInt()).toList(),
    );
  }
}

/// Resposta do envio de um bloco (`PUT /api/v1/laudos/:id/chunk`).
class RespostaChunkLaudoRemoto {
  final int statusHttp;
  final bool finalizado;
  final bool jaEnviado;
  final int? versao;
  final String? statusModeracao;
  final List<int> chunksRecebidos;

  const RespostaChunkLaudoRemoto({
    required this.statusHttp,
    required this.finalizado,
    required this.jaEnviado,
    required this.versao,
    required this.statusModeracao,
    required this.chunksRecebidos,
  });

  factory RespostaChunkLaudoRemoto.deJson(
    int statusHttp,
    Map<String, dynamic> json,
  ) {
    final chunks = (json['chunks_recebidos'] as List<dynamic>?) ?? const [];
    return RespostaChunkLaudoRemoto(
      statusHttp: statusHttp,
      finalizado: (json['finalizado'] as bool?) ?? false,
      jaEnviado: (json['ja_enviado'] as bool?) ?? false,
      versao: (json['versao'] as num?)?.toInt(),
      statusModeracao: json['status_moderacao'] as String?,
      chunksRecebidos: chunks.whereType<num>().map((e) => e.toInt()).toList(),
    );
  }
}

/// Etapas observáveis do fluxo de publicação e liberação do link público de um laudo.
enum EtapaPublicacaoLaudo {
  enviandoBlocos,
  aguardandoVerificacaoServidor,
  concluidoAtivo,
  semInternet,
  rejeitadoOuFalha,
}

/// Estado de progresso observável da publicação de um laudo na nuvem.
class ProgressoPublicacaoLaudo {
  final String idSessao;
  final EtapaPublicacaoLaudo etapa;
  final int blocosEnviados;
  final int totalBlocos;
  final String? mensagemErro;

  const ProgressoPublicacaoLaudo({
    required this.idSessao,
    required this.etapa,
    required this.blocosEnviados,
    required this.totalBlocos,
    this.mensagemErro,
  });

  double get fracaoBlocos =>
      totalBlocos <= 0 ? 0.0 : (blocosEnviados / totalBlocos).clamp(0.0, 1.0);
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

  Future<StatusLaudoRemoto> consultarStatusLaudo({
    required String idSessao,
    String? sha256,
    required String jwtSupabase,
    required String tokenAppCheck,
  });

  Future<RespostaChunkLaudoRemoto> enviarChunkEpub({
    required String idSessao,
    required String sha256,
    required int index,
    required int total,
    required Uint8List chunkBytes,
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
  Future<StatusLaudoRemoto> consultarStatusLaudo({
    required String idSessao,
    String? sha256,
    required String jwtSupabase,
    required String tokenAppCheck,
  }) async {
    final client = _criadorHttpClient();
    try {
      final query = (sha256 != null && sha256.isNotEmpty)
          ? '?sha256=${Uri.encodeQueryComponent(sha256)}'
          : '';
      final uri = Uri.parse(
        '$urlBase/api/v1/laudos/${Uri.encodeComponent(idSessao)}/status$query',
      );
      final req = await client.getUrl(uri);
      req.headers.set('Authorization', 'Bearer $jwtSupabase');
      req.headers.set('X-Firebase-AppCheck', tokenAppCheck);
      final res = await req.close();
      final texto = await utf8.decoder.bind(res).join();
      final mapa = jsonDecode(texto) as Map<String, dynamic>;
      return StatusLaudoRemoto.deJson(mapa);
    } finally {
      client.close(force: true);
    }
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
    final client = _criadorHttpClient();
    try {
      final uri = Uri.parse(
        '$urlBase/api/v1/laudos/${Uri.encodeComponent(idSessao)}/chunk'
        '?sha256=${Uri.encodeQueryComponent(sha256)}&index=$index&total=$total',
      );
      final req = await client.putUrl(uri);
      req.headers.set('Content-Type', 'application/octet-stream');
      req.headers.set('Authorization', 'Bearer $jwtSupabase');
      req.headers.set('X-Firebase-AppCheck', tokenAppCheck);
      req.add(chunkBytes);
      final res = await req.close();
      final texto = await utf8.decoder.bind(res).join();
      final mapa = jsonDecode(texto) as Map<String, dynamic>;
      return RespostaChunkLaudoRemoto.deJson(res.statusCode, mapa);
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

/// Serviço offline-first de sincronização retomável em blocos (`512 KB`),
/// verificação de moderação e restauração de pacotes periciais `.epub` 3 com `fixalog.app`.
class SincronizadorNuvemService {
  /// Tamanho padrão de cada bloco de upload retomável (`512 KB` = `524.288 bytes`).
  static const int tamanhoPadraoBlocoBytes = 512 * 1024;

  final BancoDadosLocal? _banco;
  final AutenticacaoNuvemService _autenticacaoService;
  final ClienteHttpFixalogNuvem _clienteHttp;
  final RegistroLogger _logger;
  final int _tamanhoBlocoBytes;
  final Duration _intervaloPollingModeracao;
  final int _maxTentativasPollingModeracao;
  final bool _emModoDesenvolvimento;

  final Map<String, Future<bool>> _uploadsEmAndamento = {};
  final Map<String, ProgressoPublicacaoLaudo> _progressoPorSessao = {};
  final StreamController<ProgressoPublicacaoLaudo> _controladorProgresso =
      StreamController<ProgressoPublicacaoLaudo>.broadcast(sync: true);

  SincronizadorNuvemService({
    required BancoDadosLocal? banco,
    required AutenticacaoNuvemService autenticacaoService,
    ClienteHttpFixalogNuvem? clienteHttp,
    RegistroLogger? logger,
    int tamanhoBlocoBytes = tamanhoPadraoBlocoBytes,
    Duration intervaloPollingModeracao = const Duration(seconds: 2),
    int maxTentativasPollingModeracao = 30,
    bool emModoDesenvolvimento = kModoDesenvolvimento,
  })  : _banco = banco,
        _autenticacaoService = autenticacaoService,
        _clienteHttp = clienteHttp ?? ClienteHttpFixalogNuvemPadrao(),
        _logger = logger ?? RegistroLogger.instancia,
        _tamanhoBlocoBytes = tamanhoBlocoBytes,
        _intervaloPollingModeracao = intervaloPollingModeracao,
        _maxTentativasPollingModeracao = maxTentativasPollingModeracao,
        _emModoDesenvolvimento = emModoDesenvolvimento;

  /// Constrói a URL canônica pública de compartilhamento web de uma sessão.
  static String obterUrlCompartilhamentoPublico(String idSessao) {
    return 'https://fixalog.app/v/${Uri.encodeComponent(idSessao.trim())}';
  }

  /// Calcula o hash criptográfico SHA-256 hexadecimal de um pacote `.epub`.
  static String calcularSha256Hex(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Constrói o texto descritivo rico para compartilhamento do link público no WhatsApp/mensageiros.
  static String construirResumoCompartilhamento({
    required String idSessao,
    String? titulo,
    Uint8List? epubBytes,
  }) {
    final url = obterUrlCompartilhamentoPublico(idSessao);
    String nomeProtocolo = '';
    String tituloEspecifico = (titulo ?? '').trim();
    String autorLinha = '';

    if (epubBytes != null && epubBytes.isNotEmpty) {
      try {
        final archive = ZipDecoder().decodeBytes(epubBytes);
        for (final file in archive.files) {
          if (file.name == 'OEBPS/relatorio.xhtml' && file.isFile) {
            final xhtml = utf8.decode(
              file.content as List<int>,
              allowMalformed: true,
            );
            final h1 = RegExp(
              r'<h1[^>]*>([\s\S]*?)<\/h1>',
              caseSensitive: false,
            ).firstMatch(xhtml);
            final h2 = RegExp(
              r'<h2[^>]*>([\s\S]*?)<\/h2>',
              caseSensitive: false,
            ).firstMatch(xhtml);
            final mant = RegExp(
              r'Mantenedor[^:<]*:\s*([^<\n]+)',
              caseSensitive: false,
            ).firstMatch(xhtml);

            if (h1 != null) {
              nomeProtocolo = h1
                  .group(1)!
                  .replaceAll(RegExp(r'<[^>]+>'), '')
                  .trim();
            }
            if (h2 != null) {
              final extraido = h2
                  .group(1)!
                  .replaceAll(RegExp(r'<[^>]+>'), '')
                  .trim();
              if (extraido.isNotEmpty) {
                tituloEspecifico = extraido;
              }
            }
            if (mant != null) {
              autorLinha = mant.group(1)!.trim();
            }
            break;
          }
        }
      } catch (_) {}
    }

    final cabecalho =
        (nomeProtocolo.isNotEmpty &&
            tituloEspecifico.isNotEmpty &&
            nomeProtocolo.toLowerCase() != tituloEspecifico.toLowerCase())
        ? '$nomeProtocolo — $tituloEspecifico'
        : (tituloEspecifico.isNotEmpty ? tituloEspecifico : 'Laudo Técnico Fixalog');

    final linhas = <String>[
      '📋 *$cabecalho*',
      if (autorLinha.isNotEmpty) '👤 Mantenedor: $autorLinha',
      '🔒 Laudo pericial assinado digitalmente (ECDSA P-256)',
      '🔗 $url',
    ];
    return linhas.join('\n');
  }

  /// Retorna o último estado de progresso registrado para [idSessao], se houver.
  ProgressoPublicacaoLaudo? obterProgressoAtual(String idSessao) {
    return _progressoPorSessao[idSessao];
  }

  /// Observa atualizações em tempo real do progresso de publicação de [idSessao].
  Stream<ProgressoPublicacaoLaudo> observarProgresso(String idSessao) {
    return _controladorProgresso.stream.where((p) => p.idSessao == idSessao);
  }

  void _emitirProgresso(ProgressoPublicacaoLaudo progresso) {
    _progressoPorSessao[progresso.idSessao] = progresso;
    _controladorProgresso.add(progresso);
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

    unawaited(
      ServicoTelemetria.instancia.registrarSincronizacaoNuvem(
        enviados: enviados,
        falhas: falhas,
      ),
    );

    return ResultadoSincronizacaoNuvem(
      enviados: enviados,
      falhas: falhas,
      idsEnviados: idsEnviados,
    );
  }

  /// Envia uma submissão específica para a nuvem usando protocolo retomável em blocos de `512 KB`
  /// (enviando antes quaisquer materiais referenciados ainda não sincronizados) e deduplicando
  /// chamadas concorrentes (*single-flight*) para o mesmo `idSessao`.
  Future<bool> enviarSubmissao(SubmissionRecord record) {
    final emAndamento = _uploadsEmAndamento[record.idSessao];
    if (emAndamento != null) {
      return emAndamento;
    }
    final futuro = _executarEnvioSubmissao(record);
    _uploadsEmAndamento[record.idSessao] = futuro;
    return futuro.whenComplete(() {
      _uploadsEmAndamento.remove(record.idSessao);
    });
  }

  Future<bool> _executarEnvioSubmissao(SubmissionRecord record) async {
    final banco = _banco;
    if (!record.isGerado) {
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
    if (record.isManutencao && banco != null) {
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
      final totalBlocos = (epubBytes.length / _tamanhoBlocoBytes).ceil().clamp(
        1,
        1000000,
      );

      if (_emModoDesenvolvimento &&
          !AutenticacaoNuvemService.possuiTokenAppCheckReal(tokenAppCheck)) {
        _logger.logInfo(
          '📝 [DEBUG MOCK] Upload de laudo concluído localmente (App Check não registrado em dev): ${record.idSessao}',
        );
        record.enviadoNuvem = true;
        if (banco != null) {
          await banco.salvarSubmissao(record);
        }
        _emitirProgresso(
          ProgressoPublicacaoLaudo(
            idSessao: record.idSessao,
            etapa: EtapaPublicacaoLaudo.concluidoAtivo,
            blocosEnviados: totalBlocos,
            totalBlocos: totalBlocos,
          ),
        );
        return true;
      }

      final hashSha256 = calcularSha256Hex(epubBytes);

      final statusRemoto = await _clienteHttp.consultarStatusLaudo(
        idSessao: record.idSessao,
        sha256: hashSha256,
        jwtSupabase: sessao.jwtSupabase,
        tokenAppCheck: tokenAppCheck,
      );

      if (statusRemoto.jaEnviado) {
        record.enviadoNuvem = true;
        if (banco != null) {
          await banco.salvarSubmissao(record);
        }
        _emitirProgresso(
          ProgressoPublicacaoLaudo(
            idSessao: record.idSessao,
            etapa: statusRemoto.estaAtivo
                ? EtapaPublicacaoLaudo.concluidoAtivo
                : EtapaPublicacaoLaudo.aguardandoVerificacaoServidor,
            blocosEnviados: totalBlocos,
            totalBlocos: totalBlocos,
          ),
        );
        return true;
      }

      final recebidos = statusRemoto.chunksRecebidos.toSet();
      int concluidos = recebidos.length.clamp(0, totalBlocos);
      _emitirProgresso(
        ProgressoPublicacaoLaudo(
          idSessao: record.idSessao,
          etapa: EtapaPublicacaoLaudo.enviandoBlocos,
          blocosEnviados: concluidos,
          totalBlocos: totalBlocos,
        ),
      );

      String? ultimoStatusModeracao;
      for (int i = 0; i < totalBlocos; i++) {
        if (recebidos.contains(i)) {
          continue;
        }
        final inicio = i * _tamanhoBlocoBytes;
        final fim = (inicio + _tamanhoBlocoBytes < epubBytes.length)
            ? inicio + _tamanhoBlocoBytes
            : epubBytes.length;
        final fatia = Uint8List.sublistView(epubBytes, inicio, fim);

        final resChunk = await _clienteHttp.enviarChunkEpub(
          idSessao: record.idSessao,
          sha256: hashSha256,
          index: i,
          total: totalBlocos,
          chunkBytes: fatia,
          jwtSupabase: sessao.jwtSupabase,
          tokenAppCheck: tokenAppCheck,
        );

        ultimoStatusModeracao = resChunk.statusModeracao;
        concluidos++;
        _emitirProgresso(
          ProgressoPublicacaoLaudo(
            idSessao: record.idSessao,
            etapa: (concluidos >= totalBlocos)
                ? (ultimoStatusModeracao == 'ativo'
                      ? EtapaPublicacaoLaudo.concluidoAtivo
                      : EtapaPublicacaoLaudo.aguardandoVerificacaoServidor)
                : EtapaPublicacaoLaudo.enviandoBlocos,
            blocosEnviados: concluidos,
            totalBlocos: totalBlocos,
          ),
        );
      }

      record.enviadoNuvem = true;
      if (banco != null) {
        await banco.salvarSubmissao(record);
      }
      return true;
    } catch (e, stackTrace) {
      _logger.logFalhaSyncOuDownload(
        'Falha ao enviar pacote EPUB (${record.idSessao}) para a nuvem',
        error: e,
        stackTrace: stackTrace,
      );
      _emitirProgresso(
        ProgressoPublicacaoLaudo(
          idSessao: record.idSessao,
          etapa: EtapaPublicacaoLaudo.semInternet,
          blocosEnviados: 0,
          totalBlocos: 1,
          mensagemErro: e.toString(),
        ),
      );
      return false;
    }
  }

  /// Garante que o laudo [idSessao] seja enviado para a nuvem (retomando se necessário) e
  /// aguarda até que o servidor confirme `status_moderacao == 'ativo'` antes de liberar o link.
  Future<ProgressoPublicacaoLaudo> publicarEAguardarLiberacao({
    required String idSessao,
    String? epubPath,
    void Function(ProgressoPublicacaoLaudo progresso)? aoProgredir,
  }) async {
    StreamSubscription<ProgressoPublicacaoLaudo>? inscricao;
    if (aoProgredir != null) {
      inscricao = observarProgresso(idSessao).listen(aoProgredir);
    }

    try {
      var sessao = await _autenticacaoService.obterSessaoAtual();
      sessao ??= await _autenticacaoService.entrarComProvedorOidc(
        ProvedorOidc.google,
      );

      final banco = _banco;
      final registroBanco = banco?.obterSubmissaoPorIdSessaoSync(idSessao);
      final caminhoEfetivo = (epubPath != null && epubPath.isNotEmpty)
          ? epubPath
          : (registroBanco?.epubPath ?? '');
      final registro =
          registroBanco ??
          (caminhoEfetivo.isNotEmpty
              ? (SubmissionRecord()
                  ..idSessao = idSessao
                  ..status = SubmissionStatus.gerado
                  ..tipoRegistro = SubmissionTipoRegistro.manutencao
                  ..epubPath = caminhoEfetivo)
              : null);

      final hashSha256 =
          (caminhoEfetivo.isNotEmpty && File(caminhoEfetivo).existsSync())
          ? calcularSha256Hex(File(caminhoEfetivo).readAsBytesSync())
          : null;

      for (int tentativa = 0;
          tentativa < _maxTentativasPollingModeracao;
          tentativa++) {
        final tokenAppCheck = await _autenticacaoService.obterTokenAppCheck();
        if (_emModoDesenvolvimento &&
            !AutenticacaoNuvemService.possuiTokenAppCheckReal(tokenAppCheck)) {
          if (registro != null && !registro.enviadoNuvem) {
            await enviarSubmissao(registro);
          }
          final concluidoMock = ProgressoPublicacaoLaudo(
            idSessao: idSessao,
            etapa: EtapaPublicacaoLaudo.concluidoAtivo,
            blocosEnviados: 1,
            totalBlocos: 1,
          );
          _emitirProgresso(concluidoMock);
          return concluidoMock;
        }
        final status = await _clienteHttp.consultarStatusLaudo(
          idSessao: idSessao,
          sha256: hashSha256,
          jwtSupabase: sessao.jwtSupabase,
          tokenAppCheck: tokenAppCheck,
        );

        if (!status.jaEnviado && registro != null) {
          registro.enviadoNuvem = false;
          if (!await enviarSubmissao(registro)) {
            throw StateError('Falha no envio dos blocos do laudo.');
          }
          continue;
        }

        if (status.estaAtivo) {
          final concluido = ProgressoPublicacaoLaudo(
            idSessao: idSessao,
            etapa: EtapaPublicacaoLaudo.concluidoAtivo,
            blocosEnviados: 1,
            totalBlocos: 1,
          );
          _emitirProgresso(concluido);
          return concluido;
        }

        if (status.statusModeracao == 'rejeitado') {
          final rejeitado = ProgressoPublicacaoLaudo(
            idSessao: idSessao,
            etapa: EtapaPublicacaoLaudo.rejeitadoOuFalha,
            blocosEnviados: 1,
            totalBlocos: 1,
            mensagemErro:
                'O laudo não pôde ser publicado pela verificação de segurança.',
          );
          _emitirProgresso(rejeitado);
          return rejeitado;
        }

        _emitirProgresso(
          ProgressoPublicacaoLaudo(
            idSessao: idSessao,
            etapa: EtapaPublicacaoLaudo.aguardandoVerificacaoServidor,
            blocosEnviados: 1,
            totalBlocos: 1,
          ),
        );
        await Future<void>.delayed(_intervaloPollingModeracao);
      }

      final tempoEsgotado = ProgressoPublicacaoLaudo(
        idSessao: idSessao,
        etapa: EtapaPublicacaoLaudo.rejeitadoOuFalha,
        blocosEnviados: 1,
        totalBlocos: 1,
        mensagemErro:
            'A verificação do laudo no servidor ainda está em processamento. Tente compartilhar novamente em instantes.',
      );
      _emitirProgresso(tempoEsgotado);
      return tempoEsgotado;
    } catch (e) {
      final semRede = ProgressoPublicacaoLaudo(
        idSessao: idSessao,
        etapa: EtapaPublicacaoLaudo.semInternet,
        blocosEnviados: 0,
        totalBlocos: 1,
        mensagemErro: e.toString(),
      );
      _emitirProgresso(semRede);
      return semRede;
    } finally {
      unawaited(inscricao?.cancel());
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
      if (_emModoDesenvolvimento &&
          !AutenticacaoNuvemService.possuiTokenAppCheckReal(tokenAppCheck)) {
        _logger.logInfo(
          '📝 [DEBUG MOCK] Restauração de relatórios concluída localmente (App Check não registrado em dev).',
        );
        return 0;
      }
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
