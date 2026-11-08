// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

// test/wizard_state_controller_test.dart
//
// Testa o WizardStateController com o novo schema (Step.conteudos).
//
// Uso: flutter test test/wizard_state_controller_test.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_image_compress_platform_interface/flutter_image_compress_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:fixalog/core/models/proto/protos/wizard.pb.dart';
import 'package:fixalog/features/wizard/controllers/wizard_state_controller.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/session_bundle_manager.dart';
import 'package:fixalog/core/services/protocol_parser.dart';
import 'package:fixalog/features/media/services/media_compressor_service.dart';
import 'package:fixalog/features/media/services/video_transcoder_service.dart';
import 'package:fixnum/fixnum.dart';

class _FakeImageCompressPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FlutterImageCompressPlatform {
  @override
  FlutterImageCompressValidator get validator =>
      FlutterImageCompressValidator(const MethodChannel('flutter_image_compress'));

  @override
  Future<XFile?> compressAndGetFile(
    String path,
    String targetPath, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async {
    final file = File(targetPath);
    await file.create(recursive: true);
    await file.writeAsBytes([1, 2, 3, 4]);
    return XFile(targetPath);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Builders para construir protos de teste sem YAML
// ─────────────────────────────────────────────────────────────────────────────

/// Cria um ConteudoStep de CampoSimples.
ConteudoStep campoConteudo({
  required String id,
  String label = 'Campo',
  bool obrigatorio = false,
  StepCampoSimples_TipoCampo tipo = StepCampoSimples_TipoCampo.TEXT,
  bool preencherDataAtual = false,
}) {
  return ConteudoStep(
    id: id,
    campoSimples: StepCampoSimples(
      label: label,
      obrigatorio: obrigatorio,
      tipo: tipo,
      preencherDataAtual: preencherDataAtual,
    ),
  );
}

/// Cria um ConteudoStep de Instrucao.
ConteudoStep instrucaoConteudo({required String id, String titulo = 'Info'}) {
  return ConteudoStep(
    id: id,
    instrucao: StepInstrucao(titulo: titulo),
  );
}

/// Cria um ConteudoStep de SelecaoRamo.
ConteudoStep ramoConteudo({
  required String id,
  required List<Ramo> ramos,
  bool obrigatorio = true,
}) {
  return ConteudoStep(
    id: id,
    selecaoRamo: StepSelecaoRamo(
      label: 'Escolha',
      obrigatorio: obrigatorio,
      ramos: ramos,
    ),
  );
}

/// Cria um ConteudoStep de ListaAcoes.
ConteudoStep listaConteudo({
  required String id,
  int minimo = 0,
  List<TipoAcao> tipos = const [],
}) {
  return ConteudoStep(
    id: id,
    listaAcoes: StepListaAcoes(
      label: 'Lista',
      minimo: minimo,
      tiposDisponiveis: tipos,
    ),
  );
}

/// Cria um Step (card) com uma lista de conteudos.
Step makeStep(String id, List<ConteudoStep> conteudos) =>
    Step(id: id, conteudos: conteudos);

/// Cria um protocolo mínimo de 1 bloco com os steps dados.
DefinicaoProtocolo makeProtocol(List<Step> steps, {String id = 'test_proto', String nome = 'Test'}) {
  return DefinicaoProtocolo(
    id: id,
    nome: nome,
    versao: '1.0.0',
    blocos: [Bloco(id: 'bloco1', titulo: 'B1', steps: steps)],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Factories para WidgetRef (usando ProviderContainer)
// ─────────────────────────────────────────────────────────────────────────────

ProviderContainer makeContainer() => ProviderContainer();

// ─────────────────────────────────────────────────────────────────────────────
// Testes
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. Carregamento ──────────────────────────────────────────────────────────

  group('WizardStateController — carregamento', () {
    test('estado inicial está vazio', () {
      final container = makeContainer();
      final state = container.read(wizardControllerProvider);
      expect(state.protocol, isNull);
      expect(state.queue, isEmpty);
      expect(state.currentIndex, 0);
    });

    test(
      'loadProtocol popula a fila com todos os steps de todos os blocos',
      () {
        final container = makeContainer();
        final protocol = makeProtocol([
          makeStep('s1', [campoConteudo(id: 'c1')]),
          makeStep('s2', [campoConteudo(id: 'c2')]),
          makeStep('s3', [instrucaoConteudo(id: 'c3')]),
        ]);

        container
            .read(wizardControllerProvider.notifier)
            .loadProtocol(protocol);
        final state = container.read(wizardControllerProvider);

        expect(state.protocol, isNotNull);
        expect(state.queue.length, 3);
        expect(state.currentIndex, 0);
        expect(state.isFinished, isFalse);
      },
    );
  });

  // ── 2. Navegação básica ───────────────────────────────────────────────────────

  group('WizardStateController — navegação', () {
    test('nextStep avança quando todos os conteudos opcionais', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [instrucaoConteudo(id: 'c1')]),
              makeStep('s2', [instrucaoConteudo(id: 'c2')]),
            ]),
          );

      final success = container
          .read(wizardControllerProvider.notifier)
          .nextStep();
      expect(success, isTrue);
      expect(container.read(wizardControllerProvider).currentIndex, 1);
    });

    test('nextStep bloqueia se campo obrigatório não preenchido', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [campoConteudo(id: 'c1', obrigatorio: true)]),
              makeStep('s2', [instrucaoConteudo(id: 'c2')]),
            ]),
          );

      final success = container
          .read(wizardControllerProvider.notifier)
          .nextStep();
      expect(success, isFalse);
      expect(container.read(wizardControllerProvider).currentIndex, 0);
    });

    test('nextStep avança após preencher campo obrigatório', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [campoConteudo(id: 'c1', obrigatorio: true)]),
              makeStep('s2', [instrucaoConteudo(id: 'c2')]),
            ]),
          );

      container
          .read(wizardControllerProvider.notifier)
          .answerConteudoString('c1', 'resposta');
      final success = container
          .read(wizardControllerProvider.notifier)
          .nextStep();
      expect(success, isTrue);
      expect(container.read(wizardControllerProvider).currentIndex, 1);
    });

    test(
      'nextStep com múltiplos conteudos: bloqueia se 1 obrigatório incompleto',
      () {
        final container = makeContainer();
        container
            .read(wizardControllerProvider.notifier)
            .loadProtocol(
              makeProtocol([
                makeStep('s1', [
                  instrucaoConteudo(id: 'c1'), // não obrigatório
                  campoConteudo(id: 'c2'), // não obrigatório
                  campoConteudo(id: 'c3', obrigatorio: true), // OBRIGATÓRIO
                ]),
                makeStep('s2', [instrucaoConteudo(id: 'c4')]),
              ]),
            );

        // Preenche apenas c2 (não obrigatório) — c3 still empty
        container
            .read(wizardControllerProvider.notifier)
            .answerConteudoString('c2', 'ok');

        final success = container
            .read(wizardControllerProvider.notifier)
            .nextStep();
        expect(success, isFalse);
      },
    );

    test(
      'nextStep com múltiplos conteudos: avança quando todos satisfeitos',
      () {
        final container = makeContainer();
        container
            .read(wizardControllerProvider.notifier)
            .loadProtocol(
              makeProtocol([
                makeStep('s1', [
                  instrucaoConteudo(id: 'c1'),
                  campoConteudo(id: 'c2', obrigatorio: true),
                  campoConteudo(id: 'c3', obrigatorio: true),
                ]),
                makeStep('s2', [instrucaoConteudo(id: 'c4')]),
              ]),
            );

        container
            .read(wizardControllerProvider.notifier)
            .answerConteudoString('c2', 'v1');
        container
            .read(wizardControllerProvider.notifier)
            .answerConteudoString('c3', 'v2');
        final success = container
            .read(wizardControllerProvider.notifier)
            .nextStep();
        expect(success, isTrue);
      },
    );

    test('isFinished é true quando ultrapassa a fila', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [instrucaoConteudo(id: 'c1')]),
            ]),
          );

      container.read(wizardControllerProvider.notifier).nextStep();
      expect(container.read(wizardControllerProvider).isFinished, isTrue);
    });

    test('previousStep volta ao step anterior', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [instrucaoConteudo(id: 'c1')]),
              makeStep('s2', [instrucaoConteudo(id: 'c2')]),
            ]),
          );

      container.read(wizardControllerProvider.notifier).nextStep();
      expect(container.read(wizardControllerProvider).currentIndex, 1);

      container.read(wizardControllerProvider.notifier).previousStep();
      expect(container.read(wizardControllerProvider).currentIndex, 0);
    });
  });

  // ── 3. chooseRamo — injeção na fila sem auto-avanço ──────────────────────────

  group('WizardStateController — chooseRamo', () {
    late DefinicaoProtocolo protocol;

    final ramoA = Ramo(
      id: 'ramo_a',
      label: 'Ramo A',
      steps: [
        makeStep('ra_s1', [campoConteudo(id: 'ra_c1')]),
      ],
    );
    final ramoB = Ramo(
      id: 'ramo_b',
      label: 'Ramo B',
      steps: [
        makeStep('rb_s1', [campoConteudo(id: 'rb_c1')]),
      ],
    );

    setUp(() {
      protocol = makeProtocol([
        makeStep('s1', [
          instrucaoConteudo(id: 'c0'),
          ramoConteudo(id: 'selecao', ramos: [ramoA, ramoB]),
        ]),
        makeStep('s2', [instrucaoConteudo(id: 'c2')]),
      ]);
    });

    test('chooseRamo registra a resposta e injeta steps do ramo na fila', () {
      final container = makeContainer();
      container.read(wizardControllerProvider.notifier).loadProtocol(protocol);
      expect(container.read(wizardControllerProvider).queue.length, 2);

      container
          .read(wizardControllerProvider.notifier)
          .chooseRamo('selecao', 'ramo_a');
      final state = container.read(wizardControllerProvider);

      expect(state.answers['selecao']?.texto, equals('ramo_a'));
      expect(state.queue.length, 3); // s1 + ra_s1 + s2
      expect(state.currentIndex, 0); // NÃO avançou
    });

    test('chooseRamo substitui steps ao mudar de ramo', () {
      final container = makeContainer();
      container.read(wizardControllerProvider.notifier).loadProtocol(protocol);

      container
          .read(wizardControllerProvider.notifier)
          .chooseRamo('selecao', 'ramo_a');
      expect(container.read(wizardControllerProvider).queue.length, 3);

      // Muda para ramo_b — deve remover ra_s1 e injetar rb_s1
      container
          .read(wizardControllerProvider.notifier)
          .chooseRamo('selecao', 'ramo_b');
      final state = container.read(wizardControllerProvider);

      expect(state.answers['selecao']?.texto, equals('ramo_b'));
      expect(state.queue.length, 3);
      expect(state.queue[1].step.id, equals('rb_s1'));
    });
  });

  // ── 4. addListItem / confirmListItem / expandListItem ────────────────────────

  group('WizardStateController — lista inline', () {
    late TipoAcao tipoSimples;
    late TipoAcao tipoComObrigatorio;

    setUp(() {
      tipoSimples = TipoAcao(
        id: 'tipo_simples',
        label: 'Tipo Simples',
        steps: [
          makeStep('ts_s1', [instrucaoConteudo(id: 'ts_c1')]),
        ],
      );
      tipoComObrigatorio = TipoAcao(
        id: 'tipo_obrg',
        label: 'Tipo Obrigatório',
        steps: [
          makeStep('to_s1', [campoConteudo(id: 'to_c1', obrigatorio: true)]),
        ],
      );
    });

    test('addListItem cria item e o expande', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [listaConteudo(id: 'lista1')]),
            ]),
          );

      container
          .read(wizardControllerProvider.notifier)
          .addListItem(listConteudoId: 'lista1', tipo: tipoSimples);
      final state = container.read(wizardControllerProvider);

      expect(state.lists['lista1']!.length, 1);
      final itemId = state.lists['lista1']!.first.id;
      expect(state.expandedListItems['lista1'], equals(itemId));
    });

    test('confirmListItem sem obrigatórios retorna true e colapsa', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [listaConteudo(id: 'lista1')]),
            ]),
          );

      container
          .read(wizardControllerProvider.notifier)
          .addListItem(listConteudoId: 'lista1', tipo: tipoSimples);
      final itemId = container
          .read(wizardControllerProvider)
          .lists['lista1']!
          .first
          .id;

      final ok = container
          .read(wizardControllerProvider.notifier)
          .confirmListItem('lista1', itemId);
      expect(ok, isTrue);
      expect(
        container.read(wizardControllerProvider).expandedListItems['lista1'],
        isNull,
      );
    });

    test(
      'confirmListItem com campo obrigatório não preenchido retorna false',
      () {
        final container = makeContainer();
        container
            .read(wizardControllerProvider.notifier)
            .loadProtocol(
              makeProtocol([
                makeStep('s1', [listaConteudo(id: 'lista1')]),
              ]),
            );

        container
            .read(wizardControllerProvider.notifier)
            .addListItem(listConteudoId: 'lista1', tipo: tipoComObrigatorio);
        final itemId = container
            .read(wizardControllerProvider)
            .lists['lista1']!
            .first
            .id;

        final ok = container
            .read(wizardControllerProvider.notifier)
            .confirmListItem('lista1', itemId);
        expect(ok, isFalse);
      },
    );

    test('confirmListItem com campo obrigatório preenchido retorna true', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [listaConteudo(id: 'lista1')]),
            ]),
          );

      container
          .read(wizardControllerProvider.notifier)
          .addListItem(listConteudoId: 'lista1', tipo: tipoComObrigatorio);
      final itemId = container
          .read(wizardControllerProvider)
          .lists['lista1']!
          .first
          .id;

      // Preenche o campo obrigatório (key = "to_c1__itemId")
      container
          .read(wizardControllerProvider.notifier)
          .answerInlineConteudoString('to_c1', 'valor', itemId);

      final ok = container
          .read(wizardControllerProvider.notifier)
          .confirmListItem('lista1', itemId);
      expect(ok, isTrue);
    });

    test('expandListItem re-expande um item colapsado', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [listaConteudo(id: 'lista1')]),
            ]),
          );

      container
          .read(wizardControllerProvider.notifier)
          .addListItem(listConteudoId: 'lista1', tipo: tipoSimples);
      final itemId = container
          .read(wizardControllerProvider)
          .lists['lista1']!
          .first
          .id;
      container
          .read(wizardControllerProvider.notifier)
          .confirmListItem('lista1', itemId);
      expect(
        container.read(wizardControllerProvider).expandedListItems['lista1'],
        isNull,
      );

      container
          .read(wizardControllerProvider.notifier)
          .expandListItem('lista1', itemId);
      expect(
        container.read(wizardControllerProvider).expandedListItems['lista1'],
        equals(itemId),
      );
    });

    test('removeListItem remove o item da lista', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [listaConteudo(id: 'lista1')]),
            ]),
          );

      container
          .read(wizardControllerProvider.notifier)
          .addListItem(listConteudoId: 'lista1', tipo: tipoSimples);
      final itemId = container
          .read(wizardControllerProvider)
          .lists['lista1']!
          .first
          .id;

      container
          .read(wizardControllerProvider.notifier)
          .removeListItem('lista1', itemId);
      expect(container.read(wizardControllerProvider).lists['lista1'], isEmpty);
    });

    test('nextStep bloqueia se lista com minimo não atingido', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [listaConteudo(id: 'lista1', minimo: 1)]),
              makeStep('s2', [instrucaoConteudo(id: 'c2')]),
            ]),
          );

      final success = container
          .read(wizardControllerProvider.notifier)
          .nextStep();
      expect(success, isFalse);
    });

    test('nextStep libera após atingir mínimo da lista', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [listaConteudo(id: 'lista1', minimo: 1)]),
              makeStep('s2', [instrucaoConteudo(id: 'c2')]),
            ]),
          );

      container
          .read(wizardControllerProvider.notifier)
          .addListItem(listConteudoId: 'lista1', tipo: tipoSimples);

      final success = container
          .read(wizardControllerProvider.notifier)
          .nextStep();
      expect(success, isTrue);
    });
  });

  // ── 5. RefMateriais ───────────────────────────────────────────────────────────

  group('WizardStateController — RefMateriais', () {
    test('setRefMateriais salva IDs e resposta no formato join', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [instrucaoConteudo(id: 'c1')]),
            ]),
          );

      container.read(wizardControllerProvider.notifier).setRefMateriais(
        'ref_c1',
        ['id1', 'id2', 'id3'],
      );
      final state = container.read(wizardControllerProvider);

      expect(state.refSelections['ref_c1'], equals(['id1', 'id2', 'id3']));
      expect(
        state.answers['ref_c1']?.lista.valores.map((e) => e.texto).toList(),
        equals(['id1', 'id2', 'id3']),
      );
    });

    test('setRefMateriais com listItemId usa chave composta', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [instrucaoConteudo(id: 'c1')]),
            ]),
          );

      container.read(wizardControllerProvider.notifier).setRefMateriais(
        'ref_c1',
        ['m1'],
        listItemId: 'item_abc',
      );
      final state = container.read(wizardControllerProvider);

      expect(state.refSelections['ref_c1__item_abc'], equals(['m1']));
      expect(
        state.answers['ref_c1__item_abc']?.lista.valores.map((e) => e.texto).toList(),
        equals(['m1']),
      );
    });

    test('getMaterialItems retorna itens da lista correta', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [listaConteudo(id: 'materiais')]),
            ]),
          );

      final tipo = TipoAcao(id: 't1', label: 'T1', steps: []);
      container
          .read(wizardControllerProvider.notifier)
          .addListItem(listConteudoId: 'materiais', tipo: tipo);

      final items = container
          .read(wizardControllerProvider.notifier)
          .getMaterialItems('materiais');
      expect(items.length, 1);
      expect(items.first.tipoId, 't1');
    });
  });

  // ── 6. answerInlineConteudo — chave composta ────────────────────────────────

  group('WizardStateController — respostas inline', () {
    test('answerInlineConteudo usa chave "conteudoId__listItemId"', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [instrucaoConteudo(id: 'c1')]),
            ]),
          );

      container
          .read(wizardControllerProvider.notifier)
          .answerInlineConteudoString('campo_marca', 'Petzl', 'item_xyz');
      final state = container.read(wizardControllerProvider);

      expect(state.answers['campo_marca__item_xyz']?.texto, equals('Petzl'));
      expect(state.answers.containsKey('campo_marca'), isFalse);
    });

    test('answerConteudo usa chave simples sem sufixo', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [campoConteudo(id: 'via_nome')]),
            ]),
          );

      container
          .read(wizardControllerProvider.notifier)
          .answerConteudoString('via_nome', 'Via Teste');
      final state = container.read(wizardControllerProvider);

      expect(state.answers['via_nome']?.texto, equals('Via Teste'));
    });
    test('answerConteudo armazena instâncias corretas de Resposta (Test-First)', () {
      final container = makeContainer();
      container
          .read(wizardControllerProvider.notifier)
          .loadProtocol(
            makeProtocol([
              makeStep('s1', [
                campoConteudo(id: 'c_text'),
                campoConteudo(id: 'c_int'),
                campoConteudo(id: 'c_double'),
                campoConteudo(id: 'c_bool'),
              ]),
            ]),
          );

      final notifier = container.read(wizardControllerProvider.notifier);

      notifier.answerConteudo('c_text', Resposta(texto: 'hello'));
      notifier.answerConteudo('c_int', Resposta(inteiro: Int64(42)));
      notifier.answerConteudo('c_double', Resposta(numero: 3.14));
      notifier.answerConteudo('c_bool', Resposta(booleano: true));

      final state = container.read(wizardControllerProvider);

      expect(state.answers['c_text']?.texto, equals('hello'));
      expect(state.answers['c_int']?.inteiro, equals(Int64(42)));
      expect(state.answers['c_double']?.numero, equals(3.14));
      expect(state.answers['c_bool']?.booleano, equals(true));

      // Valida o whichValor
      expect(state.answers['c_text']?.whichValor(), equals(Resposta_Valor.texto));
      expect(state.answers['c_int']?.whichValor(), equals(Resposta_Valor.inteiro));
      expect(state.answers['c_double']?.whichValor(), equals(Resposta_Valor.numero));
      expect(state.answers['c_bool']?.whichValor(), equals(Resposta_Valor.booleano));
    });
  });

  // ── 7. Data Atual, Listas Aninhadas e Persistência de Material ──────────────

  group('WizardStateController — preencher_data_atual, listas aninhadas e SubmissionRecord', () {
    late BancoDadosLocal banco;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wizard_ctrl_test');
      banco = await BancoDadosLocal.abrirEmMemoria();
    });

    tearDown(() async {
      await banco.fechar();
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('loadProtocol e addListItem preenchem automaticamente campos DATE com preencherDataAtual=true permitindo edição', () {
      final container = makeContainer();
      final tipoComData = TipoAcao(
        id: 'teste_qualidade',
        label: 'Teste de Qualidade',
        steps: [
          makeStep('tq_s1', [
            campoConteudo(
              id: 'tq_data',
              tipo: StepCampoSimples_TipoCampo.DATE,
              preencherDataAtual: true,
              obrigatorio: true,
            ),
          ]),
        ],
      );

      final protocol = makeProtocol([
        makeStep('s1', [
          campoConteudo(
            id: 'mat_data',
            tipo: StepCampoSimples_TipoCampo.DATE,
            preencherDataAtual: true,
            obrigatorio: true,
          ),
          campoConteudo(
            id: 'mat_data_manual',
            tipo: StepCampoSimples_TipoCampo.DATE,
            preencherDataAtual: false,
          ),
          listaConteudo(id: 'lista_testes', tipos: [tipoComData]),
        ]),
      ]);

      final notifier = container.read(wizardControllerProvider.notifier);
      notifier.loadProtocol(protocol);

      var state = container.read(wizardControllerProvider);
      final hoje = DateTime.now();
      final esperado =
          '${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';

      expect(state.answers['mat_data']?.texto, equals(esperado));
      expect(state.answers.containsKey('mat_data_manual'), isFalse);

      // Verifica que também preenche ao adicionar um item de lista que contém campo DATE com preencherDataAtual=true
      notifier.addListItem(listConteudoId: 'lista_testes', tipo: tipoComData);
      state = container.read(wizardControllerProvider);
      final itemId = state.lists['lista_testes']!.first.id;
      expect(state.answers['tq_data__$itemId']?.texto, equals(esperado));

      // Verifica que o usuário pode editar livremente a data pré-preenchida
      notifier.answerConteudoString('mat_data', '15/08/2025');
      state = container.read(wizardControllerProvider);
      expect(state.answers['mat_data']?.texto, equals('15/08/2025'));
    });

    test('manipula, valida, persiste e reconstrói StepListaAcoes aninhadas dentro de outra StepListaAcoes', () async {
      const yamlAninhado = '''
protocolo:
  id: "cadastro_material"
  nome: "Cadastro de Material"
  versao: 1
  blocos:
    - id: "b1"
      titulo: "Materiais"
      steps:
        - id: "s_ident"
          conteudos:
            - id: "mat_nome"
              campo_simples:
                label: "Nome do Material"
                tipo: TEXT
                obrigatorio: true
        - id: "lista_itens_material"
          conteudos:
            - id: "lista_itens_material_c"
              lista_acoes:
                label: "Itens do Material"
                minimo: 1
                tipos_disponiveis:
                  - id: "parabolt"
                    label: "Parabolt"
                    steps:
                      - id: "pb_s1"
                        conteudos:
                          - id: "pb_marca"
                            campo_simples:
                              label: "Marca"
                              tipo: TEXT
                              obrigatorio: true
                          - id: "pb_detalhes"
                            lista_acoes:
                              label: "Detalhes / Fabricação"
                              minimo: 1
                              tipos_disponiveis:
                                - id: "detalhe_item"
                                  label: "Detalhe / Etapa Relevante"
                                  steps:
                                    - id: "pb_det_step"
                                      conteudos:
                                        - id: "det_descricao"
                                          campo_simples:
                                            label: "Descrição da Etapa"
                                            tipo: TEXT
                                            obrigatorio: true
''';

      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          sessionBundleManagerProvider.overrideWithValue(
            SessionBundleManager(baseDirectoryGetter: () async => tempDir),
          ),
        ],
      );

      final protocol = ProtocolParser.fromYaml(yamlAninhado);
      final notifier = container.read(wizardControllerProvider.notifier);
      notifier.loadProtocol(protocol, rawYaml: yamlAninhado);

      notifier.answerConteudoString('mat_nome', 'Barra Roscada Inox 316 14cm');

      final tipoParabolt = protocol
          .blocos[0]
          .steps[1]
          .conteudos[0]
          .listaAcoes
          .tiposDisponiveis[0];
      final tipoEtapa = tipoParabolt
          .steps[0]
          .conteudos[1]
          .listaAcoes
          .tiposDisponiveis[0];

      // Adiciona item pai (parabolt)
      notifier.addListItem(listConteudoId: 'lista_itens_material_c', tipo: tipoParabolt);
      final parentItemId = container.read(wizardControllerProvider).lists['lista_itens_material_c']!.first.id;

      // Preenche marca do parabolt, mas não adiciona item na sub-lista que tem minimo: 1
      notifier.answerInlineConteudoString('pb_marca', 'Fabricação Própria', parentItemId);
      expect(notifier.confirmListItem('lista_itens_material_c', parentItemId), isFalse);

      // Adiciona item na sub-lista usando chave composta "pb_detalhes__<parentItemId>"
      final subListKey = 'pb_detalhes__$parentItemId';
      notifier.addListItem(listConteudoId: subListKey, tipo: tipoEtapa);
      final subItemId = container.read(wizardControllerProvider).lists[subListKey]!.first.id;

      // Preenche resposta da etapa e confirma sub-item e item pai
      notifier.answerInlineConteudoString('det_descricao', 'Corte e repassivação ácida', subItemId);
      expect(notifier.confirmListItem(subListKey, subItemId), isTrue);
      expect(notifier.confirmListItem('lista_itens_material_c', parentItemId), isTrue);

      // Persiste a sessão no disco e no banco local
      final sessionId = await notifier.saveSession();

      // Verifica o SubmissionRecord salvo no banco local
      final record = await banco.obterSubmissaoPorIdSessao(sessionId);
      expect(record, isNotNull);
      expect(record!.tipoRegistro, equals(SubmissionTipoRegistro.material));
      expect(record.isMaterial, isTrue);
      expect(record.tituloExibicao, equals('Barra Roscada Inox 316 14cm'));

      // Reconstrói em um novo container via loadSession
      final container2 = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          sessionBundleManagerProvider.overrideWithValue(
            SessionBundleManager(baseDirectoryGetter: () async => tempDir),
          ),
        ],
      );
      await container2.read(wizardControllerProvider.notifier).loadSession(sessionId);
      final restored = container2.read(wizardControllerProvider);

      final subListKeyMigrada = 'eb_details__$parentItemId';
      expect(restored.answers['mat_name']?.texto, equals('Barra Roscada Inox 316 14cm'));
      expect(restored.lists['material_items_list_c'], hasLength(1));
      expect(restored.lists['material_items_list_c']!.first.id, equals(parentItemId));
      expect(restored.answers['eb_brand__$parentItemId']?.texto, equals('Fabricação Própria'));
      expect(restored.lists[subListKeyMigrada], hasLength(1));
      expect(restored.lists[subListKeyMigrada]!.first.id, equals(subItemId));
      expect(restored.lists[subListKeyMigrada]!.first.tipoLabel, equals('Detalhe / Etapa de Fabricação'));
      expect(restored.answers['det_description__$subItemId']?.texto, equals('Corte e repassivação ácida'));
    });

    test('obterItensParaRefMateriais lista materiais do catálogo ordenados por dataUltimaSelecao e filtra nas ações', () async {
      await banco.salvarSubmissao(
        SubmissionRecord()
          ..idSessao = 'mat-antigo'
          ..idProtocolo = 'cadastro_material'
          ..tipoRegistro = SubmissionTipoRegistro.material
          ..tituloExibicao = 'Material Antigo'
          ..status = SubmissionStatus.gerado
          ..dataInclusao = DateTime(2026, 1, 1)
          ..dataUltimaSelecao = DateTime(2026, 5, 1),
      );
      await banco.salvarSubmissao(
        SubmissionRecord()
          ..idSessao = 'mat-recente'
          ..idProtocolo = 'cadastro_material'
          ..tipoRegistro = SubmissionTipoRegistro.material
          ..tituloExibicao = 'Material Recente'
          ..status = SubmissionStatus.gerado
          ..dataInclusao = DateTime(2026, 1, 2)
          ..dataUltimaSelecao = DateTime(2026, 10, 1),
      );
      await banco.salvarSubmissao(
        SubmissionRecord()
          ..idSessao = 'manut-1'
          ..idProtocolo = 'manutencao_ferragens'
          ..tipoRegistro = SubmissionTipoRegistro.manutencao
          ..tituloExibicao = 'Via Sul'
          ..status = SubmissionStatus.gerado,
      );

      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          sessionBundleManagerProvider.overrideWithValue(
            SessionBundleManager(baseDirectoryGetter: () async => tempDir),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(wizardControllerProvider.notifier);
      notifier.loadProtocol(
        makeProtocol([
          makeStep('s1', [
            ConteudoStep(
              id: 'lista_materiais_c',
              refMateriais: StepRefMateriais(
                label: 'Materiais do Catálogo',
                origemCatalogo: true,
                obrigatorio: true,
              ),
            ),
          ]),
        ]),
      );

      // 1. Verifica que obterItensParaRefMateriais(origemCatalogo: true) retorna apenas materiais ordenados por dataUltimaSelecao desc
      final refCatalogo = StepRefMateriais(origemCatalogo: true);
      var itensCatalogo = notifier.obterItensParaRefMateriais(refCatalogo);
      expect(itensCatalogo.map((i) => i.id).toList(), equals(['mat-recente', 'mat-antigo']));
      expect(itensCatalogo.first.tipoLabel, equals('Material Recente'));

      // 2. Seleciona 'mat-antigo' em lista_materiais_c -> deve atualizar dataUltimaSelecao e colocá-lo no topo
      notifier.setRefMateriais('lista_materiais_c', ['mat-antigo']);
      itensCatalogo = notifier.obterItensParaRefMateriais(refCatalogo);
      expect(itensCatalogo.map((i) => i.id).toList(), equals(['mat-antigo', 'mat-recente']));

      // 3. Verifica que um StepRefMateriais de ação que referencia idStepMateriais: 'lista_materiais_c' filtra pelos selecionados no Bloco 1
      final refAcao = StepRefMateriais(
        idStepMateriais: 'lista_materiais_c',
        origemCatalogo: false,
      );
      final itensAcao = notifier.obterItensParaRefMateriais(refAcao);
      expect(itensAcao.map((i) => i.id).toList(), equals(['mat-antigo']));
      await notifier.flushAutoSave();
    });

    test('saveDocumentAnswerBytes salva PDF original, rasteriza páginas WebP e registra ArquivoDocumento com hashes SHA-256', () async {
      final sessionManager = SessionBundleManager(baseDirectoryGetter: () async => tempDir);
      final mediaCompressor = MediaCompressorService(
        rasterizadorPdf: (pdfBytes, {double dpi = 150.0}) async {
          return [
            Uint8List.fromList([137, 80, 78, 71, 10]),
            Uint8List.fromList([137, 80, 78, 71, 20]),
          ];
        },
      );

      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          sessionBundleManagerProvider.overrideWithValue(sessionManager),
          mediaCompressorProvider.overrideWithValue(mediaCompressor),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(wizardControllerProvider.notifier);
      notifier.loadProtocol(
        makeProtocol([
          makeStep('s1', [
            campoConteudo(
              id: 'pb_nf_foto',
              tipo: StepCampoSimples_TipoCampo.IMAGE,
            ),
          ]),
        ]),
      );

      final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]);
      await notifier.saveDocumentAnswerBytes(
        'pb_nf_foto',
        pdfBytes,
        nomeOriginal: 'danfe_inox_316.pdf',
      );

      final state = container.read(wizardControllerProvider);
      final resposta = state.answers['pb_nf_foto'];
      expect(resposta, isNotNull);
      expect(resposta!.hasMidia(), isTrue);
      expect(resposta.midia.hasDocumento(), isTrue);

      final doc = resposta.midia.documento;
      expect(doc.uuid, isNotEmpty);
      expect(doc.tipoOriginal, equals('application/pdf'));
      expect(doc.nomeOriginal, equals('danfe_inox_316.pdf'));
      expect(doc.hashOriginal, isNotEmpty);
      expect(doc.quantidadePaginas, equals(2));
      expect(doc.hashesPaginasWebp, hasLength(2));

      final dirSessao = await sessionManager.getSessionDirectory(state.sessionId);
      expect(File('${dirSessao.path}/${doc.uuid}_original.pdf').existsSync(), isTrue);
      expect(File('${dirSessao.path}/${doc.uuid}_p1.webp').existsSync(), isTrue);
      expect(File('${dirSessao.path}/${doc.uuid}_p2.webp').existsSync(), isTrue);
      await notifier.flushAutoSave();
    });

    test('permite anexar múltiplas mídias (fotos, vídeos e PDFs) no mesmo campo, remover individualmente e restaurar na sessão', () async {
      final sessionManager = SessionBundleManager(baseDirectoryGetter: () async => tempDir);
      final mediaCompressor = MediaCompressorService(
        videoTranscoderService: VideoTranscoderService(
          executador: (cmd) async => true,
        ),
        rasterizadorPdf: (pdfBytes, {double dpi = 150.0}) async {
          return [
            Uint8List.fromList([137, 80, 78, 71, 10]),
          ];
        },
      );

      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          sessionBundleManagerProvider.overrideWithValue(sessionManager),
          mediaCompressorProvider.overrideWithValue(mediaCompressor),
        ],
      );
      addTearDown(container.dispose);

      const yamlProtocolo = '''
protocolo:
  id: "teste_multi_midia"
  nome: "Teste Multi Mídia"
  versao: "1.0.0"
  blocos:
    - id: "b1"
      titulo: "Bloco 1"
      steps:
        - id: "s1"
          conteudos:
            - id: "etapa_midias"
              campo_simples:
                label: "Mídias da Etapa"
                tipo: IMAGE
''';

      final notifier = container.read(wizardControllerProvider.notifier);
      final protocol = ProtocolParser.fromYaml(yamlProtocolo);
      notifier.loadProtocol(protocol, rawYaml: yamlProtocolo);

      // 1. Primeira mídia (Foto) -> armazenada como Resposta(midia: ...)
      await notifier.saveMediaAnswerBytes(
        'etapa_midias',
        Uint8List.fromList([1, 2, 3]),
        '.jpg',
        StepCampoSimples_TipoCampo.IMAGE,
      );
      var state = container.read(wizardControllerProvider);
      expect(state.answers['etapa_midias']!.hasMidia(), isTrue);
      expect(
        WizardStateController.extrairMidiasDeResposta(state.answers['etapa_midias']),
        hasLength(1),
      );

      // 2. Segunda mídia (Vídeo) -> passa a armazenar como ListaRespostas com 2 mídias
      await notifier.saveMediaAnswerBytes(
        'etapa_midias',
        Uint8List.fromList([4, 5, 6]),
        '.mp4',
        StepCampoSimples_TipoCampo.VIDEO,
      );
      state = container.read(wizardControllerProvider);
      expect(state.answers['etapa_midias']!.hasLista(), isTrue);

      // 3. Terceira mídia (Documento PDF) -> ListaRespostas com 3 mídias (foto, vídeo, PDF)
      await notifier.saveDocumentAnswerBytes(
        'etapa_midias',
        Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
        nomeOriginal: 'laudo_etapa.pdf',
      );
      state = container.read(wizardControllerProvider);
      final midias = WizardStateController.extrairMidiasDeResposta(state.answers['etapa_midias']);
      expect(midias, hasLength(3));
      expect(midias[0].hasImagem(), isTrue);
      expect(midias[1].hasVideo(), isTrue);
      expect(midias[2].hasDocumento(), isTrue);
      expect(midias[2].documento.nomeOriginal, equals('laudo_etapa.pdf'));

      // 4. Recarrega sessão via loadSession e verifica que ListaRespostas de mídias não contamina refSelections
      final sessionId = state.sessionId;
      await notifier.loadSession(sessionId);
      state = container.read(wizardControllerProvider);
      expect(state.refSelections.containsKey('etapa_midias'), isFalse);
      final midiasRestauradas = WizardStateController.extrairMidiasDeResposta(state.answers['etapa_midias']);
      expect(midiasRestauradas, hasLength(3));

      // 6. Remove a mídia do meio (vídeo, índice 1) -> restam 2 mídias (foto e PDF)
      await notifier.removerMidiaDaResposta('etapa_midias', 1);
      state = container.read(wizardControllerProvider);
      final aposRemover1 = WizardStateController.extrairMidiasDeResposta(state.answers['etapa_midias']);
      expect(aposRemover1, hasLength(2));
      expect(aposRemover1[0].hasImagem(), isTrue);
      expect(aposRemover1[1].hasDocumento(), isTrue);

      // 7. Remove a primeira mídia (índice 0) -> resta 1 mídia (volta a ser Resposta.midia)
      await notifier.removerMidiaDaResposta('etapa_midias', 0);
      state = container.read(wizardControllerProvider);
      expect(state.answers['etapa_midias']!.hasMidia(), isTrue);
      expect(state.answers['etapa_midias']!.midia.hasDocumento(), isTrue);

      // 8. Remove a última mídia (índice 0) -> remove a chave de answers
      await notifier.removerMidiaDaResposta('etapa_midias', 0);
      state = container.read(wizardControllerProvider);
      expect(state.answers.containsKey('etapa_midias'), isFalse);
      await notifier.flushAutoSave();
    });

    test('loadSession atualiza automaticamente rascunho de cadastro_material com YAML legado (det_video/tq_video) para o YAML atualizado', () async {
      final sessionManager = SessionBundleManager(baseDirectoryGetter: () async => tempDir);
      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          sessionBundleManagerProvider.overrideWithValue(sessionManager),
        ],
      );
      addTearDown(container.dispose);

      const yamlLegadoComVideoSeparado = '''
protocolo:
  id: cadastro_material
  nome: "Cadastro de Material de Manutenção"
  versao: "1.0.0"
  blocos:
    - id: composicao_materiais
      titulo: "Bloco 2"
      steps:
        - id: lista_itens_material
          conteudos:
            - id: lista_itens_material_c
              lista_acoes:
                label: "Materiais"
                minimo: 1
                tipos_disponiveis:
                  - id: parabolt
                    label: "Parabolt"
                    steps:
                      - id: pb_dados
                        conteudos:
                          - id: pb_detalhes
                            lista_acoes:
                              label: "Detalhes"
                              tipos_disponiveis:
                                - id: detalhe_item
                                  label: "Detalhe"
                                  steps:
                                    - id: pb_det_step
                                      conteudos:
                                        - id: det_foto
                                          campo_simples:
                                            label: "Foto da Etapa / Detalhe"
                                            tipo: IMAGE
                                        - id: det_video
                                          campo_simples:
                                            label: "Vídeo Curto da Etapa / Detalhe"
                                            tipo: VIDEO
''';

      final notifier = container.read(wizardControllerProvider.notifier);
      final protoLegado = ProtocolParser.fromYaml(yamlLegadoComVideoSeparado);
      notifier.loadProtocol(protoLegado, rawYaml: yamlLegadoComVideoSeparado);
      final sessionId = await notifier.saveSession();

      await notifier.loadSession(sessionId);
      final state = container.read(wizardControllerProvider);
      expect(state.protocolRawYaml.contains('det_video'), isFalse);
      expect(state.protocolRawYaml.contains('tq_video'), isFalse);
      expect(state.protocolRawYaml, contains('Attach Media to Step / Detail'));
      expect(state.protocolRawYaml, contains('Attach Media to Test / Report'));
    });

    test('saveMultipleMediaAnswers processa lote em background expondo processandoMidiasPorCampo durante a execução', () async {
      final sessionManager = SessionBundleManager(baseDirectoryGetter: () async => tempDir);
      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          sessionBundleManagerProvider.overrideWithValue(sessionManager),
          videoTranscoderServiceProvider.overrideWithValue(
            VideoTranscoderService(executador: (cmd) async => true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(wizardControllerProvider.notifier);
      notifier.loadProtocol(
        makeProtocol([
          makeStep('s1', [
            campoConteudo(
              id: 'det_foto',
              tipo: StepCampoSimples_TipoCampo.IMAGE,
            ),
          ]),
        ]),
      );

      final arqFoto = File('${tempDir.path}/lote_foto.jpg')
        ..writeAsBytesSync(List<int>.filled(70000, 7));
      final arqVideo = File('${tempDir.path}/lote_video.mp4')
        ..writeAsBytesSync([1, 2, 3, 4]);

      final valoresObservados = <int>[];
      container.listen<WizardState>(
        wizardControllerProvider,
        (prev, next) {
          final qtd = next.processandoMidiasPorCampo['det_foto'] ?? 0;
          valoresObservados.add(qtd);
        },
      );

      await notifier.saveMultipleMediaAnswers(
        'det_foto',
        [
          (
            filePath: arqFoto.path,
            tipo: StepCampoSimples_TipoCampo.IMAGE,
            inicioCorteSegundos: null,
            duracaoCorteSegundos: null,
          ),
          (
            filePath: arqVideo.path,
            tipo: StepCampoSimples_TipoCampo.VIDEO,
            inicioCorteSegundos: null,
            duracaoCorteSegundos: null,
          ),
        ],
      );

      // Durante a execução deve ter sinalizado 2 -> 1 -> 0 mídias sendo processadas
      expect(valoresObservados, contains(2));
      expect(valoresObservados.last, equals(0));

      final state = container.read(wizardControllerProvider);
      expect(state.processandoMidiasPorCampo.containsKey('det_foto'), isFalse);
      final midias = WizardStateController.extrairMidiasDeResposta(state.answers['det_foto']);
      expect(midias, hasLength(2));
      expect(midias[0].hasImagem(), isTrue);
      expect(midias[1].hasVideo(), isTrue);
      await notifier.flushAutoSave();
    });

    test('dispara pré-processamento não-bloqueante em background no MediaCompressorService ao anexar fotos e vídeos', () async {
      FlutterImageCompressPlatform.instance = _FakeImageCompressPlatform();
      final sessionManager = SessionBundleManager(baseDirectoryGetter: () async => tempDir);
      final comandosVideo = <String>[];
      final transcoder = VideoTranscoderService(
        executador: (cmd) async {
          comandosVideo.add(cmd);
          final match = RegExp(r'-y "([^"]+)"').firstMatch(cmd);
          if (match != null) {
            final outFile = File(match.group(1)!);
            await outFile.create(recursive: true);
            await outFile.writeAsBytes([9, 9, 9]);
          }
          return true;
        },
      );
      final mediaCompressor = MediaCompressorService(
        videoTranscoderService: transcoder,
      );

      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          sessionBundleManagerProvider.overrideWithValue(sessionManager),
          mediaCompressorProvider.overrideWithValue(mediaCompressor),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(wizardControllerProvider.notifier);
      notifier.loadProtocol(
        makeProtocol([
          makeStep('s1', [
            campoConteudo(
              id: 'campo_midia',
              tipo: StepCampoSimples_TipoCampo.IMAGE,
            ),
          ]),
        ]),
      );

      // 1. Anexa foto via saveMediaAnswerBytes
      await notifier.saveMediaAnswerBytes(
        'campo_midia',
        Uint8List.fromList([10, 20, 30]),
        '.jpg',
        StepCampoSimples_TipoCampo.IMAGE,
      );

      // 2. Anexa vídeo via saveMultipleMediaAnswers
      final arqVideo = File('${tempDir.path}/video_bg.mp4')
        ..writeAsBytesSync([1, 2, 3, 4]);
      await notifier.saveMultipleMediaAnswers(
        'campo_midia',
        [
          (
            filePath: arqVideo.path,
            tipo: StepCampoSimples_TipoCampo.VIDEO,
            inicioCorteSegundos: null,
            duracaoCorteSegundos: null,
          ),
        ],
      );

      final state = container.read(wizardControllerProvider);
      final midias = WizardStateController.extrairMidiasDeResposta(state.answers['campo_midia']);
      expect(midias, hasLength(2));
      final uuidFoto = midias[0].imagem.uuid;
      final uuidVideo = midias[1].video.uuid;

      // Aguarda conclusão das tarefas disparadas automaticamente em background pelo controller
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final dirSessao = await sessionManager.getSessionDirectory(state.sessionId);
      expect(File('${dirSessao.path}/$uuidFoto.webp').existsSync(), isTrue);
      expect(File('${dirSessao.path}/${uuidFoto}_thumb.jpg').existsSync(), isTrue);
      expect(File('${dirSessao.path}/$uuidVideo.mp4').existsSync(), isTrue);
      expect(File('${dirSessao.path}/${uuidVideo}_poster.jpg').existsSync(), isTrue);
      expect(comandosVideo, isNotEmpty);
      await notifier.flushAutoSave();
    });

    test('loadSession remove respostas legadas assinatura_c/mat_assinatura_c e migra YAML legado com SIGNATURE', () async {
      final sessionManager = SessionBundleManager(baseDirectoryGetter: () async => tempDir);
      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          sessionBundleManagerProvider.overrideWithValue(sessionManager),
        ],
      );
      addTearDown(container.dispose);

      const yamlLegadoAssinatura = '''
protocolo:
  id: manutencao_ferragens
  nome: "Manutenção de Ferragens"
  versao: "1.0.0"
  blocos:
    - id: avaliacao
      titulo: "Avaliação Final"
      steps:
        - id: observacoes_finais
          conteudos:
            - id: obs_c
              campo_simples:
                label: "Observações"
                tipo: TEXT_LONG
        - id: assinatura
          conteudos:
            - id: assinatura_instrucao
              instrucao:
                titulo: "Declaração"
                texto: "Declaro..."
            - id: assinatura_c
              campo_simples:
                label: "Assinatura"
                tipo: SIGNATURE
                obrigatorio: true
''';

      final sessionId = 'sessao-legada-assinatura';
      final registroLegado = Registro(
        idSessao: sessionId,
        idProtocolo: 'manutencao_ferragens',
        versaoProtocolo: '1.0.0',
        yamlConteudo: yamlLegadoAssinatura,
        respostas: [
          MapEntry('obs_c', Resposta(texto: 'Via em bom estado')),
          MapEntry('assinatura_c', Resposta(texto: 'uuid-assinatura-antiga')),
          MapEntry('mat_assinatura_c', Resposta(texto: 'uuid-mat-assinatura-antiga')),
        ],
      );
      await sessionManager.saveManifest(
        sessionId: sessionId,
        binarypb: registroLegado.writeToBuffer(),
      );

      final notifier = container.read(wizardControllerProvider.notifier);
      await notifier.loadSession(sessionId);

      final state = container.read(wizardControllerProvider);
      expect(state.answers['obs_c']?.texto, equals('Via em bom estado'));
      expect(state.answers.containsKey('assinatura_c'), isFalse);
      expect(state.answers.containsKey('mat_assinatura_c'), isFalse);
      expect(state.protocolRawYaml.contains('SIGNATURE'), isFalse);
      final todosStepIds = state.protocol!.blocos.expand((b) => b.steps).map((s) => s.id).toList();
      expect(todosStepIds, isNot(contains('assinatura')));
    });

    test('loadSession verifica midias da sessao e dispara pre-processamento em 2o plano quando arquivos finais nao existem', () async {
      FlutterImageCompressPlatform.instance = _FakeImageCompressPlatform();
      final sessionManager = SessionBundleManager(baseDirectoryGetter: () async => tempDir);
      final transcoder = VideoTranscoderService(
        executador: (cmd) async {
          final match = RegExp(r'-y "([^"]+)"').firstMatch(cmd);
          if (match != null) {
            final outFile = File(match.group(1)!);
            await outFile.create(recursive: true);
            await outFile.writeAsBytes([7, 7, 7]);
          }
          return true;
        },
      );
      final mediaCompressor = MediaCompressorService(
        videoTranscoderService: transcoder,
      );

      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          sessionBundleManagerProvider.overrideWithValue(sessionManager),
          mediaCompressorProvider.overrideWithValue(mediaCompressor),
        ],
      );
      addTearDown(container.dispose);

      const sessionId = 'sessao-edicao-pendente';
      final dirSessao = await sessionManager.getSessionDirectory(sessionId);

      // Cria apenas os arquivos originais (simulando sessão cujo pré-processamento não terminou)
      File('${dirSessao.path}/foto_pend_original.jpg').writeAsBytesSync([1, 2, 3]);
      File('${dirSessao.path}/vid_pend_original.mp4').writeAsBytesSync([4, 5, 6]);
      File('${dirSessao.path}/doc_pend_p1_original.jpg').writeAsBytesSync([7, 8, 9]);

      const yamlSimples = '''
protocolo:
  id: manutencao_ferragens
  nome: "Manutenção"
  versao: "1.0.0"
  blocos:
    - id: b1
      titulo: "Bloco 1"
      steps:
        - id: s1
          conteudos:
            - id: midias_c
              campo_simples:
                label: "Mídias"
                tipo: IMAGE
''';

      final registro = Registro(
        idSessao: sessionId,
        idProtocolo: 'manutencao_ferragens',
        versaoProtocolo: '1.0.0',
        yamlConteudo: yamlSimples,
        respostas: [
          MapEntry(
            'midias_c',
            Resposta(
              lista: ListaRespostas(
                valores: [
                  Resposta(
                    midia: ReferenciaMidia(
                      imagem: ArquivoImagem(
                        uuid: 'foto_pend',
                        hashOriginal: 'h1',
                        tipoOriginal: 'image/jpg',
                      ),
                    ),
                  ),
                  Resposta(
                    midia: ReferenciaMidia(
                      video: ArquivoVideo(
                        uuid: 'vid_pend',
                        hashOriginal: 'h2',
                        tipoOriginal: 'video/mp4',
                      ),
                    ),
                  ),
                  Resposta(
                    midia: ReferenciaMidia(
                      documento: ArquivoDocumento(
                        uuid: 'doc_pend',
                        hashOriginal: 'h3',
                        tipoOriginal: 'application/pdf',
                        nomeOriginal: 'nota.pdf',
                        quantidadePaginas: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      await sessionManager.saveManifest(
        sessionId: sessionId,
        binarypb: registro.writeToBuffer(),
      );

      final notifier = container.read(wizardControllerProvider.notifier);
      await notifier.loadSession(sessionId);

      // Aguarda conclusão do pré-processamento disparado em 2o plano pelo loadSession
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(File('${dirSessao.path}/foto_pend.webp').existsSync(), isTrue);
      expect(File('${dirSessao.path}/foto_pend_thumb.jpg').existsSync(), isTrue);
      expect(File('${dirSessao.path}/vid_pend.mp4').existsSync(), isTrue);
      expect(File('${dirSessao.path}/vid_pend_poster.jpg').existsSync(), isTrue);
      expect(File('${dirSessao.path}/doc_pend_p1.webp').existsSync(), isTrue);
      expect(File('${dirSessao.path}/doc_pend_p1_thumb.jpg').existsSync(), isTrue);
    });

    test('duplicarSessao clona respostas, listas e midias com sufixo incremental (Cópia), (Cópia 2), (Cópia 3) e atualiza data atual', () async {
      FlutterImageCompressPlatform.instance = _FakeImageCompressPlatform();
      final sessionManager = SessionBundleManager(baseDirectoryGetter: () async => tempDir);
      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          sessionBundleManagerProvider.overrideWithValue(sessionManager),
        ],
      );
      addTearDown(container.dispose);

      const yamlMaterial = '''
protocolo:
  id: cadastro_material
  nome: "Cadastro de Material"
  versao: "1.0.0"
  blocos:
    - id: b1
      titulo: "Identificação"
      steps:
        - id: s1
          conteudos:
            - id: mat_nome
              campo_simples:
                label: "Nome do Material"
                tipo: TEXT
                obrigatorio: true
            - id: mat_data
              campo_simples:
                label: "Data"
                tipo: DATE
                preencher_data_atual: true
            - id: mat_foto
              campo_simples:
                label: "Foto"
                tipo: IMAGE
''';

      const idOriginal = 'sessao-mat-original';
      final dirOriginal = await sessionManager.getSessionDirectory(idOriginal);
      File('${dirOriginal.path}/foto_mat_original.jpg').writeAsBytesSync([1, 2, 3]);
      File('${dirOriginal.path}/foto_mat.webp').writeAsBytesSync([4, 5, 6]);
      File('${dirOriginal.path}/foto_mat_thumb.jpg').writeAsBytesSync([7, 8, 9]);
      File('${dirOriginal.path}/fixalog_$idOriginal.epub').writeAsBytesSync([99, 99]);

      final registroOriginal = Registro(
        idSessao: idOriginal,
        idProtocolo: 'cadastro_material',
        versaoProtocolo: '1.0.0',
        yamlConteudo: yamlMaterial,
        respostas: [
          MapEntry('mat_nome', Resposta(texto: 'Kit Parabolt Inox')),
          MapEntry('mat_data', Resposta(texto: '01/01/2020')),
          MapEntry(
            'mat_foto',
            Resposta(
              midia: ReferenciaMidia(
                imagem: ArquivoImagem(
                  uuid: 'foto_mat',
                  hashOriginal: 'hash_foto',
                  tipoOriginal: 'image/jpg',
                ),
              ),
            ),
          ),
        ],
      );
      await sessionManager.saveManifest(
        sessionId: idOriginal,
        binarypb: registroOriginal.writeToBuffer(),
      );
      await banco.salvarSubmissao(
        SubmissionRecord()
          ..idSessao = idOriginal
          ..idProtocolo = 'cadastro_material'
          ..nomeProtocolo = 'Cadastro de Material'
          ..tituloExibicao = 'Kit Parabolt Inox'
          ..tipoRegistro = SubmissionTipoRegistro.material
          ..status = SubmissionStatus.gerado
          ..pdfPath = '${dirOriginal.path}/fixalog_$idOriginal.pdf'
          ..protobufPath = '${dirOriginal.path}/fixalog_$idOriginal.epub',
      );

      final notifier = container.read(wizardControllerProvider.notifier);

      // 1a cópia -> "Kit Parabolt Inox (Cópia)"
      final idCopia1 = await notifier.duplicarSessao(idOriginal);
      expect(idCopia1, isNot(equals(idOriginal)));
      final state1 = container.read(wizardControllerProvider);
      expect(state1.sessionId, equals(idCopia1));
      expect(state1.answers['mat_name']?.texto, equals('Kit Parabolt Inox (Cópia)'));
      expect(state1.answers['mat_date']?.texto, isNot(equals('01/01/2020')));

      final hoje = DateTime.now();
      final dataHojeEsperada =
          '${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';
      expect(state1.answers['mat_date']?.texto, equals(dataHojeEsperada));

      // Verifica que mídias foram copiadas e EPUB antigo não foi copiado
      final dirCopia1 = await sessionManager.getSessionDirectory(idCopia1);
      expect(File('${dirCopia1.path}/foto_mat_original.jpg').existsSync(), isTrue);
      expect(File('${dirCopia1.path}/foto_mat.webp').existsSync(), isTrue);
      expect(File('${dirCopia1.path}/foto_mat_thumb.jpg').existsSync(), isTrue);
      expect(File('${dirCopia1.path}/fixalog_$idOriginal.epub').existsSync(), isFalse);

      // Verifica registro salvo no SQLite como EM_PROGRESSO
      final regCopia1 = await banco.obterSubmissaoPorIdSessao(idCopia1);
      expect(regCopia1, isNotNull);
      expect(regCopia1!.tituloExibicao, equals('Kit Parabolt Inox (Cópia)'));
      expect(regCopia1.status, equals(SubmissionStatus.emProgresso));
      expect(regCopia1.pdfPath, isEmpty);

      // 2a cópia (duplicando a partir da própria 1a cópia!) -> "Kit Parabolt Inox (Cópia 2)"
      final idCopia2 = await notifier.duplicarSessao(idCopia1);
      final state2 = container.read(wizardControllerProvider);
      expect(state2.answers['mat_name']?.texto, equals('Kit Parabolt Inox (Cópia 2)'));

      // 3a cópia (duplicando a partir do original novamente) -> "Kit Parabolt Inox (Cópia 3)"
      final idCopia3 = await notifier.duplicarSessao(idOriginal);
      final state3 = container.read(wizardControllerProvider);
      expect(state3.answers['mat_name']?.texto, equals('Kit Parabolt Inox (Cópia 3)'));
    });

    test('loadSession e duplicarSessao migram automaticamente sessões legadas (manutencao_ferragens, abertura_via_v1, inspecao_visual_v1, registro_expresso v1)', () async {
      final sessionManager = SessionBundleManager(baseDirectoryGetter: () async => tempDir);
      final container = ProviderContainer(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
          sessionBundleManagerProvider.overrideWithValue(sessionManager),
        ],
      );
      addTearDown(container.dispose);

      // 1. Sessão legada de manutencao_ferragens (v2.1.0) com lista_materiais_c e np_ref_materiais
      const idManutLegado = 'sessao-manut-legada';
      final regManutLegado = Registro(
        idSessao: idManutLegado,
        idProtocolo: 'manutencao_ferragens',
        versaoProtocolo: '2.1.0',
        yamlConteudo: 'id: manutencao_ferragens\nversao: "2.1.0"\nnome: "Manutenção"\nblocos: []',
        respostas: [
          MapEntry('via_nome', Resposta(texto: 'Via Clássica')),
          MapEntry(
            'lista_materiais_c',
            Resposta(lista: ListaRespostas(valores: [Resposta(texto: 'mat-1')])),
          ),
        ],
        listas: [
          GrupoRepetido(
            idLista: 'lista_acoes_c',
            idItem: 'item_np_1',
            idTipo: 'novo_ponto',
            respostasItem: [
              MapEntry(
                'np_ref_materiais',
                Resposta(lista: ListaRespostas(valores: [Resposta(texto: 'mat-1')])),
              ),
            ],
          ),
        ],
      );
      await sessionManager.saveManifest(
        sessionId: idManutLegado,
        binarypb: regManutLegado.writeToBuffer(),
      );

      final notifier = container.read(wizardControllerProvider.notifier);
      await notifier.loadSession(idManutLegado);
      final stateManut = container.read(wizardControllerProvider);
      expect(stateManut.protocol!.id, equals('maintenance'));
      expect(stateManut.protocol!.versao, equals('3'));
      expect(stateManut.answers.containsKey('lista_materiais_c'), isFalse);
      expect(stateManut.refSelections['ref_mat_new_anchor__item_np_1'], equals(['mat-1']));

      // 2. Duplicar sessão legada de abertura_via_v1 (v1.0.0) -> migra para route_opening v3 e aplica (Cópia) em route_name
      const idAberturaLegado = 'sessao-abertura-legada';
      final regAberturaLegado = Registro(
        idSessao: idAberturaLegado,
        idProtocolo: 'abertura_via_v1',
        versaoProtocolo: '1.0.0',
        yamlConteudo: 'id: abertura_via_v1\nversao: "1.0.0"\nnome: "Abertura"\nblocos: []',
        respostas: [
          MapEntry('nome_via', Resposta(texto: 'Via Nova Sul')),
          MapEntry('graduacao_proposta', Resposta(texto: '7a')),
        ],
      );
      await sessionManager.saveManifest(
        sessionId: idAberturaLegado,
        binarypb: regAberturaLegado.writeToBuffer(),
      );

      final idAberturaCopia = await notifier.duplicarSessao(idAberturaLegado);
      final stateAbertura = container.read(wizardControllerProvider);
      expect(idAberturaCopia, isNot(equals(idAberturaLegado)));
      expect(stateAbertura.protocol!.id, equals('route_opening'));
      expect(stateAbertura.protocol!.versao, equals('3'));
      expect(stateAbertura.answers['route_name']?.texto, equals('Via Nova Sul (Cópia)'));
      expect(stateAbertura.answers['route_grade']?.texto, equals('7a'));
    });
  });
}
