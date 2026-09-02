// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/proto/protos/fixalog.pb.dart';

class PdfReportService {
  /// Compila a interface visual em um formato buffer nativo de PDF
  Future<Uint8List> generateReport(
    SubmissaoProtocolo form,
    String pdfHashSignature,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                "Relatório de Manutenção - FixLog",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Sessão ID: \${form.idSessao}"),
            pw.Text("Timestamp Autêntico: \${form.utcTimestampGps}"),
            pw.Divider(),
            pw.Text("Respostas Coletadas:"),
            pw.ListView(
              children: form.respostas
                  .map(
                    (r) => pw.Text(
                      "Hash do campo \${r.idCampo}: \${r.valorTexto}",
                    ),
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 20),
            if (form.assinaturaVisual.isNotEmpty)
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Image(
                  pw.MemoryImage(Uint8List.fromList(form.assinaturaVisual)),
                ),
              ),
            pw.SizedBox(height: 10),
            pw.Text(
              "Assinatura Criptográfica: \$pdfHashSignature",
              style: const pw.TextStyle(fontSize: 8),
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }
}
