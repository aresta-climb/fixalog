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

  group('manutencao_ferragens.yaml — Feature 1 (multi-conteúdo)', () {
    late DefinicaoProtocolo proto;

    setUp(() {
      final file = File('assets/protocols/manutencao_ferragens.yaml');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'manutencao_ferragens.yaml não encontrado',
      );
      proto = ProtocolParser.fromYaml(file.readAsStringSync());
    });

    test('tem 4 blocos na ordem correta', () {
      expect(
        proto.blocos.map((b) => b.id).toList(),
        equals(['materiais', 'via', 'acoes', 'avaliacao']),
      );
    });

    test('bloco "materiais" tem ConteudoStep refMateriais "lista_materiais_c" com origemCatalogo=true', () {
      final bloco = proto.blocos.firstWhere((b) => b.id == 'materiais');
      final refC = _conteudoById(bloco.steps, 'lista_materiais_c');
      expect(refC.whichTipo(), equals(ConteudoStep_Tipo.refMateriais));
      expect(refC.refMateriais.origemCatalogo, isTrue);
      expect(refC.refMateriais.obrigatorio, isTrue);
    });

    test(
      'step "via_localizacao" tem múltiplos conteudos (instrucao + GPS + campos)',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'via');
        final step = bloco.steps.firstWhere((s) => s.id == 'via_localizacao');

        expect(
          step.conteudos.length,
          greaterThanOrEqualTo(3),
          reason:
              'via_localizacao deve ter instrucao + GPS + nome (mínimo 3 conteudos)',
        );

        final tipos = step.conteudos.map((c) => c.whichTipo()).toList();
        expect(tipos, contains(ConteudoStep_Tipo.instrucao));
        expect(tipos, contains(ConteudoStep_Tipo.campoSimples));
      },
    );

    test('step "assinatura" tem instrucao + SIGNATURE em sequência', () {
      final bloco = proto.blocos.firstWhere((b) => b.id == 'avaliacao');
      final step = bloco.steps.firstWhere((s) => s.id == 'assinatura');

      expect(step.conteudos.length, greaterThanOrEqualTo(2));
      expect(step.conteudos.first.whichTipo(), ConteudoStep_Tipo.instrucao);
      final lastC = step.conteudos.last;
      expect(lastC.whichTipo(), ConteudoStep_Tipo.campoSimples);
      expect(lastC.campoSimples.tipo, StepCampoSimples_TipoCampo.SIGNATURE);
      expect(lastC.campoSimples.obrigatorio, isTrue);
    });

    test(
      '"ia_avaliacao" (tipo inspecao_ancoragem) tem instrucao + IMAGE + SelecaoRamo no mesmo step',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'acoes');
        final listaC = _firstConteudoOfType(
          bloco.steps,
          ConteudoStep_Tipo.listaAcoes,
        );
        final inspecao = listaC.listaAcoes.tiposDisponiveis.firstWhere(
          (t) => t.id == 'inspecao_ancoragem',
        );
        final iaStep = inspecao.steps.firstWhere((s) => s.id == 'ia_avaliacao');

        final tipos = iaStep.conteudos.map((c) => c.whichTipo()).toList();
        expect(tipos, contains(ConteudoStep_Tipo.instrucao));
        expect(tipos, contains(ConteudoStep_Tipo.campoSimples));
        expect(tipos, contains(ConteudoStep_Tipo.selecaoRamo));
      },
    );

    test(
      '"avaliacao_geral" tem condição + comentários em sequência no mesmo step',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'avaliacao');
        final step = bloco.steps.firstWhere((s) => s.id == 'avaliacao_geral');

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

  group('manutencao_ferragens.yaml — Feature 2 (listas inline)', () {
    late DefinicaoProtocolo proto;

    setUp(() {
      proto = ProtocolParser.fromYaml(
        File('assets/protocols/manutencao_ferragens.yaml').readAsStringSync(),
      );
    });

    test(
      'bloco "acoes" tem ConteudoStep listaAcoes com id "lista_acoes_c" e 5 tipos',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'acoes');
        final listaC = _firstConteudoOfType(
          bloco.steps,
          ConteudoStep_Tipo.listaAcoes,
        );

        expect(listaC.id, equals('lista_acoes_c'));
        expect(listaC.listaAcoes.minimo, equals(1));
        expect(
          listaC.listaAcoes.tiposDisponiveis.map((t) => t.id).toList(),
          equals([
            'inspecao_ancoragem',
            'novo_ponto',
            'remocao_bloco',
            'limpeza_vegetacao',
            'outro',
          ]),
        );
      },
    );
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
      final bloco = proto.blocos.firstWhere((b) => b.id == 'acoes');
      final listaC = _firstConteudoOfType(
        bloco.steps,
        ConteudoStep_Tipo.listaAcoes,
      );
      final inspecao = listaC.listaAcoes.tiposDisponiveis.firstWhere(
        (t) => t.id == 'inspecao_ancoragem',
      );

      final iaStep = inspecao.steps.firstWhere((s) => s.id == 'ia_avaliacao');
      final resultadoC = _conteudoById([iaStep], 'ia_resultado');

      expect(resultadoC.whichTipo(), ConteudoStep_Tipo.selecaoRamo);
      expect(resultadoC.selecaoRamo.obrigatorio, isTrue);

      final ramoIds = resultadoC.selecaoRamo.ramos.map((r) => r.id).toList();
      expect(ramoIds, containsAll(['aprovado', 'reaperto', 'substituir']));
    });

    test(
      'ramo "substituir" contém um SelecaoRamo aninhado com "reusar_furo" e "novo_local"',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'acoes');
        final listaC = _firstConteudoOfType(
          bloco.steps,
          ConteudoStep_Tipo.listaAcoes,
        );
        final inspecao = listaC.listaAcoes.tiposDisponiveis.firstWhere(
          (t) => t.id == 'inspecao_ancoragem',
        );

        final iaStep = inspecao.steps.firstWhere((s) => s.id == 'ia_avaliacao');
        final resultadoC = _conteudoById([iaStep], 'ia_resultado');
        final ramoSub = resultadoC.selecaoRamo.ramos.firstWhere(
          (r) => r.id == 'substituir',
        );

        // o step dentro de "substituir" tem um conteudo SelecaoRamo
        expect(
          _hasConteudoOfType(ramoSub.steps, ConteudoStep_Tipo.selecaoRamo),
          isTrue,
          reason: 'Ramo "substituir" deve ter SelecaoRamo aninhado',
        );

        final subRamoC = _firstConteudoOfType(
          ramoSub.steps,
          ConteudoStep_Tipo.selecaoRamo,
        );
        final subRamoIds = subRamoC.selecaoRamo.ramos.map((r) => r.id).toList();
        expect(subRamoIds, containsAll(['reusar_furo', 'novo_local']));
      },
    );

    test(
      'sub-ramo "reusar_furo" tem RefMateriais apontando para "lista_materiais_c"',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'acoes');
        final listaC = _firstConteudoOfType(
          bloco.steps,
          ConteudoStep_Tipo.listaAcoes,
        );
        final inspecao = listaC.listaAcoes.tiposDisponiveis.firstWhere(
          (t) => t.id == 'inspecao_ancoragem',
        );

        final iaStep = inspecao.steps.firstWhere((s) => s.id == 'ia_avaliacao');
        final resultadoC = _conteudoById([iaStep], 'ia_resultado');
        final ramoSub = resultadoC.selecaoRamo.ramos.firstWhere(
          (r) => r.id == 'substituir',
        );
        final subRamoC = _firstConteudoOfType(
          ramoSub.steps,
          ConteudoStep_Tipo.selecaoRamo,
        );
        final ramoReusar = subRamoC.selecaoRamo.ramos.firstWhere(
          (r) => r.id == 'reusar_furo',
        );

        expect(
          _hasConteudoOfType(ramoReusar.steps, ConteudoStep_Tipo.refMateriais),
          isTrue,
          reason: 'Sub-ramo "reusar_furo" deve ter RefMateriais',
        );

        final refC = _firstConteudoOfType(
          ramoReusar.steps,
          ConteudoStep_Tipo.refMateriais,
        );
        expect(refC.refMateriais.idStepMateriais, equals('lista_materiais_c'));
      },
    );

    test(
      '"novo_ponto" tem RefMateriais que referencia "lista_materiais_c"',
      () {
        final bloco = proto.blocos.firstWhere((b) => b.id == 'acoes');
        final listaC = _firstConteudoOfType(
          bloco.steps,
          ConteudoStep_Tipo.listaAcoes,
        );
        final novoPonto = listaC.listaAcoes.tiposDisponiveis.firstWhere(
          (t) => t.id == 'novo_ponto',
        );

        final refC = _firstConteudoOfType(
          novoPonto.steps,
          ConteudoStep_Tipo.refMateriais,
          reason: 'novo_ponto deve ter RefMateriais',
        );
        expect(refC.refMateriais.idStepMateriais, equals('lista_materiais_c'));
        expect(refC.refMateriais.obrigatorio, isTrue);
      },
    );
  });

  // ── 5. Novos recursos do Parser para Materiais ──────────────────────────────

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
      expect(proto.id, equals('cadastro_material'));
      expect(proto.blocos.length, equals(3));

      // Bloco 1: Identificação Geral com mat_nome, mat_codigo_associacao e mat_data (preencher_data_atual: true)
      final blocoIdent = proto.blocos[0];
      final stepIdent = blocoIdent.steps.first;
      final idsIdent = stepIdent.conteudos.map((c) => c.id).toList();
      expect(idsIdent, containsAll(['mat_nome', 'mat_codigo_associacao', 'mat_data']));
      final cData = stepIdent.conteudos.firstWhere((c) => c.id == 'mat_data');
      expect(cData.campoSimples.preencherDataAtual, isTrue);

      // Bloco 2: Lista de materiais com as 6 categorias exigidas
      final blocoLista = proto.blocos[1];
      final listaMateriais = blocoLista.steps.first.conteudos.first.listaAcoes;
      expect(listaMateriais.minimo, equals(1));
      final idsTipos = listaMateriais.tiposDisponiveis.map((t) => t.id).toList();
      expect(
        idsTipos,
        equals([
          'parabolt',
          'chapeleta',
          'chapeleta_argola',
          'ancoragem_quimica',
          'costura_permanente',
          'outro',
        ]),
      );

      // Verifica que todas as 6 categorias possuem sub-listas de Testes de Qualidade e Detalhes/Fabricação
      for (final tipo in listaMateriais.tiposDisponiveis) {
        final conteudosTipo = tipo.steps.expand((s) => s.conteudos).toList();
        final campoNfAnexo = conteudosTipo.firstWhere(
          (c) => c.id.endsWith('_nf_foto'),
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
          conteudosTestes.any((c) => c.id == 'tq_video'),
          isFalse,
          reason: 'Categoria "${tipo.id}" deve ter campo único de mídias no teste sem tq_video separado',
        );
        final campoMidiasTeste = conteudosTestes.firstWhere((c) => c.id == 'tq_foto');
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
        final campoMidiasDetalhe = conteudosDetalhes.firstWhere((c) => c.id == 'det_foto');
        expect(
          campoMidiasDetalhe.campoSimples.label,
          equals('Anexar Mídias à Etapa / Detalhe'),
        );
      }

      // Bloco 3: Assinatura obrigatória
      final blocoAssinatura = proto.blocos[2];
      final stepAssinatura = blocoAssinatura.steps.last;
      expect(
        stepAssinatura.conteudos.last.campoSimples.tipo,
        equals(StepCampoSimples_TipoCampo.SIGNATURE),
      );
      expect(stepAssinatura.conteudos.last.campoSimples.obrigatorio, isTrue);
    });
  });
}
