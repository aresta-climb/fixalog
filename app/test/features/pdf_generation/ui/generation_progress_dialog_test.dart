import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixlog/features/pdf_generation/ui/generation_progress_dialog.dart';
import 'package:fixlog/features/pdf_generation/providers/generation_provider.dart';

class _FakeGenerationNotifier extends StateNotifier<GenerationState>
    implements GenerationNotifier {
  _FakeGenerationNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('GenerationProgressDialog Widget Tests', () {
    testWidgets('exibe indicador de carregamento e status inicial', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            generationProvider.overrideWith(
              (ref) => _FakeGenerationNotifier(
                GenerationState(
                  progress: 0.5,
                  status: 'Comprimindo mídias...',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GenerationProgressDialog()),
          ),
        ),
      );

      expect(find.text('Selando Laudo FixLog'), findsOneWidget);
      expect(find.text('Comprimindo mídias...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('exibe estado de sucesso e botão ABRIR PDF', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            generationProvider.overrideWith(
              (ref) => _FakeGenerationNotifier(
                GenerationState(
                  progress: 1.0,
                  status: 'Selo FixLog aplicado com sucesso!',
                  isComplete: true,
                  outputPath: '/path/to/laudo.pdf',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GenerationProgressDialog()),
          ),
        ),
      );

      expect(find.text('Selo FixLog aplicado com sucesso!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('FECHAR'), findsOneWidget);
      expect(find.text('ABRIR PDF'), findsOneWidget);
    });

    testWidgets('exibe estado de erro', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            generationProvider.overrideWith(
              (ref) => _FakeGenerationNotifier(
                GenerationState(
                  progress: 0.0,
                  status: 'Falha',
                  hasError: true,
                  errorMessage: 'Erro ao gerar assinatura',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GenerationProgressDialog()),
          ),
        ),
      );

      expect(find.text('Erro ao gerar assinatura'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('FECHAR'), findsOneWidget);
    });
  });
}
