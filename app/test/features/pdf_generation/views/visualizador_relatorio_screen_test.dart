// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/features/pdf_generation/views/visualizador_relatorio_screen.dart';
import 'package:fixalog/core/services/epub_extrator_service.dart';
import 'package:fixalog/core/services/pdf_print_summary_service.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';

const String kYamlManutencaoVis = '''
id: "manutencao_ferragens"
versao: "1.0.0"
nome: "Manutenção de Ferragens"
blocos:
  - id: "b1"
    titulo: "Bloco 1"
    steps:
      - id: "s1"
        conteudos:
          - id: "via_nome"
            campo_simples:
              label: "Nome da Via"
              tipo: "TEXT"
          - id: "r1"
            campo_simples:
              label: "Foto 1"
              tipo: "IMAGE"
          - id: "r2"
            campo_simples:
              label: "Vídeo 1"
              tipo: "VIDEO"
          - id: "laudo_pdf"
            campo_simples:
              label: "Laudo PDF"
              tipo: "IMAGE"
          - id: "lista_materiais_c"
            ref_materiais:
              label: "Materiais"
              origem_catalogo: true
''';

const String kYamlMaterialVis = '''
id: "cadastro_material"
versao: "1.0.0"
nome: "Cadastro de Material"
blocos:
  - id: "b1"
    titulo: "Bloco 1"
    steps:
      - id: "s1"
        conteudos:
          - id: "mat_nome"
            campo_simples:
              label: "Nome do Conjunto"
              tipo: "TEXT"
          - id: "nf_foto"
            campo_simples:
              label: "Foto da NF"
              tipo: "IMAGE"
          - id: "lista_materiais_cadastro"
            lista_acoes:
              label: "Itens"
              tipos_disponiveis:
                - id: "chapeleta"
                  label: "Chapeleta"
                  steps:
                    - id: "s_ch"
                      conteudos:
                        - id: "mat_nota_fiscal"
                          campo_simples:
                            label: "Nota Fiscal PDF"
                            tipo: "IMAGE"
''';

