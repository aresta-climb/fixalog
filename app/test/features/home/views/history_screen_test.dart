// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/features/home/views/history_screen.dart';
import 'package:fixalog/features/home/providers/history_provider.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/pdf_viewer_service.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:open_filex/open_filex.dart';
import 'package:fixalog/features/pdf_generation/views/visualizador_relatorio_screen.dart';
import 'package:fixalog/features/wizard/views/wizard_screen.dart';
import 'package:fixalog/features/wizard/controllers/wizard_state_controller.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';

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
    testWidgets('Exibe o header FIXALOG', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('FIXALOG'), findsOneWidget);
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

    testWidgets('Toque no item com relatório EPUB (via epubPath mesmo com protobufPath apontando para registro.yaml e pdfPath preenchido) abre VisualizadorRelatorioScreen', (tester) async {
      final logs = [
        SubmissionRecord()
          ..idSessao = 's_epub'
          ..nomeProtocolo = 'Via com EPUB'
          ..dataInclusao = DateTime(2025, 5, 10)
          ..status = SubmissionStatus.gerado
          ..epubPath = '/path/to/sessoes/s_epub/relatorio.epub'
          ..protobufPath = '/path/to/sessoes/s_epub/registro.yaml'
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
      File('${tempDir.path}/relatorio_com_irmao.epub').writeAsStringSync('fake epub');

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

    testWidgets('Separa Manutenções e Materiais permitindo alternar entre as categorias e exibir tituloExibicao', (tester) async {
      final logs = [
        SubmissionRecord()
          ..idSessao = 'manut_1'
          ..idProtocolo = 'manutencao_ferragens'
          ..nomeProtocolo = 'Manutenção de Proteções Fixas'
          ..tituloExibicao = 'Via Diedro Sul'
          ..tipoRegistro = SubmissionTipoRegistro.manutencao
          ..dataInclusao = DateTime(2026, 10, 10)
          ..status = SubmissionStatus.gerado
          ..protobufPath = '/path/to/manut.epub',
        SubmissionRecord()
          ..idSessao = 'mat_1'
          ..idProtocolo = 'cadastro_material'
          ..nomeProtocolo = 'Cadastro de Material de Manutenção'
          ..tituloExibicao = 'Kit Parabolt Inox 316 + Chapeleta'
          ..tipoRegistro = SubmissionTipoRegistro.material
          ..dataInclusao = DateTime(2026, 10, 11)
          ..status = SubmissionStatus.gerado
          ..protobufPath = '/path/to/mat.epub',
      ];

      await tester.pumpWidget(_buildScreen(customLogs: logs));
      await tester.pumpAndSettle();

      // Por padrão, a aba MANUTENÇÕES está selecionada: mostra a manutenção e oculta o material
      expect(find.text('MANUTENÇÕES'), findsOneWidget);
      expect(find.text('MATERIAIS'), findsOneWidget);
      expect(find.text('Via Diedro Sul'), findsOneWidget);
      expect(find.text('Kit Parabolt Inox 316 + Chapeleta'), findsNothing);

      // Alterna para a categoria MATERIAIS
      await tester.tap(find.text('MATERIAIS'));
      await tester.pumpAndSettle();

      expect(find.text('Kit Parabolt Inox 316 + Chapeleta'), findsOneWidget);
      expect(find.text('Via Diedro Sul'), findsNothing);

      // Verifica que o menu de contexto do material permite Abrir Relatório, Editar e Excluir
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Abrir Relatório'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Excluir'), findsOneWidget);
    });

    testWidgets('Permite excluir relatório legado com artefato de assinatura e EPUB irmão sem erros', (tester) async {
      late Directory tempDir;
      late BancoDadosLocal banco;
      late SessionBundleManager sessionManager;
      late File relatorioPdf;
      late File relatorioEpubIrmao;
      late Directory dirSessao;
      late File arqAssinatura;
      late SubmissionRecord record;

      await tester.runAsync(() async {
        tempDir = await Directory.systemTemp.createTemp('hist_screen_del_');
        banco = await BancoDadosLocal.abrirEmMemoria();
        sessionManager = SessionBundleManager(baseDirectoryGetter: () async => tempDir);

        relatorioPdf = File('${tempDir.path}/laudo_legado.pdf')..writeAsStringSync('pdf');
        relatorioEpubIrmao = File('${tempDir.path}/laudo_legado.epub')..writeAsStringSync('epub');
        dirSessao = await sessionManager.getSessionDirectory('sessao_legada_1');
        arqAssinatura = File('${dirSessao.path}/assinatura_c_original.png')
          ..writeAsBytesSync([1, 2, 3]);
        final arqManifesto = File('${dirSessao.path}/registro.binarypb')
          ..writeAsBytesSync([4, 5, 6]);

        record = SubmissionRecord()
          ..idSessao = 'sessao_legada_1'
          ..idProtocolo = 'manutencao_ferragens'
          ..nomeProtocolo = 'Manutenção Antiga com Assinatura'
          ..tituloExibicao = 'Via Legada Com Assinatura'
          ..tipoRegistro = SubmissionTipoRegistro.manutencao
          ..dataInclusao = DateTime(2025, 8, 10)
          ..status = SubmissionStatus.gerado
          ..pdfPath = relatorioPdf.path
          ..protobufPath = arqManifesto.path;

        await banco.salvarSubmissao(record);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bancoDadosLocalProvider.overrideWithValue(banco),
            sessionBundleManagerProvider.overrideWithValue(sessionManager),
            historyProvider.overrideWith((ref) => Stream.value([record])),
          ],
          child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Via Legada Com Assinatura'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(find.text('Excluir Protocolo'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(relatorioPdf.existsSync(), isFalse);
      expect(relatorioEpubIrmao.existsSync(), isFalse);
      expect(arqAssinatura.existsSync(), isFalse);
      expect(dirSessao.existsSync(), isFalse);
      expect(banco.listarSubmissoesSync(), isEmpty);

      await tester.runAsync(() async {
        await banco.fechar();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });
    });

    testWidgets('Menu de 3 pontinhos exibe "Criar cópia" tanto para GERADO quanto EM PROGRESSO e abre WizardScreen na nova sessão com sufixo (Cópia)', (tester) async {
      late Directory tempDir;
      late BancoDadosLocal banco;
      late SessionBundleManager sessionManager;
      late SubmissionRecord recordGerado;
      late SubmissionRecord recordRascunho;

      const yamlTeste = '''
protocolo:
  id: manutencao_ferragens
  nome: "Manutenção de Proteções Fixas"
  versao: "1.0.0"
  blocos:
    - id: via
      titulo: "Identificação da Via"
      steps:
        - id: s1
          conteudos:
            - id: via_nome
              campo_simples:
                label: "Nome da via"
                tipo: TEXT
                obrigatorio: true
''';

      await tester.runAsync(() async {
        tempDir = await Directory.systemTemp.createTemp('hist_screen_dup_');
        banco = await BancoDadosLocal.abrirEmMemoria();
        sessionManager = SessionBundleManager(baseDirectoryGetter: () async => tempDir);

        final regPb = Registro(
          idSessao: 'sessao_orig_1',
          idProtocolo: 'manutencao_ferragens',
          versaoProtocolo: '1.0.0',
          yamlConteudo: yamlTeste,
          respostas: [
            MapEntry('via_nome', Resposta(texto: 'Via do Diedro')),
          ],
        );
        await sessionManager.saveManifest(
          sessionId: 'sessao_orig_1',
          binarypb: regPb.writeToBuffer(),
        );

        recordGerado = SubmissionRecord()
          ..idSessao = 'sessao_orig_1'
          ..idProtocolo = 'manutencao_ferragens'
          ..nomeProtocolo = 'Manutenção de Proteções Fixas'
          ..tituloExibicao = 'Via do Diedro'
          ..tipoRegistro = SubmissionTipoRegistro.manutencao
          ..dataInclusao = DateTime(2026, 10, 20)
          ..status = SubmissionStatus.gerado
          ..pdfPath = '/tmp/via.pdf';

        recordRascunho = SubmissionRecord()
          ..idSessao = 'sessao_rasc_1'
          ..idProtocolo = 'manutencao_ferragens'
          ..nomeProtocolo = 'Manutenção de Proteções Fixas'
          ..tituloExibicao = 'Via em Rascunho'
          ..tipoRegistro = SubmissionTipoRegistro.manutencao
          ..dataInclusao = DateTime(2026, 10, 19)
          ..status = SubmissionStatus.emProgresso;

        await banco.salvarSubmissao(recordGerado);
        await banco.salvarSubmissao(recordRascunho);
      });

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bancoDadosLocalProvider.overrideWithValue(banco),
            sessionBundleManagerProvider.overrideWithValue(sessionManager),
            historyProvider.overrideWith(
              (ref) => Stream.value([recordGerado, recordRascunho]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const HistoryScreen();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica "Criar cópia" no item EM PROGRESSO (segundo item)
      final botoesMenu = find.byIcon(Icons.more_vert);
      expect(botoesMenu, findsNWidgets(2));
      await tester.tap(botoesMenu.at(1));
      await tester.pumpAndSettle();
      expect(find.text('Continuar preenchimento'), findsOneWidget);
      expect(find.text('Criar cópia'), findsOneWidget);

      // Fecha o menu do segundo item tocando fora
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Abre menu do primeiro item (GERADO) e toca em "Criar cópia"
      await tester.tap(botoesMenu.at(0));
      await tester.pumpAndSettle();
      expect(find.text('Abrir Relatório'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Criar cópia'), findsOneWidget);

      await tester.tap(find.text('Criar cópia'));
      await tester.pump();

      // O diálogo de carregamento giratório deve aparecer enquanto a cópia inicia
      expect(find.text('Criando cópia do relatório...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      // Deve ter aberto o WizardScreen carregado na nova sessão com sufixo (Cópia)
      expect(find.byType(WizardScreen), findsOneWidget);
      final wizardState = capturedRef.read(wizardControllerProvider);
      expect(wizardState.sessionId, isNot(equals('sessao_orig_1')));
      expect(wizardState.answers['route_name']?.texto, equals('Via do Diedro (Cópia)'));

      await tester.runAsync(() async {
        await capturedRef.read(wizardControllerProvider.notifier).flushAutoSave();
        await banco.fechar();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });
    });

    testWidgets(
      'Renderiza títulos, abas e tags localizados em Inglês, Árabe e Japonês sem overflow visual',
      (tester) async {
        final logs = [
          SubmissionRecord()
            ..idSessao = 's1'
            ..nomeProtocolo = 'Route A'
            ..dataInclusao = DateTime(2026, 5, 10)
            ..status = SubmissionStatus.gerado
            ..pdfPath = '/docs/a.pdf',
        ];

        late WidgetRef refCapturado;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localeSistemaProvider.overrideWithValue(const Locale('en')),
              historyProvider.overrideWith((ref) => Stream.value(logs)),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: ResolvedorIdioma.localesSuportados,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    refCapturado = ref;
                    return const HistoryScreen();
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('AUDIT HISTORY'), findsOneWidget);
        expect(find.text('COMPLETED'), findsOneWidget);

        await refCapturado
            .read(idiomaAtivoProvider.notifier)
            .selecionarIdioma('ar');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('سجل المعاينات'), findsOneWidget);

        await refCapturado
            .read(idiomaAtivoProvider.notifier)
            .selecionarIdioma('ja');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('監査履歴'), findsOneWidget);
      },
    );

    testWidgets(
      'Exibe Icons.cloud_done_outlined quando enviadoNuvem=true, Icons.cloud_upload_outlined quando enviadoNuvem=false e aciona sincronização manual',
      (tester) async {
        final logs = [
          SubmissionRecord()
            ..idSessao = 's_sincronizado'
            ..nomeProtocolo = 'Via na Nuvem'
            ..dataInclusao = DateTime(2026, 11, 8)
            ..status = SubmissionStatus.gerado
            ..pdfPath = '/docs/a.pdf'
            ..enviadoNuvem = true,
          SubmissionRecord()
            ..idSessao = 's_pendente'
            ..nomeProtocolo = 'Via Pendente Upload'
            ..dataInclusao = DateTime(2026, 11, 7)
            ..status = SubmissionStatus.gerado
            ..pdfPath = '/docs/b.pdf'
            ..enviadoNuvem = false,
        ];

        await tester.pumpWidget(_buildScreen(customLogs: logs));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
        expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);

        final botaoSync = find.byKey(const Key('botao_sincronizar_nuvem'));
        expect(botaoSync, findsOneWidget);
        await tester.tap(botaoSync);
        await tester.pump();
      },
    );
  });
}
