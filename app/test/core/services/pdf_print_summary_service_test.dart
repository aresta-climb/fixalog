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

const String kYamlManutencaoPdf = '''
id: "manutencao_ferragens"
versao: "2.1.0"
nome: "Manutenção de Proteções Fixas"
descricao: "Protocolo de auditoria de vias"

blocos:
  - id: "bloco_via"
    titulo: "Bloco 1 — Identificação da Via"
    subtitulo: "Localização e estado geral"
    steps:
      - id: "step_inst"
        conteudos:
          - id: "inst_1"
            instrucao:
              titulo: "Instrução do Wizard que não deve ir para o PDF"
              corpo: "Orientação interna"
      - id: "step_dados"
        conteudos:
          - id: "via_nome"
            campo_simples:
              label: "Nome da Via"
              tipo: "TEXT"
          - id: "setor"
            campo_simples:
              label: "Setor da Falésia"
              sublabel: "Sub-região"
              tipo: "TEXT"
          - id: "campo_vazio_opcional"
            campo_simples:
              label: "Campo Vazio Opcional"
              tipo: "TEXT"
          - id: "condicao_via"
            campo_simples:
              label: "Condição Final da Via"
              tipo: "DROPDOWN"
              ui_hint: "LARGE_TILES"
              opcoes:
                - valor: "liberada"
                  label: "Via Liberada para Escalada"
                  sublabel: "Proteções íntegras"
          - id: "obs_geral"
            campo_simples:
              label: "Observações Gerais"
              sublabel: "Notas técnicas"
              tipo: "TEXT"
              ui_hint: "TEXT_AREA"
          - id: "resumo_curto"
            campo_simples:
              label: "Resumo Curto"
              sublabel: "Síntese rápida"
              tipo: "TEXT"
              ui_hint: "TEXT_AREA"
          - id: "foto_base"
            campo_simples:
              label: "Foto da Base"
              tipo: "IMAGE"
          - id: "foto_topo"
            campo_simples:
              label: "Foto do Topo"
              tipo: "IMAGE"
          - id: "video_grampo"
            campo_simples:
              label: "Vídeo do Grampo"
              tipo: "VIDEO"
          - id: "laudo_pdf"
            campo_simples:
              label: "Laudo Técnico PDF"
              tipo: "IMAGE"
          - id: "lista_materiais_c"
            ref_materiais:
              label: "Materiais Instalados na Via"
              sublabel: "Lotes do catálogo"
              origem_catalogo: true
''';

