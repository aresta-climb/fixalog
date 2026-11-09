// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/local/feedback_record.dart';
import '../../../core/services/autenticacao_nuvem_service.dart';
import '../../../core/services/banco_dados_local.dart';
import '../../../core/services/classificador_dispositivo.dart';
import '../../../core/services/registro_logger.dart';
import '../../../core/services/servico_configuracao_remota.dart';
import '../utils/compressor_imagem_feedback.dart';

/// Serviço offline-first responsável por comprimir, persistir localmente no `BancoDadosLocal` (SQLite)
/// e despachar em segundo plano os relatos de feedback in-app autenticados via Firebase App Check.
class ServicoFilaFeedback {
  /// Nome do subdiretório onde as capturas de tela comprimidas aguardam envio.
  static const String nomeDiretorioFila = 'feedback_queue';

  final BancoDadosLocal? _banco;
  final AutenticacaoNuvemService? _autenticacaoService;
  final CompressorImagemFeedback _compressorImagem;
  final RegistroLogger _logger;
  final http.Client _clienteHttp;
  final Future<Directory> Function() _obterDiretorioSuporte;
  final String Function() _geradorIdFeedback;
  final String? _urlEdgeFunctionOverride;

  /// Cria uma instância de [ServicoFilaFeedback] com dependências injetáveis para testes.
  ServicoFilaFeedback({
    required BancoDadosLocal? banco,
    AutenticacaoNuvemService? autenticacaoService,
    CompressorImagemFeedback? compressorImagem,
    RegistroLogger? logger,
    http.Client? clienteHttp,
    Future<Directory> Function()? obterDiretorioSuporte,
    String Function()? geradorIdFeedback,
    String? urlEdgeFunction,
  })  : _banco = banco,
        _autenticacaoService = autenticacaoService,
        _compressorImagem = compressorImagem ?? CompressorImagemFeedback(),
        _logger = logger ?? RegistroLogger.instancia,
        _clienteHttp = clienteHttp ?? http.Client(),
        _obterDiretorioSuporte =
            obterDiretorioSuporte ?? getApplicationSupportDirectory,
        _geradorIdFeedback = geradorIdFeedback ?? const Uuid().v4,
        _urlEdgeFunctionOverride = urlEdgeFunction;

  String _obterUrlEdgeFunction() {
    if (_urlEdgeFunctionOverride != null &&
        _urlEdgeFunctionOverride.trim().isNotEmpty) {
      return _urlEdgeFunctionOverride;
    }
    return ServicoConfiguracaoRemota.instancia.urlFeedbackEdgeFunction;
  }

  Future<Directory> _garantirDiretorioFila() async {
    final baseDir = await _obterDiretorioSuporte();
    final dirFila = Directory(p.join(baseDir.path, nomeDiretorioFila));
    if (!dirFila.existsSync()) {
      dirFila.createSync(recursive: true);
    }
    return dirFila;
  }

  /// Comprime a [capturaTela], persiste o [FeedbackRecord] na tabela `fila_feedback` do SQLite
  /// e dispara uma tentativa imediata de envio em segundo plano quando [despacharImediatamente] for `true`.
  Future<FeedbackRecord> enfileirarEDespacharFeedback({
    required String mensagem,
    required Uint8List capturaTela,
    String categoria = 'aplicativo',
    Map<String, Object?>? metadadosExtras,
    bool despacharImediatamente = true,
  }) async {
    final idFeedback = _geradorIdFeedback();
    final agoraUtc = DateTime.now().toUtc();

    String caminhoImagem = '';
    if (capturaTela.isNotEmpty) {
      final resultado = await _compressorImagem.comprimirParaWebp(capturaTela);
      final dirFila = await _garantirDiretorioFila();
      final arquivoImagem = File(
        p.join(dirFila.path, '$idFeedback.${resultado.extensao}'),
      );
      arquivoImagem.writeAsBytesSync(resultado.bytes);
      caminhoImagem = arquivoImagem.path;
    }

    final identidade = await _banco?.obterIdentidadeAtual();
    final sessaoOidc = await _autenticacaoService?.obterSessaoAtual();

    final metadados = <String, Object?>{
      'app': 'fixalog',
      'feedbackId': idFeedback,
      'categoria': categoria,
      'submittedAt': agoraUtc.toIso8601String(),
      'tier_dispositivo': ClassificadorDispositivo.instancia.tierDispositivo,
      'ram_gb': ClassificadorDispositivo.instancia.ramGb,
      if (identidade != null && identidade.nome.isNotEmpty)
        'autor_nome': identidade.nome,
      if (identidade != null && identidade.clubeAssociacao.isNotEmpty)
        'clube': identidade.clubeAssociacao,
      if (sessaoOidc != null && sessaoOidc.userId.isNotEmpty)
        'user_id': sessaoOidc.userId,
      ...?metadadosExtras,
    };

    final registro = FeedbackRecord(
      idFeedback: idFeedback,
      mensagem: mensagem.trim(),
      categoria: categoria,
      caminhoImagem: caminhoImagem,
      metadadosJson: jsonEncode(metadados),
      dataCriacao: agoraUtc,
      enviado: false,
    );

    if (_banco != null) {
      await _banco.inserirFeedback(registro);
    }

    _logger.logInfo(
      '💬 [ServicoFilaFeedback] Feedback ($idFeedback) enfileirado localmente.',
    );

    if (despacharImediatamente) {
      await processarFilaPendentes();
    }

    return registro;
  }

