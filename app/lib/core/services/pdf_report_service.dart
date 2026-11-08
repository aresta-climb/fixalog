// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:typed_data';
import 'dart:ui';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../l10n/resolvedor_idioma.dart';
import '../models/proto/protos/fixalog.pb.dart';
import '../models/proto/protos/wizard.pb.dart';
import 'pdf_print_summary_service.dart';
import 'protocol_parser.dart';

class PdfReportService {
  final PdfPrintSummaryService _summaryService;

  PdfReportService({PdfPrintSummaryService? summaryService})
      : _summaryService = summaryService ?? PdfPrintSummaryService();

  /// Compila a interface visual em um formato buffer nativo de PDF localizado com fontes Google Noto Sans.
  Future<Uint8List> generateReport(
    SubmissaoProtocolo form,
    String pdfHashSignature, {
    String codigoIdioma = 'pt',
    DefinicaoProtocolo? protocolo,
  }) async {
    final pdf = pw.Document();
    final codigoNorm = codigoIdioma.split(RegExp(r'[-_]')).first.toLowerCase();
    final l10n = ResolvedorIdioma.obterTraducoes(Locale(codigoNorm));
    final tema = _summaryService.construirTemaParaIdioma(codigoNorm);
    final direcao =
        codigoNorm == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: tema,
        textDirection: direcao,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Fixalog — ${l10n.laudoRotuloProtocolo}',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('${l10n.laudoRotuloSessao}: ${form.idSessao}'),
            pw.Text('${l10n.laudoRotuloEmissao}: ${form.utcTimestampGps}'),
            pw.Divider(),
            pw.ListView(
              children: form.respostas.map((r) {
                final rotulo = protocolo != null
                    ? (ProtocolParser.resolverRotuloConteudo(
                          protocolo,
                          r.idCampo,
                        ) ??
                        r.idCampo)
                    : r.idCampo;
                final valor = protocolo != null
                    ? (ProtocolParser.resolverRotuloOpcao(
                          protocolo,
                          r.idCampo,
                          r.valorTexto,
                        ) ??
                        r.valorTexto)
                    : r.valorTexto;
                return pw.Text('$rotulo: $valor');
              }).toList(),
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
              '${l10n.laudoSecaoIntegridadeTitulo}: $pdfHashSignature',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }
}
