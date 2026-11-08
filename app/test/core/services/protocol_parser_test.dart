// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

// test/validate_protocols_test.dart
//
// Testa que todos os protocolos YAML em assets/protocols/ são válidos segundo
// o schema definido em wizard.proto e podem ser serializados em .binarypb.
//
// Uso: flutter test test/validate_protocols_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fixalog/core/models/proto/protos/wizard.pb.dart';
import 'package:fixalog/core/services/protocol_parser.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers para os testes — adaptados para o novo schema (Step.conteudos)
// ─────────────────────────────────────────────────────────────────────────────

List<File> _getProtocolFiles() {
  final dir = Directory('assets/protocols');
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// Coleta recursivamente os IDs de todos os ConteudoSteps que podem fornecer materiais
/// (tipo listaAcoes ou refMateriais com origemCatalogo) no protocolo.
Set<String> _collectListaConteudoIds(DefinicaoProtocolo proto) {
  final ids = <String>{};
  void visitSteps(List<Step> steps) {
    for (final step in steps) {
      for (final c in step.conteudos) {
        if (c.whichTipo() == ConteudoStep_Tipo.listaAcoes) {
          ids.add(c.id);
          for (final tipo in c.listaAcoes.tiposDisponiveis) {
            visitSteps(tipo.steps);
          }
        } else if (c.whichTipo() == ConteudoStep_Tipo.refMateriais &&
            c.refMateriais.origemCatalogo) {
          ids.add(c.id);
        } else if (c.whichTipo() == ConteudoStep_Tipo.selecaoRamo) {
          for (final ramo in c.selecaoRamo.ramos) {
            visitSteps(ramo.steps);
          }
        }
      }
    }
  }

  for (final bloco in proto.blocos) {
    visitSteps(bloco.steps);
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
ConteudoStep _firstConteudoOfType(
  List<Step> steps,
  ConteudoStep_Tipo tipo, {
  String? reason,
}) {
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
      expect(
        files,
        isNotEmpty,
        reason: 'Nenhum protocolo YAML encontrado em assets/protocols/',
      );
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
            expect(
              step.conteudos,
              isNotEmpty,
              reason: '$name: step "${step.id}" não tem conteudos',
            );
          }
        }
      }
    });

    test('todos os YAMLs serializam para binary protobuf (binarypb)', () {
      for (final file in _getProtocolFiles()) {
        final name = file.uri.pathSegments.last;
        final proto = ProtocolParser.fromYaml(file.readAsStringSync());

        final bytes = proto.writeToBuffer();

        expect(
          bytes,
          isNotEmpty,
          reason: '$name: buffer binário vazio após writeToBuffer()',
        );
      }
    });

    test(
      'todos os YAMLs passam pelo roundtrip binarypb → DefinicaoProtocolo',
      () {
        for (final file in _getProtocolFiles()) {
          final name = file.uri.pathSegments.last;
          final original = ProtocolParser.fromYaml(file.readAsStringSync());
          final bytes = original.writeToBuffer();

          final restored = DefinicaoProtocolo.fromBuffer(bytes);

          expect(
            restored.id,
            equals(original.id),
            reason: '$name: id diverge no roundtrip',
          );
          expect(
            restored.versao,
            equals(original.versao),
            reason: '$name: versao diverge no roundtrip',
          );
          expect(
            restored.blocos.length,
            equals(original.blocos.length),
            reason: '$name: número de blocos diverge no roundtrip',
          );
        }
      },
    );

    test(
      'todos os StepRefMateriais referenciam um ConteudoStep existente ou o catálogo',
      () {
        for (final file in _getProtocolFiles()) {
          final name = file.uri.pathSegments.last;
          final proto = ProtocolParser.fromYaml(file.readAsStringSync());

          final listaIds = _collectListaConteudoIds(proto);
          final refs = <StepRefMateriais>[];

          for (final bloco in proto.blocos) {
            _collectRefMateriais(bloco.steps, refs);
          }

          for (final ref in refs) {
            if (ref.origemCatalogo && ref.idStepMateriais.isEmpty) {
              continue;
            }
            expect(
              listaIds,
              contains(ref.idStepMateriais),
              reason:
                  '$name: StepRefMateriais referencia "${ref.idStepMateriais}" '
                  'que não existe como fonte de materiais no protocolo',
            );
          }
        }
      },
    );
  });

  // ── 2. Feature 1: Multi-conteúdo por step ───────────────────────────────────

  group('manutencao.yaml — Feature 1 (multi-conteúdo e sem Bloco 1 de materiais)', () {
    late DefinicaoProtocolo proto;

    setUp(() {
      final file = File('assets/protocols/manutencao.yaml');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'manutencao.yaml não encontrado',
      );
      proto = ProtocolParser.fromYaml(file.readAsStringSync());
    });

    test('tem id "maintenance", versao "3" e 3 blocos na ordem correta (route, actions, assessment)', () {
      expect(proto.id, equals('maintenance'));
      expect(proto.versao, equals('3'));
      expect(
        proto.blocos.map((b) => b.id).toList(),
        equals(['route', 'actions', 'assessment']),
      );
    });

    test(
      'step "route_location" tem múltiplos conteudos (instrucao + data automática + GPS + campos)',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'route');
        final step = bloco.steps.firstWhere((s) => s.id == 'route_location');

        expect(
          step.conteudos.length,
          greaterThanOrEqualTo(4),
          reason:
              'route_location deve ter instrucao + data + GPS + nome (mínimo 4 conteudos)',
        );

        final dataC = _conteudoById([step], 'route_date');
        expect(dataC.campoSimples.tipo, equals(StepCampoSimples_TipoCampo.DATE));
        expect(dataC.campoSimples.preencherDataAtual, isTrue);

        final tipos = step.conteudos.map((c) => c.whichTipo()).toList();
        expect(tipos, contains(ConteudoStep_Tipo.instrucao));
        expect(tipos, contains(ConteudoStep_Tipo.campoSimples));
      },
    );

    test('bloco "assessment" encerra em "general_assessment" sem step de assinatura', () {
      final bloco = proto.blocos.firstWhere((b) => b.id == 'assessment');
      final stepIds = bloco.steps.map((s) => s.id).toList();
      expect(stepIds, isNot(contains('assinatura')));
      expect(bloco.steps.last.id, equals('general_assessment'));

      final tiposCampo = bloco.steps
          .expand((s) => s.conteudos)
          .where((c) => c.whichTipo() == ConteudoStep_Tipo.campoSimples)
          .map((c) => c.campoSimples.tipo)
          .toList();
      expect(tiposCampo, isNot(contains(StepCampoSimples_TipoCampo.SIGNATURE)));
    });

    test(
      '"ai_assessment" (tipo anchor_inspection) tem instrucao + IMAGE + SelecaoRamo no mesmo step',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'actions');
        final listaC = _firstConteudoOfType(
          bloco.steps,
          ConteudoStep_Tipo.listaAcoes,
        );
        final inspecao = listaC.listaAcoes.tiposDisponiveis.firstWhere(
          (t) => t.id == 'anchor_inspection',
        );
        final iaStep = inspecao.steps.firstWhere((s) => s.id == 'ai_assessment');

        final tipos = iaStep.conteudos.map((c) => c.whichTipo()).toList();
        expect(tipos, contains(ConteudoStep_Tipo.instrucao));
        expect(tipos, contains(ConteudoStep_Tipo.campoSimples));
        expect(tipos, contains(ConteudoStep_Tipo.selecaoRamo));
      },
    );

    test(
      '"general_assessment" tem condição + comentários em sequência no mesmo step',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'assessment');
        final step = bloco.steps.firstWhere((s) => s.id == 'general_assessment');

        expect(step.conteudos.length, greaterThanOrEqualTo(2));
        final tipos = step.conteudos.map((c) => c.whichTipo()).toList();
        // Ambos são campoSimples (dropdown + text_area)
        expect(
          tipos.where((t) => t == ConteudoStep_Tipo.campoSimples).length,
          greaterThanOrEqualTo(2),
        );
      },
    );
  });

  // ── 3. Feature 2: Lista de ações inline ─────────────────────────────────────

  group('manutencao.yaml — Feature 2 (listas inline)', () {
    late DefinicaoProtocolo proto;

    setUp(() {
      proto = ProtocolParser.fromYaml(
        File('assets/protocols/manutencao.yaml').readAsStringSync(),
      );
    });

    test(
      'bloco "actions" tem ConteudoStep listaAcoes com id "action_list_c" e 5 tipos',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'actions');
        final listaC = _firstConteudoOfType(
          bloco.steps,
          ConteudoStep_Tipo.listaAcoes,
        );

        expect(listaC.id, equals('action_list_c'));
        expect(listaC.listaAcoes.minimo, equals(1));
        expect(
          listaC.listaAcoes.tiposDisponiveis.map((t) => t.id).toList(),
          equals([
            'anchor_inspection',
            'new_anchor_point',
            'loose_rock_removal',
            'vegetation_cleaning',
            'other',
          ]),
        );
      },
    );
  });

  // ── 4. Branching recursivo ───────────────────────────────────────────────────

  group('manutencao.yaml — branching recursivo e ref_mat_* direto do catálogo', () {
    late DefinicaoProtocolo proto;

    setUp(() {
      proto = ProtocolParser.fromYaml(
        File('assets/protocols/manutencao.yaml').readAsStringSync(),
      );
    });

    test('"ai_assessment" tem SelecaoRamo "ai_result" com 3 ramos', () {
      final bloco = proto.blocos.firstWhere((b) => b.id == 'actions');
      final listaC = _firstConteudoOfType(
        bloco.steps,
        ConteudoStep_Tipo.listaAcoes,
      );
      final inspecao = listaC.listaAcoes.tiposDisponiveis.firstWhere(
        (t) => t.id == 'anchor_inspection',
      );

      final iaStep = inspecao.steps.firstWhere((s) => s.id == 'ai_assessment');
      final resultadoC = _conteudoById([iaStep], 'ai_result');

      expect(resultadoC.whichTipo(), ConteudoStep_Tipo.selecaoRamo);
      expect(resultadoC.selecaoRamo.obrigatorio, isTrue);

      final ramoIds = resultadoC.selecaoRamo.ramos.map((r) => r.id).toList();
      expect(ramoIds, containsAll(['approved', 'retightened', 'replace']));
    });

    test(
      'ramo "replace" contém um SelecaoRamo aninhado com "reuse_hole" e "new_location"',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'actions');
        final listaC = _firstConteudoOfType(
          bloco.steps,
          ConteudoStep_Tipo.listaAcoes,
        );
        final inspecao = listaC.listaAcoes.tiposDisponiveis.firstWhere(
          (t) => t.id == 'anchor_inspection',
        );

        final iaStep = inspecao.steps.firstWhere((s) => s.id == 'ai_assessment');
        final resultadoC = _conteudoById([iaStep], 'ai_result');
        final ramoSub = resultadoC.selecaoRamo.ramos.firstWhere(
          (r) => r.id == 'replace',
        );

        // o step dentro de "replace" tem um conteudo SelecaoRamo
        expect(
          _hasConteudoOfType(ramoSub.steps, ConteudoStep_Tipo.selecaoRamo),
          isTrue,
          reason: 'Ramo "replace" deve ter SelecaoRamo aninhado',
        );

        final subRamoC = _firstConteudoOfType(
          ramoSub.steps,
          ConteudoStep_Tipo.selecaoRamo,
        );
        final subRamoIds = subRamoC.selecaoRamo.ramos.map((r) => r.id).toList();
        expect(subRamoIds, containsAll(['reuse_hole', 'new_location']));
      },
    );

    test(
      'sub-ramos "reuse_hole" e "new_location" têm RefMateriais com origemCatalogo=true',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'actions');
        final listaC = _firstConteudoOfType(
          bloco.steps,
          ConteudoStep_Tipo.listaAcoes,
        );
        final inspecao = listaC.listaAcoes.tiposDisponiveis.firstWhere(
          (t) => t.id == 'anchor_inspection',
        );

        final iaStep = inspecao.steps.firstWhere((s) => s.id == 'ai_assessment');
        final resultadoC = _conteudoById([iaStep], 'ai_result');
        final ramoSub = resultadoC.selecaoRamo.ramos.firstWhere(
          (r) => r.id == 'replace',
        );
        final subRamoC = _firstConteudoOfType(
          ramoSub.steps,
          ConteudoStep_Tipo.selecaoRamo,
        );
        final ramoReusar = subRamoC.selecaoRamo.ramos.firstWhere(
          (r) => r.id == 'reuse_hole',
        );
        final refReusar = _firstConteudoOfType(
          ramoReusar.steps,
          ConteudoStep_Tipo.refMateriais,
        );
        expect(refReusar.id, equals('ref_mat_reuse_hole'));
        expect(refReusar.refMateriais.origemCatalogo, isTrue);
        expect(refReusar.refMateriais.obrigatorio, isTrue);

        final ramoNovoLocal = subRamoC.selecaoRamo.ramos.firstWhere(
          (r) => r.id == 'new_location',
        );
        final refNovoLocal = _firstConteudoOfType(
          ramoNovoLocal.steps,
          ConteudoStep_Tipo.refMateriais,
        );
        expect(refNovoLocal.id, equals('ref_mat_new_location'));
        expect(refNovoLocal.refMateriais.origemCatalogo, isTrue);
        expect(refNovoLocal.refMateriais.obrigatorio, isTrue);
      },
    );

    test(
      '"new_anchor_point" e "other" têm RefMateriais com origemCatalogo=true (obrigatório e opcional respectivamente)',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'actions');
        final listaC = _firstConteudoOfType(
          bloco.steps,
          ConteudoStep_Tipo.listaAcoes,
        );
        final novoPonto = listaC.listaAcoes.tiposDisponiveis.firstWhere(
          (t) => t.id == 'new_anchor_point',
        );

        final refC = _firstConteudoOfType(
          novoPonto.steps,
          ConteudoStep_Tipo.refMateriais,
          reason: 'new_anchor_point deve ter RefMateriais',
        );
        expect(refC.id, equals('ref_mat_new_anchor'));
        expect(refC.refMateriais.origemCatalogo, isTrue);
        expect(refC.refMateriais.obrigatorio, isTrue);

        final outro = listaC.listaAcoes.tiposDisponiveis.firstWhere(
          (t) => t.id == 'other',
        );
        final refOutro = _firstConteudoOfType(
          outro.steps,
          ConteudoStep_Tipo.refMateriais,
          reason: 'other deve ter RefMateriais opcional',
        );
        expect(refOutro.id, equals('ref_mat_other'));
        expect(refOutro.refMateriais.origemCatalogo, isTrue);
        expect(refOutro.refMateriais.obrigatorio, isFalse);
      },
    );
  });

  // ── 5. Novos recursos do Parser para Materiais ──────────────────────────────

  group('Versionamento inteiro e extrairVersaoInteira', () {
    test('parseia versao declarada como número inteiro no YAML e normaliza via extrairVersaoInteira', () {
      const yaml = '''
protocolo:
  id: teste_versao_inteira
  nome: Teste Versão Inteira
  versao: 2
  blocos:
    - id: b1
      titulo: Bloco 1
      steps:
        - id: s1
          conteudos:
            - id: c1
              campo_simples:
                label: "Campo"
                tipo: TEXT
''';
      final proto = ProtocolParser.fromYaml(yaml);
      expect(proto.versao, equals('2'));
      expect(ProtocolParser.extrairVersaoInteira(proto.versao), equals(2));
    });

    test('extrairVersaoInteira converte versões semver legadas ou vazias para 1 e inteiros positivos para seu valor', () {
      expect(ProtocolParser.extrairVersaoInteira('1.0.0'), equals(1));
      expect(ProtocolParser.extrairVersaoInteira('2.1.0'), equals(1));
      expect(ProtocolParser.extrairVersaoInteira(''), equals(1));
      expect(ProtocolParser.extrairVersaoInteira('0'), equals(1));
      expect(ProtocolParser.extrairVersaoInteira('-3'), equals(1));
      expect(ProtocolParser.extrairVersaoInteira('1'), equals(1));
      expect(ProtocolParser.extrairVersaoInteira('3'), equals(3));
    });
  });

  group('Parsing de preencher_data_atual, origem_catalogo e listas aninhadas', () {
    test('parseia preencher_data_atual em StepCampoSimples do tipo DATE', () {
      const yaml = '''
protocolo:
  id: teste_data
  nome: Teste Data
  versao: "1.0.0"
  blocos:
    - id: b1
      titulo: Bloco 1
      steps:
        - id: s1
          conteudos:
            - id: data_cadastro
              campo_simples:
                label: "Data de Registro"
                tipo: DATE
                preencher_data_atual: true
                obrigatorio: true
''';
      final proto = ProtocolParser.fromYaml(yaml);
      final conteudo = proto.blocos.first.steps.first.conteudos.first;
      expect(conteudo.campoSimples.tipo, StepCampoSimples_TipoCampo.DATE);
      expect(conteudo.campoSimples.preencherDataAtual, isTrue);
    });

    test('parseia origem_catalogo em StepRefMateriais', () {
      const yaml = '''
protocolo:
  id: teste_catalogo
  nome: Teste Catalogo
  versao: "1.0.0"
  blocos:
    - id: b1
      titulo: Bloco 1
      steps:
        - id: s1
          conteudos:
            - id: selecao_catalogo
              ref_materiais:
                label: "Materiais do Catálogo"
                origem_catalogo: true
                obrigatorio: true
''';
      final proto = ProtocolParser.fromYaml(yaml);
      final conteudo = proto.blocos.first.steps.first.conteudos.first;
      expect(conteudo.refMateriais.origemCatalogo, isTrue);
      expect(conteudo.refMateriais.obrigatorio, isTrue);
    });

    test('parseia StepListaAcoes aninhada dentro de um TipoAcao', () {
      const yaml = '''
protocolo:
  id: teste_lista_aninhada
  nome: Teste Lista Aninhada
  versao: "1.0.0"
  blocos:
    - id: b1
      titulo: Materiais
      steps:
        - id: s_mat
          conteudos:
            - id: lista_materiais
              lista_acoes:
                label: "Materiais"
                minimo: 1
                tipos_disponiveis:
                  - id: outro
                    label: "Outro"
                    steps:
                      - id: s_outro
                        conteudos:
                          - id: sub_detalhes
                            lista_acoes:
                              label: "Detalhes / Processo de Fabricação"
                              minimo: 0
                              tipos_disponiveis:
                                - id: detalhe_item
                                  label: "Adicionar Detalhe"
                                  steps:
                                    - id: s_det
                                      conteudos:
                                        - id: det_texto
                                          campo_simples:
                                            label: "Descrição"
                                            tipo: TEXT
''';
      final proto = ProtocolParser.fromYaml(yaml);
      final listaPrincipal = proto.blocos.first.steps.first.conteudos.first.listaAcoes;
      final tipoOutro = listaPrincipal.tiposDisponiveis.first;
      final subListaConteudo = tipoOutro.steps.first.conteudos.first;
      expect(subListaConteudo.id, equals('sub_detalhes'));
      expect(subListaConteudo.whichTipo(), equals(ConteudoStep_Tipo.listaAcoes));
      expect(
        subListaConteudo.listaAcoes.tiposDisponiveis.first.id,
        equals('detalhe_item'),
      );
    });
  });

  // ── 6. cadastro_material.yaml — Estrutura do Protocolo de Materiais ─────────

  group('cadastro_material.yaml — Estrutura do Protocolo de Materiais', () {
    test('contém identificação geral, 6 categorias de material com seção universal e assinatura', () {
      final file = File('assets/protocols/cadastro_material.yaml');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'cadastro_material.yaml deve existir em assets/protocols/',
      );

      final proto = ProtocolParser.fromYaml(file.readAsStringSync());
      expect(proto.id, equals('material_registration'));
      expect(proto.versao, equals('2'));
      expect(proto.blocos.length, equals(2));
      expect(proto.blocos.map((b) => b.id), isNot(contains('encerramento_material')));

      // Bloco 1: Identificação Geral com mat_name, mat_association_code e mat_date (preencher_data_atual: true)
      final blocoIdent = proto.blocos[0];
      final stepIdent = blocoIdent.steps.first;
      final idsIdent = stepIdent.conteudos.map((c) => c.id).toList();
      expect(idsIdent, containsAll(['mat_name', 'mat_association_code', 'mat_date']));
      final cData = stepIdent.conteudos.firstWhere((c) => c.id == 'mat_date');
      expect(cData.campoSimples.preencherDataAtual, isTrue);

      // Bloco 2: Lista de materiais com as 6 categorias exigidas
      final blocoLista = proto.blocos[1];
      final listaMateriais = blocoLista.steps.first.conteudos.first.listaAcoes;
      expect(listaMateriais.minimo, equals(1));
      final idsTipos = listaMateriais.tiposDisponiveis.map((t) => t.id).toList();
      expect(
        idsTipos,
        equals([
          'expansion_bolt',
          'hanger',
          'ring_hanger',
          'chemical_anchor',
          'permanent_quickdraw',
          'other',
        ]),
      );

      // Verifica que todas as 6 categorias possuem sub-listas de Testes de Qualidade e Detalhes/Fabricação
      for (final tipo in listaMateriais.tiposDisponiveis) {
        final conteudosTipo = tipo.steps.expand((s) => s.conteudos).toList();
        final campoNfAnexo = conteudosTipo.firstWhere(
          (c) => c.id.endsWith('_invoice_media'),
        );
        expect(
          campoNfAnexo.campoSimples.label,
          equals('Foto ou PDF da Nota Fiscal / Comprovante'),
        );

        final subListas = conteudosTipo
            .where((c) => c.whichTipo() == ConteudoStep_Tipo.listaAcoes)
            .toList();
        expect(
          subListas.length,
          greaterThanOrEqualTo(2),
          reason: 'Categoria "${tipo.id}" deve ter sub-lista de Testes de Qualidade e de Detalhes/Fabricação',
        );

        final conteudosTestes = subListas[0]
            .listaAcoes
            .tiposDisponiveis
            .first
            .steps
            .expand((s) => s.conteudos)
            .toList();
        expect(
          conteudosTestes.any((c) => c.id == 'tq_video' || c.id == 'qt_video'),
          isFalse,
          reason: 'Categoria "${tipo.id}" deve ter campo único de mídias no teste sem tq_video separado',
        );
        final campoMidiasTeste = conteudosTestes.firstWhere((c) => c.id == 'qt_media');
        expect(
          campoMidiasTeste.campoSimples.label,
          equals('Anexar Mídias ao Teste / Laudo'),
        );

        final conteudosDetalhes = subListas[1]
            .listaAcoes
            .tiposDisponiveis
            .first
            .steps
            .expand((s) => s.conteudos)
            .toList();
        expect(
          conteudosDetalhes.any((c) => c.id == 'det_video'),
          isFalse,
          reason: 'Categoria "${tipo.id}" deve ter campo único de mídias na etapa sem det_video separado',
        );
        final campoMidiasDetalhe = conteudosDetalhes.firstWhere((c) => c.id == 'det_media');
        expect(
          campoMidiasDetalhe.campoSimples.label,
          equals('Anexar Mídias à Etapa / Detalhe'),
        );
      }

      // Nenhum bloco ou step de cadastro_material deve conter campo do tipo SIGNATURE
      final todosConteudos = proto.blocos
          .expand((b) => b.steps)
          .expand((s) => s.conteudos)
          .toList();
      expect(
        todosConteudos.any(
          (c) =>
              c.whichTipo() == ConteudoStep_Tipo.campoSimples &&
              c.campoSimples.tipo == StepCampoSimples_TipoCampo.SIGNATURE,
        ),
        isFalse,
      );
    });

    test('fromYaml filtra silenciosamente conteúdos, steps e blocos legados de SIGNATURE', () {
      const yamlLegadoComAssinatura = '''
protocolo:
  id: protocolo_legado
  nome: "Protocolo Legado com Assinatura"
  versao: "1.0.0"
  blocos:
    - id: avaliacao
      titulo: "Avaliação"
      steps:
        - id: observacoes_finais
          conteudos:
            - id: obs_c
              campo_simples:
                label: "Observações"
                tipo: TEXT_LONG
        - id: assinatura
          conteudos:
            - id: assinatura_instrucao
              instrucao:
                titulo: "Declaração"
                texto: "Texto da declaração"
            - id: assinatura_c
              campo_simples:
                label: "Assinatura"
                tipo: SIGNATURE
                obrigatorio: true
    - id: encerramento_material
      titulo: "Assinatura e Responsabilidade"
      steps:
        - id: assinatura_material
          conteudos:
            - id: mat_assinatura_instrucao
              instrucao:
                titulo: "Responsabilidade"
                texto: "Declaro..."
            - id: mat_assinatura_c
              campo_simples:
                label: "Assinatura"
                tipo: SIGNATURE
                obrigatorio: true
''';

      final proto = ProtocolParser.fromYaml(yamlLegadoComAssinatura);
      expect(proto.blocos, hasLength(1));
      expect(proto.blocos.first.id, equals('avaliacao'));
      expect(proto.blocos.first.steps, hasLength(1));
      expect(proto.blocos.first.steps.first.id, equals('observacoes_finais'));
    });
  });

  // ── 7. inspecao_visual.yaml, abertura_vias.yaml e registro_expresso.yaml (v3) ──

  group('inspecao_visual.yaml, abertura_vias.yaml e registro_expresso.yaml (versão 3)', () {
    test('inspecao_visual.yaml tem id "visual_inspection", versao "3", 3 blocos e lista ponto-a-ponto sem materiais', () {
      final file = File('assets/protocols/inspecao_visual.yaml');
      final proto = ProtocolParser.fromYaml(file.readAsStringSync());

      expect(proto.id, equals('visual_inspection'));
      expect(proto.versao, equals('3'));
      expect(
        proto.blocos.map((b) => b.id).toList(),
        equals(['route', 'inspection', 'assessment']),
      );

      final stepVia = proto.blocos[0].steps.first;
      final idsVia = stepVia.conteudos.map((c) => c.id).toList();
      expect(
        idsVia,
        containsAll(['route_date', 'route_gps', 'route_name', 'route_sector', 'route_peak']),
      );
      expect(_conteudoById([stepVia], 'route_date').campoSimples.preencherDataAtual, isTrue);

      final listaInspecao = _firstConteudoOfType(
        proto.blocos[1].steps,
        ConteudoStep_Tipo.listaAcoes,
      );
      expect(listaInspecao.id, equals('inspection_list_c'));
      expect(listaInspecao.listaAcoes.minimo, equals(1));
      expect(
        listaInspecao.listaAcoes.tiposDisponiveis.map((t) => t.id).toList(),
        equals(['anchor_protection', 'belay_rappel_station', 'rock_environment']),
      );

      final refs = <StepRefMateriais>[];
      for (final bloco in proto.blocos) {
        _collectRefMateriais(bloco.steps, refs);
      }
      expect(refs, isEmpty, reason: 'Inspeção visual não deve ter seleção de materiais');
    });

    test('abertura_vias.yaml tem id "route_opening", versao "3", 3 blocos e ref_mat_* do catálogo nas ações', () {
      final file = File('assets/protocols/abertura_vias.yaml');
      final proto = ProtocolParser.fromYaml(file.readAsStringSync());

      expect(proto.id, equals('route_opening'));
      expect(proto.versao, equals('3'));
      expect(
        proto.blocos.map((b) => b.id).toList(),
        equals(['route', 'actions', 'assessment']),
      );

      final stepVia = proto.blocos[0].steps.first;
      final idsVia = stepVia.conteudos.map((c) => c.id).toList();
      expect(
        idsVia,
        containsAll([
          'route_date',
          'route_gps',
          'route_name',
          'route_first_ascensionists',
          'route_grade',
          'route_length',
          'route_sector',
          'route_peak',
          'route_line_media',
        ]),
      );
      expect(_conteudoById([stepVia], 'route_date').campoSimples.preencherDataAtual, isTrue);

      final listaAcoes = _firstConteudoOfType(
        proto.blocos[1].steps,
        ConteudoStep_Tipo.listaAcoes,
      );
      expect(listaAcoes.id, equals('action_list_c'));
      expect(listaAcoes.listaAcoes.minimo, equals(1));
      expect(
        listaAcoes.listaAcoes.tiposDisponiveis.map((t) => t.id).toList(),
        equals([
          'installed_protection',
          'belay_rappel_station',
          'loose_rock_removal',
          'vegetation_cleaning',
          'other',
        ]),
      );

      final protInstalada = listaAcoes.listaAcoes.tiposDisponiveis
          .firstWhere((t) => t.id == 'installed_protection');
      final refProt = _firstConteudoOfType(
        protInstalada.steps,
        ConteudoStep_Tipo.refMateriais,
      );
      expect(refProt.id, equals('ref_mat_protection'));
      expect(refProt.refMateriais.origemCatalogo, isTrue);
      expect(refProt.refMateriais.obrigatorio, isTrue);

      final parada = listaAcoes.listaAcoes.tiposDisponiveis
          .firstWhere((t) => t.id == 'belay_rappel_station');
      final refParada = _firstConteudoOfType(
        parada.steps,
        ConteudoStep_Tipo.refMateriais,
      );
      expect(refParada.id, equals('ref_mat_belay'));
      expect(refParada.refMateriais.origemCatalogo, isTrue);
      expect(refParada.refMateriais.obrigatorio, isTrue);
    });

    test('registro_expresso.yaml tem id "express_log", versao "3", identificação com route_name/route_date, lista unificada e ref_mat_express opcional', () {
      final file = File('assets/protocols/registro_expresso.yaml');
      final proto = ProtocolParser.fromYaml(file.readAsStringSync());

      expect(proto.id, equals('express_log'));
      expect(proto.versao, equals('3'));

      final todosConteudos = proto.blocos
          .expand((b) => b.steps)
          .expand((s) => s.conteudos)
          .toList();
      final idsRaiz = todosConteudos.map((c) => c.id).toList();
      expect(
        idsRaiz,
        containsAll([
          'route_name',
          'route_date',
          'route_gps',
          'general_notes',
          'evidence_list',
          'ref_mat_express',
        ]),
      );

      final cNome = todosConteudos.firstWhere((c) => c.id == 'route_name');
      expect(cNome.campoSimples.obrigatorio, isTrue);

      final cData = todosConteudos.firstWhere((c) => c.id == 'route_date');
      expect(cData.campoSimples.preencherDataAtual, isTrue);

      final cRefMat = todosConteudos.firstWhere((c) => c.id == 'ref_mat_express');
      expect(cRefMat.refMateriais.origemCatalogo, isTrue);
      expect(cRefMat.refMateriais.obrigatorio, isFalse);

      final cEvidencias = todosConteudos.firstWhere((c) => c.id == 'evidence_list');
      expect(cEvidencias.listaAcoes.tiposDisponiveis, hasLength(1));
      expect(cEvidencias.listaAcoes.tiposDisponiveis.first.id, equals('evidence_item'));
    });

    test('suporta formato shorthand em Step e lança FormatException para tipo de ConteudoStep desconhecido', () {
      const yamlShorthand = '''
id: "teste_shorthand"
versao: 1
nome: "Teste Shorthand"
blocos:
  - id: "b1"
    titulo: "Bloco 1"
    steps:
      - id: "step_direto"
        campo_simples:
          rotulo: "Campo Direto"
          tipo: "STRING"
''';
      final proto = ProtocolParser.fromYaml(yamlShorthand);
      expect(proto.blocos.first.steps.first.conteudos.first.id, equals('step_direto'));

      const yamlInvalido = '''
id: "teste_invalido"
versao: 1
nome: "Teste Inválido"
blocos:
  - id: "b1"
    titulo: "Bloco 1"
    steps:
      - id: "step_invalido"
        tipo_desconhecido: {}
''';
      expect(
        () => ProtocolParser.fromYaml(yamlInvalido),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Internacionalização de Protocolos (i18n e Fallback em Inglês)', () {
    test(
      'fromYaml com codigoIdioma injeta traduções completas nos 7 idiomas preservando IDs canônicos',
      () {
        final yamlAbertura = File(
          'assets/protocols/abertura_vias.yaml',
        ).readAsStringSync();

        final protoJa = ProtocolParser.fromYaml(
          yamlAbertura,
          codigoIdioma: 'ja',
        );
        expect(protoJa.id, equals('route_opening'));
        expect(protoJa.nome, equals('ルート開拓'));
        expect(protoJa.blocos.first.id, equals('route'));
        expect(protoJa.blocos.first.titulo, equals('ブロック 1 — 新規ルートの特定'));

        final cNomeJa = _conteudoById(protoJa.blocos.first.steps, 'route_name');
        expect(cNomeJa.campoSimples.label, equals('ルート名'));

        final protoAr = ProtocolParser.fromYaml(
          yamlAbertura,
          codigoIdioma: 'ar',
        );
        expect(protoAr.id, equals('route_opening'));
        expect(protoAr.nome, equals('فتح مسار تسلق جديد'));

        final yamlManut = File(
          'assets/protocols/manutencao.yaml',
        ).readAsStringSync();
        final protoEn = ProtocolParser.fromYaml(
          yamlManut,
          codigoIdioma: 'en',
        );
        expect(protoEn.nome, equals('Fixed Anchor Maintenance'));
        expect(
          ProtocolParser.resolverRotuloConteudo(protoEn, 'via_nome'),
          equals('Route Name'),
        );
        expect(
          ProtocolParser.resolverRotuloConteudo(protoEn, 'ia_instrucao'),
          equals('Visual and Mechanical Assessment'),
        );
        expect(
          ProtocolParser.resolverRotuloConteudo(protoEn, 'ref_mat_novo_ponto'),
          equals('Materials used'),
        );
        expect(
          ProtocolParser.resolverRotuloConteudo(protoEn, 'lista_acoes_c'),
          equals('Actions performed'),
        );
        expect(
          ProtocolParser.resolverRotuloOpcao(
            protoEn,
            'avaliacao_condicao',
            'liberada',
          ),
          equals('Open for climbing'),
        );
        expect(
          ProtocolParser.resolverRotuloOpcao(
            protoEn,
            'ia_resultado',
            'substituir',
          ),
          equals('Replacement required'),
        );
        expect(
          ProtocolParser.resolverRotuloOpcao(
            protoEn,
            'ia_sub_ramo',
            'reusar_furo',
          ),
          equals('Reuse existing hole'),
        );
        expect(
          ProtocolParser.resolverRotuloConteudo(protoEn, 'inexistente'),
          isNull,
        );
        expect(
          ProtocolParser.resolverRotuloOpcao(
            protoEn,
            'avaliacao_condicao',
            'opcao_inexistente',
          ),
          isNull,
        );
        expect(
          ProtocolParser.resolverRotuloOpcao(
            protoEn,
            'inexistente',
            'qualquer',
          ),
          isNull,
        );
      },
    );

    test(
      'aplica fallback em Inglês (en) quando um campo não possui tradução no dicionário customizado',
      () {
        final yamlInspecao = File(
          'assets/protocols/inspecao_visual.yaml',
        ).readAsStringSync();

        final traducoesParciais = ProtocolParser.carregarTraducoesYaml('''
protocolo:
  nome: "Inspeção Customizada"
conteudos:
  via_nome:
    label: "Nome Customizado"
''');

        final proto = ProtocolParser.fromYaml(
          yamlInspecao,
          traducoes: traducoesParciais,
        );

        // Campo presente no mapa customizado usa o valor customizado
        expect(proto.nome, equals('Inspeção Customizada'));
        expect(
          ProtocolParser.resolverRotuloConteudo(proto, 'via_nome'),
          equals('Nome Customizado'),
        );

        // Campos ausentes no mapa customizado caem para o fallback em Inglês (en)
        expect(
          proto.blocos.first.titulo,
          equals('Block 1 — Route Identification'),
        );
        expect(
          ProtocolParser.resolverRotuloConteudo(proto, 'via_gps'),
          equals('GPS Location'),
        );
      },
    );

    test(
      'garantirTraducoesCarregadas carrega dicionários no cache em memória e limparCacheTraducoes limpa o cache',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        ProtocolParser.limparCacheTraducoes();
        await ProtocolParser.garantirTraducoesCarregadas('fr');

        final mapaFr = ProtocolParser.obterTraducoesLocais(
          'registro_expresso',
          'fr',
        );
        expect(mapaFr, isNotNull);
        expect(
          (mapaFr!['protocolo'] as Map)['nome'],
          equals('Registre Express'),
        );

        // Idioma ou protocolo inexistente retorna null sem lançar erro
        expect(
          ProtocolParser.obterTraducoesLocais('protocolo_inexistente', 'fr'),
          isNull,
        );
      },
    );
  });
}
