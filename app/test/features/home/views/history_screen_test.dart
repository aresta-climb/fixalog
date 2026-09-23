// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixlog/features/home/views/history_screen.dart';
import 'package:fixlog/features/home/providers/history_provider.dart';
import 'package:fixlog/core/models/local/submission_record.dart';
import 'package:fixlog/core/services/pdf_viewer_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:fixlog/features/pdf_generation/views/visualizador_relatorio_screen.dart';

Widget _buildScreen({List<SubmissionRecord>? customLogs, PdfViewerService? customPdfViewer}) {
  return ProviderScope(
    overrides: [
      historyProvider.overrideWith((ref) {
        final logs = customLogs ?? List.generate(15, (index) {
          return SubmissionRecord()
            ..nomeProtocolo = 'Protocolo $index'
            ..dataInclusao = index == 0 ? DateTime(2023, 10, 12) : DateTime(2023, 9, 25)
            ..status = SubmissionStatus.gerado
            ..pdfPath = '/caminho/doc_$index.pdf';
        });
        return Stream.value(logs);
      }),
      if (customPdfViewer != null)
        pdfViewerServiceProvider.overrideWithValue(customPdfViewer),
    ],
    child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
  );
}

void main() {
  group('HistoryScreen Widget Tests (TDD)', () {
    testWidgets('Exibe o header FIXLOG', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('FIXLOG'), findsOneWidget);
    });

    testWidgets('Exibe título da página "Histórico"', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Histórico'), findsOneWidget);
    });

    testWidgets('Exibe subtítulo descritivo', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Registros de manutenção preenchidos'), findsOneWidget);
    });

    testWidgets('Exibe os dois stat cards com valores dinâmicos', (WidgetTester tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('LOGS TOTAIS'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('ÚLTIMO LOG'), findsOneWidget);
      expect(find.text('12/10/2023').first, findsOneWidget);
    });

    testWidgets('Exibe tags distintas para relatórios EM PROGRESSO e GERADO', (tester) async {
      final logs = [
        SubmissionRecord()
          ..idSessao = 's1'
          ..nomeProtocolo = 'Via Em Progresso'
          ..dataInclusao = DateTime(2025, 5, 10)
          ..status = SubmissionStatus.emProgresso
          ..pdfPath = '',
        SubmissionRecord()
          ..idSessao = 's2'
          ..nomeProtocolo = 'Via Concluída'
          ..dataInclusao = DateTime(2025, 5, 9)
          ..status = SubmissionStatus.gerado
          ..pdfPath = '/docs/relatorio.pdf',
      ];

      await tester.pumpWidget(_buildScreen(customLogs: logs));
      await tester.pumpAndSettle();

      expect(find.text('Via Em Progresso'), findsOneWidget);
      expect(find.text('EM PROGRESSO'), findsOneWidget);

      expect(find.text('Via Concluída'), findsOneWidget);
      expect(find.text('GERADO'), findsOneWidget);
    });

    testWidgets('Toque no item GERADO abre o visualizador de PDF', (tester) async {
      bool pdfAberto = false;
      String? caminhoAberto;

      final tempDir = Directory.systemTemp.createTempSync('hist_test_');
      final fakePdf = File('${tempDir.path}/relatorio_final.pdf')..writeAsStringSync('fake pdf content');

      final mockPdfViewer = PdfViewerService(
        fileExistsProxy: (_) async => true,
        openProxy: (path) async {
          pdfAberto = true;
          caminhoAberto = path;
          return OpenResult(type: ResultType.done, message: 'OK');
        },
      );

      final logs = [
        SubmissionRecord()
          ..idSessao = 's_pdf'
          ..nomeProtocolo = 'Via com PDF'
          ..dataInclusao = DateTime(2025, 5, 10)
          ..status = SubmissionStatus.gerado
          ..pdfPath = fakePdf.path,
      ];

      await tester.pumpWidget(_buildScreen(customLogs: logs, customPdfViewer: mockPdfViewer));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Via com PDF'));
      await tester.pumpAndSettle();

      expect(pdfAberto, isTrue);
      expect(caminhoAberto, equals(fakePdf.path));

      tempDir.deleteSync(recursive: true);
    });

    testWidgets('Exibe apenas 10 itens inicialmente e pagina para 15', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Protocolo 0'), findsOneWidget);
      expect(find.text('Protocolo 9'), findsOneWidget);
      expect(find.text('Protocolo 10'), findsNothing);

      final carregarMaisFinder = find.text('CARREGAR MAIS');
      expect(carregarMaisFinder, findsOneWidget);

      await tester.ensureVisible(carregarMaisFinder);
      await tester.tap(carregarMaisFinder);
      await tester.pumpAndSettle();

      expect(find.text('Protocolo 10'), findsOneWidget);
      expect(find.text('Protocolo 14'), findsOneWidget);
      expect(carregarMaisFinder, findsNothing);
    });

    testWidgets('Toque no item com relatório EPUB abre VisualizadorRelatorioScreen', (tester) async {
      final logs = [
        SubmissionRecord()
          ..idSessao = 's_epub'
          ..nomeProtocolo = 'Via com EPUB'
          ..dataInclusao = DateTime(2025, 5, 10)
          ..status = SubmissionStatus.gerado
          ..protobufPath = '/path/to/laudo.epub'
          ..pdfPath = '/path/to/laudo.pdf',
      ];

      await tester.pumpWidget(_buildScreen(customLogs: logs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Via com EPUB'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(VisualizadorRelatorioScreen), findsOneWidget);
    });

    testWidgets('Menu de contexto exibe Abrir Relatório (e não Abrir PDF) e abre VisualizadorRelatorioScreen', (tester) async {
      final logs = [
        SubmissionRecord()
          ..idSessao = 's_context'
          ..nomeProtocolo = 'Via Context Menu'
          ..dataInclusao = DateTime(2025, 5, 10)
          ..status = SubmissionStatus.gerado
          ..protobufPath = '/path/to/laudo.epub',
      ];

      await tester.pumpWidget(_buildScreen(customLogs: logs));
      await tester.pumpAndSettle();

      // Abrir o menu de 3 pontos
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Abrir Relatório'), findsOneWidget);
      expect(find.text('Abrir PDF'), findsNothing);

      // Clicar em 'Abrir Relatório'
      await tester.tap(find.text('Abrir Relatório'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(VisualizadorRelatorioScreen), findsOneWidget);
    });

    testWidgets('Item com PDF que possui EPUB irmão correspondente abre VisualizadorRelatorioScreen', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('hist_epub_test_');
      final fakePdf = File('${tempDir.path}/relatorio_com_irmao.pdf')..writeAsStringSync('fake pdf');
      final fakeEpub = File('${tempDir.path}/relatorio_com_irmao.epub')..writeAsStringSync('fake epub');

      final logs = [
        SubmissionRecord()
          ..idSessao = 's_irmao'
          ..nomeProtocolo = 'Via Irmão EPUB'
          ..dataInclusao = DateTime(2025, 5, 10)
          ..status = SubmissionStatus.gerado
          ..pdfPath = fakePdf.path,
      ];

      await tester.pumpWidget(_buildScreen(customLogs: logs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Via Irmão EPUB'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(VisualizadorRelatorioScreen), findsOneWidget);

      tempDir.deleteSync(recursive: true);
    });
  });
}
