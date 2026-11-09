// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/serializador_yaml_registro.dart';

void main() {
  group('SerializadorYamlRegistro - Conversão YAML <-> Protobuf', () {
    test(
      'Dado um Registro completo com todos os tipos de Resposta, listas e yamlConteudo, Quando serializado para YAML e desserializado de volta, Então preserva todos os campos estaticamente tipados e formata yamlConteudo em bloco literal',
      () {
        final registroOriginal = Registro(
          idSessao: 'sessao-123',
          idProtocolo: 'manutencao',
          versaoProtocolo: '2',
          utcTimestampInicio: Int64(1762550000),
          utcTimestampFim: Int64(1762550500),
          idMantenedor: 'chave-pub-abc',
          attestationToken: 'token-xyz',
          assinaturaVisual: [1, 2, 3, 4],
          assinaturaDigital: [5, 6, 7, 8],
          yamlConteudo: 'id: manutencao\nversao: 2\nnome: "Manutenção"\n',
        );

        registroOriginal.respostas['via_nome'] = Resposta(
          texto: 'Via do Diedro',
        );
        registroOriginal.respostas['chave-com-hifen'] = Resposta(
          texto: 'Valor com chave quotada',
        );
        registroOriginal.respostas['observacao_multilinha'] = Resposta(
          texto: 'Linha 1\nLinha 2 sem quebra final',
        );
        registroOriginal.respostas['texto_vazio'] = Resposta(texto: '');
        registroOriginal.respostas['nota_decimal'] = Resposta(numero: 9.75);
        registroOriginal.respostas['quantidade_protecoes'] = Resposta(
          inteiro: Int64(12),
        );
        registroOriginal.respostas['via_liberada'] = Resposta(booleano: true);
        registroOriginal.respostas['foto_base'] = Resposta(
          midia: ReferenciaMidia(
            imagem: ArquivoImagem(
              uuid: 'img-1',
              tipoOriginal: 'image/jpeg',
              hashOriginal: 'hash-orig-img',
              tipoComprimido: 'image/webp',
              hashComprimido: 'hash-comp-img',
              versaoCompressao: 1,
            ),
          ),
        );
        registroOriginal.respostas['video_inspecao'] = Resposta(
          midia: ReferenciaMidia(
            video: ArquivoVideo(
              uuid: 'vid-1',
              tipoOriginal: 'video/mp4',
              hashOriginal: 'hash-orig-vid',
              tipoComprimido: 'video/mp4',
              hashComprimido: 'hash-comp-vid',
              versaoCompressao: 1,
            ),
          ),
        );
        registroOriginal.respostas['audio_laudo'] = Resposta(
          midia: ReferenciaMidia(
            audio: ArquivoAudio(
              uuid: 'aud-1',
              tipoOriginal: 'audio/aac',
              hashOriginal: 'hash-orig-aud',
              tipoComprimido: 'audio/aac',
              hashComprimido: 'hash-comp-aud',
              versaoCompressao: 1,
            ),
          ),
        );
        registroOriginal.respostas['nf_pdf'] = Resposta(
          midia: ReferenciaMidia(
            documento: ArquivoDocumento(
              uuid: 'doc-1',
              tipoOriginal: 'application/pdf',
              hashOriginal: 'hash-pdf',
              nomeOriginal: 'nota_fiscal.pdf',
              quantidadePaginas: 2,
              hashesPaginasWebp: ['hash-p1', 'hash-p2'],
            ),
          ),
        );

        final itemAcao = GrupoRepetido(
          idLista: 'lista_acoes_c',
          idItem: 'item-1',
          idTipo: 'novo_ponto',
        );
        itemAcao.respostasItem['ref_mat_novo_ponto'] = Resposta(
          lista: ListaRespostas(
            valores: [
              Resposta(texto: 'mat-uuid-1'),
              Resposta(texto: 'mat-uuid-2'),
            ],
          ),
        );
        itemAcao.respostasItem['lista_vazia'] = Resposta(
          lista: ListaRespostas(valores: []),
        );
        registroOriginal.listas.add(itemAcao);

        final yamlGerado = SerializadorYamlRegistro.paraYaml(registroOriginal);

        expect(yamlGerado, contains('yamlConteudo: |'));
        expect(yamlGerado, contains('  id: manutencao'));
        expect(yamlGerado, contains('  versao: 2'));

        final registroReconstruido = SerializadorYamlRegistro.deYaml(yamlGerado);

        expect(registroReconstruido, equals(registroOriginal));
        expect(registroReconstruido.idSessao, 'sessao-123');
        expect(registroReconstruido.versaoProtocolo, '2');
        expect(
          registroReconstruido.respostas['via_nome']?.texto,
          'Via do Diedro',
        );
        expect(
          registroReconstruido.respostas['observacao_multilinha']?.texto,
          'Linha 1\nLinha 2 sem quebra final',
        );
        expect(
          registroReconstruido.respostas['nf_pdf']?.midia.documento.hashesPaginasWebp,
          ['hash-p1', 'hash-p2'],
        );
        expect(
          registroReconstruido.listas.single.respostasItem['ref_mat_novo_ponto']
              ?.lista.valores
              .map((v) => v.texto)
              .toList(),
          ['mat-uuid-1', 'mat-uuid-2'],
        );
      },
    );

    test(
      'Dado um YAML com estrutura inválida ou campo desconhecido no schema Protobuf, Quando deYaml é chamado, Então lança FormatException',
      () {
        expect(
          () => SerializadorYamlRegistro.deYaml('apenas_texto_escalar'),
          throwsFormatException,
        );

        expect(
          () => SerializadorYamlRegistro.deYaml(
            'campoInexistenteNoProto: "valor"\n',
          ),
          throwsFormatException,
        );
      },
    );

    test(
      'Dado um mapa de arquivos de EPUB com registro.yaml ou fallback registro.binarypb, Quando lerDeMapaArquivos é chamado, Então reconstrói o Registro ou lança FormatException se ausente',
      () {
        final reg = Registro(
          idSessao: 's-yaml',
          idProtocolo: 'manutencao',
          versaoProtocolo: '2',
        );
        final bytesYaml = Uint8List.fromList(
          utf8.encode(SerializadorYamlRegistro.paraYaml(reg)),
        );
        final lidoYaml = SerializadorYamlRegistro.lerDeMapaArquivos({
          'OEBPS/dados/registro.yaml': bytesYaml,
        });
        expect(lidoYaml.idSessao, 's-yaml');

        final regPb = Registro(
          idSessao: 's-pb',
          idProtocolo: 'manutencao',
          versaoProtocolo: '1',
        );
        final lidoPb = SerializadorYamlRegistro.lerDeMapaArquivos({
          'OEBPS/dados/registro.binarypb': Uint8List.fromList(
            regPb.writeToBuffer(),
          ),
        });
        expect(lidoPb.idSessao, 's-pb');

        expect(
          () => SerializadorYamlRegistro.lerDeMapaArquivos({}),
          throwsFormatException,
        );
      },
    );
  });

  group('SerializadorYamlRegistro - Trava de Sincronia .proto <-> .pb.dart', () {
    test(
      'Dados os arquivos reais protos/registro.proto e protos/wizard.proto, Quando validarSincroniaSchemasProto é executado, Então retorna zero divergências',
      () {
        final registroProto = File('protos/registro.proto').readAsStringSync();
        final wizardProto = File('protos/wizard.proto').readAsStringSync();

        final erros = SerializadorYamlRegistro.validarSincroniaSchemasProto(
          conteudoRegistroProto: registroProto,
          conteudoWizardProto: wizardProto,
        );

        expect(erros, isEmpty);
      },
    );

    test(
      'Dado um arquivo .proto com mensagem ausente, campo divergente ou campo extra não compilado, Quando validarSincroniaSchemasProto é executado, Então reporta todas as divergências',
      () {
        final registroProtoOriginal =
            File('protos/registro.proto').readAsStringSync();
        final wizardProtoOriginal =
            File('protos/wizard.proto').readAsStringSync();

        final registroProtoAdulterado = registroProtoOriginal
            .replaceFirst(
              'string id_sessao            = 1;',
              'string id_sessao_alterado   = 1;\n  string campo_fantasma = 99;',
            )
            .replaceFirst('message ArquivoAudio {', 'message AudioRenomeado {');

        final erros = SerializadorYamlRegistro.validarSincroniaSchemasProto(
          conteudoRegistroProto: registroProtoAdulterado,
          conteudoWizardProto: wizardProtoOriginal,
        );

        expect(
          erros,
          contains(
            allOf(
              contains('Registro'),
              contains('tag 1'),
            ),
          ),
        );
        expect(
          erros,
          contains(
            allOf(
              contains('Registro'),
              contains('tag 99'),
            ),
          ),
        );
        expect(
          erros,
          contains(contains('ArquivoAudio')),
        );
        expect(
          erros,
          contains(contains('AudioRenomeado')),
        );
      },
    );
  });
}
