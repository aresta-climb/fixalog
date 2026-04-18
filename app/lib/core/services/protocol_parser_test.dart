import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/protocol_parser.dart';
import 'package:app/core/models/proto/protos/fixalog.pb.dart';

void main() {
  group('ProtocolParser Tests', () {
    test('Should parse a valid maintenance protocol YAML', () {
      const yaml = '''
protocolo:
  id: "test_protocol"
  nome: "Test Protocol"
  campos:
    - id: "field_1"
      label: "Field 1"
      tipo: TEXT
      obrigatorio: true
    - id: "field_2"
      label: "Field 2"
      tipo: DROPDOWN
      ui_hint: LARGE_TILES
      opcoes:
        - valor: "opt1"
          label: "Option 1"
          icon_name: "home"
''';

      final protocol = ProtocolParser.fromYaml(yaml);

      expect(protocol.id, equals('test_protocol'));
      expect(protocol.nome, equals('Test Protocol'));
      expect(protocol.campos.length, equals(2));
      expect(protocol.campos[0].id, equals('field_1'));
      expect(protocol.campos[0].tipo, equals(Campo_Tipo.TEXT));
      expect(protocol.campos[0].obrigatorio, isTrue);
      
      expect(protocol.campos[1].tipo, equals(Campo_Tipo.DROPDOWN));
      expect(protocol.campos[1].uiHint, equals(Campo_UIHint.LARGE_TILES));
      expect(protocol.campos[1].opcoes[0].valor, equals('opt1'));
      expect(protocol.campos[1].opcoes[0].iconName, equals('home'));
    });

    test('Should handle complex types like GPS and BOOLEAN', () {
      const yaml = '''
protocolo:
  id: "gps_test"
  nome: "GPS Test"
  campos:
    - id: "loc"
      label: "Location"
      tipo: GPS
    - id: "confirm"
      label: "Confirm?"
      tipo: BOOLEAN
''';

      final protocol = ProtocolParser.fromYaml(yaml);

      expect(protocol.campos[0].tipo, equals(Campo_Tipo.GPS));
      expect(protocol.campos[1].tipo, equals(Campo_Tipo.BOOLEAN));
    });

    test('Should throw exception or handle malformed YAML', () {
      const yaml = 'invalid: yaml: : content';
      
      expect(() => ProtocolParser.fromYaml(yaml), throwsException);
    });
  });
}
