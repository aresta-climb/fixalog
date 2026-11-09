// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/proto/protos/registro.pb.dart';
import 'serializador_yaml_registro.dart';

/// Gerencia a persistência de mídias e manifestos para uma Sessão de Geração.
/// 
/// Cada relatório/protocolo gerado no aplicativo pertence a uma "Sessão" única (`sessionId`).
/// Todos os arquivos (mídias originais, comprimidas, manifestos yaml/binarypb/json e o relatório gerado)
/// ficam isolados dentro do diretório específico da sessão (`/sessoes/<sessionId>/`).
/// Esta classe é a principal interface para escrever e ler esses bundles isolados no disco local.
class SessionBundleManager {
  final Future<Directory> Function()? baseDirectoryGetter;

  SessionBundleManager({this.baseDirectoryGetter});

  /// Retorna (e cria, se não existir) o diretório da sessão correspondente ao [sessionId].
  Future<Directory> getSessionDirectory(String sessionId) async {
    final appDir = baseDirectoryGetter != null
        ? await baseDirectoryGetter!()
        : await getApplicationDocumentsDirectory();
    final sessionDir = Directory(p.join(appDir.path, 'sessoes', sessionId));
    if (!sessionDir.existsSync()) {
      sessionDir.createSync(recursive: true);
    }
    return sessionDir;
  }

  /// Salva uma mídia no seu formato original no bundle da sessão.
  ///
  /// O arquivo será nomeado com o sufixo `_original` (ex: `uuid_original.jpg`).
  /// Ideal para armazenar os dados coletados antes de qualquer compressão/modificação.
  Future<File> saveOriginalMedia({
    required String sessionId,
    required String mediaUuid,
    required String extension,
    required Uint8List bytes,
  }) async {
    final dir = await getSessionDirectory(sessionId);
    // Remove o ponto inicial se houver, para não dar erro
    final ext = extension.startsWith('.') ? extension : '.$extension';
    final file = File(p.join(dir.path, '${mediaUuid}_original$ext'));
    file.writeAsBytesSync(bytes);
    return file;
  }

  /// Salva uma mídia comprimida no bundle da sessão.
  ///
  /// O arquivo será nomeado apenas com o UUID (ex: `uuid.jpg`).
  /// Essa é a mídia padrão utilizada durante as inserções finais no PDF.
  Future<File> saveCompressedMedia({
    required String sessionId,
    required String mediaUuid,
    required String extension,
    required Uint8List bytes,
  }) async {
    final dir = await getSessionDirectory(sessionId);
    final ext = extension.startsWith('.') ? extension : '.$extension';
    final file = File(p.join(dir.path, '$mediaUuid$ext'));
    file.writeAsBytesSync(bytes);
    return file;
  }

  /// Salva o manifesto de dados em formato YAML legível (`registro.yaml`) no bundle da sessão.
  ///
  /// Este arquivo é a Single Source of Truth legível por humanos para re-edição e geração de laudos.
  Future<File> salvarRegistroSessao({
    required String sessionId,
    required Registro registro,
  }) async {
    final dir = await getSessionDirectory(sessionId);
    final file = File(p.join(dir.path, 'registro.yaml'));
    final conteudoYaml = SerializadorYamlRegistro.paraYaml(registro);
    file.writeAsStringSync(conteudoYaml);
    return file;
  }

  /// Lê e reconstrói o [Registro] tipado a partir de `registro.yaml` no disco,
  /// com fallback transparente para `registro.binarypb` legado se `registro.yaml` não existir.
  Future<Registro> lerRegistroSessao({required String sessionId}) async {
    final dir = await getSessionDirectory(sessionId);
    final arquivoYaml = File(p.join(dir.path, 'registro.yaml'));
    if (arquivoYaml.existsSync()) {
      return SerializadorYamlRegistro.deYaml(arquivoYaml.readAsStringSync());
    }
    final arquivoPb = File(p.join(dir.path, 'registro.binarypb'));
    return Registro.fromBuffer(arquivoPb.readAsBytesSync());
  }

