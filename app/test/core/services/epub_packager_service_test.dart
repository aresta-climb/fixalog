// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/services/epub_packager_service.dart';

void main() {
  group('EpubPackagerService - Testes Unitários', () {
    late EpubPackagerService empacotador;

    setUp(() {
      empacotador = EpubPackagerService();
    });

    test('empacotarEpub deve gerar arquivo ZIP com mimetype sem compressão no primeiro arquivo', () {
      final epubBytes = empacotador.empacotarEpub(
        idSessao: 'sessao_123',
        idProtocolo: 'via_teste',
        xhtmlConteudo: '<html><body>Teste</body></html>',
        cssConteudo: 'body { color: black; }',
        binarypb: Uint8List.fromList([0x08, 0x96, 0x01]),
        arquivosMidia: {
          'midias/foto.webp': Uint8List.fromList([1, 2, 3]),
          'midias/video.mp4': Uint8List.fromList([4, 5, 6]),
        },
      );

      expect(epubBytes, isNotEmpty);

      // Decodifica o ZIP usando a biblioteca archive
      final zip = ZipDecoder().decodeBytes(epubBytes);

      // Regra obrigatória do OCF: o primeiro arquivo deve ser o mimetype
      final primeiroArquivo = zip.files.first;
      expect(primeiroArquivo.name, equals('mimetype'));
      expect(utf8.decode(primeiroArquivo.content as List<int>), equals('application/epub+zip'));
      // Mimetype deve ser armazenado sem compressão (método STORE = 0)
      expect(primeiroArquivo.compression, equals(CompressionType.none));
    });

    test('empacotarEpub deve conter META-INF/container.xml apontando para OEBPS/content.opf', () {
      final epubBytes = empacotador.empacotarEpub(
        idSessao: 'sessao_123',
        idProtocolo: 'via_teste',
        xhtmlConteudo: '<html><body>Teste</body></html>',
        cssConteudo: 'body { color: black; }',
        binarypb: Uint8List.fromList([1, 2, 3]),
      );

      final zip = ZipDecoder().decodeBytes(epubBytes);
      final containerFile = zip.files.firstWhere((f) => f.name == 'META-INF/container.xml');
      final containerXml = utf8.decode(containerFile.content as List<int>);

      expect(containerXml, contains('full-path="OEBPS/content.opf"'));
      expect(containerXml, contains('media-type="application/oebps-package+xml"'));
    });

    test('empacotarEpub deve gerar manifesto content.opf com todos os itens declarados', () {
      final epubBytes = empacotador.empacotarEpub(
        idSessao: 'sessao_456',
        idProtocolo: 'via_fenda',
        xhtmlConteudo: '<html><body>Conteudo</body></html>',
        cssConteudo: 'body { margin: 0; }',
        binarypb: Uint8List.fromList([10, 20, 30]),
        arquivosMidia: {
          'midias/foto1.webp': Uint8List.fromList([1, 2]),
          'midias/foto2.jpg': Uint8List.fromList([3, 4]),
          'midias/foto3.png': Uint8List.fromList([5, 6]),
          'midias/video1.mp4': Uint8List.fromList([7, 8]),
          'midias/nota.pdf': Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
        },
      );

      final zip = ZipDecoder().decodeBytes(epubBytes);
      final opfFile = zip.files.firstWhere((f) => f.name == 'OEBPS/content.opf');
      final opfConteudo = utf8.decode(opfFile.content as List<int>);

      expect(opfConteudo, contains('<dc:identifier id="pub-id">sessao_456</dc:identifier>'));
      expect(opfConteudo, contains('<dc:title>via_fenda</dc:title>'));
      expect(opfConteudo, contains('href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"'));
      expect(opfConteudo, contains('href="relatorio.xhtml" media-type="application/xhtml+xml"'));
      expect(opfConteudo, contains('href="estilo.css" media-type="text/css"'));
      expect(opfConteudo, contains('href="dados/registro.binarypb" media-type="application/x-protobuf"'));
      expect(opfConteudo, contains('href="midias/foto1.webp" media-type="image/webp"'));
      expect(opfConteudo, contains('href="midias/foto2.jpg" media-type="image/jpeg"'));
      expect(opfConteudo, contains('href="midias/foto3.png" media-type="image/png"'));
      expect(opfConteudo, contains('href="midias/video1.mp4" media-type="video/mp4"'));
      expect(opfConteudo, contains('href="midias/nota.pdf" media-type="application/pdf"'));
    });

    test('empacotarEpub deve incluir META-INF/signatures.xml quando fornecido', () {
      final epubBytes = empacotador.empacotarEpub(
        idSessao: 'sessao_assinada',
        idProtocolo: 'via_assinada',
        xhtmlConteudo: '<html><body>Assinado</body></html>',
        cssConteudo: 'body {}',
        binarypb: Uint8List.fromList([99]),
        signaturesXml: '<signatures><Signature>abc</Signature></signatures>',
      );

      final zip = ZipDecoder().decodeBytes(epubBytes);
      final sigFile = zip.files.firstWhere((f) => f.name == 'META-INF/signatures.xml');
      expect(utf8.decode(sigFile.content as List<int>), contains('<Signature>abc</Signature>'));
    });

    test('empacotarEpub deve criar nav.xhtml válido com o sumário e nomes reais dos materiais', () {
      final epubBytes = empacotador.empacotarEpub(
        idSessao: 'sessao_nav',
        idProtocolo: 'via_nav',
        xhtmlConteudo: '<html><body>Nav</body></html>',
        cssConteudo: 'body {}',
        binarypb: Uint8List.fromList([0]),
        materiaisAninhados: {
          'uuid-mat-1': {'OEBPS/relatorio.xhtml': Uint8List.fromList([1])},
          'uuid-mat-2': {'OEBPS/relatorio.xhtml': Uint8List.fromList([2])},
        },
        titulosMateriais: {
          'uuid-mat-1': 'Kit Parabolt Inox 316L',
        },
      );

      final zip = ZipDecoder().decodeBytes(epubBytes);
      final navFile = zip.files.firstWhere((f) => f.name == 'OEBPS/nav.xhtml');
      final navXml = utf8.decode(navFile.content as List<int>);
      expect(navXml, contains('epub:type="toc"'));
      expect(navXml, contains('<a href="relatorio.xhtml">Relatório de Vistoria</a>'));
      expect(
        navXml,
        contains('<a href="materiais/uuid-mat-1/OEBPS/relatorio.xhtml">Material: Kit Parabolt Inox 316L</a>'),
      );
      expect(
        navXml,
        contains('<a href="materiais/uuid-mat-2/OEBPS/relatorio.xhtml">Material: uuid-mat-2</a>'),
      );
    });

    test('determinarTipoMime deve resolver corretamente todos os formatos e fallback', () {
      expect(empacotador.determinarTipoMime('teste.webp'), equals('image/webp'));
      expect(empacotador.determinarTipoMime('teste.jpg'), equals('image/jpeg'));
      expect(empacotador.determinarTipoMime('teste.jpeg'), equals('image/jpeg'));
      expect(empacotador.determinarTipoMime('teste.png'), equals('image/png'));
      expect(empacotador.determinarTipoMime('teste.mp4'), equals('video/mp4'));
      expect(empacotador.determinarTipoMime('teste.pdf'), equals('application/pdf'));
      expect(empacotador.determinarTipoMime('teste.css'), equals('text/css'));
      expect(empacotador.determinarTipoMime('teste.xhtml'), equals('application/xhtml+xml'));
      expect(empacotador.determinarTipoMime('teste.html'), equals('application/xhtml+xml'));
      expect(empacotador.determinarTipoMime('teste.binarypb'), equals('application/x-protobuf'));
      expect(empacotador.determinarTipoMime('fonts/NotoSans-Regular.ttf'), equals('font/ttf'));
      expect(empacotador.determinarTipoMime('teste.desconhecido'), equals('application/octet-stream'));
    });

    test('empacotarEpub deve incorporar a árvore extraída de materiais em OEBPS/materiais/<uuid>/ preservando signatures.xml e registro.binarypb originais', () {
      final epubMaterialBytes = empacotador.empacotarEpub(
        idSessao: 'uuid-mat-1',
        idProtocolo: 'cadastro_material',
        xhtmlConteudo: '<html><body>Ficha do Material</body></html>',
        cssConteudo: 'body { color: #fff; }',
        binarypb: Uint8List.fromList([0x0A, 0x0B, 0x0C]),
        arquivosMidia: {
          'midias/nota_fiscal.webp': Uint8List.fromList([9, 8, 7]),
        },
        signaturesXml: '<signatures><Signature id="AssinaturaMaterialOriginal"/></signatures>',
      );

      final arquivosExtraidosMat = empacotador.extrairArquivosDeEpubAninhado(epubMaterialBytes);
      expect(arquivosExtraidosMat.containsKey('mimetype'), isFalse);
      expect(arquivosExtraidosMat.containsKey('META-INF/signatures.xml'), isTrue);
      expect(arquivosExtraidosMat.containsKey('OEBPS/dados/registro.binarypb'), isTrue);

      final epubManutencaoBytes = empacotador.empacotarEpub(
        idSessao: 'sessao_manut_99',
        idProtocolo: 'manutencao_ferragens',
        xhtmlConteudo: '<html><body>Manutenção Principal</body></html>',
        cssConteudo: 'body {}',
        binarypb: Uint8List.fromList([0x01, 0x02]),
        materiaisAninhados: {
          'uuid-mat-1': arquivosExtraidosMat,
        },
      );

      final zip = ZipDecoder().decodeBytes(epubManutencaoBytes);
      final nomesArquivos = zip.files.map((f) => f.name).toSet();

      // Verifica se os arquivos originais do material estão preservados bit-a-bit em OEBPS/materiais/uuid-mat-1/
      expect(
        nomesArquivos,
        contains('OEBPS/materiais/uuid-mat-1/META-INF/signatures.xml'),
      );
      expect(
        nomesArquivos,
        contains('OEBPS/materiais/uuid-mat-1/OEBPS/dados/registro.binarypb'),
      );
      expect(
        nomesArquivos,
        contains('OEBPS/materiais/uuid-mat-1/OEBPS/relatorio.xhtml'),
      );
      expect(
        nomesArquivos,
        contains('OEBPS/materiais/uuid-mat-1/OEBPS/midias/nota_fiscal.webp'),
      );

      // Garante que a mídia do material não foi duplicada na pasta raiz OEBPS/midias/
      expect(nomesArquivos.contains('OEBPS/midias/nota_fiscal.webp'), isFalse);

      final sigMat = zip.files.firstWhere(
        (f) => f.name == 'OEBPS/materiais/uuid-mat-1/META-INF/signatures.xml',
      );
      expect(
        utf8.decode(sigMat.content as List<int>),
        contains('AssinaturaMaterialOriginal'),
      );

      final pbMat = zip.files.firstWhere(
        (f) => f.name == 'OEBPS/materiais/uuid-mat-1/OEBPS/dados/registro.binarypb',
      );
      expect(pbMat.content, equals([0x0A, 0x0B, 0x0C]));
    });

    test('empacotarEpub armazena mídias já comprimidas (.mp4, .webp, .jpg, .jpeg, .png, .pdf) com CompressionType.none e mantém DEFLATE para textos e protobuf', () {
      // Usa payloads grandes o suficiente (> 64 bytes repetidos) para que o ZipEncoder aplique DEFLATE quando habilitado
      final payloadRepetido = Uint8List.fromList(List<int>.filled(256, 65));
      final epubBytes = empacotador.empacotarEpub(
        idSessao: 'sessao_store',
        idProtocolo: 'via_store',
        xhtmlConteudo: '<html><body>${'Texto repetido ' * 20}</body></html>',
        cssConteudo: 'body { color: #000000; margin: 0; padding: 0; } ' * 5,
        binarypb: payloadRepetido,
        arquivosMidia: {
          'midias/foto.webp': payloadRepetido,
          'midias/video.mp4': payloadRepetido,
          'midias/poster.jpg': payloadRepetido,
          'midias/extra.jpeg': payloadRepetido,
          'midias/assinatura.png': payloadRepetido,
          'midias/comprovante.pdf': payloadRepetido,
        },
        materiaisAninhados: {
          'mat-1': {
            'OEBPS/relatorio.xhtml': payloadRepetido,
            'OEBPS/midias/mat_foto.webp': payloadRepetido,
          },
        },
      );

      final zip = ZipDecoder().decodeBytes(epubBytes);
      ArchiveFile encontrar(String nome) => zip.files.firstWhere((f) => f.name == nome);

      expect(encontrar('OEBPS/midias/foto.webp').compression, equals(CompressionType.none));
      expect(encontrar('OEBPS/midias/video.mp4').compression, equals(CompressionType.none));
      expect(encontrar('OEBPS/midias/poster.jpg').compression, equals(CompressionType.none));
      expect(encontrar('OEBPS/midias/extra.jpeg').compression, equals(CompressionType.none));
      expect(encontrar('OEBPS/midias/assinatura.png').compression, equals(CompressionType.none));
      expect(encontrar('OEBPS/midias/comprovante.pdf').compression, equals(CompressionType.none));
      expect(encontrar('OEBPS/materiais/mat-1/OEBPS/midias/mat_foto.webp').compression, equals(CompressionType.none));

      expect(encontrar('OEBPS/relatorio.xhtml').compression, equals(CompressionType.deflate));
      expect(encontrar('OEBPS/estilo.css').compression, equals(CompressionType.deflate));
      expect(encontrar('OEBPS/content.opf').compression, equals(CompressionType.deflate));
      expect(encontrar('OEBPS/dados/registro.binarypb').compression, equals(CompressionType.deflate));
      expect(encontrar('OEBPS/materiais/mat-1/OEBPS/relatorio.xhtml').compression, equals(CompressionType.deflate));
    });

    test('empacotarEpub registra dc:language, nav.xhtml localizado com dir="rtl" em árabe e empacota seletivamente as fontes Noto Sans com DEFLATE', () {
      final fontesPt = empacotador.obterFontesNotoSansParaIdioma('pt');
      expect(
        fontesPt.keys.toSet(),
        equals({'fonts/NotoSans-Regular.ttf', 'fonts/NotoSans-Bold.ttf'}),
      );

      final fontesAr = empacotador.obterFontesNotoSansParaIdioma('ar');
      expect(
        fontesAr.keys.toSet(),
        equals({
          'fonts/NotoSans-Regular.ttf',
          'fonts/NotoSans-Bold.ttf',
          'fonts/NotoSansArabic-Regular.ttf',
          'fonts/NotoSansArabic-Bold.ttf',
        }),
      );

      final fontesJa = empacotador.obterFontesNotoSansParaIdioma('ja');
      expect(
        fontesJa.keys.toSet(),
        equals({
          'fonts/NotoSans-Regular.ttf',
          'fonts/NotoSans-Bold.ttf',
          'fonts/NotoSansJP-Regular.ttf',
          'fonts/NotoSansJP-Bold.ttf',
        }),
      );

      final epubEn = empacotador.empacotarEpub(
        idSessao: 'sessao_en',
        idProtocolo: 'visual_inspection_v1',
        xhtmlConteudo: '<html lang="en"><body>Report</body></html>',
        cssConteudo: 'body {}',
        binarypb: Uint8List.fromList([1, 2, 3]),
        codigoIdioma: 'en',
        incluirFontesNotoSans: true,
      );
      final zipEn = ZipDecoder().decodeBytes(epubEn);
      final nomesEn = zipEn.files.map((f) => f.name).toSet();
      expect(nomesEn, contains('OEBPS/fonts/NotoSans-Regular.ttf'));
      expect(nomesEn, contains('OEBPS/fonts/NotoSans-Bold.ttf'));
      expect(nomesEn, isNot(contains('OEBPS/fonts/NotoSansArabic-Regular.ttf')));
      expect(nomesEn, isNot(contains('OEBPS/fonts/NotoSansJP-Regular.ttf')));

      final fonteRegularEn = zipEn.files.firstWhere((f) => f.name == 'OEBPS/fonts/NotoSans-Regular.ttf');
      expect(fonteRegularEn.compression, equals(CompressionType.deflate));

      final opfEn = utf8.decode(zipEn.files.firstWhere((f) => f.name == 'OEBPS/content.opf').content as List<int>);
      expect(opfEn, contains('<dc:language>en</dc:language>'));
      expect(opfEn, contains('href="fonts/NotoSans-Regular.ttf" media-type="font/ttf"'));
      expect(opfEn, contains('href="fonts/NotoSans-Bold.ttf" media-type="font/ttf"'));

      final epubAr = empacotador.empacotarEpub(
        idSessao: 'sessao_ar',
        idProtocolo: 'visual_inspection_v1',
        xhtmlConteudo: '<html lang="ar" dir="rtl"><body>تقرير</body></html>',
        cssConteudo: 'body {}',
        binarypb: Uint8List.fromList([1, 2, 3]),
        codigoIdioma: 'ar',
        arquivosFonte: {
          'fonts/NotoSans-Regular.ttf': Uint8List.fromList(List<int>.filled(128, 70)),
          'fonts/NotoSansArabic-Regular.ttf': Uint8List.fromList(List<int>.filled(128, 71)),
        },
      );
      final zipAr = ZipDecoder().decodeBytes(epubAr);
      final navAr = utf8.decode(zipAr.files.firstWhere((f) => f.name == 'OEBPS/nav.xhtml').content as List<int>);
      expect(navAr, contains('lang="ar" dir="rtl"'));
      final opfAr = utf8.decode(zipAr.files.firstWhere((f) => f.name == 'OEBPS/content.opf').content as List<int>);
      expect(opfAr, contains('<dc:language>ar</dc:language>'));
      expect(opfAr, contains('href="fonts/NotoSansArabic-Regular.ttf" media-type="font/ttf"'));
    });
  });
}
