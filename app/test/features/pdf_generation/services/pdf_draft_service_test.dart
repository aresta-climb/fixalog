// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fixalog/features/pdf_generation/services/pdf_draft_service.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';

void main() {
  group('PdfDraftService', () {
    late PdfDraftService pdfDraftService;
    late Directory tempDir;

    setUp(() async {
      pdfDraftService = PdfDraftService();
      tempDir = await Directory.systemTemp.createTemp('pdf_draft_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('deve gerar PDF vazio se Registro não tiver respostas', () async {
      final registro = Registro()
        ..idProtocolo = 'Test Protocol';

      final outPath = '${tempDir.path}/test1.pdf';
      final file = await pdfDraftService.drawDraft(registro, outPath, (uuid) => '');

      expect(file.existsSync(), isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.isNotEmpty, isTrue);
    });

    test('deve renderizar respostas simples no PDF', () async {
      final registro = Registro()
        ..idProtocolo = 'Test Protocol'
        ..respostas['nome'] = (Resposta()..texto = 'Fixalog Test')
        ..respostas['idade'] = (Resposta()..inteiro = Int64(30))
        ..respostas['ativo'] = (Resposta()..booleano = true)
        ..respostas['peso'] = (Resposta()..numero = 75.5);

      final outPath = '${tempDir.path}/test2.pdf';
      final file = await pdfDraftService.drawDraft(registro, outPath, (uuid) => '');

      expect(file.existsSync(), isTrue);
    });

    test('deve renderizar Listas e imagens associadas', () async {
      final registro = Registro()
        ..idProtocolo = 'Test Protocol'
        ..listas.add(
          GrupoRepetido()
            ..idLista = 'fotos'
            ..respostasItem['foto'] = (Resposta()..midia = (ReferenciaMidia()..imagem = (ArquivoImagem()..uuid = 'img1')))
            ..respostasItem['desc'] = (Resposta()..texto = 'Uma bela foto'),
        );

      final outPath = '${tempDir.path}/test3.pdf';
      
      // Cria uma imagem "falsa" mas válida para carregar em memória
      final dummyImagePath = '${tempDir.path}/img1.jpg';
      // um pixel branco em jpg
      final dummyBytes = Uint8List.fromList([
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
        0x3F, 0x00, 0x3F, 0xFF, 0xD9
      ]);
      File(dummyImagePath).writeAsBytesSync(dummyBytes);

      final file = await pdfDraftService.drawDraft(
        registro, 
        outPath, 
        (uuid) => uuid == 'img1' ? dummyImagePath : ''
      );

      expect(file.existsSync(), isTrue);
    });

    test('deve renderizar documentos PDF de múltiplas páginas em respostas e listas', () async {
      final registro = Registro()
        ..idProtocolo = 'cadastro_material'
        ..respostas['doc_geral'] = (Resposta()
          ..midia = (ReferenciaMidia()
            ..documento = (ArquivoDocumento()
              ..uuid = 'doc1'
              ..nomeOriginal = 'nota.pdf'
              ..quantidadePaginas = 2)))
        ..listas.add(
          GrupoRepetido()
            ..idLista = 'lista_materiais_cadastro'
            ..respostasItem['mat_nota_fiscal'] = (Resposta()
              ..midia = (ReferenciaMidia()
                ..documento = (ArquivoDocumento()
                  ..uuid = 'doc2'
                  ..nomeOriginal = 'laudo.pdf'
                  ..quantidadePaginas = 2))),
        );

      final outPath = '${tempDir.path}/test_doc_pdf.pdf';
      final dummyImagePath = '${tempDir.path}/page.jpg';
      final dummyBytes = Uint8List.fromList([
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
        0x3F, 0x00, 0x3F, 0xFF, 0xD9
      ]);
      File(dummyImagePath).writeAsBytesSync(dummyBytes);

      final solicitados = <String>[];
      final file = await pdfDraftService.drawDraft(
        registro,
        outPath,
        (uuid) {
          solicitados.add(uuid);
          return dummyImagePath;
        },
      );

      expect(file.existsSync(), isTrue);
      expect(solicitados, containsAll(['doc1_p1', 'doc1_p2', 'doc2_p1', 'doc2_p2']));
    });

    test('deve renderizar múltiplas mídias (fotos e PDFs) contidas na mesma Resposta.lista', () async {
      final respostaMulti = Resposta(
        lista: ListaRespostas(
          valores: [
            Resposta(
              midia: ReferenciaMidia(
                imagem: ArquivoImagem(uuid: 'img_multi'),
              ),
            ),
            Resposta(
              midia: ReferenciaMidia(
                documento: ArquivoDocumento(
                  uuid: 'doc_multi',
                  nomeOriginal: 'laudo_multi.pdf',
                  quantidadePaginas: 1,
                ),
              ),
            ),
          ],
        ),
      );

      final registro = Registro()
        ..idProtocolo = 'cadastro_material'
        ..respostas['etapa_raiz'] = respostaMulti
        ..listas.add(
          GrupoRepetido()
            ..idLista = 'sub_detalhes'
            ..respostasItem['det_foto'] = respostaMulti,
        );

      final outPath = '${tempDir.path}/test_multi_midia_draft.pdf';
      final dummyImagePath = '${tempDir.path}/page_multi.jpg';
      final dummyBytes = Uint8List.fromList([
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
        0x3F, 0x00, 0x3F, 0xFF, 0xD9
      ]);
      File(dummyImagePath).writeAsBytesSync(dummyBytes);

      final solicitados = <String>[];
      final file = await pdfDraftService.drawDraft(
        registro,
        outPath,
        (uuid) {
          solicitados.add(uuid);
          return dummyImagePath;
        },
      );

      expect(file.existsSync(), isTrue);
      expect(solicitados, containsAll(['img_multi', 'doc_multi_p1']));
    });

    test('deve renderizar respostas de texto com Markdown e linhas em branco', () async {
      const textoMarkdown =
          '# Título Principal\n\n'
          'Parágrafo com **negrito**, *itálico*, `código` e ~~tachado~~.\n\n'
          '- Item de lista 1\n'
          '* Item de lista 2';

      final registro = Registro()
        ..idProtocolo = 'cadastro_material'
        ..respostas['desc_raiz'] = (Resposta()..texto = textoMarkdown)
        ..listas.add(
          GrupoRepetido()
            ..idLista = 'sub_detalhes'
            ..respostasItem['det_descricao'] = (Resposta()..texto = textoMarkdown),
        );

      final outPath = '${tempDir.path}/test_markdown_draft.pdf';
      final file = await pdfDraftService.drawDraft(
        registro,
        outPath,
        (uuid) => '',
      );

      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });
  });
}
