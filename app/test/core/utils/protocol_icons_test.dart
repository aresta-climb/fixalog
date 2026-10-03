// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/utils/protocol_icons.dart';

void main() {
  group('ProtocolIcons Utility Tests', () {
    test('retorna ícones mapeados corretamente', () {
      expect(ProtocolIcons.get('layers'), Icons.layers_outlined);
      expect(ProtocolIcons.get('bolt'), Icons.bolt_rounded);
      expect(ProtocolIcons.get('warning'), Icons.warning_amber_rounded);
      expect(ProtocolIcons.get('camera'), Icons.camera_alt_outlined);
    });

    test('retorna Icons.help_outline para nulo, vazio ou desconhecido', () {
      expect(ProtocolIcons.get(null), Icons.help_outline);
      expect(ProtocolIcons.get(''), Icons.help_outline);
      expect(ProtocolIcons.get('icone_inexistente_xyz'), Icons.help_outline);
    });
  });
}
