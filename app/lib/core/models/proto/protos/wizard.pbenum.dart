// This is a generated file - do not edit.
//
// Generated from wizard.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class StepInstrucao_NivelAlerta extends $pb.ProtobufEnum {
  static const StepInstrucao_NivelAlerta INFO =
      StepInstrucao_NivelAlerta._(0, _omitEnumNames ? '' : 'INFO');
  static const StepInstrucao_NivelAlerta ATENCAO =
      StepInstrucao_NivelAlerta._(1, _omitEnumNames ? '' : 'ATENCAO');
  static const StepInstrucao_NivelAlerta PERIGO =
      StepInstrucao_NivelAlerta._(2, _omitEnumNames ? '' : 'PERIGO');

  static const $core.List<StepInstrucao_NivelAlerta> values =
      <StepInstrucao_NivelAlerta>[
    INFO,
    ATENCAO,
    PERIGO,
  ];

  static final $core.List<StepInstrucao_NivelAlerta?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static StepInstrucao_NivelAlerta? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const StepInstrucao_NivelAlerta._(super.value, super.name);
}

class StepCampoSimples_TipoCampo extends $pb.ProtobufEnum {
  static const StepCampoSimples_TipoCampo TEXT =
      StepCampoSimples_TipoCampo._(0, _omitEnumNames ? '' : 'TEXT');
  static const StepCampoSimples_TipoCampo NUMBER =
      StepCampoSimples_TipoCampo._(1, _omitEnumNames ? '' : 'NUMBER');
  static const StepCampoSimples_TipoCampo DROPDOWN =
      StepCampoSimples_TipoCampo._(2, _omitEnumNames ? '' : 'DROPDOWN');
  static const StepCampoSimples_TipoCampo IMAGE =
      StepCampoSimples_TipoCampo._(3, _omitEnumNames ? '' : 'IMAGE');
  static const StepCampoSimples_TipoCampo BOOLEAN =
      StepCampoSimples_TipoCampo._(4, _omitEnumNames ? '' : 'BOOLEAN');
  static const StepCampoSimples_TipoCampo GPS =
      StepCampoSimples_TipoCampo._(5, _omitEnumNames ? '' : 'GPS');
  static const StepCampoSimples_TipoCampo VIDEO =
      StepCampoSimples_TipoCampo._(6, _omitEnumNames ? '' : 'VIDEO');
  static const StepCampoSimples_TipoCampo SIGNATURE =
      StepCampoSimples_TipoCampo._(7, _omitEnumNames ? '' : 'SIGNATURE');
  static const StepCampoSimples_TipoCampo DATE =
      StepCampoSimples_TipoCampo._(8, _omitEnumNames ? '' : 'DATE');

  static const $core.List<StepCampoSimples_TipoCampo> values =
      <StepCampoSimples_TipoCampo>[
    TEXT,
    NUMBER,
    DROPDOWN,
    IMAGE,
    BOOLEAN,
    GPS,
    VIDEO,
    SIGNATURE,
    DATE,
  ];

  static final $core.List<StepCampoSimples_TipoCampo?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static StepCampoSimples_TipoCampo? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const StepCampoSimples_TipoCampo._(super.value, super.name);
}

class StepCampoSimples_UiHint extends $pb.ProtobufEnum {
  static const StepCampoSimples_UiHint DEFAULT =
      StepCampoSimples_UiHint._(0, _omitEnumNames ? '' : 'DEFAULT');
  static const StepCampoSimples_UiHint LARGE_TILES =
      StepCampoSimples_UiHint._(1, _omitEnumNames ? '' : 'LARGE_TILES');
  static const StepCampoSimples_UiHint CAMERA_ACTION =
      StepCampoSimples_UiHint._(2, _omitEnumNames ? '' : 'CAMERA_ACTION');
  static const StepCampoSimples_UiHint TEXT_AREA =
      StepCampoSimples_UiHint._(3, _omitEnumNames ? '' : 'TEXT_AREA');

  static const $core.List<StepCampoSimples_UiHint> values =
      <StepCampoSimples_UiHint>[
    DEFAULT,
    LARGE_TILES,
    CAMERA_ACTION,
    TEXT_AREA,
  ];

  static final $core.List<StepCampoSimples_UiHint?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static StepCampoSimples_UiHint? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const StepCampoSimples_UiHint._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
