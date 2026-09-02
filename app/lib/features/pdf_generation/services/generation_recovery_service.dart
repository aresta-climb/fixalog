// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class GenerationRecoveryService {
  static const _processingFlagKey = 'is_generating_pdf';
  static const _tempDirName = 'fixalog_temp_media';

  /// Marca no armazenamento local que o processamento começou
  Future<void> markAsProcessing(bool isProcessing) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_processingFlagKey, isProcessing);
  }

  /// Verifica se houve falha no último processamento
  Future<bool> wasInterrupted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_processingFlagKey) ?? false;
  }

  /// Limpa arquivos temporários gerados (compressão) durante uma sessão falha
  Future<void> garbageCollect() async {
    final interrupted = await wasInterrupted();
    if (interrupted) {
      final cacheDir = await getTemporaryDirectory();
      final targetDir = Directory(p.join(cacheDir.path, _tempDirName));
      
      if (targetDir.existsSync()) {
        try {
          targetDir.deleteSync(recursive: true);
          print('Garbage Collector limpou o diretório temporário.');
        } catch (e) {
          print('Falha ao rodar Garbage Collector: \$e');
        }
      }
      // Limpa a flag
      await markAsProcessing(false);
    }
  }

  /// Retorna o diretório de trabalho temporário seguro
  Future<Directory> getWorkspaceDir() async {
    final cacheDir = await getTemporaryDirectory();
    final targetDir = Directory(p.join(cacheDir.path, _tempDirName));
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }
    return targetDir;
  }
}
