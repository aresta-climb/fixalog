import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/express_form_view_model.dart';
import 'package:app/core/services/session_bundle_manager.dart';
import 'package:app/features/pdf_generation/providers/generation_provider.dart';
import 'package:app/features/pdf_generation/models/generation_media.dart';
import 'package:app/features/pdf_generation/ui/generation_progress_dialog.dart';
import 'package:app/core/services/pdf_viewer_service.dart';

class ExpressFormScreen extends ConsumerWidget {
  const ExpressFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(expressFormViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Expresso'),
        actions: [
          if (entries.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                final sessionId = await ref.read(expressFormViewModelProvider.notifier).saveSession();
                
                final sessionManager = ref.read(sessionBundleManagerProvider);
                final outputPath = await sessionManager.getReportFilePath(sessionId: sessionId);
                
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const GenerationProgressDialog(),
                );

                final files = entries.map((e) => GenerationMedia(file: File(e.mediaPath), description: e.description)).toList();
                
                // startGeneration also needs to receive the sessionId to attach the manifest
                ref.read(generationProvider.notifier).startGeneration(
                  'Registro Expresso',
                  files,
                  outputPath,
                  sessionId: sessionId,
                );
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                'Gerar Relatório',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma foto adicionada ainda.\nToque no botão + para começar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: const Color(0xFF1E2124),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        children: [
                          Image.file(
                            File(entry.mediaPath),
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                              onPressed: () {
                                ref
                                    .read(expressFormViewModelProvider.notifier)
                                    .removeEntry(index);
                              },
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextFormField(
                          key: ValueKey(entries[index].uuid),
                          initialValue: entries[index].description,
                          onChanged: (text) {
                            ref
                                .read(expressFormViewModelProvider.notifier)
                                .updateDescription(index, text);
                          },
                          decoration: const InputDecoration(
                            hintText: 'Descrição (opcional)',
                            border: InputBorder.none,
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF6B00),
        onPressed: () =>
            ref.read(expressFormViewModelProvider.notifier).takePhoto(),
        icon: const Icon(Icons.camera_alt),
        label: const Text(
          'Adicionar Foto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
