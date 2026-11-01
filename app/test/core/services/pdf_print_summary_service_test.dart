// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:printing/src/interface.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/pdf_print_summary_service.dart';

class FakePrintingPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PrintingPlatform {
  String? lastHtml;
  PdfPageFormat? lastFormat;

  @override
  Future<Uint8List> convertHtml(
    String html,
    String? baseUrl,
    PdfPageFormat format,
  ) async {
    lastHtml = html;
    lastFormat = format;
    return Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]); // %PDF-1.4
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FakePrintingPlatform fakePrinting;
  late PdfPrintSummaryService service;
  late Registro registroExemplo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pdf_summary_test_');
    fakePrinting = FakePrintingPlatform();
    PrintingPlatform.instance = fakePrinting;

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
          'uuid-vid-1': 'midias/uuid-vid-1_poster.webp',
        },
      );

      // Cabeçalho explicativo
      expect(html, contains('Fixalog — Relatório Técnico de Manutenção (Versão Resumida)'));
      expect(html, contains('Este documento é uma representação impressa'));
      expect(html, contains('https://fixalog.app/v/sessao-abc'));
      expect(html, contains('data:image/svg+xml;utf8,'));

      // CSS incorporado com regras de impressão
      expect(html, contains('<style>'));
      expect(html, contains('@media print'));
      expect(html, contains('.cabecalho-versao-impressa'));
      expect(html, contains('.poster-impressao'));
      expect(html, contains('page-break-inside: avoid'));

      // Substituição de vídeo por poster frame com mini QR Code
      expect(html, contains('class="poster-impressao"'));
      expect(html, contains('src="midias/uuid-vid-1_poster.webp"'));
      expect(html, contains('Escaneie para assistir ao vídeo desta proteção online'));
      expect(html, contains('alt="QR Code do Vídeo"'));
    });

    test('gerarPdfResumidoBytes invoca Printing.convertHtml com A4 e retorna bytes válidos', () async {
      final bytes = await service.gerarPdfResumidoBytes(
        registro: registroExemplo,
        idSessao: 'sessao-abc',
        urlCanonica: 'https://fixalog.app/v/sessao-abc',
      );

      expect(bytes, isNotEmpty);
      expect(bytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46])); // %PDF
      expect(fakePrinting.lastFormat, equals(PdfPageFormat.a4));
      expect(fakePrinting.lastHtml, contains('Fixalog — Relatório Técnico de Manutenção'));
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
      expect(await arquivo.readAsBytes(), isNotEmpty);
    });

    test('permite injetar conversor customizado no construtor', () async {
      bool conversorCustomizadoChamado = false;
      final servicoCustom = PdfPrintSummaryService(
        converter: ({required html, baseUrl, required format}) async {
          conversorCustomizadoChamado = true;
          return Uint8List.fromList([1, 2, 3]);
        },
      );

      final bytes = await servicoCustom.gerarPdfResumidoBytes(
        registro: registroExemplo,
        idSessao: '123',
        urlCanonica: 'https://fixalog.app/v/123',
      );

      expect(conversorCustomizadoChamado, isTrue);
      expect(bytes, equals([1, 2, 3]));
    });

    test('pdfPrintSummaryServiceProvider provê instância funcional', () {
      final container = ProviderContainer();
      final inst = container.read(pdfPrintSummaryServiceProvider);
      expect(inst, isA<PdfPrintSummaryService>());
    });

    test('gerarHtmlParaImpressao e exportarPdfResumido concatenam relatórios dos materiais anexos ao final do documento', () async {
      final grupoMaterial = GrupoRepetido()
        ..idLista = 'lista_itens_material_c'
        ..idItem = 'item_mat_1'
        ..idTipo = 'parabolt'
        ..respostasItem['parabolt_marca'] = (Resposta()..texto = 'Petzl Coeur Pulse')
        ..respostasItem['nf_descricao'] = (Resposta()..texto = 'NF-e 998877');

      final grupoFabricacao = GrupoRepetido()
        ..idLista = 'sublista_detalhes_fabricacao__item_mat_1'
        ..idItem = 'etapa_1'
        ..idTipo = 'etapa_detalhe'
        ..respostasItem['detalhe_titulo'] = (Resposta()..texto = 'Corte e Repassivação Ácida');

      final registroMat = Registro()
        ..idProtocolo = 'cadastro_material'
        ..respostas['mat_nome'] = (Resposta()..texto = 'Conjunto Parabolt Inox 316L')
        ..respostas['mat_codigo_associacao'] = (Resposta()..texto = 'ASSOC-2026-01')
        ..listas.addAll([grupoMaterial, grupoFabricacao]);

      final registroManut = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..respostas['via_nome'] = (Resposta()..texto = 'Via Aresta Solar')
        ..respostas['lista_materiais_c'] = (Resposta()..texto = 'uuid-mat-anexo-1');

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

      // O relatório principal deve vir antes do relatório do material anexo
      final posManut = html.indexOf('Via Aresta Solar');
      final posMaterial = html.indexOf('Conjunto Parabolt Inox 316L');
      final posFabricacao = html.indexOf('Corte e Repassivação Ácida');

      expect(posManut, isNonNegative);
      expect(posMaterial, greaterThan(posManut));
      expect(posFabricacao, greaterThan(posManut));
      expect(html, contains('NF-e 998877'));
      expect(html, contains('page-break-before: always'));

      final destino = '${tempDir.path}/manut_com_materiais.pdf';
      final arquivo = await service.exportarPdfResumido(
        caminhoSaida: destino,
        registro: registroManut,
        idSessao: 'sessao-manut-99',
        urlCanonica: 'https://fixalog.app/v/sessao-manut-99',
        materiaisAnexos: [anexo],
      );

      expect(await arquivo.exists(), isTrue);
      expect(fakePrinting.lastHtml, contains('Corte e Repassivação Ácida'));
    });

    test('gerarHtmlParaImpressao renderiza todas as páginas WebP de documentos PDF no relatório principal e nos materiais anexos', () {
      final grupoMat = GrupoRepetido()
        ..idLista = 'lista_materiais_cadastro'
        ..idItem = 'item_mat_1'
        ..idTipo = 'chumbador_mecanico'
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
          'uuid-nf-anexo_p1': 'data:image/webp;base64,AAA1',
          'uuid-nf-anexo_p2': 'data:image/webp;base64,AAA2',
        },
      );

      final html = service.gerarHtmlParaImpressao(
        registro: registroManut,
        idSessao: 'sessao-manut-pdf',
        urlCanonica: 'https://fixalog.app/v/sessao-manut-pdf',
        mapeamentoMidias: {
          'uuid-laudo-princ_p1': 'data:image/webp;base64,BBB1',
          'uuid-laudo-princ_p2': 'data:image/webp;base64,BBB2',
        },
        materiaisAnexos: [anexo],
      );

      expect(html, contains('laudo_principal.pdf — Página 1 de 2'));
      expect(html, contains('src="data:image/webp;base64,BBB1"'));
      expect(html, contains('laudo_principal.pdf — Página 2 de 2'));
      expect(html, contains('src="data:image/webp;base64,BBB2"'));

      expect(html, contains('nf_anexo.pdf — Página 1 de 2'));
      expect(html, contains('src="data:image/webp;base64,AAA1"'));
      expect(html, contains('nf_anexo.pdf — Página 2 de 2'));
      expect(html, contains('src="data:image/webp;base64,AAA2"'));
    });

    test('gerarHtmlParaImpressao reflete formatação Markdown e linhas em branco nas descrições do PDF Resumido', () {
      final grupo = GrupoRepetido()
        ..idLista = 'pb_detalhes'
        ..idItem = 'det_1'
        ..idTipo = 'detalhe_item'
        ..respostasItem['det_descricao'] = (Resposta()
          ..texto = '# Tratamento Térmico\n\nAquecimento a **1050°C** com resfriamento *rápido*.\n\n- Ensaio aprovado');

      final registro = Registro()
        ..idProtocolo = 'cadastro_material'
        ..listas.add(grupo);

      final html = service.gerarHtmlParaImpressao(
        registro: registro,
        idSessao: 'sessao-md-pdf',
        urlCanonica: 'https://fixalog.app/v/sessao-md-pdf',
      );

      expect(html, contains('<h4>Tratamento Térmico</h4>'));
      expect(html, contains('<strong>1050°C</strong>'));
      expect(html, contains('<em>rápido</em>'));
      expect(html, contains('<ul><li>Ensaio aprovado</li></ul>'));
    });
  });
}
