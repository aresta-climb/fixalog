// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/features/pdf_generation/views/visualizador_relatorio_screen.dart';
import 'package:fixalog/core/services/epub_extrator_service.dart';
import 'package:fixalog/core/services/pdf_print_summary_service.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';

class FakePdfPrintSummaryService extends Fake implements PdfPrintSummaryService {
  String? ultimoCaminhoSaida;
  Registro? ultimoRegistro;
  Map<String, String>? ultimoMapeamentoMidias;
  int chamadas = 0;
  final Duration? delay;

  FakePdfPrintSummaryService({this.delay});

  @override
  Future<File> exportarPdfResumido({
    required String caminhoSaida,
    required Registro registro,
    required String idSessao,
    required String urlCanonica,
    Map<String, String> mapeamentoMidias = const {},
    Map<String, String> posterFrames = const {},
    String? baseUrl,
  }) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }
    chamadas++;
    ultimoCaminhoSaida = caminhoSaida;
    ultimoRegistro = registro;
    ultimoMapeamentoMidias = mapeamentoMidias;
    final file = File(caminhoSaida);
    file.createSync(recursive: true);
    file.writeAsStringSync('pdf content');
    return file;
  }
}

class FakeEpubExtratorService extends EpubExtratorService {
  final String? caminhoRetorno;
  bool deveFalhar;
  final Duration? delay;

  FakeEpubExtratorService({
    this.caminhoRetorno,
    this.deveFalhar = false,
    this.delay,
  });

