// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';

/// Serviço responsável pelo empacotamento de relatórios no formato padronizado EPUB 3 (OCF/W3C).
///
/// Monta a estrutura canônica de diretórios (mimetype sem compressão, META-INF e OEBPS),
/// incluindo páginas XHTML, folhas de estilo CSS, fontes TTF da família Google Noto Sans,
/// dados brutos em Protobuf, ativos multimídia (fotos e vídeos), materiais aninhados
/// (`OEBPS/materiais/<uuid>/`) e assinaturas digitais W3C XML-DSig.
class EpubPackagerService {
  static final Map<String, Uint8List> _cacheFontes = {};

  /// Determina o tipo MIME correspondente a partir da extensão do arquivo.
  String determinarTipoMime(String caminho) {
    final minusculo = caminho.toLowerCase();
    if (minusculo.endsWith('.webp')) return 'image/webp';
    if (minusculo.endsWith('.jpg') || minusculo.endsWith('.jpeg')) return 'image/jpeg';
    if (minusculo.endsWith('.png')) return 'image/png';
    if (minusculo.endsWith('.mp4')) return 'video/mp4';
    if (minusculo.endsWith('.pdf')) return 'application/pdf';
    if (minusculo.endsWith('.css')) return 'text/css';
    if (minusculo.endsWith('.xhtml') || minusculo.endsWith('.html')) return 'application/xhtml+xml';
    if (minusculo.endsWith('.xml') || minusculo.endsWith('.opf')) return 'application/xml';
    if (minusculo.endsWith('.binarypb')) return 'application/x-protobuf';
    if (minusculo.endsWith('.ttf')) return 'font/ttf';
    return 'application/octet-stream';
  }

  /// Retorna os nomes dos arquivos TTF da família Google Noto Sans necessários para [codigoIdioma].
  List<String> nomesFontesParaIdioma(String codigoIdioma) {
    final codigoNorm = codigoIdioma.split(RegExp(r'[-_]')).first.toLowerCase();
    final fontes = <String>['NotoSans-Regular.ttf', 'NotoSans-Bold.ttf'];
    if (codigoNorm == 'ar') {
      fontes.addAll(['NotoSansArabic-Regular.ttf', 'NotoSansArabic-Bold.ttf']);
    } else if (codigoNorm == 'ja') {
      fontes.addAll(['NotoSansJP-Regular.ttf', 'NotoSansJP-Bold.ttf']);
    }
    return fontes;
  }

  /// Carrega dos assets locais apenas os arquivos TTF de `Noto Sans` necessários para [codigoIdioma].
  Map<String, Uint8List> obterFontesNotoSansParaIdioma(String codigoIdioma) {
    final resultado = <String, Uint8List>{};
    for (final nomeArquivo in nomesFontesParaIdioma(codigoIdioma)) {
      final bytes = _cacheFontes.putIfAbsent(
        nomeArquivo,
        () => File('assets/fonts/$nomeArquivo').readAsBytesSync(),
      );
      resultado['fonts/$nomeArquivo'] = bytes;
    }
    return resultado;
  }

  /// Extrai todos os arquivos internos de um pacote `.epub` de material (exceto `mimetype`)
  /// para que possam ser aninhados intactos em `OEBPS/materiais/<uuid>/`.
  Map<String, Uint8List> extrairArquivosDeEpubAninhado(Uint8List epubBytes) {
    final zip = ZipDecoder().decodeBytes(epubBytes);
    final resultado = <String, Uint8List>{};
    for (final file in zip.files) {
      if (!file.isFile) continue;
      if (file.name == 'mimetype') continue;
      resultado[file.name] = Uint8List.fromList(file.content as List<int>);
    }
    return resultado;
  }

  /// Indica se o arquivo já é uma mídia comprimida e deve ser armazenado com método STORE (`CompressionType.none`).
  bool _deveArmazenarSemCompressao(String caminho) {
    final minusculo = caminho.toLowerCase();
    return minusculo.endsWith('.mp4') ||
        minusculo.endsWith('.webp') ||
        minusculo.endsWith('.jpg') ||
        minusculo.endsWith('.jpeg') ||
        minusculo.endsWith('.png') ||
        minusculo.endsWith('.pdf');
  }

