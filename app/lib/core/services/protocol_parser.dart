// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../models/proto/protos/wizard.pb.dart';
import 'migrador_protocolo_registro.dart';

/// Converte um arquivo YAML de protocolo em um [DefinicaoProtocolo] proto,
/// aplicando opcionalmente o dicionário de localização (`i18n/<locale>/<id>.yaml`)
/// com fallback automático para Inglês (`en`).
class ProtocolParser {
  static final Map<String, Map<String, Map<String, dynamic>>> _cacheTraducoes =
      {};

  static const List<String> _idsProtocolosCatalogo = [
    'inspecao_visual',
    'manutencao',
    'abertura_vias',
    'registro_expresso',
    'cadastro_material',
  ];

  /// Limpa o cache em memória de dicionários de localização de protocolos.
  static void limparCacheTraducoes() {
    _cacheTraducoes.clear();
  }

  /// Pré-carrega em memória via `rootBundle` (ou sistema de arquivos local) os dicionários
  /// dos protocolos para o [codigoIdioma] informado e para o fallback `'en'`.
  static Future<void> garantirTraducoesCarregadas(String codigoIdioma) async {
    final idiomas = <String>{'en', codigoIdioma.trim().toLowerCase()};
    for (final lang in idiomas) {
      final porProtocolo = _cacheTraducoes.putIfAbsent(lang, () => {});
      for (final idProto in _idsProtocolosCatalogo) {
        if (porProtocolo.containsKey(idProto)) continue;
        final caminho = 'assets/protocols/i18n/$lang/$idProto.yaml';
        try {
          final conteudo = await rootBundle.loadString(caminho);
          porProtocolo[idProto] = carregarTraducoesYaml(conteudo);
        } catch (_) {
          final arq = File(caminho);
          if (arq.existsSync()) {
            porProtocolo[idProto] = carregarTraducoesYaml(
              arq.readAsStringSync(),
            );
          }
        }
      }
    }
  }

  /// Obtém sincronamente o dicionário de traduções de um protocolo [idProtocolo]
  /// para o [codigoIdioma] a partir do cache em memória ou do disco local.
  static Map<String, dynamic>? obterTraducoesLocais(
    String idProtocolo,
    String codigoIdioma,
  ) {
    final idCanonico = MigradorProtocoloRegistro.normalizarIdProtocolo(
      idProtocolo,
    );
    final lang = codigoIdioma.trim().toLowerCase();
    final porProtocolo = _cacheTraducoes.putIfAbsent(lang, () => {});
    if (porProtocolo.containsKey(idCanonico)) {
      return porProtocolo[idCanonico];
    }

    final arq = File('assets/protocols/i18n/$lang/$idCanonico.yaml');
    if (arq.existsSync()) {
      final mapa = carregarTraducoesYaml(arq.readAsStringSync());
      porProtocolo[idCanonico] = mapa;
      return mapa;
    }
    return null;
  }

  /// Converte um documento YAML de tradução de protocolo em um [Map<String, dynamic>].
  static Map<String, dynamic> carregarTraducoesYaml(String yamlTraducao) {
    final doc = loadYaml(yamlTraducao);
    if (doc is YamlMap) {
      return _converterYamlParaMapa(doc);
    }
    return const {};
  }

  static Map<String, dynamic> _converterYamlParaMapa(YamlMap yamlMap) {
    final resultado = <String, dynamic>{};
    for (final entry in yamlMap.entries) {
      final chave = entry.key.toString();
      final valor = entry.value;
      if (valor is YamlMap) {
        resultado[chave] = _converterYamlParaMapa(valor);
      } else {
        resultado[chave] = valor?.toString() ?? '';
      }
    }
    return resultado;
  }

  /// Analisa uma string YAML e retorna a estrutura [DefinicaoProtocolo] correspondente.
  ///
  /// Quando [codigoIdioma] ou [traducoes] são fornecidos, o parser aplica primeiro o
  /// dicionário base em Inglês (`en`) como fallback e, em seguida, sobrepõe as traduções
  /// do [codigoIdioma] e/ou do mapa [traducoes] explícito.
  static DefinicaoProtocolo fromYaml(
    String yamlContent, {
    Map<String, dynamic>? traducoes,
    String? codigoIdioma,
  }) {
    final doc = loadYaml(yamlContent) as YamlMap;
    final proto = doc['protocolo'] as YamlMap? ?? doc;
    final definicao = _parseDefinicaoProtocolo(proto);

    if (codigoIdioma != null || traducoes != null) {
      final fallbackEn = obterTraducoesLocais(definicao.id, 'en');
      if (fallbackEn != null) {
        _aplicarTraducoes(definicao, fallbackEn);
      }
      if (codigoIdioma != null && codigoIdioma.trim().toLowerCase() != 'en') {
        final mapaIdioma = obterTraducoesLocais(definicao.id, codigoIdioma);
        if (mapaIdioma != null) {
          _aplicarTraducoes(definicao, mapaIdioma);
        }
      }
      if (traducoes != null) {
        _aplicarTraducoes(definicao, traducoes);
      }
    }

    return definicao;
  }

