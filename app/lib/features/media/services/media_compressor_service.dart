// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fixlog/core/services/session_bundle_manager.dart';
import 'package:fixlog/features/media/services/video_transcoder_service.dart';

/// Assinatura para execução de áudio customizada (para testes).
typedef ExecutadorAudio = Future<bool> Function(String comando);

/// Serviço responsável pela compressão de mídias para relatórios do FixLog.
///
/// Calibração oficial conforme especificações de design e EPUB 3:
/// - Imagens: WebP (4MP, qualidade 85, máx 2048x2048).
/// - Vídeos: H.264 720p 30fps CRF 26 com áudio AAC mono 64k e +faststart via [VideoTranscoderService].
/// - Áudio: AAC m4a a 96 kbps.
/// - Preservação: Arquivos brutos originais mantidos intactos no disco via [SessionBundleManager].
class MediaCompressorService {
  final VideoTranscoderService _videoTranscoderService;
  final ExecutadorAudio? _audioExecutador;

  MediaCompressorService({
    VideoTranscoderService? videoTranscoderService,
    ExecutadorAudio? audioExecutador,
  })  : _videoTranscoderService =
            videoTranscoderService ?? VideoTranscoderService(),
        _audioExecutador = audioExecutador;

  /// Reduz resolução e comprime imagens padronizadas em WebP 4MP (2048x2048) com qualidade 85.
  ///
  /// Retorna o [File] comprimido ou `null` se o arquivo de entrada não existir ou a compressão falhar.
  Future<File?> compressImage(
    File file,
    String outputPath, {
    int quality = 85,
    int minWidth = 2048,
    int minHeight = 2048,
    CompressFormat format = CompressFormat.webp,
  }) async {
    if (!await file.exists()) {
      return null;
    }

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outputPath,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: format,
    );

    if (result == null) return null;
    return File(result.path);
  }

  /// Reduz resolução e comprime miniaturas leves para impressão em WebP (600x600) com qualidade 85.
  ///
  /// Retorna o [File] comprimido ou `null` se o arquivo de entrada não existir ou a compressão falhar.
  Future<File?> compressThumbnail(
    File file,
    String outputPath, {
    int quality = 85,
    int minWidth = 600,
    int minHeight = 600,
    CompressFormat format = CompressFormat.webp,
  }) async {
    if (!await file.exists()) {
      return null;
    }

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outputPath,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: format,
    );

    if (result == null) return null;
    return File(result.path);
  }

  /// Transcodifica vídeo para H.264 720p CRF 26 delegando para [VideoTranscoderService].
  Future<File?> compressVideo(File file, String outputPath) async {
    return _videoTranscoderService.transcodificarVideo(
      arquivoEntrada: file,
      caminhoSaida: outputPath,
    );
  }

  /// Transcodifica áudio para m4a (AAC) com bitrate de 96k (alta fidelidade para voz).
  Future<File?> compressAudio(File file, String outputPath) async {
    if (!await file.exists()) {
      return null;
    }

    final inputPath = file.absolute.path;
    final command = '-i "$inputPath" -c:a aac -b:a 96k -y "$outputPath"';

    final sucesso = _audioExecutador != null
        ? await _audioExecutador(command)
        : await VideoTranscoderService.executarFfmpeg(command);

    if (sucesso) {
      return File(outputPath);
    }
    return null;
  }

  /// Alias de conveniência para [comprimirImagemSessao].
  Future<File?> comprimirFotoSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
  }) =>
      comprimirImagemSessao(
        sessionManager: sessionManager,
        sessionId: sessionId,
        mediaUuid: mediaUuid,
      );

  /// Localiza o arquivo original da foto na sessão (`<uuid>_original.jpg/png`),
  /// comprime para WebP principal (`<uuid>.webp`), gera miniatura de impressão (`<uuid>_thumb.webp`)
  /// e preserva o arquivo bruto intacto no disco.
  Future<File?> comprimirImagemSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
  }) async {
    // 1. Tenta encontrar a matriz original (.jpg ou .png)
    var originalPath = await sessionManager.getMediaFilePath(
      sessionId: sessionId,
      mediaUuid: '${mediaUuid}_original',
      extension: '.jpg',
    );
    var originalFile = File(originalPath);

    if (!await originalFile.exists()) {
      originalPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '${mediaUuid}_original',
        extension: '.png',
      );
      originalFile = File(originalPath);
    }

    if (!await originalFile.exists()) {
      return null;
    }

    // 2. Destino comprimido principal em WebP (2048x2048, q85)
    final outputPath = await sessionManager.getMediaFilePath(
      sessionId: sessionId,
      mediaUuid: mediaUuid,
      extension: '.webp',
    );

    // 3. Destino da miniatura leve de impressão em WebP (600x600, q85)
    final thumbPath = await sessionManager.getMediaFilePath(
      sessionId: sessionId,
      mediaUuid: '${mediaUuid}_thumb',
      extension: '.webp',
    );
    await compressThumbnail(originalFile, thumbPath);

    return compressImage(originalFile, outputPath);
  }

  /// Localiza o vídeo original na sessão (`<uuid>_original.mp4`),
  /// transcodifica para H.264 720p (`<uuid>.mp4`) e extrai o poster frame (`<uuid>_poster.webp`),
  /// mantendo o vídeo bruto intacto no disco.
  Future<({File? video, File? poster})> transcodificarVideoSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
  }) async {
    final originalPath = await sessionManager.getMediaFilePath(
      sessionId: sessionId,
      mediaUuid: '${mediaUuid}_original',
      extension: '.mp4',
    );
    final originalFile = File(originalPath);

    if (!await originalFile.exists()) {
      return (video: null, poster: null);
    }

    final outVideoPath = await sessionManager.getMediaFilePath(
      sessionId: sessionId,
      mediaUuid: mediaUuid,
      extension: '.mp4',
    );

    final outPosterPath = await sessionManager.getMediaFilePath(
      sessionId: sessionId,
      mediaUuid: '${mediaUuid}_poster',
      extension: '.webp',
    );

    final videoFile = await _videoTranscoderService.transcodificarVideo(
      arquivoEntrada: originalFile,
      caminhoSaida: outVideoPath,
    );

    final posterFile = await _videoTranscoderService.extrairPosterFrame(
      arquivoEntrada: originalFile,
      caminhoSaida: outPosterPath,
    );

    return (video: videoFile, poster: posterFile);
  }
}

final mediaCompressorProvider = Provider<MediaCompressorService>((ref) {
  final transcoder = ref.watch(videoTranscoderServiceProvider);
  return MediaCompressorService(videoTranscoderService: transcoder);
});
