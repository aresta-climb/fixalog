// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Assinatura da função executora de comandos FFmpeg (permite injeção em testes).
typedef ExecutadorFfmpeg = Future<bool> Function(String comando);

/// Serviço responsável pela transcodificação padronizada de vídeos de inspeção
/// e extração de poster frames estáticos para o relatório EPUB 3 e PDF.
///
/// Calibração oficial conforme especificações:
/// - Vídeo: H.264 (High profile), 720p a 30fps, CRF 26, preset fast, -movflags +faststart.
/// - Áudio: AAC mono a 64 kbps (-ac 1 -b:a 64k).
/// - Poster frame: Extração estática aos 0.5s (-ss 0.5 -vframes 1).
class VideoTranscoderService {
  final ExecutadorFfmpeg _executador;

  VideoTranscoderService({ExecutadorFfmpeg? executador})
      : _executador = executador ?? executarFfmpeg;

  /// Transcodifica um arquivo de vídeo para H.264 720p 30fps CRF 26 com áudio mono AAC 64k.
  ///
  /// Retorna o [File] gerado em [caminhoSaida] em caso de sucesso, ou `null` se houver falha
  /// ou se [arquivoEntrada] não existir.
  Future<File?> transcodificarVideo({
    required File arquivoEntrada,
    required String caminhoSaida,
  }) async {
    if (!await arquivoEntrada.exists()) {
      return null;
    }

    final inputPath = arquivoEntrada.absolute.path;
    final comando =
        '-i "$inputPath" -vf scale=-2:720 -r 30 -c:v libx264 -crf 26 -preset fast -c:a aac -ac 1 -b:a 64k -movflags +faststart -y "$caminhoSaida"';

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

  /// Executa o comando FFmpeg através do [FFmpegKit].
  static Future<bool> executarFfmpeg(String comando) async {
    final session = await FFmpegKit.execute(comando);
    final returnCode = await session.getReturnCode();
    return ReturnCode.isSuccess(returnCode);
  }
}

final videoTranscoderServiceProvider = Provider<VideoTranscoderService>((ref) {
  return VideoTranscoderService();
});
