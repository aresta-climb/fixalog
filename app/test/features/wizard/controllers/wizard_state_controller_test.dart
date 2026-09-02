// test/wizard_state_controller_test.dart
//
// Testa o WizardStateController com o novo schema (Step.conteudos).
//
// Uso: flutter test test/wizard_state_controller_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixlog/core/models/proto/protos/wizard.pb.dart';
import 'package:fixlog/features/wizard/controllers/wizard_state_controller.dart';
import 'package:fixlog/core/models/proto/protos/registro.pb.dart';
import 'package:fixnum/fixnum.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Builders para construir protos de teste sem YAML
// ─────────────────────────────────────────────────────────────────────────────

/// Cria um ConteudoStep de CampoSimples.
ConteudoStep campoConteudo({
  required String id,
  String label = 'Campo',
  bool obrigatorio = false,
  StepCampoSimples_TipoCampo tipo = StepCampoSimples_TipoCampo.TEXT,
}) {
  return ConteudoStep(
    id: id,
    campoSimples: StepCampoSimples(
      label: label,
      obrigatorio: obrigatorio,
      tipo: tipo,
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
DefinicaoProtocolo makeProtocol(List<Step> steps) {
  return DefinicaoProtocolo(
    id: 'test_proto',
    nome: 'Test',
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
}
