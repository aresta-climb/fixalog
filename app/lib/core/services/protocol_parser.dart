import 'package:yaml/yaml.dart';
import '../models/proto/protos/wizard.pb.dart';

/// Converte um arquivo YAML de protocolo em um [DefinicaoProtocolo] proto.
///
/// O YAML segue a DSL definida em wizard.proto.
///
/// **Formato canônico** (multi-conteúdo):
/// ```yaml
/// - id: "card_1"
///   conteudos:
///     - id: "c1"
///       instrucao: { titulo: "..." }
///     - id: "c2"
///       campo_simples: { label: "...", tipo: TEXT }
/// ```
///
/// **Formato shorthand** (retrocompatível — gera um único ConteudoStep):
/// ```yaml
/// - id: "card_1"
///   campo_simples: { label: "...", tipo: TEXT }
/// ```
/// Neste caso o ConteudoStep herda o mesmo id do Step pai.
class ProtocolParser {
  static DefinicaoProtocolo fromYaml(String yamlContent) {
    final doc = loadYaml(yamlContent) as YamlMap;
    final proto = doc['protocolo'] as YamlMap? ?? doc;
    return _parseDefinicaoProtocolo(proto);
  }

  static DefinicaoProtocolo _parseDefinicaoProtocolo(YamlMap m) {
    return DefinicaoProtocolo(
      id: m['id'] as String? ?? '',
      nome: m['nome'] as String? ?? '',
      descricao: m['descricao'] as String? ?? '',
      versao: m['versao'] as String? ?? '',
      blocos: (m['blocos'] as YamlList? ?? YamlList.wrap([])).map(_parseBloco),
    );
  }

  static Bloco _parseBloco(dynamic b) {
    final m = b as YamlMap;
    return Bloco(
      id: m['id'] as String? ?? '',
      titulo: m['titulo'] as String? ?? '',
      subtitulo: m['subtitulo'] as String? ?? '',
      steps: (m['steps'] as YamlList? ?? YamlList.wrap([])).map(_parseStep),
    );
  }

  // ─── Step (card) ─────────────────────────────────────────────────────────

  static Step _parseStep(dynamic s) {
    final m = s as YamlMap;
    final id = m['id'] as String? ?? '';

    // Formato canônico: conteudos explícitos
    if (m.containsKey('conteudos')) {
      return Step(
        id: id,
        conteudos: (m['conteudos'] as YamlList).map(_parseConteudoStep),
      );
    }

    // Formato shorthand: conteúdo direto no step — retrocompatível
    // O ConteudoStep herda o id do Step para manter refs existentes.
    final conteudo = _parseConteudoStepShorthand(id, m);
    if (conteudo != null) {
      return Step(id: id, conteudos: [conteudo]);
    }

    throw FormatException(
      'Step "$id" não tem conteúdo reconhecido. '
      'Chaves encontradas: ${m.keys.toList()}',
    );
  }

  // ─── ConteudoStep ─────────────────────────────────────────────────────────

  static ConteudoStep _parseConteudoStep(dynamic s) {
    final m = s as YamlMap;
    final id = m['id'] as String? ?? '';

    if (m.containsKey('instrucao')) {
      return ConteudoStep(id: id, instrucao: _parseStepInstrucao(m['instrucao'] as YamlMap));
    }
    if (m.containsKey('campo_simples')) {
      return ConteudoStep(id: id, campoSimples: _parseStepCampoSimples(m['campo_simples'] as YamlMap));
    }
    if (m.containsKey('selecao_ramo')) {
      return ConteudoStep(id: id, selecaoRamo: _parseStepSelecaoRamo(m['selecao_ramo'] as YamlMap));
    }
    if (m.containsKey('lista_acoes')) {
      return ConteudoStep(id: id, listaAcoes: _parseStepListaAcoes(m['lista_acoes'] as YamlMap));
    }
    if (m.containsKey('ref_materiais')) {
      return ConteudoStep(id: id, refMateriais: _parseStepRefMateriais(m['ref_materiais'] as YamlMap));
    }

    throw FormatException(
      'ConteudoStep "$id" não tem tipo reconhecido. '
      'Chaves encontradas: ${m.keys.toList()}',
    );
  }

  /// Retrocompatibilidade: lê o tipo de conteúdo diretamente do YamlMap do
  /// Step e devolve um [ConteudoStep] com o mesmo id do Step.
  static ConteudoStep? _parseConteudoStepShorthand(String stepId, YamlMap m) {
    if (m.containsKey('instrucao')) {
      return ConteudoStep(id: stepId, instrucao: _parseStepInstrucao(m['instrucao'] as YamlMap));
    }
    if (m.containsKey('campo_simples')) {
      return ConteudoStep(id: stepId, campoSimples: _parseStepCampoSimples(m['campo_simples'] as YamlMap));
    }
    if (m.containsKey('selecao_ramo')) {
      return ConteudoStep(id: stepId, selecaoRamo: _parseStepSelecaoRamo(m['selecao_ramo'] as YamlMap));
    }
    if (m.containsKey('lista_acoes')) {
      return ConteudoStep(id: stepId, listaAcoes: _parseStepListaAcoes(m['lista_acoes'] as YamlMap));
    }
    if (m.containsKey('ref_materiais')) {
      return ConteudoStep(id: stepId, refMateriais: _parseStepRefMateriais(m['ref_materiais'] as YamlMap));
    }
    return null;
  }

