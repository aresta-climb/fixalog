import 'package:flutter_test/flutter_test.dart';
import 'package:fixlog/core/models/local/app_config_record.dart';

void main() {
  group('AppConfigRecord Tests', () {
    test('Should construct with default parameters', () {
      final record = AppConfigRecord();

      expect(record.id, 1);
      expect(record.acceptedTermsVersion, 0);
    });

    test('Should allow setting specific parameters', () {
      final record = AppConfigRecord();
      record.id = 2;
      record.acceptedTermsVersion = 1;

      expect(record.id, 2);
      expect(record.acceptedTermsVersion, 1);
    });
  });
}
