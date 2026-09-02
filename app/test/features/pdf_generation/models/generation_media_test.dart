// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixlog/features/pdf_generation/models/generation_media.dart';

void main() {
  group('GenerationMedia Model Tests', () {
    test('instancia com arquivo e descrição padrão', () {
      final file = File('/tmp/foto.jpg');
      final media = GenerationMedia(file: file);

      expect(media.file.path, '/tmp/foto.jpg');
      expect(media.description, '');
    });

    test('instancia com descrição customizada', () {
      final file = File('/tmp/foto2.jpg');
      final media = GenerationMedia(file: file, description: 'Foto da ancoragem');

      expect(media.file.path, '/tmp/foto2.jpg');
      expect(media.description, 'Foto da ancoragem');
    });
  });
}
