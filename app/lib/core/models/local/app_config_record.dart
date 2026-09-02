// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'package:isar_community/isar.dart';

part 'app_config_record.g.dart';

@collection
class AppConfigRecord {
  Id id = 1; // Singleton record

  /// Version of the terms of use that the user has accepted.
  /// 0 means none accepted yet.
  int acceptedTermsVersion = 0;
}