  /// Salva o manifesto de dados em formato binário (Protobuf) no bundle da sessão (suporte legado).
  ///
  /// O nome do arquivo será sempre `registro.binarypb`.
  Future<File> saveManifest({
    required String sessionId,
    required Uint8List binarypb,
  }) async {
    final dir = await getSessionDirectory(sessionId);
    final file = File(p.join(dir.path, 'registro.binarypb'));
    file.writeAsBytesSync(binarypb);
    return file;
  }

  /// Salva o manifesto de dados convertido para JSON no bundle da sessão.
  ///
  /// É este arquivo `registro.json` que é extraído e anexado nativamente no 
  /// contêiner do PDF/A-3 para leitura universal e extração de dados no futuro.
  Future<File> saveManifestJson({
    required String sessionId,
    required String jsonStr,
  }) async {
    final dir = await getSessionDirectory(sessionId);
    final file = File(p.join(dir.path, 'registro.json'));
    file.writeAsStringSync(jsonStr);
    return file;
  }

  /// Lê o manifesto da sessão retornando os bytes Protobuf correspondentes
  /// (lendo de `registro.yaml` quando disponível ou `registro.binarypb` como fallback).
  Future<Uint8List> readManifest({required String sessionId}) async {
    final dir = await getSessionDirectory(sessionId);
    final arquivoYaml = File(p.join(dir.path, 'registro.yaml'));
    if (arquivoYaml.existsSync()) {
      final registro = SerializadorYamlRegistro.deYaml(
        arquivoYaml.readAsStringSync(),
      );
      return Uint8List.fromList(registro.writeToBuffer());
    }
    final file = File(p.join(dir.path, 'registro.binarypb'));
    return file.readAsBytesSync();
  }

  /// Retorna o caminho absoluto do arquivo de mídia persistido para esta sessão.
  Future<String> getMediaFilePath({
    required String sessionId,
    required String mediaUuid,
    required String extension,
  }) async {
    final dir = await getSessionDirectory(sessionId);
    final ext = extension.startsWith('.') ? extension : '.$extension';
    return p.join(dir.path, '$mediaUuid$ext');
  }

  /// Retorna o caminho formatado do relatório PDF com a nomenclatura única (`fixalog_<uuid>.pdf`)
  Future<String> getReportFilePath({required String sessionId}) async {
    final dir = await getSessionDirectory(sessionId);
    return p.join(dir.path, 'fixalog_$sessionId.pdf');
  }

  /// Copia todos os arquivos de mídia (originais `_original.*` e pré-processados
  /// `.webp`, `_thumb.jpg`, `.mp4`, `_poster.jpg`) do diretório de [idSessaoOrigem]
  /// para [idSessaoDestino], ignorando manifestos (`registro.yaml`, `registro.binarypb`, `registro.json`),
  /// arquivos temporários (`*.tmp`) e relatórios finais (`fixalog_*`, `relatorio.*`).
  Future<void> copiarArquivosMidiaSessao({
    required String idSessaoOrigem,
    required String idSessaoDestino,
  }) async {
    final dirOrigem = await getSessionDirectory(idSessaoOrigem);
    final dirDestino = await getSessionDirectory(idSessaoDestino);

    final arquivos = dirOrigem.listSync().whereType<File>();
    for (final arquivo in arquivos) {
      final nome = p.basename(arquivo.path);
      final nomeLower = nome.toLowerCase();
      if (nomeLower == 'registro.yaml' ||
          nomeLower == 'registro.binarypb' ||
          nomeLower == 'registro.json' ||
          nomeLower.endsWith('.tmp') ||
          nomeLower.startsWith('fixalog_') ||
          nomeLower.startsWith('relatorio.') ||
          nomeLower.endsWith('.epub')) {
        continue;
      }
      await arquivo.copy(p.join(dirDestino.path, nome));
    }
  }

  /// Remove permanentemente todos os arquivos e o diretório de uma Sessão.
  ///
  /// Esta ação exclui fotos originais, vídeos, manifestos json/binarypb.
  /// É invocada na rotina de lixeira quando o usuário deleta um log do Histórico.
  Future<void> deleteSessionBundle(String sessionId) async {
    final dir = await getSessionDirectory(sessionId);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }
}

final sessionBundleManagerProvider = Provider<SessionBundleManager>((ref) {
  return SessionBundleManager();
});
