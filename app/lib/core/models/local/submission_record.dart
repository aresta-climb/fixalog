// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:isar_community/isar.dart';

part 'submission_record.g.dart';

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

/// Registro local persistido no banco Isar representando uma sessão de manutenção ou de material.
@collection
class SubmissionRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
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

  /// Caminho do arquivo EPUB/PDF salvo em disco.
  String pdfPath = '';

  /// Caminho do arquivo Protobuf (binarypb) salvo em disco.
  String protobufPath = '';

  bool enviadoNuvem = false;

  /// Status do preenchimento: 'EM_PROGRESSO' ou 'GERADO'.
  String status = SubmissionStatus.emProgresso;

  @ignore
  bool get isEmProgresso =>
      status == SubmissionStatus.emProgresso || (status.isEmpty && pdfPath.isEmpty);

  @ignore
  bool get isGerado =>
      status == SubmissionStatus.gerado || (status.isEmpty && pdfPath.isNotEmpty);

  @ignore
  bool get isMaterial =>
      tipoRegistro == SubmissionTipoRegistro.material ||
      idProtocolo == 'cadastro_material';

  @ignore
  bool get isManutencao => !isMaterial;
}
