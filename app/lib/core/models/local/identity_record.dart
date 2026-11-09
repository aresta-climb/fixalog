// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

/// Registro local da identidade do mantenedor/perito persistido no SQLite.
class IdentityRecord {
  int id = 0;

  String nome = '';
  String clubeAssociacao = '';
  DateTime dataRegistro = DateTime.fromMillisecondsSinceEpoch(0);

  IdentityRecord();

  /// Converte o registro para um mapa compatível com a tabela SQLite `identidade`.
  Map<String, Object?> toMap() {
    return {
      if (id > 0) 'id': id,
      'nome': nome,
      'clube_associacao': clubeAssociacao,
      'data_registro': dataRegistro.toIso8601String(),
    };
  }

  /// Reconstrói o registro a partir de uma linha da tabela SQLite `identidade`.
  factory IdentityRecord.fromMap(Map<String, Object?> map) {
    return IdentityRecord()
      ..id = (map['id'] as int?) ?? 0
      ..nome = (map['nome'] as String?) ?? ''
      ..clubeAssociacao = (map['clube_associacao'] as String?) ?? ''
      ..dataRegistro = DateTime.parse(map['data_registro'] as String);
  }
}
