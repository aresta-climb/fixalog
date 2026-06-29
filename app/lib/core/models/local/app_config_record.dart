import 'package:isar/isar.dart';

part 'app_config_record.g.dart';

@collection
class AppConfigRecord {
  Id id = 1; // Singleton record

  /// Version of the terms of use that the user has accepted.
  /// 0 means none accepted yet.
  int acceptedTermsVersion = 0;
}
