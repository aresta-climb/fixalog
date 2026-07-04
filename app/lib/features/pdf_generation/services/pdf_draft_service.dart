import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:app/features/pdf_generation/models/generation_media.dart';

class PdfDraftService {
  /// Gera o PDF estrutural (Rascunho) com textos, imagens estáticas e placeholders
  /// para as mídias (GoToE - Go To Embedded).
  Future<File> drawDraft(String title, List<GenerationMedia> medias, String outputPath) async {
    final pdf = pw.Document();

    final loadedImages = <String, pw.MemoryImage>{};
    for (var m in medias) {
      final ext = m.file.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png'].contains(ext)) {
        try {
          final bytes = await m.file.readAsBytes();
          loadedImages[m.file.path] = pw.MemoryImage(bytes);
        } catch (e) {
          // ignora se falhar ao ler a imagem
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),
            pw.Text('Evidências Anexadas:', style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: medias.map((m) {
                final image = loadedImages[m.file.path];
                if (image != null) {
                  return pw.Container(
                    width: 200,
                    margin: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 200,
                          height: 200,
                          child: pw.Image(image, fit: pw.BoxFit.contain),
                        ),
                        if (m.description.isNotEmpty) ...[
                          pw.SizedBox(height: 5),
                          pw.Text(m.description, style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic), textAlign: pw.TextAlign.center),
                        ]
                      ]
                    )
                  );
                } else {
                  final filename = m.file.path.split(Platform.pathSeparator).last;
                  return pw.Container(
                    width: 120,
                    height: 40,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(filename, style: const pw.TextStyle(fontSize: 10)),
                  );
                }
              }).toList(),
            ),
          ];
        },
      ),
    );

    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