class FakePdfPrintSummaryService extends Fake implements PdfPrintSummaryService {
  String? ultimoCaminhoSaida;
  Registro? ultimoRegistro;
  Map<String, String>? ultimoMapeamentoMidias;
  Map<String, String>? ultimoPosterFrames;
  List<RelatorioMaterialAnexo>? ultimosMateriaisAnexos;
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
    List<RelatorioMaterialAnexo> materiaisAnexos = const [],
    String? baseUrl,
    String? codigoIdioma,
    Map<String, dynamic>? traducoesProtocolo,
  }) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }
    chamadas++;
    ultimoCaminhoSaida = caminhoSaida;
    ultimoRegistro = registro;
    ultimoMapeamentoMidias = mapeamentoMidias;
    ultimoPosterFrames = posterFrames;
    ultimosMateriaisAnexos = materiaisAnexos;
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
    void Function(Future<bool> Function(String url) tratarUrl)?
        aoRegistrarTratadorUrl,
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
          aoRegistrarTratadorUrl: aoRegistrarTratadorUrl,
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
    'Geração padrão sob demanda utiliza caminhos diretos de _thumb.jpg e _poster.jpg (sem Base64) do bundle da sessão e exporta PDF',
    (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('vis_relatorio_test_');
      try {
        final sessionManager = SessionBundleManager(
          baseDirectoryGetter: () async => tempDir,
        );
        final fakePdfService = FakePdfPrintSummaryService();
        const sessionId = 'sessao-integ-1';

        // 1. Cria a miniatura _thumb.jpg e o poster _poster.jpg no bundle da sessão
        final thumbBytes = Uint8List.fromList([10, 20, 30, 40]);
        final thumbFile = File('${tempDir.path}/sessoes/$sessionId/foto1_thumb.jpg');
        thumbFile.parent.createSync(recursive: true);
        thumbFile.writeAsBytesSync(thumbBytes);

        final posterFile = File('${tempDir.path}/sessoes/$sessionId/vid1_poster.jpg');
        posterFile.writeAsBytesSync(thumbBytes);

        // 2. Cria o arquivo XHTML e Protobuf da vistoria
        final xhtmlFile = File('${tempDir.path}/relatorios_cache/$sessionId/OEBPS/relatorio.xhtml');
        xhtmlFile.parent.createSync(recursive: true);
        xhtmlFile.writeAsStringSync('<html><body>Teste</body></html>');

        final registro = Registro()
          ..idProtocolo = 'Protocolo Teste'
          ..yamlConteudo = kYamlManutencaoVis
          ..respostas['r1'] = (Resposta()
            ..midia = (ReferenciaMidia()
              ..imagem = (ArquivoImagem()..uuid = 'foto1')))
          ..respostas['r2'] = (Resposta()
            ..midia = (ReferenciaMidia()
              ..video = (ArquivoVideo()..uuid = 'vid1')));
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

      // Verifica que o serviço padrão de impressão foi invocado com caminhos diretos sem Base64
      expect(fakePdfService.chamadas, equals(1));
      expect(fakePdfService.ultimoMapeamentoMidias, isNotNull);
      expect(
        fakePdfService.ultimoMapeamentoMidias!['foto1'],
        endsWith('foto1_thumb.jpg'),
      );
      expect(
        fakePdfService.ultimoMapeamentoMidias!['foto1']!.startsWith('data:'),
        isFalse,
      );
      expect(
        fakePdfService.ultimoPosterFrames!['vid1'],
        endsWith('vid1_poster.jpg'),
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

  testWidgets(
    'Geração padrão sob demanda inclui os relatórios dos materiais embutidos em OEBPS/materiais/<uuid>/ com fallback para .webp sem Base64',
    (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('vis_relatorio_mat_test_');
      try {
        final sessionManager = SessionBundleManager(
          baseDirectoryGetter: () async => tempDir,
        );
        final fakePdfService = FakePdfPrintSummaryService();
        const sessionId = 'sessao-manut-mat-1';
        const matUuid = 'uuid-mat-embutido';

        final xhtmlFile = File(
          '${tempDir.path}/relatorios_cache/$sessionId/OEBPS/relatorio.xhtml',
        );
        xhtmlFile.parent.createSync(recursive: true);
        xhtmlFile.writeAsStringSync('<html><body>Manutenção</body></html>');

        final registroManut = Registro()
          ..idProtocolo = 'manutencao_ferragens'
          ..yamlConteudo = kYamlManutencaoVis
          ..respostas['via_nome'] = (Resposta()..texto = 'Via Teste')
          ..respostas['lista_materiais_c'] = (Resposta()..texto = matUuid);
        final pbFile = File(
          '${tempDir.path}/relatorios_cache/$sessionId/OEBPS/dados/registro.binarypb',
        );
        pbFile.parent.createSync(recursive: true);
        pbFile.writeAsBytesSync(registroManut.writeToBuffer());

        // Cria o material embutido em OEBPS/materiais/<matUuid>/OEBPS/dados/registro.binarypb e sua foto
        final registroMat = Registro()
          ..idProtocolo = 'cadastro_material'
          ..yamlConteudo = kYamlMaterialVis
          ..respostas['mat_nome'] = (Resposta()..texto = 'Parabolt Inox Embutido')
          ..respostas['nf_foto'] = (Resposta()
            ..midia = (ReferenciaMidia()
              ..imagem = (ArquivoImagem()..uuid = 'foto-nf-1')));
        final pbMatFile = File(
          '${tempDir.path}/relatorios_cache/$sessionId/OEBPS/materiais/$matUuid/OEBPS/dados/registro.binarypb',
        );
        pbMatFile.parent.createSync(recursive: true);
        pbMatFile.writeAsBytesSync(registroMat.writeToBuffer());

        final fotoMatFile = File(
          '${tempDir.path}/relatorios_cache/$sessionId/OEBPS/materiais/$matUuid/OEBPS/midias/foto-nf-1.webp',
        );
        fotoMatFile.parent.createSync(recursive: true);
        fotoMatFile.writeAsBytesSync([11, 22, 33]);

        await tester.pumpWidget(criarTelaParaTeste(
          caminhoEpub: '${tempDir.path}/manut.epub',
          caminhoPdf: null,
          caminhoXhtml: xhtmlFile.path,
          idSessao: sessionId,
          pdfSummaryService: fakePdfService,
          sessionManager: sessionManager,
          compartilharArquivosProxy: (paths, {text, subject}) async {},
        ));

        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_compartilhar')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('opcao_compartilhar_pdf')));
        await tester.pumpAndSettle();

        expect(fakePdfService.chamadas, equals(1));
        expect(fakePdfService.ultimosMateriaisAnexos, isNotNull);
        expect(fakePdfService.ultimosMateriaisAnexos!.length, equals(1));
        expect(
          fakePdfService.ultimosMateriaisAnexos!.first.idSessao,
          equals(matUuid),
        );
        expect(
          fakePdfService
              .ultimosMateriaisAnexos!.first.registro.respostas['mat_nome']?.texto,
          equals('Parabolt Inox Embutido'),
        );
        expect(
          fakePdfService.ultimosMateriaisAnexos!.first.mapeamentoMidias['foto-nf-1'],
          endsWith('foto-nf-1.webp'),
        );
      } finally {
        try {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        } catch (_) {}
      }
    },
  );

  testWidgets(
    'Geração padrão sob demanda carrega todas as páginas de ArquivoDocumento priorizando _thumb.jpg e com fallback para .webp sem Base64',
    (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('vis_relatorio_pdf_doc_test_');
      try {
        final sessionManager = SessionBundleManager(
          baseDirectoryGetter: () async => tempDir,
        );
        final fakePdfService = FakePdfPrintSummaryService();
        const sessionId = 'sessao-doc-pdf-1';
        const matUuid = 'uuid-mat-com-pdf';

        // Páginas _p1_thumb.jpg e _p2.webp na sessão principal
        final pag1Thumb = File('${tempDir.path}/sessoes/$sessionId/doc-princ_p1_thumb.jpg');
        pag1Thumb.parent.createSync(recursive: true);
        pag1Thumb.writeAsBytesSync([1, 2, 3]);

        final pag2Main = File('${tempDir.path}/sessoes/$sessionId/doc-princ_p2.webp');
        pag2Main.writeAsBytesSync([4, 5, 6]);

        final xhtmlFile = File(
          '${tempDir.path}/relatorios_cache/$sessionId/OEBPS/relatorio.xhtml',
        );
        xhtmlFile.parent.createSync(recursive: true);
        xhtmlFile.writeAsStringSync('<html><body>Manutenção</body></html>');

        final registroManut = Registro()
          ..idProtocolo = 'manutencao_ferragens'
          ..yamlConteudo = kYamlManutencaoVis
          ..respostas['lista_materiais_c'] = (Resposta()..texto = matUuid)
          ..respostas['laudo_pdf'] = (Resposta()
            ..midia = (ReferenciaMidia()
              ..documento = (ArquivoDocumento()
                ..uuid = 'doc-princ'
                ..nomeOriginal = 'laudo.pdf'
                ..quantidadePaginas = 2)));
        final pbFile = File(
          '${tempDir.path}/relatorios_cache/$sessionId/OEBPS/dados/registro.binarypb',
        );
        pbFile.parent.createSync(recursive: true);
        pbFile.writeAsBytesSync(registroManut.writeToBuffer());

        // Material embutido com um PDF de 2 páginas em OEBPS/materiais/<matUuid>/OEBPS/midias/
        final grupoMat = GrupoRepetido()
          ..idLista = 'lista_materiais_cadastro'
          ..idItem = 'item_1'
          ..idTipo = 'chapeleta'
          ..respostasItem['mat_nota_fiscal'] = (Resposta()
            ..midia = (ReferenciaMidia()
              ..documento = (ArquivoDocumento()
                ..uuid = 'nf-mat-pdf'
                ..nomeOriginal = 'nf_chapeleta.pdf'
                ..quantidadePaginas = 2)));
        final registroMat = Registro()
          ..idProtocolo = 'cadastro_material'
          ..yamlConteudo = kYamlMaterialVis
          ..respostas['mat_nome'] = (Resposta()..texto = 'Chapeleta Inox')
          ..listas.add(grupoMat);

        final pbMatFile = File(
          '${tempDir.path}/relatorios_cache/$sessionId/OEBPS/materiais/$matUuid/OEBPS/dados/registro.binarypb',
        );
        pbMatFile.parent.createSync(recursive: true);
        pbMatFile.writeAsBytesSync(registroMat.writeToBuffer());

        final nfMatP1 = File(
          '${tempDir.path}/relatorios_cache/$sessionId/OEBPS/materiais/$matUuid/OEBPS/midias/nf-mat-pdf_p1.webp',
        );
        nfMatP1.parent.createSync(recursive: true);
        nfMatP1.writeAsBytesSync([7, 8, 9]);

        final nfMatP2 = File(
          '${tempDir.path}/relatorios_cache/$sessionId/OEBPS/materiais/$matUuid/OEBPS/midias/nf-mat-pdf_p2.webp',
        );
        nfMatP2.writeAsBytesSync([10, 11, 12]);

        await tester.pumpWidget(criarTelaParaTeste(
          caminhoEpub: '${tempDir.path}/manut.epub',
          caminhoPdf: null,
          caminhoXhtml: xhtmlFile.path,
          idSessao: sessionId,
          pdfSummaryService: fakePdfService,
          sessionManager: sessionManager,
          compartilharArquivosProxy: (paths, {text, subject}) async {},
        ));

        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_compartilhar')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('opcao_compartilhar_pdf')));
        await tester.pumpAndSettle();

        expect(fakePdfService.chamadas, equals(1));
        expect(
          fakePdfService.ultimoMapeamentoMidias!['doc-princ_p1'],
          endsWith('doc-princ_p1_thumb.jpg'),
        );
        expect(
          fakePdfService.ultimoMapeamentoMidias!['doc-princ_p2'],
          endsWith('doc-princ_p2.webp'),
        );
        expect(
          fakePdfService.ultimosMateriaisAnexos!.first.mapeamentoMidias['nf-mat-pdf_p1'],
          endsWith('nf-mat-pdf_p1.webp'),
        );
        expect(
          fakePdfService.ultimosMateriaisAnexos!.first.mapeamentoMidias['nf-mat-pdf_p2'],
          endsWith('nf-mat-pdf_p2.webp'),
        );
      } finally {
        try {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        } catch (_) {}
      }
    },
  );

  testWidgets(
    'Tratador de URL do relatório intercepta links .pdf e abre o arquivo local via abrirArquivoProxy',
    (tester) async {
      final caminhosAbertos = <String>[];
      Future<bool> Function(String url)? tratarUrl;

      await tester.pumpWidget(criarTelaParaTeste(
        caminhoXhtml: '/cache/sessao1/OEBPS/relatorio.xhtml',
        abrirArquivoProxy: (path) async {
          caminhosAbertos.add(path);
        },
        aoRegistrarTratadorUrl: (fn) {
          tratarUrl = fn;
        },
      ));

      await tester.pumpAndSettle();
      expect(tratarUrl, isNotNull);

      // URL que não é PDF deve retornar false
      final ignorado = await tratarUrl!('materiais/uuid-1/OEBPS/relatorio.xhtml');
      expect(ignorado, isFalse);
      expect(caminhosAbertos, isEmpty);

      // URL relativa de PDF dentro do EPUB extraído deve resolver e abrir
      final interceptadoRel = await tratarUrl!('midias/nota_fiscal.pdf');
      expect(interceptadoRel, isTrue);
      expect(caminhosAbertos.last, endsWith('nota_fiscal.pdf'));

      // URL file:// de PDF também deve ser resolvida e aberta
      final interceptadoFile = await tratarUrl!('file:///tmp/laudo_govbr.pdf');
      expect(interceptadoFile, isTrue);
      expect(caminhosAbertos.last, contains('laudo_govbr.pdf'));
    },
  );

  testWidgets(
    'Renderiza botão de compartilhamento e modal localizados em Inglês e Japonês sem overflow visual',
    (tester) async {
      late WidgetRef refCapturado;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeSistemaProvider.overrideWithValue(const Locale('en')),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: ResolvedorIdioma.localesSuportados,
            home: Consumer(
              builder: (context, ref, _) {
                refCapturado = ref;
                return VisualizadorRelatorioScreen(
                  caminhoEpub: '/meu/laudo.epub',
                  caminhoPdf: '/meu/laudo.pdf',
                  caminhoXhtml: '/cache/relatorio.xhtml',
                  webViewBuilder: (context, path) => const SizedBox.shrink(),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('SHARE'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_compartilhar')));
      await tester.pumpAndSettle();
      expect(find.text('EPUB 3 REPORT'), findsOneWidget);
      expect(find.text('PDF SUMMARY'), findsOneWidget);
      Navigator.of(tester.element(find.text('EPUB 3 REPORT'))).pop();
      await tester.pumpAndSettle();

      await refCapturado
          .read(idiomaAtivoProvider.notifier)
          .selecionarIdioma('ja');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('共有'), findsOneWidget);
    },
  );

  testWidgets(
    'Compartilha link público web https://fixalog.app/v/<idSessao> pelo modal de compartilhamento',
    (tester) async {
      String? textoCompartilhado;
      String? assuntoCompartilhado;

      await tester.pumpWidget(
        criarTelaParaTeste(
          caminhoEpub: '/meu/laudo.epub',
          caminhoPdf: '/meu/laudo.pdf',
          caminhoXhtml: '/cache/relatorio.xhtml',
          idSessao: 'sessao_web_99',
          compartilharArquivosProxy: (paths, {text, subject}) async {
            textoCompartilhado = text;
            assuntoCompartilhado = subject;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_compartilhar')));
      await tester.pumpAndSettle();

      final opcaoLink = find.byKey(const Key('opcao_compartilhar_link_web'));
      expect(opcaoLink, findsOneWidget);
      await tester.tap(opcaoLink);
      await tester.pumpAndSettle();

      expect(
        textoCompartilhado,
        equals('https://fixalog.app/v/sessao_web_99'),
      );
      expect(assuntoCompartilhado, isNotNull);
    },
  );
}
