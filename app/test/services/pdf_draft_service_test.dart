import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/pdf_generation/services/pdf_draft_service.dart';

import 'package:app/features/pdf_generation/models/generation_media.dart';

void main() {
  group('PdfDraftService Tests', () {
    test('drawDraft deve anexar imagens corretamente ao PDF (Fase Red)', () async {
      final service = PdfDraftService();
      final tempDir = Directory.systemTemp.createTempSync('pdf_test');
      
      // Cria uma imagem fake (1x1 transparente PNG)
      final fakeImage = File('${tempDir.path}/foto.png');
      final imageBytes = [137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130];
      await fakeImage.writeAsBytes(imageBytes);

      final outputPath = '${tempDir.path}/output.pdf';

      final file = await service.drawDraft('Test PDF', [
        GenerationMedia(file: fakeImage, description: 'Bela imagem')
      ], outputPath);

      expect(await file.exists(), isTrue);
      final pdfBytes = await file.readAsBytes();
      
      // O PDF gerado com uma imagem deve ser razoavelmente maior do que um PDF sem imagem.
      // Além disso, ele não deve crachar ao tentar parsear a imagem real.
      expect(pdfBytes.length, greaterThan(100));

      tempDir.deleteSync(recursive: true);
    });
  });
}
