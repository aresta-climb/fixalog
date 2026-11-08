// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/features/media/services/media_compressor_service.dart';
import 'package:fixalog/features/media/services/seletor_documento_service.dart';
import 'package:fixalog/features/media/services/servico_galeria_dispositivo.dart';
import 'package:fixalog/features/wizard/views/wizard_screen.dart';
import 'package:fixalog/features/wizard/controllers/wizard_state_controller.dart';
import 'package:fixalog/core/models/proto/protos/wizard.pb.dart';
import '../../../fakes/servico_galeria_dispositivo_fake.dart';

void main() {
  const testYaml = '''
id: "test_protocol"
nome: "Protocolo de Teste"
versao: "1.0.0"
blocos:
  - id: "b1"
    nome: "Bloco Inicial"
    steps:
      - id: "s1"
        nome: "Passo 1"
        conteudos:
          - id: "c1"
            tipo_componente: "CAMPO_SIMPLES"
            campo_simples:
              label: "Tipo de Chapeleta"
              tipo: "TEXT"
              obrigatorio: true
''';

  group('WizardScreen Widget Tests', () {
    testWidgets('renderiza o cabeçalho e campo de texto do protocolo YAML', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: testYaml),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('FIXALOG'), findsOneWidget);
      expect(find.text('Tipo de Chapeleta'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('botão de avanço habilita após preencher campo obrigatório', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: testYaml),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final nextButtonFinder = find.widgetWithText(
        ElevatedButton,
        'CONCLUIR',
      );
      expect(nextButtonFinder, findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Bonier Inox');
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(nextButtonFinder);
      final color = button.style?.backgroundColor?.resolve({});
      expect(color, equals(const Color(0xFFFF6B00)));
    });

    testWidgets('ao clicar em ADICIONAR MÍDIA em campo VIDEO exibe modal unificado de Foto, Vídeo, Galeria e PDF', (tester) async {
      const videoYaml = '''
id: "video_protocol"
nome: "Protocolo Vídeo"
versao: 1
blocos:
  - id: "b1"
    nome: "Bloco 1"
    steps:
      - id: "s1"
        nome: "Passo 1"
        conteudos:
          - id: "v1"
            tipo_componente: "CAMPO_SIMPLES"
            campo_simples:
              label: "Vídeo de Inspeção"
              tipo: "VIDEO"
              obrigatorio: true
''';
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: videoYaml),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('GRAVAR VÍDEO'), findsNothing);
      final mediaButtonFinder = find.text('ADICIONAR MÍDIA');
      expect(mediaButtonFinder, findsOneWidget);
      expect(find.text('Fotos, vídeos ou PDFs'), findsOneWidget);

      await tester.tap(mediaButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('ADICIONAR MÍDIA (FOTO, VÍDEO OU PDF)'), findsOneWidget);
      expect(find.text('Gravar com a Câmera'), findsOneWidget);
      expect(find.text('Escolher da Galeria'), findsOneWidget);
      expect(find.text('Escolher da Galeria / Arquivos'), findsNothing);

      await tester.tap(find.text('Escolher da Galeria'));
      await tester.pumpAndSettle();
      expect(find.text('ADICIONAR MÍDIA (FOTO, VÍDEO OU PDF)'), findsNothing);
    });

    testWidgets('ao clicar em ADICIONAR MÍDIA em campo IMAGE exibe modal unificado de Foto, Vídeo, Galeria e PDF', (tester) async {
      const fotoYaml = '''
id: "foto_protocol"
nome: "Protocolo Foto"
versao: 1
blocos:
  - id: "b1"
    nome: "Bloco 1"
    steps:
      - id: "s1"
        nome: "Passo 1"
        conteudos:
          - id: "f1"
            tipo_componente: "CAMPO_SIMPLES"
            campo_simples:
              label: "Foto de Inspeção"
              tipo: "IMAGE"
              obrigatorio: true
''';
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: fotoYaml),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ABRIR CÂMERA'), findsNothing);
      final fotoButtonFinder = find.text('ADICIONAR MÍDIA');
      expect(fotoButtonFinder, findsOneWidget);
      expect(find.text('Fotos, vídeos ou PDFs'), findsOneWidget);

      await tester.tap(fotoButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('ADICIONAR MÍDIA (FOTO, VÍDEO OU PDF)'), findsOneWidget);
      expect(find.text('Tirar Foto com a Câmera'), findsOneWidget);
      expect(find.text('Escolher da Galeria'), findsOneWidget);

      await tester.tap(find.text('Escolher da Galeria'));
      await tester.pumpAndSettle();
      expect(find.text('ADICIONAR MÍDIA (FOTO, VÍDEO OU PDF)'), findsNothing);
    });

    testWidgets('exibe campo DATE pré-preenchido com a data atual e permite edição pelo usuário', (tester) async {
      const dataYaml = '''
id: "data_protocol"
nome: "Protocolo Data"
versao: "1.0.0"
blocos:
  - id: "b1"
    titulo: "Bloco 1"
    steps:
      - id: "s1"
        conteudos:
          - id: "mat_data"
            campo_simples:
              label: "Data de Cadastro"
              tipo: "DATE"
              obrigatorio: true
              preencher_data_atual: true
''';
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: dataYaml),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final hoje = DateTime.now();
      final esperado =
          '${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';

      expect(find.text(esperado), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '10/05/2025');
      await tester.pumpAndSettle();

      expect(find.text('10/05/2025'), findsOneWidget);
    });

    testWidgets('renderiza StepListaAcoes aninhada dentro de outra StepListaAcoes e confirma itens', (tester) async {
      const yamlAninhado = '''
id: "aninhado_proto"
nome: "Protocolo Aninhado"
versao: "1.0.0"
blocos:
  - id: "b1"
    titulo: "Materiais"
    steps:
      - id: "s1"
        lista_acoes:
          label: "Materiais do Conjunto"
          minimo: 1
          tipos_disponiveis:
            - id: "parabolt"
              label: "Chumbador Parabolt"
              steps:
                - id: "pb_s1"
                  conteudos:
                    - id: "pb_marca"
                      campo_simples:
                        label: "Marca do Parabolt"
                        tipo: "TEXT"
                        obrigatorio: true
                    - id: "sub_detalhes"
                      lista_acoes:
                        label: "Detalhes de Fabricação"
                        minimo: 1
                        tipos_disponiveis:
                          - id: "etapa_fab"
                            label: "Etapa de Fabricação"
                            steps:
                              - id: "ef_s1"
                                campo_simples:
                                  label: "Descrição da Etapa"
                                  tipo: "TEXT"
                                  obrigatorio: true
''';
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: yamlAninhado),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clica em ADICIONAR ITEM na lista principal
      await tester.tap(find.text('ADICIONAR ITEM'));
      await tester.pumpAndSettle();

      // Seleciona "Chumbador Parabolt" no bottom sheet
      await tester.tap(find.text('Chumbador Parabolt'));
      await tester.pumpAndSettle();

      // Verifica que a sub-lista "Detalhes de Fabricação" foi renderizada inline dentro do item pai
      expect(find.text('Marca do Parabolt'), findsOneWidget);
      expect(find.text('Detalhes de Fabricação'), findsOneWidget);

      // Clica no botão ADICIONAR ITEM da sub-lista
      await tester.tap(find.text('ADICIONAR ITEM'));
      await tester.pumpAndSettle();

      // Seleciona "Etapa de Fabricação" no bottom sheet
      await tester.tap(find.text('Etapa de Fabricação'));
      await tester.pumpAndSettle();

      expect(find.text('Descrição da Etapa'), findsOneWidget);
    });

    testWidgets('abrirSessaoIsolada abre segundo WizardScreen empilhado sem corromper o estado da sessão pai', (tester) async {
      const yamlPai = '''
id: "manutencao_pai"
nome: "Manutenção Pai"
versao: "1.0.0"
blocos:
  - id: "b1"
    titulo: "Bloco Pai"
    steps:
      - id: "s1"
        campo_simples:
          label: "Nome da Via Pai"
          tipo: "TEXT"
          obrigatorio: true
''';

      const yamlFilho = '''
id: "cadastro_material"
nome: "Cadastro de Material Filho"
versao: "1.0.0"
blocos:
  - id: "b1"
    titulo: "Bloco Filho"
    steps:
      - id: "s_mat"
        campo_simples:
          label: "Nome do Material Filho"
          tipo: "TEXT"
          obrigatorio: true
''';

      final containerPai = ProviderContainer();
      addTearDown(containerPai.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: containerPai,
          child: const MaterialApp(
            home: WizardScreen(initialYaml: yamlPai),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Preenche o campo na sessão pai
      await tester.enterText(find.byType(TextFormField), 'Via Paredão Sul');
      await tester.pumpAndSettle();

      final sessionIdPai = containerPai.read(wizardControllerProvider).sessionId;
      expect(containerPai.read(wizardControllerProvider).answers['s1']?.texto, equals('Via Paredão Sul'));

      // Abre o segundo WizardScreen isolado empilhado sobre o primeiro
      final ctx = tester.element(find.byType(WizardScreen));
      WizardScreen.abrirSessaoIsolada(ctx, initialYaml: yamlFilho);
      await tester.pumpAndSettle();

      // Estamos agora no WizardScreen filho
      expect(find.text('Nome do Material Filho'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Chapeleta Inox 316L');
      await tester.pumpAndSettle();

      // Volta do WizardScreen filho para o pai
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verifica que a sessão pai permaneceu intacta
      expect(containerPai.read(wizardControllerProvider).protocol?.id, equals('manutencao_pai'));
      expect(containerPai.read(wizardControllerProvider).sessionId, equals(sessionIdPai));
      expect(containerPai.read(wizardControllerProvider).answers['s1']?.texto, equals('Via Paredão Sul'));
      expect(find.text('Nome da Via Pai'), findsOneWidget);
    });

    testWidgets('RefMateriaisWidget com origem_catalogo exibe botão CADASTRAR NOVO MATERIAL e abre cadastro isolado', (tester) async {
      const yamlComCatalogo = '''
id: "manutencao_catalogo"
nome: "Manutenção com Catálogo"
versao: "1.0.0"
blocos:
  - id: "b1"
    titulo: "Materiais"
    steps:
      - id: "s1"
        conteudos:
          - id: "lista_materiais_c"
            ref_materiais:
              label: "Materiais a instalar"
              origem_catalogo: true
              obrigatorio: true
''';

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WizardScreen(initialYaml: yamlComCatalogo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica que o botão CADASTRAR NOVO MATERIAL é exibido
      final btnCadastrar = find.text('CADASTRAR NOVO MATERIAL');
      expect(btnCadastrar, findsOneWidget);

      // Toca em CADASTRAR NOVO MATERIAL -> abre o WizardScreen de cadastro_material.yaml
      await tester.tap(btnCadastrar);
      await tester.pumpAndSettle();

      expect(find.text('Nome do Material ou Conjunto'), findsOneWidget);

      // Simula retorno com o ID do material recém-cadastrado
      final childCtx = tester.element(find.text('Nome do Material ou Conjunto'));
      Navigator.of(childCtx).pop('mat-novo-uuid');
      await tester.pumpAndSettle();

      // Verifica que o material retornado foi auto-selecionado no passo lista_materiais_c da manutenção pai
      expect(
        container.read(wizardControllerProvider).refSelections['lista_materiais_c'],
        contains('mat-novo-uuid'),
      );
    });

    testWidgets('RefMateriais inline dentro de uma ação (ref_mat_*) exibe CADASTRAR NOVO MATERIAL e vincula o material criado ao item da ação', (tester) async {
      const yamlAcaoComMaterial = '''
id: "manutencao_acao_catalogo"
nome: "Manutenção Ação Direta"
versao: 2
blocos:
  - id: "acoes"
    titulo: "Ações"
    steps:
      - id: "lista_acoes"
        conteudos:
          - id: "lista_acoes_c"
            lista_acoes:
              label: "Ações realizadas"
              minimo: 1
              tipos_disponiveis:
                - id: "novo_ponto"
                  label: "Adição de Novo Ponto"
                  icon_name: "add_location_alt"
                  steps:
                    - id: "np_detalhes"
                      conteudos:
                        - id: "ref_mat_novo_ponto"
                          ref_materiais:
                            label: "Materiais instalados"
                            origem_catalogo: true
                            obrigatorio: true
''';

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WizardScreen(initialYaml: yamlAcaoComMaterial),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADICIONAR ITEM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adição de Novo Ponto'));
      await tester.pumpAndSettle();

      final itemId = container
          .read(wizardControllerProvider)
          .lists['lista_acoes_c']!
          .first
          .id;

      final btnCadastrar = find.text('CADASTRAR NOVO MATERIAL');
      expect(btnCadastrar, findsOneWidget);
      await tester.ensureVisible(btnCadastrar);
      await tester.pumpAndSettle();

      await tester.tap(btnCadastrar);
      await tester.pumpAndSettle();

      expect(find.text('Nome do Material ou Conjunto'), findsOneWidget);
      final childCtx = tester.element(find.text('Nome do Material ou Conjunto'));
      Navigator.of(childCtx).pop('mat-acao-uuid');
      await tester.pumpAndSettle();

      expect(
        container
            .read(wizardControllerProvider)
            .refSelections['ref_mat_novo_ponto__$itemId'],
        contains('mat-acao-uuid'),
      );
    });

    testWidgets('BottomSheet de seleção de tipo permite rolar sem overflow e selecionar a 6ª opção Outro', (tester) async {
      final yamlCadastroMat = File('assets/protocols/cadastro_material.yaml').readAsStringSync();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: WizardScreen(initialYaml: yamlCadastroMat),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Preenche o nome no Bloco 1 e avança para o Bloco 2
      await tester.enterText(find.byType(TextFormField).first, 'Barra Inox 316');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('SEGUINTE'));
      await tester.tap(find.text('SEGUINTE'));
      await tester.pumpAndSettle();

      // Abre o modal de seleção de tipo (que contém 6 opções)
      await tester.ensureVisible(find.text('ADICIONAR ITEM'));
      await tester.tap(find.text('ADICIONAR ITEM'));
      await tester.pumpAndSettle();

      // Rola até a 6ª opção ('Outro') e toca nela
      final opcaoOutro = find.text('Outro');
      await tester.ensureVisible(opcaoOutro);
      await tester.pumpAndSettle();
      await tester.tap(opcaoOutro);
      await tester.pumpAndSettle();

      // Verifica que o item do tipo 'outro' foi adicionado e expandido sem overflow
      expect(
        find.text('Material Customizado ou Fabricação Própria'),
        findsOneWidget,
      );
    });

    testWidgets('permite selecionar arquivo PDF no modal de comprovante e exibe confirmação visual com contagem de páginas', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('wizard_pdf_test_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      const nfYaml = '''
id: "nf_protocol"
nome: "Protocolo Nota Fiscal"
versao: "1.0.0"
blocos:
  - id: "b1"
    titulo: "Bloco 1"
    steps:
      - id: "s1"
        conteudos:
          - id: "pb_nf_foto"
            campo_simples:
              label: "Foto ou PDF da Nota Fiscal / Comprovante"
              tipo: "IMAGE"
              obrigatorio: true
''';

      final container = ProviderContainer(
        overrides: [
          sessionBundleManagerProvider.overrideWithValue(
            SessionBundleManager(baseDirectoryGetter: () async => tempDir),
          ),
          mediaCompressorProvider.overrideWithValue(
            MediaCompressorService(
              rasterizadorPdf: (pdfBytes, {double dpi = 150.0}) async => [
                Uint8List.fromList([137, 80, 78, 71, 1]),
                Uint8List.fromList([137, 80, 78, 71, 2]),
              ],
            ),
          ),
          seletorDocumentoServiceProvider.overrideWithValue(
            SeletorDocumentoService(
              seletorCustomizado: () async => DocumentoSelecionado(
                nome: 'danfe_chumbador.pdf',
                bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WizardScreen(initialYaml: nfYaml),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADICIONAR MÍDIA'));
      await tester.pumpAndSettle();

      expect(find.text('Tirar Foto com a Câmera'), findsOneWidget);
      expect(find.text('Escolher da Galeria'), findsOneWidget);
      expect(find.text('Selecionar Arquivo PDF'), findsOneWidget);

      await tester.tap(find.text('Selecionar Arquivo PDF'));
      await tester.pumpAndSettle();

      expect(find.text('PDF ANEXADO'), findsOneWidget);
      expect(find.text('danfe_chumbador.pdf (2 pág.)'), findsOneWidget);
    });

    testWidgets('Modal de seleção de modo respeita o espaço dos botões de navegação do SO (viewPadding/systemGestureInsets)', (tester) async {
      final yamlCadastro = File('assets/protocols/cadastro_material.yaml').readAsStringSync();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  padding: EdgeInsets.zero,
                  viewPadding: const EdgeInsets.only(bottom: 48.0),
                  systemGestureInsets: const EdgeInsets.only(bottom: 48.0),
                ),
                child: child!,
              );
            },
            home: WizardScreen(initialYaml: yamlCadastro),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Lote Teste');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('SEGUINTE'));
      await tester.tap(find.text('SEGUINTE'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('ADICIONAR ITEM'));
      await tester.tap(find.text('ADICIONAR ITEM'));
      await tester.pumpAndSettle();

      final scrollRect = tester.getRect(find.byKey(const Key('scroll_selecao_tipo')));
      final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final folgaInferior = screenHeight - scrollRect.bottom;

      // Deve preservar os 24px de padding próprio + 48px da barra de botões do SO (>= 72px)
      expect(folgaInferior, greaterThanOrEqualTo(72.0));
    });

    testWidgets('Ao selecionar modo para abrir nova sub-seção com campo de texto focado no topo, o scroll não volta para o alto e foca na nova seção', (tester) async {
      tester.view.physicalSize = const Size(412, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final yamlCadastro = File('assets/protocols/cadastro_material.yaml').readAsStringSync();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: yamlCadastro),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Conjunto Parabolt');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('SEGUINTE'));
      await tester.tap(find.text('SEGUINTE'));
      await tester.pumpAndSettle();

      // Abre o primeiro material ('Chumbador Mecânico / Parabolt')
      await tester.ensureVisible(find.text('ADICIONAR ITEM'));
      await tester.tap(find.text('ADICIONAR ITEM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chumbador Mecânico / Parabolt'));
      await tester.pumpAndSettle();

      // Digita no campo de texto no topo do material ('Marca / Fabricante'), mantendo-o com foco!
      final campoMarca = find.byType(TextFormField).at(3);
      await tester.tap(campoMarca);
      await tester.enterText(campoMarca, 'Petzl Coeur');
      await tester.pumpAndSettle();

      // Rola manualmente a tela principal lá para baixo até o botão de adicionar Detalhe / Etapa de Fabricação
      final todosBotoesAdicionar = find.text('ADICIONAR ITEM');
      await tester.ensureVisible(todosBotoesAdicionar.last);
      await tester.pumpAndSettle();

      final mainScrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
      final offsetAntesDoModal = mainScrollable.position.pixels;
      expect(offsetAntesDoModal, greaterThan(250.0));

      // Clica em ADICIONAR ITEM na sub-lista lá de baixo e seleciona o modo no modal
      await tester.tap(todosBotoesAdicionar.last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Detalhe / Etapa de Fabricação'));
      await tester.pumpAndSettle();

      // O scroll NÃO pode ter voltado lá para o alto (onde estava o campo Marca focado)!
      final offsetDepoisDoModal = mainScrollable.position.pixels;
      expect(offsetDepoisDoModal, greaterThan(250.0));

      // E o campo da nova sub-seção que abriu ('Título do Detalhe ou Etapa') deve estar visível na tela (dentro de [0, 700])
      final rectNovaSubsecao = tester.getRect(find.text('Título do Detalhe ou Etapa'));
      expect(rectNovaSubsecao.top, greaterThanOrEqualTo(0.0));
      expect(rectNovaSubsecao.bottom, lessThanOrEqualTo(700.0));
    });

    testWidgets('Ao clicar em modo de selecao_ramo inline que abre sub-seção, rola até a sub-seção nova em vez de voltar ao topo', (tester) async {
      tester.view.physicalSize = const Size(412, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const ramoInlineYaml = '''
id: "ramo_inline_test"
nome: "Teste Ramo Inline"
versao: "1.0.0"
blocos:
  - id: "b1"
    titulo: "Bloco 1"
    steps:
      - id: "s1"
        conteudos:
          - id: "campo_topo"
            campo_simples:
              label: "Nome no Topo"
              tipo: "TEXT"
              obrigatorio: true
      - id: "s2"
        conteudos:
          - id: "lista_acoes_c"
            lista_acoes:
              label: "Ações realizadas"
              minimo: 1
              maximo: 0
              tipos_disponiveis:
                - id: "inspecao"
                  label: "Inspeção de Ancoragem"
                  icon_name: "search"
                  steps:
                    - id: "ia_step"
                      conteudos:
                        - id: "ia_obs_inicial"
                          campo_simples:
                            label: "Observação Inicial"
                            tipo: "TEXT"
                        - id: "ia_espacador_1"
                          instrucao:
                            titulo: "Instrução Longa 1"
                            corpo: "Texto longo para empurrar o seletor de modo para baixo na tela."
                            nivel_alerta: "INFO"
                        - id: "ia_espacador_2"
                          instrucao:
                            titulo: "Instrução Longa 2"
                            corpo: "Mais instruções técnicas detalhadas antes da escolha do modo."
                            nivel_alerta: "ATENCAO"
                        - id: "ia_resultado"
                          selecao_ramo:
                            label: "Resultado da avaliação"
                            obrigatorio: true
                            ramos:
                              - id: "substituir"
                                label: "Substituição necessária"
                                sublabel: "Ancoragem com dano estrutural"
                                icon_name: "swap_horiz"
                                steps:
                                  - id: "sub_step"
                                    conteudos:
                                      - id: "justificativa_sub"
                                        campo_simples:
                                          label: "Justificativa da Substituição"
                                          tipo: "TEXT"
                                          obrigatorio: true
''';

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: ramoInlineYaml),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Preenche o Passo 1 deixando foco no TextFormField do topo e avança
      await tester.enterText(find.byType(TextFormField).first, 'Via Teste');
      await tester.pumpAndSettle();
      await tester.tap(find.text('SEGUINTE'));
      await tester.pumpAndSettle();

      // Abre o modal de adicionar ação e seleciona 'Inspeção de Ancoragem'
      await tester.tap(find.text('ADICIONAR ITEM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inspeção de Ancoragem'));
      await tester.pumpAndSettle();

      // Foca no campo 'Observação Inicial' no topo do card da ação
      final campoObs = find.byType(TextFormField).last;
      await tester.tap(campoObs);
      await tester.enterText(campoObs, 'Oxidação superficial');
      await tester.pumpAndSettle();

      // Rola até a opção de ramo 'Substituição necessária' e toca nela
      final opcaoSubstituir = find.text('Substituição necessária');
      await tester.ensureVisible(opcaoSubstituir);
      await tester.pumpAndSettle();
      await tester.tap(opcaoSubstituir);
      await tester.pumpAndSettle();

      // Verifica que a nova sub-seção ('Justificativa da Substituição') abriu e está visível na tela
      final rectSub = tester.getRect(find.text('Justificativa da Substituição'));
      expect(rectSub.top, greaterThanOrEqualTo(0.0));
      expect(rectSub.bottom, lessThanOrEqualTo(700.0));
    });

    testWidgets('Campo de mídia permite anexar múltiplas mídias (fotos, vídeos e PDFs) na mesma etapa e remover individualmente', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('wizard_multi_media_test_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      const etapaYaml = '''
id: "etapa_multi_midia"
nome: "Protocolo Multi Mídia"
versao: "1.0.0"
blocos:
  - id: "b1"
    titulo: "Bloco 1"
    steps:
      - id: "s1"
        conteudos:
          - id: "det_foto"
            campo_simples:
              label: "Mídias da Etapa (Fotos, Vídeos ou PDFs)"
              tipo: "IMAGE"
              obrigatorio: false
''';

      int contadorPdfs = 0;
      final container = ProviderContainer(
        overrides: [
          sessionBundleManagerProvider.overrideWithValue(
            SessionBundleManager(baseDirectoryGetter: () async => tempDir),
          ),
          mediaCompressorProvider.overrideWithValue(
            MediaCompressorService(
              rasterizadorPdf: (pdfBytes, {double dpi = 150.0}) async => [
                Uint8List.fromList([137, 80, 78, 71, 1]),
              ],
            ),
          ),
          seletorDocumentoServiceProvider.overrideWithValue(
            SeletorDocumentoService(
              seletorCustomizado: () async {
                contadorPdfs++;
                return DocumentoSelecionado(
                  nome: 'laudo_$contadorPdfs.pdf',
                  bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, contadorPdfs]),
                );
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WizardScreen(initialYaml: etapaYaml),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre o modal de mídia e verifica que oferece opções de Foto, Vídeo e PDF simultaneamente
      await tester.tap(find.text('ADICIONAR MÍDIA'));
      await tester.pumpAndSettle();

      expect(find.text('Tirar Foto com a Câmera'), findsOneWidget);
      expect(find.text('Gravar com a Câmera'), findsOneWidget);
      expect(find.text('Escolher da Galeria'), findsOneWidget);
      expect(find.text('Escolher da Galeria / Arquivos'), findsNothing);
      expect(find.text('Selecionar Arquivo PDF'), findsOneWidget);

      // Seleciona o 1º PDF
      await tester.tap(find.text('Selecionar Arquivo PDF'));
      await tester.pumpAndSettle();

      expect(find.text('PDF ANEXADO'), findsOneWidget);
      expect(find.text('laudo_1.pdf (1 pág.)'), findsOneWidget);
      // O botão ADICIONAR MÍDIA continua visível para adicionar mais mídias na mesma etapa
      expect(find.text('ADICIONAR MÍDIA'), findsOneWidget);

      // Anexa também 1 foto e 1 vídeo via controller e mais 1 PDF pela UI
      final notifier = container.read(wizardControllerProvider.notifier);
      await notifier.saveMediaAnswerBytes(
        'det_foto',
        Uint8List.fromList([1, 2, 3]),
        '.jpg',
        StepCampoSimples_TipoCampo.IMAGE,
      );
      await notifier.saveMediaAnswerBytes(
        'det_foto',
        Uint8List.fromList([4, 5, 6]),
        '.mp4',
        StepCampoSimples_TipoCampo.VIDEO,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADICIONAR MÍDIA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecionar Arquivo PDF'));
      await tester.pumpAndSettle();

      // Agora temos 4 mídias exibidas na mesma etapa: 2 PDFs, 1 foto e 1 vídeo
      expect(find.text('PDF ANEXADO'), findsNWidgets(2));
      expect(find.text('laudo_1.pdf (1 pág.)'), findsOneWidget);
      expect(find.text('laudo_2.pdf (1 pág.)'), findsOneWidget);
      expect(find.text('FOTO CAPTURADA'), findsOneWidget);
      expect(find.text('VÍDEO GRAVADO'), findsOneWidget);

      // Remove a primeira mídia (laudo_1.pdf) clicando no botão de remover
      await tester.tap(find.byKey(const Key('btn_remover_midia_det_foto_0')));
      await tester.pumpAndSettle();

      expect(find.text('laudo_1.pdf (1 pág.)'), findsNothing);
      expect(find.text('FOTO CAPTURADA'), findsOneWidget);
      expect(find.text('VÍDEO GRAVADO'), findsOneWidget);
      expect(find.text('laudo_2.pdf (1 pág.)'), findsOneWidget);
    });

    testWidgets('Exibe indicador de loading imediato enquanto mídias estão sendo processadas no background e oculta ao concluir', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('wizard_loading_midia_test_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      const etapaYaml = '''
id: "etapa_loading_midia"
nome: "Protocolo Loading Mídia"
versao: "1.0.0"
blocos:
  - id: "b1"
    titulo: "Bloco 1"
    steps:
      - id: "s1"
        conteudos:
          - id: "det_foto"
            campo_simples:
              label: "Anexar Mídias à Etapa / Detalhe"
              tipo: "IMAGE"
              obrigatorio: false
''';

      final completerRaster = Completer<List<Uint8List>>();
      final container = ProviderContainer(
        overrides: [
          sessionBundleManagerProvider.overrideWithValue(
            SessionBundleManager(baseDirectoryGetter: () async => tempDir),
          ),
          mediaCompressorProvider.overrideWithValue(
            MediaCompressorService(
              rasterizadorPdf: (pdfBytes, {double dpi = 150.0}) => completerRaster.future,
            ),
          ),
          seletorDocumentoServiceProvider.overrideWithValue(
            SeletorDocumentoService(
              seletorCustomizado: () async => DocumentoSelecionado(
                nome: 'laudo_pesado.pdf',
                bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 1]),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WizardScreen(initialYaml: etapaYaml),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADICIONAR MÍDIA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecionar Arquivo PDF'));
      // Avança um frame para fechar o modal e iniciar o processamento em background
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verifica que o indicador de loading está visível enquanto processa em segundo plano
      expect(find.byKey(const Key('loading_midia_det_foto')), findsOneWidget);
      expect(find.textContaining('PROCESSANDO'), findsOneWidget);

      // Conclui o processamento em background
      completerRaster.complete([
        Uint8List.fromList([137, 80, 78, 71, 1]),
      ]);
      await tester.pumpAndSettle();

      // O indicador de loading desaparece e a mídia aparece anexada
      expect(find.byKey(const Key('loading_midia_det_foto')), findsNothing);
      expect(find.text('laudo_pesado.pdf (1 pág.)'), findsOneWidget);
    });

    testWidgets('Ao fechar um detalhe clicando em CONFIRMAR ITEM no final de uma seção longa, o scroll volta para onde estão os detalhes', (tester) async {
      tester.view.physicalSize = const Size(400, 650);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const detalheLongoYaml = '''
id: "protocolo_detalhe_longo"
nome: "Protocolo Detalhe Longo"
versao: "1.0.0"
blocos:
  - id: "b1"
    titulo: "Bloco Principal"
    steps:
      - id: "s1"
        conteudos:
          - id: "etapa_detalhes"
            lista_acoes:
              label: "Detalhes da Etapa"
              sublabel: "Adicione cada detalhe executado"
              minimo: 0
              maximo: 10
              tipos_disponiveis:
                - id: "detalhe_padrao"
                  label: "Detalhe de Execução"
                  sublabel: "Registro detalhado"
                  icon_name: "build"
                  steps:
                    - id: "det_step"
                      conteudos:
                        - id: "c1"
                          campo_simples:
                            label: "Campo Detalhe 1"
                            tipo: "TEXT"
                            obrigatorio: true
                        - id: "c2"
                          campo_simples:
                            label: "Campo Detalhe 2"
                            tipo: "TEXT"
                            obrigatorio: false
                        - id: "c3"
                          campo_simples:
                            label: "Campo Detalhe 3"
                            tipo: "TEXT"
                            obrigatorio: false
                        - id: "c4"
                          campo_simples:
                            label: "Campo Detalhe 4"
                            tipo: "TEXT"
                            obrigatorio: false
                        - id: "c5"
                          campo_simples:
                            label: "Campo Detalhe 5"
                            tipo: "TEXT"
                            obrigatorio: false
                        - id: "c6"
                          campo_simples:
                            label: "Campo Detalhe 6"
                            tipo: "TEXT"
                            obrigatorio: false
          - id: "rodape_1"
            campo_simples:
              label: "Observação Geral 1"
              tipo: "TEXT"
              obrigatorio: false
          - id: "rodape_2"
            campo_simples:
              label: "Observação Geral 2"
              tipo: "TEXT"
              obrigatorio: false
          - id: "rodape_3"
            campo_simples:
              label: "Observação Geral 3"
              tipo: "TEXT"
              obrigatorio: false
          - id: "rodape_4"
            campo_simples:
              label: "Observação Geral 4"
              tipo: "TEXT"
              obrigatorio: false
          - id: "rodape_5"
            campo_simples:
              label: "Observação Geral 5"
              tipo: "TEXT"
              obrigatorio: false
          - id: "rodape_6"
            campo_simples:
              label: "Observação Geral 6"
              tipo: "TEXT"
              obrigatorio: false
''';

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardScreen(initialYaml: detalheLongoYaml),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre o modal e adiciona o detalhe
      await tester.tap(find.text('ADICIONAR ITEM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Detalhe de Execução'));
      await tester.pumpAndSettle();

      // Preenche o Campo Detalhe 1 (obrigatório)
      await tester.enterText(find.byType(TextFormField).first, 'Solda TIG');
      await tester.pumpAndSettle();

      // Rola até o final do detalhe onde fica o botão CONFIRMAR ITEM
      final btnConfirmar = find.text('CONFIRMAR ITEM');
      await tester.ensureVisible(btnConfirmar);
      await tester.pumpAndSettle();

      // Clica em CONFIRMAR ITEM para fechar o detalhe
      await tester.tap(btnConfirmar);
      await tester.pumpAndSettle();

      // O card colapsado ('Detalhe de Execução') e o botão 'ADICIONAR OUTRO' devem estar visíveis na tela
      final rectDetalhe = tester.getRect(find.text('Detalhe de Execução'));
      expect(rectDetalhe.top, greaterThanOrEqualTo(0.0));
      expect(rectDetalhe.bottom, lessThanOrEqualTo(650.0));
    });

    testWidgets('Exibe botão CONCLUIR no último passo após confirmar os itens obrigatórios dos passos anteriores e avança direto para o card de conclusão sem assinatura na tela', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('wizard_conclusao_test_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      const protocoloYaml = '''
id: "protocolo_conclusao"
nome: "Protocolo Conclusão Direta"
versao: "1.0.0"
blocos:
  - id: "b1"
    titulo: "Bloco 1"
    steps:
      - id: "s1"
        conteudos:
          - id: "mat_nome"
            campo_simples:
              label: "Nome do Material"
              tipo: "TEXT"
              obrigatorio: true
  - id: "b2"
    titulo: "Bloco 2"
    steps:
      - id: "s2"
        conteudos:
          - id: "lista_itens"
            lista_acoes:
              label: "Materiais"
              minimo: 1
              maximo: 0
              tipos_disponiveis:
                - id: "parabolt"
                  label: "Parabolt"
                  icon_name: "hardware"
                  steps:
                    - id: "pb_s1"
                      conteudos:
                        - id: "pb_marca"
                          campo_simples:
                            label: "Marca"
                            tipo: "TEXT"
                            obrigatorio: true
  - id: "b3"
    titulo: "Bloco 3"
    steps:
      - id: "s3"
        conteudos:
          - id: "obs_finais"
            campo_simples:
              label: "Observações finais"
              tipo: "TEXT"
              obrigatorio: false
''';

      final container = ProviderContainer(
        overrides: [
          sessionBundleManagerProvider.overrideWithValue(
            SessionBundleManager(baseDirectoryGetter: () async => tempDir),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WizardScreen(initialYaml: protocoloYaml),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Passo 1: preenche o Nome do Material e avança
      await tester.enterText(find.byType(TextFormField).first, 'Chapeleta Inox');
      await tester.pumpAndSettle();
      await tester.tap(find.text('SEGUINTE'));
      await tester.pumpAndSettle();

      // Passo 2: adiciona e confirma o item obrigatório e avança para o último passo
      await tester.tap(find.text('ADICIONAR ITEM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parabolt'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Bonier');
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONFIRMAR ITEM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONCLUIR LISTA (1)'));
      await tester.pumpAndSettle();

      // No último passo, o botão deve exibir 'CONCLUIR' (sem modal de assinatura)
      expect(find.text('ASSINAR E CONCLUIR'), findsNothing);
      final btnConcluir = find.text('CONCLUIR');
      expect(btnConcluir, findsOneWidget);

      await tester.ensureVisible(btnConcluir);
      await tester.pumpAndSettle();
      await tester.tap(btnConcluir);
      await tester.pumpAndSettle();

      // Avança diretamente para o card de conclusão sem abrir modal de assinatura
      expect(find.text('ASSINATURA DIGITAL'), findsNothing);
      expect(find.text('PROTOCOLO CONCLUÍDO'), findsOneWidget);
    });

    testWidgets('Campo TEXT_AREA suporta linhas em branco com Enter sem fechar teclado e aplica estilo Markdown in-place preservando o texto escrito', (tester) async {
      const markdownYaml = '''
id: "protocolo_markdown"
nome: "Protocolo Markdown"
versao: "1.0.0"
blocos:
  - id: "b1"
    titulo: "Bloco 1"
    steps:
      - id: "s1"
        conteudos:
          - id: "det_descricao"
            campo_simples:
              label: "Descrição Detalhada"
              tipo: "TEXT"
              ui_hint: "TEXT_AREA"
              obrigatorio: true
''';

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WizardScreen(initialYaml: markdownYaml),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.keyboardType, equals(TextInputType.multiline));
      expect(textField.textInputAction, equals(TextInputAction.newline));
      expect(textField.maxLines, isNull);
      expect(textField.minLines, greaterThanOrEqualTo(4));

      const textoComMarkdown = '# Solda\n\nUsado **inox 316L** e *argônio* com `TIG-01`';
      await tester.enterText(textFieldFinder, textoComMarkdown);
      await tester.pumpAndSettle();

      // O texto bruto não deve ser alterado (mantém **, *, `, # e linhas em branco)
      expect(textField.controller?.text, equals(textoComMarkdown));
      final respostaSalva = container.read(wizardControllerProvider).answers['det_descricao']?.texto;
      expect(respostaSalva, equals(textoComMarkdown));

      // E o buildTextSpan do controller deve aplicar estilos visuais aos trechos Markdown
      final Element elemento = tester.element(textFieldFinder);
      final spanRaiz = textField.controller!.buildTextSpan(
        context: elemento,
        style: const TextStyle(fontSize: 14),
        withComposing: false,
      );
      expect(spanRaiz.toPlainText(), equals(textoComMarkdown));

      final filhos = <TextSpan>[];
      void coletarSpans(InlineSpan s) {
        if (s is TextSpan) {
          if (s.text != null && s.text!.isNotEmpty) {
            filhos.add(s);
          }
          if (s.children != null) {
            for (final c in s.children!) {
              coletarSpans(c);
            }
          }
        }
      }
      coletarSpans(spanRaiz);

      expect(
        filhos.any((s) => s.text!.contains('inox 316L') && s.style?.fontWeight == FontWeight.bold),
        isTrue,
      );
      expect(
        filhos.any((s) => s.text!.contains('argônio') && s.style?.fontStyle == FontStyle.italic),
        isTrue,
      );
      expect(
        filhos.any((s) => s.text!.contains('TIG-01') && s.style?.fontFamily == 'monospace'),
        isTrue,
      );
    });

    testWidgets('Salva fotos e vídeos capturados pela câmera no rolo da câmera sem duplicar mídias da galeria e tolera falha de permissão', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('wizard_camera_roll_test_');
      const canalImagePicker = MethodChannel('plugins.flutter.io/image_picker');
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(canalImagePicker, null);
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      final arqFotoCamera = File('${tempDir.path}/foto_camera_1.jpg')
        ..writeAsBytesSync([1, 2, 3, 4]);
      final arqVideoCamera = File('${tempDir.path}/video_camera_1.mp4')
        ..writeAsBytesSync([5, 6, 7, 8]);
      final arqFotoGaleria = File('${tempDir.path}/foto_galeria_1.jpg')
        ..writeAsBytesSync([9, 10, 11]);
      final arqFotoCameraSemPermissao = File('${tempDir.path}/foto_camera_2.jpg')
        ..writeAsBytesSync([12, 13, 14]);

      String proximaFotoCamera = arqFotoCamera.path;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canalImagePicker, (call) async {
        if (call.method == 'pickImage') {
          return proximaFotoCamera;
        }
        if (call.method == 'pickVideo') {
          return arqVideoCamera.path;
        }
        if (call.method == 'pickMultiImage' || call.method == 'pickMedia') {
          return <String>[arqFotoGaleria.path];
        }
        return null;
      });

      const midiaYaml = '''
id: "protocolo_camera_galeria"
nome: "Protocolo Câmera Galeria"
versao: "1.0.0"
blocos:
  - id: "b1"
    titulo: "Bloco 1"
    steps:
      - id: "s1"
        conteudos:
          - id: "f_midia"
            campo_simples:
              label: "Evidências Fotográficas e de Vídeo"
              tipo: "IMAGE"
              obrigatorio: false
''';

      final galeriaFake = ServicoGaleriaDispositivoFake();
      final container = ProviderContainer(
        overrides: [
          sessionBundleManagerProvider.overrideWithValue(
            SessionBundleManager(baseDirectoryGetter: () async => tempDir),
          ),
          servicoGaleriaDispositivoProvider.overrideWithValue(galeriaFake),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WizardScreen(initialYaml: midiaYaml),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Captura foto com a câmera -> salva na sessão E no rolo da câmera
      await tester.tap(find.text('ADICIONAR MÍDIA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tirar Foto com a Câmera'));
      await tester.pumpAndSettle();

      expect(find.text('FOTO CAPTURADA'), findsOneWidget);
      expect(galeriaFake.fotosSalvas, equals([arqFotoCamera.path]));
      expect(galeriaFake.videosSalvos, isEmpty);

      // 2. Grava vídeo com a câmera -> salva na sessão E no rolo da câmera
      await tester.tap(find.text('ADICIONAR MÍDIA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gravar com a Câmera'));
      await tester.pumpAndSettle();

      expect(find.text('VÍDEO GRAVADO'), findsOneWidget);
      expect(galeriaFake.videosSalvos, equals([arqVideoCamera.path]));

      // 3. Escolhe mídia existente da galeria -> anexa na sessão SEM duplicar no rolo da câmera
      await tester.tap(find.text('ADICIONAR MÍDIA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escolher da Galeria'));
      await tester.pumpAndSettle();

      expect(find.text('FOTO CAPTURADA'), findsNWidgets(2));
      expect(galeriaFake.fotosSalvas, equals([arqFotoCamera.path]));
      expect(galeriaFake.videosSalvos, equals([arqVideoCamera.path]));

      // 4. Se o salvamento no rolo da câmera falhar (ex: permissão negada), a foto ainda é salva na sessão normalmente
      galeriaFake.simularFalha = true;
      proximaFotoCamera = arqFotoCameraSemPermissao.path;

      await tester.tap(find.text('ADICIONAR MÍDIA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tirar Foto com a Câmera'));
      await tester.pumpAndSettle();

      expect(find.text('FOTO CAPTURADA'), findsNWidgets(3));
    });
  });
}
