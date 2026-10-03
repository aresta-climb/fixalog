// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Arquitetura de Testes — Espelhamento 1:1 (PRINCIPIOS.md)', () {
    test(
      'todo arquivo .dart de produção em lib/ deve possuir um arquivo _test.dart equivalente em test/',
      () {
        final libDir = Directory('lib');
        expect(
          libDir.existsSync(),
          isTrue,
          reason: 'Diretório lib/ não foi encontrado na raiz de execução.',
        );

        final allLibFiles = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList();

        final missingTests = <String>[];

        for (final file in allLibFiles) {
          // Normaliza caminhos para barras normais '/'
          final relativePath = file.path
              .replaceAll(r'\', '/')
              .replaceFirst(RegExp(r'^lib/'), '');

          // Ignora arquivos gerados automaticamente por ferramentas e codegen
          if (relativePath.endsWith('.g.dart') ||
              relativePath.endsWith('.pb.dart') ||
              relativePath.endsWith('.pbenum.dart') ||
              relativePath.endsWith('.pbjson.dart') ||
              relativePath.startsWith('src/rust/')) {
            continue;
          }

          final testPath = 'test/${relativePath.replaceFirst(RegExp(r'\.dart$'), '_test.dart')}';
          final testFile = File(testPath);

          if (!testFile.existsSync()) {
            missingTests.add('lib/$relativePath -> esperava existir: $testPath');
          }
        }

        expect(
          missingTests,
          isEmpty,
          reason:
              'Violação do Princípio IV de PRINCIPIOS.md: Os seguintes arquivos em lib/ não possuem testes espelhados em test/:\n${missingTests.map((m) => '  - $m').join('\n')}',
        );
      },
    );
  });
}
