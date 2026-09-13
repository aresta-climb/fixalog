// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'package:isar_community/isar.dart';

part 'app_config_record.g.dart';

@collection
class AppConfigRecord {
  Id id = 1; // Registro singleton

  /// Versão dos termos de uso que o usuário aceitou.
  /// 0 significa que nenhum termo foi aceito ainda.
  int acceptedTermsVersion = 0;

  /// Alias em português para manter conformidade com o princípio de Tudo em Português.
  @ignore
  int get versaoTermosAceita => acceptedTermsVersion;
  set versaoTermosAceita(int valor) => acceptedTermsVersion = valor;

  /// Data e hora exata em que o usuário aceitou os termos de uso.
  DateTime? dataHoraAceiteTermos;
}
