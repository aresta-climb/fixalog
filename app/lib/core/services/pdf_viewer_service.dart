// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

class PdfViewerService {
  final Future<OpenResult> Function(String filePath)? openProxy;
  final Future<bool> Function(String filePath)? fileExistsProxy;

  PdfViewerService({this.openProxy, this.fileExistsProxy});

  Future<void> openPdf(String path) async {
    final exists = fileExistsProxy != null
        ? await fileExistsProxy!(path)
        : await File(path).exists();
    if (!exists) {
      throw Exception('Arquivo PDF não encontrado para abrir.');
    }
    
    final proxy = openProxy ?? OpenFilex.open;
    final result = await proxy(path);
    if (result.type != ResultType.done) {
      throw Exception('Falha ao abrir PDF: ${result.message}');
    }
  }
}

final pdfViewerServiceProvider = Provider<PdfViewerService>((ref) {
  return PdfViewerService();
});