  /// Resolve recursivamente o rótulo humano (`label` ou `titulo`) de um [ConteudoStep]
  /// pelo seu [idConteudo] dentro de um [DefinicaoProtocolo].
  static String? resolverRotuloConteudo(
    DefinicaoProtocolo protocolo,
    String idConteudo,
  ) {
    for (final bloco in protocolo.blocos) {
      final c = _buscarConteudoEmSteps(bloco.steps, idConteudo);
      if (c != null) {
        if (c.hasCampoSimples()) return c.campoSimples.label;
        if (c.hasInstrucao()) return c.instrucao.titulo;
        if (c.hasSelecaoRamo()) return c.selecaoRamo.label;
        if (c.hasListaAcoes()) return c.listaAcoes.label;
        if (c.hasRefMateriais()) return c.refMateriais.label;
      }
    }
    return null;
  }

  /// Resolve recursivamente o rótulo humano de uma opção (`DROPDOWN`) ou ramo (`selecao_ramo`)
  /// pelo [idConteudo] e [valorOpcao] dentro de um [DefinicaoProtocolo].
  static String? resolverRotuloOpcao(
    DefinicaoProtocolo protocolo,
    String idConteudo,
    String valorOpcao,
  ) {
    for (final bloco in protocolo.blocos) {
      final c = _buscarConteudoEmSteps(bloco.steps, idConteudo);
      if (c != null) {
        if (c.hasCampoSimples()) {
          for (final op in c.campoSimples.opcoes) {
            if (op.valor == valorOpcao) return op.label;
          }
        } else if (c.hasSelecaoRamo()) {
          for (final r in c.selecaoRamo.ramos) {
            if (r.id == valorOpcao) return r.label;
          }
        }
      }
    }
    return null;
  }

  static ConteudoStep? _buscarConteudoEmSteps(
    List<Step> steps,
    String idConteudo,
  ) {
    for (final step in steps) {
      for (final c in step.conteudos) {
        if (c.id == idConteudo) return c;
        if (c.hasSelecaoRamo()) {
          for (final r in c.selecaoRamo.ramos) {
            final achado = _buscarConteudoEmSteps(r.steps, idConteudo);
            if (achado != null) return achado;
          }
        } else if (c.hasListaAcoes()) {
          for (final t in c.listaAcoes.tiposDisponiveis) {
            final achado = _buscarConteudoEmSteps(t.steps, idConteudo);
            if (achado != null) return achado;
          }
        }
      }
    }
    return null;
  }

  static void _aplicarTraducoes(
    DefinicaoProtocolo proto,
    Map<String, dynamic> traducoes,
  ) {
    final protoMap = traducoes['protocolo'] as Map<String, dynamic>?;
    if (protoMap != null) {
      final nome = protoMap['nome']?.toString() ?? '';
      final desc = protoMap['descricao']?.toString() ?? '';
      if (nome.isNotEmpty) proto.nome = nome;
      if (desc.isNotEmpty) proto.descricao = desc;
    }

    final blocosMap = traducoes['blocos'] as Map<String, dynamic>?;
    final conteudosMap = traducoes['conteudos'] as Map<String, dynamic>?;
    final ramosMap = traducoes['ramos'] as Map<String, dynamic>?;
    final tiposMap = traducoes['tipos_acao'] as Map<String, dynamic>?;
    final opcoesMap = traducoes['opcoes'] as Map<String, dynamic>?;

    for (final bloco in proto.blocos) {
      final bTr = blocosMap?[bloco.id] as Map<String, dynamic>?;
      if (bTr != null) {
        final t = bTr['titulo']?.toString() ?? '';
        final st = bTr['subtitulo']?.toString() ?? '';
        if (t.isNotEmpty) bloco.titulo = t;
        if (st.isNotEmpty) bloco.subtitulo = st;
      }
      _traduzirSteps(
        bloco.steps,
        conteudosMap: conteudosMap,
        ramosMap: ramosMap,
        tiposMap: tiposMap,
        opcoesMap: opcoesMap,
      );
    }
  }

