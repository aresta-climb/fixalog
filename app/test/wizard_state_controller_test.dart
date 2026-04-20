import 'package:app/features/wizard/controllers/wizard_state_controller.dart';
import 'package:app/core/models/proto/protos/wizard.pb.dart';
import 'package:app/core/models/proto/protos/wizard.pbenum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers de fixture
// ─────────────────────────────────────────────────────────────────────────────

Step _textStep(String id, {bool obrigatorio = true}) => Step(
      id: id,
      campoSimples: StepCampoSimples(
        label: id,
        tipo: StepCampoSimples_TipoCampo.TEXT,
        obrigatorio: obrigatorio,
      ),
    );

Step _boolStep(String id) => Step(
      id: id,
      campoSimples: StepCampoSimples(
        label: id,
        tipo: StepCampoSimples_TipoCampo.BOOLEAN,
        obrigatorio: false,
      ),
    );

Step _ramoStep(String id, {required List<Ramo> ramos}) => Step(
      id: id,
      selecaoRamo: StepSelecaoRamo(
        label: id,
        obrigatorio: true,
        ramos: ramos,
      ),
    );

Step _instrucaoStep(String id) => Step(
      id: id,
      instrucao: StepInstrucao(titulo: id, corpo: 'Texto de instrução'),
    );

Step _listaStep(String id, {int minimo = 1}) => Step(
      id: id,
      listaAcoes: StepListaAcoes(
        label: id,
        minimo: minimo,
        tiposDisponiveis: [
          TipoAcao(
            id: 'tipo_a',
            label: 'Tipo A',
            steps: [_textStep('tipo_a_detalhe')],
          ),
        ],
      ),
    );

DefinicaoProtocolo _singleStepProtocol(Step step) => DefinicaoProtocolo(
      id: 'test',
      versao: '1.0.0',
      blocos: [
        Bloco(id: 'b1', titulo: 'Bloco', steps: [step]),
      ],
    );

DefinicaoProtocolo _multiStepProtocol(List<Step> steps) => DefinicaoProtocolo(
      id: 'test',
      versao: '1.0.0',
      blocos: [
        Bloco(id: 'b1', titulo: 'Bloco', steps: steps),
      ],
    );

