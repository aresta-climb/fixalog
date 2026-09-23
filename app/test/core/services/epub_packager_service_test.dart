// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixlog/core/services/epub_packager_service.dart';

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

    test('empacotarEpub deve criar nav.xhtml válido com o sumário', () {
      final epubBytes = empacotador.empacotarEpub(
        idSessao: 'sessao_nav',
        idProtocolo: 'via_nav',
        xhtmlConteudo: '<html><body>Nav</body></html>',
        cssConteudo: 'body {}',
        binarypb: Uint8List.fromList([0]),
      );

      final zip = ZipDecoder().decodeBytes(epubBytes);
      final navFile = zip.files.firstWhere((f) => f.name == 'OEBPS/nav.xhtml');
      final navXml = utf8.decode(navFile.content as List<int>);
      expect(navXml, contains('epub:type="toc"'));
      expect(navXml, contains('<a href="relatorio.xhtml">Relatório de Vistoria</a>'));
    });

    test('determinarTipoMime deve resolver corretamente todos os formatos e fallback', () {
      expect(empacotador.determinarTipoMime('teste.webp'), equals('image/webp'));
      expect(empacotador.determinarTipoMime('teste.jpg'), equals('image/jpeg'));
      expect(empacotador.determinarTipoMime('teste.jpeg'), equals('image/jpeg'));
      expect(empacotador.determinarTipoMime('teste.png'), equals('image/png'));
      expect(empacotador.determinarTipoMime('teste.mp4'), equals('video/mp4'));
      expect(empacotador.determinarTipoMime('teste.css'), equals('text/css'));
      expect(empacotador.determinarTipoMime('teste.xhtml'), equals('application/xhtml+xml'));
      expect(empacotador.determinarTipoMime('teste.html'), equals('application/xhtml+xml'));
      expect(empacotador.determinarTipoMime('teste.binarypb'), equals('application/x-protobuf'));
      expect(empacotador.determinarTipoMime('teste.desconhecido'), equals('application/octet-stream'));
    });
  });
}
