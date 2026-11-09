// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'dart:typed_data';
import 'package:protobuf/protobuf.dart';
import 'package:yaml/yaml.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/models/proto/protos/wizard.pb.dart';

/// Serializador e desserializador determinístico entre o modelo Protobuf [Registro]
/// (estaticamente tipado em memória) e a representação textual `registro.yaml`
/// (legível por humanos para preservação de longo prazo em disco e no container EPUB 3).
class SerializadorYamlRegistro {
  /// Descritores compilados das mensagens de `registro.proto` e `wizard.proto`.
  static final Map<String, BuilderInfo> descritoresCompilados = {
    'ArquivoImagem': ArquivoImagem().info_,
    'ArquivoVideo': ArquivoVideo().info_,
    'ArquivoAudio': ArquivoAudio().info_,
    'ArquivoDocumento': ArquivoDocumento().info_,
    'ReferenciaMidia': ReferenciaMidia().info_,
    'ListaRespostas': ListaRespostas().info_,
    'Resposta': Resposta().info_,
    'GrupoRepetido': GrupoRepetido().info_,
    'Registro': Registro().info_,
    'DefinicaoProtocolo': DefinicaoProtocolo().info_,
    'Bloco': Bloco().info_,
    'ConteudoStep': ConteudoStep().info_,
    'Step': Step().info_,
    'StepInstrucao': StepInstrucao().info_,
    'StepCampoSimples': StepCampoSimples().info_,
    'OpcaoCampo': OpcaoCampo().info_,
    'StepSelecaoRamo': StepSelecaoRamo().info_,
    'Ramo': Ramo().info_,
    'StepListaAcoes': StepListaAcoes().info_,
    'TipoAcao': TipoAcao().info_,
    'StepRefMateriais': StepRefMateriais().info_,
  };

  /// Converte uma instância tipada [Registro] para texto YAML determinístico,
  /// preservando textos multilinhas (como `yamlConteudo`) em blocos literais (`|` / `|-`).
  static String paraYaml(Registro registro) {
    final mapaJson = registro.toProto3Json() as Map<String, dynamic>;
    final buffer = StringBuffer();
    _escreverMapaYaml(mapaJson, buffer, 0);
    return buffer.toString();
  }

  /// Reconstrói e valida estaticamente uma instância [Registro] a partir de [conteudoYaml].
  ///
  /// Lança [FormatException] caso o YAML não represente um mapa válido ou viole o schema Protobuf.
  static Registro deYaml(String conteudoYaml) {
    final nodo = loadYaml(conteudoYaml);
    if (nodo is! YamlMap) {
      throw const FormatException(
        'O conteúdo de registro.yaml deve ser um mapa YAML válido na raiz.',
      );
    }
    final mapaPuro = _converterNodoYaml(nodo);
    try {
      return Registro()..mergeFromProto3Json(mapaPuro);
    } catch (e) {
      throw FormatException('Falha ao validar registro.yaml contra o schema Protobuf: $e');
    }
  }

  /// Lê um [Registro] a partir de um mapa de arquivos extraídos de um container EPUB,
  /// priorizando `${prefixo}registro.yaml` e utilizando `${prefixo}registro.binarypb` como fallback legado.
  static Registro lerDeMapaArquivos(
    Map<String, Uint8List> arquivos, {
    String prefixo = 'OEBPS/dados/',
  }) {
    final bytesYaml = arquivos['${prefixo}registro.yaml'];
    if (bytesYaml != null) {
      return deYaml(utf8.decode(bytesYaml));
    }
    final bytesPb = arquivos['${prefixo}registro.binarypb'];
    if (bytesPb != null) {
      return Registro.fromBuffer(bytesPb);
    }
    throw FormatException(
      'Nenhum manifesto registro.yaml ou registro.binarypb encontrado em $prefixo.',
    );
  }

  /// Valida que todas as mensagens e campos declarados em `registro.proto` e `wizard.proto`
  /// correspondem exatamente aos descritores compilados em `registro.pb.dart` e `wizard.pb.dart`.
  static List<String> validarSincroniaSchemasProto({
    required String conteudoRegistroProto,
    required String conteudoWizardProto,
  }) {
    final erros = <String>[];
    final mensagensExtraidas = <String, Map<int, String>>{
      ..._extrairMensagensDoProto(conteudoRegistroProto),
      ..._extrairMensagensDoProto(conteudoWizardProto),
    };

    for (final nomeEsperado in descritoresCompilados.keys) {
      if (!mensagensExtraidas.containsKey(nomeEsperado)) {
        erros.add("Mensagem '$nomeEsperado' ausente nos arquivos .proto.");
      }
    }

    for (final nomeDeclarado in mensagensExtraidas.keys) {
      if (!descritoresCompilados.containsKey(nomeDeclarado)) {
        erros.add(
          "Mensagem '$nomeDeclarado' declarada no .proto não possui classe compilada registrada.",
        );
      }
    }

    for (final entrada in descritoresCompilados.entries) {
      final nomeMensagem = entrada.key;
      final camposProto = mensagensExtraidas[nomeMensagem];
      if (camposProto == null) continue;

      final camposCompilados = entrada.value.fieldInfo;
      final todasTags = <int>{
        ...camposProto.keys,
        ...camposCompilados.keys,
      }.toList()
        ..sort();

      for (final tag in todasTags) {
        final nomeNoProto = camposProto[tag];
        final nomeCompilado = camposCompilados[tag]?.name;
        if (nomeNoProto != nomeCompilado) {
          erros.add(
            "Divergência em $nomeMensagem (tag $tag): .proto define '$nomeNoProto', mas classe compilada define '$nomeCompilado'.",
          );
        }
      }
    }

    return erros;
  }

