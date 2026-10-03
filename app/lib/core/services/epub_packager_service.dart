// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

/// Serviço responsável pelo empacotamento de relatórios no formato padronizado EPUB 3 (OCF/W3C).
///
/// Monta a estrutura canônica de diretórios (mimetype sem compressão, META-INF e OEBPS),
/// incluindo páginas XHTML, folhas de estilo CSS, dados brutos em Protobuf,
/// ativos multimídia (fotos e vídeos) e assinaturas digitais W3C XML-DSig.
class EpubPackagerService {
  /// Determina o tipo MIME correspondente a partir da extensão do arquivo.
  String determinarTipoMime(String caminho) {
    final minusculo = caminho.toLowerCase();
    if (minusculo.endsWith('.webp')) return 'image/webp';
    if (minusculo.endsWith('.jpg') || minusculo.endsWith('.jpeg')) return 'image/jpeg';
    if (minusculo.endsWith('.png')) return 'image/png';
    if (minusculo.endsWith('.mp4')) return 'video/mp4';
    if (minusculo.endsWith('.css')) return 'text/css';
    if (minusculo.endsWith('.xhtml') || minusculo.endsWith('.html')) return 'application/xhtml+xml';
    if (minusculo.endsWith('.binarypb')) return 'application/x-protobuf';
    return 'application/octet-stream';
  }

  /// Empacota todos os recursos fornecidos em um arquivo binário ZIP compatível com a especificação EPUB 3.
  Uint8List empacotarEpub({
    required String idSessao,
    required String idProtocolo,
    required String xhtmlConteudo,
    required String cssConteudo,
    required Uint8List binarypb,
    Map<String, Uint8List> arquivosMidia = const {},
    String? signaturesXml,
  }) {
    final arquivoZip = Archive();

    // 1. Arquivo 'mimetype' - DEVE ser o primeiro arquivo e armazenado sem compressão (CompressionType.none)
    final bytesMime = utf8.encode('application/epub+zip');
    final entradaMime = ArchiveFile('mimetype', bytesMime.length, bytesMime)
      ..compression = CompressionType.none;
    arquivoZip.addFile(entradaMime);

    // 2. META-INF/container.xml
    final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
    final bytesContainer = utf8.encode(containerXml);
    arquivoZip.addFile(ArchiveFile('META-INF/container.xml', bytesContainer.length, bytesContainer));

    // 3. META-INF/signatures.xml (se fornecido)
    if (signaturesXml != null && signaturesXml.isNotEmpty) {
      final bytesSig = utf8.encode(signaturesXml);
      arquivoZip.addFile(ArchiveFile('META-INF/signatures.xml', bytesSig.length, bytesSig));
    }

    // 4. OEBPS/nav.xhtml (Documento de navegação obrigatório no EPUB 3)
    final navXhtml = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="pt-BR">
<head>
  <meta charset="utf-8"/>
  <title>Sumário</title>
</head>
<body>
  <nav epub:type="toc" id="toc">
    <h1>Sumário de Navegação</h1>
    <ol>
      <li><a href="relatorio.xhtml">Relatório de Vistoria</a></li>
    </ol>
  </nav>
</body>
</html>''';
    final bytesNav = utf8.encode(navXhtml);
    arquivoZip.addFile(ArchiveFile('OEBPS/nav.xhtml', bytesNav.length, bytesNav));

    // 5. OEBPS/relatorio.xhtml e OEBPS/estilo.css
    final bytesXhtml = utf8.encode(xhtmlConteudo);
    arquivoZip.addFile(ArchiveFile('OEBPS/relatorio.xhtml', bytesXhtml.length, bytesXhtml));

    final bytesCss = utf8.encode(cssConteudo);
    arquivoZip.addFile(ArchiveFile('OEBPS/estilo.css', bytesCss.length, bytesCss));

    // 6. OEBPS/dados/registro.binarypb (Protobuf original da vistoria)
    arquivoZip.addFile(ArchiveFile('OEBPS/dados/registro.binarypb', binarypb.length, binarypb));

    // 7. Mídias (fotos e vídeos)
    for (final entrada in arquivosMidia.entries) {
      final caminhoRelativo = entrada.key.startsWith('OEBPS/') ? entrada.key : 'OEBPS/${entrada.key}';
      final bytesMidia = entrada.value;
      arquivoZip.addFile(ArchiveFile(caminhoRelativo, bytesMidia.length, bytesMidia));
    }

    // 8. OEBPS/content.opf (Manifesto do pacote EPUB 3)
    final bufferOpf = StringBuffer();
    final dataModificacao = DateTime.now().toUtc().toIso8601String().split('.').first + 'Z';

    bufferOpf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    bufferOpf.writeln('<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id">');
    bufferOpf.writeln('  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">');
    bufferOpf.writeln('    <dc:identifier id="pub-id">$idSessao</dc:identifier>');
    bufferOpf.writeln('    <dc:title>$idProtocolo</dc:title>');
    bufferOpf.writeln('    <dc:language>pt-BR</dc:language>');
    bufferOpf.writeln('    <meta property="dcterms:modified">$dataModificacao</meta>');
    bufferOpf.writeln('  </metadata>');
    bufferOpf.writeln('  <manifest>');
    bufferOpf.writeln('    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>');
    bufferOpf.writeln('    <item id="relatorio" href="relatorio.xhtml" media-type="application/xhtml+xml"/>');
    bufferOpf.writeln('    <item id="estilo" href="estilo.css" media-type="text/css"/>');
    bufferOpf.writeln('    <item id="dados-protobuf" href="dados/registro.binarypb" media-type="application/x-protobuf"/>');

    var contadorItem = 1;
    for (final entrada in arquivosMidia.entries) {
      final idItem = 'midia_$contadorItem';
      final caminhoNoOpf = entrada.key.replaceFirst('OEBPS/', '');
      final tipoMime = determinarTipoMime(caminhoNoOpf);
      bufferOpf.writeln('    <item id="$idItem" href="$caminhoNoOpf" media-type="$tipoMime"/>');
      contadorItem++;
    }

    bufferOpf.writeln('  </manifest>');
    bufferOpf.writeln('  <spine>');
    bufferOpf.writeln('    <itemref idref="relatorio"/>');
    bufferOpf.writeln('  </spine>');
    bufferOpf.writeln('</package>');

    final bytesOpf = utf8.encode(bufferOpf.toString());
    arquivoZip.addFile(ArchiveFile('OEBPS/content.opf', bytesOpf.length, bytesOpf));

    // Codifica tudo em formato ZIP padrão
    final encoder = ZipEncoder();
    final bytesFinal = encoder.encode(arquivoZip);
    return Uint8List.fromList(bytesFinal);
  }
}
