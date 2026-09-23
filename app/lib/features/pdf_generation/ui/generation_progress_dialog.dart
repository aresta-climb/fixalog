// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixlog/features/pdf_generation/providers/generation_provider.dart';
import 'package:fixlog/features/pdf_generation/views/visualizador_relatorio_screen.dart';

class GenerationProgressDialog extends ConsumerWidget {
  const GenerationProgressDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generationProvider);

    return PopScope(
      canPop: state.isComplete || state.hasError,
      child: AlertDialog(
        title: const Text('Selando Laudo FixLog'),
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
              child: const Text('FECHAR', style: TextStyle(color: Colors.white)),
            ),
          if (state.isComplete && (state.epubPath != null || state.outputPath != null))
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.visibility),
              label: const Text('VISUALIZAR RELATÓRIO'),
              onPressed: () {
                final epub = state.epubPath ??
                    (state.outputPath?.endsWith('.epub') == true
                        ? state.outputPath
                        : null);
                final pdf = state.pdfPath ??
                    (state.outputPath?.endsWith('.pdf') == true
                        ? state.outputPath
                        : null);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VisualizadorRelatorioScreen(
                      caminhoEpub: epub,
                      caminhoPdf: pdf,
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
