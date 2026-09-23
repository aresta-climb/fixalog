// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Serviço responsável por descompactar e preparar relatórios EPUB 3 para visualização local.
///
/// Extrai o conteúdo OCF (XHTML, CSS e mídias) para um diretório de cache
/// permitindo que a WebView carregue os arquivos locais com resolução relativa de mídias.
class EpubExtratorService {
  final Future<Directory> Function()? obterDiretorioTemporario;

  EpubExtratorService({this.obterDiretorioTemporario});

  /// Extrai o conteúdo do arquivo `.epub` para [diretorioDestino] e retorna o caminho absoluto do XHTML principal.
  Future<String> extrairEpub({
    required String caminhoEpub,
    String? diretorioDestino,
  }) async {
    final file = File(caminhoEpub);
    if (!await file.exists()) {
      throw FileSystemException('Arquivo EPUB não encontrado', caminhoEpub);
    }

    final bytes = await file.readAsBytes();
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw Exception('Falha ao decodificar arquivo EPUB/ZIP: $e');
    }

    final Directory destDir;
    if (diretorioDestino != null) {
      destDir = Directory(diretorioDestino);
    } else {
      final tempDir = obterDiretorioTemporario != null
          ? await obterDiretorioTemporario!()
          : await getTemporaryDirectory();
      final identificador = p.basenameWithoutExtension(caminhoEpub);
      destDir = Directory(p.join(tempDir.path, 'relatorios_cache', identificador));
    }

    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    for (final archiveFile in archive) {
      if (archiveFile.isFile) {
        final outPath = p.join(destDir.path, archiveFile.name);
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(archiveFile.content as List<int>);
      }
    }

    // Identificar ponto de entrada XHTML
    final relatorioPadrao = File(p.join(destDir.path, 'OEBPS', 'relatorio.xhtml'));
    if (await relatorioPadrao.exists()) {
      return relatorioPadrao.path;
    }

    // Busca recursiva caso a estrutura interna tenha outra nomenclatura
    await for (final entidade in destDir.list(recursive: true)) {
      if (entidade is File &&
          (entidade.path.endsWith('.xhtml') || entidade.path.endsWith('.html'))) {
        return entidade.path;
      }
    }

    throw const FormatException('Nenhum documento XHTML/HTML encontrado no EPUB');
  }

  /// Remove o diretório de cache descompactado.
  Future<void> limparCache({required String diretorioCache}) async {
    final dir = Directory(diretorioCache);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

final epubExtratorServiceProvider = Provider<EpubExtratorService>((ref) {
  return EpubExtratorService();
});
