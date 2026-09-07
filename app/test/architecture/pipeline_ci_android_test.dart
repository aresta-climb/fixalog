// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Conformidade do Pipeline CI/CD Android — Prevenção de Falta de Espaço em Disco', () {
    late File workflowFile;
    late String workflowContent;

    setUpAll(() {
      // Localiza o arquivo de workflow a partir de app/ ou da raiz do repositório
      var file = File('../.github/workflows/build_android.yml');
      if (!file.existsSync()) {
        file = File('.github/workflows/build_android.yml');
      }
      expect(
        file.existsSync(),
        isTrue,
        reason: 'O arquivo .github/workflows/build_android.yml deve existir no repositório.',
      );
      workflowFile = file;
      workflowContent = workflowFile.readAsStringSync();
    });

    test('deve conter uma etapa explícita para liberar espaço em disco no início do job', () {
      expect(
        workflowContent.contains('Liberar espaço em disco') ||
            workflowContent.contains('Free disk space'),
        isTrue,
        reason:
            'O runner ubuntu-latest possui espaço em disco limitado (~14 GB livres). '
            'É obrigatório ter um passo para remover pacotes pesados não utilizados '
            '(como .NET, Haskell, Android NDKs não utilizados) antes de iniciar a compilação do Rust e Flutter.',
      );
    });

    test('a etapa Setup Flutter DEVE ter cache habilitado (cache: true)', () {
      final lines = workflowContent.split('\n');
      var inFlutterAction = false;
      var hasCacheTrue = false;

      for (final line in lines) {
        if (line.contains('subosito/flutter-action')) {
          inFlutterAction = true;
          continue;
        }
        if (inFlutterAction) {
          if (line.trim().startsWith('- name:') ||
              (line.trim().startsWith('- uses:') && !line.contains('flutter-action'))) {
            inFlutterAction = false;
          } else if (line.contains('cache: true')) {
            hasCacheTrue = true;
          }
        }
      }

      expect(
        hasCacheTrue,
        isTrue,
        reason:
            'A etapa subosito/flutter-action deve manter "cache: true" para acelerar o setup do Flutter entre execuções.',
      );
    });

    test('deve conter etapa de limpeza de artefatos intermediários do Rust após compilação do AAB', () {
      expect(
        workflowContent.contains('Limpar artefatos') ||
            workflowContent.contains('Clean build artifacts'),
        isTrue,
        reason:
            'Após compilar o AAB, as pastas de build intermediárias do Rust (build/rust_lib_app/build) '
            'acumulam mais de 8 GB de arquivos temporários que devem ser limpos para evitar estouro de disco.',
      );
    });
  });
}
