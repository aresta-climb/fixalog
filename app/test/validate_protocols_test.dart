// test/validate_protocols_test.dart
//
// Testa que todos os protocolos YAML em assets/protocols/ são válidos segundo
// o schema definido em wizard.proto e podem ser serializados em .binarypb.
//
// Uso: flutter test test/validate_protocols_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:app/core/models/proto/protos/wizard.pb.dart';
import 'package:app/core/models/proto/protos/wizard.pbenum.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Parser: YAML → DefinicaoProtocolo
//
// O YAML usa snake_case e tem um wrapper raiz 'protocolo:'.
// Esta função converte recursivamente o mapa YAML para as classes proto geradas.
// ─────────────────────────────────────────────────────────────────────────────

DefinicaoProtocolo parseYamlToProto(String yamlContent) {
  final doc = loadYaml(yamlContent) as YamlMap;
  final proto = doc['protocolo'] as YamlMap? ?? doc;
  return _parseDefinicaoProtocolo(proto);
}

DefinicaoProtocolo _parseDefinicaoProtocolo(YamlMap m) {
  return DefinicaoProtocolo(
    id: m['id'] as String? ?? '',
    nome: m['nome'] as String? ?? '',
    descricao: m['descricao'] as String? ?? '',
    versao: m['versao'] as String? ?? '',
    blocos: (m['blocos'] as YamlList? ?? YamlList.wrap([])).map(_parseBloco),
  );
}

Bloco _parseBloco(dynamic b) {
  final m = b as YamlMap;
  return Bloco(
    id: m['id'] as String? ?? '',
    titulo: m['titulo'] as String? ?? '',
    subtitulo: m['subtitulo'] as String? ?? '',
    steps: (m['steps'] as YamlList? ?? YamlList.wrap([])).map(_parseStep),
  );
}

Step _parseStep(dynamic s) {
  final m = s as YamlMap;
  final id = m['id'] as String? ?? '';

  if (m.containsKey('instrucao')) {
    return Step(id: id, instrucao: _parseStepInstrucao(m['instrucao'] as YamlMap));
  }
  if (m.containsKey('campo_simples')) {
    return Step(id: id, campoSimples: _parseStepCampoSimples(m['campo_simples'] as YamlMap));
  }
  if (m.containsKey('selecao_ramo')) {
    return Step(id: id, selecaoRamo: _parseStepSelecaoRamo(m['selecao_ramo'] as YamlMap));
  }
  if (m.containsKey('lista_acoes')) {
    return Step(id: id, listaAcoes: _parseStepListaAcoes(m['lista_acoes'] as YamlMap));
  }
  if (m.containsKey('ref_materiais')) {
    return Step(id: id, refMateriais: _parseStepRefMateriais(m['ref_materiais'] as YamlMap));
  }

  throw FormatException('Step "$id" não tem um tipo reconhecido. '
      'Chaves encontradas: ${m.keys.toList()}');
}

StepInstrucao _parseStepInstrucao(YamlMap m) {
  return StepInstrucao(
    titulo: m['titulo'] as String? ?? '',
    corpo: m['corpo'] as String? ?? '',
    iconName: m['icon_name'] as String? ?? '',
    nivelAlerta: _parseNivelAlerta(m['nivel_alerta'] as String?),
  );
}

StepInstrucao_NivelAlerta _parseNivelAlerta(String? s) => switch (s) {
      'ATENCAO' => StepInstrucao_NivelAlerta.ATENCAO,
      'PERIGO'  => StepInstrucao_NivelAlerta.PERIGO,
      _         => StepInstrucao_NivelAlerta.INFO,
    };

StepCampoSimples _parseStepCampoSimples(YamlMap m) {
  return StepCampoSimples(
    label: m['label'] as String? ?? '',
    sublabel: m['sublabel'] as String? ?? '',
    tipo: _parseTipoCampo(m['tipo'] as String?),
    uiHint: _parseUiHint(m['ui_hint'] as String?),
    obrigatorio: m['obrigatorio'] as bool? ?? false,
    opcoes: (m['opcoes'] as YamlList? ?? YamlList.wrap([])).map(_parseOpcaoCampo),
  );
}

