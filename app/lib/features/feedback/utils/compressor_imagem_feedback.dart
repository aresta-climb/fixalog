// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../core/services/registro_logger.dart';

/// Encapsula os bytes resultantes e os metadados de formato da compressão de imagem de feedback.
class ResultadoCompressaoFeedback {
  /// Bytes da imagem após o processamento (WebP comprimido ou PNG original em caso de fallback).
  final Uint8List bytes;

  /// Formato da imagem resultante (`'webp'` ou `'png'`).
  final String formato;

  const ResultadoCompressaoFeedback({
    required this.bytes,
    required this.formato,
  });

  /// Extensão de arquivo correspondente ao formato (`'webp'` ou `'png'`).
  String get extensao => formato;

  /// Tipo MIME correspondente para envio HTTP multipart (`'image/webp'` ou `'image/png'`).
  String get tipoMime => 'image/$formato';
}

/// Assinatura da função de compressão nativa injetável para testes determinísticos.
typedef CompressaoNativaFeedbackCallback = Future<Uint8List?> Function(
  Uint8List bytes, {
  required int quality,
  required int minWidth,
  required int minHeight,
});

/// Utilitário responsável por comprimir capturas de tela anotadas antes da persistência na fila local.
///
/// Utiliza `flutter_image_compress` para codificar em WebP, aplicando fallback gracioso
/// para os bytes originais em PNG caso o canal nativo não esteja disponível ou falhe.
class CompressorImagemFeedback {
  final CompressaoNativaFeedbackCallback _compressaoNativa;
  final RegistroLogger _logger;

  /// Cria uma instância de [CompressorImagemFeedback].
  CompressorImagemFeedback({
    CompressaoNativaFeedbackCallback? compressaoNativa,
    RegistroLogger? logger,
  })  : _compressaoNativa = compressaoNativa ?? _comprimirPadrao,
        _logger = logger ?? RegistroLogger.instancia;

  static Future<Uint8List?> _comprimirPadrao(
    Uint8List bytes, {
    required int quality,
    required int minWidth,
    required int minHeight,
  }) {
    return FlutterImageCompress.compressWithList(
      bytes,
      format: CompressFormat.webp,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
    );
  }

  /// Comprime [bytesOriginais] (PNG gerado pelo `BetterFeedback`) para o formato WebP.
  ///
  /// Caso [bytesOriginais] esteja vazio ou a compressão nativa falhe, retorna os bytes
  /// originais associados ao formato `'png'`.
  Future<ResultadoCompressaoFeedback> comprimirParaWebp(
    Uint8List bytesOriginais, {
    int qualidade = 80,
    int minWidth = 1080,
    int minHeight = 1920,
  }) async {
    if (bytesOriginais.isEmpty) {
      return ResultadoCompressaoFeedback(bytes: bytesOriginais, formato: 'png');
    }

    try {
      final bytesComprimidos = await _compressaoNativa(
        bytesOriginais,
        quality: qualidade,
        minWidth: minWidth,
        minHeight: minHeight,
      );

      if (bytesComprimidos != null && bytesComprimidos.isNotEmpty) {
        return ResultadoCompressaoFeedback(
          bytes: bytesComprimidos,
          formato: 'webp',
        );
      }
    } catch (e) {
      _logger.logAviso(
        '🖼️ [CompressorImagemFeedback] Falha ao comprimir imagem para WebP. Aplicando fallback para PNG: $e',
      );
    }

    return ResultadoCompressaoFeedback(
      bytes: bytesOriginais,
      formato: 'png',
    );
  }
}
