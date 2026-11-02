// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:collection';
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

/// Serviço responsável pela compressão e pré-processamento em segundo plano de mídias
/// para relatórios do Fixalog.
///
/// Calibração oficial conforme especificações de design, EPUB 3 e PDF Resumido:
/// - Imagens principais (EPUB 3): WebP 4MP (`2048x2048`, qualidade 85).
/// - Imagens de impressão (PDF Resumido): JPEG 2MP (`1440x1440`, qualidade 80, `<uuid>_thumb.jpg`),
///   derivadas a partir da imagem WebP de 4MP já redimensionada.
/// - Documentos PDF: 1 imagem WebP 4MP + 1 imagem JPEG 2MP por página (`<uuid>_p<N>.webp` e `<uuid>_p<N>_thumb.jpg`) + `.pdf` original preservado.
/// - Vídeos: H.264 720p 30fps CRF 26 (`-preset veryfast`) com áudio AAC mono 64k, `+faststart` e poster em JPEG (`<uuid>_poster.jpg`).
/// - Áudio: AAC m4a a 96 kbps.
/// - Escrita atômica (`.tmp` -> `rename`) e reutilização de artefatos já processados.
class MediaCompressorService {
  final VideoTranscoderService _videoTranscoderService;
  final ExecutadorAudio? _audioExecutador;
  final RasterizadorPdfEmPngs _rasterizadorPdf;

  final Map<String, Future<File?>> _tarefasImagemEmAndamento = {};
  final Map<String, Future<({File? video, File? poster})>> _tarefasVideoEmAndamento = {};
  final Map<String, Future<List<File>>> _tarefasPdfEmAndamento = {};

  static const int _limiteImagensSimultaneas = 3;
  int _imagensAtivas = 0;
  final Queue<Completer<void>> _filaEsperaImagens = Queue<Completer<void>>();

  bool _videoAtivo = false;
  final Queue<Completer<void>> _filaEsperaVideos = Queue<Completer<void>>();

  MediaCompressorService({
    VideoTranscoderService? videoTranscoderService,
    ExecutadorAudio? audioExecutador,
    RasterizadorPdfEmPngs? rasterizadorPdf,
  })  : _videoTranscoderService =
            videoTranscoderService ?? VideoTranscoderService(),
        _audioExecutador = audioExecutador,
        _rasterizadorPdf = rasterizadorPdf ?? rasterizarPdfPadrao;

  Future<T> _executarNoPoolDeImagens<T>(Future<T> Function() acao) async {
    if (_imagensAtivas >= _limiteImagensSimultaneas) {
      final completer = Completer<void>();
      _filaEsperaImagens.addLast(completer);
      await completer.future;
    }
    _imagensAtivas++;
    try {
      return await acao();
    } finally {
      _imagensAtivas--;
      if (_filaEsperaImagens.isNotEmpty) {
        _filaEsperaImagens.removeFirst().complete();
      }
    }
  }

  Future<T> _executarNaFilaDeVideos<T>(Future<T> Function() acao) async {
    if (_videoAtivo) {
      final completer = Completer<void>();
      _filaEsperaVideos.addLast(completer);
      await completer.future;
    }
    _videoAtivo = true;
    try {
      return await acao();
    } finally {
      _videoAtivo = false;
      if (_filaEsperaVideos.isNotEmpty) {
        _filaEsperaVideos.removeFirst().complete();
      }
    }
  }

  static String _construirCaminhoTemporario(String outputPath) {
    final idx = outputPath.lastIndexOf('.');
    if (idx == -1) return '$outputPath.tmp';
    return '${outputPath.substring(0, idx)}.tmp${outputPath.substring(idx)}';
  }

