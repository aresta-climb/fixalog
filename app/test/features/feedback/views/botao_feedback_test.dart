// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:typed_data';

import 'package:feedback/feedback.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/features/feedback/services/servico_fila_feedback.dart';
import 'package:fixalog/features/feedback/views/botao_feedback.dart';
import 'package:fixalog/features/feedback/views/construtor_feedback_usuario.dart';

import '../../../fakes/servico_fila_feedback_fake.dart';

void main() {
  group('BotaoFeedback — Acionamento do BetterFeedback e Enfileiramento Offline', () {
    testWidgets(
      'processarEnvioFeedback enfileira relato no ServicoFilaFeedback e exibe SnackBar de confirmação',
      (tester) async {
        final filaFake = ServicoFilaFeedbackFake();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bancoDadosLocalProvider.overrideWithValue(null),
              servicoFilaFeedbackProvider.overrideWithValue(filaFake),
            ],
            child: BetterFeedback(
              feedbackBuilder: construtorFeedbackUsuario,
              child: MaterialApp(
                locale: const Locale('pt'),
                home: Scaffold(
                  body: Center(
                    child: BotaoFeedback(
                      exibidorFeedback: (context, aoSubmeter) {
                        aoSubmeter(
                          UserFeedback(
                            text: 'Problema na câmera do passo 2',
                            screenshot: Uint8List.fromList([1, 2, 3]),
                            extra: const {'categoria': 'protocolo'},
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('botao_acionar_feedback')), findsOneWidget);
        await tester.tap(find.byKey(const Key('botao_acionar_feedback')));
        await tester.pumpAndSettle();

        expect(filaFake.feedbacksEnfileirados, hasLength(1));
        expect(
          filaFake.feedbacksEnfileirados.single.mensagem,
          equals('Problema na câmera do passo 2'),
        );
        expect(
          filaFake.feedbacksEnfileirados.single.categoria,
          equals('protocolo'),
        );
        expect(
          find.text('Relato registrado! Será enviado assim que houver conexão.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'aciona BetterFeedback.of(context).show por padrão quando tocado',
      (tester) async {
        final filaFake = ServicoFilaFeedbackFake();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bancoDadosLocalProvider.overrideWithValue(null),
              servicoFilaFeedbackProvider.overrideWithValue(filaFake),
            ],
            child: BetterFeedback(
              feedbackBuilder: construtorFeedbackUsuario,
              child: const MaterialApp(
                locale: Locale('pt'),
                home: Scaffold(
                  body: Center(
                    child: BotaoFeedback(),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('botao_acionar_feedback')));
        await tester.pumpAndSettle();

        final controller = BetterFeedback.of(
          tester.element(find.byType(BotaoFeedback)),
        );
        expect(controller.isVisible, isTrue);

        controller.hide();
        await tester.pumpAndSettle();
      },
    );
  });
}
