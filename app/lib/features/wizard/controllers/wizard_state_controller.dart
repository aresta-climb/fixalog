import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/proto/protos/wizard.pb.dart';
import '../../../core/models/proto/protos/wizard.pbenum.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelos de dados do estado do wizard
// ─────────────────────────────────────────────────────────────────────────────

/// Representa um item adicionado pelo mantenedor numa [StepListaAcoes].
/// Carrega as respostas dos steps internos (por answerId composto).
class ListItemRecord {
  final String id;         // UUID auto-gerado
  final String tipoId;
  final String tipoLabel;
  final String tipoIconName;

  const ListItemRecord({
    required this.id,
    required this.tipoId,
    required this.tipoLabel,
    required this.tipoIconName,
  });
}

/// Um step ativo na fila de execução do wizard.
/// Carrega o contexto do item de lista ao qual pertence (se houver).
class FlowStep {
  final Step step;

  /// ID do step [StepListaAcoes] de origem (se este step faz parte de um item).
  final String? listStepId;

  /// ID da instância do item na lista ([ListItemRecord.id]).
  final String? listItemId;

  const FlowStep({required this.step, this.listStepId, this.listItemId});

  /// Chave única para indexar a resposta deste step.
  /// Dentro de um contexto de lista: "<stepId>__<listItemId>".
  String get answerKey =>
      listItemId != null ? '${step.id}__$listItemId' : step.id;
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado imutável
// ─────────────────────────────────────────────────────────────────────────────

class WizardState {
  final DefinicaoProtocolo? protocol;

  /// Fila plana de steps (pode ser expandida dinamicamente via branching/listas).
  final List<FlowStep> queue;

  /// Índice do step atual na fila.
  final int currentIndex;

  /// Respostas por [FlowStep.answerKey] → valor string.
  final Map<String, String> answers;

  /// Itens adicionados por listStepId → lista de registros.
  final Map<String, List<ListItemRecord>> lists;

  /// Ids de instâncias de material selecionados por refStepAnswerKey → lista.
  final Map<String, List<String>> refSelections;

  const WizardState({
    this.protocol,
    this.queue = const [],
    this.currentIndex = 0,
    this.answers = const {},
    this.lists = const {},
    this.refSelections = const {},
  });

  WizardState copyWith({
    DefinicaoProtocolo? protocol,
    List<FlowStep>? queue,
    int? currentIndex,
    Map<String, String>? answers,
    Map<String, List<ListItemRecord>>? lists,
    Map<String, List<String>>? refSelections,
  }) {
    return WizardState(
      protocol: protocol ?? this.protocol,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      lists: lists ?? this.lists,
      refSelections: refSelections ?? this.refSelections,
    );
  }

  FlowStep? get currentFlowStep =>
      (queue.isNotEmpty && currentIndex < queue.length) ? queue[currentIndex] : null;

  Step? get currentStep => currentFlowStep?.step;

  bool get isFinished => currentIndex >= queue.length;

  int get totalSteps => queue.length;
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class WizardStateController extends Notifier<WizardState> {
  @override
  WizardState build() => const WizardState();

  // ── Carregamento ────────────────────────────────────────────────────────────

  void loadProtocol(DefinicaoProtocolo protocol) {
    final initialQueue = protocol.blocos
        .expand((bloco) => bloco.steps)
        .map((step) => FlowStep(step: step))
        .toList();

    state = WizardState(
      protocol: protocol,
      queue: initialQueue,
      currentIndex: 0,
    );
  }

  // ── Navegação ────────────────────────────────────────────────────────────────

  /// Avança para o próximo step. Retorna false se o step atual for obrigatório
  /// e não tiver resposta.
  bool nextStep() {
    final flowStep = state.currentFlowStep;
    if (flowStep == null) return false;

    final step = flowStep.step;

    // Verificar obrigatoriedade
    if (_isRequired(step) && !state.answers.containsKey(flowStep.answerKey)) {
      return false;
    }

    if (state.currentIndex < state.queue.length) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
      return true;
    }
    return false;
  }

