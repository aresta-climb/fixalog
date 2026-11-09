// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/epub_extrator_service.dart';
import 'package:fixalog/core/services/sincronizador_nuvem_service.dart';
import 'package:fixalog/features/pdf_generation/views/visualizador_relatorio_screen.dart';
import 'package:path/path.dart' as p;
import '../../../fakes/crypto_service_fake.dart';
import '../../../core/services/autenticacao_nuvem_service_fake.dart';
import '../../../core/services/sincronizador_nuvem_service_fake.dart';

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

Uint8List _criarEpubAssinadoTeste() {
  final archive = Archive();
  final xhtml = utf8.encode(
    '<html><head><title>Manutenção de Ferragens</title></head>'
    '<body><h1>Manutenção de Ferragens</h1><h2>Via Paredão Sul</h2>'
    '<p>Mantenedor: Escalador Teste (FEMERJ)</p></body></html>',
  );
  archive.addFile(ArchiveFile('OEBPS/relatorio.xhtml', xhtml.length, xhtml));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AutenticacaoNuvemServiceFake auth;
  late ClienteHttpFixalogNuvemFake clienteHttp;
  late SincronizadorNuvemService sincronizador;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('vis_relatorio_test_');
    auth = AutenticacaoNuvemServiceFake(crypto: CryptoServiceFake());
    await auth.entrarComProvedorOidc(ProvedorOidc.google);
    clienteHttp = ClienteHttpFixalogNuvemFake();
    sincronizador = SincronizadorNuvemService(
      banco: null,
      autenticacaoService: auth,
      clienteHttp: clienteHttp,
      intervaloPollingModeracao: const Duration(milliseconds: 20),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget criarTelaParaTeste({
    Key? key,
    String? caminhoEpub,
    String? caminhoXhtml,
    String? idSessao,
    String titulo = 'Via Paredão Sul',
    EpubExtratorService? extratorService,
    SincronizadorNuvemService? sincronizadorOverride,
    Future<void> Function(List<String> paths, {String? text, String? subject})?
        compartilharArquivosProxy,
    Future<void> Function(String path)? abrirArquivoProxy,
    void Function(Future<bool> Function(String url) tratarUrl)?
        aoRegistrarTratadorUrl,
    Widget Function(BuildContext context, String caminhoXhtml)? webViewBuilder,
  }) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        sincronizadorNuvemServiceProvider.overrideWithValue(
          sincronizadorOverride ?? sincronizador,
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(splashFactory: InkRipple.splashFactory),
        home: VisualizadorRelatorioScreen(
          key: key,
          caminhoEpub: caminhoEpub,
          caminhoXhtml: caminhoXhtml,
          idSessao: idSessao,
          titulo: titulo,
          extratorService: extratorService,
          sincronizadorNuvem: sincronizadorOverride,
          compartilharArquivosProxy: compartilharArquivosProxy,
          abrirArquivoProxy: abrirArquivoProxy,
          aoRegistrarTratadorUrl: aoRegistrarTratadorUrl,
          webViewBuilder:
              webViewBuilder ??
              (context, path) => Container(
                key: const Key('fake_webview'),
                child: Text('WebView carregando: $path'),
              ),
        ),
      ),
    );
  }

  testWidgets(
    'Exibe indicador de carregamento, carrega via WebView e não expõe nenhuma opção local de PDF',
    (tester) async {
      final fakeExtrator = FakeEpubExtratorService(
        caminhoRetorno: '/tmp/relatorio.xhtml',
      );

      await tester.pumpWidget(
        criarTelaParaTeste(
          caminhoEpub: '/documentos/relatorio.epub',
          extratorService: fakeExtrator,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Carregando relatório...'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fake_webview')), findsOneWidget);
      expect(
        find.text('WebView carregando: /tmp/relatorio.xhtml'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('opcao_compartilhar_pdf')), findsNothing);
    },
  );

  testWidgets(
    'Exibe modal de progresso em 2 etapas, bloqueia compartilhamento durante em_analise e libera link rico quando ativo',
    (tester) async {
      final epubFile = File(p.join(tempDir.path, 'sessao_1.epub'))
        ..writeAsBytesSync(_criarEpubAssinadoTeste());

      // Configura atraso no envio de chunk e 2 consultas em_analise para inspecionar Etapa 1 e Etapa 2
      clienteHttp.atrasoEnvioChunk = const Duration(milliseconds: 15);
      clienteHttp.consultasEmAnaliseAntesDeAtivar['sessao_1'] = 2;

      String? textoCompartilhado;
      String? assuntoCompartilhado;

      await tester.pumpWidget(
        criarTelaParaTeste(
          caminhoEpub: epubFile.path,
          caminhoXhtml: '/cache/relatorio.xhtml',
          idSessao: 'sessao_1',
          titulo: 'Via Paredão Sul',
          compartilharArquivosProxy: (paths, {text, subject}) async {
            textoCompartilhado = text;
            assuntoCompartilhado = subject;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_compartilhar')));
      await tester.pump();

      // Etapa 1: enviando blocos (ícone de upload ativo)
      expect(
        find.byKey(const Key('modal_progresso_upload_laudo')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);

      // Avança para Etapa 2: verificando no servidor
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(
        find.textContaining('Enviando blocos do laudo'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Verificando integridade e mídias no servidor'),
        findsOneWidget,
      );
      expect(textoCompartilhado, isNull);

      // Aguarda concluir o polling até status_moderacao == 'ativo'
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(
        find.byKey(const Key('modal_progresso_upload_laudo')),
        findsNothing,
      );
      expect(textoCompartilhado, isNotNull);
      expect(textoCompartilhado, contains('Manutenção de Ferragens'));
      expect(textoCompartilhado, contains('Via Paredão Sul'));
      expect(
        textoCompartilhado,
        contains('https://fixalog.app/v/sessao_1'),
      );
      expect(assuntoCompartilhado, equals('Via Paredão Sul'));
    },
  );

  testWidgets(
    'Exibe aviso claro quando sem internet e permite exportar EPUB local ou fechar sem liberar link quebrado',
    (tester) async {
      final epubFile = File(p.join(tempDir.path, 'offline.epub'))
        ..writeAsBytesSync(_criarEpubAssinadoTeste());
      clienteHttp.deveLancarErroRede = true;

      String? textoCompartilhado;
      List<String>? arquivosCompartilhados;

      await tester.pumpWidget(
        criarTelaParaTeste(
          caminhoEpub: epubFile.path,
          caminhoXhtml: '/cache/relatorio.xhtml',
          idSessao: 'sessao_offline',
          compartilharArquivosProxy: (paths, {text, subject}) async {
            arquivosCompartilhados = paths;
            textoCompartilhado = text;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_appbar_compartilhar')));
      await tester.pumpAndSettle();

      // Aviso de falta de internet visível e nenhum link compartilhado
      expect(
        find.textContaining('necessária conexão com a internet'),
        findsOneWidget,
      );
      expect(textoCompartilhado, isNull);

      // Fecha o modal de aviso offline
      await tester.tap(find.byKey(const Key('btn_fechar_modal_upload')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('modal_progresso_upload_laudo')),
        findsNothing,
      );

      // Exporta o pacote .epub assinado pelo botão da AppBar
      await tester.tap(find.byKey(const Key('btn_appbar_exportar_epub')));
      await tester.pumpAndSettle();
      expect(arquivosCompartilhados, equals([epubFile.path]));
    },
  );

  testWidgets(
    'Exibe erro de verificação quando o laudo é rejeitado pela moderação no servidor',
    (tester) async {
      final epubFile = File(p.join(tempDir.path, 'rejeitado.epub'))
        ..writeAsBytesSync(_criarEpubAssinadoTeste());
      clienteHttp.statusModeracaoForcadoPorSessao['rejeitado'] = 'rejeitado';

      await tester.pumpWidget(
        criarTelaParaTeste(
          caminhoEpub: epubFile.path,
          caminhoXhtml: '/cache/relatorio.xhtml',
          idSessao: null,
          compartilharArquivosProxy: (paths, {text, subject}) async {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_compartilhar')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('modal_progresso_upload_laudo')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('btn_fechar_modal_upload')));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Trata erros de extração, ausência de caminhos, abertura externa, clique em URL PDF e localização',
    (tester) async {
      // 1. Ausência de caminhoEpub e caminhoXhtml
      await tester.pumpWidget(
        criarTelaParaTeste(
          key: const Key('v_sem_caminho'),
          caminhoEpub: null,
          caminhoXhtml: null,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // 2. Falha de extração e tentar novamente
      final fakeExtrator = FakeEpubExtratorService(deveFalhar: true);
      await tester.pumpWidget(
        criarTelaParaTeste(
          key: const Key('v_falha_ext'),
          caminhoEpub: '/doc/corrompido.epub',
          extratorService: fakeExtrator,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tentar novamente'), findsOneWidget);
      fakeExtrator.deveFalhar = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fake_webview')), findsOneWidget);

      // 3. Abertura externa e interceptação de URL .pdf
      final abertos = <String>[];
      Future<bool> Function(String url)? tratarUrl;
      await tester.pumpWidget(
        criarTelaParaTeste(
          key: const Key('v_urls'),
          caminhoEpub: '/meu/laudo.epub',
          caminhoXhtml: '/cache/s1/OEBPS/relatorio.xhtml',
          idSessao: 's1',
          abrirArquivoProxy: (path) async => abertos.add(path),
          aoRegistrarTratadorUrl: (fn) => tratarUrl = fn,
          compartilharArquivosProxy: (paths, {text, subject}) async {
            throw Exception('Falha share simulada');
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_abrir_externo')));
      await tester.pump();
      expect(abertos.last, equals('/meu/laudo.epub'));

      expect(await tratarUrl!('materiais/u1/relatorio.xhtml'), isFalse);
      expect(await tratarUrl!('midias/nf.pdf'), isTrue);
      expect(await tratarUrl!('file:///tmp/nf2.pdf'), isTrue);

      // Erro ao exportar EPUB e ao compartilhar link exibe SnackBar
      await tester.tap(find.byKey(const Key('btn_appbar_exportar_epub')));
      await tester.pump();
      expect(find.textContaining('Erro ao compartilhar EPUB'), findsOneWidget);

      clienteHttp.epubsPublicosPorSessao['s1'] = _criarEpubAssinadoTeste();
      await tester.tap(find.byKey(const Key('btn_appbar_compartilhar')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.textContaining('Erro ao compartilhar link web'),
        findsOneWidget,
      );

      // Erro ao abrir externamente
      await tester.pumpWidget(
        criarTelaParaTeste(
          key: const Key('v_erro_abrir'),
          caminhoEpub: '/meu/laudo.epub',
          caminhoXhtml: '/cache/s1/OEBPS/relatorio.xhtml',
          abrirArquivoProxy: (path) async {
            throw Exception('Falha abrir externo');
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_appbar_abrir_externo')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.textContaining('Erro ao abrir aplicativo externo'),
        findsOneWidget,
      );

      // 4. Localização em Inglês e Japonês sem overflow
      late WidgetRef refCapturado;
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
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
                  key: const Key('v_i18n'),
                  caminhoEpub: '/meu/laudo.epub',
                  caminhoXhtml: '/cache/relatorio.xhtml',
                  webViewBuilder: (context, path) => const SizedBox.shrink(),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SHARE'), findsOneWidget);

      await refCapturado
          .read(idiomaAtivoProvider.notifier)
          .selecionarIdioma('ja');
      await tester.pumpAndSettle();
      expect(find.text('共有'), findsOneWidget);

      // Exercita implementações estáticas padrão sem acionar processos do SO
      final executorShareOriginal = VisualizadorRelatorioScreen.executorSharePlus;
      final executorOpenOriginal = VisualizadorRelatorioScreen.executorOpenFilex;
      VisualizadorRelatorioScreen.executorSharePlus = (_) async => null;
      VisualizadorRelatorioScreen.executorOpenFilex = (_) async => null;
      await VisualizadorRelatorioScreen.compartilharPadrao(
        const ['/tmp/a.epub'],
        text: 't',
        subject: 's',
      );
      await VisualizadorRelatorioScreen.compartilharPadrao(
        const [],
        text: 't',
      );
      await VisualizadorRelatorioScreen.abrirArquivoPadrao('/tmp/a.epub');
      VisualizadorRelatorioScreen.executorSharePlus = executorShareOriginal;
      VisualizadorRelatorioScreen.executorOpenFilex = executorOpenOriginal;
      expect(
        () => VisualizadorRelatorioScreen.construirWebViewPadrao(
          tester.element(find.byType(VisualizadorRelatorioScreen)),
          '/cache/relatorio.xhtml',
        ),
        throwsA(anything),
      );
    },
  );
}