  static void _traduzirSteps(
    List<Step> steps, {
    required Map<String, dynamic>? conteudosMap,
    required Map<String, dynamic>? ramosMap,
    required Map<String, dynamic>? tiposMap,
    required Map<String, dynamic>? opcoesMap,
  }) {
    for (final step in steps) {
      for (final c in step.conteudos) {
        final cTr = conteudosMap?[c.id] as Map<String, dynamic>?;
        if (c.hasInstrucao() && cTr != null) {
          final t = cTr['titulo']?.toString() ?? '';
          final corpo = cTr['corpo']?.toString() ?? '';
          if (t.isNotEmpty) c.instrucao.titulo = t;
          if (corpo.isNotEmpty) c.instrucao.corpo = corpo;
        } else if (c.hasCampoSimples()) {
          if (cTr != null) {
            final l = cTr['label']?.toString() ?? '';
            final sl = cTr['sublabel']?.toString() ?? '';
            if (l.isNotEmpty) c.campoSimples.label = l;
            if (sl.isNotEmpty) c.campoSimples.sublabel = sl;
          }
          final opcoesLocais = cTr?['opcoes'] as Map<String, dynamic>?;
          for (final op in c.campoSimples.opcoes) {
            final opTr =
                (opcoesLocais?[op.valor] as Map<String, dynamic>?) ??
                (opcoesMap?[op.valor] as Map<String, dynamic>?);
            if (opTr != null) {
              final ol = opTr['label']?.toString() ?? '';
              final osl = opTr['sublabel']?.toString() ?? '';
              if (ol.isNotEmpty) op.label = ol;
              if (osl.isNotEmpty) op.sublabel = osl;
            }
          }
        } else if (c.hasSelecaoRamo()) {
          if (cTr != null) {
            final l = cTr['label']?.toString() ?? '';
            final sl = cTr['sublabel']?.toString() ?? '';
            if (l.isNotEmpty) c.selecaoRamo.label = l;
            if (sl.isNotEmpty) c.selecaoRamo.sublabel = sl;
          }
          for (final r in c.selecaoRamo.ramos) {
            final rTr = ramosMap?[r.id] as Map<String, dynamic>?;
            if (rTr != null) {
              final rl = rTr['label']?.toString() ?? '';
              final rsl = rTr['sublabel']?.toString() ?? '';
              if (rl.isNotEmpty) r.label = rl;
              if (rsl.isNotEmpty) r.sublabel = rsl;
            }
            _traduzirSteps(
              r.steps,
              conteudosMap: conteudosMap,
              ramosMap: ramosMap,
              tiposMap: tiposMap,
              opcoesMap: opcoesMap,
            );
          }
        } else if (c.hasListaAcoes()) {
          if (cTr != null) {
            final l = cTr['label']?.toString() ?? '';
            final sl = cTr['sublabel']?.toString() ?? '';
            if (l.isNotEmpty) c.listaAcoes.label = l;
            if (sl.isNotEmpty) c.listaAcoes.sublabel = sl;
          }
          for (final t in c.listaAcoes.tiposDisponiveis) {
            final tTr = tiposMap?[t.id] as Map<String, dynamic>?;
            if (tTr != null) {
              final tl = tTr['label']?.toString() ?? '';
              final tsl = tTr['sublabel']?.toString() ?? '';
              if (tl.isNotEmpty) t.label = tl;
              if (tsl.isNotEmpty) t.sublabel = tsl;
            }
            _traduzirSteps(
              t.steps,
              conteudosMap: conteudosMap,
              ramosMap: ramosMap,
              tiposMap: tiposMap,
              opcoesMap: opcoesMap,
            );
          }
        } else if (c.hasRefMateriais() && cTr != null) {
          final l = cTr['label']?.toString() ?? '';
          final sl = cTr['sublabel']?.toString() ?? '';
          if (l.isNotEmpty) c.refMateriais.label = l;
          if (sl.isNotEmpty) c.refMateriais.sublabel = sl;
        }
      }
    }
  }

  /// Normaliza o valor textual da versão do protocolo para um número inteiro sequencial positivo (`>= 1`).
  ///
  /// Strings em formato semver legado (como `"1.0.0"` ou `"2.1.0"`), strings vazias ou
  /// números menores que `1` são convertidos para a versão base `1`.
  static int extrairVersaoInteira(String versaoBruta) {
    final parsed = int.tryParse(versaoBruta.trim());
    if (parsed == null || parsed < 1) return 1;
    return parsed;
  }

  static DefinicaoProtocolo _parseDefinicaoProtocolo(YamlMap m) {
    return DefinicaoProtocolo(
      id: m['id'] as String? ?? '',
      nome: m['nome'] as String? ?? '',
      descricao: m['descricao'] as String? ?? '',
      versao: m['versao']?.toString() ?? '',
      blocos: (m['blocos'] as YamlList? ?? YamlList.wrap([]))
          .map(_parseBloco)
          .where((b) => b.steps.isNotEmpty),
    );
  }

