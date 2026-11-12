// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/features/pdf_generation/providers/generation_provider.dart';
import 'package:fixalog/features/pdf_generation/views/visualizador_relatorio_screen.dart';

class GenerationProgressDialog extends ConsumerWidget {
  const GenerationProgressDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generationProvider);
    final locale = ResolvedorIdioma.obterLocaleEfetivo(context, ref);
    final l10n = ResolvedorIdioma.obterTraducoes(locale);
    final ehPt = locale.languageCode == 'pt';

    final String titulo = ehPt
        ? 'Selando Laudo Fixalog'
        : (state.hasError
              ? l10n.geracaoFalhaTitulo
              : (state.isComplete
                    ? l10n.geracaoConcluidaTitulo
                    : l10n.geracaoEmAndamentoTitulo));

    return PopScope(
      canPop: state.isComplete || state.hasError,
      child: AlertDialog(
        title: Text(titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.hasError)
              const Icon(Icons.error, color: Colors.red, size: 48)
            else if (state.isComplete)
              const Icon(Icons.check_circle, color: Colors.green, size: 48)
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              state.hasError ? state.errorMessage! : state.status,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!state.isComplete && !state.hasError)
              LinearProgressIndicator(value: state.progress),
          ],
        ),
        actions: [
          if (state.isComplete || state.hasError)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                l10n.comumFechar,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          if (state.isComplete &&
              (state.epubPath != null || state.outputPath != null))
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.visibility),
              label: Text(
                ehPt ? 'VISUALIZAR RELATÓRIO' : l10n.geracaoBotaoAbrirRelatorio,
              ),
              onPressed: () {
                final epub = state.epubPath ??
                    (state.outputPath?.endsWith('.epub') == true
                        ? state.outputPath
                        : null);
                final tituloRelatorio =
                    (state.title != null && state.title!.trim().isNotEmpty)
                        ? state.title!.trim()
                        : 'Relatório Técnico';
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VisualizadorRelatorioScreen(
                      caminhoEpub: epub,
                      idSessao: state.sessionId,
                      titulo: tituloRelatorio,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
