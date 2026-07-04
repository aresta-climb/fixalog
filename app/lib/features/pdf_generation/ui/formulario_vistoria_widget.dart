import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app/features/pdf_generation/providers/generation_provider.dart';
import 'package:app/features/pdf_generation/ui/generation_progress_dialog.dart';
import 'package:app/core/services/pdf_viewer_service.dart';
import 'package:app/features/pdf_generation/models/generation_media.dart';

class FormularioVistoriaWidget extends ConsumerWidget {
  const FormularioVistoriaWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Vistoria')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Finalizar e Selar PDF'),
          onPressed: () async {
            final dir = await getApplicationDocumentsDirectory();
            final outputPath = '${dir.path}/Laudo_123.pdf';
            
            // Mostra o modal de progresso sem deixar fechar clicando fora
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const GenerationProgressDialog(),
            );

            // Dispara o Provider (Arquivos Mocks para exemplo)
            ref.read(generationProvider.notifier).startGeneration(
              'Vistoria 123',
              [GenerationMedia(file: File('/dummy/video.mp4'))], // Exemplo de mídia coletada no formulário
              outputPath,
            );
          },
        ),
      ),
    );
  }
}
