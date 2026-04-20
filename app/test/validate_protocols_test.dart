// test/validate_protocols_test.dart
//
// Testa que todos os protocolos YAML em assets/protocols/ são válidos segundo
// o schema definido em wizard.proto e podem ser serializados em .binarypb.
//
// Uso: flutter test test/validate_protocols_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/models/proto/protos/wizard.pb.dart';
import 'package:app/core/models/proto/protos/wizard.pbenum.dart';
import 'package:app/core/services/protocol_parser.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers para os testes — adaptados para o novo schema (Step.conteudos)
// ─────────────────────────────────────────────────────────────────────────────

List<File> _getProtocolFiles() {
  final dir = Directory('assets/protocols');
  return dir.listSync().whereType<File>().where((f) => f.path.endsWith('.yaml')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// Coleta recursivamente todos os ConteudoSteps de um certo tipo em uma lista
/// de steps (incluindo dentro de ramos e tipos de ação).
void _collectConteudosByType(
    List<Step> steps,
    ConteudoStep_Tipo tipo,
    List<ConteudoStep> result) {
  for (final step in steps) {
    for (final c in step.conteudos) {
      if (c.whichTipo() == tipo) {
        result.add(c);
      }
      // Recursão em ramos
      if (c.whichTipo() == ConteudoStep_Tipo.selecaoRamo) {
        for (final ramo in c.selecaoRamo.ramos) {
          _collectConteudosByType(ramo.steps, tipo, result);
        }
      }
      // Recursão em tipos de ação de listas
      if (c.whichTipo() == ConteudoStep_Tipo.listaAcoes) {
        for (final tipo in c.listaAcoes.tiposDisponiveis) {
          _collectConteudosByType(tipo.steps, c.whichTipo(), result);
        }
      }
    }
  }
}

/// Coleta os IDs de todos os ConteudoSteps do tipo listaAcoes no protocolo.
Set<String> _collectListaConteudoIds(DefinicaoProtocolo proto) {
  final ids = <String>{};
  for (final bloco in proto.blocos) {
    for (final step in bloco.steps) {
      for (final c in step.conteudos) {
        if (c.whichTipo() == ConteudoStep_Tipo.listaAcoes) {
          ids.add(c.id);
        }
      }
    }
  }
  return ids;
}

/// Coleta recursivamente todos os StepRefMateriais do protocolo
/// (incluindo dentro de ramos e tipos de ação).
void _collectRefMateriais(List<Step> steps, List<StepRefMateriais> refs) {
  for (final step in steps) {
    for (final c in step.conteudos) {
      if (c.whichTipo() == ConteudoStep_Tipo.refMateriais) {
        refs.add(c.refMateriais);
      }
      if (c.whichTipo() == ConteudoStep_Tipo.selecaoRamo) {
        for (final ramo in c.selecaoRamo.ramos) {
          _collectRefMateriais(ramo.steps, refs);
        }
      }
      if (c.whichTipo() == ConteudoStep_Tipo.listaAcoes) {
        for (final tipo in c.listaAcoes.tiposDisponiveis) {
          _collectRefMateriais(tipo.steps, refs);
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers para acessar conteudos de steps (novo schema)
// ─────────────────────────────────────────────────────────────────────────────

/// Retorna o primeiro ConteudoStep de um dado tipo dentro de uma lista de steps.
/// Lança TestFailure se não encontrar.
ConteudoStep _firstConteudoOfType(List<Step> steps, ConteudoStep_Tipo tipo, {String? reason}) {
  for (final step in steps) {
    for (final c in step.conteudos) {
      if (c.whichTipo() == tipo) return c;
    }
  }
  throw TestFailure(reason ?? 'ConteudoStep do tipo $tipo não encontrado');
}

/// Retorna o ConteudoStep com um id específico dentro de uma lista de steps.
ConteudoStep _conteudoById(List<Step> steps, String id) {
  for (final step in steps) {
    for (final c in step.conteudos) {
      if (c.id == id) return c;
    }
  }
  throw TestFailure('ConteudoStep com id "$id" não encontrado');
}

/// Verifica se uma lista de steps tem algum ConteudoStep de um dado tipo.
bool _hasConteudoOfType(List<Step> steps, ConteudoStep_Tipo tipo) {
  return steps.any((s) => s.conteudos.any((c) => c.whichTipo() == tipo));
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

        final proto = ProtocolParser.fromYaml(yaml);

        expect(proto.id, isNotEmpty, reason: '$name: campo "id" vazio');
        expect(proto.versao, isNotEmpty, reason: '$name: campo "versao" vazio');
        expect(proto.blocos, isNotEmpty, reason: '$name: lista "blocos" vazia');
      }
    });

    test('todos os steps têm pelo menos um ConteudoStep', () {
      for (final file in _getProtocolFiles()) {
        final name = file.uri.pathSegments.last;
        final proto = ProtocolParser.fromYaml(file.readAsStringSync());

        for (final bloco in proto.blocos) {
          for (final step in bloco.steps) {
            expect(step.conteudos, isNotEmpty,
                reason: '$name: step "${step.id}" não tem conteudos');
          }
        }
      }
    });

    test('todos os YAMLs serializam para binary protobuf (binarypb)', () {
      for (final file in _getProtocolFiles()) {
        final name  = file.uri.pathSegments.last;
        final proto = ProtocolParser.fromYaml(file.readAsStringSync());

        final bytes = proto.writeToBuffer();

        expect(bytes, isNotEmpty,
            reason: '$name: buffer binário vazio após writeToBuffer()');
      }
    });

    test('todos os YAMLs passam pelo roundtrip binarypb → DefinicaoProtocolo', () {
      for (final file in _getProtocolFiles()) {
        final name    = file.uri.pathSegments.last;
        final original = ProtocolParser.fromYaml(file.readAsStringSync());
        final bytes    = original.writeToBuffer();

        final restored = DefinicaoProtocolo.fromBuffer(bytes);

        expect(restored.id,    equals(original.id),    reason: '$name: id diverge no roundtrip');
        expect(restored.versao, equals(original.versao), reason: '$name: versao diverge no roundtrip');
        expect(restored.blocos.length, equals(original.blocos.length),
            reason: '$name: número de blocos diverge no roundtrip');
      }
    });

    test('todos os StepRefMateriais referenciam um ConteudoStep listaAcoes existente', () {
      for (final file in _getProtocolFiles()) {
        final name  = file.uri.pathSegments.last;
        final proto = ProtocolParser.fromYaml(file.readAsStringSync());

        final listaIds = _collectListaConteudoIds(proto);
        final refs     = <StepRefMateriais>[];

        for (final bloco in proto.blocos) {
          _collectRefMateriais(bloco.steps, refs);
        }

        for (final ref in refs) {
          expect(listaIds, contains(ref.idStepMateriais),
              reason: '$name: StepRefMateriais referencia "${ref.idStepMateriais}" '
                  'que não existe como ConteudoStep listaAcoes no protocolo');
        }
      }
    });
  });

  // ── 2. Feature 1: Multi-conteúdo por step ───────────────────────────────────

  group('manutencao_ferragens.yaml — Feature 1 (multi-conteúdo)', () {
    late DefinicaoProtocolo proto;

    setUp(() {
      final file = File('assets/protocols/manutencao_ferragens.yaml');
      expect(file.existsSync(), isTrue, reason: 'manutencao_ferragens.yaml não encontrado');
      proto = ProtocolParser.fromYaml(file.readAsStringSync());
    });

    test('tem 4 blocos na ordem correta', () {
      expect(proto.blocos.map((b) => b.id).toList(),
          equals(['materiais', 'via', 'acoes', 'avaliacao']));
    });

    test('step "via_localizacao" tem múltiplos conteudos (instrucao + GPS + campos)', () {
      final bloco = proto.blocos.firstWhere((b) => b.id == 'via');
      final step  = bloco.steps.firstWhere((s) => s.id == 'via_localizacao');

      expect(step.conteudos.length, greaterThanOrEqualTo(3),
          reason: 'via_localizacao deve ter instrucao + GPS + nome (mínimo 3 conteudos)');

      final tipos = step.conteudos.map((c) => c.whichTipo()).toList();
      expect(tipos, contains(ConteudoStep_Tipo.instrucao));
      expect(tipos, contains(ConteudoStep_Tipo.campoSimples));
    });

    test('step "assinatura" tem instrucao + SIGNATURE em sequência', () {
      final bloco = proto.blocos.firstWhere((b) => b.id == 'avaliacao');
      final step  = bloco.steps.firstWhere((s) => s.id == 'assinatura');

      expect(step.conteudos.length, greaterThanOrEqualTo(2));
      expect(step.conteudos.first.whichTipo(), ConteudoStep_Tipo.instrucao);
      final lastC = step.conteudos.last;
      expect(lastC.whichTipo(), ConteudoStep_Tipo.campoSimples);
      expect(lastC.campoSimples.tipo, StepCampoSimples_TipoCampo.SIGNATURE);
      expect(lastC.campoSimples.obrigatorio, isTrue);
    });

    test('"ia_avaliacao" (tipo inspecao_ancoragem) tem instrucao + IMAGE + SelecaoRamo no mesmo step', () {
      final bloco     = proto.blocos.firstWhere((b) => b.id == 'acoes');
      final listaC    = _firstConteudoOfType(bloco.steps, ConteudoStep_Tipo.listaAcoes);
      final inspecao  = listaC.listaAcoes.tiposDisponiveis.firstWhere((t) => t.id == 'inspecao_ancoragem');
      final iaStep    = inspecao.steps.firstWhere((s) => s.id == 'ia_avaliacao');

      final tipos = iaStep.conteudos.map((c) => c.whichTipo()).toList();
      expect(tipos, contains(ConteudoStep_Tipo.instrucao));
      expect(tipos, contains(ConteudoStep_Tipo.campoSimples));
      expect(tipos, contains(ConteudoStep_Tipo.selecaoRamo));
    });

    test('"avaliacao_geral" tem condição + comentários em sequência no mesmo step', () {
      final bloco = proto.blocos.firstWhere((b) => b.id == 'avaliacao');
      final step  = bloco.steps.firstWhere((s) => s.id == 'avaliacao_geral');

      expect(step.conteudos.length, greaterThanOrEqualTo(2));
      final tipos = step.conteudos.map((c) => c.whichTipo()).toList();
      // Ambos são campoSimples (dropdown + text_area)
      expect(tipos.where((t) => t == ConteudoStep_Tipo.campoSimples).length,
          greaterThanOrEqualTo(2));
    });
  });

  // ── 3. Feature 2: Lista de ações inline ─────────────────────────────────────

  group('manutencao_ferragens.yaml — Feature 2 (listas inline)', () {
    late DefinicaoProtocolo proto;

    setUp(() {
      proto = ProtocolParser.fromYaml(
        File('assets/protocols/manutencao_ferragens.yaml').readAsStringSync(),
      );
    });

    test('bloco "materiais" tem ConteudoStep listaAcoes com id "lista_materiais_c" e 5 tipos', () {
      final bloco  = proto.blocos.firstWhere((b) => b.id == 'materiais');
      final listaC = _firstConteudoOfType(bloco.steps, ConteudoStep_Tipo.listaAcoes);

      expect(listaC.id, equals('lista_materiais_c'));
      expect(listaC.listaAcoes.minimo, equals(1));
      expect(
        listaC.listaAcoes.tiposDisponiveis.map((t) => t.id).toList(),
        equals(['parabolt', 'chapeleta', 'argola', 'ancoragem_quimica', 'cola_quimica']),
      );
    });

    test('tipo "parabolt" tem step único com múltiplos conteudos (inclui lote obrigatório)', () {
      final bloco    = proto.blocos.firstWhere((b) => b.id == 'materiais');
      final listaC   = _firstConteudoOfType(bloco.steps, ConteudoStep_Tipo.listaAcoes);
      final parabolt = listaC.listaAcoes.tiposDisponiveis.firstWhere((t) => t.id == 'parabolt');

      expect(parabolt.steps.length, equals(1));
      final pbStep = parabolt.steps.first;
      expect(pbStep.conteudos.length, greaterThanOrEqualTo(4)); // aviso+marca+liga+lote...

      final loteC = _conteudoById([pbStep], 'pb_lote');
      expect(loteC.campoSimples.obrigatorio, isTrue);
    });

    test('bloco "acoes" tem ConteudoStep listaAcoes com id "lista_acoes_c" e 6 tipos', () {
      final bloco  = proto.blocos.firstWhere((b) => b.id == 'acoes');
      final listaC = _firstConteudoOfType(bloco.steps, ConteudoStep_Tipo.listaAcoes);

      expect(listaC.id, equals('lista_acoes_c'));
      expect(listaC.listaAcoes.minimo, equals(1));
      expect(
        listaC.listaAcoes.tiposDisponiveis.map((t) => t.id).toList(),
        equals(['inspecao_ancoragem', 'novo_ponto', 'remocao_bloco', 'limpeza_vegetacao', 'outro']),
      );
    });
  });

  // ── 4. Branching recursivo ───────────────────────────────────────────────────

  group('manutencao_ferragens.yaml — branching recursivo', () {
    late DefinicaoProtocolo proto;

    setUp(() {
      proto = ProtocolParser.fromYaml(
        File('assets/protocols/manutencao_ferragens.yaml').readAsStringSync(),
      );
    });

    test('"ia_avaliacao" tem SelecaoRamo "ia_resultado" com 3 ramos', () {
      final bloco    = proto.blocos.firstWhere((b) => b.id == 'acoes');
      final listaC   = _firstConteudoOfType(bloco.steps, ConteudoStep_Tipo.listaAcoes);
      final inspecao = listaC.listaAcoes.tiposDisponiveis
          .firstWhere((t) => t.id == 'inspecao_ancoragem');

      final iaStep    = inspecao.steps.firstWhere((s) => s.id == 'ia_avaliacao');
      final resultadoC = _conteudoById([iaStep], 'ia_resultado');

      expect(resultadoC.whichTipo(), ConteudoStep_Tipo.selecaoRamo);
      expect(resultadoC.selecaoRamo.obrigatorio, isTrue);

      final ramoIds = resultadoC.selecaoRamo.ramos.map((r) => r.id).toList();
      expect(ramoIds, containsAll(['aprovado', 'reaperto', 'substituir']));
    });

    test('ramo "substituir" contém um SelecaoRamo aninhado com "reusar_furo" e "novo_local"', () {
      final bloco    = proto.blocos.firstWhere((b) => b.id == 'acoes');
      final listaC   = _firstConteudoOfType(bloco.steps, ConteudoStep_Tipo.listaAcoes);
      final inspecao = listaC.listaAcoes.tiposDisponiveis
          .firstWhere((t) => t.id == 'inspecao_ancoragem');

      final iaStep    = inspecao.steps.firstWhere((s) => s.id == 'ia_avaliacao');
      final resultadoC = _conteudoById([iaStep], 'ia_resultado');
      final ramoSub   = resultadoC.selecaoRamo.ramos.firstWhere((r) => r.id == 'substituir');

      // o step dentro de "substituir" tem um conteudo SelecaoRamo
      expect(_hasConteudoOfType(ramoSub.steps, ConteudoStep_Tipo.selecaoRamo), isTrue,
          reason: 'Ramo "substituir" deve ter SelecaoRamo aninhado');

      final subRamoC = _firstConteudoOfType(ramoSub.steps, ConteudoStep_Tipo.selecaoRamo);
      final subRamoIds = subRamoC.selecaoRamo.ramos.map((r) => r.id).toList();
      expect(subRamoIds, containsAll(['reusar_furo', 'novo_local']));
    });

    test('sub-ramo "reusar_furo" tem RefMateriais apontando para "lista_materiais_c"', () {
      final bloco    = proto.blocos.firstWhere((b) => b.id == 'acoes');
      final listaC   = _firstConteudoOfType(bloco.steps, ConteudoStep_Tipo.listaAcoes);
      final inspecao = listaC.listaAcoes.tiposDisponiveis
          .firstWhere((t) => t.id == 'inspecao_ancoragem');

      final iaStep    = inspecao.steps.firstWhere((s) => s.id == 'ia_avaliacao');
      final resultadoC = _conteudoById([iaStep], 'ia_resultado');
      final ramoSub   = resultadoC.selecaoRamo.ramos.firstWhere((r) => r.id == 'substituir');
      final subRamoC  = _firstConteudoOfType(ramoSub.steps, ConteudoStep_Tipo.selecaoRamo);
      final ramoReusar = subRamoC.selecaoRamo.ramos.firstWhere((r) => r.id == 'reusar_furo');

      expect(_hasConteudoOfType(ramoReusar.steps, ConteudoStep_Tipo.refMateriais), isTrue,
          reason: 'Sub-ramo "reusar_furo" deve ter RefMateriais');

      final refC = _firstConteudoOfType(ramoReusar.steps, ConteudoStep_Tipo.refMateriais);
      expect(refC.refMateriais.idStepMateriais, equals('lista_materiais_c'));
    });

    test('"novo_ponto" tem RefMateriais que referencia "lista_materiais_c"', () {
      final bloco    = proto.blocos.firstWhere((b) => b.id == 'acoes');
      final listaC   = _firstConteudoOfType(bloco.steps, ConteudoStep_Tipo.listaAcoes);
      final novoPonto = listaC.listaAcoes.tiposDisponiveis
          .firstWhere((t) => t.id == 'novo_ponto');

      final refC = _firstConteudoOfType(novoPonto.steps, ConteudoStep_Tipo.refMateriais,
          reason: 'novo_ponto deve ter RefMateriais');
      expect(refC.refMateriais.idStepMateriais, equals('lista_materiais_c'));
      expect(refC.refMateriais.obrigatorio, isTrue);
    });
  });

  // ── 5. Integridade global de referências ─────────────────────────────────────

  group('Integridade de referências RefMateriais', () {
    test('todos os RefMateriais referenciam ConteudoStep listaAcoes existente', () {
      for (final file in _getProtocolFiles()) {
        final name  = file.uri.pathSegments.last;
        final proto = ProtocolParser.fromYaml(file.readAsStringSync());

        final listaIds = _collectListaConteudoIds(proto);
        final refs     = <StepRefMateriais>[];

        for (final bloco in proto.blocos) {
          _collectRefMateriais(bloco.steps, refs);
        }

        for (final ref in refs) {
          expect(listaIds, contains(ref.idStepMateriais),
              reason: '$name: RefMateriais referencia "${ref.idStepMateriais}" '
                  'que não existe como ConteudoStep listaAcoes');
        }
      }
    });
  });
}
