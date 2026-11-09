// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/epub_document_builder.dart';

void main() {
  const yamlBaseManutencao = '''
protocolo:
  id: manutencao_ferragens
  nome: "Manutenção de Proteções Fixas"
  descricao: "Protocolo técnico de manutenção"
  versao: "2.1.0"
  blocos:
    - id: bloco_materiais
      titulo: "Bloco 1 — Materiais a Instalar"
      subtitulo: "Seleção do catálogo"
      steps:
        - id: s_mat
          conteudos:
            - id: inst_1
              instrucao:
                titulo: "Instrução que deve ser omitida"
                corpo: "Texto orientativo do wizard"
                nivel_alerta: INFO
            - id: lista_materiais_c
              ref_materiais:
                label: "Materiais a instalar"
                sublabel: "Do catálogo local"
                origem_catalogo: true
    - id: bloco_via
      titulo: "Bloco 2 — Identificação da Via"
      subtitulo: "Localização e dados básicos"
      steps:
        - id: s_via
          conteudos:
            - id: via_nome
              campo_simples:
                label: "Nome da via"
                tipo: TEXT
            - id: material
              campo_simples:
                label: "Liga Principal"
                sublabel: "Especificação metalúrgica"
                tipo: TEXT
            - id: posicao_metros
              campo_simples:
                label: "Posição (m)"
                tipo: NUMBER
            - id: queda_fator
              campo_simples:
                label: "Fator de Queda"
                tipo: NUMBER
            - id: aprovado
              campo_simples:
                label: "Inspeção Aprovada?"
                tipo: BOOLEAN
            - id: reprovado
              campo_simples:
                label: "Apresenta Falha?"
                tipo: BOOLEAN
            - id: condicao_via
              campo_simples:
                label: "Condição Final da Via"
                tipo: DROPDOWN
                ui_hint: LARGE_TILES
                opcoes:
                  - valor: liberada
                    label: "Liberada para escalada"
                    sublabel: "Via em boas condições"
            - id: obs_geral
              campo_simples:
                label: "Observações Gerais"
                sublabel: "Notas em Markdown"
                tipo: TEXT
                ui_hint: TEXT_AREA
            - id: foto_ancoragem
              campo_simples:
                label: "Foto da Ancoragem"
                tipo: IMAGE
            - id: foto_sem_mapeamento
              campo_simples:
                label: "Foto Sem Arquivo"
                tipo: IMAGE
            - id: video_ensaio
              campo_simples:
                label: "Vídeo do Ensaio"
                tipo: VIDEO
            - id: doc_laudo_geral
              campo_simples:
                label: "Laudo Geral em PDF"
                tipo: IMAGE
            - id: doc_sem_mapeamento
              campo_simples:
                label: "Documento Vazio"
                tipo: IMAGE
    - id: bloco_acoes
      titulo: "Bloco 3 — Ações de Manutenção"
      subtitulo: "Intervenções realizadas"
      steps:
        - id: s_acoes
          conteudos:
            - id: protecoes
              lista_acoes:
                label: "Ações Realizadas"
                sublabel: "Cada intervenção na via"
                tipos_disponiveis:
                  - id: grampo
                    label: "Inspeção de Ancoragem"
                    sublabel: "Avaliação mecânica"
                    steps:
                      - id: s_grampo
                        conteudos:
                          - id: tipo_fixacao
                            campo_simples:
                              label: "Tipo de Fixação"
                              tipo: TEXT
                          - id: torque_nm
                            campo_simples:
                              label: "Torque Aplicado (Nm)"
                              tipo: NUMBER
                          - id: quantidade
                            campo_simples:
                              label: "Quantidade"
                              tipo: NUMBER
                          - id: corrodo
                            campo_simples:
                              label: "Corroído?"
                              tipo: BOOLEAN
                          - id: trocado
                            campo_simples:
                              label: "Substituído?"
                              tipo: BOOLEAN
                          - id: ref_mat_grampo
                            ref_materiais:
                              label: "Materiais aplicados no ponto"
                              sublabel: "Do bloco 1"
                              id_step_materiais: "lista_materiais_c"
                          - id: foto_item
                            campo_simples:
                              label: "Foto Antes"
                              tipo: IMAGE
                          - id: foto_depois_item
                            campo_simples:
                              label: "Foto Depois"
                              tipo: IMAGE
                          - id: foto_sem_map
                            campo_simples:
                              label: "Foto Ausente"
                              tipo: IMAGE
                          - id: video_item
                            campo_simples:
                              label: "Vídeo da Proteção"
                              tipo: VIDEO
                          - id: mat_nota_fiscal
                            campo_simples:
                              label: "Nota Fiscal Anexada"
                              tipo: IMAGE
                          - id: det_descricao
                            campo_simples:
                              label: "Descrição da Etapa"
                              tipo: TEXT
                              ui_hint: TEXT_AREA
                          - id: sub_testes
                            lista_acoes:
                              label: "Testes de Qualidade"
                              sublabel: "Ensaios do lote"
                              tipos_disponiveis:
                                - id: teste_tracao
                                  label: "Ensaio de Tração"
                                  sublabel: "Carga axial"
                                  steps:
                                    - id: s_tt
                                      conteudos:
                                        - id: carga_obtida
                                          campo_simples:
                                            label: "Carga Obtida"
                                            tipo: TEXT
''';

  group('EpubDocumentBuilder - Testes Unitários', () {
    late EpubDocumentBuilder construtor;

    setUp(() {
      construtor = EpubDocumentBuilder();
    });

    test('gerarQrCodeSvg gera marcação SVG vetorial válida com dimensões escaláveis', () {
      final svgPadrao = EpubDocumentBuilder.gerarQrCodeSvg('https://fixalog.app/v/123');
      expect(() => XmlDocument.parse(svgPadrao), returnsNormally);
      expect(svgPadrao, startsWith('<svg xmlns="http://www.w3.org/2000/svg"'));
      expect(svgPadrao, contains('<rect width="100%" height="100%" fill="#ffffff"/>'));
      expect(svgPadrao, contains('fill="#000000"'));

      final svgGrande = EpubDocumentBuilder.gerarQrCodeSvg(
        'https://fixalog.app/v/123',
        moduloTamanho: 8,
      );
      expect(svgGrande, contains('width="8" height="8"'));
    });

    test('gerarCss deve retornar folha de estilos com regras de grade, cards, tela e impressão', () {
      final css = construtor.gerarCss();

      expect(css, contains('@media print'));
      expect(css, contains('@media screen'));
      expect(css, contains('.bloco-protocolo'));
      expect(css, contains('.grade-propriedades'));
      expect(css, contains('.grade-fotos'));
      expect(css, contains('.card-item-lista'));
      expect(css, contains('.destaque-escolha'));
      expect(css, contains('.cabecalho-versao-impressa'));
      expect(css, contains('.player-video'));
      expect(css, contains('.poster-impressao'));
    });

    test('gerarXhtml deve lançar FormatException quando yamlConteudo estiver vazio', () {
      final registroSemYaml = Registro()..idProtocolo = 'sem_yaml';
      expect(
        () => construtor.gerarXhtml(
          registro: registroSemYaml,
          idSessao: 'sessao_erro',
          urlCanonica: 'https://fixalog.app/v/sessao_erro',
        ),
        throwsFormatException,
      );
    });

    test('gerarXhtml deve compilar documento XHTML 5 válido com cabeçalho do protocolo e omitir StepInstrucao', () {
      final registro = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..versaoProtocolo = '2.1.0'
        ..utcTimestampFim = Int64(1762520400)
        ..yamlConteudo = yamlBaseManutencao
        ..respostas['via_nome'] = (Resposta()..texto = 'Via dos Italianos');

      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'sessao_abc',
        urlCanonica: 'https://fixalog.app/v/sessao_abc',
        qrCodeCanonica: 'midias/qr_principal.png',
      );

      expect(() => XmlDocument.parse(xhtml), returnsNormally);
      expect(xhtml, contains('<?xml version="1.0" encoding="utf-8"?>'));
      expect(xhtml, contains('<!DOCTYPE html>'));
      expect(xhtml, contains('xmlns="http://www.w3.org/1999/xhtml"'));
      expect(xhtml, contains('xmlns:epub="http://www.idpf.org/2007/ops"'));
      expect(xhtml, contains('Manutenção de Proteções Fixas'));
      expect(xhtml, contains('Via dos Italianos'));
      expect(xhtml, contains('v2.1.0'));
      expect(xhtml, contains('Bloco 2 — Identificação da Via'));
      expect(xhtml, isNot(contains('Instrução que deve ser omitida')));
      expect(xhtml, isNot(contains('Bloco 1 — Materiais a Instalar')));
      expect(xhtml, contains('https://fixalog.app/v/sessao_abc'));
      expect(xhtml, contains('<img src="midias/qr_principal.png" class="qr-code"'));
    });

    test('gerarXhtml deve renderizar campos simples em grade com rótulos humanos e destaque para LARGE_TILES', () {
      final registro = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..yamlConteudo = yamlBaseManutencao
        ..respostas['material'] = (Resposta()..texto = 'Titânio Grau 2')
        ..respostas['posicao_metros'] = (Resposta()..numero = 25.5)
        ..respostas['queda_fator'] = (Resposta()..inteiro = Int64(2))
        ..respostas['aprovado'] = (Resposta()..booleano = true)
        ..respostas['reprovado'] = (Resposta()..booleano = false)
        ..respostas['condicao_via'] = (Resposta()..texto = 'liberada');

      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'sessao_999',
        urlCanonica: 'https://fixalog.app/v/sessao_999',
      );

      expect(() => XmlDocument.parse(xhtml), returnsNormally);
      expect(xhtml, contains('class="grade-propriedades"'));
      expect(xhtml, contains('Liga Principal'));
      expect(xhtml, contains('Especificação metalúrgica'));
      expect(xhtml, contains('Titânio Grau 2'));
      expect(xhtml, contains('Posição (m)'));
      expect(xhtml, contains('25.5'));
      expect(xhtml, contains('Fator de Queda'));
      expect(xhtml, contains('>2<'));
      expect(xhtml, contains('Inspeção Aprovada?'));
      expect(xhtml, contains('>Sim<'));
      expect(xhtml, contains('Apresenta Falha?'));
      expect(xhtml, contains('>Não<'));

      expect(xhtml, contains('class="destaque-escolha"'));
      expect(xhtml, contains('Condição Final da Via'));
      expect(xhtml, contains('Liberada para escalada'));
      expect(xhtml, contains('Via em boas condições'));
    });

    test('gerarXhtml deve renderizar imagem em galeria com rótulo do campo e ignorar sem mapeamento', () {
      final registro = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..yamlConteudo = yamlBaseManutencao
        ..respostas['foto_ancoragem'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..imagem = (ArquivoImagem()
              ..uuid = 'uuid-foto-1'
              ..tipoOriginal = 'image/webp')))
        ..respostas['foto_sem_mapeamento'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..imagem = (ArquivoImagem()
              ..uuid = 'uuid-foto-2'
              ..tipoOriginal = 'image/webp')));

      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'sessao_foto',
        urlCanonica: 'https://fixalog.app/v/sessao_foto',
        mapeamentoMidias: {'uuid-foto-1': 'midias/uuid-foto-1.webp'},
      );

      expect(() => XmlDocument.parse(xhtml), returnsNormally);
      expect(xhtml, contains('class="grade-fotos"'));
      expect(xhtml, contains('Foto da Ancoragem'));
      expect(xhtml, contains('<img src="midias/uuid-foto-1.webp"'));
      expect(xhtml, isNot(contains('uuid-foto-2.webp')));
      expect(xhtml, isNot(contains('Foto Sem Arquivo')));
      expect(
        EpubDocumentBuilder.extrairMidiasDeResposta(registro.respostas['foto_ancoragem']),
        hasLength(1),
      );
    });

    test('gerarXhtml deve renderizar vídeo com rótulo, player e poster de impressão com QR Code', () {
      final registro = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..yamlConteudo = yamlBaseManutencao
        ..respostas['video_ensaio'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..video = (ArquivoVideo()
              ..uuid = 'uuid-video-1'
              ..tipoOriginal = 'video/mp4')));

      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'sessao_video',
        urlCanonica: 'https://fixalog.app/v/sessao_video',
        mapeamentoMidias: {'uuid-video-1': 'midias/uuid-video-1.mp4'},
        posterFrames: {'uuid-video-1': 'midias/uuid-video-1_poster.webp'},
        qrCodesVideos: {'uuid-video-1': 'midias/uuid-video-1_qr.png'},
      );

      expect(() => XmlDocument.parse(xhtml), returnsNormally);
      expect(xhtml, contains('<div id="video-uuid-video-1" class="container-video">'));
      expect(xhtml, contains('Vídeo do Ensaio'));
      expect(xhtml, contains('<video controls="controls"'));
      expect(xhtml, contains('poster="midias/uuid-video-1_poster.webp"'));
      expect(xhtml, contains('<source src="midias/uuid-video-1.mp4" type="video/mp4"'));
      expect(xhtml, contains('class="poster-impressao"'));
      expect(xhtml, contains('src="midias/uuid-video-1_qr.png"'));
      expect(xhtml, contains('Escaneie para assistir ao vídeo'));
    });

    test('gerarXhtml deve renderizar cards numerados de lista e aninhar sub-listas dentro do item pai', () {
      final grupo = GrupoRepetido()
        ..idLista = 'protecoes'
        ..idItem = 'item_1'
        ..idTipo = 'grampo'
        ..respostasItem['tipo_fixacao'] = (Resposta()..texto = 'Parabolt 3/8 inox')
        ..respostasItem['torque_nm'] = (Resposta()..numero = 35.5)
        ..respostasItem['quantidade'] = (Resposta()..inteiro = Int64(3))
        ..respostasItem['corrodo'] = (Resposta()..booleano = false)
        ..respostasItem['trocado'] = (Resposta()..booleano = true)
        ..respostasItem['foto_item'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..imagem = (ArquivoImagem()
              ..uuid = 'uuid-item-foto-1'
              ..tipoOriginal = 'image/webp')))
        ..respostasItem['foto_depois_item'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..imagem = (ArquivoImagem()
              ..uuid = 'uuid-item-foto-2'
              ..tipoOriginal = 'image/webp')))
        ..respostasItem['foto_sem_map'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..imagem = (ArquivoImagem()
              ..uuid = 'uuid-sem-map'
              ..tipoOriginal = 'image/webp')))
        ..respostasItem['video_item'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..video = (ArquivoVideo()
              ..uuid = 'uuid-item-video'
              ..tipoOriginal = 'video/mp4')));

      final subGrupo = GrupoRepetido()
        ..idLista = 'sub_testes__item_1'
        ..idItem = 'sub_1'
        ..idTipo = 'teste_tracao'
        ..respostasItem['carga_obtida'] = (Resposta()..texto = '28 kN sem deslocamento');

      final registro = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..yamlConteudo = yamlBaseManutencao
        ..listas.addAll([grupo, subGrupo]);

      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'sessao_lista',
        urlCanonica: 'https://fixalog.app/v/sessao_lista',
        mapeamentoMidias: {
          'uuid-item-foto-1': 'midias/uuid-item-foto-1.webp',
          'uuid-item-foto-2': 'midias/uuid-item-foto-2.webp',
          'uuid-item-video': 'midias/uuid-item-video.mp4',
        },
        posterFrames: {'uuid-item-video': 'midias/uuid-item-video_poster.webp'},
        qrCodesVideos: {'uuid-item-video': 'midias/uuid-item-video_qr.png'},
      );

      expect(() => XmlDocument.parse(xhtml), returnsNormally);
      expect(xhtml, contains('Ações Realizadas'));
      expect(xhtml, contains('#1'));
      expect(xhtml, contains('Inspeção de Ancoragem'));
      expect(xhtml, contains('Avaliação mecânica'));
      expect(xhtml, contains('Tipo de Fixação'));
      expect(xhtml, contains('Parabolt 3/8 inox'));
      expect(xhtml, contains('Torque Aplicado (Nm)'));
      expect(xhtml, contains('35.5'));
      expect(xhtml, contains('Foto Antes'));
      expect(xhtml, contains('Foto Depois'));
      expect(xhtml, contains('<img src="midias/uuid-item-foto-1.webp"'));
      expect(xhtml, contains('<img src="midias/uuid-item-foto-2.webp"'));
      expect(xhtml, contains('src="midias/uuid-item-video.mp4"'));

      // Sub-lista aninhada sem exibir o sufixo __item_1
      expect(xhtml, isNot(contains('sub_testes__item_1')));
      expect(xhtml, contains('Testes de Qualidade'));
      expect(xhtml, contains('#1.1'));
      expect(xhtml, contains('Ensaio de Tração'));
      expect(xhtml, contains('Carga Obtida'));
      expect(xhtml, contains('28 kN sem deslocamento'));
    });

    test('gerarXhtml deve incluir barra de retorno e links para materiais anexados via StepRefMateriais', () {
      final grupo = GrupoRepetido()
        ..idLista = 'protecoes'
        ..idItem = 'acao_1'
        ..idTipo = 'grampo'
        ..respostasItem['ref_mat_grampo'] = (Resposta()..texto = 'uuid-mat-1,uuid-mat-2');

      final registro = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..yamlConteudo = yamlBaseManutencao
        ..respostas['lista_materiais_c'] = (Resposta()..texto = 'uuid-mat-1,uuid-mat-2')
        ..listas.add(grupo);

      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'sessao_manut_1',
        urlCanonica: 'https://fixalog.app/v/sessao_manut_1',
        titulosMateriais: {
          'uuid-mat-1': 'Parabolt Inox 316L Petzl',
          'uuid-mat-2': 'Chapeleta Bonier Dupla',
        },
      );

      expect(() => XmlDocument.parse(xhtml), returnsNormally);
      expect(xhtml, contains('href="javascript:history.back()"'));
      expect(xhtml, contains('Voltar para a página anterior'));
      expect(xhtml, contains('Materiais a instalar'));
      expect(xhtml, contains('Materiais aplicados no ponto'));
      expect(
        xhtml,
        contains('href="materiais/uuid-mat-1/OEBPS/relatorio.xhtml"'),
      );
      expect(xhtml, contains('Parabolt Inox 316L Petzl'));
      expect(
        xhtml,
        contains('href="materiais/uuid-mat-2/OEBPS/relatorio.xhtml"'),
      );
      expect(xhtml, contains('Chapeleta Bonier Dupla'));

      expect(
        EpubDocumentBuilder.extrairUuidsMateriaisReferenciados(registro),
        equals(['uuid-mat-1', 'uuid-mat-2']),
      );
    });

    test('gerarXhtml deve renderizar documento PDF com link para download original e imagens das páginas', () {
      final grupo = GrupoRepetido()
        ..idLista = 'protecoes'
        ..idItem = 'item_1'
        ..idTipo = 'grampo'
        ..respostasItem['mat_nota_fiscal'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..documento = (ArquivoDocumento()
              ..uuid = 'uuid-doc-1'
              ..tipoOriginal = 'application/pdf'
              ..nomeOriginal = 'nota_petzl.pdf'
              ..quantidadePaginas = 2)));

      final registro = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..yamlConteudo = yamlBaseManutencao
        ..respostas['doc_laudo_geral'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..documento = (ArquivoDocumento()
              ..uuid = 'uuid-doc-geral'
              ..tipoOriginal = 'application/pdf'
              ..nomeOriginal = ''
              ..quantidadePaginas = 0)))
        ..respostas['doc_sem_mapeamento'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..documento = (ArquivoDocumento()
              ..uuid = 'uuid-doc-vazio'
              ..tipoOriginal = 'application/pdf'
              ..nomeOriginal = 'vazio.pdf'
              ..quantidadePaginas = 1)))
        ..listas.add(grupo);

      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'sessao_doc',
        urlCanonica: 'https://fixalog.app/v/sessao_doc',
        mapeamentoMidias: {
          'uuid-doc-1': 'midias/uuid-doc-1.pdf',
          'uuid-doc-1_p1': 'midias/uuid-doc-1_p1.webp',
          'uuid-doc-1_p2': 'midias/uuid-doc-1_p2.webp',
          'uuid-doc-geral': 'midias/uuid-doc-geral.pdf',
          'uuid-doc-geral_p1': 'midias/uuid-doc-geral_p1.webp',
        },
      );

      expect(() => XmlDocument.parse(xhtml), returnsNormally);
      expect(xhtml, contains('Nota Fiscal Anexada'));
      expect(
        xhtml,
        contains('href="midias/uuid-doc-1.pdf" download="nota_petzl.pdf" class="link-pdf-original"'),
      );
      expect(xhtml, contains('Baixar / Abrir PDF Original (nota_petzl.pdf)'));
      expect(xhtml, contains('nota_petzl.pdf — Página 1 de 2'));
      expect(xhtml, contains('<img src="midias/uuid-doc-1_p1.webp" alt="Página 1 de nota_petzl.pdf"/>'));
      expect(xhtml, contains('nota_petzl.pdf — Página 2 de 2'));
      expect(xhtml, contains('<img src="midias/uuid-doc-1_p2.webp" alt="Página 2 de nota_petzl.pdf"/>'));

      expect(
        xhtml,
        contains('href="midias/uuid-doc-geral.pdf" download="uuid-doc-geral.pdf" class="link-pdf-original"'),
      );
      expect(xhtml, contains('<img src="midias/uuid-doc-geral_p1.webp" alt="Página 1 de uuid-doc-geral.pdf"/>'));
      expect(xhtml, isNot(contains('vazio.pdf')));
    });

    test('gerarXhtml converte descrições com Markdown (headings, listas ul/ol e inline) em elementos XHTML5 válidos', () {
      const descricaoMarkdown = '''# Etapa de Soldagem
### Subtítulo Menor

Realizada solda **TIG** em aço *inox 316L* com código `LOTE-99` e ~~rebarba~~ removida.

- Decapagem ácida
- Passivação completa

1. Primeiro passo
2. Segundo passo''';

      final grupo = GrupoRepetido()
        ..idLista = 'protecoes'
        ..idItem = 'det_1'
        ..idTipo = 'grampo'
        ..respostasItem['det_descricao'] = (Resposta()..texto = descricaoMarkdown);

      final registro = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..yamlConteudo = yamlBaseManutencao
        ..respostas['obs_geral'] = (Resposta()..texto = 'Texto curto com **negrito**')
        ..listas.add(grupo);

      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'sessao_md',
        urlCanonica: 'https://fixalog.app/v/sessao_md',
      );

      expect(() => XmlDocument.parse(xhtml), returnsNormally);
      expect(xhtml, contains('<div class="conteudo-markdown">'));
      expect(xhtml, contains('<h4>Etapa de Soldagem</h4>'));
      expect(xhtml, contains('<h5>Subtítulo Menor</h5>'));
      expect(xhtml, contains('<strong>TIG</strong>'));
      expect(xhtml, contains('<em>inox 316L</em>'));
      expect(xhtml, contains('<code>LOTE-99</code>'));
      expect(xhtml, contains('<del>rebarba</del>'));
      expect(xhtml, contains('<ul><li>Decapagem ácida</li><li>Passivação completa</li></ul>'));
      expect(xhtml, contains('<ol><li>Primeiro passo</li><li>Segundo passo</li></ol>'));
      expect(xhtml, contains('Texto curto com <strong>negrito</strong>'));
    });

    test('compila e linka automaticamente materiais referenciados em ref_mat_* dentro das ações de Manutenção v2, Abertura de Vias v2 e Registro Expresso v2', () {
      final yamlManutencaoV2 = File('assets/protocols/manutencao.yaml').readAsStringSync();
      final acaoNovoPonto = GrupoRepetido(
        idLista: 'lista_acoes_c',
        idItem: 'item_np_1',
        idTipo: 'novo_ponto',
      )..respostasItem['ref_mat_novo_ponto'] = Resposta(
          lista: ListaRespostas(valores: [Resposta(texto: 'uuid-mat-direto-1')]),
        );

      final regManut = Registro(
        idSessao: 'sessao_manut_v2',
        idProtocolo: 'manutencao',
        versaoProtocolo: '2',
        yamlConteudo: yamlManutencaoV2,
      )
        ..respostas['via_nome'] = Resposta(texto: 'Via Leste')
        ..listas.add(acaoNovoPonto);

      expect(
        EpubDocumentBuilder.extrairUuidsMateriaisReferenciados(regManut),
        equals(['uuid-mat-direto-1']),
      );

      final xhtmlManut = construtor.gerarXhtml(
        registro: regManut,
        idSessao: 'sessao_manut_v2',
        urlCanonica: 'https://fixalog.app/v/sessao_manut_v2',
        titulosMateriais: {'uuid-mat-direto-1': 'Grampos Titânio Lote A'},
      );
      expect(() => XmlDocument.parse(xhtmlManut), returnsNormally);
      expect(xhtmlManut, contains('href="materiais/uuid-mat-direto-1/OEBPS/relatorio.xhtml"'));
      expect(xhtmlManut, contains('Grampos Titânio Lote A'));

      final yamlAberturaV2 = File('assets/protocols/abertura_vias.yaml').readAsStringSync();
      final acaoProt = GrupoRepetido(
        idLista: 'lista_acoes_c',
        idItem: 'item_prot_1',
        idTipo: 'protecao_instalada',
      )..respostasItem['ref_mat_protecao'] = Resposta(
          lista: ListaRespostas(valores: [Resposta(texto: 'uuid-mat-abertura-1')]),
        );

      final regAbertura = Registro(
        idSessao: 'sessao_abertura_v2',
        idProtocolo: 'abertura_vias',
        versaoProtocolo: '2',
        yamlConteudo: yamlAberturaV2,
      )
        ..respostas['via_nome'] = Resposta(texto: 'Via Conquista Nova')
        ..listas.add(acaoProt);

      expect(
        EpubDocumentBuilder.extrairUuidsMateriaisReferenciados(regAbertura),
        equals(['uuid-mat-abertura-1']),
      );

      final yamlExpressoV2 = File('assets/protocols/registro_expresso.yaml').readAsStringSync();
      final regExpresso = Registro(
        idSessao: 'sessao_expresso_v2',
        idProtocolo: 'registro_expresso',
        versaoProtocolo: '2',
        yamlConteudo: yamlExpressoV2,
      )
        ..respostas['via_nome'] = Resposta(texto: 'Ocorrência Trilha')
        ..respostas['ref_mat_expresso'] = Resposta(
          lista: ListaRespostas(valores: [Resposta(texto: 'uuid-mat-expresso-1')]),
        );

      expect(
        EpubDocumentBuilder.extrairUuidsMateriaisReferenciados(regExpresso),
        equals(['uuid-mat-expresso-1']),
      );
    });

    test('gerarCss inclui @font-face seletivo da família Noto Sans conforme o idioma do relatório', () {
      final cssPt = construtor.gerarCss(codigoIdioma: 'pt');
      expect(cssPt, contains("font-family: 'Noto Sans'"));
      expect(cssPt, contains("url('fonts/NotoSans-Regular.ttf')"));
      expect(cssPt, contains("url('fonts/NotoSans-Bold.ttf')"));
      expect(cssPt, isNot(contains('NotoSansArabic')));
      expect(cssPt, isNot(contains('NotoSansJP')));

      final cssAr = construtor.gerarCss(codigoIdioma: 'ar');
      expect(cssAr, contains("url('fonts/NotoSans-Regular.ttf')"));
      expect(cssAr, contains("font-family: 'Noto Sans Arabic'"));
      expect(cssAr, contains("url('fonts/NotoSansArabic-Regular.ttf')"));
      expect(cssAr, contains("url('fonts/NotoSansArabic-Bold.ttf')"));
      expect(cssAr, isNot(contains('NotoSansJP')));

      final cssJa = construtor.gerarCss(codigoIdioma: 'ja');
      expect(cssJa, contains("url('fonts/NotoSans-Regular.ttf')"));
      expect(cssJa, contains("font-family: 'Noto Sans JP'"));
      expect(cssJa, contains("url('fonts/NotoSansJP-Regular.ttf')"));
      expect(cssJa, contains("url('fonts/NotoSansJP-Bold.ttf')"));
      expect(cssJa, isNot(contains('NotoSansArabic')));
    });

    test('gerarXhtml compila laudo no idioma ativo (ja, en e ar com dir="rtl") resolvendo rótulos e opções traduzidos do protocolo', () {
      final yamlInspecao = File('assets/protocols/inspecao_visual.yaml').readAsStringSync();
      final regInspecao = Registro(
        idSessao: 'sessao_i18n_1',
        idProtocolo: 'inspecao_visual',
        versaoProtocolo: '2',
        yamlConteudo: yamlInspecao,
      )
        ..respostas['via_nome'] = Resposta(texto: 'Mount Fuji North Ridge')
        ..respostas['avaliacao_condicao'] = Resposta(texto: 'liberada');

      final xhtmlJa = construtor.gerarXhtml(
        registro: regInspecao,
        idSessao: 'sessao_i18n_1',
        urlCanonica: 'https://fixalog.app/v/sessao_i18n_1',
        codigoIdioma: 'ja',
        titulosMateriais: {'mat-1': 'チタンボルト'},
      );
      expect(() => XmlDocument.parse(xhtmlJa), returnsNormally);
      expect(xhtmlJa, contains('lang="ja"'));
      expect(xhtmlJa, isNot(contains('dir="rtl"')));
      expect(xhtmlJa, contains('固定支点の目視点検'));
      expect(xhtmlJa, contains('ルート名'));
      expect(xhtmlJa, contains('登攀可能（開放）'));
      expect(xhtmlJa, contains('セッション'));
      expect(xhtmlJa, contains('付録 — 参照資材カタログ'));

      final xhtmlAr = construtor.gerarXhtml(
        registro: regInspecao,
        idSessao: 'sessao_i18n_1',
        urlCanonica: 'https://fixalog.app/v/sessao_i18n_1',
        codigoIdioma: 'ar',
      );
      expect(() => XmlDocument.parse(xhtmlAr), returnsNormally);
      expect(xhtmlAr, contains('lang="ar" dir="rtl"'));
      expect(xhtmlAr, contains('الفحص البصري لنقاط التثبيت الثابتة'));
      expect(xhtmlAr, contains('اسم المسار'));
      expect(xhtmlAr, contains('مفتوح للتسلق'));
      expect(xhtmlAr, contains('الجلسة'));
    });
  });
}
