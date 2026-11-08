// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr/qr.dart';
import '../models/proto/protos/registro.pb.dart';
import 'construtor_arvore_relatorio.dart';
import 'epub_document_builder.dart';

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
/// Constrói o documento A4 nativamente via `package:pdf` (`pw.Document` / `pw.MultiPage`),
/// interpretando obrigatoriamente o schema YAML (`ConstrutorArvoreRelatorio`) para organizar
/// blocos, traduzir rótulos humanos, dispor campos curtos e fotos em duas colunas,
/// aninhar sub-listas recursivamente e concatenar as fichas técnicas de materiais utilizados.
class PdfPrintSummaryService {
  final EpubDocumentBuilder _documentBuilder;
  final ConstrutorArvoreRelatorio _construtorArvore;

  PdfPrintSummaryService({
    EpubDocumentBuilder? documentBuilder,
    ConstrutorArvoreRelatorio? construtorArvore,
  })  : _documentBuilder = documentBuilder ?? EpubDocumentBuilder(),
        _construtorArvore =
            construtorArvore ?? const ConstrutorArvoreRelatorio();

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
    return match!.group(1)!;
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
    final qrPrincipalSvg = gerarQrCodeSvg(urlCanonica);
    final qrPrincipalDataUri =
        'data:image/svg+xml;utf8,${Uri.encodeComponent(qrPrincipalSvg)}';

    final Map<String, String> qrCodesVideos = {};
    for (final entrada in posterFrames.entries) {
      final uuid = entrada.key;
      final videoUrl = '$urlCanonica#video-$uuid';
      final qrVideoSvg = gerarQrCodeSvg(videoUrl);
      qrCodesVideos[uuid] =
          'data:image/svg+xml;utf8,${Uri.encodeComponent(qrVideoSvg)}';
    }

    final Map<String, String> titulosMateriais = _resolverTitulosMateriais(
      materiaisAnexos,
    );

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

        final tituloMat = titulosMateriais[mat.idSessao]!;
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

    final css = _documentBuilder.gerarCss();
    final htmlCompleto = xhtml.replaceFirst(
      '<link rel="stylesheet" type="text/css" href="estilo.css"/>',
      '<style>$css</style>',
    );

