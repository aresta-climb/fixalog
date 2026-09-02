import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_filex/open_filex.dart';
import 'package:fixlog/core/services/pdf_viewer_service.dart';

void main() {
  group('PdfViewerService', () {
    test('Deve chamar o proxy de abertura com os argumentos corretos', () async {
      // Arrange
      bool proxyCalled = false;
      String? capturedPath;

      final service = PdfViewerService(
        openProxy: (filePath) async {
          proxyCalled = true;
          capturedPath = filePath;
          return OpenResult(type: ResultType.done, message: 'done');
        },
      );

      final tempFile = File('test_output.pdf');
      await tempFile.writeAsBytes([1, 2, 3, 4]);

      // Act
      await service.openPdf(tempFile.path);

      // Assert
      expect(proxyCalled, isTrue);
      expect(capturedPath, tempFile.path);

      // Cleanup
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test('Deve lançar exceção se o arquivo PDF não existir', () async {
      final service = PdfViewerService(
        openProxy: (filePath) async {
          fail('Não deveria chegar aqui');
        }
      );
      
      expect(
        () => service.openPdf('caminho_inexistente.pdf'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('não encontrado'))),
      );
    });
  });
}
