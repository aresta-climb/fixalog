import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/proto/protos/wizard.pb.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelos imutáveis de domínio
// ─────────────────────────────────────────────────────────────────────────────

/// Registro de uma instância adicionada numa [StepListaAcoes].
/// O campo [tipo] é mantido para validação e renderização inline.
class ListItemRecord {
  final String id;
  final String tipoId;
  final String tipoLabel;
  final String tipoIconName;
  final TipoAcao tipo;

  const ListItemRecord({
    required this.id,
    required this.tipoId,
    required this.tipoLabel,
    required this.tipoIconName,
    required this.tipo,
  });
}

/// Um passo activo na fila de navegação principal do wizard.
class FlowStep {
  final Step step;
  const FlowStep({required this.step});
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado imutável
// ─────────────────────────────────────────────────────────────────────────────

class WizardState {
  final DefinicaoProtocolo? protocol;

  /// Fila de cards (FlowStep). Pode crescer dinamicamente via chooseRamo.
  final List<FlowStep> queue;

  /// Índice do card atual na fila.
  final int currentIndex;

  /// Respostas keyed por ConteudoStep.id.
  /// Para conteúdos dentro de itens de lista: "${conteudoId}__${listItemId}".
  final Map<String, String> answers;

  /// Itens de lista keyed por ConteudoStep.id (do StepListaAcoes).
  final Map<String, List<ListItemRecord>> lists;

  /// Qual item está expandido (em edição) em cada lista.
  /// listConteudoId → listItemId | null (nenhum expandido).
  final Map<String, String?> expandedListItems;

  /// Seleções múltiplas de RefMateriais: conteudoId → ids selecionados.
  final Map<String, List<String>> refSelections;

  /// Rastreia quais Step.ids foram injetados por cada SelecaoRamo.
  /// ramoConteudoId → [stepIds injetados].
  /// Usado para remover steps ao re-escolher um ramo.
  final Map<String, List<String>> ramoInjectedStepIds;

  const WizardState({
    this.protocol,
    this.queue = const [],
    this.currentIndex = 0,
    this.answers = const {},
    this.lists = const {},
    this.expandedListItems = const {},
    this.refSelections = const {},
    this.ramoInjectedStepIds = const {},
  });

  WizardState copyWith({
    DefinicaoProtocolo? protocol,
    List<FlowStep>? queue,
    int? currentIndex,
    Map<String, String>? answers,
    Map<String, List<ListItemRecord>>? lists,
    Map<String, String?>? expandedListItems,
    Map<String, List<String>>? refSelections,
    Map<String, List<String>>? ramoInjectedStepIds,
  }) {
    return WizardState(
      protocol: protocol ?? this.protocol,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      lists: lists ?? this.lists,
      expandedListItems: expandedListItems ?? this.expandedListItems,
      refSelections: refSelections ?? this.refSelections,
      ramoInjectedStepIds: ramoInjectedStepIds ?? this.ramoInjectedStepIds,
    );
  }

  FlowStep? get currentFlowStep =>
      (queue.isNotEmpty && currentIndex < queue.length)
      ? queue[currentIndex]
      : null;

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
    final queue = protocol.blocos
        .expand((b) => b.steps)
        .map((s) => FlowStep(step: s))
        .toList();

    state = WizardState(protocol: protocol, queue: queue, currentIndex: 0);
  }

  // ── Navegação principal ──────────────────────────────────────────────────────

