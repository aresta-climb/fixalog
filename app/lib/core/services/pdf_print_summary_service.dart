// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:qr/qr.dart';
import '../models/proto/protos/registro.pb.dart';
import 'epub_document_builder.dart';

/// Assinatura da função conversora de HTML para PDF (permite injeção em testes).
typedef ConversorHtmlParaPdf = Future<Uint8List> Function({
  required String html,
  String? baseUrl,
  required PdfPageFormat format,
});

/// Representa os dados de um material vinculado a uma manutenção para inclusão sequencial ao final do PDF Resumido.
class RelatorioMaterialAnexo {
  final String idSessao;
  final Registro registro;
  final String urlCanonica;
  final Map<String, String> mapeamentoMidias;
  final Map<String, String> posterFrames;

  const RelatorioMaterialAnexo({
    required this.idSessao,
    required this.registro,
    required this.urlCanonica,
    this.mapeamentoMidias = const {},
    this.posterFrames = const {},
  });
}

/// Serviço responsável pela exportação de PDF Resumido para protocolo burocrático e órgãos ambientais/SEI.
///
/// O documento é derivado da mesma marcação XHTML semântica do relatório oficial via regras
/// de impressão (`@media print`), incluindo cabeçalho explicativo, link canônico, QR Codes
/// para rastreabilidade e reprodução de vídeos online, e concatenação das fichas de materiais utilizados.
class PdfPrintSummaryService {
  final EpubDocumentBuilder _documentBuilder;
  final ConversorHtmlParaPdf _converter;

  PdfPrintSummaryService({
    EpubDocumentBuilder? documentBuilder,
    ConversorHtmlParaPdf? converter,
  })  : _documentBuilder = documentBuilder ?? EpubDocumentBuilder(),
        _converter = converter ?? _converterPadrao;

  /// Gera a marcação SVG vetorial para um QR Code contendo o [texto] informado.
  static String gerarQrCodeSvg(String texto, {int moduloTamanho = 4}) {
    final qr = QrCode.fromData(
      data: texto,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qr);
    final count = qrImage.moduleCount;
    final totalSize = count * moduloTamanho;

    final buffer = StringBuffer();
    buffer.write(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $totalSize $totalSize" width="$totalSize" height="$totalSize">',
    );
    buffer.write('<rect width="100%" height="100%" fill="#ffffff"/>');

    for (int x = 0; x < count; x++) {
      for (int y = 0; y < count; y++) {
        if (qrImage.isDark(y, x)) {
          buffer.write(
            '<rect x="${x * moduloTamanho}" y="${y * moduloTamanho}" width="$moduloTamanho" height="$moduloTamanho" fill="#000000"/>',
          );
        }
      }
    }
    buffer.write('</svg>');
    return buffer.toString();
  }

  String _extrairCorpoHtml(String xhtml) {
    final match = RegExp(
      r'<body[^>]*>([\s\S]*?)<\/body>',
      caseSensitive: false,
    ).firstMatch(xhtml);
    if (match != null) {
      return match.group(1) ?? xhtml;
    }
    return xhtml;
  }

