// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dados de um documento PDF selecionado pelo usuário.
class DocumentoSelecionado {
  /// Nome original do arquivo (ex: `nota_fiscal.pdf`).
  final String nome;

  /// Caminho local do arquivo selecionado, quando disponível.
  final String? caminho;

  /// Conteúdo binário completo do arquivo PDF.
  final Uint8List bytes;

  const DocumentoSelecionado({
    required this.nome,
    this.caminho,
    required this.bytes,
  });
}

/// Assinatura de função para seleção customizada de PDF (permite injeção determinística em testes).
typedef FuncaoSelecaoPdf = Future<DocumentoSelecionado?> Function();

/// Serviço responsável por selecionar documentos PDF do sistema de arquivos do dispositivo.
class SeletorDocumentoService {
  final FuncaoSelecaoPdf? _seletorCustomizado;

  SeletorDocumentoService({FuncaoSelecaoPdf? seletorCustomizado})
      : _seletorCustomizado = seletorCustomizado;

  /// Abre o seletor de arquivos filtrando por extensão `.pdf` e retorna os bytes e metadados do arquivo.
  ///
  /// Retorna `null` caso o usuário cancele a seleção ou o arquivo esteja vazio/ilegível.
  Future<DocumentoSelecionado?> selecionarPdf() async {
    if (_seletorCustomizado != null) {
      return _seletorCustomizado();
    }

    final arquivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (arquivo == null) return null;

    try {
      final bytes = await arquivo.readAsBytes();
      if (bytes.isEmpty) return null;
      return DocumentoSelecionado(
        nome: arquivo.name,
        caminho: arquivo.path,
        bytes: bytes,
      );
    } catch (_) {
      return null;
    }
  }
}

final seletorDocumentoServiceProvider =
    Provider<SeletorDocumentoService>((ref) {
  return SeletorDocumentoService();
});
