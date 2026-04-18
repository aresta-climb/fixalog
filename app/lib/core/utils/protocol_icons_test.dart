import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/protocol_icons.dart';

void main() {
  group('ProtocolIcons Tests', () {
    test('Should return correct IconData for valid names', () {
      expect(ProtocolIcons.get('diamond'), equals(Icons.diamond_outlined));
      expect(ProtocolIcons.get('layers'), equals(Icons.layers_outlined));
      expect(ProtocolIcons.get('verified'), equals(Icons.verified_outlined));
    });

    test('Should return fallback help_outline for unknown names', () {
      expect(ProtocolIcons.get('unknown_icon_xyz'), equals(Icons.help_outline));
    });

    test('Should return fallback help_outline for empty names', () {
      expect(ProtocolIcons.get(''), equals(Icons.help_outline));
    });
  });
}
