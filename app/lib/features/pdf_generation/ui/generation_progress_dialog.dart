import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/pdf_generation/providers/generation_provider.dart';
import 'package:app/core/services/pdf_viewer_service.dart';

class GenerationProgressDialog extends ConsumerWidget {
  const GenerationProgressDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generationProvider);

    return PopScope(
      canPop: state.isComplete || state.hasError,
      child: AlertDialog(
        title: const Text('Selando Laudo FixaLog'),
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
          if (state.isComplete && state.outputPath != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('ABRIR PDF'),
              onPressed: () {
                ref.read(pdfViewerServiceProvider).openPdf(state.outputPath!).catchError((e) {
                  debugPrint('Erro ao abrir: $e');
                });
              },
          ),
      ],
      ),
    );
  }
}

// Para usar na UI:
// showDialog(
//   context: context,
//   barrierDismissible: false,
//   builder: (_) => GenerationProgressDialog(onComplete: () => print('Done!')),
// );
// 
// E então acionar a geração:
// ref.read(generationProvider.notifier).startGeneration('Vistoria X', [file1, file2], '/path/to/final.pdf');
