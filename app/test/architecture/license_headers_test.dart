// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Conformidade Arquitetural — Cabeçalhos de Licença SPDX/MPL-2.0', () {
    const expectedLine1 = '// SPDX-License-Identifier: MPL-2.0';
    const expectedLine2 = '// Copyright (c) 2026 FixLog Contributors';

    bool hasValidHeader(File file) {
      final lines = file
          .readAsLinesSync()
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.length < 2) return false;
      return lines[0] == expectedLine1 && lines[1] == expectedLine2;
    }

    test('todos os arquivos Dart autorais em lib/ e test/ devem conter o cabeçalho SPDX/MPL-2.0', () {
      final directories = [Directory('lib'), Directory('test')];
      final invalidFiles = <String>[];

      for (final dir in directories) {
        if (!dir.existsSync()) continue;

        final dartFiles = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in dartFiles) {
          final normalizedPath = file.path.replaceAll(r'\', '/');

          // Ignora arquivos gerados por codegen (build_runner, protoc, flutter_rust_bridge)
          if (normalizedPath.endsWith('.g.dart') ||
              normalizedPath.endsWith('.pb.dart') ||
              normalizedPath.endsWith('.pbenum.dart') ||
              normalizedPath.endsWith('.pbjson.dart') ||
              normalizedPath.contains('src/rust/frb_generated')) {
            continue;
          }

          if (!hasValidHeader(file)) {
            invalidFiles.add(normalizedPath);
          }
        }
      }

      expect(
        invalidFiles,
        isEmpty,
        reason:
            'Os seguintes arquivos Dart não contêm o cabeçalho SPDX/MPL-2.0 obrigatório:\n'
            '${invalidFiles.map((f) => '  - $f').join('\n')}\n\n'
            'O topo do arquivo deve conter:\n'
            '$expectedLine1\n'
            '$expectedLine2\n',
      );
    });

    test('todos os arquivos Rust autorais em rust/src/ devem conter o cabeçalho SPDX/MPL-2.0', () {
      final rustSrcDir = Directory('rust/src');
      if (!rustSrcDir.existsSync()) {
        // Se executado da raiz do workspace em vez da pasta app/
        final altRustDir = Directory('app/rust/src');
        if (!altRustDir.existsSync()) {
          fail('Diretório rust/src não foi encontrado.');
        }
      }

      final targetDir = rustSrcDir.existsSync() ? rustSrcDir : Directory('app/rust/src');
      final rsFiles = targetDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.rs'));

      final invalidFiles = <String>[];

      for (final file in rsFiles) {
        final normalizedPath = file.path.replaceAll(r'\', '/');

        // Ignora arquivos gerados automaticamente pelo flutter_rust_bridge
        if (normalizedPath.endsWith('frb_generated.rs') ||
            normalizedPath.contains('/target/') ||
            normalizedPath.contains('/formats/')) {
          continue;
        }

        if (!hasValidHeader(file)) {
          invalidFiles.add(normalizedPath);
        }
      }

      expect(
        invalidFiles,
        isEmpty,
        reason:
            'Os seguintes arquivos Rust não contêm o cabeçalho SPDX/MPL-2.0 obrigatório:\n'
            '${invalidFiles.map((f) => '  - $f').join('\n')}\n\n'
            'O topo do arquivo deve conter:\n'
            '$expectedLine1\n'
            '$expectedLine2\n',
      );
    });

    test('todos os arquivos Kotlin autorais em android/ devem conter o cabeçalho SPDX/MPL-2.0', () {
      final kotlinDir = Directory('android/app/src/main/kotlin');
      final targetDir = kotlinDir.existsSync() ? kotlinDir : Directory('app/android/app/src/main/kotlin');
      
      if (!targetDir.existsSync()) {
        fail('Diretório de código Kotlin do Android não foi encontrado.');
      }

      final ktFiles = targetDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.kt'));

      final invalidFiles = <String>[];

      for (final file in ktFiles) {
        final normalizedPath = file.path.replaceAll(r'\', '/');

        if (!hasValidHeader(file)) {
          invalidFiles.add(normalizedPath);
        }
      }

      expect(
        invalidFiles,
        isEmpty,
        reason:
            'Os seguintes arquivos Kotlin não contêm o cabeçalho SPDX/MPL-2.0 obrigatório:\n'
            '${invalidFiles.map((f) => '  - $f').join('\n')}\n\n'
            'O topo do arquivo deve conter:\n'
            '$expectedLine1\n'
            '$expectedLine2\n',
      );
    });
  });
}