  // ─── Tipos de ConteudoStep ─────────────────────────────────────────────────

  static StepInstrucao _parseStepInstrucao(YamlMap m) {
    return StepInstrucao(
      titulo: m['titulo'] as String? ?? '',
      corpo: m['corpo'] as String? ?? '',
      iconName: m['icon_name'] as String? ?? '',
      nivelAlerta: _parseNivelAlerta(m['nivel_alerta'] as String?),
    );
  }

  static StepInstrucao_NivelAlerta _parseNivelAlerta(String? s) => switch (s) {
        'ATENCAO' => StepInstrucao_NivelAlerta.ATENCAO,
        'PERIGO'  => StepInstrucao_NivelAlerta.PERIGO,
        _         => StepInstrucao_NivelAlerta.INFO,
      };

  static StepCampoSimples _parseStepCampoSimples(YamlMap m) {
    return StepCampoSimples(
      label: m['label'] as String? ?? '',
      sublabel: m['sublabel'] as String? ?? '',
      tipo: _parseTipoCampo(m['tipo'] as String?),
      uiHint: _parseUiHint(m['ui_hint'] as String?),
      obrigatorio: m['obrigatorio'] as bool? ?? false,
      opcoes: (m['opcoes'] as YamlList? ?? YamlList.wrap([])).map(_parseOpcaoCampo),
    );
  }

  static StepCampoSimples_TipoCampo _parseTipoCampo(String? s) => switch (s) {
        'NUMBER'    => StepCampoSimples_TipoCampo.NUMBER,
        'DROPDOWN'  => StepCampoSimples_TipoCampo.DROPDOWN,
        'IMAGE'     => StepCampoSimples_TipoCampo.IMAGE,
        'BOOLEAN'   => StepCampoSimples_TipoCampo.BOOLEAN,
        'GPS'       => StepCampoSimples_TipoCampo.GPS,
        'VIDEO'     => StepCampoSimples_TipoCampo.VIDEO,
        'SIGNATURE' => StepCampoSimples_TipoCampo.SIGNATURE,
        'DATE'      => StepCampoSimples_TipoCampo.DATE,
        _           => StepCampoSimples_TipoCampo.TEXT,
      };

  static StepCampoSimples_UiHint _parseUiHint(String? s) => switch (s) {
        'LARGE_TILES'   => StepCampoSimples_UiHint.LARGE_TILES,
        'CAMERA_ACTION' => StepCampoSimples_UiHint.CAMERA_ACTION,
        'TEXT_AREA'     => StepCampoSimples_UiHint.TEXT_AREA,
        _               => StepCampoSimples_UiHint.DEFAULT,
      };

  static OpcaoCampo _parseOpcaoCampo(dynamic o) {
    final m = o as YamlMap;
    return OpcaoCampo(
      valor: m['valor'] as String? ?? '',
      label: m['label'] as String? ?? '',
      sublabel: m['sublabel'] as String? ?? '',
      iconName: m['icon_name'] as String? ?? '',
    );
  }

  static StepSelecaoRamo _parseStepSelecaoRamo(YamlMap m) {
    return StepSelecaoRamo(
      label: m['label'] as String? ?? '',
      sublabel: m['sublabel'] as String? ?? '',
      obrigatorio: m['obrigatorio'] as bool? ?? false,
      ramos: (m['ramos'] as YamlList? ?? YamlList.wrap([])).map(_parseRamo),
    );
  }

  static Ramo _parseRamo(dynamic r) {
    final m = r as YamlMap;
    return Ramo(
      id: m['id'] as String? ?? '',
      label: m['label'] as String? ?? '',
      sublabel: m['sublabel'] as String? ?? '',
      iconName: m['icon_name'] as String? ?? '',
      steps: (m['steps'] as YamlList? ?? YamlList.wrap([])).map(_parseStep),
    );
  }

  static StepListaAcoes _parseStepListaAcoes(YamlMap m) {
    return StepListaAcoes(
      label: m['label'] as String? ?? '',
      sublabel: m['sublabel'] as String? ?? '',
      minimo: m['minimo'] as int? ?? 0,
      maximo: m['maximo'] as int? ?? 0,
      tiposDisponiveis: (m['tipos_disponiveis'] as YamlList? ?? YamlList.wrap([])).map(_parseTipoAcao),
    );
  }

  static TipoAcao _parseTipoAcao(dynamic t) {
    final m = t as YamlMap;
    return TipoAcao(
      id: m['id'] as String? ?? '',
      label: m['label'] as String? ?? '',
      sublabel: m['sublabel'] as String? ?? '',
      iconName: m['icon_name'] as String? ?? '',
      steps: (m['steps'] as YamlList? ?? YamlList.wrap([])).map(_parseStep),
    );
  }

  static StepRefMateriais _parseStepRefMateriais(YamlMap m) {
    return StepRefMateriais(
      label: m['label'] as String? ?? '',
      sublabel: m['sublabel'] as String? ?? '',
      idStepMateriais: m['id_step_materiais'] as String? ?? '',
      obrigatorio: m['obrigatorio'] as bool? ?? false,
    );
  }
}
