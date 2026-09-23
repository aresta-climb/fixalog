// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixlog/features/wizard/views/wizard_screen.dart';

void main() {
  const testYaml = '''
id: "test_protocol"
nome: "Protocolo de Teste"
versao: "1.0.0"
blocos:
  - id: "b1"
    nome: "Bloco Inicial"
    steps:
      - id: "s1"
        nome: "Passo 1"
        conteudos:
          - id: "c1"
            tipo_componente: "CAMPO_SIMPLES"
            campo_simples:
              label: "Tipo de Chapeleta"
              tipo: "TEXT"
              obrigatorio: true
''';

  group('WizardScreen Widget Tests', () {
    testWidgets('renderiza o cabeçalho e campo de texto do protocolo YAML', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: testYaml),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('FIXLOG'), findsOneWidget);
      expect(find.text('Tipo de Chapeleta'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('botão de avanço habilita após preencher campo obrigatório', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: testYaml),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final nextButtonFinder = find.widgetWithText(
        ElevatedButton,
        'ASSINAR E CONCLUIR',
      );
      expect(nextButtonFinder, findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Bonier Inox');
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(nextButtonFinder);
      final color = button.style?.backgroundColor?.resolve({});
      expect(color, equals(const Color(0xFFFF6B00)));
    });

    testWidgets('ao clicar em GRAVAR VÍDEO exibe modal de seleção entre Câmera e Galeria', (tester) async {
      const videoYaml = '''
id: "video_protocol"
nome: "Protocolo Vídeo"
versao: "1.0.0"
blocos:
  - id: "b1"
    nome: "Bloco 1"
    steps:
      - id: "s1"
        nome: "Passo 1"
        conteudos:
          - id: "v1"
            tipo_componente: "CAMPO_SIMPLES"
            campo_simples:
              label: "Vídeo de Inspeção"
              tipo: "VIDEO"
              obrigatorio: true
''';
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: videoYaml),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final videoButtonFinder = find.text('GRAVAR VÍDEO');
      expect(videoButtonFinder, findsOneWidget);

      await tester.tap(videoButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('SELECIONE A ORIGEM DO VÍDEO'), findsOneWidget);
      expect(find.text('Gravar com a Câmera'), findsOneWidget);
      expect(find.text('Escolher da Galeria / Arquivos'), findsOneWidget);

      await tester.tap(find.text('Escolher da Galeria / Arquivos'));
      await tester.pumpAndSettle();
      expect(find.text('SELECIONE A ORIGEM DO VÍDEO'), findsNothing);
    });

    testWidgets('ao clicar em ABRIR CÂMERA exibe modal de seleção entre Câmera e Galeria para fotos', (tester) async {
      const fotoYaml = '''
id: "foto_protocol"
nome: "Protocolo Foto"
versao: "1.0.0"
blocos:
  - id: "b1"
    nome: "Bloco 1"
    steps:
      - id: "s1"
        nome: "Passo 1"
        conteudos:
          - id: "f1"
            tipo_componente: "CAMPO_SIMPLES"
            campo_simples:
              label: "Foto de Inspeção"
              tipo: "IMAGE"
              obrigatorio: true
''';
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: fotoYaml),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final fotoButtonFinder = find.text('ABRIR CÂMERA');
      expect(fotoButtonFinder, findsOneWidget);

      await tester.tap(fotoButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('SELECIONE A ORIGEM DA FOTO'), findsOneWidget);
      expect(find.text('Tirar Foto com a Câmera'), findsOneWidget);
      expect(find.text('Escolher da Galeria'), findsOneWidget);

      await tester.tap(find.text('Escolher da Galeria'));
      await tester.pumpAndSettle();
      expect(find.text('SELECIONE A ORIGEM DA FOTO'), findsNothing);
    });
  });
}
