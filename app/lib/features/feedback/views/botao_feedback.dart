// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:feedback/feedback.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/resolvedor_idioma.dart';
import '../services/servico_fila_feedback.dart';

/// Assinatura da função de abertura do overlay de feedback (permite injeção em testes).
typedef ExibidorFeedbackCallback = void Function(
  BuildContext context,
  Future<void> Function(UserFeedback feedback) aoSubmeter,
);

/// Botão que aciona a captura de tela anotada do `BetterFeedback` e enfileira
/// o relato no [ServicoFilaFeedback] com persistência offline em SQLite.
class BotaoFeedback extends ConsumerWidget {
  final ExibidorFeedbackCallback? exibidorFeedback;

  const BotaoFeedback({
    super.key,
    this.exibidorFeedback,
  });

  static void _exibirPadrao(
    BuildContext context,
    Future<void> Function(UserFeedback feedback) aoSubmeter,
  ) {
    BetterFeedback.of(context).show(aoSubmeter);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ResolvedorIdioma.obterLocaleEfetivo(context, ref);
    final l10n = ResolvedorIdioma.obterTraducoes(locale);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        key: const Key('botao_acionar_feedback'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.bug_report_outlined, size: 18),
        label: Text(
          l10n.configBotaoFeedback,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        onPressed: () {
          final exibidor = exibidorFeedback ?? _exibirPadrao;
          exibidor(context, (UserFeedback feedback) async {
            final servico = ref.read(servicoFilaFeedbackProvider);
            final categoria =
                (feedback.extra?['categoria'] as String?) ?? 'aplicativo';
            await servico.enfileirarEDespacharFeedback(
              mensagem: feedback.text,
              capturaTela: feedback.screenshot,
              categoria: categoria,
              metadadosExtras: feedback.extra,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.feedbackSucessoEnvio),
                  backgroundColor: const Color(0xFF1B3D2F),
                ),
              );
            }
          });
        },
      ),
    );
  }
}
