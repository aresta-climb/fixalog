import 'package:isar/isar.dart';

part 'identity_record.g.dart';

@collection
class IdentityRecord {
  Id id = Isar.autoIncrement;

  late String nome;
  late String clubeAssociacao;
  late DateTime dataRegistro;
}
