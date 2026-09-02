// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixlog/core/services/crypto_service.dart';

final cryptoServiceProvider = Provider<CryptoService>((ref) {
  return CryptoService();
});
