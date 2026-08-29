import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:app/core/models/proto/protos/registro.pb.dart';

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
      if (resposta.hasMidia() && resposta.midia.hasImagem()) {
        await loadImage(resposta.midia.imagem.uuid);
      }
    }

    // Pré-carrega as imagens das listas
    for (final grupo in registro.listas) {
      for (final resposta in grupo.respostasItem.values) {
        if (resposta.hasMidia() && resposta.midia.hasImagem()) {
          await loadImage(resposta.midia.imagem.uuid);
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final children = <pw.Widget>[
            pw.Header(level: 0, child: pw.Text('Relatório do Protocolo: ${registro.idProtocolo}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),
          ];

          if (registro.respostas.isEmpty && registro.listas.isEmpty) {
            children.add(pw.Text('Nenhum dado registrado.'));
            return children;
          }

          // Respostas Simples
          if (registro.respostas.isNotEmpty) {
            children.add(pw.Text('Dados Coletados:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
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
              
              if (valorStr.isNotEmpty) {
                children.add(pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text('$chave: $valorStr', style: const pw.TextStyle(fontSize: 12)),
                ));
              } else if (resp.hasMidia() && resp.midia.hasImagem()) {
                final uuid = resp.midia.imagem.uuid;
                final img = loadedImages[uuid];
                if (img != null) {
                  children.add(pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 10),
                    height: 200,
                    child: pw.Image(img, fit: pw.BoxFit.contain),
                  ));
                }
              }
            }
          }

          // Listas/Grupos Repetidos
          if (registro.listas.isNotEmpty) {
            children.add(pw.SizedBox(height: 20));
            children.add(pw.Text('Evidências Anexadas:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
            children.add(pw.SizedBox(height: 10));

            final wrapChildren = <pw.Widget>[];
            for (final grupo in registro.listas) {
              String desc = '';
              pw.MemoryImage? img;
              
              for (final resp in grupo.respostasItem.values) {
                if (resp.hasTexto()) {
                  desc = resp.texto;
                } else if (resp.hasMidia() && resp.midia.hasImagem()) {
                  img = loadedImages[resp.midia.imagem.uuid];
                }
              }

              if (img != null || desc.isNotEmpty) {
                wrapChildren.add(pw.Container(
                  width: 200,
                  margin: const pw.EdgeInsets.only(bottom: 10, right: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (img != null)
                        pw.Container(
                          width: 200,
                          height: 200,
                          child: pw.Image(img, fit: pw.BoxFit.contain),
                        ),
                      if (desc.isNotEmpty) ...[
                        pw.SizedBox(height: 5),
                        pw.Text(desc, style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic), textAlign: pw.TextAlign.center),
                      ]
                    ]
                  )
                ));
              }
            }

            if (wrapChildren.isNotEmpty) {
              children.add(pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: wrapChildren,
              ));
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
}
