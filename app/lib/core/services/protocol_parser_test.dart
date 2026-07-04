import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/protocol_parser.dart';
import 'package:app/core/models/proto/protos/wizard.pb.dart';
import 'package:app/core/models/proto/protos/wizard.pbenum.dart';

void main() {
  group('ProtocolParser', () {
    test('parseia um protocolo YAML mínimo com um bloco e campo simples', () {
      const yaml = '''
protocolo:
  id: "test_protocol"
  nome: "Test Protocol"
  versao: "1.0.0"
  blocos:
    - id: "b1"
      titulo: "Bloco 1"
      steps:
        - id: "field_1"
          campo_simples:
            label: "Field 1"
            tipo: TEXT
            obrigatorio: true
        - id: "field_2"
          campo_simples:
            label: "Field 2"
            tipo: DROPDOWN
            ui_hint: LARGE_TILES
            opcoes:
              - valor: "opt1"
                label: "Option 1"
                icon_name: "home"
''';

      final protocol = ProtocolParser.fromYaml(yaml);

      expect(protocol.id, equals('test_protocol'));
      expect(protocol.nome, equals('Test Protocol'));
      expect(protocol.versao, equals('1.0.0'));
      expect(protocol.blocos.length, equals(1));

      final bloco = protocol.blocos[0];
      expect(bloco.id, 'b1');
      expect(bloco.steps.length, 2);

      final campoTexto = bloco.steps[0].campoSimples;
      expect(bloco.steps[0].id, 'field_1');
      expect(campoTexto.tipo, StepCampoSimples_TipoCampo.TEXT);
      expect(campoTexto.obrigatorio, isTrue);

      final campoDropdown = bloco.steps[1].campoSimples;
      expect(campoDropdown.tipo, StepCampoSimples_TipoCampo.DROPDOWN);
      expect(campoDropdown.uiHint, StepCampoSimples_UiHint.LARGE_TILES);
      expect(campoDropdown.opcoes[0].valor, 'opt1');
      expect(campoDropdown.opcoes[0].iconName, 'home');
    });

    test('parseia StepInstrucao com nível de alerta', () {
      const yaml = '''
protocolo:
  id: "inst_test"
  nome: "Instrução"
  versao: "1.0.0"
  blocos:
    - id: "b1"
      titulo: "Bloco"
      steps:
        - id: "aviso"
          instrucao:
            titulo: "Atenção"
            corpo: "Cuidado!"
            nivel_alerta: PERIGO
''';
      final protocol = ProtocolParser.fromYaml(yaml);
      final step = protocol.blocos[0].steps[0];

      expect(step.whichConteudo(), Step_Conteudo.instrucao);
      expect(step.instrucao.nivelAlerta, StepInstrucao_NivelAlerta.PERIGO);
    });

    test('parseia StepSelecaoRamo com sub-steps recursivos', () {
      const yaml = '''
protocolo:
  id: "ramo_test"
  nome: "Branching"
  versao: "1.0.0"
  blocos:
    - id: "b1"
      titulo: "Bloco"
      steps:
        - id: "escolha"
          selecao_ramo:
            label: "Qual?"
            obrigatorio: true
            ramos:
              - id: "sim"
                label: "Sim"
                steps:
                  - id: "detalhe_sim"
                    campo_simples:
                      label: "Detalhe"
                      tipo: TEXT
              - id: "nao"
                label: "Não"
                steps: []
''';
      final protocol = ProtocolParser.fromYaml(yaml);
      final step = protocol.blocos[0].steps[0];

      expect(step.whichConteudo(), Step_Conteudo.selecaoRamo);
      expect(step.selecaoRamo.ramos.length, 2);
      expect(step.selecaoRamo.ramos[0].id, 'sim');
      expect(step.selecaoRamo.ramos[0].steps.length, 1);
      expect(step.selecaoRamo.ramos[0].steps[0].id, 'detalhe_sim');
    });

    test('parseia StepListaAcoes com tipos disponíveis', () {
      const yaml = '''
protocolo:
  id: "lista_test"
  nome: "Lista"
  versao: "1.0.0"
  blocos:
    - id: "b1"
      titulo: "Bloco"
      steps:
        - id: "materiais"
          lista_acoes:
            label: "Materiais"
            minimo: 1
            maximo: 0
            tipos_disponiveis:
              - id: "parabolt"
                label: "Parabolt"
                steps:
                  - id: "pb_marca"
                    campo_simples:
                      label: "Marca"
                      tipo: TEXT
''';
      final protocol = ProtocolParser.fromYaml(yaml);
      final step = protocol.blocos[0].steps[0];

      expect(step.whichConteudo(), Step_Conteudo.listaAcoes);
      expect(step.listaAcoes.minimo, 1);
      expect(step.listaAcoes.tiposDisponiveis.length, 1);
      expect(step.listaAcoes.tiposDisponiveis[0].id, 'parabolt');
      expect(step.listaAcoes.tiposDisponiveis[0].steps.length, 1);
    });

    test('parseia StepRefMateriais', () {
      const yaml = '''
protocolo:
  id: "ref_test"
  nome: "Ref"
  versao: "1.0.0"
  blocos:
    - id: "b1"
      titulo: "Bloco"
      steps:
        - id: "sel_mat"
          ref_materiais:
            label: "Materiais usados"
            id_step_materiais: "lista_materiais"
            obrigatorio: true
''';
      final protocol = ProtocolParser.fromYaml(yaml);
      final step = protocol.blocos[0].steps[0];

      expect(step.whichConteudo(), Step_Conteudo.refMateriais);
      expect(step.refMateriais.idStepMateriais, 'lista_materiais');
      expect(step.refMateriais.obrigatorio, isTrue);
    });

    test('step desconhecido lança FormatException', () {
      const yaml = '''
protocolo:
  id: "err"
  nome: "Err"
  versao: "1.0.0"
  blocos:
    - id: "b1"
      titulo: "B"
      steps:
        - id: "broken"
          tipo_inexistente:
            label: "Vai quebrar"
''';
      expect(
        () => ProtocolParser.fromYaml(yaml),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
