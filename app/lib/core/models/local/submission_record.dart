// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

/// Constantes de status para o ciclo de vida do relatório/protocolo.
class SubmissionStatus {
  static const String emProgresso = 'EM_PROGRESSO';
  static const String gerado = 'GERADO';
}

/// Constantes de tipo de registro para diferenciar manutenções e materiais.
class SubmissionTipoRegistro {
  static const String manutencao = 'MANUTENCAO';
  static const String material = 'MATERIAL';
}

/// Registro local persistido no banco SQLite representando uma sessão de manutenção ou de material.
class SubmissionRecord {
  int id = 0;

  String idSessao = '';

  String idProtocolo = '';

  String nomeProtocolo = '';

  /// Título descritivo para exibição em listas (ex.: nome do material/conjunto ou nome da via).
  String tituloExibicao = '';

  /// Categoria do registro: 'MANUTENCAO' (padrão) ou 'MATERIAL'.
  String tipoRegistro = SubmissionTipoRegistro.manutencao;

  DateTime dataInclusao = DateTime.now();

  /// Data e hora em que o material foi selecionado pela última vez em uma manutenção.
  DateTime? dataUltimaSelecao;

  /// Hash completo para integridade.
  String hashAssinatura = '';

  /// Caminho do arquivo PDF resumido salvo em disco.
  String pdfPath = '';

  /// Caminho do arquivo Protobuf (binarypb) ou EPUB salvo em disco.
  String protobufPath = '';

  bool enviadoNuvem = false;

  /// Status do preenchimento: 'EM_PROGRESSO' ou 'GERADO'.
  String status = SubmissionStatus.emProgresso;

  SubmissionRecord();

  bool get isEmProgresso =>
      status == SubmissionStatus.emProgresso ||
      (status.isEmpty && pdfPath.isEmpty);

  bool get isGerado =>
      status == SubmissionStatus.gerado ||
      (status.isEmpty && pdfPath.isNotEmpty);

  bool get isMaterial =>
      tipoRegistro == SubmissionTipoRegistro.material ||
      idProtocolo == 'cadastro_material';

  bool get isManutencao => !isMaterial;

  /// Converte o registro para um mapa compatível com a tabela SQLite `submissoes`.
  Map<String, Object?> toMap() {
    return {
      if (id > 0) 'id': id,
      'id_sessao': idSessao,
      'id_protocolo': idProtocolo,
      'nome_protocolo': nomeProtocolo,
      'titulo_exibicao': tituloExibicao,
      'tipo_registro': tipoRegistro,
      'data_inclusao': dataInclusao.toIso8601String(),
      'data_ultima_selecao': dataUltimaSelecao?.toIso8601String(),
      'hash_assinatura': hashAssinatura,
      'pdf_path': pdfPath,
      'protobuf_path': protobufPath,
      'enviado_nuvem': enviadoNuvem ? 1 : 0,
      'status': status,
    };
  }

  /// Reconstrói o registro a partir de uma linha da tabela SQLite `submissoes`.
  factory SubmissionRecord.fromMap(Map<String, Object?> map) {
    final selecaoStr = map['data_ultima_selecao'] as String?;
    return SubmissionRecord()
      ..id = (map['id'] as int?) ?? 0
      ..idSessao = (map['id_sessao'] as String?) ?? ''
      ..idProtocolo = (map['id_protocolo'] as String?) ?? ''
      ..nomeProtocolo = (map['nome_protocolo'] as String?) ?? ''
      ..tituloExibicao = (map['titulo_exibicao'] as String?) ?? ''
      ..tipoRegistro =
          (map['tipo_registro'] as String?) ?? SubmissionTipoRegistro.manutencao
      ..dataInclusao = DateTime.parse(map['data_inclusao'] as String)
      ..dataUltimaSelecao = selecaoStr != null && selecaoStr.isNotEmpty
          ? DateTime.parse(selecaoStr)
          : null
      ..hashAssinatura = (map['hash_assinatura'] as String?) ?? ''
      ..pdfPath = (map['pdf_path'] as String?) ?? ''
      ..protobufPath = (map['protobuf_path'] as String?) ?? ''
      ..enviadoNuvem = ((map['enviado_nuvem'] as int?) ?? 0) != 0
      ..status = (map['status'] as String?) ?? SubmissionStatus.emProgresso;
  }
}
