// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:io';

class GenerationMedia {
  final File file;
  final String description;

  GenerationMedia({
    required this.file,
    this.description = '',
  });
}
