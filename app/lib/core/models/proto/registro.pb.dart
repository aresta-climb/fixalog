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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'registro.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'registro.pbenum.dart';

class ArquivoImagem extends $pb.GeneratedMessage {
  factory ArquivoImagem({
    $core.String? uuid,
    $core.String? tipoOriginal,
    $core.String? hashOriginal,
    $core.String? tipoComprimido,
    $core.String? hashComprimido,
    $core.int? versaoCompressao,
  }) {
    final result = create();
    if (uuid != null) result.uuid = uuid;
    if (tipoOriginal != null) result.tipoOriginal = tipoOriginal;
    if (hashOriginal != null) result.hashOriginal = hashOriginal;
    if (tipoComprimido != null) result.tipoComprimido = tipoComprimido;
    if (hashComprimido != null) result.hashComprimido = hashComprimido;
    if (versaoCompressao != null) result.versaoCompressao = versaoCompressao;
    return result;
  }

  ArquivoImagem._();

  factory ArquivoImagem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArquivoImagem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArquivoImagem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'uuid')
    ..aOS(2, _omitFieldNames ? '' : 'tipoOriginal')
    ..aOS(3, _omitFieldNames ? '' : 'hashOriginal')
    ..aOS(4, _omitFieldNames ? '' : 'tipoComprimido')
    ..aOS(5, _omitFieldNames ? '' : 'hashComprimido')
    ..aI(6, _omitFieldNames ? '' : 'versaoCompressao')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoImagem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoImagem copyWith(void Function(ArquivoImagem) updates) =>
      super.copyWith((message) => updates(message as ArquivoImagem))
          as ArquivoImagem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArquivoImagem create() => ArquivoImagem._();
  @$core.override
  ArquivoImagem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArquivoImagem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArquivoImagem>(create);
  static ArquivoImagem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uuid => $_getSZ(0);
  @$pb.TagNumber(1)
  set uuid($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUuid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUuid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get tipoOriginal => $_getSZ(1);
  @$pb.TagNumber(2)
  set tipoOriginal($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTipoOriginal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTipoOriginal() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get hashOriginal => $_getSZ(2);
  @$pb.TagNumber(3)
  set hashOriginal($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHashOriginal() => $_has(2);
  @$pb.TagNumber(3)
  void clearHashOriginal() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get tipoComprimido => $_getSZ(3);
  @$pb.TagNumber(4)
  set tipoComprimido($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTipoComprimido() => $_has(3);
  @$pb.TagNumber(4)
  void clearTipoComprimido() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get hashComprimido => $_getSZ(4);
  @$pb.TagNumber(5)
  set hashComprimido($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHashComprimido() => $_has(4);
  @$pb.TagNumber(5)
  void clearHashComprimido() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get versaoCompressao => $_getIZ(5);
  @$pb.TagNumber(6)
  set versaoCompressao($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVersaoCompressao() => $_has(5);
  @$pb.TagNumber(6)
  void clearVersaoCompressao() => $_clearField(6);
}

class ArquivoVideo extends $pb.GeneratedMessage {
  factory ArquivoVideo({
    $core.String? uuid,
    $core.String? tipoOriginal,
    $core.String? hashOriginal,
    $core.String? tipoComprimido,
    $core.String? hashComprimido,
    $core.int? versaoCompressao,
  }) {
    final result = create();
    if (uuid != null) result.uuid = uuid;
    if (tipoOriginal != null) result.tipoOriginal = tipoOriginal;
    if (hashOriginal != null) result.hashOriginal = hashOriginal;
    if (tipoComprimido != null) result.tipoComprimido = tipoComprimido;
    if (hashComprimido != null) result.hashComprimido = hashComprimido;
    if (versaoCompressao != null) result.versaoCompressao = versaoCompressao;
    return result;
  }

  ArquivoVideo._();

  factory ArquivoVideo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArquivoVideo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArquivoVideo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'uuid')
    ..aOS(2, _omitFieldNames ? '' : 'tipoOriginal')
    ..aOS(3, _omitFieldNames ? '' : 'hashOriginal')
    ..aOS(4, _omitFieldNames ? '' : 'tipoComprimido')
    ..aOS(5, _omitFieldNames ? '' : 'hashComprimido')
    ..aI(6, _omitFieldNames ? '' : 'versaoCompressao')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoVideo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoVideo copyWith(void Function(ArquivoVideo) updates) =>
      super.copyWith((message) => updates(message as ArquivoVideo))
          as ArquivoVideo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArquivoVideo create() => ArquivoVideo._();
  @$core.override
  ArquivoVideo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArquivoVideo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArquivoVideo>(create);
  static ArquivoVideo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uuid => $_getSZ(0);
  @$pb.TagNumber(1)
  set uuid($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUuid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUuid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get tipoOriginal => $_getSZ(1);
  @$pb.TagNumber(2)
  set tipoOriginal($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTipoOriginal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTipoOriginal() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get hashOriginal => $_getSZ(2);
  @$pb.TagNumber(3)
  set hashOriginal($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHashOriginal() => $_has(2);
  @$pb.TagNumber(3)
  void clearHashOriginal() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get tipoComprimido => $_getSZ(3);
  @$pb.TagNumber(4)
  set tipoComprimido($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTipoComprimido() => $_has(3);
  @$pb.TagNumber(4)
  void clearTipoComprimido() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get hashComprimido => $_getSZ(4);
  @$pb.TagNumber(5)
  set hashComprimido($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHashComprimido() => $_has(4);
  @$pb.TagNumber(5)
  void clearHashComprimido() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get versaoCompressao => $_getIZ(5);
  @$pb.TagNumber(6)
  set versaoCompressao($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVersaoCompressao() => $_has(5);
  @$pb.TagNumber(6)
  void clearVersaoCompressao() => $_clearField(6);
}

class ArquivoAudio extends $pb.GeneratedMessage {
  factory ArquivoAudio({
    $core.String? uuid,
    $core.String? tipoOriginal,
    $core.String? hashOriginal,
    $core.String? tipoComprimido,
    $core.String? hashComprimido,
    $core.int? versaoCompressao,
  }) {
    final result = create();
    if (uuid != null) result.uuid = uuid;
    if (tipoOriginal != null) result.tipoOriginal = tipoOriginal;
    if (hashOriginal != null) result.hashOriginal = hashOriginal;
    if (tipoComprimido != null) result.tipoComprimido = tipoComprimido;
    if (hashComprimido != null) result.hashComprimido = hashComprimido;
    if (versaoCompressao != null) result.versaoCompressao = versaoCompressao;
    return result;
  }

  ArquivoAudio._();

  factory ArquivoAudio.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArquivoAudio.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArquivoAudio',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'uuid')
    ..aOS(2, _omitFieldNames ? '' : 'tipoOriginal')
    ..aOS(3, _omitFieldNames ? '' : 'hashOriginal')
    ..aOS(4, _omitFieldNames ? '' : 'tipoComprimido')
    ..aOS(5, _omitFieldNames ? '' : 'hashComprimido')
    ..aI(6, _omitFieldNames ? '' : 'versaoCompressao')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoAudio clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoAudio copyWith(void Function(ArquivoAudio) updates) =>
      super.copyWith((message) => updates(message as ArquivoAudio))
          as ArquivoAudio;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArquivoAudio create() => ArquivoAudio._();
  @$core.override
  ArquivoAudio createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArquivoAudio getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArquivoAudio>(create);
  static ArquivoAudio? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uuid => $_getSZ(0);
  @$pb.TagNumber(1)
  set uuid($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUuid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUuid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get tipoOriginal => $_getSZ(1);
  @$pb.TagNumber(2)
  set tipoOriginal($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTipoOriginal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTipoOriginal() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get hashOriginal => $_getSZ(2);
  @$pb.TagNumber(3)
  set hashOriginal($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHashOriginal() => $_has(2);
  @$pb.TagNumber(3)
  void clearHashOriginal() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get tipoComprimido => $_getSZ(3);
  @$pb.TagNumber(4)
  set tipoComprimido($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTipoComprimido() => $_has(3);
  @$pb.TagNumber(4)
  void clearTipoComprimido() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get hashComprimido => $_getSZ(4);
  @$pb.TagNumber(5)
  set hashComprimido($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHashComprimido() => $_has(4);
  @$pb.TagNumber(5)
  void clearHashComprimido() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get versaoCompressao => $_getIZ(5);
  @$pb.TagNumber(6)
  set versaoCompressao($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVersaoCompressao() => $_has(5);
  @$pb.TagNumber(6)
  void clearVersaoCompressao() => $_clearField(6);
}

enum ReferenciaMidia_Midia { imagem, video, audio, notSet }

class ReferenciaMidia extends $pb.GeneratedMessage {
  factory ReferenciaMidia({
    ArquivoImagem? imagem,
    ArquivoVideo? video,
    ArquivoAudio? audio,
  }) {
    final result = create();
    if (imagem != null) result.imagem = imagem;
    if (video != null) result.video = video;
    if (audio != null) result.audio = audio;
    return result;
  }

  ReferenciaMidia._();

  factory ReferenciaMidia.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReferenciaMidia.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ReferenciaMidia_Midia>
      _ReferenciaMidia_MidiaByTag = {
    1: ReferenciaMidia_Midia.imagem,
    2: ReferenciaMidia_Midia.video,
    3: ReferenciaMidia_Midia.audio,
    0: ReferenciaMidia_Midia.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReferenciaMidia',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<ArquivoImagem>(1, _omitFieldNames ? '' : 'imagem',
        subBuilder: ArquivoImagem.create)
    ..aOM<ArquivoVideo>(2, _omitFieldNames ? '' : 'video',
        subBuilder: ArquivoVideo.create)
    ..aOM<ArquivoAudio>(3, _omitFieldNames ? '' : 'audio',
        subBuilder: ArquivoAudio.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferenciaMidia clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferenciaMidia copyWith(void Function(ReferenciaMidia) updates) =>
      super.copyWith((message) => updates(message as ReferenciaMidia))
          as ReferenciaMidia;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReferenciaMidia create() => ReferenciaMidia._();
  @$core.override
  ReferenciaMidia createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReferenciaMidia getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReferenciaMidia>(create);
  static ReferenciaMidia? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  ReferenciaMidia_Midia whichMidia() =>
      _ReferenciaMidia_MidiaByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearMidia() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ArquivoImagem get imagem => $_getN(0);
  @$pb.TagNumber(1)
  set imagem(ArquivoImagem value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasImagem() => $_has(0);
  @$pb.TagNumber(1)
  void clearImagem() => $_clearField(1);
  @$pb.TagNumber(1)
  ArquivoImagem ensureImagem() => $_ensure(0);

  @$pb.TagNumber(2)
  ArquivoVideo get video => $_getN(1);
  @$pb.TagNumber(2)
  set video(ArquivoVideo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasVideo() => $_has(1);
  @$pb.TagNumber(2)
  void clearVideo() => $_clearField(2);
  @$pb.TagNumber(2)
  ArquivoVideo ensureVideo() => $_ensure(1);

  @$pb.TagNumber(3)
  ArquivoAudio get audio => $_getN(2);
  @$pb.TagNumber(3)
  set audio(ArquivoAudio value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAudio() => $_has(2);
  @$pb.TagNumber(3)
  void clearAudio() => $_clearField(3);
  @$pb.TagNumber(3)
  ArquivoAudio ensureAudio() => $_ensure(2);
}

class RegistroManutencao extends $pb.GeneratedMessage {
  factory RegistroManutencao({
    $core.String? idSessao,
    $core.String? idProtocolo,
    $core.String? versaoProtocolo,
    $fixnum.Int64? utcTimestampInicio,
    $fixnum.Int64? utcTimestampFim,
    RegistroMateriais? materiais,
    RegistroVia? via,
    $core.Iterable<AcaoManutencao>? acoes,
    AvaliacaoFinal? avaliacao,
    $core.List<$core.int>? assinaturaVisual,
    $core.List<$core.int>? assinaturaDigital,
    $core.String? idMantenedor,
    $core.String? attestationToken,
  }) {
    final result = create();
    if (idSessao != null) result.idSessao = idSessao;
    if (idProtocolo != null) result.idProtocolo = idProtocolo;
    if (versaoProtocolo != null) result.versaoProtocolo = versaoProtocolo;
    if (utcTimestampInicio != null)
      result.utcTimestampInicio = utcTimestampInicio;
    if (utcTimestampFim != null) result.utcTimestampFim = utcTimestampFim;
    if (materiais != null) result.materiais = materiais;
    if (via != null) result.via = via;
    if (acoes != null) result.acoes.addAll(acoes);
    if (avaliacao != null) result.avaliacao = avaliacao;
    if (assinaturaVisual != null) result.assinaturaVisual = assinaturaVisual;
    if (assinaturaDigital != null) result.assinaturaDigital = assinaturaDigital;
    if (idMantenedor != null) result.idMantenedor = idMantenedor;
    if (attestationToken != null) result.attestationToken = attestationToken;
    return result;
  }

  RegistroManutencao._();

  factory RegistroManutencao.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegistroManutencao.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegistroManutencao',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'idSessao')
    ..aOS(2, _omitFieldNames ? '' : 'idProtocolo')
    ..aOS(3, _omitFieldNames ? '' : 'versaoProtocolo')
    ..aInt64(4, _omitFieldNames ? '' : 'utcTimestampInicio')
    ..aInt64(5, _omitFieldNames ? '' : 'utcTimestampFim')
    ..aOM<RegistroMateriais>(6, _omitFieldNames ? '' : 'materiais',
        subBuilder: RegistroMateriais.create)
    ..aOM<RegistroVia>(7, _omitFieldNames ? '' : 'via',
        subBuilder: RegistroVia.create)
    ..pPM<AcaoManutencao>(8, _omitFieldNames ? '' : 'acoes',
        subBuilder: AcaoManutencao.create)
    ..aOM<AvaliacaoFinal>(9, _omitFieldNames ? '' : 'avaliacao',
        subBuilder: AvaliacaoFinal.create)
    ..a<$core.List<$core.int>>(
        10, _omitFieldNames ? '' : 'assinaturaVisual', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        11, _omitFieldNames ? '' : 'assinaturaDigital', $pb.PbFieldType.OY)
    ..aOS(12, _omitFieldNames ? '' : 'idMantenedor')
    ..aOS(99, _omitFieldNames ? '' : 'attestationToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegistroManutencao clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegistroManutencao copyWith(void Function(RegistroManutencao) updates) =>
      super.copyWith((message) => updates(message as RegistroManutencao))
          as RegistroManutencao;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegistroManutencao create() => RegistroManutencao._();
  @$core.override
  RegistroManutencao createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegistroManutencao getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegistroManutencao>(create);
  static RegistroManutencao? _defaultInstance;

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
  $core.String get versaoProtocolo => $_getSZ(2);
  @$pb.TagNumber(3)
  set versaoProtocolo($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersaoProtocolo() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersaoProtocolo() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get utcTimestampInicio => $_getI64(3);
  @$pb.TagNumber(4)
  set utcTimestampInicio($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUtcTimestampInicio() => $_has(3);
  @$pb.TagNumber(4)
  void clearUtcTimestampInicio() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get utcTimestampFim => $_getI64(4);
  @$pb.TagNumber(5)
  set utcTimestampFim($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUtcTimestampFim() => $_has(4);
  @$pb.TagNumber(5)
  void clearUtcTimestampFim() => $_clearField(5);

  @$pb.TagNumber(6)
  RegistroMateriais get materiais => $_getN(5);
  @$pb.TagNumber(6)
  set materiais(RegistroMateriais value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasMateriais() => $_has(5);
  @$pb.TagNumber(6)
  void clearMateriais() => $_clearField(6);
  @$pb.TagNumber(6)
  RegistroMateriais ensureMateriais() => $_ensure(5);

  @$pb.TagNumber(7)
  RegistroVia get via => $_getN(6);
  @$pb.TagNumber(7)
  set via(RegistroVia value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasVia() => $_has(6);
  @$pb.TagNumber(7)
  void clearVia() => $_clearField(7);
  @$pb.TagNumber(7)
  RegistroVia ensureVia() => $_ensure(6);

  @$pb.TagNumber(8)
  $pb.PbList<AcaoManutencao> get acoes => $_getList(7);

  @$pb.TagNumber(9)
  AvaliacaoFinal get avaliacao => $_getN(8);
  @$pb.TagNumber(9)
  set avaliacao(AvaliacaoFinal value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasAvaliacao() => $_has(8);
  @$pb.TagNumber(9)
  void clearAvaliacao() => $_clearField(9);
  @$pb.TagNumber(9)
  AvaliacaoFinal ensureAvaliacao() => $_ensure(8);

  @$pb.TagNumber(10)
  $core.List<$core.int> get assinaturaVisual => $_getN(9);
  @$pb.TagNumber(10)
  set assinaturaVisual($core.List<$core.int> value) => $_setBytes(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAssinaturaVisual() => $_has(9);
  @$pb.TagNumber(10)
  void clearAssinaturaVisual() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.List<$core.int> get assinaturaDigital => $_getN(10);
  @$pb.TagNumber(11)
  set assinaturaDigital($core.List<$core.int> value) => $_setBytes(10, value);
  @$pb.TagNumber(11)
  $core.bool hasAssinaturaDigital() => $_has(10);
  @$pb.TagNumber(11)
  void clearAssinaturaDigital() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get idMantenedor => $_getSZ(11);
  @$pb.TagNumber(12)
  set idMantenedor($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasIdMantenedor() => $_has(11);
  @$pb.TagNumber(12)
  void clearIdMantenedor() => $_clearField(12);

  @$pb.TagNumber(99)
  $core.String get attestationToken => $_getSZ(12);
  @$pb.TagNumber(99)
  set attestationToken($core.String value) => $_setString(12, value);
  @$pb.TagNumber(99)
  $core.bool hasAttestationToken() => $_has(12);
  @$pb.TagNumber(99)
  void clearAttestationToken() => $_clearField(99);
}

class RegistroMateriais extends $pb.GeneratedMessage {
  factory RegistroMateriais({
    $core.Iterable<MaterialInstalado>? itens,
  }) {
    final result = create();
    if (itens != null) result.itens.addAll(itens);
    return result;
  }

  RegistroMateriais._();

  factory RegistroMateriais.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegistroMateriais.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegistroMateriais',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..pPM<MaterialInstalado>(1, _omitFieldNames ? '' : 'itens',
        subBuilder: MaterialInstalado.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegistroMateriais clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegistroMateriais copyWith(void Function(RegistroMateriais) updates) =>
      super.copyWith((message) => updates(message as RegistroMateriais))
          as RegistroMateriais;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegistroMateriais create() => RegistroMateriais._();
  @$core.override
  RegistroMateriais createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegistroMateriais getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegistroMateriais>(create);
  static RegistroMateriais? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<MaterialInstalado> get itens => $_getList(0);
}

/// Representa uma entrada de material registrada no wizard.
/// O id_instancia é gerado automaticamente pelo wizard ao adicionar o item
/// e é usado para referência em AcaoManutencao.ids_materiais_usados.
class MaterialInstalado extends $pb.GeneratedMessage {
  factory MaterialInstalado({
    $core.String? idInstancia,
    $core.String? tipo,
    $core.String? marca,
    $core.String? lote,
    $core.String? liga,
    $core.String? validade,
    $core.int? quantidade,
    ReferenciaMidia? foto,
  }) {
    final result = create();
    if (idInstancia != null) result.idInstancia = idInstancia;
    if (tipo != null) result.tipo = tipo;
    if (marca != null) result.marca = marca;
    if (lote != null) result.lote = lote;
    if (liga != null) result.liga = liga;
    if (validade != null) result.validade = validade;
    if (quantidade != null) result.quantidade = quantidade;
    if (foto != null) result.foto = foto;
    return result;
  }

  MaterialInstalado._();

  factory MaterialInstalado.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MaterialInstalado.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MaterialInstalado',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'idInstancia')
    ..aOS(2, _omitFieldNames ? '' : 'tipo')
    ..aOS(3, _omitFieldNames ? '' : 'marca')
    ..aOS(4, _omitFieldNames ? '' : 'lote')
    ..aOS(5, _omitFieldNames ? '' : 'liga')
    ..aOS(6, _omitFieldNames ? '' : 'validade')
    ..aI(7, _omitFieldNames ? '' : 'quantidade')
    ..aOM<ReferenciaMidia>(8, _omitFieldNames ? '' : 'foto',
        subBuilder: ReferenciaMidia.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MaterialInstalado clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MaterialInstalado copyWith(void Function(MaterialInstalado) updates) =>
      super.copyWith((message) => updates(message as MaterialInstalado))
          as MaterialInstalado;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MaterialInstalado create() => MaterialInstalado._();
  @$core.override
  MaterialInstalado createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MaterialInstalado getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MaterialInstalado>(create);
  static MaterialInstalado? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get idInstancia => $_getSZ(0);
  @$pb.TagNumber(1)
  set idInstancia($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdInstancia() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdInstancia() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get tipo => $_getSZ(1);
  @$pb.TagNumber(2)
  set tipo($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTipo() => $_has(1);
  @$pb.TagNumber(2)
  void clearTipo() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get marca => $_getSZ(2);
  @$pb.TagNumber(3)
  set marca($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMarca() => $_has(2);
  @$pb.TagNumber(3)
  void clearMarca() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get lote => $_getSZ(3);
  @$pb.TagNumber(4)
  set lote($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLote() => $_has(3);
  @$pb.TagNumber(4)
  void clearLote() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get liga => $_getSZ(4);
  @$pb.TagNumber(5)
  set liga($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLiga() => $_has(4);
  @$pb.TagNumber(5)
  void clearLiga() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get validade => $_getSZ(5);
  @$pb.TagNumber(6)
  set validade($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasValidade() => $_has(5);
  @$pb.TagNumber(6)
  void clearValidade() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get quantidade => $_getIZ(6);
  @$pb.TagNumber(7)
  set quantidade($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasQuantidade() => $_has(6);
  @$pb.TagNumber(7)
  void clearQuantidade() => $_clearField(7);

  @$pb.TagNumber(8)
  ReferenciaMidia get foto => $_getN(7);
  @$pb.TagNumber(8)
  set foto(ReferenciaMidia value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasFoto() => $_has(7);
  @$pb.TagNumber(8)
  void clearFoto() => $_clearField(8);
  @$pb.TagNumber(8)
  ReferenciaMidia ensureFoto() => $_ensure(7);
}

class RegistroVia extends $pb.GeneratedMessage {
  factory RegistroVia({
    $core.String? nomeVia,
    $core.String? pico,
    $core.String? setor,
    $core.double? latitude,
    $core.double? longitude,
    $core.double? altitudeM,
    ReferenciaMidia? permissaoConquistador,
    $core.String? nomeConquistador,
  }) {
    final result = create();
    if (nomeVia != null) result.nomeVia = nomeVia;
    if (pico != null) result.pico = pico;
    if (setor != null) result.setor = setor;
    if (latitude != null) result.latitude = latitude;
    if (longitude != null) result.longitude = longitude;
    if (altitudeM != null) result.altitudeM = altitudeM;
    if (permissaoConquistador != null)
      result.permissaoConquistador = permissaoConquistador;
    if (nomeConquistador != null) result.nomeConquistador = nomeConquistador;
    return result;
  }

  RegistroVia._();

  factory RegistroVia.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegistroVia.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegistroVia',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nomeVia')
    ..aOS(2, _omitFieldNames ? '' : 'pico')
    ..aOS(3, _omitFieldNames ? '' : 'setor')
    ..aD(4, _omitFieldNames ? '' : 'latitude')
    ..aD(5, _omitFieldNames ? '' : 'longitude')
    ..aD(6, _omitFieldNames ? '' : 'altitudeM')
    ..aOM<ReferenciaMidia>(7, _omitFieldNames ? '' : 'permissaoConquistador',
        subBuilder: ReferenciaMidia.create)
    ..aOS(8, _omitFieldNames ? '' : 'nomeConquistador')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegistroVia clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegistroVia copyWith(void Function(RegistroVia) updates) =>
      super.copyWith((message) => updates(message as RegistroVia))
          as RegistroVia;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegistroVia create() => RegistroVia._();
  @$core.override
  RegistroVia createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegistroVia getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegistroVia>(create);
  static RegistroVia? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nomeVia => $_getSZ(0);
  @$pb.TagNumber(1)
  set nomeVia($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNomeVia() => $_has(0);
  @$pb.TagNumber(1)
  void clearNomeVia() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get pico => $_getSZ(1);
  @$pb.TagNumber(2)
  set pico($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPico() => $_has(1);
  @$pb.TagNumber(2)
  void clearPico() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get setor => $_getSZ(2);
  @$pb.TagNumber(3)
  set setor($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSetor() => $_has(2);
  @$pb.TagNumber(3)
  void clearSetor() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get latitude => $_getN(3);
  @$pb.TagNumber(4)
  set latitude($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLatitude() => $_has(3);
  @$pb.TagNumber(4)
  void clearLatitude() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get longitude => $_getN(4);
  @$pb.TagNumber(5)
  set longitude($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLongitude() => $_has(4);
  @$pb.TagNumber(5)
  void clearLongitude() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get altitudeM => $_getN(5);
  @$pb.TagNumber(6)
  set altitudeM($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAltitudeM() => $_has(5);
  @$pb.TagNumber(6)
  void clearAltitudeM() => $_clearField(6);

  @$pb.TagNumber(7)
  ReferenciaMidia get permissaoConquistador => $_getN(6);
  @$pb.TagNumber(7)
  set permissaoConquistador(ReferenciaMidia value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPermissaoConquistador() => $_has(6);
  @$pb.TagNumber(7)
  void clearPermissaoConquistador() => $_clearField(7);
  @$pb.TagNumber(7)
  ReferenciaMidia ensurePermissaoConquistador() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.String get nomeConquistador => $_getSZ(7);
  @$pb.TagNumber(8)
  set nomeConquistador($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasNomeConquistador() => $_has(7);
  @$pb.TagNumber(8)
  void clearNomeConquistador() => $_clearField(8);
}

enum AcaoManutencao_Detalhes {
  inspecao,
  novoPonto,
  remocaoBloco,
  limpeza,
  outro,
  notSet
}

/// Cada instância de ação adicionada pelo mantenedor no wizard
class AcaoManutencao extends $pb.GeneratedMessage {
  factory AcaoManutencao({
    $core.String? idInstancia,
    $core.String? idTipoAcao,
    $fixnum.Int64? utcTimestamp,
    DetalheInspecao? inspecao,
    DetalheNovoPonto? novoPonto,
    DetalheRemocaoBloco? remocaoBloco,
    DetalheLimpeza? limpeza,
    DetalheAcaoCustomizada? outro,
  }) {
    final result = create();
    if (idInstancia != null) result.idInstancia = idInstancia;
    if (idTipoAcao != null) result.idTipoAcao = idTipoAcao;
    if (utcTimestamp != null) result.utcTimestamp = utcTimestamp;
    if (inspecao != null) result.inspecao = inspecao;
    if (novoPonto != null) result.novoPonto = novoPonto;
    if (remocaoBloco != null) result.remocaoBloco = remocaoBloco;
    if (limpeza != null) result.limpeza = limpeza;
    if (outro != null) result.outro = outro;
    return result;
  }

  AcaoManutencao._();

  factory AcaoManutencao.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcaoManutencao.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, AcaoManutencao_Detalhes>
      _AcaoManutencao_DetalhesByTag = {
    10: AcaoManutencao_Detalhes.inspecao,
    11: AcaoManutencao_Detalhes.novoPonto,
    12: AcaoManutencao_Detalhes.remocaoBloco,
    13: AcaoManutencao_Detalhes.limpeza,
    14: AcaoManutencao_Detalhes.outro,
    0: AcaoManutencao_Detalhes.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcaoManutencao',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 13, 14])
    ..aOS(1, _omitFieldNames ? '' : 'idInstancia')
    ..aOS(2, _omitFieldNames ? '' : 'idTipoAcao')
    ..aInt64(3, _omitFieldNames ? '' : 'utcTimestamp')
    ..aOM<DetalheInspecao>(10, _omitFieldNames ? '' : 'inspecao',
        subBuilder: DetalheInspecao.create)
    ..aOM<DetalheNovoPonto>(11, _omitFieldNames ? '' : 'novoPonto',
        subBuilder: DetalheNovoPonto.create)
    ..aOM<DetalheRemocaoBloco>(12, _omitFieldNames ? '' : 'remocaoBloco',
        subBuilder: DetalheRemocaoBloco.create)
    ..aOM<DetalheLimpeza>(13, _omitFieldNames ? '' : 'limpeza',
        subBuilder: DetalheLimpeza.create)
    ..aOM<DetalheAcaoCustomizada>(14, _omitFieldNames ? '' : 'outro',
        subBuilder: DetalheAcaoCustomizada.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcaoManutencao clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcaoManutencao copyWith(void Function(AcaoManutencao) updates) =>
      super.copyWith((message) => updates(message as AcaoManutencao))
          as AcaoManutencao;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcaoManutencao create() => AcaoManutencao._();
  @$core.override
  AcaoManutencao createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcaoManutencao getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcaoManutencao>(create);
  static AcaoManutencao? _defaultInstance;

  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  AcaoManutencao_Detalhes whichDetalhes() =>
      _AcaoManutencao_DetalhesByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  void clearDetalhes() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get idInstancia => $_getSZ(0);
  @$pb.TagNumber(1)
  set idInstancia($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdInstancia() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdInstancia() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get idTipoAcao => $_getSZ(1);
  @$pb.TagNumber(2)
  set idTipoAcao($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIdTipoAcao() => $_has(1);
  @$pb.TagNumber(2)
  void clearIdTipoAcao() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get utcTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set utcTimestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUtcTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearUtcTimestamp() => $_clearField(3);

  @$pb.TagNumber(10)
  DetalheInspecao get inspecao => $_getN(3);
  @$pb.TagNumber(10)
  set inspecao(DetalheInspecao value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasInspecao() => $_has(3);
  @$pb.TagNumber(10)
  void clearInspecao() => $_clearField(10);
  @$pb.TagNumber(10)
  DetalheInspecao ensureInspecao() => $_ensure(3);

  @$pb.TagNumber(11)
  DetalheNovoPonto get novoPonto => $_getN(4);
  @$pb.TagNumber(11)
  set novoPonto(DetalheNovoPonto value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasNovoPonto() => $_has(4);
  @$pb.TagNumber(11)
  void clearNovoPonto() => $_clearField(11);
  @$pb.TagNumber(11)
  DetalheNovoPonto ensureNovoPonto() => $_ensure(4);

  @$pb.TagNumber(12)
  DetalheRemocaoBloco get remocaoBloco => $_getN(5);
  @$pb.TagNumber(12)
  set remocaoBloco(DetalheRemocaoBloco value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasRemocaoBloco() => $_has(5);
  @$pb.TagNumber(12)
  void clearRemocaoBloco() => $_clearField(12);
  @$pb.TagNumber(12)
  DetalheRemocaoBloco ensureRemocaoBloco() => $_ensure(5);

  @$pb.TagNumber(13)
  DetalheLimpeza get limpeza => $_getN(6);
  @$pb.TagNumber(13)
  set limpeza(DetalheLimpeza value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasLimpeza() => $_has(6);
  @$pb.TagNumber(13)
  void clearLimpeza() => $_clearField(13);
  @$pb.TagNumber(13)
  DetalheLimpeza ensureLimpeza() => $_ensure(6);

  @$pb.TagNumber(14)
  DetalheAcaoCustomizada get outro => $_getN(7);
  @$pb.TagNumber(14)
  set outro(DetalheAcaoCustomizada value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasOutro() => $_has(7);
  @$pb.TagNumber(14)
  void clearOutro() => $_clearField(14);
  @$pb.TagNumber(14)
  DetalheAcaoCustomizada ensureOutro() => $_ensure(7);
}

class DetalheInspecao extends $pb.GeneratedMessage {
  factory DetalheInspecao({
    $core.String? tipoAncoragemOriginal,
    $core.String? materialOriginal,
    ReferenciaMidia? fotoAntes,
    ReferenciaMidia? videoAntes,
    DetalheInspecao_ResultadoInspecao? resultado,
    DetalheSubstituicao? substituicao,
  }) {
    final result = create();
    if (tipoAncoragemOriginal != null)
      result.tipoAncoragemOriginal = tipoAncoragemOriginal;
    if (materialOriginal != null) result.materialOriginal = materialOriginal;
    if (fotoAntes != null) result.fotoAntes = fotoAntes;
    if (videoAntes != null) result.videoAntes = videoAntes;
    if (resultado != null) result.resultado = resultado;
    if (substituicao != null) result.substituicao = substituicao;
    return result;
  }

  DetalheInspecao._();

  factory DetalheInspecao.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DetalheInspecao.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DetalheInspecao',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tipoAncoragemOriginal')
    ..aOS(2, _omitFieldNames ? '' : 'materialOriginal')
    ..aOM<ReferenciaMidia>(3, _omitFieldNames ? '' : 'fotoAntes',
        subBuilder: ReferenciaMidia.create)
    ..aOM<ReferenciaMidia>(4, _omitFieldNames ? '' : 'videoAntes',
        subBuilder: ReferenciaMidia.create)
    ..aE<DetalheInspecao_ResultadoInspecao>(
        5, _omitFieldNames ? '' : 'resultado',
        enumValues: DetalheInspecao_ResultadoInspecao.values)
    ..aOM<DetalheSubstituicao>(6, _omitFieldNames ? '' : 'substituicao',
        subBuilder: DetalheSubstituicao.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetalheInspecao clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetalheInspecao copyWith(void Function(DetalheInspecao) updates) =>
      super.copyWith((message) => updates(message as DetalheInspecao))
          as DetalheInspecao;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DetalheInspecao create() => DetalheInspecao._();
  @$core.override
  DetalheInspecao createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DetalheInspecao getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DetalheInspecao>(create);
  static DetalheInspecao? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get tipoAncoragemOriginal => $_getSZ(0);
  @$pb.TagNumber(1)
  set tipoAncoragemOriginal($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTipoAncoragemOriginal() => $_has(0);
  @$pb.TagNumber(1)
  void clearTipoAncoragemOriginal() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get materialOriginal => $_getSZ(1);
  @$pb.TagNumber(2)
  set materialOriginal($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaterialOriginal() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaterialOriginal() => $_clearField(2);

  @$pb.TagNumber(3)
  ReferenciaMidia get fotoAntes => $_getN(2);
  @$pb.TagNumber(3)
  set fotoAntes(ReferenciaMidia value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFotoAntes() => $_has(2);
  @$pb.TagNumber(3)
  void clearFotoAntes() => $_clearField(3);
  @$pb.TagNumber(3)
  ReferenciaMidia ensureFotoAntes() => $_ensure(2);

  @$pb.TagNumber(4)
  ReferenciaMidia get videoAntes => $_getN(3);
  @$pb.TagNumber(4)
  set videoAntes(ReferenciaMidia value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasVideoAntes() => $_has(3);
  @$pb.TagNumber(4)
  void clearVideoAntes() => $_clearField(4);
  @$pb.TagNumber(4)
  ReferenciaMidia ensureVideoAntes() => $_ensure(3);

  @$pb.TagNumber(5)
  DetalheInspecao_ResultadoInspecao get resultado => $_getN(4);
  @$pb.TagNumber(5)
  set resultado(DetalheInspecao_ResultadoInspecao value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasResultado() => $_has(4);
  @$pb.TagNumber(5)
  void clearResultado() => $_clearField(5);

  /// Preenchido apenas quando resultado == SUBSTITUIR
  @$pb.TagNumber(6)
  DetalheSubstituicao get substituicao => $_getN(5);
  @$pb.TagNumber(6)
  set substituicao(DetalheSubstituicao value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSubstituicao() => $_has(5);
  @$pb.TagNumber(6)
  void clearSubstituicao() => $_clearField(6);
  @$pb.TagNumber(6)
  DetalheSubstituicao ensureSubstituicao() => $_ensure(5);
}

class DetalheSubstituicao extends $pb.GeneratedMessage {
  factory DetalheSubstituicao({
    $core.String? estrategia,
    ReferenciaMidia? fotoDurante,
    ReferenciaMidia? fotoDepois,
    $core.Iterable<$core.String>? idsMateriaisUsados,
    $core.double? torqueNm,
    $core.bool? autorizacaoConfirmada,
    $core.String? justificativaNovoLocal,
    $core.String? observacoes,
  }) {
    final result = create();
    if (estrategia != null) result.estrategia = estrategia;
    if (fotoDurante != null) result.fotoDurante = fotoDurante;
    if (fotoDepois != null) result.fotoDepois = fotoDepois;
    if (idsMateriaisUsados != null)
      result.idsMateriaisUsados.addAll(idsMateriaisUsados);
    if (torqueNm != null) result.torqueNm = torqueNm;
    if (autorizacaoConfirmada != null)
      result.autorizacaoConfirmada = autorizacaoConfirmada;
    if (justificativaNovoLocal != null)
      result.justificativaNovoLocal = justificativaNovoLocal;
    if (observacoes != null) result.observacoes = observacoes;
    return result;
  }

  DetalheSubstituicao._();

  factory DetalheSubstituicao.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DetalheSubstituicao.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DetalheSubstituicao',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'estrategia')
    ..aOM<ReferenciaMidia>(2, _omitFieldNames ? '' : 'fotoDurante',
        subBuilder: ReferenciaMidia.create)
    ..aOM<ReferenciaMidia>(3, _omitFieldNames ? '' : 'fotoDepois',
        subBuilder: ReferenciaMidia.create)
    ..pPS(4, _omitFieldNames ? '' : 'idsMateriaisUsados')
    ..aD(5, _omitFieldNames ? '' : 'torqueNm', fieldType: $pb.PbFieldType.OF)
    ..aOB(6, _omitFieldNames ? '' : 'autorizacaoConfirmada')
    ..aOS(7, _omitFieldNames ? '' : 'justificativaNovoLocal')
    ..aOS(8, _omitFieldNames ? '' : 'observacoes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetalheSubstituicao clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetalheSubstituicao copyWith(void Function(DetalheSubstituicao) updates) =>
      super.copyWith((message) => updates(message as DetalheSubstituicao))
          as DetalheSubstituicao;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DetalheSubstituicao create() => DetalheSubstituicao._();
  @$core.override
  DetalheSubstituicao createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DetalheSubstituicao getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DetalheSubstituicao>(create);
  static DetalheSubstituicao? _defaultInstance;

  /// Qual estratégia foi usada: ramo escolhido pelo mantenedor
  /// Valores: "reusar_furo", "novo_local", "local_alternativo"
  @$pb.TagNumber(1)
  $core.String get estrategia => $_getSZ(0);
  @$pb.TagNumber(1)
  set estrategia($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEstrategia() => $_has(0);
  @$pb.TagNumber(1)
  void clearEstrategia() => $_clearField(1);

  @$pb.TagNumber(2)
  ReferenciaMidia get fotoDurante => $_getN(1);
  @$pb.TagNumber(2)
  set fotoDurante(ReferenciaMidia value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFotoDurante() => $_has(1);
  @$pb.TagNumber(2)
  void clearFotoDurante() => $_clearField(2);
  @$pb.TagNumber(2)
  ReferenciaMidia ensureFotoDurante() => $_ensure(1);

  @$pb.TagNumber(3)
  ReferenciaMidia get fotoDepois => $_getN(2);
  @$pb.TagNumber(3)
  set fotoDepois(ReferenciaMidia value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFotoDepois() => $_has(2);
  @$pb.TagNumber(3)
  void clearFotoDepois() => $_clearField(3);
  @$pb.TagNumber(3)
  ReferenciaMidia ensureFotoDepois() => $_ensure(2);

  /// Lista de id_instancia de MaterialInstalado usados nesta substituição.
  /// Gerados pelo wizard no Bloco 1 e selecionados via StepRefMateriais.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get idsMateriaisUsados => $_getList(3);

  /// Dados extras para substituição com reaperto (ramo reaperto_realizado)
  @$pb.TagNumber(5)
  $core.double get torqueNm => $_getN(4);
  @$pb.TagNumber(5)
  set torqueNm($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTorqueNm() => $_has(4);
  @$pb.TagNumber(5)
  void clearTorqueNm() => $_clearField(5);

  /// Dados extras para novo local
  @$pb.TagNumber(6)
  $core.bool get autorizacaoConfirmada => $_getBF(5);
  @$pb.TagNumber(6)
  set autorizacaoConfirmada($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAutorizacaoConfirmada() => $_has(5);
  @$pb.TagNumber(6)
  void clearAutorizacaoConfirmada() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get justificativaNovoLocal => $_getSZ(6);
  @$pb.TagNumber(7)
  set justificativaNovoLocal($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasJustificativaNovoLocal() => $_has(6);
  @$pb.TagNumber(7)
  void clearJustificativaNovoLocal() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get observacoes => $_getSZ(7);
  @$pb.TagNumber(8)
  set observacoes($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasObservacoes() => $_has(7);
  @$pb.TagNumber(8)
  void clearObservacoes() => $_clearField(8);
}

class DetalheNovoPonto extends $pb.GeneratedMessage {
  factory DetalheNovoPonto({
    $core.bool? autorizacaoConfirmada,
    $core.double? latitude,
    $core.double? longitude,
    ReferenciaMidia? fotoLocalEscolhido,
    ReferenciaMidia? fotoInstalado,
    $core.Iterable<$core.String>? idsMateriaisUsados,
    $core.String? observacoes,
  }) {
    final result = create();
    if (autorizacaoConfirmada != null)
      result.autorizacaoConfirmada = autorizacaoConfirmada;
    if (latitude != null) result.latitude = latitude;
    if (longitude != null) result.longitude = longitude;
    if (fotoLocalEscolhido != null)
      result.fotoLocalEscolhido = fotoLocalEscolhido;
    if (fotoInstalado != null) result.fotoInstalado = fotoInstalado;
    if (idsMateriaisUsados != null)
      result.idsMateriaisUsados.addAll(idsMateriaisUsados);
    if (observacoes != null) result.observacoes = observacoes;
    return result;
  }

  DetalheNovoPonto._();

  factory DetalheNovoPonto.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DetalheNovoPonto.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DetalheNovoPonto',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'autorizacaoConfirmada')
    ..aD(2, _omitFieldNames ? '' : 'latitude')
    ..aD(3, _omitFieldNames ? '' : 'longitude')
    ..aOM<ReferenciaMidia>(4, _omitFieldNames ? '' : 'fotoLocalEscolhido',
        subBuilder: ReferenciaMidia.create)
    ..aOM<ReferenciaMidia>(5, _omitFieldNames ? '' : 'fotoInstalado',
        subBuilder: ReferenciaMidia.create)
    ..pPS(6, _omitFieldNames ? '' : 'idsMateriaisUsados')
    ..aOS(7, _omitFieldNames ? '' : 'observacoes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetalheNovoPonto clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetalheNovoPonto copyWith(void Function(DetalheNovoPonto) updates) =>
      super.copyWith((message) => updates(message as DetalheNovoPonto))
          as DetalheNovoPonto;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DetalheNovoPonto create() => DetalheNovoPonto._();
  @$core.override
  DetalheNovoPonto createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DetalheNovoPonto getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DetalheNovoPonto>(create);
  static DetalheNovoPonto? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get autorizacaoConfirmada => $_getBF(0);
  @$pb.TagNumber(1)
  set autorizacaoConfirmada($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAutorizacaoConfirmada() => $_has(0);
  @$pb.TagNumber(1)
  void clearAutorizacaoConfirmada() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get latitude => $_getN(1);
  @$pb.TagNumber(2)
  set latitude($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLatitude() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatitude() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get longitude => $_getN(2);
  @$pb.TagNumber(3)
  set longitude($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLongitude() => $_has(2);
  @$pb.TagNumber(3)
  void clearLongitude() => $_clearField(3);

  @$pb.TagNumber(4)
  ReferenciaMidia get fotoLocalEscolhido => $_getN(3);
  @$pb.TagNumber(4)
  set fotoLocalEscolhido(ReferenciaMidia value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasFotoLocalEscolhido() => $_has(3);
  @$pb.TagNumber(4)
  void clearFotoLocalEscolhido() => $_clearField(4);
  @$pb.TagNumber(4)
  ReferenciaMidia ensureFotoLocalEscolhido() => $_ensure(3);

  @$pb.TagNumber(5)
  ReferenciaMidia get fotoInstalado => $_getN(4);
  @$pb.TagNumber(5)
  set fotoInstalado(ReferenciaMidia value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasFotoInstalado() => $_has(4);
  @$pb.TagNumber(5)
  void clearFotoInstalado() => $_clearField(5);
  @$pb.TagNumber(5)
  ReferenciaMidia ensureFotoInstalado() => $_ensure(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get idsMateriaisUsados => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get observacoes => $_getSZ(6);
  @$pb.TagNumber(7)
  set observacoes($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasObservacoes() => $_has(6);
  @$pb.TagNumber(7)
  void clearObservacoes() => $_clearField(7);
}

class DetalheRemocaoBloco extends $pb.GeneratedMessage {
  factory DetalheRemocaoBloco({
    ReferenciaMidia? fotoAntes,
    ReferenciaMidia? fotoDepois,
    $core.String? observacoes,
  }) {
    final result = create();
    if (fotoAntes != null) result.fotoAntes = fotoAntes;
    if (fotoDepois != null) result.fotoDepois = fotoDepois;
    if (observacoes != null) result.observacoes = observacoes;
    return result;
  }

  DetalheRemocaoBloco._();

  factory DetalheRemocaoBloco.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DetalheRemocaoBloco.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DetalheRemocaoBloco',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOM<ReferenciaMidia>(1, _omitFieldNames ? '' : 'fotoAntes',
        subBuilder: ReferenciaMidia.create)
    ..aOM<ReferenciaMidia>(2, _omitFieldNames ? '' : 'fotoDepois',
        subBuilder: ReferenciaMidia.create)
    ..aOS(3, _omitFieldNames ? '' : 'observacoes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetalheRemocaoBloco clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetalheRemocaoBloco copyWith(void Function(DetalheRemocaoBloco) updates) =>
      super.copyWith((message) => updates(message as DetalheRemocaoBloco))
          as DetalheRemocaoBloco;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DetalheRemocaoBloco create() => DetalheRemocaoBloco._();
  @$core.override
  DetalheRemocaoBloco createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DetalheRemocaoBloco getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DetalheRemocaoBloco>(create);
  static DetalheRemocaoBloco? _defaultInstance;

  @$pb.TagNumber(1)
  ReferenciaMidia get fotoAntes => $_getN(0);
  @$pb.TagNumber(1)
  set fotoAntes(ReferenciaMidia value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFotoAntes() => $_has(0);
  @$pb.TagNumber(1)
  void clearFotoAntes() => $_clearField(1);
  @$pb.TagNumber(1)
  ReferenciaMidia ensureFotoAntes() => $_ensure(0);

  @$pb.TagNumber(2)
  ReferenciaMidia get fotoDepois => $_getN(1);
  @$pb.TagNumber(2)
  set fotoDepois(ReferenciaMidia value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFotoDepois() => $_has(1);
  @$pb.TagNumber(2)
  void clearFotoDepois() => $_clearField(2);
  @$pb.TagNumber(2)
  ReferenciaMidia ensureFotoDepois() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get observacoes => $_getSZ(2);
  @$pb.TagNumber(3)
  set observacoes($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasObservacoes() => $_has(2);
  @$pb.TagNumber(3)
  void clearObservacoes() => $_clearField(3);
}

class DetalheLimpeza extends $pb.GeneratedMessage {
  factory DetalheLimpeza({
    ReferenciaMidia? fotoAntes,
    ReferenciaMidia? fotoDepois,
    $core.String? observacoes,
  }) {
    final result = create();
    if (fotoAntes != null) result.fotoAntes = fotoAntes;
    if (fotoDepois != null) result.fotoDepois = fotoDepois;
    if (observacoes != null) result.observacoes = observacoes;
    return result;
  }

  DetalheLimpeza._();

  factory DetalheLimpeza.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DetalheLimpeza.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DetalheLimpeza',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOM<ReferenciaMidia>(1, _omitFieldNames ? '' : 'fotoAntes',
        subBuilder: ReferenciaMidia.create)
    ..aOM<ReferenciaMidia>(2, _omitFieldNames ? '' : 'fotoDepois',
        subBuilder: ReferenciaMidia.create)
    ..aOS(3, _omitFieldNames ? '' : 'observacoes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetalheLimpeza clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetalheLimpeza copyWith(void Function(DetalheLimpeza) updates) =>
      super.copyWith((message) => updates(message as DetalheLimpeza))
          as DetalheLimpeza;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DetalheLimpeza create() => DetalheLimpeza._();
  @$core.override
  DetalheLimpeza createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DetalheLimpeza getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DetalheLimpeza>(create);
  static DetalheLimpeza? _defaultInstance;

  @$pb.TagNumber(1)
  ReferenciaMidia get fotoAntes => $_getN(0);
  @$pb.TagNumber(1)
  set fotoAntes(ReferenciaMidia value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFotoAntes() => $_has(0);
  @$pb.TagNumber(1)
  void clearFotoAntes() => $_clearField(1);
  @$pb.TagNumber(1)
  ReferenciaMidia ensureFotoAntes() => $_ensure(0);

  @$pb.TagNumber(2)
  ReferenciaMidia get fotoDepois => $_getN(1);
  @$pb.TagNumber(2)
  set fotoDepois(ReferenciaMidia value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFotoDepois() => $_has(1);
  @$pb.TagNumber(2)
  void clearFotoDepois() => $_clearField(2);
  @$pb.TagNumber(2)
  ReferenciaMidia ensureFotoDepois() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get observacoes => $_getSZ(2);
  @$pb.TagNumber(3)
  set observacoes($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasObservacoes() => $_has(2);
  @$pb.TagNumber(3)
  void clearObservacoes() => $_clearField(3);
}

class DetalheAcaoCustomizada extends $pb.GeneratedMessage {
  factory DetalheAcaoCustomizada({
    $core.String? descricao,
    ReferenciaMidia? foto,
    ReferenciaMidia? video,
    $core.String? observacoes,
  }) {
    final result = create();
    if (descricao != null) result.descricao = descricao;
    if (foto != null) result.foto = foto;
    if (video != null) result.video = video;
    if (observacoes != null) result.observacoes = observacoes;
    return result;
  }

  DetalheAcaoCustomizada._();

  factory DetalheAcaoCustomizada.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DetalheAcaoCustomizada.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DetalheAcaoCustomizada',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'descricao')
    ..aOM<ReferenciaMidia>(2, _omitFieldNames ? '' : 'foto',
        subBuilder: ReferenciaMidia.create)
    ..aOM<ReferenciaMidia>(3, _omitFieldNames ? '' : 'video',
        subBuilder: ReferenciaMidia.create)
    ..aOS(4, _omitFieldNames ? '' : 'observacoes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetalheAcaoCustomizada clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetalheAcaoCustomizada copyWith(
          void Function(DetalheAcaoCustomizada) updates) =>
      super.copyWith((message) => updates(message as DetalheAcaoCustomizada))
          as DetalheAcaoCustomizada;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DetalheAcaoCustomizada create() => DetalheAcaoCustomizada._();
  @$core.override
  DetalheAcaoCustomizada createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DetalheAcaoCustomizada getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DetalheAcaoCustomizada>(create);
  static DetalheAcaoCustomizada? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get descricao => $_getSZ(0);
  @$pb.TagNumber(1)
  set descricao($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDescricao() => $_has(0);
  @$pb.TagNumber(1)
  void clearDescricao() => $_clearField(1);

  @$pb.TagNumber(2)
  ReferenciaMidia get foto => $_getN(1);
  @$pb.TagNumber(2)
  set foto(ReferenciaMidia value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFoto() => $_has(1);
  @$pb.TagNumber(2)
  void clearFoto() => $_clearField(2);
  @$pb.TagNumber(2)
  ReferenciaMidia ensureFoto() => $_ensure(1);

  @$pb.TagNumber(3)
  ReferenciaMidia get video => $_getN(2);
  @$pb.TagNumber(3)
  set video(ReferenciaMidia value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasVideo() => $_has(2);
  @$pb.TagNumber(3)
  void clearVideo() => $_clearField(3);
  @$pb.TagNumber(3)
  ReferenciaMidia ensureVideo() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get observacoes => $_getSZ(3);
  @$pb.TagNumber(4)
  set observacoes($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasObservacoes() => $_has(3);
  @$pb.TagNumber(4)
  void clearObservacoes() => $_clearField(4);
}

class AvaliacaoFinal extends $pb.GeneratedMessage {
  factory AvaliacaoFinal({
    AvaliacaoFinal_ResultadoGeral? resultado,
    $core.String? observacoes,
  }) {
    final result = create();
    if (resultado != null) result.resultado = resultado;
    if (observacoes != null) result.observacoes = observacoes;
    return result;
  }

  AvaliacaoFinal._();

  factory AvaliacaoFinal.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AvaliacaoFinal.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AvaliacaoFinal',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aE<AvaliacaoFinal_ResultadoGeral>(1, _omitFieldNames ? '' : 'resultado',
        enumValues: AvaliacaoFinal_ResultadoGeral.values)
    ..aOS(2, _omitFieldNames ? '' : 'observacoes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AvaliacaoFinal clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AvaliacaoFinal copyWith(void Function(AvaliacaoFinal) updates) =>
      super.copyWith((message) => updates(message as AvaliacaoFinal))
          as AvaliacaoFinal;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AvaliacaoFinal create() => AvaliacaoFinal._();
  @$core.override
  AvaliacaoFinal createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AvaliacaoFinal getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AvaliacaoFinal>(create);
  static AvaliacaoFinal? _defaultInstance;

  @$pb.TagNumber(1)
  AvaliacaoFinal_ResultadoGeral get resultado => $_getN(0);
  @$pb.TagNumber(1)
  set resultado(AvaliacaoFinal_ResultadoGeral value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResultado() => $_has(0);
  @$pb.TagNumber(1)
  void clearResultado() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get observacoes => $_getSZ(1);
  @$pb.TagNumber(2)
  set observacoes($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasObservacoes() => $_has(1);
  @$pb.TagNumber(2)
  void clearObservacoes() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
