// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:isar_community/isar.dart';

part 'submission_record.g.dart';

/// Constantes de status para o ciclo de vida do relatório/protocolo.
class SubmissionStatus {
  static const String emProgresso = 'EM_PROGRESSO';
  static const String gerado = 'GERADO';
}

@collection
class SubmissionRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String idSessao = '';

  String idProtocolo = '';

  String nomeProtocolo = '';

  DateTime dataInclusao = DateTime.now();

  // Hash completo para integridade
  String hashAssinatura = '';

  // Caminho do arquivo PDF salvo em disco
  String pdfPath = '';

  // Caminho do arquivo Protobuf (binarypb) salvo em disco
  String protobufPath = '';

  bool enviadoNuvem = false;

  /// Status do preenchimento: 'EM_PROGRESSO' ou 'GERADO'
  String status = SubmissionStatus.emProgresso;

  @ignore
  bool get isEmProgresso =>
      status == SubmissionStatus.emProgresso || (status.isEmpty && pdfPath.isEmpty);

  @ignore
  bool get isGerado =>
      status == SubmissionStatus.gerado || (status.isEmpty && pdfPath.isNotEmpty);
}