  /// Empacota todos os recursos fornecidos em um arquivo binário ZIP compatível com a especificação EPUB 3.
  Uint8List empacotarEpub({
    required String idSessao,
    required String idProtocolo,
    required String xhtmlConteudo,
    required String cssConteudo,
    required Uint8List binarypb,
    Map<String, Uint8List> arquivosMidia = const {},
    Map<String, Map<String, Uint8List>> materiaisAninhados = const {},
    Map<String, String> titulosMateriais = const {},
    String? signaturesXml,
    String codigoIdioma = 'pt-BR',
    Map<String, Uint8List> arquivosFonte = const {},
    bool incluirFontesNotoSans = false,
  }) {
    final arquivoZip = Archive();
    final codigoNorm = codigoIdioma.split(RegExp(r'[-_]')).first.toLowerCase();
    final atributoDir = codigoNorm == 'ar' ? ' dir="rtl"' : '';
    final fontesEfetivas = arquivosFonte.isNotEmpty
        ? arquivosFonte
        : (incluirFontesNotoSans
            ? obterFontesNotoSansParaIdioma(codigoIdioma)
            : const <String, Uint8List>{});

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
    final itensNavMateriais = StringBuffer();
    for (final uuidMat in materiaisAninhados.keys) {
      final nomeMat = titulosMateriais[uuidMat]?.trim() ?? '';
      final rotuloNav = nomeMat.isNotEmpty ? nomeMat : uuidMat;
      itensNavMateriais.writeln(
        '      <li><a href="materiais/$uuidMat/OEBPS/relatorio.xhtml">Material: $rotuloNav</a></li>',
      );
    }

    final navXhtml = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="$codigoIdioma"$atributoDir>
<head>
  <meta charset="utf-8"/>
  <title>Sumário</title>
</head>
<body>
  <nav epub:type="toc" id="toc">
    <h1>Sumário de Navegação</h1>
    <ol>
      <li><a href="relatorio.xhtml">Relatório de Vistoria</a></li>
${itensNavMateriais.toString().trimRight()}
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

    // 5b. Fontes tipográficas Noto Sans em OEBPS/fonts/ comprimidas com DEFLATE
    for (final entradaFonte in fontesEfetivas.entries) {
      final caminhoRelativo = entradaFonte.key.startsWith('OEBPS/')
          ? entradaFonte.key
          : 'OEBPS/${entradaFonte.key}';
      final bytesFonte = entradaFonte.value;
      final arquivoFonte = ArchiveFile(caminhoRelativo, bytesFonte.length, bytesFonte)
        ..compression = CompressionType.deflate;
      arquivoZip.addFile(arquivoFonte);
    }

    // 6. OEBPS/dados/registro.binarypb (Protobuf original da vistoria)
    arquivoZip.addFile(ArchiveFile('OEBPS/dados/registro.binarypb', binarypb.length, binarypb));

    // 7. Mídias (fotos e vídeos)
    for (final entrada in arquivosMidia.entries) {
      final caminhoRelativo = entrada.key.startsWith('OEBPS/') ? entrada.key : 'OEBPS/${entrada.key}';
      final bytesMidia = entrada.value;
      final arquivo = ArchiveFile(caminhoRelativo, bytesMidia.length, bytesMidia)
        ..compression = _deveArmazenarSemCompressao(caminhoRelativo)
            ? CompressionType.none
            : CompressionType.deflate;
      arquivoZip.addFile(arquivo);
    }

    // 7b. Materiais Aninhados em OEBPS/materiais/<uuid>/
    for (final entradaMat in materiaisAninhados.entries) {
      final uuidMat = entradaMat.key;
      final arquivosDoMaterial = entradaMat.value;
      for (final arquivoMat in arquivosDoMaterial.entries) {
        final caminhoInterno = arquivoMat.key;
        final bytesMat = arquivoMat.value;
        final caminhoNoZip = 'OEBPS/materiais/$uuidMat/$caminhoInterno';
        final arquivo = ArchiveFile(caminhoNoZip, bytesMat.length, bytesMat)
          ..compression = _deveArmazenarSemCompressao(caminhoInterno)
              ? CompressionType.none
              : CompressionType.deflate;
        arquivoZip.addFile(arquivo);
      }
    }

    // 8. OEBPS/content.opf (Manifesto do pacote EPUB 3)
    final bufferOpf = StringBuffer();
    final dataModificacao = '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';

    bufferOpf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    bufferOpf.writeln('<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id">');
    bufferOpf.writeln('  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">');
    bufferOpf.writeln('    <dc:identifier id="pub-id">$idSessao</dc:identifier>');
    bufferOpf.writeln('    <dc:title>$idProtocolo</dc:title>');
    bufferOpf.writeln('    <dc:language>$codigoIdioma</dc:language>');
    bufferOpf.writeln('    <meta property="dcterms:modified">$dataModificacao</meta>');
    bufferOpf.writeln('  </metadata>');
    bufferOpf.writeln('  <manifest>');
    bufferOpf.writeln('    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>');
    bufferOpf.writeln('    <item id="relatorio" href="relatorio.xhtml" media-type="application/xhtml+xml"/>');
    bufferOpf.writeln('    <item id="estilo" href="estilo.css" media-type="text/css"/>');
    bufferOpf.writeln('    <item id="dados-protobuf" href="dados/registro.binarypb" media-type="application/x-protobuf"/>');

    var contadorFonte = 1;
    for (final entradaFonte in fontesEfetivas.entries) {
      final idFonte = 'fonte_$contadorFonte';
      final caminhoNoOpf = entradaFonte.key.replaceFirst('OEBPS/', '');
      final tipoMime = determinarTipoMime(caminhoNoOpf);
      bufferOpf.writeln('    <item id="$idFonte" href="$caminhoNoOpf" media-type="$tipoMime"/>');
      contadorFonte++;
    }

    var contadorItem = 1;
    for (final entrada in arquivosMidia.entries) {
      final idItem = 'midia_$contadorItem';
      final caminhoNoOpf = entrada.key.replaceFirst('OEBPS/', '');
      final tipoMime = determinarTipoMime(caminhoNoOpf);
      bufferOpf.writeln('    <item id="$idItem" href="$caminhoNoOpf" media-type="$tipoMime"/>');
      contadorItem++;
    }

    var contadorMaterialItem = 1;
    for (final entradaMat in materiaisAninhados.entries) {
      final uuidMat = entradaMat.key;
      for (final caminhoInterno in entradaMat.value.keys) {
        final idItem = 'mat_$contadorMaterialItem';
        final hrefNoOpf = 'materiais/$uuidMat/$caminhoInterno';
        final tipoMime = determinarTipoMime(caminhoInterno);
        bufferOpf.writeln('    <item id="$idItem" href="$hrefNoOpf" media-type="$tipoMime"/>');
        contadorMaterialItem++;
      }
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
