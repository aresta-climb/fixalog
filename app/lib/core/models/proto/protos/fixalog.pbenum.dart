// This is a generated file - do not edit.
//
// Generated from fixalog.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Campo_Tipo extends $pb.ProtobufEnum {
  static const Campo_Tipo TEXT = Campo_Tipo._(0, _omitEnumNames ? '' : 'TEXT');
  static const Campo_Tipo NUMBER =
      Campo_Tipo._(1, _omitEnumNames ? '' : 'NUMBER');
  static const Campo_Tipo DROPDOWN =
      Campo_Tipo._(2, _omitEnumNames ? '' : 'DROPDOWN');
  static const Campo_Tipo IMAGE =
      Campo_Tipo._(3, _omitEnumNames ? '' : 'IMAGE');
  static const Campo_Tipo BOOLEAN =
      Campo_Tipo._(4, _omitEnumNames ? '' : 'BOOLEAN');
  static const Campo_Tipo GPS = Campo_Tipo._(5, _omitEnumNames ? '' : 'GPS');
  static const Campo_Tipo VIDEO =
      Campo_Tipo._(6, _omitEnumNames ? '' : 'VIDEO');
  static const Campo_Tipo SIGNATURE =
      Campo_Tipo._(7, _omitEnumNames ? '' : 'SIGNATURE');

  static const $core.List<Campo_Tipo> values = <Campo_Tipo>[
    TEXT,
    NUMBER,
    DROPDOWN,
    IMAGE,
    BOOLEAN,
    GPS,
    VIDEO,
    SIGNATURE,
  ];

  static final $core.List<Campo_Tipo?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static Campo_Tipo? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Campo_Tipo._(super.value, super.name);
}

class Campo_UIHint extends $pb.ProtobufEnum {
  static const Campo_UIHint DEFAULT =
      Campo_UIHint._(0, _omitEnumNames ? '' : 'DEFAULT');
  static const Campo_UIHint LARGE_TILES =
      Campo_UIHint._(1, _omitEnumNames ? '' : 'LARGE_TILES');
  static const Campo_UIHint CAMERA_ACTION =
      Campo_UIHint._(2, _omitEnumNames ? '' : 'CAMERA_ACTION');

  static const $core.List<Campo_UIHint> values = <Campo_UIHint>[
    DEFAULT,
    LARGE_TILES,
    CAMERA_ACTION,
  ];

  static final $core.List<Campo_UIHint?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Campo_UIHint? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Campo_UIHint._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
