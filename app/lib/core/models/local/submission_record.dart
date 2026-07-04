import 'package:isar_community/isar.dart';

part 'submission_record.g.dart';

@collection
class SubmissionRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String idSessao;

  late String idProtocolo;

  late String nomeProtocolo;

  late DateTime dataInclusao;

  // Hash completo para integridade
  late String hashAssinatura;

  // Caminho do arquivo PDF salvo em disco
  late String pdfPath;

  // Caminho do arquivo YAML salvo em disco
  late String yamlPath;

  bool enviadoNuvem = false;
}
