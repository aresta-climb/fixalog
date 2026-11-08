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
    test('normaliza IDs legados para os IDs canônicos atuais e resolve caminhos de asset', () {
      expect(
        MigradorProtocoloRegistro.normalizarIdProtocolo('manutencao_ferragens'),
        equals('manutencao'),
      );
      expect(
        MigradorProtocoloRegistro.normalizarIdProtocolo('abertura_via_v1'),
        equals('abertura_vias'),
      );
      expect(
        MigradorProtocoloRegistro.normalizarIdProtocolo('inspecao_visual_v1'),
        equals('inspecao_visual'),
      );
      expect(
        MigradorProtocoloRegistro.normalizarIdProtocolo('registro_expresso'),
        equals('registro_expresso'),
      );
      expect(
        MigradorProtocoloRegistro.normalizarIdProtocolo('cadastro_material'),
        equals('cadastro_material'),
      );
      expect(
        MigradorProtocoloRegistro.caminhoAssetParaProtocolo('manutencao_ferragens'),
        equals('assets/protocols/manutencao.yaml'),
      );
    });
  });

  group('MigradorProtocoloRegistro — Migrações 1 -> 2 dos Protocolos Reais', () {
    test('migra registro legado de manutencao_ferragens (v2.1.0 -> v2) removendo Bloco 1 e renomeando ref_mat_* nas ações', () {
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

      expect(registro.idProtocolo, equals('manutencao'));
      expect(registro.versaoProtocolo, equals('2'));
      expect(registro.yamlConteudo, equals(yamlNovo));
      expect(registro.respostas.containsKey('lista_materiais_c'), isFalse);
      expect(registro.respostas.containsKey('assinatura_c'), isFalse);
      expect(registro.respostas['via_nome']?.texto, equals('Via dos Italianos'));
      expect(registro.respostas['via_data']?.texto, equals('10/05/2026'));

      expect(
        acaoReusar.respostasItem.containsKey('ia_sub_rf_materiais'),
        isFalse,
      );
      expect(
        acaoReusar.respostasItem['ref_mat_reusar_furo']?.lista.valores.first.texto,
        equals('mat-uuid-1'),
      );
      expect(
        acaoReusar.respostasItem['ref_mat_novo_local']?.lista.valores.first.texto,
        equals('mat-uuid-2'),
      );
      expect(
        acaoNovoPonto.respostasItem['ref_mat_novo_ponto']?.lista.valores.first.texto,
        equals('mat-uuid-1'),
      );
    });

    test('migra registro legado de abertura_via_v1 (v1.0.0 -> v2) mapeando campos da via e preenchendo data', () {
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

      expect(registro.idProtocolo, equals('abertura_vias'));
      expect(registro.versaoProtocolo, equals('2'));
      expect(registro.respostas['via_nome']?.texto, equals('Aresta Nova'));
      expect(registro.respostas['via_graduacao']?.texto, equals('7a'));
      expect(registro.respostas['via_gps']?.texto, equals('-22.9,-43.1'));
      expect(registro.respostas['via_foto_linha']?.midia.imagem.uuid, equals('img-linha'));
      expect(registro.respostas['via_data']?.texto, isNotEmpty);
      expect(registro.respostas.containsKey('nome_via'), isFalse);
    });

    test('migra registro legado de inspecao_visual_v1 (v1.0.0 -> v2) convertendo campos soltos em item de lista ponto-a-ponto', () {
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

      expect(registro.idProtocolo, equals('inspecao_visual'));
      expect(registro.versaoProtocolo, equals('2'));
      expect(registro.respostas.containsKey('estado_geral'), isFalse);
      expect(registro.respostas.containsKey('corrosao'), isFalse);
      expect(registro.respostas.containsKey('foto_evidencia'), isFalse);
      expect(registro.listas, hasLength(1));

      final item = registro.listas.first;
      expect(item.idLista, equals('lista_inspecao_c'));
      expect(item.idTipo, equals('protecao_ancoragem'));
      expect(item.respostasItem['iv_pa_posicao']?.texto, equals('Proteção 1'));
      expect(item.respostasItem['iv_pa_estado']?.texto, equals('critico'));
      expect(item.respostasItem['iv_pa_corrosao']?.texto, equals('true'));
      expect(item.respostasItem['iv_pa_midia']?.midia.imagem.uuid, equals('img-ev'));
    });

    test('migra registro legado de registro_expresso (v1.0.0 -> v2) unificando acao_foto e acao_video em lista_evidencias', () {
      final yamlNovo = File('assets/protocols/registro_expresso.yaml').readAsStringSync();
      final registro = Registro(
        idSessao: 'sessao-exp-1',
        idProtocolo: 'registro_expresso',
        versaoProtocolo: '1.0.0',
      );
      registro.respostas['gps'] = Resposta(texto: '-22.1,-43.2');

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

      expect(registro.idProtocolo, equals('registro_expresso'));
      expect(registro.versaoProtocolo, equals('2'));
      expect(registro.respostas['via_gps']?.texto, equals('-22.1,-43.2'));
      expect(registro.respostas.containsKey('gps'), isFalse);
      expect(registro.listas, hasLength(2));
      expect(registro.listas[0].idLista, equals('lista_evidencias'));
      expect(registro.listas[0].idTipo, equals('item_evidencia'));
      expect(registro.listas[0].respostasItem['ev_midia']?.midia.imagem.uuid, equals('u-foto'));
      expect(registro.listas[0].respostasItem['ev_descricao']?.texto, equals('Foto 1'));
      expect(registro.listas[1].idLista, equals('lista_evidencias'));
      expect(registro.listas[1].idTipo, equals('item_evidencia'));
      expect(registro.listas[1].respostasItem['ev_midia']?.midia.video.uuid, equals('u-video'));
      expect(registro.listas[1].respostasItem['ev_descricao']?.texto, equals('Vídeo 1'));
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
  id: manutencao
  nome: Manutenção
  versao: 2
  blocos:
    - id: via
      titulo: Bloco 1
      steps:
        - id: via_localizacao
          conteudos:
            - id: campo_novo_nao_migrado
              campo_simples:
                label: Novo
                tipo: TEXT
''';
      final errosTravaA = MigradorProtocoloRegistro.validarContratoProtocolos({
        'manutencao': yamlAlteradoSemSubirVersao,
      });
      expect(errosTravaA, isNotEmpty);
      expect(errosTravaA.first, contains('assinatura estrutural'));

      final protoAlterado = ProtocolParser.fromYaml(yamlAlteradoSemSubirVersao);
      final hashNovo = MigradorProtocoloRegistro.calcularAssinaturaEstrutural(protoAlterado);

      const yamlVersao3SemMigrador2Para3 = '''
protocolo:
  id: manutencao
  nome: Manutenção
  versao: 3
  blocos:
    - id: via
      titulo: Bloco 1
      steps:
        - id: via_localizacao
          conteudos:
            - id: campo_novo_nao_migrado
              campo_simples:
                label: Novo
                tipo: TEXT
''';
      final errosTravaB = MigradorProtocoloRegistro.validarContratoProtocolos(
        {'manutencao': yamlVersao3SemMigrador2Para3},
        assinaturasEsperadas: {
          'manutencao': (versaoAtual: 3, assinaturaEstrutural: hashNovo),
        },
      );
      expect(errosTravaB, isNotEmpty);
      expect(errosTravaB.first, contains('2 -> 3'));

      final errosNaoRegistrado = MigradorProtocoloRegistro.validarContratoProtocolos({
        'protocolo_desconhecido': yamlAlteradoSemSubirVersao,
      });
      expect(errosNaoRegistrado, isNotEmpty);
      expect(errosNaoRegistrado.first, contains('não possui versão e assinatura'));

      final errosVersaoDivergente = MigradorProtocoloRegistro.validarContratoProtocolos(
        {'manutencao': yamlVersao3SemMigrador2Para3},
        assinaturasEsperadas: {
          'manutencao': (versaoAtual: 2, assinaturaEstrutural: hashNovo),
        },
      );
      expect(errosVersaoDivergente, isNotEmpty);
      expect(errosVersaoDivergente.first, contains('declara versao 3, mas a versão registrada'));
    });
  });
}
