// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;

class MediaCompressorService {
  /// Reduz resolução mantendo a proporção (limite de 4M pixels, máx 2048x2048)
  /// Usamos JPEG (nível 95) para garantir fidelidade visual idêntica ao WebP90,
  /// mantendo 100% de compatibilidade (DCTDecode) com os PDFs.
  Future<File?> compressImage(File file, String outputPath) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outputPath,
      quality: 95,
      minWidth: 2048,
      minHeight: 2048,
      format: CompressFormat.jpeg,
    );
    
    if (result == null) return null;
    return File(result.path);
  }

  /// Transcodifica vídeo para H.264 1080p (FHD) mantendo altíssima retenção de detalhes
  /// (CRF 24). Arquivos de 4K gigantes viram 1080p enxutos.
  Future<File?> compressVideo(File file, String outputPath) async {
    final inputPath = file.absolute.path;
    // FFmpeg command: scale=-2:1080 (FHD), H.264, CRF 24 (visualmente sem perdas), preset fast
    final command = '-i "\$inputPath" -vf scale=-2:1080 -c:v libx264 -crf 24 -preset fast -c:a aac -b:a 128k -y "\$outputPath"';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    
    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath);
    } else {
      final logs = await session.getLogsAsString();
      print('FFmpeg Video falhou: \$logs');
      return null;
    }
  }

  /// Transcodifica áudio para m4a (AAC) com bitrate de 96k (alta fidelidade para voz).
  Future<File?> compressAudio(File file, String outputPath) async {
    final inputPath = file.absolute.path;
    // FFmpeg command: AAC 96kbps
    final command = '-i "\$inputPath" -c:a aac -b:a 96k -y "\$outputPath"';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    
    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath);
    } else {
      final logs = await session.getLogsAsString();
      print('FFmpeg Audio falhou: \$logs');
      return null;
    }
  }
}
