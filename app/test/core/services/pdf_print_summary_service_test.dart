// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/pdf_print_summary_service.dart';

/// Bytes de um JPEG 1x1 válido para testes de embutimento via pw.MemoryImage.
final Uint8List kJpegValidoBytes = Uint8List.fromList([
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
  0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
  0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xC0, 0x00, 0x0B, 0x08,
  0x00, 0x01, 0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14,
  0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00,
  0x3F, 0x00, 0x3F, 0xFF, 0xD9,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PdfPrintSummaryService service;
  late Registro registroExemplo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pdf_summary_test_');
    service = PdfPrintSummaryService();

    registroExemplo = Registro()
      ..idProtocolo = 'VIS-2026-09-01'
      ..respostas.addAll({
        'setor': Resposta()..texto = 'Setor Falésia dos Ventos',
        'foto_base': Resposta()
          ..midia = (ReferenciaMidia()..imagem = (ArquivoImagem()..uuid = 'uuid-foto-1')),
        'video_grampo': Resposta()
          ..midia = (ReferenciaMidia()..video = (ArquivoVideo()..uuid = 'uuid-vid-1')),
      });
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PdfPrintSummaryService - Testes Unitários', () {
    test('gerarQrCodeSvg gera marcação SVG vetorial válida com módulos escuros e claros', () {
      final svg = PdfPrintSummaryService.gerarQrCodeSvg('https://fixalog.app/v/123');

      expect(svg, startsWith('<svg'));
      expect(svg, endsWith('</svg>'));
      expect(svg, contains('xmlns="http://www.w3.org/2000/svg"'));
      expect(svg, contains('<rect'));
      expect(svg, contains('fill="#000000"'));
      expect(svg, contains('fill="#ffffff"'));
    });

    test('gerarQrCodeSvg aceita módulo com tamanho customizado', () {
      final svgPadrao = PdfPrintSummaryService.gerarQrCodeSvg('https://fixalog.app', moduloTamanho: 4);
      final svgGrande = PdfPrintSummaryService.gerarQrCodeSvg('https://fixalog.app', moduloTamanho: 8);

      expect(svgGrande.length, greaterThan(svgPadrao.length));
    });

    test('gerarHtmlParaImpressao injeta cabeçalho de versão resumida com link e QR Code', () {
      final html = service.gerarHtmlParaImpressao(
        registro: registroExemplo,
        idSessao: 'sessao-abc',
        urlCanonica: 'https://fixalog.app/v/sessao-abc',
        mapeamentoMidias: {
          'uuid-foto-1': 'midias/uuid-foto-1.webp',
          'uuid-vid-1': 'midias/uuid-vid-1.mp4',
        },
        posterFrames: {
          'uuid-vid-1': 'midias/uuid-vid-1_poster.jpg',
        },
      );

      expect(html, contains('Fixalog — Relatório Técnico de Manutenção (Versão Resumida)'));
      expect(html, contains('Este documento é uma representação impressa'));
      expect(html, contains('https://fixalog.app/v/sessao-abc'));
      expect(html, contains('data:image/svg+xml;utf8,'));
      expect(html, contains('<style>'));
      expect(html, contains('@media print'));
      expect(html, contains('class="poster-impressao"'));
      expect(html, contains('src="midias/uuid-vid-1_poster.jpg"'));
      expect(html, contains('Escaneie para assistir ao vídeo desta proteção online'));
    });

    test('gerarPdfResumidoBytes constrói PDF A4 nativamente via package:pdf sem WebView com cabeçalho, QR Codes e imagens JPEG pré-processadas', () async {
      final fotoThumb = File('${tempDir.path}/uuid-foto-1_thumb.jpg')
        ..writeAsBytesSync(kJpegValidoBytes);
      final posterJpg = File('${tempDir.path}/uuid-vid-1_poster.jpg')
        ..writeAsBytesSync(kJpegValidoBytes);

      final bytes = await service.gerarPdfResumidoBytes(
        registro: registroExemplo,
        idSessao: 'sessao-abc',
        urlCanonica: 'https://fixalog.app/v/sessao-abc',
        mapeamentoMidias: {
          'uuid-foto-1': fotoThumb.path,
        },
        posterFrames: {
          'uuid-vid-1': posterJpg.path,
        },
      );

      expect(bytes, isNotEmpty);
      expect(bytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46])); // %PDF

      final textoPdf = latin1.decode(bytes, allowInvalid: true);
      expect(textoPdf, contains('Fixalog'));
      expect(textoPdf, contains('Relatório'));
      expect(textoPdf, contains('https://fixalog.app/v/sessao-abc'));
      expect(textoPdf, contains('Falésia'));
      expect(textoPdf, contains('Escaneie'));
      expect(textoPdf, contains('/DCTDecode'));
    });

    test('exportarPdfResumido grava arquivo PDF em disco no caminho solicitado', () async {
      final destino = '${tempDir.path}/relatorio_resumo.pdf';

      final arquivo = await service.exportarPdfResumido(
        caminhoSaida: destino,
        registro: registroExemplo,
        idSessao: 'sessao-abc',
        urlCanonica: 'https://fixalog.app/v/sessao-abc',
      );

      expect(arquivo.path, equals(destino));
      expect(await arquivo.exists(), isTrue);
      final bytes = await arquivo.readAsBytes();
      expect(bytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
    });

    test('pdfPrintSummaryServiceProvider provê instância funcional', () {
      final container = ProviderContainer();
      final inst = container.read(pdfPrintSummaryServiceProvider);
      expect(inst, isA<PdfPrintSummaryService>());
    });

    test('gerarPdfResumidoBytes e exportarPdfResumido concatenam relatórios dos materiais anexos e todos os tipos de campos ao final do documento', () async {
      final grupoMaterial = GrupoRepetido()
        ..idLista = 'lista_itens_material_c'
        ..idItem = 'item_mat_1'
        ..idTipo = 'parabolt'
        ..respostasItem['parabolt_marca'] = (Resposta()..texto = 'Petzl Coeur Pulse')
        ..respostasItem['nf_descricao'] = (Resposta()..texto = 'NF-e 998877')
        ..respostasItem['qtd_lote'] = (Resposta()..inteiro = Int64(50))
        ..respostasItem['diametro_mm'] = (Resposta()..numero = 12.5)
        ..respostasItem['inox_certificado'] = (Resposta()..booleano = true)
        ..respostasItem['tags_item'] = (Resposta()
          ..lista = (ListaRespostas()
            ..valores.addAll([
              Resposta()..texto = 'TAG-A',
              Resposta()..texto = 'TAG-B',
            ])));

      final grupoFabricacao = GrupoRepetido()
        ..idLista = 'sublista_detalhes_fabricacao__item_mat_1'
        ..idItem = 'etapa_1'
        ..idTipo = 'etapa_detalhe'
        ..respostasItem['detalhe_titulo'] = (Resposta()..texto = 'Corte e Repassivação Ácida');

      final registroMat = Registro()
        ..idProtocolo = 'cadastro_material'
        ..respostas['mat_nome'] = (Resposta()..texto = 'Conjunto Parabolt Inox 316L')
        ..respostas['mat_codigo_associacao'] = (Resposta()..texto = 'ASSOC-2026-01')
        ..respostas['mat_qtd'] = (Resposta()..inteiro = Int64(10))
        ..respostas['mat_peso'] = (Resposta()..numero = 1.25)
        ..respostas['mat_ativo'] = (Resposta()..booleano = false)
        ..listas.addAll([grupoMaterial, grupoFabricacao]);

      final registroManut = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..respostas['via_nome'] = (Resposta()..texto = 'Via Aresta Solar')
        ..respostas['lista_materiais_c'] = (Resposta()..texto = 'uuid-mat-anexo-1')
        ..respostas['refs_extras'] = (Resposta()
          ..lista = (ListaRespostas()
            ..valores.add(Resposta()..texto = 'uuid-mat-anexo-1')));

      final anexo = RelatorioMaterialAnexo(
        idSessao: 'uuid-mat-anexo-1',
        registro: registroMat,
        urlCanonica: 'https://fixalog.app/v/uuid-mat-anexo-1',
      );

      final html = service.gerarHtmlParaImpressao(
        registro: registroManut,
        idSessao: 'sessao-manut-99',
        urlCanonica: 'https://fixalog.app/v/sessao-manut-99',
        materiaisAnexos: [anexo],
      );
      expect(html, contains('Via Aresta Solar'));
      expect(html, contains('Conjunto Parabolt Inox 316L'));

      final destino = '${tempDir.path}/manut_com_materiais.pdf';
      final arquivo = await service.exportarPdfResumido(
        caminhoSaida: destino,
        registro: registroManut,
        idSessao: 'sessao-manut-99',
        urlCanonica: 'https://fixalog.app/v/sessao-manut-99',
        materiaisAnexos: [anexo],
      );

      expect(await arquivo.exists(), isTrue);
      final textoPdf = latin1.decode(await arquivo.readAsBytes(), allowInvalid: true);
      final posManut = textoPdf.indexOf('Aresta');
      final posMaterial = textoPdf.indexOf('316L');
      final posFabricacao = textoPdf.indexOf('Repassivação');

      expect(posManut, isNonNegative);
      expect(posMaterial, greaterThan(posManut));
      expect(posFabricacao, greaterThan(posManut));
      expect(textoPdf, contains('998877'));
    });

    test('gerarPdfResumidoBytes renderiza páginas de documentos PDF e mídias em listas tanto por caminho de arquivo quanto por data URI', () async {
      final arqPag1 = File('${tempDir.path}/laudo_p1_thumb.jpg')
        ..writeAsBytesSync(kJpegValidoBytes);
      final arqPag2 = File('${tempDir.path}/laudo_p2_thumb.jpg')
        ..writeAsBytesSync(kJpegValidoBytes);
      final dataUriJpeg = 'data:image/jpeg;base64,${base64Encode(kJpegValidoBytes)}';

      final grupoMat = GrupoRepetido()
        ..idLista = 'lista_materiais_cadastro'
        ..idItem = 'item_mat_1'
        ..idTipo = 'chumbador_mecanico'
        ..respostasItem['mat_foto'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..imagem = (ArquivoImagem()..uuid = 'uuid-foto-lista')))
        ..respostasItem['mat_video'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..video = (ArquivoVideo()..uuid = 'uuid-vid-lista')))
        ..respostasItem['mat_nota_fiscal'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..documento = (ArquivoDocumento()
              ..uuid = 'uuid-nf-anexo'
              ..nomeOriginal = 'nf_anexo.pdf'
              ..quantidadePaginas = 2)));

      final registroMat = Registro()
        ..idProtocolo = 'cadastro_material'
        ..respostas['mat_nome'] = (Resposta()..texto = 'Parabolt com PDF')
        ..listas.add(grupoMat);

      final registroManut = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..respostas['laudo_pdf'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..documento = (ArquivoDocumento()
              ..uuid = 'uuid-laudo-princ'
              ..nomeOriginal = 'laudo_principal.pdf'
              ..quantidadePaginas = 2)));

      final anexo = RelatorioMaterialAnexo(
        idSessao: 'uuid-mat-pdf',
        registro: registroMat,
        urlCanonica: 'https://fixalog.app/v/uuid-mat-pdf',
        mapeamentoMidias: {
          'uuid-foto-lista': dataUriJpeg,
          'uuid-nf-anexo_p1': dataUriJpeg,
          'uuid-nf-anexo_p2': dataUriJpeg,
        },
        posterFrames: {
          'uuid-vid-lista': dataUriJpeg,
        },
      );

      final bytes = await service.gerarPdfResumidoBytes(
        registro: registroManut,
        idSessao: 'sessao-manut-pdf',
        urlCanonica: 'https://fixalog.app/v/sessao-manut-pdf',
        mapeamentoMidias: {
          'uuid-laudo-princ_p1': arqPag1.path,
          'uuid-laudo-princ_p2': arqPag2.path,
        },
        materiaisAnexos: [anexo],
      );

      final textoPdf = latin1.decode(bytes, allowInvalid: true);
      expect(textoPdf, contains('laudo_principal.pdf'));
      expect(textoPdf, contains('nf_anexo.pdf'));
    });

    test('gerarPdfResumidoBytes reflete formatação Markdown (títulos, negrito, itálico, código, tachado e listas) e linhas em branco', () async {
      final grupo = GrupoRepetido()
        ..idLista = 'pb_detalhes'
        ..idItem = 'det_1'
        ..idTipo = 'detalhe_item'
        ..respostasItem['det_descricao'] = (Resposta()
          ..texto = '# Tratamento Térmico\r\n\r\nAquecimento a **1050°C** com resfriamento *rápido* em `forno_v2` e ~~escória~~.\r\n\r\n- Ensaio aprovado');

      final registro = Registro()
        ..idProtocolo = 'cadastro_material'
        ..respostas['obs_geral'] = (Resposta()..texto = '# Resumo Geral\n\nTexto **importante**.')
        ..listas.add(grupo);

      final bytes = await service.gerarPdfResumidoBytes(
        registro: registro,
        idSessao: 'sessao-md-pdf',
        urlCanonica: 'https://fixalog.app/v/sessao-md-pdf',
      );

      final textoPdf = latin1.decode(bytes, allowInvalid: true);
      expect(textoPdf, contains('Tratamento'));
      expect(textoPdf, contains('1050°C'));
      expect(textoPdf, contains('forno_v2'));
      expect(textoPdf, contains('aprovado'));
    });
  });
}