StepCampoSimples_TipoCampo _parseTipoCampo(String? s) => switch (s) {
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

StepCampoSimples_UiHint _parseUiHint(String? s) => switch (s) {
      'LARGE_TILES'   => StepCampoSimples_UiHint.LARGE_TILES,
      'CAMERA_ACTION' => StepCampoSimples_UiHint.CAMERA_ACTION,
      'TEXT_AREA'     => StepCampoSimples_UiHint.TEXT_AREA,
      _               => StepCampoSimples_UiHint.DEFAULT,
    };

OpcaoCampo _parseOpcaoCampo(dynamic o) {
  final m = o as YamlMap;
  return OpcaoCampo(
    valor: m['valor'] as String? ?? '',
    label: m['label'] as String? ?? '',
    sublabel: m['sublabel'] as String? ?? '',
    iconName: m['icon_name'] as String? ?? '',
  );
}

StepSelecaoRamo _parseStepSelecaoRamo(YamlMap m) {
  return StepSelecaoRamo(
    label: m['label'] as String? ?? '',
    sublabel: m['sublabel'] as String? ?? '',
    obrigatorio: m['obrigatorio'] as bool? ?? false,
    ramos: (m['ramos'] as YamlList? ?? YamlList.wrap([])).map(_parseRamo),
  );
}

Ramo _parseRamo(dynamic r) {
  final m = r as YamlMap;
  return Ramo(
    id: m['id'] as String? ?? '',
    label: m['label'] as String? ?? '',
    sublabel: m['sublabel'] as String? ?? '',
    iconName: m['icon_name'] as String? ?? '',
    // Recursão: sub-fluxo de cada ramo pode conter qualquer tipo de step
    steps: (m['steps'] as YamlList? ?? YamlList.wrap([])).map(_parseStep),
  );
}

StepListaAcoes _parseStepListaAcoes(YamlMap m) {
  return StepListaAcoes(
    label: m['label'] as String? ?? '',
    sublabel: m['sublabel'] as String? ?? '',
    minimo: m['minimo'] as int? ?? 0,
    maximo: m['maximo'] as int? ?? 0,
    tiposDisponiveis: (m['tipos_disponiveis'] as YamlList? ?? YamlList.wrap([]))
        .map(_parseTipoAcao),
  );
}

TipoAcao _parseTipoAcao(dynamic t) {
  final m = t as YamlMap;
  return TipoAcao(
    id: m['id'] as String? ?? '',
    label: m['label'] as String? ?? '',
    sublabel: m['sublabel'] as String? ?? '',
    iconName: m['icon_name'] as String? ?? '',
    steps: (m['steps'] as YamlList? ?? YamlList.wrap([])).map(_parseStep),
  );
}

StepRefMateriais _parseStepRefMateriais(YamlMap m) {
  return StepRefMateriais(
    label: m['label'] as String? ?? '',
    sublabel: m['sublabel'] as String? ?? '',
    idStepMateriais: m['id_step_materiais'] as String? ?? '',
    obrigatorio: m['obrigatorio'] as bool? ?? false,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers para os testes
// ─────────────────────────────────────────────────────────────────────────────

List<File> _getProtocolFiles() {
  final dir = Directory('assets/protocols');
  return dir.listSync().whereType<File>().where((f) => f.path.endsWith('.yaml')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

void _collectRefMateriais(List<Step> steps, List<String> refs) {
  for (final s in steps) {
    switch (s.whichConteudo()) {
      case Step_Conteudo.refMateriais:
        refs.add(s.refMateriais.idStepMateriais);
      case Step_Conteudo.selecaoRamo:
        for (final ramo in s.selecaoRamo.ramos) {
          _collectRefMateriais(ramo.steps, refs);
        }
      case Step_Conteudo.listaAcoes:
        for (final tipo in s.listaAcoes.tiposDisponiveis) {
          _collectRefMateriais(tipo.steps, refs);
        }
      default:
        break;
    }
  }
}

Set<String> _collectListaStepIds(DefinicaoProtocolo proto) {
  final ids = <String>{};
  for (final bloco in proto.blocos) {
    for (final step in bloco.steps) {
      if (step.whichConteudo() == Step_Conteudo.listaAcoes) {
        ids.add(step.id);
      }
    }
  }
  return ids;
}

// ─────────────────────────────────────────────────────────────────────────────
// Suíte de testes
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. Parse e serialização de todos os YAMLs ───────────────────────────────

  group('Todos os protocolos YAML', () {
    test('assets/protocols/ contém pelo menos um arquivo .yaml', () {
      final files = _getProtocolFiles();
      expect(files, isNotEmpty, reason: 'Nenhum protocolo YAML encontrado em assets/protocols/');
    });

    test('todos os YAMLs parseiam como DefinicaoProtocolo sem erros', () {
      for (final file in _getProtocolFiles()) {
        final name = file.uri.pathSegments.last;
        final yaml = file.readAsStringSync();

        final proto = parseYamlToProto(yaml);

        expect(proto.id, isNotEmpty, reason: '$name: campo "id" vazio');
        expect(proto.versao, isNotEmpty, reason: '$name: campo "versao" vazio');
        expect(proto.blocos, isNotEmpty, reason: '$name: lista "blocos" vazia');
      }
    });

    test('todos os YAMLs serializam para binary protobuf (binarypb)', () {
      for (final file in _getProtocolFiles()) {
        final name = file.uri.pathSegments.last;
        final proto = parseYamlToProto(file.readAsStringSync());

        final bytes = proto.writeToBuffer();

        expect(bytes, isNotEmpty,
            reason: '$name: buffer binário vazio após writeToBuffer()');
      }
    });

    test('todos os YAMLs passam pelo roundtrip binarypb → DefinicaoProtocolo', () {
      for (final file in _getProtocolFiles()) {
        final name = file.uri.pathSegments.last;
        final original = parseYamlToProto(file.readAsStringSync());
        final bytes    = original.writeToBuffer();

        final restored = DefinicaoProtocolo.fromBuffer(bytes);

        expect(restored.id,    equals(original.id),    reason: '$name: id diverge no roundtrip');
        expect(restored.versao, equals(original.versao), reason: '$name: versao diverge no roundtrip');
        expect(restored.blocos.length, equals(original.blocos.length),
            reason: '$name: número de blocos diverge no roundtrip');
      }
    });

    test('todos os StepRefMateriais referenciam um StepListaAcoes existente', () {
      for (final file in _getProtocolFiles()) {
        final name  = file.uri.pathSegments.last;
        final proto = parseYamlToProto(file.readAsStringSync());

        final listaIds = _collectListaStepIds(proto);
        final refs     = <String>[];

        for (final bloco in proto.blocos) {
          _collectRefMateriais(bloco.steps, refs);
        }

        for (final ref in refs) {
          expect(listaIds, contains(ref),
              reason: '$name: StepRefMateriais referencia "$ref" '
                  'que não existe como StepListaAcoes no protocolo');
        }
      }
    });
  });

  // ── 2. Validações estruturais: manutencao_ferragens ──────────────────────────

  group('manutencao_ferragens.yaml — estrutura', () {
    late DefinicaoProtocolo proto;

    setUp(() {
      final file = File('assets/protocols/manutencao_ferragens.yaml');
      expect(file.existsSync(), isTrue, reason: 'manutencao_ferragens.yaml não encontrado');
      proto = parseYamlToProto(file.readAsStringSync());
    });

    test('tem 4 blocos na ordem correta', () {
      expect(proto.blocos.map((b) => b.id).toList(),
          equals(['materiais', 'via', 'acoes', 'avaliacao']));
    });

    test('bloco "materiais" tem um StepListaAcoes com mínimo 1 e 5 tipos', () {
      final bloco = proto.blocos.firstWhere((b) => b.id == 'materiais');
      expect(bloco.steps.length, equals(1));

      final step = bloco.steps.first;
      expect(step.id, equals('lista_materiais'));
      expect(step.whichConteudo(), equals(Step_Conteudo.listaAcoes));
      expect(step.listaAcoes.minimo, equals(1));
      expect(
        step.listaAcoes.tiposDisponiveis.map((t) => t.id).toList(),
        equals(['parabolt', 'chapeleta', 'argola', 'ancoragem_quimica', 'cola_quimica']),
      );
    });

    test('bloco "via" tem pelo menos um step GPS obrigatório', () {
      final bloco   = proto.blocos.firstWhere((b) => b.id == 'via');
      final gpsStep = bloco.steps.firstWhere(
        (s) =>
            s.whichConteudo() == Step_Conteudo.campoSimples &&
            s.campoSimples.tipo == StepCampoSimples_TipoCampo.GPS,
        orElse: () => throw TestFailure('Nenhum step GPS encontrado no bloco "via"'),
      );
      expect(gpsStep.campoSimples.obrigatorio, isTrue);
    });

    test('bloco "acoes" tem StepListaAcoes com mínimo 1 e 5 tipos de ação', () {
      final bloco = proto.blocos.firstWhere((b) => b.id == 'acoes');
      expect(bloco.steps.length, equals(1));

      final step = bloco.steps.first;
      expect(step.whichConteudo(), equals(Step_Conteudo.listaAcoes));
      expect(step.listaAcoes.minimo, equals(1));
      expect(
        step.listaAcoes.tiposDisponiveis.map((t) => t.id).toList(),
        equals(['inspecao_ancoragem', 'novo_ponto', 'remocao_bloco',
                'limpeza_vegetacao', 'outro']),
      );
    });

    test('bloco "avaliacao" termina com step SIGNATURE obrigatório', () {
      final bloco    = proto.blocos.firstWhere((b) => b.id == 'avaliacao');
      final lastStep = bloco.steps.last;

      expect(lastStep.whichConteudo(), equals(Step_Conteudo.campoSimples));
      expect(lastStep.campoSimples.tipo, equals(StepCampoSimples_TipoCampo.SIGNATURE));
      expect(lastStep.campoSimples.obrigatorio, isTrue);
    });
  });

  // ── 3. Validações do branching recursivo ────────────────────────────────────

  group('manutencao_ferragens.yaml — branching recursivo', () {
    late DefinicaoProtocolo proto;

    setUp(() {
      proto = parseYamlToProto(
        File('assets/protocols/manutencao_ferragens.yaml').readAsStringSync(),
      );
    });

    test('inspecao_ancoragem tem StepSelecaoRamo com 3 ramos', () {
      final stepLista = proto.blocos
          .firstWhere((b) => b.id == 'acoes')
          .steps
          .first;
      final inspecao = stepLista.listaAcoes.tiposDisponiveis
          .firstWhere((t) => t.id == 'inspecao_ancoragem');

      final ramoSteps = inspecao.steps
          .where((s) => s.whichConteudo() == Step_Conteudo.selecaoRamo)
          .toList();
      expect(ramoSteps, isNotEmpty);

      final resultado = ramoSteps.firstWhere((s) => s.id == 'ia_resultado');
      final ramoIds   = resultado.selecaoRamo.ramos.map((r) => r.id).toList();
      expect(ramoIds, containsAll(['aprovado', 'reaperto', 'substituir']));
    });

    test('ramo "substituir" contém um StepSelecaoRamo aninhado (branching recursivo)', () {
      final stepLista = proto.blocos
          .firstWhere((b) => b.id == 'acoes')
          .steps
          .first;
      final inspecao = stepLista.listaAcoes.tiposDisponiveis
          .firstWhere((t) => t.id == 'inspecao_ancoragem');

      final resultado   = inspecao.steps.firstWhere((s) => s.id == 'ia_resultado');
      final ramoSub     = resultado.selecaoRamo.ramos.firstWhere((r) => r.id == 'substituir');
      final subRamoSteps = ramoSub.steps
          .where((s) => s.whichConteudo() == Step_Conteudo.selecaoRamo)
          .toList();

      expect(subRamoSteps, isNotEmpty,
          reason: 'Ramo "substituir" deve ter pelo menos um StepSelecaoRamo aninhado');

      final subRamoIds = subRamoSteps.first.selecaoRamo.ramos.map((r) => r.id).toList();
      expect(subRamoIds, containsAll(['reusar_furo', 'novo_local']));
    });

    test('sub-ramo "reusar_furo" contém um StepRefMateriais apontando para "lista_materiais"', () {
      final stepLista = proto.blocos
          .firstWhere((b) => b.id == 'acoes')
          .steps
          .first;
      final inspecao = stepLista.listaAcoes.tiposDisponiveis
          .firstWhere((t) => t.id == 'inspecao_ancoragem');

      final resultado = inspecao.steps.firstWhere((s) => s.id == 'ia_resultado');
      final ramoSub   = resultado.selecaoRamo.ramos.firstWhere((r) => r.id == 'substituir');
      final estrategia = ramoSub.steps
          .firstWhere((s) => s.whichConteudo() == Step_Conteudo.selecaoRamo);

      final ramoReusar = estrategia.selecaoRamo.ramos
          .firstWhere((r) => r.id == 'reusar_furo');
      final refSteps = ramoReusar.steps
          .where((s) => s.whichConteudo() == Step_Conteudo.refMateriais)
          .toList();

      expect(refSteps, isNotEmpty,
          reason: 'Sub-ramo "reusar_furo" deve ter um StepRefMateriais');
      expect(refSteps.first.refMateriais.idStepMateriais, equals('lista_materiais'));
    });
  });
}
