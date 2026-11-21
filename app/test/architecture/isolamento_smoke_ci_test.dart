// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Isolamento Arquitetural do Módulo Smoke CI', () {
    test('nenhum arquivo de produção em lib/ fora de lib/core/smoke_ci/ deve importar ou referenciar smoke_ci', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final violacoes = <String>[];
      final arquivos = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final arq in arquivos) {
        final caminho = arq.path.replaceAll(r'\', '/');
        if (caminho.contains('lib/core/smoke_ci/')) {
          continue;
        }
        final conteudo = arq.readAsStringSync();
        if (conteudo.contains('smoke_ci') ||
            conteudo.contains('/__smoke__/') ||
            conteudo.contains('ARESTA_SMOKE')) {
          violacoes.add(caminho);
        }
      }

      expect(
        violacoes,
        isEmpty,
        reason:
            'O entrypoint de produção (lib/main.dart) e demais módulos em lib/ jamais devem referenciar '
            'core/smoke_ci/ para garantir zero bytes de smoke test nos binários das lojas:\n'
            '${violacoes.join('\n')}',
      );
    });
  });
}
