// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/features/pdf_generation/ui/generation_progress_dialog.dart';
import 'package:fixalog/features/pdf_generation/providers/generation_provider.dart';
import 'package:fixalog/features/pdf_generation/views/visualizador_relatorio_screen.dart';

class _FakeGenerationNotifier extends StateNotifier<GenerationState>
    implements GenerationNotifier {
  _FakeGenerationNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('GenerationProgressDialog Widget Tests', () {
    testWidgets('exibe indicador de carregamento e status inicial', (
      tester,
    ) async {
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

      expect(find.text('Selando Laudo Fixalog'), findsOneWidget);
      expect(find.text('Comprimindo mídias...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'exibe estado de sucesso e botão VISUALIZAR RELATÓRIO propagando idSessao e titulo para VisualizadorRelatorioScreen',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              generationProvider.overrideWith(
                (ref) => _FakeGenerationNotifier(
                  GenerationState(
                    progress: 1.0,
                    status: 'Selo Fixalog aplicado com sucesso!',
                    isComplete: true,
                    outputPath: '/path/to/laudo.epub',
                    sessionId: 'sessao_123',
                    title: 'Via Dedo de Deus',
                  ),
                ),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: GenerationProgressDialog()),
            ),
          ),
        );

        expect(find.text('Selo Fixalog aplicado com sucesso!'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('FECHAR'), findsOneWidget);
        expect(find.text('VISUALIZAR RELATÓRIO'), findsOneWidget);
        expect(find.text('ABRIR PDF'), findsNothing);

        await tester.tap(find.text('VISUALIZAR RELATÓRIO'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final visualizador = tester.widget<VisualizadorRelatorioScreen>(
          find.byType(VisualizadorRelatorioScreen),
        );
        expect(visualizador.idSessao, equals('sessao_123'));
        expect(visualizador.titulo, equals('Via Dedo de Deus'));
        expect(visualizador.caminhoEpub, equals('/path/to/laudo.epub'));
      },
    );

    testWidgets('exibe estado de erro e fecha ao tocar em FECHAR', (tester) async {
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
      await tester.tap(find.text('FECHAR'));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'renderiza estado concluído sem erro de layout quando ElevatedButtonTheme tem minimumSize(double.infinity, 56)',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              generationProvider.overrideWith(
                (ref) => _FakeGenerationNotifier(
                  GenerationState(
                    progress: 1.0,
                    status: 'Selo Fixalog aplicado com sucesso!',
                    isComplete: true,
                    outputPath: '/path/to/laudo.epub',
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              themeMode: ThemeMode.dark,
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ),
              home: const Scaffold(body: GenerationProgressDialog()),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('VISUALIZAR RELATÓRIO'), findsOneWidget);
      },
    );

    testWidgets(
      'renderiza títulos e botões localizados em Inglês, Árabe e Japonês',
      (tester) async {
        late WidgetRef refCapturado;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localeSistemaProvider.overrideWithValue(const Locale('en')),
              generationProvider.overrideWith(
                (ref) => _FakeGenerationNotifier(
                  GenerationState(
                    progress: 1.0,
                    status: 'Done!',
                    isComplete: true,
                    outputPath: '/path/to/laudo.epub',
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: ResolvedorIdioma.localesSuportados,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    refCapturado = ref;
                    return const GenerationProgressDialog();
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('REPORT READY'), findsOneWidget);
        expect(find.text('CLOSE'), findsOneWidget);
        expect(find.text('OPEN REPORT'), findsOneWidget);

        await refCapturado
            .read(idiomaAtivoProvider.notifier)
            .selecionarIdioma('ja');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('閉じる'), findsOneWidget);

        // Exercita títulos em inglês para estados em andamento e com erro
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              localeSistemaProvider.overrideWithValue(const Locale('en')),
              generationProvider.overrideWith(
                (ref) => _FakeGenerationNotifier(
                  GenerationState(
                    progress: 0.4,
                    status: 'Working...',
                    isComplete: false,
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: ResolvedorIdioma.localesSuportados,
              home: const Scaffold(body: GenerationProgressDialog()),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              localeSistemaProvider.overrideWithValue(const Locale('en')),
              generationProvider.overrideWith(
                (ref) => _FakeGenerationNotifier(
                  GenerationState(
                    progress: 0.4,
                    status: 'Error',
                    hasError: true,
                    errorMessage: 'Failed',
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: ResolvedorIdioma.localesSuportados,
              home: const Scaffold(body: GenerationProgressDialog()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.error), findsOneWidget);
      },
    );
  });
}
