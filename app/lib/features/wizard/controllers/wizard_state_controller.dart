// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:fixnum/fixnum.dart';
import '../../../core/services/session_bundle_manager.dart';
import '../../../core/services/protocol_parser.dart';
import '../../media/services/media_compressor_service.dart';
import '../../../core/models/local/submission_record.dart';
import '../../../core/services/banco_dados_local.dart';
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

/// Um passo ativo na fila de navegação principal do wizard.
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

  /// Respostas indexadas por ConteudoStep.id.
  /// Para conteúdos dentro de itens de lista: "${conteudoId}__${listItemId}".
  final Map<String, Resposta> answers;

  /// Itens de lista indexados por ConteudoStep.id (do StepListaAcoes)
  /// ou "${subListaConteudoId}__${parentItemId}" para sub-listas aninhadas.
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

  /// Quantidade de mídias em processamento assíncrono em segundo plano por chave de campo.
  final Map<String, int> processandoMidiasPorCampo;

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
    this.processandoMidiasPorCampo = const {},
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
    Map<String, int>? processandoMidiasPorCampo,
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
      processandoMidiasPorCampo:
          processandoMidiasPorCampo ?? this.processandoMidiasPorCampo,
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
      try {
        await saveSession();
      } catch (_) {}
    }
  }

  /// Marca que o estado atual foi salvo/gerado e não possui alterações pendentes.
  void marcarComoSalvo() {
    state = state.copyWith(possuiAlteracoesPendentes: false);
  }

  static String _formatarDataAtual() {
    final hoje = DateTime.now();
    return '${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';
  }

  static void _preencherDatasAtuaisNosSteps(
    List<Step> steps,
    Map<String, Resposta> targetAnswers, {
    String? listItemId,
  }) {
    final dataFormatada = _formatarDataAtual();
    for (final step in steps) {
      for (final conteudo in step.conteudos) {
        if (conteudo.hasCampoSimples() &&
            conteudo.campoSimples.preencherDataAtual) {
          final key = listItemId != null
              ? '${conteudo.id}__$listItemId'
              : conteudo.id;
          if (!targetAnswers.containsKey(key)) {
            targetAnswers[key] = Resposta(texto: dataFormatada);
          }
        } else if (listItemId != null && conteudo.hasSelecaoRamo()) {
          for (final ramo in conteudo.selecaoRamo.ramos) {
            _preencherDatasAtuaisNosSteps(
              ramo.steps,
              targetAnswers,
              listItemId: listItemId,
            );
          }
        }
      }
    }
  }

  static StepListaAcoes? _encontrarStepListaAcoes(
    DefinicaoProtocolo protocol,
    String pureListId,
  ) {
    for (final bloco in protocol.blocos) {
      final achado = _encontrarStepListaEmSteps(bloco.steps, pureListId);
      if (achado != null) return achado;
    }
    return null;
  }

  static StepListaAcoes? _encontrarStepListaEmSteps(
    List<Step> steps,
    String pureListId,
  ) {
    for (final step in steps) {
      for (final conteudo in step.conteudos) {
        if (conteudo.id == pureListId && conteudo.hasListaAcoes()) {
          return conteudo.listaAcoes;
        }
        if (conteudo.hasListaAcoes()) {
          for (final tipo in conteudo.listaAcoes.tiposDisponiveis) {
            final sub = _encontrarStepListaEmSteps(tipo.steps, pureListId);
            if (sub != null) return sub;
          }
        }
        if (conteudo.hasSelecaoRamo()) {
          for (final ramo in conteudo.selecaoRamo.ramos) {
            final sub = _encontrarStepListaEmSteps(ramo.steps, pureListId);
            if (sub != null) return sub;
          }
        }
      }
    }
    return null;
  }

  // ── Carregamento ────────────────────────────────────────────────────────────

  void loadProtocol(DefinicaoProtocolo protocol, {String rawYaml = ''}) {
    final allSteps = protocol.blocos.expand((b) => b.steps).toList();
    final queue = allSteps.map((s) => FlowStep(step: s)).toList();

    final initialAnswers = <String, Resposta>{};
    _preencherDatasAtuaisNosSteps(allSteps, initialAnswers);

    state = WizardState(
      sessionId: const Uuid().v4(),
      protocol: protocol,
      protocolRawYaml: rawYaml,
      queue: queue,
      currentIndex: 0,
      answers: initialAnswers,
      possuiAlteracoesPendentes: true,
    );
    _scheduleAutoSave(immediate: true);
  }

  Future<void> loadSession(String sessionId) async {
    final sessionManager = ref.read(sessionBundleManagerProvider);
    final bytes = await sessionManager.readManifest(sessionId: sessionId);
    final registro = Registro.fromBuffer(bytes);

    var yamlStr = registro.yamlConteudo;
    if (yamlStr.isEmpty) {
      throw Exception("O registro antigo não contém o YAML original salvo. Não é possível recriar a interface.");
    }

    if ((registro.idProtocolo == 'cadastro_material' ||
            registro.idProtocolo == 'manutencao_ferragens') &&
        (yamlStr.contains('SIGNATURE') ||
            yamlStr.contains('det_video') ||
            yamlStr.contains('tq_video') ||
            yamlStr.contains('Foto da Etapa / Detalhe') ||
            yamlStr.contains('Mídias da Etapa / Detalhe'))) {
      try {
        final caminhoAsset = 'assets/protocols/${registro.idProtocolo}.yaml';
        final arquivoLocal = File(caminhoAsset);
        if (arquivoLocal.existsSync()) {
          yamlStr = arquivoLocal.readAsStringSync();
        } else {
          yamlStr = await rootBundle.loadString(caminhoAsset);
        }
      } catch (_) {}
    }

    final protocol = ProtocolParser.fromYaml(yamlStr);

    final queue = protocol.blocos
        .expand((b) => b.steps)
        .map((s) => FlowStep(step: s))
        .toList();

    // Reconstrói o mapa de listas (incluindo sub-listas aninhadas) a partir de GrupoRepetido
    final reconstructedLists = <String, List<ListItemRecord>>{};

    for (final grupo in registro.listas) {
      final listId = grupo.idLista;
      final pureListId = listId.split('__').first;
      final tipoId = grupo.idTipo;

      final stepLista = _encontrarStepListaAcoes(protocol, pureListId);

      if (stepLista != null) {
        final tipoAcao = stepLista.tiposDisponiveis.firstWhere(
          (t) => t.id == tipoId,
          orElse: () => TipoAcao()
            ..id = tipoId
            ..label = 'Item'
            ..iconName = 'list',
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

    // Achata todas as respostas (ignorando chaves legadas de assinatura manuscrita)
    final allAnswers = <String, Resposta>{};
    allAnswers.addAll(registro.respostas);
    allAnswers.remove('assinatura_c');
    allAnswers.remove('mat_assinatura_c');

    for (final grupo in registro.listas) {
      for (final entry in grupo.respostasItem.entries) {
        allAnswers['${entry.key}__${grupo.idItem}'] = entry.value;
      }
    }

    // Reconstrói seleções de RefMateriais a partir de respostas com ListaRespostas de texto
    final reconstructedRefs = <String, List<String>>{};
    for (final entry in allAnswers.entries) {
      if (entry.value.hasLista()) {
        final textos = entry.value.lista.valores
            .where((v) => v.hasTexto() && v.texto.isNotEmpty)
            .map((v) => v.texto)
            .toList();
        if (textos.isNotEmpty) {
          reconstructedRefs[entry.key] = textos;
        }
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
      refSelections: reconstructedRefs,
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

  /// Extrai todas as [ReferenciaMidia] contidas em uma [Resposta], seja ela
  /// de mídia única (`resp.hasMidia()`) ou uma lista de mídias (`resp.hasLista()`).
  static List<ReferenciaMidia> extrairMidiasDeResposta(Resposta? resp) {
    if (resp == null) return const [];
    if (resp.hasMidia()) return [resp.midia];
    if (resp.hasLista()) {
      return resp.lista.valores
          .where((v) => v.hasMidia())
          .map((v) => v.midia)
          .toList();
    }
    return const [];
  }

  static Resposta _empacotarMidiasEmResposta(List<ReferenciaMidia> midias) {
    if (midias.length == 1) {
      return Resposta(midia: midias.first);
    }
    return Resposta(
      lista: ListaRespostas(
        valores: midias.map((m) => Resposta(midia: m)).toList(),
      ),
    );
  }

  void _definirProcessandoMidia(String key, int quantidade) {
    final atual = Map<String, int>.from(state.processandoMidiasPorCampo);
    if (quantidade <= 0) {
      atual.remove(key);
    } else {
      atual[key] = quantidade;
    }
    state = state.copyWith(processandoMidiasPorCampo: atual);
  }

  static Future<String> _calcularSha256Assincrono(Uint8List bytes) async {
    if (bytes.length > 65536) {
      return Isolate.run(() => sha256.convert(bytes).toString());
    }
    return sha256.convert(bytes).toString();
  }

  static Future<({Uint8List bytes, String hash})?> _lerArquivoECalcularHash(
    String filePath,
  ) async {
    final file = File(filePath);
    if (!file.existsSync()) return null;
    final length = file.lengthSync();
    if (length > 65536) {
      return Isolate.run(() {
        final b = File(filePath).readAsBytesSync();
        final h = sha256.convert(b).toString();
        return (bytes: b, hash: h);
      });
    }
    final bytes = file.readAsBytesSync();
    final hash = sha256.convert(bytes).toString();
    return (bytes: bytes, hash: hash);
  }

  void _dispararPreProcessamentoEmBackground({
    required SessionBundleManager sessionManager,
    required String sessionId,
    required String mediaUuid,
    required StepCampoSimples_TipoCampo tipo,
  }) {
    final mediaService = ref.read(mediaCompressorProvider);
    if (tipo == StepCampoSimples_TipoCampo.IMAGE) {
      unawaited(
        mediaService.comprimirImagemSessao(
          sessionManager: sessionManager,
          sessionId: sessionId,
          mediaUuid: mediaUuid,
        ),
      );
    } else if (tipo == StepCampoSimples_TipoCampo.VIDEO) {
      unawaited(
        mediaService.transcodificarVideoSessao(
          sessionManager: sessionManager,
          sessionId: sessionId,
          mediaUuid: mediaUuid,
        ),
      );
    }
  }

  /// Salva uma mídia no SessionBundle, calcula o hash e já armazena como ReferenciaMidia.
  Future<void> saveMediaAnswerBytes(
    String conteudoId,
    Uint8List bytes,
    String extension,
    StepCampoSimples_TipoCampo tipo, {
    String? listItemId,
  }) async {
    final key = listItemId != null ? '${conteudoId}__$listItemId' : conteudoId;
    _definirProcessandoMidia(key, 1);
    try {
      final sessionManager = ref.read(sessionBundleManagerProvider);
      final mediaUuid = const Uuid().v4();
      final hash = await _calcularSha256Assincrono(bytes);

      await sessionManager.saveOriginalMedia(
        sessionId: state.sessionId,
        mediaUuid: mediaUuid,
        extension: extension,
        bytes: bytes,
      );

      _dispararPreProcessamentoEmBackground(
        sessionManager: sessionManager,
        sessionId: state.sessionId,
        mediaUuid: mediaUuid,
        tipo: tipo,
      );

      final refMidia = ReferenciaMidia();
      final mimeExt = extension.replaceAll('.', '');
      if (tipo == StepCampoSimples_TipoCampo.IMAGE) {
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

      final atuais = extrairMidiasDeResposta(state.answers[key]);
      final novaResposta = _empacotarMidiasEmResposta([...atuais, refMidia]);
      final updated = Map<String, Resposta>.from(state.answers)
        ..[key] = novaResposta;
      final updatedProc = Map<String, int>.from(state.processandoMidiasPorCampo)
        ..remove(key);
      state = state.copyWith(
        answers: updated,
        processandoMidiasPorCampo: updatedProc,
        possuiAlteracoesPendentes: true,
      );
      await saveSession(status: SubmissionStatus.emProgresso);
    } finally {
      if (state.processandoMidiasPorCampo.containsKey(key)) {
        _definirProcessandoMidia(key, 0);
      }
    }
  }

  /// Lê o arquivo de mídia, salva no SessionBundle, calcula hash e armazena como ReferenciaMidia.
  Future<void> saveMediaAnswer(
    String conteudoId,
    String filePath,
    StepCampoSimples_TipoCampo tipo, {
    String? listItemId,
  }) async {
    await saveMultipleMediaAnswers(
      conteudoId,
      [(filePath: filePath, tipo: tipo)],
      listItemId: listItemId,
    );
  }

  /// Processa e salva múltiplas mídias em lote em segundo plano, atualizando
  /// [WizardState.processandoMidiasPorCampo] e persistindo a sessão uma única vez ao final.
  Future<void> saveMultipleMediaAnswers(
    String conteudoId,
    List<({String filePath, StepCampoSimples_TipoCampo tipo})> arquivos, {
    String? listItemId,
  }) async {
    if (arquivos.isEmpty) return;
    final key = listItemId != null ? '${conteudoId}__$listItemId' : conteudoId;
    _definirProcessandoMidia(key, arquivos.length);
    try {
      await Future<void>.delayed(Duration.zero);
      final sessionManager = ref.read(sessionBundleManagerProvider);
      final atuais = List<ReferenciaMidia>.from(
        extrairMidiasDeResposta(state.answers[key]),
      );
      var restantes = arquivos.length;

      for (final item in arquivos) {
        await Future<void>.delayed(Duration.zero);
        final lido = await _lerArquivoECalcularHash(item.filePath);
        if (lido == null) {
          restantes--;
          _definirProcessandoMidia(key, restantes);
          continue;
        }

        final mediaUuid = const Uuid().v4();
        final ext = p.extension(item.filePath);
        await sessionManager.saveOriginalMedia(
          sessionId: state.sessionId,
          mediaUuid: mediaUuid,
          extension: ext,
          bytes: lido.bytes,
        );

        _dispararPreProcessamentoEmBackground(
          sessionManager: sessionManager,
          sessionId: state.sessionId,
          mediaUuid: mediaUuid,
          tipo: item.tipo,
        );

        final refMidia = ReferenciaMidia();
        final mimeExt = ext.replaceAll('.', '');
        if (item.tipo == StepCampoSimples_TipoCampo.VIDEO) {
          refMidia.video = ArquivoVideo(
            uuid: mediaUuid,
            hashOriginal: lido.hash,
            tipoOriginal: 'video/$mimeExt',
          );
        } else {
          refMidia.imagem = ArquivoImagem(
            uuid: mediaUuid,
            hashOriginal: lido.hash,
            tipoOriginal: 'image/$mimeExt',
          );
        }

        atuais.add(refMidia);
        restantes--;

        final updatedAnswers = Map<String, Resposta>.from(state.answers)
          ..[key] = _empacotarMidiasEmResposta(atuais);
        final updatedProc =
            Map<String, int>.from(state.processandoMidiasPorCampo);
        if (restantes <= 0) {
          updatedProc.remove(key);
        } else {
          updatedProc[key] = restantes;
        }
        state = state.copyWith(
          answers: updatedAnswers,
          processandoMidiasPorCampo: updatedProc,
          possuiAlteracoesPendentes: true,
        );
      }

      await saveSession(status: SubmissionStatus.emProgresso);
    } finally {
      if (state.processandoMidiasPorCampo.containsKey(key)) {
        _definirProcessandoMidia(key, 0);
      }
    }
  }

  /// Salva um documento PDF original no SessionBundle (`<uuid>_original.pdf`),
  /// rasteriza suas páginas em WebP (`<uuid>_p1.webp` .. `<uuid>_pN.webp`),
  /// calcula os hashes SHA-256 e armazena como [ReferenciaMidia] com [ArquivoDocumento].
  Future<void> saveDocumentAnswerBytes(
    String conteudoId,
    Uint8List pdfBytes, {
    required String nomeOriginal,
    String? listItemId,
  }) async {
    final key = listItemId != null ? '${conteudoId}__$listItemId' : conteudoId;
    _definirProcessandoMidia(key, 1);
    try {
      final sessionManager = ref.read(sessionBundleManagerProvider);
      final mediaService = ref.read(mediaCompressorProvider);

      final docUuid = const Uuid().v4();
      final hashOriginal = await _calcularSha256Assincrono(pdfBytes);

      await sessionManager.saveOriginalMedia(
        sessionId: state.sessionId,
        mediaUuid: docUuid,
        extension: '.pdf',
        bytes: pdfBytes,
      );

      final paginasWebp = await mediaService.rasterizarDocumentoPdfSessao(
        sessionManager: sessionManager,
        sessionId: state.sessionId,
        mediaUuid: docUuid,
      );

      final hashesPaginas = <String>[];
      for (final arquivoPagina in paginasWebp) {
        if (arquivoPagina.existsSync()) {
          final bytesPagina = arquivoPagina.readAsBytesSync();
          hashesPaginas.add(await _calcularSha256Assincrono(bytesPagina));
        }
      }

      final refMidia = ReferenciaMidia(
        documento: ArquivoDocumento(
          uuid: docUuid,
          tipoOriginal: 'application/pdf',
          hashOriginal: hashOriginal,
          nomeOriginal: nomeOriginal,
          quantidadePaginas: hashesPaginas.length,
          hashesPaginasWebp: hashesPaginas,
        ),
      );

      final atuais = extrairMidiasDeResposta(state.answers[key]);
      final updated = Map<String, Resposta>.from(state.answers)
        ..[key] = _empacotarMidiasEmResposta([...atuais, refMidia]);
      final updatedProc = Map<String, int>.from(state.processandoMidiasPorCampo)
        ..remove(key);
      state = state.copyWith(
        answers: updated,
        processandoMidiasPorCampo: updatedProc,
        possuiAlteracoesPendentes: true,
      );
      await saveSession(status: SubmissionStatus.emProgresso);
    } finally {
      if (state.processandoMidiasPorCampo.containsKey(key)) {
        _definirProcessandoMidia(key, 0);
      }
    }
  }

  /// Remove uma mídia pelo índice [indice] da resposta associada a [conteudoId]
  /// (ou `${conteudoId}__$listItemId`) e persiste a sessão.
  Future<void> removerMidiaDaResposta(
    String conteudoId,
    int indice, {
    String? listItemId,
  }) async {
    final key = listItemId != null ? '${conteudoId}__$listItemId' : conteudoId;
    final atuais = List<ReferenciaMidia>.from(
      extrairMidiasDeResposta(state.answers[key]),
    );
    if (indice < 0 || indice >= atuais.length) return;
    atuais.removeAt(indice);

    final updated = Map<String, Resposta>.from(state.answers);
    if (atuais.isEmpty) {
      updated.remove(key);
    } else {
      updated[key] = _empacotarMidiasEmResposta(atuais);
    }
    state = state.copyWith(answers: updated, possuiAlteracoesPendentes: true);
    await saveSession(status: SubmissionStatus.emProgresso);
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
    _preencherDatasAtuaisNosSteps(ramo.steps, updatedAnswers);

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

    final updatedAnswers = Map<String, Resposta>.from(state.answers);
    _preencherDatasAtuaisNosSteps(
      tipo.steps,
      updatedAnswers,
      listItemId: itemId,
    );

    state = state.copyWith(
      lists: updatedLists,
      expandedListItems: updatedExpanded,
      answers: updatedAnswers,
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

  /// Remove um item da lista (e eventuais sub-listas aninhadas associadas ao item).
  void removeListItem(String listConteudoId, String itemId) {
    final items = List<ListItemRecord>.from(state.lists[listConteudoId] ?? [])
      ..removeWhere((i) => i.id == itemId);

    final updatedLists = Map<String, List<ListItemRecord>>.from(state.lists)
      ..[listConteudoId] = items
      ..removeWhere((k, _) => k.endsWith('__$itemId'));

    // Se o item removido estava expandido, limpa
    final updatedExpanded = Map<String, String?>.from(state.expandedListItems)
      ..removeWhere((k, _) => k.endsWith('__$itemId'));
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
    final previousIds = state.refSelections[key] ?? const <String>[];
    final recemSelecionados =
        selectedIds.where((id) => !previousIds.contains(id)).toList();

    if (recemSelecionados.isNotEmpty) {
      try {
        final banco = ref.read(bancoDadosLocalProvider);
        if (banco != null) {
          final agora = DateTime.now();
          for (final idMat in recemSelecionados) {
            final record = banco.obterSubmissaoPorIdSessaoSync(idMat);
            if (record != null && record.isMaterial) {
              record.dataUltimaSelecao = agora;
              banco.salvarSubmissaoSync(record);
            }
          }
        }
      } catch (_) {}
    }

    final updatedRefs = Map<String, List<String>>.from(state.refSelections)
      ..[key] = selectedIds;

    // Converte a lista de strings para uma lista de respostas em string
    final respostasLista = ListaRespostas(
      valores: selectedIds.map((id) => Resposta(texto: id)).toList(),
    );

    final updatedAnswers = Map<String, Resposta>.from(state.answers);
    if (selectedIds.isEmpty) {
      updatedAnswers.remove(key);
    } else {
      updatedAnswers[key] = Resposta(lista: respostasLista);
    }

    state = state.copyWith(
      refSelections: updatedRefs,
      answers: updatedAnswers,
      possuiAlteracoesPendentes: true,
    );
    _scheduleAutoSave(immediate: true);
  }

  /// Obtém todos os materiais concluídos do catálogo local ordenados por [dataUltimaSelecao] decrescente.
  List<ListItemRecord> obterMateriaisDoCatalogo() {
    try {
      final banco = ref.read(bancoDadosLocalProvider);
      if (banco == null) return [];
      final todos = banco.listarSubmissoesSync();
      final materiais = todos.where((r) => r.isMaterial && r.isGerado).toList();

      materiais.sort((a, b) {
        if (a.dataUltimaSelecao != null && b.dataUltimaSelecao != null) {
          final cmp = b.dataUltimaSelecao!.compareTo(a.dataUltimaSelecao!);
          if (cmp != 0) return cmp;
        } else if (a.dataUltimaSelecao != null) {
          return -1;
        } else if (b.dataUltimaSelecao != null) {
          return 1;
        }
        return b.dataInclusao.compareTo(a.dataInclusao);
      });

      return materiais.map((r) {
        final label = r.tituloExibicao.isNotEmpty
            ? r.tituloExibicao
            : (r.nomeProtocolo.isNotEmpty ? r.nomeProtocolo : 'Material');
        return ListItemRecord(
          id: r.idSessao,
          tipoId: 'material_catalogo',
          tipoLabel: label,
          tipoIconName: 'hardware',
          tipo: TipoAcao(
            id: 'material_catalogo',
            label: label,
            iconName: 'hardware',
          ),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Resolve a lista de itens disponíveis para um [StepRefMateriais],
  /// seja diretamente do catálogo local ou de um passo anterior da sessão.
  List<ListItemRecord> obterItensParaRefMateriais(StepRefMateriais refStep) {
    if (refStep.origemCatalogo) {
      return obterMateriaisDoCatalogo();
    }
    if (state.lists.containsKey(refStep.idStepMateriais)) {
      return state.lists[refStep.idStepMateriais]!;
    }
    final idsNoBloco1 = state.refSelections[refStep.idStepMateriais] ?? [];
    if (idsNoBloco1.isEmpty) return [];
    final catalogo = obterMateriaisDoCatalogo();
    final porId = {for (final item in catalogo) item.id: item};
    return idsNoBloco1
        .map(
          (id) =>
              porId[id] ??
              ListItemRecord(
                id: id,
                tipoId: 'material_catalogo',
                tipoLabel: id,
                tipoIconName: 'hardware',
                tipo: TipoAcao(
                  id: 'material_catalogo',
                  label: id,
                  iconName: 'hardware',
                ),
              ),
        )
        .toList();
  }

  List<ListItemRecord> getMaterialItems(String idStepMateriais) =>
      state.lists[idStepMateriais] ?? [];

  // ── Validação interna ─────────────────────────────────────────────────────────

  /// Verifica se todos os conteúdos obrigatórios do passo em [stepIndex] estão satisfeitos.
  bool isStepSatisfied(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= state.queue.length) return false;
    final step = state.queue[stepIndex].step;
    for (final conteudo in step.conteudos) {
      if (!_isConteudoSatisfied(conteudo)) return false;
    }
    return true;
  }

  /// Verifica se o passo em [stepIndex] pode ser interagido diretamente (é o passo atual,
  /// já foi concluído ou todos os passos anteriores já estão satisfeitos).
  bool podeAcessarStep(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= state.queue.length) return false;
    if (stepIndex <= state.currentIndex) return true;
    for (var i = 0; i < stepIndex; i++) {
      if (!isStepSatisfied(i)) return false;
    }
    return true;
  }

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
        !conteudo.refMateriais.obrigatorio ||
            ((state.refSelections[key]?.isNotEmpty ?? false) ||
                state.answers.containsKey(key)),
      ConteudoStep_Tipo.instrucao => true,
      _ => true,
    };
  }

  /// Validação recursiva dos conteúdos de um item inline (segue ramos escolhidos e sub-listas).
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
            ((state.refSelections[key]?.isNotEmpty ?? false) ||
                state.answers.containsKey(key));
      case ConteudoStep_Tipo.listaAcoes:
        return (state.lists[key]?.length ?? 0) >= conteudo.listaAcoes.minimo;
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
  /// através do SessionBundleManager e registra no banco local SQLite. Retorna o sessionId.
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

    BancoDadosLocal? banco;
    try {
      banco = ref.read(bancoDadosLocalProvider);
    } catch (_) {
      banco = null;
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

    // 3. Mapear grupos repetidos para 'listas' (incluindo sub-listas aninhadas)
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

    // 4. Salvar binarypb e atualizar banco local SQLite
    final binarypb = registro.writeToBuffer();
    await sessionManager.saveManifest(sessionId: sessionId, binarypb: binarypb);

    if (banco != null) {
      final bancoDb = banco;
      final sessionDir = await sessionManager.getSessionDirectory(sessionId);

      SubmissionRecord? existingRecord;
      try {
        existingRecord = await bancoDb.obterSubmissaoPorIdSessao(sessionId);
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

      final ehMaterial = protocol.id == 'cadastro_material';
      final tipoRegistro = ehMaterial
          ? SubmissionTipoRegistro.material
          : SubmissionTipoRegistro.manutencao;

      String tituloExtraido = '';
      for (final chaveTitulo in const ['mat_nome', 'via_nome', 'nome_via']) {
        final texto = finalAnswers[chaveTitulo]?.texto.trim() ?? '';
        if (texto.isNotEmpty) {
          tituloExtraido = texto;
          break;
        }
      }
      if (tituloExtraido.isEmpty) {
        tituloExtraido = (existingRecord != null && existingRecord.tituloExibicao.isNotEmpty)
            ? existingRecord.tituloExibicao
            : protocol.nome;
      }

      record
        ..idSessao = sessionId
        ..idProtocolo = protocol.id
        ..nomeProtocolo = protocol.nome
        ..tituloExibicao = tituloExtraido
        ..tipoRegistro = tipoRegistro
        ..dataInclusao = existingRecord?.dataInclusao ?? DateTime.now()
        ..dataUltimaSelecao = existingRecord?.dataUltimaSelecao
        ..hashAssinatura = existingRecord?.hashAssinatura ?? ''
        ..pdfPath = (targetStatus == SubmissionStatus.emProgresso ? '' : (existingRecord?.pdfPath ?? ''))
        ..protobufPath = p.join(sessionDir.path, 'registro.binarypb')
        ..status = targetStatus;

      await bancoDb.salvarSubmissao(record);
    }

    return sessionId;
  }
}

final wizardControllerProvider =
    NotifierProvider<WizardStateController, WizardState>(
      WizardStateController.new,
    );
