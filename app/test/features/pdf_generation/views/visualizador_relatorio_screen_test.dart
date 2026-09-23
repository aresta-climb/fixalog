// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixlog/features/pdf_generation/views/visualizador_relatorio_screen.dart';
import 'package:fixlog/core/services/epub_extrator_service.dart';

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
    EpubExtratorService? extratorService,
    Future<void> Function(List<String> paths, {String? text, String? subject})?
        compartilharArquivosProxy,
    Future<void> Function(String path)? abrirArquivoProxy,
    Widget Function(BuildContext context, String caminhoXhtml)? webViewBuilder,
  }) {
    return MaterialApp(
      home: VisualizadorRelatorioScreen(
        caminhoEpub: caminhoEpub,
        caminhoPdf: caminhoPdf,
        caminhoXhtml: caminhoXhtml,
        extratorService: extratorService,
        compartilharArquivosProxy: compartilharArquivosProxy,
        abrirArquivoProxy: abrirArquivoProxy,
        webViewBuilder: webViewBuilder ??
            (context, path) => Container(
                  key: const Key('fake_webview'),
                  child: Text('WebView carregando: $path'),
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
}
