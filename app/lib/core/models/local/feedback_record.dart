// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

/// Registro local de relato de feedback in-app persistido na tabela `fila_feedback` do SQLite.
class FeedbackRecord {
  /// Chave primária auto-incremental atribuída pelo SQLite (`0` antes de persistir).
  int id;

  /// Identificador único universal (UUID v4) do feedback.
  final String idFeedback;

  /// Mensagem descritiva informada pelo auditor/escalador.
  final String mensagem;

  /// Categoria do relato (`protocolo`, `aplicativo` ou `outro`).
  final String categoria;

  /// Caminho local da captura de tela anotada e comprimida (`.webp` ou `.png`).
  final String caminhoImagem;

  /// Objeto JSON serializado contendo metadados do aparelho, idioma, protocolo e auditor.
  final String metadadosJson;

  /// Data e hora UTC em que o relato foi registrado em campo.
  final DateTime dataCriacao;

  /// Indica se o relato já foi transmitido com sucesso (HTTP 2xx) para a nuvem.
  final bool enviado;

  FeedbackRecord({
    this.id = 0,
    required this.idFeedback,
    required this.mensagem,
    this.categoria = 'aplicativo',
    this.caminhoImagem = '',
    this.metadadosJson = '{}',
    required this.dataCriacao,
    this.enviado = false,
  });

  /// Cria uma cópia do registro alterando apenas os campos informados.
  FeedbackRecord copiarCom({
    int? id,
    String? idFeedback,
    String? mensagem,
    String? categoria,
    String? caminhoImagem,
    String? metadadosJson,
    DateTime? dataCriacao,
    bool? enviado,
  }) {
    return FeedbackRecord(
      id: id ?? this.id,
      idFeedback: idFeedback ?? this.idFeedback,
      mensagem: mensagem ?? this.mensagem,
      categoria: categoria ?? this.categoria,
      caminhoImagem: caminhoImagem ?? this.caminhoImagem,
      metadadosJson: metadadosJson ?? this.metadadosJson,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      enviado: enviado ?? this.enviado,
    );
  }

  /// Converte o registro para um mapa compatível com a tabela SQLite `fila_feedback`.
  Map<String, Object?> toMap() {
    return {
      if (id > 0) 'id': id,
      'id_feedback': idFeedback,
      'mensagem': mensagem,
      'categoria': categoria,
      'caminho_imagem': caminhoImagem,
      'metadados_json': metadadosJson,
      'data_criacao': dataCriacao.toIso8601String(),
      'enviado': enviado ? 1 : 0,
    };
  }

  /// Reconstrói o registro a partir de uma linha da tabela SQLite `fila_feedback`.
  factory FeedbackRecord.fromMap(Map<String, Object?> map) {
    final dataStr = map['data_criacao'] as String?;
    final categoriaStr = (map['categoria'] as String?)?.trim();
    final metadadosStr = (map['metadados_json'] as String?)?.trim();
    return FeedbackRecord(
      id: (map['id'] as int?) ?? 0,
      idFeedback: (map['id_feedback'] as String?) ?? '',
      mensagem: (map['mensagem'] as String?) ?? '',
      categoria: (categoriaStr != null && categoriaStr.isNotEmpty)
          ? categoriaStr
          : 'aplicativo',
      caminhoImagem: (map['caminho_imagem'] as String?) ?? '',
      metadadosJson: (metadadosStr != null && metadadosStr.isNotEmpty)
          ? metadadosStr
          : '{}',
      dataCriacao: dataStr != null && dataStr.isNotEmpty
          ? DateTime.parse(dataStr)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      enviado: ((map['enviado'] as int?) ?? 0) != 0,
    );
  }
}
