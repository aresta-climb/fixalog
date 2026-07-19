// This is a generated file - do not edit.
//
// Generated from registro.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class DetalheInspecao_ResultadoInspecao extends $pb.ProtobufEnum {
  static const DetalheInspecao_ResultadoInspecao APROVADO =
      DetalheInspecao_ResultadoInspecao._(0, _omitEnumNames ? '' : 'APROVADO');
  static const DetalheInspecao_ResultadoInspecao REAPERTO_REALIZADO =
      DetalheInspecao_ResultadoInspecao._(
          1, _omitEnumNames ? '' : 'REAPERTO_REALIZADO');
  static const DetalheInspecao_ResultadoInspecao SUBSTITUIR =
      DetalheInspecao_ResultadoInspecao._(
          2, _omitEnumNames ? '' : 'SUBSTITUIR');

  static const $core.List<DetalheInspecao_ResultadoInspecao> values =
      <DetalheInspecao_ResultadoInspecao>[
    APROVADO,
    REAPERTO_REALIZADO,
    SUBSTITUIR,
  ];

  static final $core.List<DetalheInspecao_ResultadoInspecao?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static DetalheInspecao_ResultadoInspecao? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DetalheInspecao_ResultadoInspecao._(super.value, super.name);
}

class AvaliacaoFinal_ResultadoGeral extends $pb.ProtobufEnum {
  static const AvaliacaoFinal_ResultadoGeral APROVADO =
      AvaliacaoFinal_ResultadoGeral._(0, _omitEnumNames ? '' : 'APROVADO');
  static const AvaliacaoFinal_ResultadoGeral APROVADO_COM_RESSALVAS =
      AvaliacaoFinal_ResultadoGeral._(
          1, _omitEnumNames ? '' : 'APROVADO_COM_RESSALVAS');
  static const AvaliacaoFinal_ResultadoGeral REQUER_NOVA_VISITA =
      AvaliacaoFinal_ResultadoGeral._(
          2, _omitEnumNames ? '' : 'REQUER_NOVA_VISITA');

  static const $core.List<AvaliacaoFinal_ResultadoGeral> values =
      <AvaliacaoFinal_ResultadoGeral>[
    APROVADO,
    APROVADO_COM_RESSALVAS,
    REQUER_NOVA_VISITA,
  ];

  static final $core.List<AvaliacaoFinal_ResultadoGeral?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static AvaliacaoFinal_ResultadoGeral? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AvaliacaoFinal_ResultadoGeral._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
