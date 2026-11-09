// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/migrador_protocolo_registro.dart';
import 'package:fixalog/core/services/protocol_parser.dart';

void main() {
  group('MigradorProtocoloRegistro — Normalização de IDs e Caminhos', () {
    test('normaliza IDs legados para os IDs canônicos atuais em inglês e resolve caminhos de asset', () {
      expect(
        MigradorProtocoloRegistro.normalizarIdProtocolo('manutencao_ferragens'),
        equals('maintenance'),
      );
      expect(
        MigradorProtocoloRegistro.normalizarIdProtocolo('manutencao'),
        equals('maintenance'),
      );
      expect(
        MigradorProtocoloRegistro.normalizarIdProtocolo('abertura_via_v1'),
        equals('route_opening'),
      );
      expect(
        MigradorProtocoloRegistro.normalizarIdProtocolo('abertura_vias'),
        equals('route_opening'),
      );
      expect(
        MigradorProtocoloRegistro.normalizarIdProtocolo('inspecao_visual_v1'),
        equals('visual_inspection'),
      );
      expect(
        MigradorProtocoloRegistro.normalizarIdProtocolo('inspecao_visual'),
        equals('visual_inspection'),
      );
      expect(
        MigradorProtocoloRegistro.normalizarIdProtocolo('registro_expresso'),
        equals('express_log'),
      );
      expect(
        MigradorProtocoloRegistro.normalizarIdProtocolo('cadastro_material'),
        equals('material_registration'),
      );
      expect(
        MigradorProtocoloRegistro.caminhoAssetParaProtocolo('manutencao_ferragens'),
        equals('assets/protocols/manutencao.yaml'),
      );
      expect(
        MigradorProtocoloRegistro.caminhoAssetParaProtocolo('maintenance'),
        equals('assets/protocols/manutencao.yaml'),
      );
    });
  });

  group('MigradorProtocoloRegistro — Migrações dos Protocolos Reais para IDs Canônicos em Inglês', () {
    test('migra registro legado de manutencao_ferragens (v2.1.0 -> v3) para maintenance e IDs em inglês', () {
      final yamlNovo = File('assets/protocols/manutencao.yaml').readAsStringSync();
      final timestampInicio = DateTime.utc(2026, 5, 10, 12, 0).millisecondsSinceEpoch ~/ 1000;

      final registro = Registro(
        idSessao: 'sessao-manut-1',
        idProtocolo: 'manutencao_ferragens',
        versaoProtocolo: '2.1.0',
        utcTimestampInicio: Int64(timestampInicio),
        yamlConteudo: 'yaml_antigo',
      );
      registro.respostas['lista_materiais_c'] = Resposta(
        lista: ListaRespostas(valores: [Resposta(texto: 'mat-uuid-1')]),
      );
      registro.respostas['via_nome'] = Resposta(texto: 'Via dos Italianos');
      registro.respostas['assinatura_c'] = Resposta(texto: 'legado');

      final acaoReusar = GrupoRepetido(
        idLista: 'lista_acoes_c',
        idItem: 'item-1',
        idTipo: 'inspecao_ancoragem',
      );
      acaoReusar.respostasItem['ia_sub_rf_materiais'] = Resposta(
        lista: ListaRespostas(valores: [Resposta(texto: 'mat-uuid-1')]),
      );
      acaoReusar.respostasItem['ia_sub_nl_materiais'] = Resposta(
        lista: ListaRespostas(valores: [Resposta(texto: 'mat-uuid-2')]),
      );

      final acaoNovoPonto = GrupoRepetido(
        idLista: 'lista_acoes_c',
        idItem: 'item-2',
        idTipo: 'novo_ponto',
      );
      acaoNovoPonto.respostasItem['np_materiais'] = Resposta(
        lista: ListaRespostas(valores: [Resposta(texto: 'mat-uuid-1')]),
      );

      registro.listas.addAll([acaoReusar, acaoNovoPonto]);

      MigradorProtocoloRegistro.migrarRegistro(registro, yamlAtual: yamlNovo);

      expect(registro.idProtocolo, equals('maintenance'));
      expect(registro.versaoProtocolo, equals('3'));
      expect(registro.yamlConteudo, equals(yamlNovo));
      expect(registro.respostas.containsKey('lista_materiais_c'), isFalse);
      expect(registro.respostas.containsKey('assinatura_c'), isFalse);
      expect(registro.respostas['route_name']?.texto, equals('Via dos Italianos'));
      expect(registro.respostas['route_date']?.texto, equals('10/05/2026'));

      expect(acaoReusar.idLista, equals('action_list_c'));
      expect(acaoReusar.idTipo, equals('anchor_inspection'));
      expect(
        acaoReusar.respostasItem.containsKey('ia_sub_rf_materiais'),
        isFalse,
      );
      expect(
        acaoReusar.respostasItem['ref_mat_reuse_hole']?.lista.valores.first.texto,
        equals('mat-uuid-1'),
      );
      expect(
        acaoReusar.respostasItem['ref_mat_new_location']?.lista.valores.first.texto,
        equals('mat-uuid-2'),
      );
      expect(acaoNovoPonto.idLista, equals('action_list_c'));
      expect(acaoNovoPonto.idTipo, equals('new_anchor_point'));
      expect(
        acaoNovoPonto.respostasItem['ref_mat_new_anchor']?.lista.valores.first.texto,
        equals('mat-uuid-1'),
      );
    });

    test('migra registro legado de abertura_via_v1 (v1.0.0 -> v3) para route_opening e IDs em inglês', () {
      final yamlNovo = File('assets/protocols/abertura_vias.yaml').readAsStringSync();
      final registro = Registro(
        idSessao: 'sessao-abertura-1',
        idProtocolo: 'abertura_via_v1',
        versaoProtocolo: '1.0.0',
        utcTimestampInicio: Int64(0),
      );
      registro.respostas['nome_via'] = Resposta(texto: 'Aresta Nova');
      registro.respostas['graduacao'] = Resposta(texto: '7a');
      registro.respostas['setor_gps'] = Resposta(texto: '-22.9,-43.1');
      registro.respostas['foto_linha'] = Resposta(
        midia: ReferenciaMidia(imagem: ArquivoImagem(uuid: 'img-linha')),
      );

      MigradorProtocoloRegistro.migrarRegistro(registro, yamlAtual: yamlNovo);

      expect(registro.idProtocolo, equals('route_opening'));
      expect(registro.versaoProtocolo, equals('3'));
      expect(registro.respostas['route_name']?.texto, equals('Aresta Nova'));
      expect(registro.respostas['route_grade']?.texto, equals('7a'));
      expect(registro.respostas['route_gps']?.texto, equals('-22.9,-43.1'));
      expect(registro.respostas['route_line_media']?.midia.imagem.uuid, equals('img-linha'));
      expect(registro.respostas['route_date']?.texto, isNotEmpty);
      expect(registro.respostas.containsKey('nome_via'), isFalse);
    });

    test('migra registro legado de inspecao_visual_v1 (v1.0.0 -> v3) para visual_inspection e IDs/opções em inglês', () {
      final yamlNovo = File('assets/protocols/inspecao_visual.yaml').readAsStringSync();
      final registro = Registro(
        idSessao: 'sessao-insp-1',
        idProtocolo: 'inspecao_visual_v1',
        versaoProtocolo: '1.0.0',
        utcTimestampInicio: Int64(1715342400),
      );
      registro.respostas['estado_geral'] = Resposta(texto: 'critico');
      registro.respostas['corrosao'] = Resposta(texto: 'true');
      registro.respostas['foto_evidencia'] = Resposta(
        midia: ReferenciaMidia(imagem: ArquivoImagem(uuid: 'img-ev')),
      );

      MigradorProtocoloRegistro.migrarRegistro(registro, yamlAtual: yamlNovo);

      expect(registro.idProtocolo, equals('visual_inspection'));
      expect(registro.versaoProtocolo, equals('3'));
      expect(registro.respostas.containsKey('estado_geral'), isFalse);
      expect(registro.respostas.containsKey('corrosao'), isFalse);
      expect(registro.respostas.containsKey('foto_evidencia'), isFalse);
      expect(registro.listas, hasLength(1));

      final item = registro.listas.first;
      expect(item.idLista, equals('inspection_list_c'));
      expect(item.idTipo, equals('anchor_protection'));
      expect(item.respostasItem['vi_ap_position']?.texto, equals('Proteção 1'));
      expect(item.respostasItem['vi_ap_condition']?.texto, equals('critical'));
      expect(item.respostasItem['vi_ap_corrosion']?.texto, equals('true'));
      expect(item.respostasItem['vi_ap_media']?.midia.imagem.uuid, equals('img-ev'));
    });

    test('migra registro legado de registro_expresso (v1.0.0 -> v3) para express_log e IDs em inglês', () {
      final yamlNovo = File('assets/protocols/registro_expresso.yaml').readAsStringSync();
      final registro = Registro(
        idSessao: 'sessao-exp-1',
        idProtocolo: 'registro_expresso',
        versaoProtocolo: '1.0.0',
      );
      registro.respostas['gps'] = Resposta(texto: '-22.1,-43.2');
      registro.respostas['via_data'] = Resposta(texto: '15/06/2026');

      final itemFoto = GrupoRepetido(
        idLista: 'lista_fotos',
        idItem: 'f1',
        idTipo: 'acao_foto',
      );
      itemFoto.respostasItem['foto'] = Resposta(
        midia: ReferenciaMidia(imagem: ArquivoImagem(uuid: 'u-foto')),
      );
      itemFoto.respostasItem['descricao'] = Resposta(texto: 'Foto 1');

      final itemVideo = GrupoRepetido(
        idLista: 'lista_fotos',
        idItem: 'v1',
        idTipo: 'acao_video',
      );
      itemVideo.respostasItem['video'] = Resposta(
        midia: ReferenciaMidia(video: ArquivoVideo(uuid: 'u-video')),
      );
      itemVideo.respostasItem['descricao'] = Resposta(texto: 'Vídeo 1');

      registro.listas.addAll([itemFoto, itemVideo]);

      MigradorProtocoloRegistro.migrarRegistro(registro, yamlAtual: yamlNovo);

      expect(registro.idProtocolo, equals('express_log'));
      expect(registro.versaoProtocolo, equals('3'));
      expect(registro.respostas['route_gps']?.texto, equals('-22.1,-43.2'));
      expect(registro.respostas.containsKey('gps'), isFalse);
      expect(registro.listas, hasLength(2));
      expect(registro.listas[0].idLista, equals('evidence_list'));
      expect(registro.listas[0].idTipo, equals('evidence_item'));
      expect(registro.listas[0].respostasItem['ev_media']?.midia.imagem.uuid, equals('u-foto'));
      expect(registro.listas[0].respostasItem['ev_description']?.texto, equals('Foto 1'));
      expect(registro.listas[1].idLista, equals('evidence_list'));
      expect(registro.listas[1].idTipo, equals('evidence_item'));
      expect(registro.listas[1].respostasItem['ev_media']?.midia.video.uuid, equals('u-video'));
      expect(registro.listas[1].respostasItem['ev_description']?.texto, equals('Vídeo 1'));
    });

    test('migra registro legado de cadastro_material (v1 -> v2) para material_registration e IDs em inglês', () {
      final yamlNovo = File('assets/protocols/cadastro_material.yaml').readAsStringSync();
      final registro = Registro(
        idSessao: 'sessao-mat-1',
        idProtocolo: 'cadastro_material',
        versaoProtocolo: '1',
      );
      registro.respostas['mat_nome'] = Resposta(texto: 'Kit Parabolt Inox');
      registro.respostas['mat_data'] = Resposta(texto: '01/05/2026');

      final itemParabolt = GrupoRepetido(
        idLista: 'lista_itens_material_c',
        idItem: 'p1',
        idTipo: 'parabolt',
      );
      itemParabolt.respostasItem['pb_marca'] = Resposta(texto: 'Bonier');
      itemParabolt.respostasItem['pb_liga'] = Resposta(texto: 'aco_inox_316');

      final itemDetalhe = GrupoRepetido(
        idLista: 'pb_detalhes__p1',
        idItem: 'd1',
        idTipo: 'detalhe_item',
      );
      itemDetalhe.respostasItem['det_titulo'] = Resposta(texto: 'Passivação');

      registro.listas.addAll([itemParabolt, itemDetalhe]);

      MigradorProtocoloRegistro.migrarRegistro(registro, yamlAtual: yamlNovo);

      expect(registro.idProtocolo, equals('material_registration'));
      expect(registro.versaoProtocolo, equals('2'));
      expect(registro.respostas['mat_name']?.texto, equals('Kit Parabolt Inox'));
      expect(registro.respostas['mat_date']?.texto, equals('01/05/2026'));
      expect(itemParabolt.idLista, equals('material_items_list_c'));
      expect(itemParabolt.idTipo, equals('expansion_bolt'));
      expect(itemParabolt.respostasItem['eb_brand']?.texto, equals('Bonier'));
      expect(itemParabolt.respostasItem['eb_alloy']?.texto, equals('stainless_steel_316'));
      expect(itemDetalhe.idLista, equals('eb_details__p1'));
      expect(itemDetalhe.idTipo, equals('manufacturing_detail'));
      expect(itemDetalhe.respostasItem['det_title']?.texto, equals('Passivação'));
    });

    test('executa múltiplos migradores em cadeia (v1 -> v2 -> v3 -> v4) na ordem sequencial correta', () {
      const yamlV4 = '''
protocolo:
  id: proto_teste
  nome: Teste Cadeia
  versao: 4
  blocos:
    - id: b1
      titulo: Bloco 1
      steps:
        - id: s1
          conteudos:
            - id: c1
              campo_simples:
                label: Campo
                tipo: TEXT
''';
      final ordemExecutada = <String>[];
      final migradoresCustom = <String, Map<int, PassoMigracaoProtocolo>>{
        'proto_teste': {
          1: (reg) {
            ordemExecutada.add('1->2');
            reg.respostas['passo'] = Resposta(texto: 'v2');
          },
          2: (reg) {
            ordemExecutada.add('2->3');
            reg.respostas['passo'] = Resposta(texto: '${reg.respostas['passo']!.texto}_v3');
          },
          3: (reg) {
            ordemExecutada.add('3->4');
            reg.respostas['passo'] = Resposta(texto: '${reg.respostas['passo']!.texto}_v4');
          },
        },
      };

      final registro = Registro(
        idSessao: 'sessao-cadeia',
        idProtocolo: 'proto_teste',
        versaoProtocolo: '1',
      );

      MigradorProtocoloRegistro.migrarRegistro(
        registro,
        yamlAtual: yamlV4,
        migradoresCustomizados: migradoresCustom,
      );

      expect(ordemExecutada, equals(['1->2', '2->3', '3->4']));
      expect(registro.versaoProtocolo, equals('4'));
      expect(registro.respostas['passo']?.texto, equals('v2_v3_v4'));
    });

    test('recusa migração lançando ExcecaoVersaoProtocoloNaoSuportada quando versaoOrigem é maior que versaoAlvo (bloqueio de downgrade)', () {
      final yamlAtual = File('assets/protocols/manutencao.yaml').readAsStringSync();
      final registroFuturo = Registro(
        idSessao: 'sessao-futura',
        idProtocolo: 'maintenance',
        versaoProtocolo: '99',
        yamlConteudo: 'yaml-da-v99',
      );

      expect(
        () => MigradorProtocoloRegistro.migrarRegistro(
          registroFuturo,
          yamlAtual: yamlAtual,
        ),
        throwsA(
          isA<ExcecaoVersaoProtocoloNaoSuportada>()
              .having((e) => e.idProtocolo, 'idProtocolo', 'maintenance')
              .having((e) => e.versaoRegistro, 'versaoRegistro', 99)
              .having((e) => e.versaoSuportada, 'versaoSuportada', 3)
              .having(
                (e) => e.toString(),
                'mensagem',
                allOf(
                  contains('versão 99'),
                  contains('versão 3'),
                  contains('Atualize o aplicativo'),
                ),
              ),
        ),
      );
      expect(registroFuturo.versaoProtocolo, equals('99'));
      expect(registroFuturo.yamlConteudo, equals('yaml-da-v99'));
    });
  });

  group('MigradorProtocoloRegistro — Trava Dupla de Contrato (Schema vs. Versão e Cadeia de Migradores)', () {
    test('Trava A e Trava B: todos os protocolos em assets/protocols/ cumprem o contrato de versão inteira, assinatura estrutural e migradores completos', () {
      final dir = Directory('assets/protocols');
      final arquivos = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yaml'))
          .toList();

      final yamlsPorId = <String, String>{};
      for (final arq in arquivos) {
        final conteudo = arq.readAsStringSync();
        final proto = ProtocolParser.fromYaml(conteudo);
        yamlsPorId[proto.id] = conteudo;
      }

      final erros = MigradorProtocoloRegistro.validarContratoProtocolos(yamlsPorId);
      expect(
        erros,
        isEmpty,
        reason: 'Falha de contrato nos protocolos YAML:\n${erros.join('\n')}',
      );
    });

    test('detecta violação quando um campo do YAML muda sem incrementar a versão ou quando falta um migrador intermediário na cadeia', () {
      const yamlAlteradoSemSubirVersao = '''
protocolo:
  id: maintenance
  nome: Maintenance
  versao: 3
  blocos:
    - id: route
      titulo: Block 1
      steps:
        - id: route_location
          conteudos:
            - id: new_unmigrated_field
              campo_simples:
                label: New
                tipo: TEXT
''';
      final errosTravaA = MigradorProtocoloRegistro.validarContratoProtocolos({
        'maintenance': yamlAlteradoSemSubirVersao,
      });
      expect(errosTravaA, isNotEmpty);
      expect(errosTravaA.first, contains('assinatura estrutural'));

      final protoAlterado = ProtocolParser.fromYaml(yamlAlteradoSemSubirVersao);
      final hashNovo = MigradorProtocoloRegistro.calcularAssinaturaEstrutural(protoAlterado);

      const yamlVersao4SemMigrador3Para4 = '''
protocolo:
  id: maintenance
  nome: Maintenance
  versao: 4
  blocos:
    - id: route
      titulo: Block 1
      steps:
        - id: route_location
          conteudos:
            - id: new_unmigrated_field
              campo_simples:
                label: New
                tipo: TEXT
''';
      final errosTravaB = MigradorProtocoloRegistro.validarContratoProtocolos(
        {'maintenance': yamlVersao4SemMigrador3Para4},
        assinaturasEsperadas: {
          'maintenance': (versaoAtual: 4, assinaturaEstrutural: hashNovo),
        },
      );
      expect(errosTravaB, isNotEmpty);
      expect(errosTravaB.first, contains('3 -> 4'));

      final errosNaoRegistrado = MigradorProtocoloRegistro.validarContratoProtocolos({
        'protocolo_desconhecido': yamlAlteradoSemSubirVersao,
      });
      expect(errosNaoRegistrado, isNotEmpty);
      expect(errosNaoRegistrado.first, contains('não possui versão e assinatura'));

      final errosVersaoDivergente = MigradorProtocoloRegistro.validarContratoProtocolos(
        {'maintenance': yamlVersao4SemMigrador3Para4},
        assinaturasEsperadas: {
          'maintenance': (versaoAtual: 3, assinaturaEstrutural: hashNovo),
        },
      );
      expect(errosVersaoDivergente, isNotEmpty);
      expect(errosVersaoDivergente.first, contains('declara versao 4, mas a versão registrada'));
    });
  });
}