  @override
  Future<String> extrairEpub({
    required String caminhoEpub,
    String? diretorioDestino,
  }) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }
    if (deveFalhar) {
      throw Exception('Falha ao descompactar EPUB simulada');
    }
    return caminhoRetorno ?? '/cache/relatorio.xhtml';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget criarTelaParaTeste({
    String? caminhoEpub,
    String? caminhoPdf,
    String? caminhoXhtml,
    String? idSessao,
    EpubExtratorService? extratorService,
    Future<void> Function(List<String> paths, {String? text, String? subject})?
        compartilharArquivosProxy,
    Future<void> Function(String path)? abrirArquivoProxy,
    PdfPrintSummaryService? pdfSummaryService,
    SessionBundleManager? sessionManager,
    Widget Function(BuildContext context, String caminhoXhtml)? webViewBuilder,
    Future<String> Function({
      required String? caminhoEpub,
      required String? caminhoXhtml,
      required String? idSessao,
    })? geradorPdfSobDemandaProxy,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          splashFactory: InkRipple.splashFactory,
        ),
        home: VisualizadorRelatorioScreen(
          caminhoEpub: caminhoEpub,
          caminhoPdf: caminhoPdf,
          caminhoXhtml: caminhoXhtml,
          idSessao: idSessao,
          extratorService: extratorService,
          pdfSummaryService: pdfSummaryService,
          sessionManager: sessionManager,
          compartilharArquivosProxy: compartilharArquivosProxy,
          abrirArquivoProxy: abrirArquivoProxy,
          geradorPdfSobDemandaProxy: geradorPdfSobDemandaProxy,
          webViewBuilder: webViewBuilder ??
              (context, path) => Container(
                    key: const Key('fake_webview'),
                    child: Text('WebView carregando: $path'),
                  ),
        ),
      ),
    );
  }

  testWidgets('Deve exibir indicador de carregamento e depois exibir o relatório via WebView', (tester) async {
    final fakeExtrator = FakeEpubExtratorService(caminhoRetorno: '/tmp/relatorio.xhtml');

    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: '/documentos/relatorio.epub',
      caminhoPdf: '/documentos/relatorio.pdf',
      extratorService: fakeExtrator,
    ));

    // Inicialmente exibe indicador de carregamento
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Carregando relatório...'), findsOneWidget);

    await tester.pumpAndSettle();

    // Após conclusão da extração, exibe o conteúdo do WebView
    expect(find.byKey(const Key('fake_webview')), findsOneWidget);
    expect(find.text('WebView carregando: /tmp/relatorio.xhtml'), findsOneWidget);
  });

  testWidgets('Se caminhoXhtml for fornecido, carrega imediatamente sem chamar extrator', (tester) async {
    await tester.pumpWidget(criarTelaParaTeste(
      caminhoXhtml: '/direto/relatorio.xhtml',
    ));

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fake_webview')), findsOneWidget);
    expect(find.text('WebView carregando: /direto/relatorio.xhtml'), findsOneWidget);
  });

  testWidgets('Deve exibir mensagem de erro e permitir tentar novamente quando extração falhar', (tester) async {
    final fakeExtrator = FakeEpubExtratorService(
      deveFalhar: true,
      delay: const Duration(milliseconds: 50),
    );

    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: '/documentos/corrompido.epub',
      extratorService: fakeExtrator,
    ));

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.textContaining('Falha ao descompactar EPUB'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    // Permitir sucesso na tentativa seguinte
    fakeExtrator.deveFalhar = false;

    // Clicar em tentar novamente
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fake_webview')), findsOneWidget);
  });

  testWidgets('Deve abrir modal de compartilhamento e compartilhar EPUB ao selecionar opção', (tester) async {
    List<String>? arquivosCompartilhados;

    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: '/meu/laudo.epub',
      caminhoPdf: '/meu/laudo.pdf',
      caminhoXhtml: '/cache/relatorio.xhtml',
      compartilharArquivosProxy: (paths, {text, subject}) async {
        arquivosCompartilhados = paths;
      },
    ));

    await tester.pumpAndSettle();

    final botaoCompartilhar = find.byKey(const Key('btn_compartilhar'));
    expect(botaoCompartilhar, findsOneWidget);
    await tester.tap(botaoCompartilhar);
    await tester.pumpAndSettle();

    expect(find.text('Compartilhar Relatório'), findsOneWidget);
    expect(find.text('Relatório Completo (EPUB)'), findsOneWidget);
    expect(find.text('Versão Resumida (PDF)'), findsOneWidget);

    final opcaoEpub = find.byKey(const Key('opcao_compartilhar_epub'));
    expect(opcaoEpub, findsOneWidget);
    await tester.tap(opcaoEpub);
    await tester.pumpAndSettle();

    expect(arquivosCompartilhados, equals(['/meu/laudo.epub']));
  });

  testWidgets('Deve abrir modal de compartilhamento e compartilhar PDF ao selecionar opção', (tester) async {
    List<String>? arquivosCompartilhados;

    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: '/meu/laudo.epub',
      caminhoPdf: '/meu/laudo.pdf',
      caminhoXhtml: '/cache/relatorio.xhtml',
      compartilharArquivosProxy: (paths, {text, subject}) async {
        arquivosCompartilhados = paths;
      },
    ));

    await tester.pumpAndSettle();

    final botaoCompartilhar = find.byKey(const Key('btn_compartilhar'));
    expect(botaoCompartilhar, findsOneWidget);
    await tester.tap(botaoCompartilhar);
    await tester.pumpAndSettle();

    final opcaoPdf = find.byKey(const Key('opcao_compartilhar_pdf'));
    expect(opcaoPdf, findsOneWidget);
    await tester.tap(opcaoPdf);
    await tester.pumpAndSettle();

    expect(arquivosCompartilhados, equals(['/meu/laudo.pdf']));
  });

  testWidgets('Deve invocar abrirArquivoProxy ao clicar no botão de abrir externamente', (tester) async {
    String? caminhoAberto;

    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: '/meu/laudo.epub',
      caminhoXhtml: '/cache/relatorio.xhtml',
      abrirArquivoProxy: (path) async {
        caminhoAberto = path;
      },
    ));

    await tester.pumpAndSettle();

    final botaoAbrir = find.byKey(const Key('btn_abrir_externo'));
    expect(botaoAbrir, findsOneWidget);
    await tester.tap(botaoAbrir);
    await tester.pump();

    expect(caminhoAberto, equals('/meu/laudo.epub'));
  });

  testWidgets('Deve exibir erro se nenhum caminho de EPUB ou XHTML for fornecido', (tester) async {
    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: null,
      caminhoXhtml: null,
    ));

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.textContaining('Nenhum caminho de arquivo EPUB ou XHTML informado'), findsOneWidget);
  });

  testWidgets('Deve exibir SnackBar caso ocorra erro ao compartilhar EPUB', (tester) async {
    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: '/meu/laudo.epub',
      caminhoXhtml: '/cache/relatorio.xhtml',
      compartilharArquivosProxy: (paths, {text, subject}) async {
        throw Exception('Erro simulado no share EPUB');
      },
    ));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_compartilhar')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('opcao_compartilhar_epub')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Erro ao compartilhar EPUB'), findsOneWidget);
  });

  testWidgets('Deve exibir SnackBar caso ocorra erro ao compartilhar PDF', (tester) async {
    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: '/meu/laudo.epub',
      caminhoPdf: '/meu/laudo.pdf',
      caminhoXhtml: '/cache/relatorio.xhtml',
      compartilharArquivosProxy: (paths, {text, subject}) async {
        throw Exception('Erro simulado no share PDF');
      },
    ));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_compartilhar')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('opcao_compartilhar_pdf')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Erro ao compartilhar PDF'), findsOneWidget);
  });

  testWidgets('Deve exibir SnackBar caso ocorra erro ao abrir externamente', (tester) async {
    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: '/meu/laudo.epub',
      caminhoXhtml: '/cache/relatorio.xhtml',
      abrirArquivoProxy: (path) async {
        throw Exception('Erro simulado ao abrir externo');
      },
    ));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_abrir_externo')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Erro ao abrir aplicativo externo'), findsOneWidget);
  });

  testWidgets('Deve abrir modal de compartilhamento através do ícone da AppBar', (tester) async {
    var epubCompartilhado = false;

    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: '/meu/laudo.epub',
      caminhoPdf: '/meu/laudo.pdf',
      caminhoXhtml: '/cache/relatorio.xhtml',
      compartilharArquivosProxy: (paths, {text, subject}) async {
        if (paths.first.endsWith('.epub')) epubCompartilhado = true;
      },
    ));

    await tester.pumpAndSettle();

    // Clicar no ícone de compartilhamento na AppBar
    await tester.tap(find.byTooltip('Compartilhar'));
    await tester.pumpAndSettle();

    expect(find.text('Compartilhar Relatório'), findsOneWidget);

    await tester.tap(find.byKey(const Key('opcao_compartilhar_epub')));
    await tester.pumpAndSettle();

    expect(epubCompartilhado, isTrue);
  });

  testWidgets('Deve gerar PDF resumido sob demanda e compartilhar quando caminhoPdf for nulo', (tester) async {
    List<String>? arquivosCompartilhados;
    int chamadasGerador = 0;

    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: '/meu/laudo.epub',
      caminhoPdf: null,
      caminhoXhtml: '/cache/relatorio.xhtml',
      geradorPdfSobDemandaProxy: ({caminhoEpub, caminhoXhtml, idSessao}) async {
        chamadasGerador++;
        return '/gerado/sob_demanda.pdf';
      },
      compartilharArquivosProxy: (paths, {text, subject}) async {
        arquivosCompartilhados = paths;
      },
    ));

    await tester.pumpAndSettle();

    // Clica em compartilhar
    await tester.tap(find.byKey(const Key('btn_compartilhar')));
    await tester.pumpAndSettle();

    // Seleciona Versão Resumida (PDF)
    final opcaoPdf = find.byKey(const Key('opcao_compartilhar_pdf'));
    expect(opcaoPdf, findsOneWidget);
    await tester.tap(opcaoPdf);
    await tester.pumpAndSettle();

    expect(chamadasGerador, equals(1));
    expect(arquivosCompartilhados, equals(['/gerado/sob_demanda.pdf']));
  });

  testWidgets('Deve exibir diálogo Gerando PDF resumido... durante a geração sob demanda', (tester) async {
    final completer = Completer<String>();

    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: '/meu/laudo.epub',
      caminhoPdf: null,
      caminhoXhtml: '/cache/relatorio.xhtml',
      geradorPdfSobDemandaProxy: ({caminhoEpub, caminhoXhtml, idSessao}) => completer.future,
      compartilharArquivosProxy: (paths, {text, subject}) async {},
    ));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_compartilhar')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('opcao_compartilhar_pdf')));
    // Avança a transição do fechamento do modal e abertura do diálogo
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verifica que o diálogo com indicador e texto está visível
    expect(find.text('Gerando PDF resumido...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Conclui a geração assíncrona
    completer.complete('/gerado/lento.pdf');
    await tester.pumpAndSettle();

    // Diálogo deve sumir após conclusão
    expect(find.text('Gerando PDF resumido...'), findsNothing);
  });

  testWidgets('Deve tratar erros na geração sob demanda com SnackBar amigável', (tester) async {
    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: '/meu/laudo.epub',
      caminhoPdf: null,
      caminhoXhtml: '/cache/relatorio.xhtml',
      geradorPdfSobDemandaProxy: ({caminhoEpub, caminhoXhtml, idSessao}) async {
        throw Exception('Falha ao renderizar PDF');
      },
      compartilharArquivosProxy: (paths, {text, subject}) async {},
    ));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_compartilhar')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('opcao_compartilhar_pdf')));
    await tester.pumpAndSettle();

    // Verifica que a SnackBar informativa foi exibida
    expect(find.textContaining('Erro ao gerar PDF resumido'), findsOneWidget);
  });

  testWidgets('Compartilhamento subsequente deve reutilizar PDF gerado sem invocar gerador novamente', (tester) async {
    int chamadasGerador = 0;
    List<String>? ultimosArquivos;

    await tester.pumpWidget(criarTelaParaTeste(
      caminhoEpub: '/meu/laudo.epub',
      caminhoPdf: null,
      caminhoXhtml: '/cache/relatorio.xhtml',
      geradorPdfSobDemandaProxy: ({caminhoEpub, caminhoXhtml, idSessao}) async {
        chamadasGerador++;
        return '/gerado/em_cache.pdf';
      },
      compartilharArquivosProxy: (paths, {text, subject}) async {
        ultimosArquivos = paths;
      },
    ));

    await tester.pumpAndSettle();

    // Primeiro compartilhamento (dispara geração)
    await tester.tap(find.byKey(const Key('btn_compartilhar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opcao_compartilhar_pdf')));
    await tester.pumpAndSettle();

    expect(chamadasGerador, equals(1));
    expect(ultimosArquivos, equals(['/gerado/em_cache.pdf']));

    // Segundo compartilhamento (deve reutilizar sem gerar novamente)
    await tester.tap(find.byKey(const Key('btn_compartilhar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opcao_compartilhar_pdf')));
    await tester.pumpAndSettle();

    expect(chamadasGerador, equals(1)); // Não incrementou!
    expect(ultimosArquivos, equals(['/gerado/em_cache.pdf']));
  });

  testWidgets(
    'Geração padrão sob demanda utiliza miniaturas _thumb.webp do bundle da sessão e exporta PDF',
    (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('vis_relatorio_test_');
      try {
        final sessionManager = SessionBundleManager(
          baseDirectoryGetter: () async => tempDir,
        );
        final fakePdfService = FakePdfPrintSummaryService();
        const sessionId = 'sessao-integ-1';

        // 1. Cria a miniatura _thumb.webp no bundle da sessão
        final thumbBytes = Uint8List.fromList([10, 20, 30, 40]);
        final thumbFile = File('${tempDir.path}/sessoes/$sessionId/foto1_thumb.webp');
        thumbFile.parent.createSync(recursive: true);
        thumbFile.writeAsBytesSync(thumbBytes);

        // 2. Cria o arquivo XHTML e Protobuf da vistoria
        final xhtmlFile = File('${tempDir.path}/relatorios_cache/$sessionId/OEBPS/relatorio.xhtml');
        xhtmlFile.parent.createSync(recursive: true);
        xhtmlFile.writeAsStringSync('<html><body>Teste</body></html>');

        final registro = Registro()
          ..idProtocolo = 'Protocolo Teste'
          ..respostas['r1'] = (Resposta()
            ..midia = (ReferenciaMidia()
              ..imagem = (ArquivoImagem()..uuid = 'foto1')));
        final pbFile = File('${tempDir.path}/relatorios_cache/$sessionId/OEBPS/dados/registro.binarypb');
        pbFile.parent.createSync(recursive: true);
        pbFile.writeAsBytesSync(registro.writeToBuffer());

        List<String>? arquivosCompartilhados;

        await tester.pumpWidget(criarTelaParaTeste(
          caminhoEpub: '${tempDir.path}/relatorio.epub',
          caminhoPdf: null,
          caminhoXhtml: xhtmlFile.path,
          idSessao: sessionId,
          pdfSummaryService: fakePdfService,
          sessionManager: sessionManager,
          compartilharArquivosProxy: (paths, {text, subject}) async {
            arquivosCompartilhados = paths;
          },
        ));

        await tester.pumpAndSettle();

        // Clica em compartilhar
        await tester.tap(find.byKey(const Key('btn_compartilhar')));
        await tester.pumpAndSettle();

        // Clica na opção Versão Resumida (PDF)
        await tester.tap(find.byKey(const Key('opcao_compartilhar_pdf')));
        await tester.pumpAndSettle();

      // Verifica que o serviço padrão de impressão foi invocado
      expect(fakePdfService.chamadas, equals(1));
      expect(fakePdfService.ultimoMapeamentoMidias, isNotNull);
      // Verifica que a miniatura [10, 20, 30, 40] foi injetada como data URI
      expect(
        fakePdfService.ultimoMapeamentoMidias!['foto1'],
        startsWith('data:image/webp;base64,'),
      );
      // E o arquivo gerado foi compartilhado
      expect(arquivosCompartilhados, isNotNull);
      expect(arquivosCompartilhados!.first, endsWith('fixalog_$sessionId.pdf'));
    } finally {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    }
  });
}
