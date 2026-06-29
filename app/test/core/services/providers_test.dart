import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/providers.dart';
import 'package:app/core/services/crypto_service.dart';

void main() {
  test('cryptoServiceProvider should provide CryptoService instance', () {
    final container = ProviderContainer();
    final service = container.read(cryptoServiceProvider);

    expect(service, isA<CryptoService>());
  });
}
