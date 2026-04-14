// This is a generated file - do not edit.
//
// Generated from protos/fixalog.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'fixalog.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'fixalog.pbenum.dart';

class Protocolo extends $pb.GeneratedMessage {
  factory Protocolo({
    $core.String? id,
    $core.String? nome,
    $core.Iterable<Campo>? campos,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (nome != null) result.nome = nome;
    if (campos != null) result.campos.addAll(campos);
    return result;
  }

  Protocolo._();

  factory Protocolo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Protocolo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Protocolo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'nome')
    ..pPM<Campo>(3, _omitFieldNames ? '' : 'campos', subBuilder: Campo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Protocolo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Protocolo copyWith(void Function(Protocolo) updates) =>
      super.copyWith((message) => updates(message as Protocolo)) as Protocolo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Protocolo create() => Protocolo._();
  @$core.override
  Protocolo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Protocolo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Protocolo>(create);
  static Protocolo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get nome => $_getSZ(1);
  @$pb.TagNumber(2)
  set nome($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNome() => $_has(1);
  @$pb.TagNumber(2)
  void clearNome() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Campo> get campos => $_getList(2);
}

class Campo extends $pb.GeneratedMessage {
  factory Campo({
    $core.String? id,
    $core.String? label,
    Campo_Tipo? tipo,
    $core.bool? obrigatorio,
    $core.Iterable<$core.String>? opcoes,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (label != null) result.label = label;
    if (tipo != null) result.tipo = tipo;
    if (obrigatorio != null) result.obrigatorio = obrigatorio;
    if (opcoes != null) result.opcoes.addAll(opcoes);
    return result;
  }

  Campo._();

  factory Campo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Campo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Campo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aE<Campo_Tipo>(3, _omitFieldNames ? '' : 'tipo',
        enumValues: Campo_Tipo.values)
    ..aOB(4, _omitFieldNames ? '' : 'obrigatorio')
    ..pPS(5, _omitFieldNames ? '' : 'opcoes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Campo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Campo copyWith(void Function(Campo) updates) =>
      super.copyWith((message) => updates(message as Campo)) as Campo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Campo create() => Campo._();
  @$core.override
  Campo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Campo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Campo>(create);
  static Campo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  Campo_Tipo get tipo => $_getN(2);
  @$pb.TagNumber(3)
  set tipo(Campo_Tipo value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTipo() => $_has(2);
  @$pb.TagNumber(3)
  void clearTipo() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get obrigatorio => $_getBF(3);
  @$pb.TagNumber(4)
  set obrigatorio($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasObrigatorio() => $_has(3);
  @$pb.TagNumber(4)
  void clearObrigatorio() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get opcoes => $_getList(4);
}

class SubmissaoProtocolo extends $pb.GeneratedMessage {
  factory SubmissaoProtocolo({
    $core.String? idSessao,
    $core.String? idProtocolo,
    $fixnum.Int64? utcTimestampGps,
    $core.List<$core.int>? assinaturaVisual,
    $core.Iterable<RespostaCampo>? respostas,
    $core.List<$core.int>? digitalAssinaturaDoHash,
  }) {
    final result = create();
    if (idSessao != null) result.idSessao = idSessao;
    if (idProtocolo != null) result.idProtocolo = idProtocolo;
    if (utcTimestampGps != null) result.utcTimestampGps = utcTimestampGps;
    if (assinaturaVisual != null) result.assinaturaVisual = assinaturaVisual;
    if (respostas != null) result.respostas.addAll(respostas);
    if (digitalAssinaturaDoHash != null)
      result.digitalAssinaturaDoHash = digitalAssinaturaDoHash;
    return result;
  }

  SubmissaoProtocolo._();

  factory SubmissaoProtocolo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubmissaoProtocolo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubmissaoProtocolo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'idSessao')
    ..aOS(2, _omitFieldNames ? '' : 'idProtocolo')
    ..aInt64(3, _omitFieldNames ? '' : 'utcTimestampGps')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'assinaturaVisual', $pb.PbFieldType.OY)
    ..pPM<RespostaCampo>(5, _omitFieldNames ? '' : 'respostas',
        subBuilder: RespostaCampo.create)
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'digitalAssinaturaDoHash', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmissaoProtocolo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmissaoProtocolo copyWith(void Function(SubmissaoProtocolo) updates) =>
      super.copyWith((message) => updates(message as SubmissaoProtocolo))
          as SubmissaoProtocolo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubmissaoProtocolo create() => SubmissaoProtocolo._();
  @$core.override
  SubmissaoProtocolo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubmissaoProtocolo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmissaoProtocolo>(create);
  static SubmissaoProtocolo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get idSessao => $_getSZ(0);
  @$pb.TagNumber(1)
  set idSessao($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdSessao() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdSessao() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get idProtocolo => $_getSZ(1);
  @$pb.TagNumber(2)
  set idProtocolo($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIdProtocolo() => $_has(1);
  @$pb.TagNumber(2)
  void clearIdProtocolo() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get utcTimestampGps => $_getI64(2);
  @$pb.TagNumber(3)
  set utcTimestampGps($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUtcTimestampGps() => $_has(2);
  @$pb.TagNumber(3)
  void clearUtcTimestampGps() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get assinaturaVisual => $_getN(3);
  @$pb.TagNumber(4)
  set assinaturaVisual($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAssinaturaVisual() => $_has(3);
  @$pb.TagNumber(4)
  void clearAssinaturaVisual() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<RespostaCampo> get respostas => $_getList(4);

  @$pb.TagNumber(6)
  $core.List<$core.int> get digitalAssinaturaDoHash => $_getN(5);
  @$pb.TagNumber(6)
  set digitalAssinaturaDoHash($core.List<$core.int> value) =>
      $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDigitalAssinaturaDoHash() => $_has(5);
  @$pb.TagNumber(6)
  void clearDigitalAssinaturaDoHash() => $_clearField(6);
}

class RespostaCampo extends $pb.GeneratedMessage {
  factory RespostaCampo({
    $core.String? idCampo,
    $core.String? valorTexto,
    $core.List<$core.int>? valorMidia,
  }) {
    final result = create();
    if (idCampo != null) result.idCampo = idCampo;
    if (valorTexto != null) result.valorTexto = valorTexto;
    if (valorMidia != null) result.valorMidia = valorMidia;
    return result;
  }

  RespostaCampo._();

  factory RespostaCampo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RespostaCampo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RespostaCampo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'idCampo')
    ..aOS(2, _omitFieldNames ? '' : 'valorTexto')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'valorMidia', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespostaCampo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespostaCampo copyWith(void Function(RespostaCampo) updates) =>
      super.copyWith((message) => updates(message as RespostaCampo))
          as RespostaCampo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RespostaCampo create() => RespostaCampo._();
  @$core.override
  RespostaCampo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RespostaCampo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RespostaCampo>(create);
  static RespostaCampo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get idCampo => $_getSZ(0);
  @$pb.TagNumber(1)
  set idCampo($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdCampo() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdCampo() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get valorTexto => $_getSZ(1);
  @$pb.TagNumber(2)
  set valorTexto($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValorTexto() => $_has(1);
  @$pb.TagNumber(2)
  void clearValorTexto() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get valorMidia => $_getN(2);
  @$pb.TagNumber(3)
  set valorMidia($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasValorMidia() => $_has(2);
  @$pb.TagNumber(3)
  void clearValorMidia() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