  static void _escreverMapaYaml(
    Map<dynamic, dynamic> mapa,
    StringBuffer buffer,
    int nivel,
  ) {
    final indent = '  ' * nivel;
    final chaves = mapa.keys.map((k) => k.toString()).toList()..sort();
    for (final chave in chaves) {
      final valor = mapa[chave];
      final chaveSegura = _precisaAspasChave(chave) ? jsonEncode(chave) : chave;
      if (valor is Map) {
        if (valor.isEmpty) {
          buffer.writeln('$indent$chaveSegura: {}');
        } else {
          buffer.writeln('$indent$chaveSegura:');
          _escreverMapaYaml(valor, buffer, nivel + 1);
        }
      } else if (valor is List) {
        buffer.writeln('$indent$chaveSegura:');
        final indentItem = '  ' * (nivel + 1);
        for (final item in valor) {
          if (item is Map) {
            buffer.writeln('$indentItem-');
            _escreverMapaYaml(item, buffer, nivel + 2);
          } else {
            buffer.writeln(
              '$indentItem- ${_formatarEscalarYaml(item, nivel + 2)}',
            );
          }
        }
      } else {
        buffer.writeln(
          '$indent$chaveSegura: ${_formatarEscalarYaml(valor, nivel + 1)}',
        );
      }
    }
  }

  static bool _precisaAspasChave(String chave) {
    return !RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(chave);
  }

  static String _formatarEscalarYaml(Object? valor, int nivelBloco) {
    if (valor is String) {
      if (valor.contains('\n')) {
        final possuiQuebraFinal = valor.endsWith('\n');
        final indicador = possuiQuebraFinal ? '|' : '|-';
        final corpoSemQuebraFinal = possuiQuebraFinal
            ? valor.substring(0, valor.length - 1)
            : valor;
        final indentBloco = '  ' * nivelBloco;
        final linhas = corpoSemQuebraFinal
            .split('\n')
            .map((l) => '$indentBloco$l')
            .join('\n');
        return '$indicador\n$linhas';
      }
      return jsonEncode(valor);
    }
    return valor.toString();
  }

  static Object? _converterNodoYaml(Object? nodo) {
    if (nodo is YamlMap) {
      return <String, dynamic>{
        for (final entry in nodo.entries)
          entry.key.toString(): _converterNodoYaml(entry.value),
      };
    }
    if (nodo is YamlList) {
      return nodo.map(_converterNodoYaml).toList();
    }
    return nodo;
  }

  static Map<String, Map<int, String>> _extrairMensagensDoProto(
    String conteudoProto,
  ) {
    final resultado = <String, Map<int, String>>{};
    String? mensagemAtual;
    var profundidadeChaves = 0;
    int? profundidadeEnum;

    final regexMensagem = RegExp(r'^\s*message\s+(\w+)\s*\{');
    final regexEnum = RegExp(r'^\s*enum\s+\w+\s*\{');
    final regexCampo = RegExp(
      r'^\s*(?:repeated\s+)?(?:map<[^>]+>\s+|\w+\s+)(\w+)\s*=\s*(\d+)\s*;',
    );

    for (final linhaBruta in conteudoProto.split('\n')) {
      final linha = linhaBruta.split('//').first.trim();
      if (linha.isEmpty) continue;

      if (mensagemAtual == null) {
        final matchMsg = regexMensagem.firstMatch(linha);
        if (matchMsg != null) {
          mensagemAtual = matchMsg.group(1)!;
          resultado[mensagemAtual] = <int, String>{};
          profundidadeChaves = 1;
        }
        continue;
      }

      if (profundidadeEnum == null && regexEnum.hasMatch(linha)) {
        profundidadeEnum = profundidadeChaves;
      }

      if (profundidadeEnum == null) {
        final matchCampo = regexCampo.firstMatch(linha);
        if (matchCampo != null) {
          final nomeSnake = matchCampo.group(1)!;
          final tag = int.parse(matchCampo.group(2)!);
          resultado[mensagemAtual]![tag] = _snakeParaCamel(nomeSnake);
        }
      }

      for (final char in linha.runes) {
        if (char == 123) {
          profundidadeChaves++;
        } else if (char == 125) {
          profundidadeChaves--;
          if (profundidadeEnum != null &&
              profundidadeChaves <= profundidadeEnum) {
            profundidadeEnum = null;
          }
          if (profundidadeChaves <= 0) {
            mensagemAtual = null;
            profundidadeChaves = 0;
          }
        }
      }
    }

    return resultado;
  }

  static String _snakeParaCamel(String texto) {
    final partes = texto.split('_');
    final buffer = StringBuffer(partes.first);
    for (var i = 1; i < partes.length; i++) {
      final p = partes[i];
      buffer.write('${p[0].toUpperCase()}${p.substring(1)}');
    }
    return buffer.toString();
  }
}