  static void _limparArquivoSeExistir(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) {
        f.deleteSync();
      }
    } catch (_) {}
  }

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

  /// Reduz resolução e comprime imagens padronizadas em WebP 4MP (2048x2048) com qualidade 85
  /// utilizando escrita atômica (`.tmp` seguido de `rename`).
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

    final tmpPath = _construirCaminhoTemporario(outputPath);
    _limparArquivoSeExistir(tmpPath);

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        tmpPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: format,
      );

      if (result == null) {
        _limparArquivoSeExistir(tmpPath);
        return null;
      }

      final tmpFile = File(result.path);
      if (tmpFile.existsSync()) {
        final destino = File(outputPath);
        await destino.parent.create(recursive: true);
        if (destino.existsSync()) {
          destino.deleteSync();
        }
        return await tmpFile.rename(outputPath);
      }
      return File(outputPath);
    } catch (_) {
      _limparArquivoSeExistir(tmpPath);
      return null;
    }
  }

  /// Reduz resolução e comprime imagens de impressão para o PDF Resumido em JPEG 2MP (`1440x1440`, qualidade 80)
  /// utilizando escrita atômica (`.tmp` seguido de `rename`).
  ///
  /// Retorna o [File] comprimido ou `null` se o arquivo de entrada não existir ou a compressão falhar.
  Future<File?> compressThumbnail(
    File file,
    String outputPath, {
    int quality = 80,
    int minWidth = 1440,
    int minHeight = 1440,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    if (!file.existsSync()) {
      return null;
    }

    final tmpPath = _construirCaminhoTemporario(outputPath);
    _limparArquivoSeExistir(tmpPath);

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        tmpPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: format,
      );

      if (result == null) {
        _limparArquivoSeExistir(tmpPath);
        return null;
      }

      final tmpFile = File(result.path);
      if (tmpFile.existsSync()) {
        final destino = File(outputPath);
        await destino.parent.create(recursive: true);
        if (destino.existsSync()) {
          destino.deleteSync();
        }
        return await tmpFile.rename(outputPath);
      }
      return File(outputPath);
    } catch (_) {
      _limparArquivoSeExistir(tmpPath);
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
  /// comprime para WebP principal de 4MP (`<uuid>.webp`), deriva a versão JPEG de 2MP (`<uuid>_thumb.jpg`)
  /// a partir do `.webp` já redimensionado e preserva o arquivo bruto intacto no disco.
  ///
  /// Se os artefatos finais já existirem em disco, retorna imediatamente sem recomprimir.
  Future<File?> comprimirImagemSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
  }) {
    final chave = '$sessionId:$mediaUuid';
    final existente = _tarefasImagemEmAndamento[chave];
    if (existente != null) {
      return existente;
    }

    final tarefa = _executarNoPoolDeImagens(() async {
      final outputPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.webp',
      );
      final thumbPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '${mediaUuid}_thumb',
        extension: '.jpg',
      );

      _limparArquivoSeExistir(_construirCaminhoTemporario(outputPath));
      _limparArquivoSeExistir(_construirCaminhoTemporario(thumbPath));

      final webpExistente = File(outputPath);
      final thumbExistente = File(thumbPath);

      if (webpExistente.existsSync() &&
          webpExistente.lengthSync() > 0 &&
          thumbExistente.existsSync() &&
          thumbExistente.lengthSync() > 0) {
        return webpExistente;
      }

      var originalPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '${mediaUuid}_original',
        extension: '.jpg',
      );
      var originalFile = File(originalPath);

      if (!originalFile.existsSync()) {
        originalPath = await sessionManager.getMediaFilePath(
          sessionId: sessionId,
          mediaUuid: '${mediaUuid}_original',
          extension: '.png',
        );
        originalFile = File(originalPath);
      }

      if (!originalFile.existsSync()) {
        return webpExistente.existsSync() ? webpExistente : null;
      }

      File? webpGerado = webpExistente.existsSync() && webpExistente.lengthSync() > 0
          ? webpExistente
          : await compressImage(originalFile, outputPath);

      final fonteParaThumb =
          (webpGerado != null && webpGerado.existsSync()) ? webpGerado : originalFile;

      if (!thumbExistente.existsSync() || thumbExistente.lengthSync() == 0) {
        await compressThumbnail(fonteParaThumb, thumbPath);
      }

      return webpGerado;
    }).whenComplete(() {
      _tarefasImagemEmAndamento.remove(chave);
    });

    _tarefasImagemEmAndamento[chave] = tarefa;
    return tarefa;
  }

  /// Localiza o vídeo original na sessão (`<uuid>_original.mp4`),
  /// transcodifica para H.264 720p (`<uuid>.mp4`) e extrai o poster frame em JPEG (`<uuid>_poster.jpg`),
  /// mantendo o vídeo bruto intacto no disco.
  ///
  /// Se os artefatos finais já existirem em disco, retorna imediatamente sem retrancodificar.
  Future<({File? video, File? poster})> transcodificarVideoSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
  }) {
    final chave = '$sessionId:$mediaUuid';
    final existente = _tarefasVideoEmAndamento[chave];
    if (existente != null) {
      return existente;
    }

    final tarefa = _executarNaFilaDeVideos(() async {
      final outVideoPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: mediaUuid,
        extension: '.mp4',
      );

      final outPosterPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '${mediaUuid}_poster',
        extension: '.jpg',
      );

      final videoPronto = File(outVideoPath);
      final posterPronto = File(outPosterPath);
      if (videoPronto.existsSync() &&
          videoPronto.lengthSync() > 0 &&
          posterPronto.existsSync() &&
          posterPronto.lengthSync() > 0) {
        return (video: videoPronto, poster: posterPronto);
      }

      final originalPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '${mediaUuid}_original',
        extension: '.mp4',
      );
      final originalFile = File(originalPath);

      if (!await originalFile.exists()) {
        return (video: null, poster: null);
      }

      final videoFile = (videoPronto.existsSync() && videoPronto.lengthSync() > 0)
          ? videoPronto
          : await _videoTranscoderService.transcodificarVideo(
              arquivoEntrada: originalFile,
              caminhoSaida: outVideoPath,
            );

      final posterFile = (posterPronto.existsSync() && posterPronto.lengthSync() > 0)
          ? posterPronto
          : await _videoTranscoderService.extrairPosterFrame(
              arquivoEntrada: originalFile,
              caminhoSaida: outPosterPath,
            );

      return (video: videoFile, poster: posterFile);
    }).whenComplete(() {
      _tarefasVideoEmAndamento.remove(chave);
    });

    _tarefasVideoEmAndamento[chave] = tarefa;
    return tarefa;
  }

  /// Localiza o documento PDF original na sessão (`<uuid>_original.pdf`) ou suas páginas já extraídas
  /// (`<uuid>_p<N>_original.jpg`), gerando as imagens WebP de 4MP (`<uuid>_p<N>.webp`) e
  /// as miniaturas JPEG de 2MP (`<uuid>_p<N>_thumb.jpg`).
  ///
  /// Preserva o arquivo `.pdf` original intacto e retorna a lista ordenada de arquivos WebP das páginas.
  Future<List<File>> rasterizarDocumentoPdfSessao({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
    double dpi = 150.0,
  }) {
    final chave = '$sessionId:$mediaUuid';
    final existente = _tarefasPdfEmAndamento[chave];
    if (existente != null) {
      return existente;
    }

    final tarefa = () async {
      // 1. Verificar se páginas <uuid>_p<N>_original.jpg já foram extraídas no Wizard
      final paginasOriginaisExtraidas = <int>[];
      var indiceBusca = 1;
      while (true) {
        final origPagPath = await sessionManager.getMediaFilePath(
          sessionId: sessionId,
          mediaUuid: '${mediaUuid}_p${indiceBusca}_original',
          extension: '.jpg',
        );
        if (File(origPagPath).existsSync()) {
          paginasOriginaisExtraidas.add(indiceBusca);
          indiceBusca++;
        } else {
          break;
        }
      }

      if (paginasOriginaisExtraidas.isNotEmpty) {
        final resultados = await Future.wait(
          paginasOriginaisExtraidas.map(
            (numPag) => comprimirImagemSessao(
              sessionManager: sessionManager,
              sessionId: sessionId,
              mediaUuid: '${mediaUuid}_p$numPag',
            ),
          ),
        );
        final validos = resultados.whereType<File>().toList();
        if (validos.isNotEmpty) {
          return validos;
        }
      }

      // 2. Verificar se páginas <uuid>_p<N>.webp já existem prontas em disco
      final paginasWebpExistentes = <File>[];
      var indiceWebp = 1;
      while (true) {
        final caminhoExistente = await sessionManager.getMediaFilePath(
          sessionId: sessionId,
          mediaUuid: '${mediaUuid}_p$indiceWebp',
          extension: '.webp',
        );
        final arquivoExistente = File(caminhoExistente);
        if (arquivoExistente.existsSync() && arquivoExistente.lengthSync() > 0) {
          final thumbPath = await sessionManager.getMediaFilePath(
            sessionId: sessionId,
            mediaUuid: '${mediaUuid}_p${indiceWebp}_thumb',
            extension: '.jpg',
          );
          final thumbFile = File(thumbPath);
          if (!thumbFile.existsSync() || thumbFile.lengthSync() == 0) {
            await compressThumbnail(arquivoExistente, thumbPath);
          }
          paginasWebpExistentes.add(arquivoExistente);
          indiceWebp++;
        } else {
          break;
        }
      }

      if (paginasWebpExistentes.isNotEmpty) {
        return paginasWebpExistentes;
      }

      // 3. Fallback: rasterizar a partir de <uuid>_original.pdf
      final originalPath = await sessionManager.getMediaFilePath(
        sessionId: sessionId,
        mediaUuid: '${mediaUuid}_original',
        extension: '.pdf',
      );
      final originalFile = File(originalPath);

      if (!originalFile.existsSync()) {
        return <File>[];
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
        final thumbJpgPath = await sessionManager.getMediaFilePath(
          sessionId: sessionId,
          mediaUuid: '${idPagina}_thumb',
          extension: '.jpg',
        );

        var paginaWebp = await compressImage(tempPngFile, outWebpPath);
        if (paginaWebp == null || !paginaWebp.existsSync()) {
          final fallbackFile = File(outWebpPath);
          fallbackFile.writeAsBytesSync(paginasPng[i]);
          paginaWebp = fallbackFile;
        }

        final fonteThumb = paginaWebp.existsSync() ? paginaWebp : tempPngFile;
        await compressThumbnail(fonteThumb, thumbJpgPath);

        if (tempPngFile.existsSync()) {
          tempPngFile.deleteSync();
        }

        arquivosPaginas.add(paginaWebp);
      }

      return arquivosPaginas;
    }().whenComplete(() {
      _tarefasPdfEmAndamento.remove(chave);
    });

    _tarefasPdfEmAndamento[chave] = tarefa;
    return tarefa;
  }
}

final mediaCompressorProvider = Provider<MediaCompressorService>((ref) {
  final transcoder = ref.watch(videoTranscoderServiceProvider);
  return MediaCompressorService(videoTranscoderService: transcoder);
});
