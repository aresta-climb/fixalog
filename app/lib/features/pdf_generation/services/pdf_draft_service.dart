// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/epub_document_builder.dart';

class PdfDraftService {
  /// Gera o PDF estrutural (Rascunho) com textos, imagens estáticas e placeholders
  Future<File> drawDraft(Registro registro, String outputPath, String Function(String) getMediaPath) async {
    final pdf = pw.Document();

    final loadedImages = <String, pw.MemoryImage>{};

    // Função auxiliar para carregar mídia
    Future<void> loadImage(String uuid) async {
      if (loadedImages.containsKey(uuid)) return;
      final path = getMediaPath(uuid);
      if (path.isEmpty) return;
      final file = File(path);
      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();
          loadedImages[uuid] = pw.MemoryImage(bytes);
        } catch (_) {}
      }
    }

    // Pré-carrega as imagens das respostas simples
    for (final resposta in registro.respostas.values) {
      for (final midia in EpubDocumentBuilder.extrairMidiasDeResposta(resposta)) {
        if (midia.hasImagem()) {
          await loadImage(midia.imagem.uuid);
        } else if (midia.hasDocumento()) {
          final doc = midia.documento;
          final total = doc.quantidadePaginas > 0 ? doc.quantidadePaginas : 1;
          for (var i = 1; i <= total; i++) {
            await loadImage('${doc.uuid}_p$i');
          }
        }
      }
    }

    // Pré-carrega as imagens das listas
    for (final grupo in registro.listas) {
      for (final resposta in grupo.respostasItem.values) {
        for (final midia in EpubDocumentBuilder.extrairMidiasDeResposta(resposta)) {
          if (midia.hasImagem()) {
            await loadImage(midia.imagem.uuid);
          } else if (midia.hasDocumento()) {
            final doc = midia.documento;
            final total = doc.quantidadePaginas > 0 ? doc.quantidadePaginas : 1;
            for (var i = 1; i <= total; i++) {
              await loadImage('${doc.uuid}_p$i');
            }
          }
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final children = <pw.Widget>[
            pw.Header(
              level: 0,
              child: pw.Text(
                'Relatório do Protocolo: ${registro.idProtocolo}',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
          ];

          if (registro.respostas.isEmpty && registro.listas.isEmpty) {
            children.add(pw.Text('Nenhum dado registrado.'));
            return children;
          }

          // Respostas Simples
          if (registro.respostas.isNotEmpty) {
            children.add(
              pw.Text(
                'Dados Coletados:',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            );
            children.add(pw.SizedBox(height: 10));

            for (final entry in registro.respostas.entries) {
              final chave = entry.key;
              final resp = entry.value;
              String valorStr = '';
              if (resp.hasTexto()) {
                valorStr = resp.texto;
              } else if (resp.hasNumero()) {
                valorStr = resp.numero.toString();
              } else if (resp.hasInteiro()) {
                valorStr = resp.inteiro.toString();
              } else if (resp.hasBooleano()) {
                valorStr = resp.booleano ? 'Sim' : 'Não';
              }

              final midiasResp = EpubDocumentBuilder.extrairMidiasDeResposta(resp);
              if (valorStr.isNotEmpty) {
                children.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: _construirTextoMarkdownPdf(
                      prefixoChave: '$chave: ',
                      texto: valorStr,
                    ),
                  ),
                );
              } else if (midiasResp.isNotEmpty) {
                for (final midia in midiasResp) {
                  if (midia.hasImagem()) {
                    final uuid = midia.imagem.uuid;
                    final img = loadedImages[uuid];
                    if (img != null) {
                      children.add(
                        pw.Container(
                          margin: const pw.EdgeInsets.symmetric(vertical: 10),
                          height: 200,
                          child: pw.Image(img, fit: pw.BoxFit.contain),
                        ),
                      );
                    }
                  } else if (midia.hasDocumento()) {
                    final doc = midia.documento;
                    final total = doc.quantidadePaginas > 0 ? doc.quantidadePaginas : 1;
                    for (var i = 1; i <= total; i++) {
                      final img = loadedImages['${doc.uuid}_p$i'];
                      if (img != null) {
                        children.add(
                          pw.Container(
                            margin: const pw.EdgeInsets.symmetric(vertical: 10),
                            height: 200,
                            child: pw.Image(img, fit: pw.BoxFit.contain),
                          ),
                        );
                      }
                    }
                  }
                }
              }
            }
          }

          // Listas/Grupos Repetidos
          if (registro.listas.isNotEmpty) {
            children.add(pw.SizedBox(height: 20));
            children.add(
              pw.Text(
                'Evidências Anexadas:',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            );
            children.add(pw.SizedBox(height: 10));

            final wrapChildren = <pw.Widget>[];
            for (final grupo in registro.listas) {
              String desc = '';
              final imgsGrupo = <pw.MemoryImage>[];

              for (final resp in grupo.respostasItem.values) {
                if (resp.hasTexto()) {
                  desc = resp.texto;
                } else {
                  for (final midia in EpubDocumentBuilder.extrairMidiasDeResposta(resp)) {
                    if (midia.hasImagem()) {
                      final img = loadedImages[midia.imagem.uuid];
                      if (img != null) imgsGrupo.add(img);
                    } else if (midia.hasDocumento()) {
                      final doc = midia.documento;
                      final total = doc.quantidadePaginas > 0 ? doc.quantidadePaginas : 1;
                      for (var i = 1; i <= total; i++) {
                        final img = loadedImages['${doc.uuid}_p$i'];
                        if (img != null) imgsGrupo.add(img);
                      }
                    }
                  }
                }
              }

              if (imgsGrupo.isNotEmpty || desc.isNotEmpty) {
                wrapChildren.add(
                  pw.Container(
                    width: 200,
                    margin: const pw.EdgeInsets.only(bottom: 10, right: 10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        for (final img in imgsGrupo)
                          pw.Container(
                            width: 200,
                            height: 200,
                            child: pw.Image(img, fit: pw.BoxFit.contain),
                          ),
                        if (desc.isNotEmpty) ...[
                          pw.SizedBox(height: 5),
                          _construirTextoMarkdownPdf(
                            texto: desc,
                            centralizar: true,
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }
            }

            if (wrapChildren.isNotEmpty) {
              children.add(
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: wrapChildren,
                ),
              );
            }
          }

          return children;
        },
      ),
    );

    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _construirTextoMarkdownPdf({
    String prefixoChave = '',
    required String texto,
    bool centralizar = false,
  }) {
    final normalizado = texto.replaceAll('\r\n', '\n');
    final spans = <pw.InlineSpan>[];
    if (prefixoChave.isNotEmpty) {
      spans.add(
        pw.TextSpan(
          text: prefixoChave,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      );
    }

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
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
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
      textAlign: centralizar ? pw.TextAlign.center : pw.TextAlign.left,
      text: pw.TextSpan(
        style: const pw.TextStyle(fontSize: 12),
        children: spans,
      ),
    );
  }

  List<pw.InlineSpan> _parseInlineMarkdownSpansPdf(String linha) {
    final padrao = RegExp(r'(\*\*([^*]+)\*\*|~~([^~]+)~~|`([^`]+)`|\*([^*]+)\*)');
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
            style: const pw.TextStyle(decoration: pw.TextDecoration.lineThrough),
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
}
