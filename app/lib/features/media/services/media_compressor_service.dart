// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:printing/printing.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/features/media/services/video_transcoder_service.dart';

/// Assinatura para execução de áudio customizada (para testes).
typedef ExecutadorAudio = Future<bool> Function(String comando);

/// Assinatura para rasterização de bytes de um PDF em uma lista ordenada de páginas PNG.
typedef RasterizadorPdfEmPngs = Future<List<Uint8List>> Function(
  Uint8List pdfBytes, {
  double dpi,
});

/// Serviço responsável pela compressão de mídias para relatórios do Fixalog.
///
/// Calibração oficial conforme especificações de design e EPUB 3:
/// - Imagens: WebP (4MP, qualidade 85, máx 2048x2048).
/// - Documentos PDF: 1 imagem WebP por página (`<uuid>_p1.webp`, `<uuid>_p2.webp`, ...) + `.pdf` original preservado.
/// - Vídeos: H.264 720p 30fps CRF 26 com áudio AAC mono 64k e +faststart via [VideoTranscoderService].
/// - Áudio: AAC m4a a 96 kbps.
/// - Preservação: Arquivos brutos originais mantidos intactos no disco via [SessionBundleManager].
class MediaCompressorService {
  final VideoTranscoderService _videoTranscoderService;
  final ExecutadorAudio? _audioExecutador;
  final RasterizadorPdfEmPngs _rasterizadorPdf;

  MediaCompressorService({
    VideoTranscoderService? videoTranscoderService,
    ExecutadorAudio? audioExecutador,
    RasterizadorPdfEmPngs? rasterizadorPdf,
  })  : _videoTranscoderService =
            videoTranscoderService ?? VideoTranscoderService(),
        _audioExecutador = audioExecutador,
        _rasterizadorPdf = rasterizadorPdf ?? rasterizarPdfPadrao;

  /// Rasterizador padrão utilizando [Printing.raster] para converter cada página do PDF em PNG.
  static Future<List<Uint8List>> rasterizarPdfPadrao(
    Uint8List pdfBytes, {
    double dpi = 150.0,
  }) async {
    final paginasPng = <Uint8List>[];
    await for (final pagina in Printing.raster(pdfBytes, dpi: dpi)) {
      final pngBytes = await pagina.toPng();
      paginasPng.add(pngBytes);
    }
    return paginasPng;
  }

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
    if (!file.existsSync()) {
      return null;
    }

    try {
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
    } catch (_) {
      return null;
    }
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
    if (!file.existsSync()) {
      return null;
    }

    try {
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
    } catch (_) {
      return null;
    }
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

  /// Localiza o documento PDF original na sessão (`<uuid>_original.pdf`),
  /// rasteriza cada página do documento e comprime em imagens WebP numeradas
  /// (`<uuid>_p1.webp`, `<uuid>_p2.webp`, ...) no diretório da sessão.
  ///
  /// Preserva o arquivo `.pdf` original intacto e retorna a lista ordenada de arquivos WebP das páginas.
  Future<List<File>> rasterizarDocumentoPdfSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
    double dpi = 150.0,
  }) async {
    final originalPath = await sessionManager.getMediaFilePath(
      sessionId: sessionId,
      mediaUuid: '${mediaUuid}_original',
      extension: '.pdf',
    );
    final originalFile = File(originalPath);

    if (!originalFile.existsSync()) {
      return [];
    }

    List<Uint8List> paginasPng = [];
    try {
      final pdfBytes = originalFile.readAsBytesSync();
      paginasPng = await _rasterizadorPdf(pdfBytes, dpi: dpi);
    } catch (_) {
      paginasPng = [];
    }

    final arquivosPaginas = <File>[];

    for (var i = 0; i < paginasPng.length; i++) {
      final indicePagina = i + 1;
      final idPagina = '${mediaUuid}_p$indicePagina';

      final tempPngPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '${idPagina}_temp',
        extension: '.png',
      );
      final tempPngFile = File(tempPngPath);
      tempPngFile.writeAsBytesSync(paginasPng[i]);

      final outWebpPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: idPagina,
        extension: '.webp',
      );
      final thumbWebpPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '${idPagina}_thumb',
        extension: '.webp',
      );

      await compressThumbnail(tempPngFile, thumbWebpPath);
      var paginaWebp = await compressImage(tempPngFile, outWebpPath);
      if (paginaWebp == null || !paginaWebp.existsSync()) {
        final fallbackFile = File(outWebpPath);
        fallbackFile.writeAsBytesSync(paginasPng[i]);
        paginaWebp = fallbackFile;
      }

      if (tempPngFile.existsSync()) {
        tempPngFile.deleteSync();
      }

      arquivosPaginas.add(paginaWebp);
    }

    // Fallback: se o rasterizador não retornou novas páginas mas páginas já existem em disco na sessão
    if (arquivosPaginas.isEmpty) {
      var indice = 1;
      while (true) {
        final caminhoExistente = await sessionManager.getMediaFilePath(
          sessionId: sessionId,
          mediaUuid: '${mediaUuid}_p$indice',
          extension: '.webp',
        );
        final arquivoExistente = File(caminhoExistente);
        if (arquivoExistente.existsSync()) {
          arquivosPaginas.add(arquivoExistente);
          indice++;
        } else {
          break;
        }
      }
    }

    return arquivosPaginas;
  }
}

final mediaCompressorProvider = Provider<MediaCompressorService>((ref) {
  final transcoder = ref.watch(videoTranscoderServiceProvider);
  return MediaCompressorService(videoTranscoderService: transcoder);
});
