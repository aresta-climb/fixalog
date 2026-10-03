// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:fixalog/core/services/epub_extrator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late EpubExtratorService extratorService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('epub_extrator_test_');
    extratorService = EpubExtratorService(
      obterDiretorioTemporario: () async => tempDir,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Deve descompactar container EPUB 3 e retornar o caminho absoluto do relatorio.xhtml', () async {
    final archive = Archive();
    
    archive.addFile(ArchiveFile.noCompress('mimetype', 20, utf8.encode('application/epub+zip')));
    
    final xhtmlContent = '<?xml version="1.0" encoding="utf-8"?><html xmlns="http://www.w3.org/1999/xhtml"><body><h1>Laudo</h1></body></html>';
    archive.addFile(ArchiveFile('OEBPS/relatorio.xhtml', xhtmlContent.length, utf8.encode(xhtmlContent)));
    
    final cssContent = 'body { font-family: sans-serif; }';
    archive.addFile(ArchiveFile('OEBPS/estilo.css', cssContent.length, utf8.encode(cssContent)));
    
    final videoBytes = [1, 2, 3, 4, 5];
    archive.addFile(ArchiveFile('OEBPS/midias/video1.mp4', videoBytes.length, videoBytes));

    final zipBytes = ZipEncoder().encode(archive);
    final epubFile = File('${tempDir.path}/laudo_teste.epub');
    await epubFile.writeAsBytes(zipBytes);

    final destDir = Directory('${tempDir.path}/cache_extracao');

    final caminhoXhtml = await extratorService.extrairEpub(
      caminhoEpub: epubFile.path,
      diretorioDestino: destDir.path,
    );

    expect(caminhoXhtml, isNotNull);
    expect(File(caminhoXhtml).existsSync(), isTrue);
    expect(caminhoXhtml.endsWith('relatorio.xhtml'), isTrue);

    final cssFile = File('${destDir.path}/OEBPS/estilo.css');
    expect(cssFile.existsSync(), isTrue);
    expect(await cssFile.readAsString(), equals(cssContent));

    final videoFile = File('${destDir.path}/OEBPS/midias/video1.mp4');
    expect(videoFile.existsSync(), isTrue);
    expect(await videoFile.readAsBytes(), equals(videoBytes));
  });

  test('Deve lançar exceção se o arquivo EPUB não existir', () async {
    expect(
      () => extratorService.extrairEpub(
        caminhoEpub: '${tempDir.path}/inexistente.epub',
      ),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('Deve lançar exceção se o arquivo não for um ZIP/EPUB válido', () async {
    final arquivoInvalido = File('${tempDir.path}/invalido.epub');
    await arquivoInvalido.writeAsString('Isto não é um arquivo ZIP válido');

    expect(
      () => extratorService.extrairEpub(
        caminhoEpub: arquivoInvalido.path,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('Deve limpar o diretório de cache quando solicitado', () async {
    final dirParaLimpar = Directory('${tempDir.path}/para_limpar');
    await dirParaLimpar.create();
    final dummyFile = File('${dirParaLimpar.path}/dummy.txt');
    await dummyFile.writeAsString('teste');

    expect(await dirParaLimpar.exists(), isTrue);

    await extratorService.limparCache(diretorioCache: dirParaLimpar.path);

    expect(await dirParaLimpar.exists(), isFalse);
  });

  test('Deve localizar XHTML mesmo quando em caminho não padrão', () async {
    final archive = Archive();
    final xhtmlContent = '<html><body>Personalizado</body></html>';
    archive.addFile(ArchiveFile('conteudo/outro.xhtml', xhtmlContent.length, utf8.encode(xhtmlContent)));
    final zipBytes = ZipEncoder().encode(archive);
    final epubFile = File('${tempDir.path}/nao_padrao.epub');
    await epubFile.writeAsBytes(zipBytes);

    final caminho = await extratorService.extrairEpub(caminhoEpub: epubFile.path);
    expect(caminho.endsWith('outro.xhtml'), isTrue);
    expect(File(caminho).existsSync(), isTrue);
  });

  test('Deve lançar FormatException quando não houver arquivo XHTML no EPUB', () async {
    final archive = Archive();
    archive.addFile(ArchiveFile('texto.txt', 4, utf8.encode('olá')));
    final zipBytes = ZipEncoder().encode(archive);
    final epubFile = File('${tempDir.path}/sem_xhtml.epub');
    await epubFile.writeAsBytes(zipBytes);

    expect(
      () => extratorService.extrairEpub(caminhoEpub: epubFile.path),
      throwsA(isA<FormatException>()),
    );
  });

  test('Provider epubExtratorServiceProvider deve prover instância funcional', () {
    expect(epubExtratorServiceProvider, isNotNull);
  });
}
