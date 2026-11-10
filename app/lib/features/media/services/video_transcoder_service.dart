// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Assinatura da função executora de comandos FFmpeg (permite injeção em testes).
typedef ExecutadorFfmpeg = Future<bool> Function(String comando);

/// Assinatura da função inspetora da duração de um arquivo de vídeo em segundos.
typedef InspetorDuracaoVideo = Future<double?> Function(File arquivoVideo);

/// Limite máximo canônico de duração (em segundos) para vídeos anexados em laudos do Fixalog.
const double limiteMaximoDuracaoVideoSegundos = 60.0;

/// Serviço responsável pela transcodificação padronizada de vídeos de inspeção,
/// corte de trechos selecionados (máximo 60s), garantia de I-Frames a cada 10s (`-g 300`)
/// e extração de poster frames estáticos para o relatório EPUB 3 e PDF.
class VideoTranscoderService {
  final ExecutadorFfmpeg _executador;
  final InspetorDuracaoVideo _inspetorDuracao;

  VideoTranscoderService({
    ExecutadorFfmpeg? executador,
    InspetorDuracaoVideo? inspetorDuracao,
  })  : _executador = executador ?? executarFfmpeg,
        _inspetorDuracao = inspetorDuracao ?? inspecionarDuracaoPadrao;

  /// Inspeciona a duração total em segundos de [arquivoVideo] (retorna `null` se inexistente ou ilegível).
  Future<double?> obterDuracaoSegundos(File arquivoVideo) async {
    if (!arquivoVideo.existsSync()) {
      return null;
    }
    return _inspetorDuracao(arquivoVideo);
  }

  /// Transcodifica um arquivo de vídeo para H.264 720p 30fps CRF 26 (`-preset veryfast -g 300`)
  /// com áudio mono AAC 64k, aplicando corte opcional via [inicioSegundos] (`-ss`) e
  /// [duracaoSegundos] (`-t`).
  ///
  /// Retorna o [File] gerado em [caminhoSaida] em caso de sucesso, ou `null` se houver falha
  /// ou se [arquivoEntrada] não existir.
  Future<File?> transcodificarVideo({
    required File arquivoEntrada,
    required String caminhoSaida,
    double? inicioSegundos,
    double? duracaoSegundos,
  }) async {
    if (!await arquivoEntrada.exists()) {
      return null;
    }

    final inputPath = arquivoEntrada.absolute.path;
    final prefixosCorte = <String>[];
    if (inicioSegundos != null && inicioSegundos > 0) {
      prefixosCorte.add('-ss $inicioSegundos');
    }
    if (duracaoSegundos != null && duracaoSegundos > 0) {
      prefixosCorte.add('-t $duracaoSegundos');
    }
    final trechoArgs =
        prefixosCorte.isEmpty ? '' : '${prefixosCorte.join(' ')} ';

    final comando =
        '$trechoArgs-i "$inputPath" -vf scale=-2:720 -r 30 -c:v libx264 -crf 26 -preset veryfast -g 300 -c:a aac -ac 1 -b:a 64k -movflags +faststart -y "$caminhoSaida"';

    final sucesso = await _executador(comando);
    if (sucesso) {
      return File(caminhoSaida);
    }
    return null;
  }

  /// Extrai um poster frame estático do vídeo no tempo especificado (padrão 0.5 segundos).
  ///
  /// Retorna o [File] da imagem gerada em [caminhoSaida], ou `null` se falhar ou se
  /// [arquivoEntrada] não existir.
  Future<File?> extrairPosterFrame({
    required File arquivoEntrada,
    required String caminhoSaida,
    double tempoSegundos = 0.5,
  }) async {
    if (!await arquivoEntrada.exists()) {
      return null;
    }

    final inputPath = arquivoEntrada.absolute.path;
    final comando =
        '-ss $tempoSegundos -i "$inputPath" -vframes 1 -y "$caminhoSaida"';

    final sucesso = await _executador(comando);
    if (sucesso) {
      return File(caminhoSaida);
    }
    return null;
  }

  /// Extrai miniaturas JPEG leves (`360p`, qualidade comprimida `-q:v 14`) a cada 10 segundos
  /// de duração do vídeo (`10s, 20s, 30s, ...` até [limiteMaximoDuracaoVideoSegundos])
  /// para auditoria pericial e moderação de segurança no servidor.
  ///
  /// Retorna a lista de arquivos [File] gerados (ex.: `<prefixoCaminhoSaida>_kf_10s.jpg`).
  Future<List<File>> extrairKeyframesModeracao({
    required File arquivoEntrada,
    required String prefixoCaminhoSaida,
    double inicioSegundos = 0.0,
    double? duracaoSegundos,
  }) async {
    if (!await arquivoEntrada.exists()) {
      return const <File>[];
    }

    final duracaoInspecionada =
        duracaoSegundos ?? await obterDuracaoSegundos(arquivoEntrada) ?? 0.0;
    final duracaoFinal = duracaoInspecionada > limiteMaximoDuracaoVideoSegundos
        ? limiteMaximoDuracaoVideoSegundos
        : duracaoInspecionada;

    final inputPath = arquivoEntrada.absolute.path;
    final gerados = <File>[];

    for (var seg = 10; seg <= duracaoFinal.floor(); seg += 10) {
      final tempoAbsoluto = inicioSegundos + seg;
      final caminhoKf = '${prefixoCaminhoSaida}_kf_${seg}s.jpg';
      final comando =
          '-ss $tempoAbsoluto -i "$inputPath" -vf scale=-2:360 -q:v 14 -vframes 1 -y "$caminhoKf"';
      final sucesso = await _executador(comando);
      if (sucesso) {
        gerados.add(File(caminhoKf));
      }
    }

    return gerados;
  }

  /// Executa o comando FFmpeg através do [FFmpegKit].
  static Future<bool> executarFfmpeg(String comando) async {
    final session = await FFmpegKit.execute(comando);
    final returnCode = await session.getReturnCode();
    return ReturnCode.isSuccess(returnCode);
  }

  /// Inspeciona a duração do vídeo via [FFprobeKit.getMediaInformation].
  static Future<double?> inspecionarDuracaoPadrao(File arquivoVideo) async {
    try {
      final sessao =
          await FFprobeKit.getMediaInformation(arquivoVideo.absolute.path);
      final info = sessao.getMediaInformation();
      final duracaoStr = info?.getDuration();
      if (duracaoStr == null) {
        return null;
      }
      return double.tryParse(duracaoStr);
    } catch (_) {
      return null;
    }
  }
}

final videoTranscoderServiceProvider = Provider<VideoTranscoderService>((ref) {
  return VideoTranscoderService();
});