  void previousStep() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void goToStep(int index) {
    if (index >= 0 && index <= state.queue.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  // ── Respostas — campos simples ───────────────────────────────────────────────

  void answerCurrentStep(String value) {
    final flowStep = state.currentFlowStep;
    if (flowStep == null) return;

    final updated = Map<String, String>.from(state.answers);
    updated[flowStep.answerKey] = value;
    state = state.copyWith(answers: updated);
  }

  // ── Branching — StepSelecaoRamo ──────────────────────────────────────────────

  /// Registra a escolha de um ramo e injeta os sub-steps do ramo logo após
  /// a posição atual na fila.
  void chooseRamo(String ramoId) {
    final flowStep = state.currentFlowStep;
    if (flowStep == null) return;
    if (flowStep.step.whichConteudo() != Step_Conteudo.selecaoRamo) return;

    final ramos = flowStep.step.selecaoRamo.ramos;
    final ramo = ramos.cast<Ramo?>().firstWhere(
      (r) => r?.id == ramoId,
      orElse: () => null,
    );
    if (ramo == null) return;

    // Registrar escolha
    final updated = Map<String, String>.from(state.answers);
    updated[flowStep.answerKey] = ramoId;

    // Construir sub-steps do ramo
    final ramoSteps = ramo.steps.map((s) => FlowStep(
          step: s,
          listStepId: flowStep.listStepId,
          listItemId: flowStep.listItemId,
        )).toList();

    // Injetar na posição seguinte
    final newQueue = List<FlowStep>.from(state.queue);
    newQueue.insertAll(state.currentIndex + 1, ramoSteps);

    state = state.copyWith(
      queue: newQueue,
      answers: updated,
      currentIndex: state.currentIndex + 1, // avança para o primeiro sub-step
    );
  }

  // ── Listas — StepListaAcoes ──────────────────────────────────────────────────

  /// Adiciona um novo item de lista do tipo [tipoId], injeta os steps do tipo
  /// na fila logo após o step de lista atual, e avança para o primeiro sub-step.
  void addListItem({
    required String listStepId,
    required TipoAcao tipo,
  }) {
    final itemId = _generateId();
    final record = ListItemRecord(
      id: itemId,
      tipoId: tipo.id,
      tipoLabel: tipo.label,
      tipoIconName: tipo.iconName,
    );

    // Atualizar mapa de listas
    final updatedLists = Map<String, List<ListItemRecord>>.from(state.lists);
    updatedLists[listStepId] = [...(updatedLists[listStepId] ?? []), record];

    // Injetar sub-steps do tipo na posição seguinte
    final tipoSteps = tipo.steps.map((s) => FlowStep(
          step: s,
          listStepId: listStepId,
          listItemId: itemId,
        )).toList();

    final newQueue = List<FlowStep>.from(state.queue);
    newQueue.insertAll(state.currentIndex + 1, tipoSteps);

    state = state.copyWith(
      queue: newQueue,
      lists: updatedLists,
      currentIndex: state.currentIndex + 1, // entra no sub-fluxo
    );
  }

  // ── Referências de materiais — StepRefMateriais ──────────────────────────────

  /// Atualiza a lista de ids de materiais selecionados para o step atual.
  void setRefMateriais(List<String> selectedIds) {
    final flowStep = state.currentFlowStep;
    if (flowStep == null) return;

    final updated = Map<String, List<String>>.from(state.refSelections);
    updated[flowStep.answerKey] = selectedIds;

    // Também marca uma resposta genérica para checagem de obrigatoriedade
    final updatedAnswers = Map<String, String>.from(state.answers);
    updatedAnswers[flowStep.answerKey] = selectedIds.join(',');

    state = state.copyWith(
      refSelections: updated,
      answers: updatedAnswers,
    );
  }

  /// Retorna os itens da lista referenciada por um [StepRefMateriais].
  List<ListItemRecord> getMaterialItems(String idStepMateriais) {
    return state.lists[idStepMateriais] ?? [];
  }

  // ── Utilitários ──────────────────────────────────────────────────────────────

  bool _isRequired(Step step) {
    return switch (step.whichConteudo()) {
      Step_Conteudo.campoSimples  => step.campoSimples.obrigatorio,
      Step_Conteudo.selecaoRamo   => step.selecaoRamo.obrigatorio,
      Step_Conteudo.refMateriais  => step.refMateriais.obrigatorio,
      Step_Conteudo.listaAcoes    => step.listaAcoes.minimo > 0,
      Step_Conteudo.instrucao     => false, // nunca bloqueia
      Step_Conteudo.notSet        => false,
      _ => false,
    };
  }

  /// Gera um ID único simples baseado no timestamp + contador.
  static int _idCounter = 0;
  static String _generateId() {
    _idCounter++;
    return '${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }
}

final wizardControllerProvider =
    NotifierProvider<WizardStateController, WizardState>(() {
  return WizardStateController();
});
