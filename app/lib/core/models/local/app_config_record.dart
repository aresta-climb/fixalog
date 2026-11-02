// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

/// Registro singleton de configuração local do aplicativo persistido no SQLite.
class AppConfigRecord {
  int id = 1;

  /// Versão dos termos de uso que o usuário aceitou.
  /// 0 significa que nenhum termo foi aceito ainda.
  int acceptedTermsVersion = 0;

  /// Alias em português para manter conformidade com o princípio de Tudo em Português.
  int get versaoTermosAceita => acceptedTermsVersion;
  set versaoTermosAceita(int valor) => acceptedTermsVersion = valor;

  /// Data e hora exata em que o usuário aceitou os termos de uso.
  DateTime? dataHoraAceiteTermos;

  AppConfigRecord({
    this.id = 1,
    this.acceptedTermsVersion = 0,
    this.dataHoraAceiteTermos,
  });

  /// Converte o registro para um mapa compatível com a tabela SQLite `configuracao_app`.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'versao_termos_aceita': acceptedTermsVersion,
      'data_hora_aceite_termos': dataHoraAceiteTermos?.toIso8601String(),
    };
  }

  /// Reconstrói o registro a partir de uma linha da tabela SQLite `configuracao_app`.
  factory AppConfigRecord.fromMap(Map<String, Object?> map) {
    final dataStr = map['data_hora_aceite_termos'] as String?;
    return AppConfigRecord(
      id: (map['id'] as int?) ?? 1,
      acceptedTermsVersion: (map['versao_termos_aceita'] as int?) ?? 0,
      dataHoraAceiteTermos:
          dataStr != null && dataStr.isNotEmpty ? DateTime.parse(dataStr) : null,
    );
  }
}
