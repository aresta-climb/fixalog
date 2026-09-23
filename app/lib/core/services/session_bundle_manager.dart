// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Gerencia a persistência de mídias e manifestos para uma Sessão de Geração.
/// 
/// Cada relatório/protocolo gerado no aplicativo pertence a uma "Sessão" única (`sessionId`).
/// Todos os arquivos (mídias originais, comprimidas, manifestos binarypb/json e o próprio PDF gerado)
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
    if (!await sessionDir.exists()) {
      await sessionDir.create(recursive: true);
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
    return file.writeAsBytes(bytes);
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
    return file.writeAsBytes(bytes);
  }

  /// Salva o manifesto de dados em formato binário (Protobuf) no bundle da sessão.
  ///
  /// O nome do arquivo será sempre `registro.binarypb`.
  /// Este formato é usado pela biblioteca FFI no Rust para a geração do PDF e também
  /// serve como a Single Source of Truth para re-edição de relatórios passados.
  Future<File> saveManifest({
    required String sessionId,
    required Uint8List binarypb,
  }) async {
    final dir = await getSessionDirectory(sessionId);
    final file = File(p.join(dir.path, 'registro.binarypb'));
    return file.writeAsBytes(binarypb);
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
    return file.writeAsString(jsonStr);
  }

  /// Lê o manifesto Protobuf binário a partir do disco, se existir.
  ///
  /// Usado primordialmente ao re-editar um relatório a partir do Histórico.
  Future<Uint8List> readManifest({required String sessionId}) async {
    final dir = await getSessionDirectory(sessionId);
    final file = File(p.join(dir.path, 'registro.binarypb'));
    return file.readAsBytes();
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

  /// Retorna o caminho formatado do relatório PDF com a nomenclatura única (fixalog_<uuid>.pdf)
  Future<String> getReportFilePath({required String sessionId}) async {
    final dir = await getSessionDirectory(sessionId);
    return p.join(dir.path, 'fixalog_$sessionId.pdf');
  }

  /// Remove permanentemente todos os arquivos e o diretório de uma Sessão.
  ///
  /// Esta ação exclui fotos originais, vídeos, manifestos json/binarypb.
  /// É invocada na rotina de lixeira quando o usuário deleta um log do Histórico.
  Future<void> deleteSessionBundle(String sessionId) async {
    final dir = await getSessionDirectory(sessionId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

final sessionBundleManagerProvider = Provider<SessionBundleManager>((ref) {
  return SessionBundleManager();
});