// ─────────────────────────────────────────────────────────────────────────────
// Suíte de testes
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('WizardStateController', () {
    late ProviderContainer container;
    late WizardStateController controller;

    setUp(() {
      container = ProviderContainer();
      controller = container.read(wizardControllerProvider.notifier);
    });

    tearDown(() => container.dispose());

    // ── Estado inicial ──────────────────────────────────────────────────────

    test('estado inicial está vazio', () {
      final state = container.read(wizardControllerProvider);
      expect(state.protocol, isNull);
      expect(state.currentIndex, 0);
      expect(state.answers.isEmpty, true);
      expect(state.queue.isEmpty, true);
    });

    // ── loadProtocol ────────────────────────────────────────────────────────

    test('loadProtocol popula a fila com os steps dos blocos', () {
      final proto = _multiStepProtocol([
        _textStep('c1'),
        _boolStep('c2'),
      ]);
      controller.loadProtocol(proto);

      final state = container.read(wizardControllerProvider);
      expect(state.protocol?.id, 'test');
      expect(state.queue.length, 2);
      expect(state.queue[0].step.id, 'c1');
      expect(state.queue[1].step.id, 'c2');
      expect(state.currentIndex, 0);
    });

    // ── nextStep — campo obrigatório ────────────────────────────────────────

    test('nextStep bloqueia se campo obrigatório sem resposta', () {
      controller.loadProtocol(_singleStepProtocol(_textStep('c1', obrigatorio: true)));

      final success = controller.nextStep();

      expect(success, false);
      expect(container.read(wizardControllerProvider).currentIndex, 0);
    });

    test('nextStep avança se campo obrigatório tem resposta', () {
      controller.loadProtocol(_singleStepProtocol(_textStep('c1', obrigatorio: true)));
      controller.answerCurrentStep('Resposta válida');

      final success = controller.nextStep();

      expect(success, true);
      expect(container.read(wizardControllerProvider).currentIndex, 1);
    });

    test('nextStep avança campo não-obrigatório sem resposta', () {
      controller.loadProtocol(_singleStepProtocol(_boolStep('c1')));

      final success = controller.nextStep();

      expect(success, true);
      expect(container.read(wizardControllerProvider).currentIndex, 1);
    });

    // ── nextStep — StepInstrucao não bloqueia ───────────────────────────────

    test('nextStep avança StepInstrucao sem resposta (nunca bloqueia)', () {
      controller.loadProtocol(_singleStepProtocol(_instrucaoStep('inst1')));

      final success = controller.nextStep();

      expect(success, true);
    });

    // ── answerCurrentStep ───────────────────────────────────────────────────

    test('answerCurrentStep registra resposta pela answerKey correta', () {
      controller.loadProtocol(_multiStepProtocol([_textStep('c1'), _textStep('c2')]));
      controller.answerCurrentStep('valor1');

      final state = container.read(wizardControllerProvider);
      expect(state.answers['c1'], 'valor1');
      expect(state.answers.containsKey('c2'), false);
    });

    // ── chooseRamo ──────────────────────────────────────────────────────────

    test('chooseRamo injeta sub-steps do ramo na fila e avança', () {
      final proto = _multiStepProtocol([
        _ramoStep('r1', ramos: [
          Ramo(id: 'opcao_a', label: 'A', steps: [_textStep('sub_a1'), _textStep('sub_a2')]),
          Ramo(id: 'opcao_b', label: 'B', steps: [_textStep('sub_b1')]),
        ]),
        _textStep('pos_ramo'),
      ]);
      controller.loadProtocol(proto);

      // Fila inicial: [r1, pos_ramo]
      expect(container.read(wizardControllerProvider).queue.length, 2);

      controller.chooseRamo('opcao_a');

      // Fila após: [r1, sub_a1, sub_a2, pos_ramo]
      final state = container.read(wizardControllerProvider);
      expect(state.queue.length, 4);
      expect(state.queue[1].step.id, 'sub_a1');
      expect(state.queue[2].step.id, 'sub_a2');
      expect(state.queue[3].step.id, 'pos_ramo');
      expect(state.currentIndex, 1); // já avançou para sub_a1
      expect(state.answers['r1'], 'opcao_a');
    });

    test('chooseRamo com ramo vazio apenas registra resposta e avança', () {
      final proto = _singleStepProtocol(
        _ramoStep('r1', ramos: [
          Ramo(id: 'sem_steps', label: 'Simples', steps: []),
        ]),
      );
      controller.loadProtocol(proto);
      controller.chooseRamo('sem_steps');

      final state = container.read(wizardControllerProvider);
      expect(state.queue.length, 1); // nenhum step injetado
      expect(state.answers['r1'], 'sem_steps');
      expect(state.currentIndex, 1); // passou para além do ramo
    });

    // ── addListItem ──────────────────────────────────────────────────────────

    test('addListItem cria registro e injeta steps do tipo na fila', () {
      final proto = _multiStepProtocol([
        _listaStep('lista1'),
        _textStep('pos_lista'),
      ]);
      controller.loadProtocol(proto);

      // Fila inicial: [lista1, pos_lista]
      final tipo = container.read(wizardControllerProvider)
          .queue[0]
          .step
          .listaAcoes
          .tiposDisponiveis[0];

      controller.addListItem(listStepId: 'lista1', tipo: tipo);

      final state = container.read(wizardControllerProvider);
      // Fila: [lista1, tipo_a_detalhe, pos_lista]
      expect(state.queue.length, 3);
      expect(state.queue[1].step.id, 'tipo_a_detalhe');
      expect(state.queue[1].listStepId, 'lista1');
      expect(state.lists['lista1']?.length, 1);
      expect(state.currentIndex, 1); // entrou no sub-fluxo
    });

    // ── setRefMateriais ──────────────────────────────────────────────────────

    test('setRefMateriais registra ids e atualiza answers', () {
      final refStep = Step(
        id: 'ref1',
        refMateriais: StepRefMateriais(
          label: 'Materiais',
          idStepMateriais: 'lista1',
          obrigatorio: true,
        ),
      );
      controller.loadProtocol(_singleStepProtocol(refStep));
      controller.setRefMateriais(['id_a', 'id_b']);

      final state = container.read(wizardControllerProvider);
      expect(state.refSelections['ref1'], containsAll(['id_a', 'id_b']));
      expect(state.answers.containsKey('ref1'), true);
    });

    // ── goToStep / previousStep ──────────────────────────────────────────────

    test('goToStep navega para índice válido', () {
      controller.loadProtocol(_multiStepProtocol([
        _boolStep('c1'), _boolStep('c2'), _boolStep('c3'),
      ]));
      controller.goToStep(2);

      expect(container.read(wizardControllerProvider).currentIndex, 2);
    });

    test('previousStep decrementa índice', () {
      controller.loadProtocol(_multiStepProtocol([_boolStep('c1'), _boolStep('c2')]));
      controller.nextStep();
      controller.previousStep();

      expect(container.read(wizardControllerProvider).currentIndex, 0);
    });

    test('previousStep não vai abaixo de 0', () {
      controller.loadProtocol(_singleStepProtocol(_boolStep('c1')));
      controller.previousStep();

      expect(container.read(wizardControllerProvider).currentIndex, 0);
    });

    // ── isFinished ───────────────────────────────────────────────────────────

    test('isFinished é true quando currentIndex >= queue.length', () {
      controller.loadProtocol(_singleStepProtocol(_boolStep('c1')));
      expect(container.read(wizardControllerProvider).isFinished, false);

      controller.nextStep();
      expect(container.read(wizardControllerProvider).isFinished, true);
    });
  });
}
