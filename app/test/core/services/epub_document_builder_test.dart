// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/epub_document_builder.dart';

void main() {
  group('EpubDocumentBuilder - Testes Unitários', () {
    late EpubDocumentBuilder construtor;

    setUp(() {
      construtor = EpubDocumentBuilder();
    });

    test('gerarCss deve retornar folha de estilos com regras de tela e impressão', () {
      final css = construtor.gerarCss();

      expect(css, contains('@media print'));
      expect(css, contains('@media screen'));
      expect(css, contains('.cabecalho-versao-impressa'));
      expect(css, contains('.player-video'));
      expect(css, contains('.poster-impressao'));
    });

    test('gerarXhtml deve compilar documento XHTML 5 válido com namespace EPUB', () {
      final registro = Registro()..idProtocolo = 'protocolo_teste_123';
      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'sessao_abc',
        urlCanonica: 'https://fixalog.app/v/sessao_abc',
        qrCodeCanonica: 'midias/qr_principal.png',
      );

      expect(xhtml, contains('<?xml version="1.0" encoding="utf-8"?>'));
      expect(xhtml, contains('<!DOCTYPE html>'));
      expect(xhtml, contains('xmlns="http://www.w3.org/1999/xhtml"'));
      expect(xhtml, contains('xmlns:epub="http://www.idpf.org/2007/ops"'));
      expect(xhtml, contains('protocolo_teste_123'));
      expect(xhtml, contains('https://fixalog.app/v/sessao_abc'));
      expect(xhtml, contains('<img src="midias/qr_principal.png" class="qr-code"'));
    });

    test('gerarXhtml deve renderizar respostas de texto, números, inteiros e booleanos', () {
      final registro = Registro()
        ..idProtocolo = 'via_do_fenda'
        ..respostas['material'] = (Resposta()..texto = 'Titânio Grau 2')
        ..respostas['posicao_metros'] = (Resposta()..numero = 25.5)
        ..respostas['queda_fator'] = (Resposta()..inteiro = Int64(2))
        ..respostas['aprovado'] = (Resposta()..booleano = true)
        ..respostas['reprovado'] = (Resposta()..booleano = false);

      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'sessao_999',
        urlCanonica: 'https://fixalog.app/v/sessao_999',
      );

      expect(xhtml, contains('>material:</span> <span>Titânio Grau 2</span>'));
      expect(xhtml, contains('>posicao_metros:</span> <span>25.5</span>'));
      expect(xhtml, contains('>queda_fator:</span> <span>2</span>'));
      expect(xhtml, contains('>aprovado:</span> <span>Sim</span>'));
      expect(xhtml, contains('>reprovado:</span> <span>Não</span>'));
    });

    test('gerarXhtml deve renderizar imagem com tag img e ignorar sem mapeamento', () {
      final registro = Registro()
        ..idProtocolo = 'inspecao_chapeleta'
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

      expect(xhtml, contains('<img src="midias/uuid-foto-1.webp"'));
      expect(xhtml, isNot(contains('uuid-foto-2.webp')));
    });

    test('gerarXhtml deve renderizar vídeo com player e poster de impressão com QR Code', () {
      final registro = Registro()
        ..idProtocolo = 'inspecao_video'
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

      // Player de tela
      expect(xhtml, contains('<video controls="controls"'));
      expect(xhtml, contains('poster="midias/uuid-video-1_poster.webp"'));
      expect(xhtml, contains('<source src="midias/uuid-video-1.mp4" type="video/mp4"'));

      // Fallback para impressão no PDF
      expect(xhtml, contains('class="poster-impressao"'));
      expect(xhtml, contains('src="midias/uuid-video-1_qr.png"'));
      expect(xhtml, contains('Escaneie para assistir ao vídeo'));
    });

    test('gerarXhtml deve renderizar todos os tipos de respostas em listas repetidas', () {
      final grupo = GrupoRepetido()
        ..idLista = 'protecoes'
        ..idItem = 'item_1'
        ..idTipo = 'grampo'
        ..respostasItem['tipo_fixacao'] = (Resposta()..texto = 'Parabolt 3/8 inox')
        ..respostasItem['torque_nm'] = (Resposta()..numero = 35.0)
        ..respostasItem['quantidade'] = (Resposta()..inteiro = Int64(3))
        ..respostasItem['corrodo'] = (Resposta()..booleano = false)
        ..respostasItem['trocado'] = (Resposta()..booleano = true)
        ..respostasItem['foto_item'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..imagem = (ArquivoImagem()
              ..uuid = 'uuid-item-foto'
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

      final registro = Registro()
        ..idProtocolo = 'via_longa'
        ..listas.add(grupo);

      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'sessao_lista',
        urlCanonica: 'https://fixalog.app/v/sessao_lista',
        mapeamentoMidias: {
          'uuid-item-foto': 'midias/uuid-item-foto.webp',
          'uuid-item-video': 'midias/uuid-item-video.mp4',
        },
        posterFrames: {'uuid-item-video': 'midias/uuid-item-video_poster.webp'},
        qrCodesVideos: {'uuid-item-video': 'midias/uuid-item-video_qr.png'},
      );

      expect(xhtml, contains('protecoes'));
      expect(xhtml, contains('>tipo_fixacao:</span> <span>Parabolt 3/8 inox</span>'));
      expect(xhtml, contains('>torque_nm:</span> <span>35.0</span>'));
      expect(xhtml, contains('>quantidade:</span> <span>3</span>'));
      expect(xhtml, contains('>corrodo:</span> <span>Não</span>'));
      expect(xhtml, contains('>trocado:</span> <span>Sim</span>'));
      expect(xhtml, contains('<img src="midias/uuid-item-foto.webp"'));
      expect(xhtml, contains('src="midias/uuid-item-video.mp4"'));
    });

    test('gerarXhtml com registro vazio não deve falhar', () {
      final registro = Registro();
      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'vazio',
        urlCanonica: 'https://fixalog.app/v/vazio',
      );

      expect(xhtml, contains('<!DOCTYPE html>'));
      expect(xhtml, contains('Sessão ID:</strong> vazio'));
    });

    test('gerarXhtml deve incluir barra de retorno à página anterior e links para materiais anexados', () {
      final grupo = GrupoRepetido()
        ..idLista = 'lista_acoes_via_c'
        ..idItem = 'acao_1'
        ..idTipo = 'grampo'
        ..respostasItem['ref_mat_grampo'] = (Resposta()..texto = 'uuid-mat-1,uuid-mat-2');

      final registro = Registro()
        ..idProtocolo = 'manutencao_ferragens'
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

      // Deve conter o botão de voltar à página anterior para navegação no EPUB
      expect(xhtml, contains('href="javascript:history.back()"'));
      expect(xhtml, contains('Voltar para a página anterior'));

      // Deve conter hiperlinks apontando para materiais/<uuid>/OEBPS/relatorio.xhtml
      expect(
        xhtml,
        contains('href="materiais/uuid-mat-1/OEBPS/relatorio.xhtml"'),
      );
      expect(
        xhtml,
        contains('Parabolt Inox 316L Petzl'),
      );
      expect(
        xhtml,
        contains('href="materiais/uuid-mat-2/OEBPS/relatorio.xhtml"'),
      );
      expect(
        xhtml,
        contains('Chapeleta Bonier Dupla'),
      );
    });

    test('gerarXhtml deve renderizar documento PDF com link para download original e imagens das páginas em respostas e listas', () {
      final grupo = GrupoRepetido()
        ..idLista = 'lista_materiais_cadastro'
        ..idItem = 'item_1'
        ..idTipo = 'chumbador_mecanico'
        ..respostasItem['mat_nota_fiscal'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..documento = (ArquivoDocumento()
              ..uuid = 'uuid-doc-1'
              ..tipoOriginal = 'application/pdf'
              ..nomeOriginal = 'nota_petzl.pdf'
              ..quantidadePaginas = 2)));

      final registro = Registro()
        ..idProtocolo = 'cadastro_material'
        ..respostas['doc_laudo_geral'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..documento = (ArquivoDocumento()
              ..uuid = 'uuid-doc-geral'
              ..tipoOriginal = 'application/pdf'
              ..nomeOriginal = ''
              ..quantidadePaginas = 1)))
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

      // Link para o PDF original no item repetido
      expect(
        xhtml,
        contains('href="midias/uuid-doc-1.pdf" download="nota_petzl.pdf" class="link-pdf-original"'),
      );
      expect(xhtml, contains('Baixar / Abrir PDF Original (nota_petzl.pdf)'));
      expect(xhtml, contains('nota_petzl.pdf — Página 1 de 2'));
      expect(xhtml, contains('<img src="midias/uuid-doc-1_p1.webp" alt="Página 1 de nota_petzl.pdf"/>'));
      expect(xhtml, contains('nota_petzl.pdf — Página 2 de 2'));
      expect(xhtml, contains('<img src="midias/uuid-doc-1_p2.webp" alt="Página 2 de nota_petzl.pdf"/>'));

      // Documento em resposta simples usando fallback de nome (<uuid>.pdf)
      expect(
        xhtml,
        contains('href="midias/uuid-doc-geral.pdf" download="uuid-doc-geral.pdf" class="link-pdf-original"'),
      );
      expect(xhtml, contains('<img src="midias/uuid-doc-geral_p1.webp" alt="Página 1 de uuid-doc-geral.pdf"/>'));

      // Documento sem mapeamento não deve renderizar container vazio
      expect(xhtml, isNot(contains('vazio.pdf')));
    });

    test('gerarXhtml renderiza múltiplas mídias (fotos, vídeos e PDFs) contidas na mesma Resposta.lista', () {
      final respostaMultiMidia = Resposta(
        lista: ListaRespostas(
          valores: [
            Resposta(
              midia: ReferenciaMidia(
                imagem: ArquivoImagem(uuid: 'uuid-foto-multi'),
              ),
            ),
            Resposta(
              midia: ReferenciaMidia(
                video: ArquivoVideo(uuid: 'uuid-video-multi'),
              ),
            ),
            Resposta(
              midia: ReferenciaMidia(
                documento: ArquivoDocumento(
                  uuid: 'uuid-pdf-multi',
                  nomeOriginal: 'certificado_lote.pdf',
                  quantidadePaginas: 1,
                ),
              ),
            ),
          ],
        ),
      );

      final grupo = GrupoRepetido()
        ..idLista = 'sub_detalhes'
        ..idItem = 'etapa_1'
        ..idTipo = 'detalhe_fabricacao'
        ..respostasItem['det_foto'] = respostaMultiMidia;

      final registro = Registro()
        ..idProtocolo = 'cadastro_material'
        ..respostas['etapa_raiz_midias'] = respostaMultiMidia
        ..listas.add(grupo);

      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'sessao_multi',
        urlCanonica: 'https://fixalog.app/v/sessao_multi',
        mapeamentoMidias: {
          'uuid-foto-multi': 'midias/uuid-foto-multi.webp',
          'uuid-video-multi': 'midias/uuid-video-multi.mp4',
          'uuid-pdf-multi': 'midias/uuid-pdf-multi.pdf',
          'uuid-pdf-multi_p1': 'midias/uuid-pdf-multi_p1.webp',
        },
        posterFrames: {
          'uuid-video-multi': 'midias/uuid-video-multi_poster.webp',
        },
        qrCodesVideos: {
          'uuid-video-multi': 'data:image/svg+xml;utf8,qr',
        },
      );

      expect(xhtml, contains('src="midias/uuid-foto-multi.webp"'));
      expect(xhtml, contains('src="midias/uuid-video-multi.mp4"'));
      expect(xhtml, contains('href="midias/uuid-pdf-multi.pdf" download="certificado_lote.pdf"'));
      expect(xhtml, contains('src="midias/uuid-pdf-multi_p1.webp"'));
    });

    test('gerarXhtml converte descrições com Markdown e linhas em branco em elementos XHTML5 semânticos válidos', () {
      const descricaoMarkdown = '''# Etapa de Soldagem

Realizada solda **TIG** em aço *inox 316L* com código `LOTE-99` e ~~rebarba~~ removida.

- Decapagem ácida
- Passivação completa''';

      final grupo = GrupoRepetido()
        ..idLista = 'pb_detalhes'
        ..idItem = 'det_1'
        ..idTipo = 'detalhe_item'
        ..respostasItem['det_descricao'] = (Resposta()..texto = descricaoMarkdown);

      final registro = Registro()
        ..idProtocolo = 'cadastro_material'
        ..respostas['obs_geral'] = (Resposta()..texto = 'Parágrafo 1\n\nParágrafo 2 com **negrito**')
        ..listas.add(grupo);

      final xhtml = construtor.gerarXhtml(
        registro: registro,
        idSessao: 'sessao_md',
        urlCanonica: 'https://fixalog.app/v/sessao_md',
      );

      expect(() => XmlDocument.parse(xhtml), returnsNormally);
      expect(xhtml, contains('<div class="conteudo-markdown">'));
      expect(xhtml, contains('<h4>Etapa de Soldagem</h4>'));
      expect(xhtml, contains('<strong>TIG</strong>'));
      expect(xhtml, contains('<em>inox 316L</em>'));
      expect(xhtml, contains('<code>LOTE-99</code>'));
      expect(xhtml, contains('<del>rebarba</del>'));
      expect(xhtml, contains('<ul><li>Decapagem ácida</li><li>Passivação completa</li></ul>'));
      expect(xhtml, contains('<p>Parágrafo 1</p><p>Parágrafo 2 com <strong>negrito</strong></p>'));
    });
  });
}