  /// Constrói o documento HTML completo com CSS de impressão embutido, QR Codes vetoriais injetados
  /// e relatórios dos [materiaisAnexos] concatenados ao final.
  String gerarHtmlParaImpressao({
    required Registro registro,
    required String idSessao,
    required String urlCanonica,
    Map<String, String> mapeamentoMidias = const {},
    Map<String, String> posterFrames = const {},
    List<RelatorioMaterialAnexo> materiaisAnexos = const [],
  }) {
    // 1. Gera QR Code principal institucional
    final qrPrincipalSvg = gerarQrCodeSvg(urlCanonica);
    final qrPrincipalDataUri =
        'data:image/svg+xml;utf8,${Uri.encodeComponent(qrPrincipalSvg)}';

    // 2. Gera mini QR Code dedicado para cada vídeo
    final Map<String, String> qrCodesVideos = {};
    for (final entrada in posterFrames.entries) {
      final uuid = entrada.key;
      final videoUrl = '$urlCanonica#video-$uuid';
      final qrVideoSvg = gerarQrCodeSvg(videoUrl);
      qrCodesVideos[uuid] =
          'data:image/svg+xml;utf8,${Uri.encodeComponent(qrVideoSvg)}';
    }

    final Map<String, String> titulosMateriais = {};
    for (final mat in materiaisAnexos) {
      final nomeMat = mat.registro.respostas['mat_nome']?.texto.trim() ?? '';
      titulosMateriais[mat.idSessao] = nomeMat.isNotEmpty
          ? nomeMat
          : (mat.registro.idProtocolo.isNotEmpty
              ? mat.registro.idProtocolo
              : mat.idSessao);
    }

    // 3. Monta o XHTML semântico principal
    var xhtml = _documentBuilder.gerarXhtml(
      registro: registro,
      idSessao: idSessao,
      urlCanonica: urlCanonica,
      mapeamentoMidias: mapeamentoMidias,
      posterFrames: posterFrames,
      qrCodesVideos: qrCodesVideos,
      qrCodeCanonica: qrPrincipalDataUri,
      titulosMateriais: titulosMateriais,
    );

    // 3b. Concatena ao final do documento as fichas completas de todos os materiais anexos
    if (materiaisAnexos.isNotEmpty) {
      final bufferAnexos = StringBuffer();
      for (final mat in materiaisAnexos) {
        final qrMatSvg = gerarQrCodeSvg(mat.urlCanonica);
        final qrMatDataUri =
            'data:image/svg+xml;utf8,${Uri.encodeComponent(qrMatSvg)}';

        final Map<String, String> qrVideosMat = {};
        for (final entrada in mat.posterFrames.entries) {
          final uuid = entrada.key;
          final qrVidSvg = gerarQrCodeSvg('${mat.urlCanonica}#video-$uuid');
          qrVideosMat[uuid] =
              'data:image/svg+xml;utf8,${Uri.encodeComponent(qrVidSvg)}';
        }

        final tituloMat = titulosMateriais[mat.idSessao] ?? mat.idSessao;
        final xhtmlMat = _documentBuilder.gerarXhtml(
          registro: mat.registro,
          idSessao: mat.idSessao,
          urlCanonica: mat.urlCanonica,
          mapeamentoMidias: mat.mapeamentoMidias,
          posterFrames: mat.posterFrames,
          qrCodesVideos: qrVideosMat,
          qrCodeCanonica: qrMatDataUri,
        );
        final corpoMat = _extrairCorpoHtml(xhtmlMat);

        bufferAnexos.writeln(
          '  <section class="anexo-material-impresso" style="page-break-before: always; margin-top: 32px; border-top: 2px solid #000000; padding-top: 16px;">',
        );
        bufferAnexos.writeln(
          '    <h2>Anexo — Ficha Técnica de Material: $tituloMat</h2>',
        );
        bufferAnexos.writeln(corpoMat);
        bufferAnexos.writeln('  </section>');
      }

      xhtml = xhtml.replaceFirst(
        '</body>',
        '${bufferAnexos.toString()}</body>',
      );
    }

    // 4. Incorpora a folha de estilo diretamente em uma tag <style> para rendering autocontido
    final css = _documentBuilder.gerarCss();
    final htmlCompleto = xhtml.replaceFirst(
      '<link rel="stylesheet" type="text/css" href="estilo.css"/>',
      '<style>$css</style>',
    );

    // 5. Remove tags <video> para evitar que o WebView tente carregar ou decodificar mídias pesadas durante a impressão
    final htmlLimpo = htmlCompleto.replaceAll(
      RegExp(r'<video[\s\S]*?<\/video>', caseSensitive: false),
      '',
    );

    return htmlLimpo;
  }

  /// Gera os bytes do PDF A4 formatado a partir da renderização do HTML.
  Future<Uint8List> gerarPdfResumidoBytes({
    required Registro registro,
    required String idSessao,
    required String urlCanonica,
    Map<String, String> mapeamentoMidias = const {},
    Map<String, String> posterFrames = const {},
    List<RelatorioMaterialAnexo> materiaisAnexos = const [],
    String? baseUrl,
  }) async {
    final html = gerarHtmlParaImpressao(
      registro: registro,
      idSessao: idSessao,
      urlCanonica: urlCanonica,
      mapeamentoMidias: mapeamentoMidias,
      posterFrames: posterFrames,
      materiaisAnexos: materiaisAnexos,
    );

    return _converter(
      html: html,
      baseUrl: baseUrl,
      format: PdfPageFormat.a4,
    );
  }

  /// Exporta o PDF Resumido e grava o arquivo no disco local em [caminhoSaida].
  Future<File> exportarPdfResumido({
    required String caminhoSaida,
    required Registro registro,
    required String idSessao,
    required String urlCanonica,
    Map<String, String> mapeamentoMidias = const {},
    Map<String, String> posterFrames = const {},
    List<RelatorioMaterialAnexo> materiaisAnexos = const [],
    String? baseUrl,
  }) async {
    final bytes = await gerarPdfResumidoBytes(
      registro: registro,
      idSessao: idSessao,
      urlCanonica: urlCanonica,
      mapeamentoMidias: mapeamentoMidias,
      posterFrames: posterFrames,
      materiaisAnexos: materiaisAnexos,
      baseUrl: baseUrl,
    );

    final arquivo = File(caminhoSaida);
    await arquivo.create(recursive: true);
    return arquivo.writeAsBytes(bytes);
  }

  static Future<Uint8List> _converterPadrao({
    required String html,
    String? baseUrl,
    required PdfPageFormat format,
  }) {
    return Printing.convertHtml(
      html: html,
      baseUrl: baseUrl,
      format: format,
    );
  }
}

final pdfPrintSummaryServiceProvider = Provider<PdfPrintSummaryService>((ref) {
  return PdfPrintSummaryService();
});
