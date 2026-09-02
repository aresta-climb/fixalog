import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:fixnum/fixnum.dart';
import '../../../core/services/session_bundle_manager.dart';
import '../../../core/services/protocol_parser.dart';
import 'package:isar_community/isar.dart';
import '../../../core/models/local/submission_record.dart';
import '../../identity/viewmodels/identity_form_view_model.dart' show isarProvider;
import '../../../core/models/proto/protos/wizard.pb.dart';
import '../../../core/models/proto/protos/registro.pb.dart';

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
  final String sessionId;
  final DefinicaoProtocolo? protocol;
  final String protocolRawYaml;

  /// Fila de cards (FlowStep). Pode crescer dinamicamente via chooseRamo.
  final List<FlowStep> queue;

  /// Índice do card atual na fila.
  final int currentIndex;

  /// Respostas keyed por ConteudoStep.id.
  /// Para conteúdos dentro de itens de lista: "${conteudoId}__${listItemId}".
  final Map<String, Resposta> answers;

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

  /// Indica se houve alteração nos dados do formulário desde o carregamento ou última geração de relatório.
  final bool possuiAlteracoesPendentes;

  const WizardState({
    this.sessionId = '',
    this.protocol,
    this.protocolRawYaml = '',
    this.queue = const [],
    this.currentIndex = 0,
    this.answers = const {},
    this.lists = const {},
    this.expandedListItems = const {},
    this.refSelections = const {},
    this.ramoInjectedStepIds = const {},
    this.possuiAlteracoesPendentes = false,
  });

  WizardState copyWith({
    String? sessionId,
    DefinicaoProtocolo? protocol,
    String? protocolRawYaml,
    List<FlowStep>? queue,
    int? currentIndex,
    Map<String, Resposta>? answers,
    Map<String, List<ListItemRecord>>? lists,
    Map<String, String?>? expandedListItems,
    Map<String, List<String>>? refSelections,
    Map<String, List<String>>? ramoInjectedStepIds,
    bool? possuiAlteracoesPendentes,
  }) {
    return WizardState(
      sessionId: sessionId ?? this.sessionId,
      protocol: protocol ?? this.protocol,
      protocolRawYaml: protocolRawYaml ?? this.protocolRawYaml,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      lists: lists ?? this.lists,
      expandedListItems: expandedListItems ?? this.expandedListItems,
      refSelections: refSelections ?? this.refSelections,
      ramoInjectedStepIds: ramoInjectedStepIds ?? this.ramoInjectedStepIds,
      possuiAlteracoesPendentes:
          possuiAlteracoesPendentes ?? this.possuiAlteracoesPendentes,
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
  Timer? _autoSaveTimer;

  @override
  WizardState build() {
    ref.onDispose(() {
      _autoSaveTimer?.cancel();
    });
    return const WizardState();
  }

  void _scheduleAutoSave({bool immediate = false}) {
    _autoSaveTimer?.cancel();
    if (immediate) {
      saveSession().catchError((_) => '');
    } else {
      _autoSaveTimer = Timer(const Duration(milliseconds: 400), () {
        saveSession().catchError((_) => '');
      });
    }
  }

  Future<void> flushAutoSave() async {
    _autoSaveTimer?.cancel();
    if (state.protocol != null && state.sessionId.isNotEmpty) {
      await saveSession();
    }
  }

  /// Marca que o estado atual foi salvo/gerado e não possui alterações pendentes.
  void marcarComoSalvo() {
    state = state.copyWith(possuiAlteracoesPendentes: false);
  }

  // ── Carregamento ────────────────────────────────────────────────────────────

  void loadProtocol(DefinicaoProtocolo protocol, {String rawYaml = ''}) {
    final queue = protocol.blocos
        .expand((b) => b.steps)
        .map((s) => FlowStep(step: s))
        .toList();

    state = WizardState(
      sessionId: const Uuid().v4(),
      protocol: protocol,
      protocolRawYaml: rawYaml,
      queue: queue,
      currentIndex: 0,
      possuiAlteracoesPendentes: true,
    );
    _scheduleAutoSave(immediate: true);
  }

  Future<void> loadSession(String sessionId) async {
    final sessionManager = ref.read(sessionBundleManagerProvider);
    final bytes = await sessionManager.readManifest(sessionId: sessionId);
    final registro = Registro.fromBuffer(bytes);

    final yamlStr = registro.yamlConteudo;
    if (yamlStr.isEmpty) {
      throw Exception("O registro antigo não contém o YAML original salvo. Não é possível recriar a interface.");
    }

    final protocol = ProtocolParser.fromYaml(yamlStr);
    
    final queue = protocol.blocos
        .expand((b) => b.steps)
        .map((s) => FlowStep(step: s))
        .toList();

    // Reconstruct lists map from GrupoRepetido
    final reconstructedLists = <String, List<ListItemRecord>>{};
    
    // We need to find the labels/icons for each list item from the protocol definition
    for (final grupo in registro.listas) {
      final listId = grupo.idLista;
      final tipoId = grupo.idTipo;
      
      // Find the StepListaAcoes in the protocol that matches listId
      StepListaAcoes? stepLista;
      for (final bloco in protocol.blocos) {
        for (final step in bloco.steps) {
          for (final conteudo in step.conteudos) {
            if (conteudo.id == listId && conteudo.hasListaAcoes()) {
              stepLista = conteudo.listaAcoes;
              break;
            }
          }
        }
      }
      
      if (stepLista != null) {
        // Find the TipoAcao
        final tipoAcao = stepLista.tiposDisponiveis.firstWhere(
          (t) => t.id == tipoId,
          orElse: () => TipoAcao()..id = tipoId..label = 'Item'..iconName = 'list',
        );
        
        final record = ListItemRecord(
          id: grupo.idItem,
          tipoId: tipoId,
          tipoLabel: tipoAcao.label,
          tipoIconName: tipoAcao.iconName,
          tipo: tipoAcao,
        );
        
        reconstructedLists.putIfAbsent(listId, () => []).add(record);
      }
    }

    // Flatten all answers
    final allAnswers = <String, Resposta>{};
    allAnswers.addAll(registro.respostas);
    
    for (final grupo in registro.listas) {
      for (final entry in grupo.respostasItem.entries) {
        allAnswers['${entry.key}__${grupo.idItem}'] = entry.value;
      }
    }

    state = WizardState(
      sessionId: sessionId,
      protocol: protocol,
      protocolRawYaml: yamlStr,
      queue: queue,
      currentIndex: 0,
      answers: allAnswers,
      lists: reconstructedLists,
      possuiAlteracoesPendentes: false,
    );
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
  void answerConteudo(String conteudoId, Resposta value) {
    final updated = Map<String, Resposta>.from(state.answers)
      ..[conteudoId] = value;
    state = state.copyWith(answers: updated, possuiAlteracoesPendentes: true);
    _scheduleAutoSave(immediate: false);
  }

  /// Registra uma resposta em string (utilitário para UI) e tenta converter se necessário,
  /// assumindo texto como default. Para tipos específicos UI deve usar answerConteudo direto.
  void answerConteudoString(String conteudoId, String value) {
    answerConteudo(conteudoId, Resposta(texto: value));
  }

  /// Registra uma resposta para um [ConteudoStep] dentro de um item de lista.
  void answerInlineConteudo(
    String conteudoId,
    Resposta value,
    String listItemId,
  ) {
    final key = '${conteudoId}__$listItemId';
    final updated = Map<String, Resposta>.from(state.answers)..[key] = value;
    state = state.copyWith(answers: updated, possuiAlteracoesPendentes: true);
    _scheduleAutoSave(immediate: false);
  }

  void answerInlineConteudoString(
    String conteudoId,
    String value,
    String listItemId,
  ) {
    answerInlineConteudo(conteudoId, Resposta(texto: value), listItemId);
  }

  // ── Mídias ───────────────────────────────────────────────────────────────────

  /// Salva uma mídia no SessionBundle, calcula o hash e já armazena como ReferenciaMidia.
  Future<void> saveMediaAnswerBytes(
    String conteudoId,
    Uint8List bytes,
    String extension,
    StepCampoSimples_TipoCampo tipo, {
    String? listItemId,
  }) async {
    final sessionManager = ref.read(sessionBundleManagerProvider);
    final mediaUuid = const Uuid().v4();
    final hash = sha256.convert(bytes).toString();

    await sessionManager.saveOriginalMedia(
      sessionId: state.sessionId,
      mediaUuid: mediaUuid,
      extension: extension,
      bytes: bytes,
    );

    final refMidia = ReferenciaMidia();
    final mimeExt = extension.replaceAll('.', '');
    if (tipo == StepCampoSimples_TipoCampo.IMAGE || tipo == StepCampoSimples_TipoCampo.SIGNATURE) {
      refMidia.imagem = ArquivoImagem(
        uuid: mediaUuid,
        hashOriginal: hash,
        tipoOriginal: 'image/$mimeExt',
      );
    } else if (tipo == StepCampoSimples_TipoCampo.VIDEO) {
      refMidia.video = ArquivoVideo(
        uuid: mediaUuid,
        hashOriginal: hash,
        tipoOriginal: 'video/$mimeExt',
      );
    }

    final key = listItemId != null ? '${conteudoId}__$listItemId' : conteudoId;
    final updated = Map<String, Resposta>.from(state.answers)..[key] = Resposta(midia: refMidia);
    state = state.copyWith(answers: updated, possuiAlteracoesPendentes: true);
    await saveSession(status: SubmissionStatus.emProgresso);
  }

  /// Lê o arquivo de mídia, salva no SessionBundle, calcula hash e armazena como ReferenciaMidia.
  Future<void> saveMediaAnswer(
    String conteudoId,
    String filePath,
    StepCampoSimples_TipoCampo tipo, {
    String? listItemId,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    final ext = p.extension(filePath);
    await saveMediaAnswerBytes(conteudoId, bytes, ext, tipo, listItemId: listItemId);
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

    // Registrar resposta (ramo selecionado é uma string)
    final updatedAnswers = Map<String, Resposta>.from(state.answers)
      ..[conteudoId] = Resposta(texto: ramoId);

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
      possuiAlteracoesPendentes: true,
    );
    _scheduleAutoSave(immediate: true);
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
      possuiAlteracoesPendentes: true,
    );
    _scheduleAutoSave(immediate: true);
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
    state = state.copyWith(
      expandedListItems: updatedExpanded,
      possuiAlteracoesPendentes: true,
    );
    _scheduleAutoSave(immediate: true);
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
      possuiAlteracoesPendentes: true,
    );
    _scheduleAutoSave(immediate: true);
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
    
    // Converte a lista de strings para uma lista de respostas em string
    final respostasLista = ListaRespostas(
      valores: selectedIds.map((id) => Resposta(texto: id)).toList()
    );
    
    final updatedAnswers = Map<String, Resposta>.from(state.answers)
      ..[key] = Resposta(lista: respostasLista);
      
    state = state.copyWith(
      refSelections: updatedRefs,
      answers: updatedAnswers,
      possuiAlteracoesPendentes: true,
    );
    _scheduleAutoSave(immediate: true);
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
        final chosenRamo = state.answers[key];
        final chosenRamoId = chosenRamo?.texto;
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

  // ── Persistência ──────────────────────────────────────────────────────────────

  Future<void>? _activeSaveFuture;

  /// Instancia o Registro Híbrido, persiste no disco
  /// através do SessionBundleManager e registra no Isar. Retorna o sessionId.
  Future<String> saveSession({String? status}) async {
    while (_activeSaveFuture != null) {
      try {
        await _activeSaveFuture;
      } catch (_) {}
    }
    final completer = Completer<void>();
    _activeSaveFuture = completer.future;
    try {
      final result = await _performSaveSession(status: status);
      return result;
    } finally {
      completer.complete();
      _activeSaveFuture = null;
    }
  }

  Future<String> _performSaveSession({String? status}) async {
    final sessionId = state.sessionId;
    final protocol = state.protocol;
    if (protocol == null || sessionId.isEmpty) return sessionId;

    SessionBundleManager sessionManager;
    try {
      sessionManager = ref.read(sessionBundleManagerProvider);
    } catch (_) {
      sessionManager = SessionBundleManager();
    }

    Isar? isar;
    try {
      isar = ref.read(isarProvider);
    } catch (_) {
      isar = null;
    }

    final finalAnswers = Map<String, Resposta>.from(state.answers);

    // 1. Construir o Registro unificado
    final registro = Registro(
      idSessao: sessionId,
      idProtocolo: protocol.id,
      versaoProtocolo: protocol.versao,
      utcTimestampInicio: Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      utcTimestampFim: Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000),
    );

    // 2. Separar flat root answers
    final rootAnswers = <String, Resposta>{};
    for (final entry in finalAnswers.entries) {
      if (!entry.key.contains('__')) {
        rootAnswers[entry.key] = entry.value;
      }
    }
    registro.respostas.addAll(rootAnswers);

    // Salvar o YAML no manifesto
    registro.yamlConteudo = state.protocolRawYaml;

    // 3. Mapear grupos repetidos para 'listas'
    for (final entry in state.lists.entries) {
      final listId = entry.key;
      for (final item in entry.value) {
        final grupo = GrupoRepetido(
          idLista: listId,
          idItem: item.id,
          idTipo: item.tipoId,
        );

        for (final ansEntry in finalAnswers.entries) {
          if (ansEntry.key.endsWith('__${item.id}')) {
            final pureKey = ansEntry.key.split('__')[0];
            grupo.respostasItem[pureKey] = ansEntry.value;
          }
        }
        registro.listas.add(grupo);
      }
    }

    // 4. Salvar binarypb e atualizar Isar
    final binarypb = registro.writeToBuffer();
    await sessionManager.saveManifest(sessionId: sessionId, binarypb: binarypb);

    if (isar != null) {
      final isarDb = isar;
      final sessionDir = await sessionManager.getSessionDirectory(sessionId);
      
      SubmissionRecord? existingRecord;
      try {
        existingRecord = await isarDb.submissionRecords.filter().idSessaoEqualTo(sessionId).findFirst();
      } catch (_) {}

      final record = existingRecord ?? SubmissionRecord();
      final String targetStatus;
      if (status != null) {
        targetStatus = status;
      } else if (existingRecord != null && existingRecord.isGerado && !state.possuiAlteracoesPendentes) {
        targetStatus = SubmissionStatus.gerado;
      } else {
        targetStatus = SubmissionStatus.emProgresso;
      }

      record
        ..idSessao = sessionId
        ..idProtocolo = protocol.id
        ..nomeProtocolo = protocol.nome
        ..dataInclusao = existingRecord?.dataInclusao ?? DateTime.now()
        ..hashAssinatura = existingRecord?.hashAssinatura ?? ''
        ..pdfPath = (targetStatus == SubmissionStatus.emProgresso ? '' : (existingRecord?.pdfPath ?? ''))
        ..protobufPath = p.join(sessionDir.path, 'registro.binarypb')
        ..status = targetStatus;

      await isarDb.writeTxn(() async {
        await isarDb.submissionRecords.put(record);
      });
    }

    return sessionId;
  }
}

final wizardControllerProvider =
    NotifierProvider<WizardStateController, WizardState>(
      WizardStateController.new,
    );
