import 'package:yaml/yaml.dart';
import '../models/proto/protos/fixalog.pb.dart';

class ProtocolParser {
  static Protocolo fromYaml(String yamlString) {
    final doc = loadYaml(yamlString) as YamlMap;
    final protocolData = doc['protocolo'] as YamlMap;

    return Protocolo(
      id: protocolData['id']?.toString() ?? '',
      nome: protocolData['nome']?.toString() ?? '',
      descricao: protocolData['descricao']?.toString() ?? '',
      campos: (protocolData['campos'] as YamlList?)?.map((campoData) {
        return Campo(
          id: campoData['id']?.toString() ?? '',
          label: campoData['label']?.toString() ?? '',
          sublabel: campoData['sublabel']?.toString() ?? '',
          tipo: _parseTipo(campoData['tipo']?.toString()),
          uiHint: _parseUIHint(campoData['ui_hint']?.toString()),
          obrigatorio: campoData['obrigatorio'] == true,
          opcoes: (campoData['opcoes'] as YamlList?)?.map((opcaoData) {
            return Opcao(
              valor: opcaoData['valor']?.toString() ?? '',
              label: opcaoData['label']?.toString() ?? '',
              sublabel: opcaoData['sublabel']?.toString() ?? '',
              iconName: opcaoData['icon_name']?.toString() ?? '',
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  static Campo_Tipo _parseTipo(String? tipo) {
    switch (tipo?.toUpperCase()) {
      case 'TEXT': return Campo_Tipo.TEXT;
      case 'NUMBER': return Campo_Tipo.NUMBER;
      case 'DROPDOWN': return Campo_Tipo.DROPDOWN;
      case 'IMAGE': return Campo_Tipo.IMAGE;
      case 'BOOLEAN': return Campo_Tipo.BOOLEAN;
      case 'GPS': return Campo_Tipo.GPS;
      case 'VIDEO': return Campo_Tipo.VIDEO;
      case 'SIGNATURE': return Campo_Tipo.SIGNATURE;
      default: return Campo_Tipo.TEXT;
    }
  }

  static Campo_UIHint _parseUIHint(String? hint) {
    switch (hint?.toUpperCase()) {
      case 'LARGE_TILES': return Campo_UIHint.LARGE_TILES;
      case 'CAMERA_ACTION': return Campo_UIHint.CAMERA_ACTION;
      default: return Campo_UIHint.DEFAULT;
    }
  }
}