  static Bloco _parseBloco(dynamic b) {
    final m = b as YamlMap;
    return Bloco(
      id: m['id'] as String? ?? '',
      titulo: m['titulo'] as String? ?? '',
      subtitulo: m['subtitulo'] as String? ?? '',
      steps: (m['steps'] as YamlList? ?? YamlList.wrap([]))
          .map(_parseStep)
          .where((s) => s.conteudos.isNotEmpty),
    );
  }

  // ─── Step (card) ─────────────────────────────────────────────────────────

  static bool _ehConteudoLegadoAssinatura(YamlMap m) {
    final id = m['id'] as String? ?? '';
    if (id == 'assinatura_instrucao' || id == 'mat_assinatura_instrucao') {
      return true;
    }
    final campoSimples = m['campo_simples'] as YamlMap?;
    return campoSimples != null && campoSimples['tipo'] == 'SIGNATURE';
  }

  static Step _parseStep(dynamic s) {
    final m = s as YamlMap;
    final id = m['id'] as String? ?? '';

    if (m.containsKey('conteudos')) {
      return Step(
        id: id,
        conteudos: (m['conteudos'] as YamlList)
            .where((c) => !_ehConteudoLegadoAssinatura(c as YamlMap))
            .map(_parseConteudoStep),
      );
    }

    return Step(id: id, conteudos: [_parseConteudoStep(m)]);
  }

  // ─── ConteudoStep ─────────────────────────────────────────────────────────

  static ConteudoStep _parseConteudoStep(dynamic s) {
    final m = s as YamlMap;
    final id = m['id'] as String? ?? '';

    if (m.containsKey('instrucao')) {
      return ConteudoStep(
        id: id,
        instrucao: _parseStepInstrucao(m['instrucao'] as YamlMap),
      );
    }
    if (m.containsKey('campo_simples')) {
      return ConteudoStep(
        id: id,
        campoSimples: _parseStepCampoSimples(m['campo_simples'] as YamlMap),
      );
    }
    if (m.containsKey('selecao_ramo')) {
      return ConteudoStep(
        id: id,
        selecaoRamo: _parseStepSelecaoRamo(m['selecao_ramo'] as YamlMap),
      );
    }
    if (m.containsKey('lista_acoes')) {
      return ConteudoStep(
        id: id,
        listaAcoes: _parseStepListaAcoes(m['lista_acoes'] as YamlMap),
      );
    }
    if (m.containsKey('ref_materiais')) {
      return ConteudoStep(
        id: id,
        refMateriais: _parseStepRefMateriais(m['ref_materiais'] as YamlMap),
      );
    }

    throw FormatException(
      'ConteudoStep "$id" não tem tipo reconhecido. '
      'Chaves encontradas: ${m.keys.toList()}',
    );
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
    'PERIGO' => StepInstrucao_NivelAlerta.PERIGO,
    _ => StepInstrucao_NivelAlerta.INFO,
  };

  static StepCampoSimples _parseStepCampoSimples(YamlMap m) {
    return StepCampoSimples(
      label: m['label'] as String? ?? '',
      sublabel: m['sublabel'] as String? ?? '',
      tipo: _parseTipoCampo(m['tipo'] as String?),
      uiHint: _parseUiHint(m['ui_hint'] as String?),
      obrigatorio: m['obrigatorio'] as bool? ?? false,
      opcoes: (m['opcoes'] as YamlList? ?? YamlList.wrap([])).map(
        _parseOpcaoCampo,
      ),
      preencherDataAtual: m['preencher_data_atual'] as bool? ?? false,
    );
  }

  static StepCampoSimples_TipoCampo _parseTipoCampo(String? s) => switch (s) {
    'NUMBER' => StepCampoSimples_TipoCampo.NUMBER,
    'DROPDOWN' => StepCampoSimples_TipoCampo.DROPDOWN,
    'IMAGE' => StepCampoSimples_TipoCampo.IMAGE,
    'BOOLEAN' => StepCampoSimples_TipoCampo.BOOLEAN,
    'GPS' => StepCampoSimples_TipoCampo.GPS,
    'VIDEO' => StepCampoSimples_TipoCampo.VIDEO,
    'DATE' => StepCampoSimples_TipoCampo.DATE,
    _ => StepCampoSimples_TipoCampo.TEXT,
  };

  static StepCampoSimples_UiHint _parseUiHint(String? s) => switch (s) {
    'LARGE_TILES' => StepCampoSimples_UiHint.LARGE_TILES,
    'CAMERA_ACTION' => StepCampoSimples_UiHint.CAMERA_ACTION,
    'TEXT_AREA' => StepCampoSimples_UiHint.TEXT_AREA,
    _ => StepCampoSimples_UiHint.DEFAULT,
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
      tiposDisponiveis:
          (m['tipos_disponiveis'] as YamlList? ?? YamlList.wrap([])).map(
            _parseTipoAcao,
          ),
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
      origemCatalogo: m['origem_catalogo'] as bool? ?? false,
    );
  }
}
