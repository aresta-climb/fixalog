import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/express_form_view_model.dart';
import '../../../core/services/express_pdf_generator.dart';

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
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                
                try {
                  await ExpressPdfGenerator.generateAndPreviewPdf(entries, ref);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao gerar relatório: $e')),
                    );
                  }
                } finally {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close loading dialog
                  }
                }
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text('Gerar Relatório', style: TextStyle(color: Colors.white)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: const Color(0xFF1E2124),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        children: [
                          Image.memory(
                            entry.imageBytes,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              onPressed: () {
                                ref.read(expressFormViewModelProvider.notifier).removeEntry(index);
                              },
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextField(
                          onChanged: (text) {
                            ref.read(expressFormViewModelProvider.notifier).updateDescription(index, text);
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
        onPressed: () => ref.read(expressFormViewModelProvider.notifier).takePhoto(),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Adicionar Foto', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
