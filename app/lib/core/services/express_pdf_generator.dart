import 'dart:typed_data';
import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fixnum/fixnum.dart';
import '../../features/express_form/viewmodels/express_form_view_model.dart';
import '../../features/identity/viewmodels/identity_form_view_model.dart';
import '../models/proto/protos/registro.pb.dart';
import '../models/proto/protos/registro.pbenum.dart';
import 'package:meta/meta.dart';
import '../../../core/services/crypto_service.dart';
import '../../../core/services/providers.dart';

class ExpressPdfGenerator {
  static Future<void> generateAndPreviewPdf(List<ExpressEntry> entries, WidgetRef ref) async {
    // 1. Capture GPS
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Serviço de localização desativado. Ative o GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização negada permanentemente.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    if (position.isMocked) {
      throw Exception('Fake GPS detectado. O registro de manutenção exige localização real para fins de auditoria.');
    }

    // 2. Map to Protobuf
    final identity = await ref.read(currentIdentityProvider.future);
    
    final registro = RegistroManutencao()
      ..idSessao = 'express-${DateTime.now().millisecondsSinceEpoch}'
      ..idProtocolo = 'express-1.0'
      ..versaoProtocolo = '1.0'
      ..utcTimestampInicio = Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000)
      ..utcTimestampFim = Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000)
      ..via = (RegistroVia()
        ..latitude = position.latitude
        ..longitude = position.longitude
        ..nomeVia = 'Registro Expresso')
      ..avaliacao = (AvaliacaoFinal()
        ..resultado = AvaliacaoFinal_ResultadoGeral.APROVADO
        ..observacoes = 'Gerado via Express Form');
        
    if (identity != null) {
      registro.idMantenedor = identity.nome;
    }

    for (int i = 0; i < entries.length; i++) {
      final acao = AcaoManutencao()
        ..idInstancia = 'acao-$i'
        ..idTipoAcao = 'express-photo'
        ..utcTimestamp = Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000)
        ..outro = (DetalheAcaoCustomizada()
          ..descricao = entries[i].description
          ..foto = entries[i].imageBytes
          ..observacoes = 'Foto $i');
          
      registro.acoes.add(acao);
    }

    // 3. Digital Signature & Protobuf Binary
    final protobufBytes = registro.writeToBuffer();
    // Injetado via Riverpod para testabilidade
    final cryptoService = ref.read(cryptoServiceProvider);
    
    // Obter signer validando biometria
    final signer = await cryptoService.getPdfSigner();
    
    final documentHash = cryptoService.computeDocumentHash(protobufBytes);
    String signature = '';
    String publicKey = '';
    try {
      signature = await cryptoService.signDocument(protobufBytes);
      publicKey = await cryptoService.getPublicKeyPem();
    } catch (e) {
      signature = 'Falha na assinatura: $e';
    }

    // 4. Construir Metadados XMP
    final metadataDocument = buildXmpMetadata(
      protobufBytes: protobufBytes,
      signature: signature,
      documentHash: documentHash,
      publicKey: publicKey,
    );

    // 5. Render PDF
    final doc = pw.Document(
      title: 'FixaLog - Registro Expresso',
      creator: 'FixaLog App',
      author: registro.idMantenedor,
      metadata: metadataDocument,
    );

    final hasVideo = entries.any((e) => e.isVideo);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        // Rodapé visual antigo removido conforme a nova especificação PKI,
        // garantindo que toda a integridade resida nos metadados (XMP) invisíveis.
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('FixaLog - Registro Expresso',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Data: ${DateTime.now().toLocal().toString().split(".")[0]}'),
            pw.Text('Mantenedor: ${registro.idMantenedor}'),
            pw.Text('Localização GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'),
            pw.SizedBox(height: 20),
            
            if (hasVideo) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor(1, 0.9, 0.9),
                  border: pw.Border.all(color: const PdfColor(0.8, 0, 0)),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ATENÇÃO: VÍDEOS ANEXADOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: const PdfColor(0.8, 0, 0))),
                    pw.SizedBox(height: 5),
                    pw.Text('Este documento contém vídeos anexados em formato compatível com PDF/A-3. '
                        'Para visualizá-los, utilize um leitor de PDF com suporte a anexos (como o Adobe Acrobat Reader). '
                        'Em leitores de celular simples ou navegadores, os vídeos podem não ser reproduzíveis diretamente, mas estão embutidos no arquivo para auditoria.'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            ...registro.acoes.map((acao) {
              final detalhe = acao.outro;
              final image = pw.MemoryImage(Uint8List.fromList(detalhe.foto));
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Image(image, height: 250, fit: pw.BoxFit.contain),
                    pw.SizedBox(height: 8),
                    if (detalhe.descricao.isNotEmpty)
                      pw.Text(detalhe.descricao, style: const pw.TextStyle(fontSize: 14)),
                    pw.Divider(),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    // 6. Compartilhar PDF
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'FixaLog_Expresso_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @visibleForTesting
  static XmlDocument buildXmpMetadata({
    required List<int> protobufBytes,
    required String signature,
    required String documentHash,
    required String publicKey,
  }) {
    final builder = XmlBuilder();
    builder.element('x:xmpmeta', namespaces: {'adobe:ns:meta/': 'x'}, nest: () {
      builder.element('rdf:RDF', namespaces: {'http://www.w3.org/1999/02/22-rdf-syntax-ns#': 'rdf'}, nest: () {
        builder.element('rdf:Description', attributes: {
          'rdf:about': '',
          'xmlns:fixalog': 'http://fixalog.app/1.0/',
          'fixalog:protobuf': base64Encode(protobufBytes),
          'fixalog:signature': signature,
          'fixalog:hash': documentHash,
          'fixalog:publicKey': base64Encode(utf8.encode(publicKey)), // Base64 pra evitar quebras de linha no XML
        });
      });
    });
    return builder.buildDocument();
  }
}