  /// Processa todos os feedbacks com `enviado = 0` no `BancoDadosLocal`,
  /// marcando-os como enviados e removendo o arquivo de imagem local após sucesso.
  Future<int> processarFilaPendentes() async {
    if (_banco == null) return 0;

    final pendentes = await _banco.listarFeedbacksPendentes();
    var totalEnviados = 0;

    for (final item in pendentes) {
      final enviadoComSucesso = await enviarItemFeedback(item);
      if (enviadoComSucesso) {
        await _banco.marcarFeedbackEnviado(item.id);
        if (item.caminhoImagem.isNotEmpty) {
          final arquivo = File(item.caminhoImagem);
          if (arquivo.existsSync()) {
            arquivo.deleteSync();
          }
        }
        totalEnviados++;
      }
    }

    return totalEnviados;
  }

  /// Envia um único [FeedbackRecord] via requisição HTTP `multipart/form-data`
  /// autenticada com o cabeçalho `X-Firebase-AppCheck`.
  Future<bool> enviarItemFeedback(FeedbackRecord item) async {
    try {
      final uri = Uri.parse(_obterUrlEdgeFunction());
      final request = http.MultipartRequest('POST', uri);

      final tokenAppCheck = await _autenticacaoService?.obterTokenAppCheck();
      if (tokenAppCheck != null && tokenAppCheck.isNotEmpty) {
        request.headers['X-Firebase-AppCheck'] = tokenAppCheck;
      }

      request.fields['description'] = item.mensagem;
      request.fields['category'] = item.categoria;
      request.fields['metadata'] = item.metadadosJson;

      if (item.caminhoImagem.isNotEmpty) {
        final arquivo = File(item.caminhoImagem);
        if (arquivo.existsSync()) {
          final ehWebp = arquivo.path.toLowerCase().endsWith('.webp');
          request.files.add(
            await http.MultipartFile.fromPath(
              'screenshot',
              arquivo.path,
              filename: ehWebp ? 'screenshot.webp' : 'screenshot.png',
              contentType: MediaType('image', ehWebp ? 'webp' : 'png'),
            ),
          );
        }
      }

      final respostaStream = await _clienteHttp.send(request);
      final corpo = await respostaStream.stream.bytesToString();

      if (respostaStream.statusCode >= 200 && respostaStream.statusCode < 300) {
        _logger.logInfo(
          '💬 [ServicoFilaFeedback] Feedback (${item.idFeedback}) transmitido com sucesso.',
        );
        return true;
      }

      throw HttpException(
        'HTTP ${respostaStream.statusCode}: $corpo',
        uri: uri,
      );
    } catch (e, stackTrace) {
      _logger.logFalhaSyncOuDownload(
        'Falha ao despachar feedback (${item.idFeedback}) para a nuvem',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

/// Provedor Riverpod do [ServicoFilaFeedback].
final servicoFilaFeedbackProvider = Provider<ServicoFilaFeedback>((ref) {
  final banco = ref.watch(bancoDadosLocalProvider);
  final auth = ref.watch(autenticacaoNuvemServiceProvider);
  return ServicoFilaFeedback(
    banco: banco,
    autenticacaoService: auth,
  );
});
