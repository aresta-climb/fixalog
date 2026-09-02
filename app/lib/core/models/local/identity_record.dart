// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'package:isar_community/isar.dart';

part 'identity_record.g.dart';

@collection
class IdentityRecord {
  Id id = Isar.autoIncrement;

  late String nome;
  late String clubeAssociacao;
  late DateTime dataRegistro;
}
