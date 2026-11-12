// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/features/feedback/views/construtor_feedback_usuario.dart';

void main() {
  group('ConstrutorFeedbackUsuario — Formulário de Feedback In-App', () {
    testWidgets(
      'renderiza título, seletor de categoria, campo de texto e envia feedback com categoria selecionada',
      (tester) async {
        String? textoEnviado;
        Map<String, dynamic>? extrasEnviados;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bancoDadosLocalProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              locale: const Locale('pt'),
              home: Scaffold(
                body: Builder(
                  builder: (context) => construtorFeedbackUsuario(
                    context,
                    (String feedback, {Map<String, dynamic>? extras}) async {
                      textoEnviado = feedback;
                      extrasEnviados = extras;
                    },
                    ScrollController(),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Sobre o que é o seu relato?'), findsOneWidget);
        expect(find.byKey(const Key('seletor_categoria_feedback')), findsOneWidget);

        // Botão desabilitado enquanto campo de texto estiver vazio
        final botaoEnviar = tester.widget<ElevatedButton>(
          find.byKey(const Key('botao_enviar_feedback_sheet')),
        );
        expect(botaoEnviar.onPressed, isNull);

        // Seleciona categoria Protocolo
        await tester.tap(find.text('Protocolo'));
        await tester.pumpAndSettle();

        // Preenche texto descritivo e envia
        await tester.enterText(
          find.byKey(const Key('campo_texto_feedback')),
          '  Faltou opção de parabolt 12mm  ',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('botao_enviar_feedback_sheet')));
        await tester.pumpAndSettle();

        expect(textoEnviado, equals('Faltou opção de parabolt 12mm'));
        expect(extrasEnviados?['categoria'], equals('protocolo'));
      },
    );
  });
}
