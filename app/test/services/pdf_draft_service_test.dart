import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/pdf_generation/services/pdf_draft_service.dart';
import 'package:app/core/models/proto/protos/registro.pb.dart';

void main() {
  group('PdfDraftService Tests', () {
    test('drawDraft deve gerar PDF com sucesso', () async {
      final service = PdfDraftService();
      final tempDir = Directory.systemTemp.createTempSync('pdf_test');
      
      final registro = Registro()..idProtocolo = 'Test Protocol';
      final outputPath = '${tempDir.path}/output.pdf';

      final file = await service.drawDraft(registro, outputPath, (uuid) => '');

      expect(await file.exists(), isTrue);
      final pdfBytes = await file.readAsBytes();
      expect(pdfBytes.length, greaterThan(100));

      tempDir.deleteSync(recursive: true);
    });
  });
}
