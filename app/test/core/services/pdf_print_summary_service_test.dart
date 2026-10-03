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
  });
}
