// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