const String kYamlMaterialPdf = '''
id: "cadastro_material"
versao: "1.4.0"
nome: "Cadastro e Ensaio de Material"
descricao: "Ficha técnica de materiais"

blocos:
  - id: "bloco_mat"
    titulo: "Bloco 1 — Identificação do Conjunto"
    steps:
      - id: "step_mat"
        conteudos:
          - id: "mat_nome"
            campo_simples:
              label: "Nome do Conjunto"
              tipo: "TEXT"
          - id: "mat_codigo_associacao"
            campo_simples:
              label: "Código da Associação"
              tipo: "TEXT"
          - id: "mat_qtd"
            campo_simples:
              label: "Quantidade no Lote"
              tipo: "NUMBER"
          - id: "mat_peso"
            campo_simples:
              label: "Peso Unitário (kg)"
              tipo: "NUMBER"
          - id: "mat_ativo"
            campo_simples:
              label: "Lote Ativo?"
              tipo: "BOOLEAN"
          - id: "lista_itens_material_c"
            lista_acoes:
              label: "Peças do Conjunto"
              sublabel: "Componentes auditados"
              tipos_disponiveis:
                - id: "parabolt"
                  label: "Chumbador Parabolt"
                  steps:
                    - id: "s_pb"
                      conteudos:
                        - id: "parabolt_marca"
                          campo_simples:
                            label: "Marca e Modelo"
                            tipo: "TEXT"
                        - id: "liga_dropdown"
                          campo_simples:
                            label: "Liga Metalúrgica"
                            tipo: "DROPDOWN"
                            opcoes:
                              - valor: "inox_316l"
                                label: "Aço Inox 316L Certificado"
                        - id: "nf_descricao"
                          campo_simples:
                            label: "Nota Fiscal"
                            tipo: "TEXT"
                        - id: "qtd_lote"
                          campo_simples:
                            label: "Peças Testadas"
                            tipo: "NUMBER"
                        - id: "diametro_mm"
                          campo_simples:
                            label: "Diâmetro (mm)"
                            tipo: "NUMBER"
                        - id: "inox_certificado"
                          campo_simples:
                            label: "Possui Certificado?"
                            tipo: "BOOLEAN"
                        - id: "mat_foto"
                          campo_simples:
                            label: "Foto da Peça"
                            tipo: "IMAGE"
                        - id: "mat_video"
                          campo_simples:
                            label: "Vídeo do Teste"
                            tipo: "VIDEO"
                        - id: "mat_nota_fiscal"
                          campo_simples:
                            label: "PDF da Nota Fiscal"
                            tipo: "IMAGE"
                        - id: "det_descricao"
                          campo_simples:
                            label: "Relatório Metalúrgico"
                            tipo: "TEXT"
                            ui_hint: "TEXT_AREA"
                        - id: "sublista_detalhes_fabricacao"
                          lista_acoes:
                            label: "Sub-lista de Fabricação"
                            tipos_disponiveis:
                              - id: "etapa_detalhe"
                                label: "Etapa Fabril"
                                steps:
                                  - id: "s_etapa"
                                    conteudos:
                                      - id: "detalhe_titulo"
                                        campo_simples:
                                          label: "Descrição da Etapa"
                                          tipo: "TEXT"
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PdfPrintSummaryService service;
  late Registro registroExemplo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pdf_summary_test_');
    service = PdfPrintSummaryService();

    registroExemplo = Registro()
      ..idProtocolo = 'manutencao_ferragens'
      ..yamlConteudo = kYamlManutencaoPdf
      ..respostas.addAll({
        'via_nome': Resposta()..texto = 'Via Aresta dos Ventos',
        'setor': Resposta()..texto = 'Setor Falésia dos Ventos',
        'condicao_via': Resposta()..texto = 'liberada',
        'foto_base': Resposta()
          ..midia = (ReferenciaMidia()..imagem = (ArquivoImagem()..uuid = 'uuid-foto-1')),
        'foto_topo': Resposta()
          ..midia = (ReferenciaMidia()..imagem = (ArquivoImagem()..uuid = 'uuid-foto-2')),
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
    test('gerarPdfResumidoBytes deve lançar FormatException quando yamlConteudo estiver vazio', () async {
      final registroSemYaml = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..respostas['via_nome'] = (Resposta()..texto = 'Via Sem Schema');

      await expectLater(
        () => service.gerarPdfResumidoBytes(
          registro: registroSemYaml,
          idSessao: 'sessao-sem-yaml',
          urlCanonica: 'https://fixalog.app/v/sessao-sem-yaml',
        ),
        throwsFormatException,
      );
    });

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

    test('gerarHtmlParaImpressao injeta cabeçalho de versão resumida com blocos do protocolo, rótulos humanos e omite StepInstrucao', () {
      final html = service.gerarHtmlParaImpressao(
        registro: registroExemplo,
        idSessao: 'sessao-abc',
        urlCanonica: 'https://fixalog.app/v/sessao-abc',
        mapeamentoMidias: {
          'uuid-foto-1': 'midias/uuid-foto-1.webp',
          'uuid-foto-2': 'midias/uuid-foto-2.webp',
          'uuid-vid-1': 'midias/uuid-vid-1.mp4',
        },
        posterFrames: {
          'uuid-vid-1': 'midias/uuid-vid-1_poster.jpg',
        },
      );

      expect(html, contains('Fixalog — Manutenção de Proteções Fixas (Versão Resumida)'));
      expect(html, contains('Este documento é uma representação impressa'));
      expect(html, contains('https://fixalog.app/v/sessao-abc'));
      expect(html, contains('data:image/svg+xml;utf8,'));
      expect(html, contains('Bloco 1 — Identificação da Via'));
      expect(html, contains('Setor da Falésia'));
      expect(html, contains('Via Liberada para Escalada'));
      expect(html, contains('Foto da Base'));
      expect(html, contains('Foto do Topo'));
      expect(html, isNot(contains('Instrução do Wizard')));
      expect(html, isNot(contains('Campo Vazio Opcional')));
      expect(html, contains('<style>'));
      expect(html, contains('@media print'));
      expect(html, contains('class="poster-impressao"'));
      expect(html, contains('src="midias/uuid-vid-1_poster.jpg"'));
      expect(html, contains('Escaneie para assistir ao vídeo'));
    });

    test('gerarPdfResumidoBytes constrói PDF A4 nativamente com blocos do protocolo, rótulos humanos, omissão de instruções/vazios e fotos lado a lado', () async {
      final fotoThumb1 = File('${tempDir.path}/uuid-foto-1_thumb.jpg')
        ..writeAsBytesSync(kJpegValidoBytes);
      final fotoThumb2 = File('${tempDir.path}/uuid-foto-2_thumb.jpg')
        ..writeAsBytesSync(kJpegValidoBytes);
      final posterJpg = File('${tempDir.path}/uuid-vid-1_poster.jpg')
        ..writeAsBytesSync(kJpegValidoBytes);

      final bytes = await service.gerarPdfResumidoBytes(
        registro: registroExemplo,
        idSessao: 'sessao-abc',
        urlCanonica: 'https://fixalog.app/v/sessao-abc',
        mapeamentoMidias: {
          'uuid-foto-1': fotoThumb1.path,
          'uuid-foto-2': fotoThumb2.path,
        },
        posterFrames: {
          'uuid-vid-1': posterJpg.path,
        },
      );

      expect(bytes, isNotEmpty);
      expect(bytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46])); // %PDF

      final textoPdf = latin1.decode(bytes, allowInvalid: true);
      expect(textoPdf, contains('Fixalog'));
      expect(textoPdf, contains('Manuten'));
      expect(textoPdf, contains('Bloco'));
      expect(textoPdf, contains('Sub-regi'));
      expect(textoPdf, contains('Liberada'));
      expect(textoPdf, contains('Base'));
      expect(textoPdf, contains('Topo'));
      expect(textoPdf, isNot(contains('Wizard')));
      expect(textoPdf, isNot(contains('Opcional')));
      expect(textoPdf, contains('https://fixalog.app/v/sessao-abc'));
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

    test('gerarPdfResumidoBytes e exportarPdfResumido concatenam relatórios dos materiais anexos com sub-listas aninhadas e rótulos humanos do YAML', () async {
      final grupoMaterial = GrupoRepetido()
        ..idLista = 'lista_itens_material_c'
        ..idItem = 'item_mat_1'
        ..idTipo = 'parabolt'
        ..respostasItem['parabolt_marca'] = (Resposta()..texto = 'Petzl Coeur Pulse')
        ..respostasItem['liga_dropdown'] = (Resposta()..texto = 'inox_316l')
        ..respostasItem['nf_descricao'] = (Resposta()..texto = 'NF-e 998877')
        ..respostasItem['qtd_lote'] = (Resposta()..inteiro = Int64(50))
        ..respostasItem['diametro_mm'] = (Resposta()..numero = 12.5)
        ..respostasItem['inox_certificado'] = (Resposta()..booleano = true);

      final grupoFabricacao = GrupoRepetido()
        ..idLista = 'sublista_detalhes_fabricacao__item_mat_1'
        ..idItem = 'etapa_1'
        ..idTipo = 'etapa_detalhe'
        ..respostasItem['detalhe_titulo'] = (Resposta()..texto = 'Corte e Repassivação Ácida');

      final registroMat = Registro()
        ..idProtocolo = 'cadastro_material'
        ..yamlConteudo = kYamlMaterialPdf
        ..respostas['mat_nome'] = (Resposta()..texto = 'Conjunto Parabolt Inox 316L')
        ..respostas['mat_codigo_associacao'] = (Resposta()..texto = 'ASSOC-2026-01')
        ..respostas['mat_qtd'] = (Resposta()..inteiro = Int64(10))
        ..respostas['mat_peso'] = (Resposta()..numero = 1.25)
        ..respostas['mat_ativo'] = (Resposta()..booleano = false)
        ..listas.addAll([grupoMaterial, grupoFabricacao]);

      final registroManut = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..yamlConteudo = kYamlManutencaoPdf
        ..respostas['via_nome'] = (Resposta()..texto = 'Via Aresta Solar')
        ..respostas['lista_materiais_c'] = (Resposta()
          ..lista = (ListaRespostas()
            ..valores.add(Resposta()..texto = 'uuid-mat-anexo-1')));

      final anexo = RelatorioMaterialAnexo(
        idSessao: 'uuid-mat-anexo-1',
        registro: registroMat,
        urlCanonica: 'https://fixalog.app/v/uuid-mat-anexo-1',
        posterFrames: {
          'vid-mat-1': 'midias/vid-mat-1_poster.jpg',
        },
      );

      final html = service.gerarHtmlParaImpressao(
        registro: registroManut,
        idSessao: 'sessao-manut-99',
        urlCanonica: 'https://fixalog.app/v/sessao-manut-99',
        materiaisAnexos: [anexo],
      );
      expect(html, contains('Via Aresta Solar'));
      expect(html, contains('Conjunto Parabolt Inox 316L'));
      expect(html, contains('Aço Inox 316L Certificado'));
      expect(html, contains('Sub-lista de Fabricação'));

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
      final posFabricacao = textoPdf.indexOf('Repassiva');

      expect(posManut, isNonNegative);
      expect(posMaterial, greaterThan(posManut));
      expect(posFabricacao, greaterThan(posManut));
      expect(textoPdf, contains('Modelo'));
      expect(textoPdf, contains('Certificado'));
      expect(textoPdf, contains('998877'));
      expect(textoPdf, contains('Sub-lista'));
      expect(textoPdf, contains('Fabril'));
    });

    test('gerarPdfResumidoBytes renderiza páginas de documentos PDF e mídias em listas tanto por caminho de arquivo quanto por data URI', () async {
      final arqPag1 = File('${tempDir.path}/laudo_p1_thumb.jpg')
        ..writeAsBytesSync(kJpegValidoBytes);
      final arqPag2 = File('${tempDir.path}/laudo_p2_thumb.jpg')
        ..writeAsBytesSync(kJpegValidoBytes);
      final dataUriJpeg = 'data:image/jpeg;base64,${base64Encode(kJpegValidoBytes)}';

      final grupoMat = GrupoRepetido()
        ..idLista = 'lista_itens_material_c'
        ..idItem = 'item_mat_1'
        ..idTipo = 'parabolt'
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
              ..quantidadePaginas = 2)));

      final registroMat = Registro()
        ..idProtocolo = 'cadastro_material'
        ..yamlConteudo = kYamlMaterialPdf
        ..respostas['mat_nome'] = (Resposta()..texto = 'Parabolt com PDF')
        ..listas.add(grupoMat);

      final registroManut = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..yamlConteudo = kYamlManutencaoPdf
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
      expect(textoPdf, contains('Laudo'));
      expect(textoPdf, contains('laudo_principal.pdf'));
      expect(textoPdf, contains('Fiscal'));
      expect(textoPdf, contains('uuid-nf-anexo.pdf'));
    });

    test('gerarPdfResumidoBytes reflete formatação Markdown (títulos, negrito, itálico, código, tachado e listas) e linhas em branco', () async {
      final grupo = GrupoRepetido()
        ..idLista = 'lista_itens_material_c'
        ..idItem = 'det_1'
        ..idTipo = 'parabolt'
        ..respostasItem['det_descricao'] = (Resposta()
          ..texto = '# Tratamento Térmico\r\n\r\n## Subtítulo\r\n\r\n### Seção Menor\r\n\r\nAquecimento a **1050°C** com resfriamento *rápido* em `forno_v2` e ~~escória~~.\r\n\r\n- Ensaio aprovado\r\n1. Passo numerado');

      final registro = Registro()
        ..idProtocolo = 'cadastro_material'
        ..yamlConteudo = kYamlMaterialPdf
        ..respostas['mat_nome'] = (Resposta()..texto = 'Lote Tratado')
        ..listas.add(grupo);

      final registroManut = Registro()
        ..idProtocolo = 'manutencao_ferragens'
        ..yamlConteudo = kYamlManutencaoPdf
        ..respostas['obs_geral'] = (Resposta()..texto = '# Resumo Geral\n\nTexto **importante**.')
        ..respostas['resumo_curto'] = (Resposta()..texto = 'Linha simples sem markdown.');

      final bytes = await service.gerarPdfResumidoBytes(
        registro: registroManut,
        idSessao: 'sessao-md-pdf',
        urlCanonica: 'https://fixalog.app/v/sessao-md-pdf',
        materiaisAnexos: [
          RelatorioMaterialAnexo(
            idSessao: 'uuid-mat-md',
            registro: registro,
            urlCanonica: 'https://fixalog.app/v/uuid-mat-md',
          ),
        ],
      );

      final textoPdf = latin1.decode(bytes, allowInvalid: true);
      expect(textoPdf, contains('Observa'));
      expect(textoPdf, contains('markdown.'));
      expect(textoPdf, contains('Tratamento'));
      expect(textoPdf, contains('1050°C'));
      expect(textoPdf, contains('forno_v2'));
      expect(textoPdf, contains('aprovado'));
      expect(textoPdf, contains('numerado'));
    });

    test('renderiza títulos de materiais referenciados via ref_mat_* diretamente nas ações de manutencao.yaml v2', () async {
      final yamlManutV2 = File('assets/protocols/manutencao.yaml').readAsStringSync();
      final registroMat = Registro()
        ..idProtocolo = 'cadastro_material'
        ..yamlConteudo = kYamlMaterialPdf
        ..respostas['mat_nome'] = (Resposta()..texto = 'Chapeleta Inox 316L Dupla');

      final acaoNovoPonto = GrupoRepetido(
        idLista: 'lista_acoes_c',
        idItem: 'item_np_pdf',
        idTipo: 'novo_ponto',
      )..respostasItem['ref_mat_novo_ponto'] = Resposta(
          lista: ListaRespostas(
            valores: [Resposta(texto: 'uuid-mat-direto-pdf')],
          ),
        );

      final registroManut = Registro(
        idSessao: 'sessao-manut-v2-pdf',
        idProtocolo: 'manutencao',
        versaoProtocolo: '2',
        yamlConteudo: yamlManutV2,
      )
        ..respostas['via_nome'] = Resposta(texto: 'Via Face Norte')
        ..listas.add(acaoNovoPonto);

      final anexo = RelatorioMaterialAnexo(
        idSessao: 'uuid-mat-direto-pdf',
        registro: registroMat,
        urlCanonica: 'https://fixalog.app/v/uuid-mat-direto-pdf',
      );

      final html = service.gerarHtmlParaImpressao(
        registro: registroManut,
        idSessao: 'sessao-manut-v2-pdf',
        urlCanonica: 'https://fixalog.app/v/sessao-manut-v2-pdf',
        materiaisAnexos: [anexo],
      );
      expect(html, contains('Via Face Norte'));
      expect(html, contains('Chapeleta Inox 316L Dupla'));

      final bytes = await service.gerarPdfResumidoBytes(
        registro: registroManut,
        idSessao: 'sessao-manut-v2-pdf',
        urlCanonica: 'https://fixalog.app/v/sessao-manut-v2-pdf',
        materiaisAnexos: [anexo],
      );
      final textoPdf = latin1.decode(bytes, allowInvalid: true);
      expect(textoPdf, contains('Face'));
      expect(textoPdf, contains('Norte'));
      expect(textoPdf, contains('Chapeleta'));
      expect(textoPdf, contains('316L'));
      expect(textoPdf, contains('Dupla'));
    });

    test('exporta PDF Resumido e HTML localizado em pt, en, ar (RTL) e ja com fontes Noto Sans locais e rótulos traduzidos', () async {
      final yamlInspecao = File('assets/protocols/inspecao_visual.yaml').readAsStringSync();
      final yamlMaterial = File('assets/protocols/cadastro_material.yaml').readAsStringSync();

      final regInspecao = Registro(
        idSessao: 'sessao-i18n-pdf',
        idProtocolo: 'inspecao_visual',
        versaoProtocolo: '2',
        yamlConteudo: yamlInspecao,
      )
        ..respostas['via_nome'] = Resposta(texto: 'North Ridge')
        ..respostas['avaliacao_condicao'] = Resposta(texto: 'liberada');

      final regMaterial = Registro(
        idSessao: 'mat-i18n-1',
        idProtocolo: 'cadastro_material',
        versaoProtocolo: '2',
        yamlConteudo: yamlMaterial,
      )..respostas['mat_nome'] = Resposta(texto: ' Bolt 316L ');

      final anexo = RelatorioMaterialAnexo(
        idSessao: 'mat-i18n-1',
        registro: regMaterial,
        urlCanonica: 'https://fixalog.app/v/mat-i18n-1',
      );

      for (final idioma in const ['pt', 'en', 'ar', 'ja']) {
        final html = service.gerarHtmlParaImpressao(
          registro: regInspecao,
          idSessao: 'sessao-i18n-pdf',
          urlCanonica: 'https://fixalog.app/v/sessao-i18n-pdf',
          materiaisAnexos: [anexo],
          codigoIdioma: idioma,
        );
        expect(html, contains('lang="$idioma"'));
        if (idioma == 'ar') {
          expect(html, contains('dir="rtl"'));
        }

        final destino = '${tempDir.path}/resumo_$idioma.pdf';
        final arqPdf = await service.exportarPdfResumido(
          caminhoSaida: destino,
          registro: regInspecao,
          idSessao: 'sessao-i18n-pdf',
          urlCanonica: 'https://fixalog.app/v/sessao-i18n-pdf',
          materiaisAnexos: [anexo],
          codigoIdioma: idioma,
        );
        final pdfBytes = await arqPdf.readAsBytes();
        expect(pdfBytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
        final pdfStr = latin1.decode(pdfBytes, allowInvalid: true);
        expect(pdfStr, contains('NotoSans'));
        if (idioma == 'ar') {
          expect(pdfStr, contains('NotoSansArabic'));
        } else if (idioma == 'ja') {
          expect(pdfStr, contains('NotoSansJP'));
        }
      }
    });

    test('aplica traducoesProtocolo do RelatorioMaterialAnexo e traduz protocolos oficiais mesmo sem codigoIdioma explicito', () async {
      final yamlManut = File('assets/protocols/manutencao.yaml').readAsStringSync();
      final yamlMat = File('assets/protocols/cadastro_material.yaml').readAsStringSync();

      final regManut = Registro(
        idSessao: 'sessao-manut-default-pt',
        idProtocolo: 'maintenance',
        versaoProtocolo: '2',
        yamlConteudo: yamlManut,
      )..respostas['route_name'] = Resposta(texto: 'Via Leste');

      final regMat = Registro(
        idSessao: 'mat-anexo-custom-trad',
        idProtocolo: 'material_registration',
        versaoProtocolo: '2',
        yamlConteudo: yamlMat,
      )..respostas['mat_name'] = Resposta(texto: 'Parabolt Custom');

      final anexoComTraducao = RelatorioMaterialAnexo(
        idSessao: 'mat-anexo-custom-trad',
        registro: regMat,
        urlCanonica: 'https://fixalog.app/v/mat-anexo-custom-trad',
        traducoesProtocolo: {
          'conteudos': {
            'mat_name': {
              'label': 'Rótulo Customizado do Anexo',
            },
          },
        },
      );

      final html = service.gerarHtmlParaImpressao(
        registro: regManut,
        idSessao: 'sessao-manut-default-pt',
        urlCanonica: 'https://fixalog.app/v/sessao-manut-default-pt',
        materiaisAnexos: [anexoComTraducao],
      );
      expect(html, contains('Rótulo Customizado do Anexo'));

      final pdfBytes = await service.gerarPdfResumidoBytes(
        registro: regManut,
        idSessao: 'sessao-manut-default-pt',
        urlCanonica: 'https://fixalog.app/v/sessao-manut-default-pt',
        materiaisAnexos: [anexoComTraducao],
      );
      final pdfStr = latin1.decode(pdfBytes, allowInvalid: true);
      expect(pdfStr, contains('Customizado'));
    });
  });
}
