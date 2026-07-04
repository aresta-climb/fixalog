import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

class PdfViewerService {
  final Future<OpenResult> Function(String filePath)? openProxy;

  PdfViewerService({this.openProxy});

  Future<void> openPdf(String path) async {
    final file = File(path);
    if (!await file.exists()) {
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