  /// Valida todos os ConteudoSteps obrigatórios do card atual e avança.
  /// Retorna false se algum conteúdo obrigatório estiver incompleto.
  bool nextStep() {
    final flowStep = state.currentFlowStep;
    if (flowStep == null) return false;

    for (final conteudo in flowStep.step.conteudos) {
      if (!_isConteudoSatisfied(conteudo)) return false;
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

  // ── Respostas — conteúdos do fluxo principal ─────────────────────────────────

  /// Registra uma resposta para um [ConteudoStep] no fluxo principal.
  void answerConteudo(String conteudoId, String value) {
    final updated = Map<String, String>.from(state.answers)
      ..[conteudoId] = value;
    state = state.copyWith(answers: updated);
  }

  /// Registra uma resposta para um [ConteudoStep] dentro de um item de lista.
  void answerInlineConteudo(
    String conteudoId,
    String value,
    String listItemId,
  ) {
    final key = '${conteudoId}__$listItemId';
    final updated = Map<String, String>.from(state.answers)..[key] = value;
    state = state.copyWith(answers: updated);
  }

  // ── SelecaoRamo — fluxo principal ────────────────────────────────────────────

  /// Registra a escolha de um ramo e injeta seus steps na fila APÓS o card
  /// atual. Se um ramo anterior já foi escolhido para este conteudo, os steps
  /// injetados por ele são removidos antes de injetar os novos.
  ///
  /// Não avança automaticamente — o avanço ocorre ao pressionar "Próximo".
  void chooseRamo(String conteudoId, String ramoId) {
    final flowStep = state.currentFlowStep;
    if (flowStep == null) return;

    // Encontrar o ConteudoStep de selecao_ramo com este id
    final conteudo = flowStep.step.conteudos.cast<ConteudoStep?>().firstWhere(
      (c) => c?.id == conteudoId,
      orElse: () => null,
    );
    if (conteudo == null || !conteudo.hasSelecaoRamo()) return;

    final ramo = conteudo.selecaoRamo.ramos.cast<Ramo?>().firstWhere(
      (r) => r?.id == ramoId,
      orElse: () => null,
    );
    if (ramo == null) return;

    // Remover steps injetados anteriormente por este conteudo
    final previousIds = state.ramoInjectedStepIds[conteudoId] ?? [];
    final newQueue = state.queue
        .where((fs) => !previousIds.contains(fs.step.id))
        .toList();

    // Registrar resposta
    final updatedAnswers = Map<String, String>.from(state.answers)
      ..[conteudoId] = ramoId;

    // Injetar sub-steps do ramo após o card atual
    final ramoFlowSteps = ramo.steps.map((s) => FlowStep(step: s)).toList();
    final insertAt = state.currentIndex + 1;
    newQueue.insertAll(insertAt, ramoFlowSteps);

    // Rastrear ids injetados para possível substituição futura
    final updatedInjected = Map<String, List<String>>.from(
      state.ramoInjectedStepIds,
    )..[conteudoId] = ramo.steps.map((s) => s.id).toList();

    state = state.copyWith(
      queue: newQueue,
      answers: updatedAnswers,
      ramoInjectedStepIds: updatedInjected,
    );
    // Não avança — o card pode ter outros conteudos a preencher
  }

  // ── ListaAcoes — card-within-card ────────────────────────────────────────────

  /// Adiciona um novo item à lista e o expande para edição inline.
  void addListItem({required String listConteudoId, required TipoAcao tipo}) {
    final itemId = _generateId();
    final record = ListItemRecord(
      id: itemId,
      tipoId: tipo.id,
      tipoLabel: tipo.label,
      tipoIconName: tipo.iconName,
      tipo: tipo,
    );

    final updatedLists = Map<String, List<ListItemRecord>>.from(state.lists);
    updatedLists[listConteudoId] = [
      ...(updatedLists[listConteudoId] ?? []),
      record,
    ];

    final updatedExpanded = Map<String, String?>.from(state.expandedListItems)
      ..[listConteudoId] = itemId;

    state = state.copyWith(
      lists: updatedLists,
      expandedListItems: updatedExpanded,
    );
  }

  /// Valida os conteúdos do item e, se completo, o colapsa.
  /// Retorna false se algum conteúdo obrigatório estiver incompleto.
  bool confirmListItem(String listConteudoId, String itemId) {
    final items = state.lists[listConteudoId] ?? [];
    final item = items.cast<ListItemRecord?>().firstWhere(
      (i) => i?.id == itemId,
      orElse: () => null,
    );
    if (item == null) return false;

    if (!_validateInlineSteps(item.tipo.steps, itemId)) return false;

    final updatedExpanded = Map<String, String?>.from(state.expandedListItems)
      ..[listConteudoId] = null;
    state = state.copyWith(expandedListItems: updatedExpanded);
    return true;
  }

  /// Re-expande um item de lista para edição.
  void expandListItem(String listConteudoId, String itemId) {
    final updatedExpanded = Map<String, String?>.from(state.expandedListItems)
      ..[listConteudoId] = itemId;
    state = state.copyWith(expandedListItems: updatedExpanded);
  }

  /// Remove um item da lista.
  void removeListItem(String listConteudoId, String itemId) {
    final items = List<ListItemRecord>.from(state.lists[listConteudoId] ?? [])
      ..removeWhere((i) => i.id == itemId);

    final updatedLists = Map<String, List<ListItemRecord>>.from(state.lists)
      ..[listConteudoId] = items;

    // Se o item removido estava expandido, limpa
    final updatedExpanded = Map<String, String?>.from(state.expandedListItems);
    if (updatedExpanded[listConteudoId] == itemId) {
      updatedExpanded[listConteudoId] = null;
    }

    state = state.copyWith(
      lists: updatedLists,
      expandedListItems: updatedExpanded,
    );
  }

  // ── RefMateriais ──────────────────────────────────────────────────────────────

  void setRefMateriais(
    String conteudoId,
    List<String> selectedIds, {
    String? listItemId,
  }) {
    final key = listItemId != null ? '${conteudoId}__$listItemId' : conteudoId;
    final updatedRefs = Map<String, List<String>>.from(state.refSelections)
      ..[key] = selectedIds;
    final updatedAnswers = Map<String, String>.from(state.answers)
      ..[key] = selectedIds.join(',');
    state = state.copyWith(refSelections: updatedRefs, answers: updatedAnswers);
  }

  List<ListItemRecord> getMaterialItems(String idStepMateriais) =>
      state.lists[idStepMateriais] ?? [];

  // ── Validação interna ─────────────────────────────────────────────────────────

  bool _isConteudoSatisfied(ConteudoStep conteudo) {
    final key = conteudo.id;
    return switch (conteudo.whichTipo()) {
      ConteudoStep_Tipo.campoSimples =>
        !conteudo.campoSimples.obrigatorio || state.answers.containsKey(key),
      ConteudoStep_Tipo.selecaoRamo =>
        !conteudo.selecaoRamo.obrigatorio || state.answers.containsKey(key),
      ConteudoStep_Tipo.listaAcoes =>
        (state.lists[key]?.length ?? 0) >= conteudo.listaAcoes.minimo,
      ConteudoStep_Tipo.refMateriais =>
        !conteudo.refMateriais.obrigatorio || state.answers.containsKey(key),
      ConteudoStep_Tipo.instrucao => true,
      _ => true,
    };
  }

  /// Validação recursiva dos conteúdos de um item inline (segue ramos escolhidos).
  bool _validateInlineSteps(List<Step> steps, String itemId) {
    for (final step in steps) {
      for (final conteudo in step.conteudos) {
        if (!_isInlineConteudoSatisfied(conteudo, itemId)) return false;
      }
    }
    return true;
  }

  bool _isInlineConteudoSatisfied(ConteudoStep conteudo, String itemId) {
    final key = '${conteudo.id}__$itemId';
    switch (conteudo.whichTipo()) {
      case ConteudoStep_Tipo.campoSimples:
        return !conteudo.campoSimples.obrigatorio ||
            state.answers.containsKey(key);
      case ConteudoStep_Tipo.refMateriais:
        return !conteudo.refMateriais.obrigatorio ||
            state.answers.containsKey(key);
      case ConteudoStep_Tipo.selecaoRamo:
        if (conteudo.selecaoRamo.obrigatorio &&
            !state.answers.containsKey(key)) {
          return false;
        }
        // Valida recursivamente o ramo escolhido
        final chosenRamoId = state.answers[key];
        if (chosenRamoId != null) {
          final ramo = conteudo.selecaoRamo.ramos.cast<Ramo?>().firstWhere(
            (r) => r?.id == chosenRamoId,
            orElse: () => null,
          );
          if (ramo != null && !_validateInlineSteps(ramo.steps, itemId)) {
            return false;
          }
        }
        return true;
      case ConteudoStep_Tipo.instrucao:
      case ConteudoStep_Tipo.listaAcoes:
      default:
        return true;
    }
  }

  // ── Utilitários ───────────────────────────────────────────────────────────────

  static int _idCounter = 0;
  static String _generateId() {
    _idCounter++;
    return '${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }
}

final wizardControllerProvider =
    NotifierProvider<WizardStateController, WizardState>(
      WizardStateController.new,
    );