    return htmlCompleto.replaceAll(
      RegExp(r'<video[\s\S]*?<\/video>', caseSensitive: false),
      '',
    );
  }

  Map<String, String> _resolverTitulosMateriais(
    List<RelatorioMaterialAnexo> materiaisAnexos,
  ) {
    final Map<String, String> titulosMateriais = {};
    for (final mat in materiaisAnexos) {
      titulosMateriais[mat.idSessao] =
          ConstrutorArvoreRelatorio.extrairTituloExibicao(
        mat.registro,
        fallback: mat.idSessao,
      );
    }
    return titulosMateriais;
  }

  String _normalizarTextoLatin1(String texto) {
    return texto.replaceAll('—', '-').replaceAll('–', '-');
  }

  pw.MemoryImage? _carregarImagemMemoria(String? referencia) {
    if (referencia == null || referencia.isEmpty) return null;
    if (referencia.startsWith('data:image/') &&
        referencia.contains(';base64,')) {
      final base64Parte = referencia.split(';base64,').last;
      return pw.MemoryImage(base64Decode(base64Parte));
    }
    final arquivo = File(referencia);
    if (arquivo.existsSync()) {
      return pw.MemoryImage(arquivo.readAsBytesSync());
    }
    return null;
  }

  List<pw.Widget> _construirWidgetsNodo({
    required NodoRelatorio nodo,
    required String urlCanonica,
    required Map<String, String> mapeamentoMidias,
    required Map<String, String> posterFrames,
    required Map<String, String> titulosMateriais,
  }) {
    switch (nodo) {
      case GradePropriedadesRelatorio():
        final widgets = <pw.Widget>[];
        for (var i = 0; i < nodo.propriedades.length; i += 2) {
          final propEsq = nodo.propriedades[i];
          final propDir = (i + 1 < nodo.propriedades.length)
              ? nodo.propriedades[i + 1]
              : null;
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: _construirCelulaPropriedade(propEsq)),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: propDir != null
                        ? _construirCelulaPropriedade(propDir)
                        : pw.SizedBox(),
                  ),
                ],
              ),
            ),
          );
        }
        return widgets;

      case DestaqueEscolhaRelatorio():
        return [
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey600),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _normalizarTextoLatin1(nodo.rotuloPergunta),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _normalizarTextoLatin1(nodo.rotuloOpcao),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (nodo.subrotuloOpcao.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _normalizarTextoLatin1(nodo.subrotuloOpcao),
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ];

      case TextoLongoRelatorio():
        return [
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _normalizarTextoLatin1(nodo.rotulo),
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (nodo.subrotulo.isNotEmpty)
                  pw.Text(
                    _normalizarTextoLatin1(nodo.subrotulo),
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                pw.SizedBox(height: 4),
                _construirTextoMarkdownPdf(texto: nodo.textoMarkdown),
              ],
            ),
          ),
        ];

      case GaleriaMidiasRelatorio():
        return _construirWidgetsGaleriaMidias(
          galeria: nodo,
          urlCanonica: urlCanonica,
          mapeamentoMidias: mapeamentoMidias,
          posterFrames: posterFrames,
        );

      case ReferenciasMateriaisRelatorio():
        final nomesResolvidos = nodo.uuidsMateriais
            .map((uuid) => _normalizarTextoLatin1(titulosMateriais[uuid] ?? uuid))
            .join(', ');
        return [
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey500),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _normalizarTextoLatin1(nodo.rotulo),
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (nodo.subrotulo.isNotEmpty)
                  pw.Text(
                    _normalizarTextoLatin1(nodo.subrotulo),
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                pw.SizedBox(height: 3),
                pw.Text(
                  nomesResolvidos,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ];

      case SecaoListaRelatorio():
        final widgets = <pw.Widget>[
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _normalizarTextoLatin1(nodo.rotulo),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (nodo.subrotulo.isNotEmpty)
                  pw.Text(
                    _normalizarTextoLatin1(nodo.subrotulo),
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
              ],
            ),
          ),
        ];

        for (final item in nodo.itens) {
          widgets.add(
            pw.Container(
              width: double.infinity,
              margin: const pw.EdgeInsets.only(top: 6),
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                border: pw.Border.all(color: PdfColors.grey500),
              ),
              child: pw.Text(
                _normalizarTextoLatin1(
                  '#${item.indiceFormatado} - ${item.rotuloTipo}',
                ),
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );

          for (final subNodo in item.nodos) {
            final filhosSub = _construirWidgetsNodo(
              nodo: subNodo,
              urlCanonica: urlCanonica,
              mapeamentoMidias: mapeamentoMidias,
              posterFrames: posterFrames,
              titulosMateriais: titulosMateriais,
            );
            for (final w in filhosSub) {
              widgets.add(
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.grey500),
                      right: pw.BorderSide(color: PdfColors.grey500),
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: w,
                ),
              );
            }
          }
          widgets.add(pw.SizedBox(height: 6));
        }

        return widgets;
    }
  }

  pw.Widget _construirCelulaPropriedade(PropriedadeCurtaRelatorio prop) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _normalizarTextoLatin1(prop.rotulo),
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          if (prop.subrotulo.isNotEmpty)
            pw.Text(
              _normalizarTextoLatin1(prop.subrotulo),
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PdfColors.grey600,
              ),
            ),
          pw.SizedBox(height: 2),
          pw.Text(
            _normalizarTextoLatin1(prop.valor),
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _construirWidgetsGaleriaMidias({
    required GaleriaMidiasRelatorio galeria,
    required String urlCanonica,
    required Map<String, String> mapeamentoMidias,
    required Map<String, String> posterFrames,
  }) {
    final widgets = <pw.Widget>[];
    final fotos = <({ItemMidiaRelatorio item, pw.MemoryImage? imagem})>[];
    final videos = <ItemMidiaRelatorio>[];
    final documentos = <ItemMidiaRelatorio>[];

    for (final item in galeria.itens) {
      if (item.midia.hasImagem()) {
        final uuid = item.midia.imagem.uuid;
        final img = _carregarImagemMemoria(mapeamentoMidias[uuid]);
        fotos.add((item: item, imagem: img));
      } else if (item.midia.hasVideo()) {
        videos.add(item);
      } else if (item.midia.hasDocumento()) {
        documentos.add(item);
      }
    }

    // Fotos lado a lado em duas colunas
    for (var i = 0; i < fotos.length; i += 2) {
      final fotoEsq = fotos[i];
      final fotoDir = (i + 1 < fotos.length) ? fotos[i + 1] : null;
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _construirCardFoto(fotoEsq.item, fotoEsq.imagem)),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: fotoDir != null
                    ? _construirCardFoto(fotoDir.item, fotoDir.imagem)
                    : pw.SizedBox(),
              ),
            ],
          ),
        ),
      );
    }

    // Vídeos com poster e QR Code
    for (final itemVid in videos) {
      final uuid = itemVid.midia.video.uuid;
      final imgPoster = _carregarImagemMemoria(posterFrames[uuid]);
      final videoUrl = '$urlCanonica#video-$uuid';

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey500),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _normalizarTextoLatin1(itemVid.rotuloCampo),
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (imgPoster != null) ...[
                    pw.Container(
                      width: 150,
                      height: 110,
                      child: pw.Image(imgPoster, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(width: 12),
                  ],
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: videoUrl,
                    width: 48,
                    height: 48,
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Escaneie para assistir ao vídeo desta proteção online',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          videoUrl,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Documentos PDF rasterizados
    for (final itemDoc in documentos) {
      final doc = itemDoc.midia.documento;
      final nome = doc.nomeOriginal.isNotEmpty
          ? doc.nomeOriginal
          : '${doc.uuid}.pdf';
      final totalPaginas =
          doc.quantidadePaginas > 0 ? doc.quantidadePaginas : 1;

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
          child: pw.Text(
            _normalizarTextoLatin1(itemDoc.rotuloCampo),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );

      for (var i = 1; i <= totalPaginas; i++) {
        final chavePag = '${doc.uuid}_p$i';
        final imgPag = _carregarImagemMemoria(mapeamentoMidias[chavePag]);
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, bottom: 4),
            child: pw.Text(
              _normalizarTextoLatin1('$nome - Página $i de $totalPaginas'),
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        );
        if (imgPag != null) {
          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              height: 220,
              child: pw.Image(imgPag, fit: pw.BoxFit.contain),
            ),
          );
        }
      }
    }

    return widgets;
  }

  pw.Widget _construirCardFoto(
    ItemMidiaRelatorio item,
    pw.MemoryImage? imagem,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _normalizarTextoLatin1(item.rotuloCampo),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (imagem != null) ...[
            pw.SizedBox(height: 4),
            pw.Container(
              height: 150,
              alignment: pw.Alignment.center,
              child: pw.Image(imagem, fit: pw.BoxFit.contain),
            ),
          ],
        ],
      ),
    );
  }

  List<pw.Widget> _construirSecaoRegistro({
    required Registro registro,
    required String idSessao,
    required String urlCanonica,
    required Map<String, String> mapeamentoMidias,
    required Map<String, String> posterFrames,
    required Map<String, String> titulosMateriais,
    String? tituloAnexo,
  }) {
    final arvore = _construtorArvore.construir(registro);
    final widgets = <pw.Widget>[];

    if (tituloAnexo != null) {
      widgets.add(pw.SizedBox(height: 16));
      widgets.add(pw.Divider(thickness: 1.5));
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Text(
            _normalizarTextoLatin1(
              'Anexo - Ficha Técnica de Material: $tituloAnexo',
            ),
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
    }

    final tituloExibicao = arvore.tituloExibicao != arvore.nomeProtocolo
        ? '${arvore.nomeProtocolo} - ${arvore.tituloExibicao}'
        : arvore.nomeProtocolo;

    // Cabeçalho Institucional da Versão Resumida com QR Code vetorial
    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        margin: const pw.EdgeInsets.only(bottom: 12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey700),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _normalizarTextoLatin1(
                      'Fixalog - $tituloExibicao (Versão Resumida)',
                    ),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Este documento é uma representação impressa. O relatório canônico oficial está disponível em:',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    urlCanonica,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _normalizarTextoLatin1(
                      'Protocolo: ${arvore.idProtocolo} (v${arvore.versaoProtocolo}) | Sessão ID: $idSessao',
                    ),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: urlCanonica,
              width: 56,
              height: 56,
            ),
          ],
        ),
      ),
    );

    for (final bloco in arvore.blocos) {
      widgets.add(
        pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(top: 8, bottom: 6),
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey700, width: 1),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _normalizarTextoLatin1(bloco.titulo),
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (bloco.subtitulo.isNotEmpty)
                pw.Text(
                  _normalizarTextoLatin1(bloco.subtitulo),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
            ],
          ),
        ),
      );

      for (final nodo in bloco.nodos) {
        widgets.addAll(
          _construirWidgetsNodo(
            nodo: nodo,
            urlCanonica: urlCanonica,
            mapeamentoMidias: mapeamentoMidias,
            posterFrames: posterFrames,
            titulosMateriais: titulosMateriais,
          ),
        );
      }
    }

    return widgets;
  }

  pw.Widget _construirTextoMarkdownPdf({
    required String texto,
  }) {
    final normalizado = _normalizarTextoLatin1(texto.replaceAll('\r\n', '\n'));
    final spans = <pw.InlineSpan>[];

    final linhas = normalizado.split('\n');
    for (var i = 0; i < linhas.length; i++) {
      if (i > 0) {
        spans.add(const pw.TextSpan(text: '\n'));
      }
      var linha = linhas[i];
      final matchHeading = RegExp(r'^#{1,6}\s+(.*)$').firstMatch(linha.trim());
      if (matchHeading != null) {
        spans.add(
          pw.TextSpan(
            text: matchHeading.group(1)!,
            style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
          ),
        );
        continue;
      }
      final matchBullet = RegExp(r'^[-*]\s+(.*)$').firstMatch(linha.trim());
      if (matchBullet != null) {
        linha = '- ${matchBullet.group(1)!}';
      }
      spans.addAll(_parseInlineMarkdownSpansPdf(linha));
    }

    return pw.RichText(
      text: pw.TextSpan(
        style: const pw.TextStyle(fontSize: 10.5),
        children: spans,
      ),
    );
  }

  List<pw.InlineSpan> _parseInlineMarkdownSpansPdf(String linha) {
    final padrao =
        RegExp(r'(\*\*([^*]+)\*\*|~~([^~]+)~~|`([^`]+)`|\*([^*]+)\*)');
    final resultado = <pw.InlineSpan>[];
    var inicio = 0;

    for (final match in padrao.allMatches(linha)) {
      if (match.start > inicio) {
        resultado.add(pw.TextSpan(text: linha.substring(inicio, match.start)));
      }
      if (match.group(2) != null) {
        resultado.add(
          pw.TextSpan(
            text: match.group(2)!,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        );
      } else if (match.group(3) != null) {
        resultado.add(
          pw.TextSpan(
            text: match.group(3)!,
            style: const pw.TextStyle(
              decoration: pw.TextDecoration.lineThrough,
            ),
          ),
        );
      } else if (match.group(4) != null) {
        resultado.add(
          pw.TextSpan(
            text: match.group(4)!,
            style: pw.TextStyle(font: pw.Font.courier()),
          ),
        );
      } else if (match.group(5) != null) {
        resultado.add(
          pw.TextSpan(
            text: match.group(5)!,
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
          ),
        );
      }
      inicio = match.end;
    }

    if (inicio < linha.length) {
      resultado.add(pw.TextSpan(text: linha.substring(inicio)));
    }
    return resultado;
  }

  /// Gera os bytes do PDF A4 formatado nativamente via `package:pdf` sem WebView.
  ///
  /// Lança [FormatException] caso `registro.yamlConteudo` esteja vazio.
  Future<Uint8List> gerarPdfResumidoBytes({
    required Registro registro,
    required String idSessao,
    required String urlCanonica,
    Map<String, String> mapeamentoMidias = const {},
    Map<String, String> posterFrames = const {},
    List<RelatorioMaterialAnexo> materiaisAnexos = const [],
    String? baseUrl,
  }) async {
    final pdf = pw.Document(compress: false);
    final titulosMateriais = _resolverTitulosMateriais(materiaisAnexos);
    final secaoPrincipal = _construirSecaoRegistro(
      registro: registro,
      idSessao: idSessao,
      urlCanonica: urlCanonica,
      mapeamentoMidias: mapeamentoMidias,
      posterFrames: posterFrames,
      titulosMateriais: titulosMateriais,
    );

    final secoesAnexos = <pw.Widget>[];
    for (final mat in materiaisAnexos) {
      final tituloMat = titulosMateriais[mat.idSessao]!;
      secoesAnexos.addAll(
        _construirSecaoRegistro(
          registro: mat.registro,
          idSessao: mat.idSessao,
          urlCanonica: mat.urlCanonica,
          mapeamentoMidias: mat.mapeamentoMidias,
          posterFrames: mat.posterFrames,
          titulosMateriais: const {},
          tituloAnexo: tituloMat,
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) => [
          ...secaoPrincipal,
          ...secoesAnexos,
        ],
      ),
    );

    return pdf.save();
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
}

final pdfPrintSummaryServiceProvider = Provider<PdfPrintSummaryService>((ref) {
  return PdfPrintSummaryService();
});
