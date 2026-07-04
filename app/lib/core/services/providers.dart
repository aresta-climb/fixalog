import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/crypto_service.dart';

final cryptoServiceProvider = Provider<CryptoService>((ref) {
  return CryptoService();
});
