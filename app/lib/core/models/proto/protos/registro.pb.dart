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

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Representa um arquivo de imagem armazenado isoladamente no diretório da sessão.
/// Esta estrutura guarda metadados essenciais de segurança para a auditoria criptográfica.
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

/// Representa um arquivo de vídeo armazenado isoladamente.
/// Permite compressões em H.264/H.265 para PDF mantendo o rastro criptográfico.
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

/// Representa um arquivo de áudio (mensagens de voz ou laudos falados).
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

/// Um contêiner polimórfico (`oneof`) que aponta para qualquer tipo de mídia no disco local.
/// Substitui a inclusão direta de bytes no Protobuf, delegando a mídia para o SessionBundleManager.
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

/// Wrapper para permitir listas de respostas dentro do oneof (ex: checkboxes, seleções múltiplas)
class ListaRespostas extends $pb.GeneratedMessage {
  factory ListaRespostas({
    $core.Iterable<Resposta>? valores,
  }) {
    final result = create();
    if (valores != null) result.valores.addAll(valores);
    return result;
  }

  ListaRespostas._();

  factory ListaRespostas.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListaRespostas.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListaRespostas',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..pPM<Resposta>(1, _omitFieldNames ? '' : 'valores',
        subBuilder: Resposta.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListaRespostas clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListaRespostas copyWith(void Function(ListaRespostas) updates) =>
      super.copyWith((message) => updates(message as ListaRespostas))
          as ListaRespostas;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListaRespostas create() => ListaRespostas._();
  @$core.override
  ListaRespostas createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListaRespostas getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListaRespostas>(create);
  static ListaRespostas? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Resposta> get valores => $_getList(0);
}

enum Resposta_Valor { texto, numero, inteiro, booleano, midia, lista, notSet }

/// Tipo de dado dinâmico para os campos do formulário
class Resposta extends $pb.GeneratedMessage {
  factory Resposta({
    $core.String? texto,
    $core.double? numero,
    $fixnum.Int64? inteiro,
    $core.bool? booleano,
    ReferenciaMidia? midia,
    ListaRespostas? lista,
  }) {
    final result = create();
    if (texto != null) result.texto = texto;
    if (numero != null) result.numero = numero;
    if (inteiro != null) result.inteiro = inteiro;
    if (booleano != null) result.booleano = booleano;
    if (midia != null) result.midia = midia;
    if (lista != null) result.lista = lista;
    return result;
  }

  Resposta._();

  factory Resposta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Resposta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Resposta_Valor> _Resposta_ValorByTag = {
    1: Resposta_Valor.texto,
    2: Resposta_Valor.numero,
    3: Resposta_Valor.inteiro,
    4: Resposta_Valor.booleano,
    5: Resposta_Valor.midia,
    6: Resposta_Valor.lista,
    0: Resposta_Valor.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Resposta',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6])
    ..aOS(1, _omitFieldNames ? '' : 'texto')
    ..aD(2, _omitFieldNames ? '' : 'numero')
    ..aInt64(3, _omitFieldNames ? '' : 'inteiro')
    ..aOB(4, _omitFieldNames ? '' : 'booleano')
    ..aOM<ReferenciaMidia>(5, _omitFieldNames ? '' : 'midia',
        subBuilder: ReferenciaMidia.create)
    ..aOM<ListaRespostas>(6, _omitFieldNames ? '' : 'lista',
        subBuilder: ListaRespostas.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Resposta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Resposta copyWith(void Function(Resposta) updates) =>
      super.copyWith((message) => updates(message as Resposta)) as Resposta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Resposta create() => Resposta._();
  @$core.override
  Resposta createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Resposta getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Resposta>(create);
  static Resposta? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  Resposta_Valor whichValor() => _Resposta_ValorByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  void clearValor() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get texto => $_getSZ(0);
  @$pb.TagNumber(1)
  set texto($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTexto() => $_has(0);
  @$pb.TagNumber(1)
  void clearTexto() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get numero => $_getN(1);
  @$pb.TagNumber(2)
  set numero($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNumero() => $_has(1);
  @$pb.TagNumber(2)
  void clearNumero() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get inteiro => $_getI64(2);
  @$pb.TagNumber(3)
  set inteiro($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInteiro() => $_has(2);
  @$pb.TagNumber(3)
  void clearInteiro() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get booleano => $_getBF(3);
  @$pb.TagNumber(4)
  set booleano($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBooleano() => $_has(3);
  @$pb.TagNumber(4)
  void clearBooleano() => $_clearField(4);

  @$pb.TagNumber(5)
  ReferenciaMidia get midia => $_getN(4);
  @$pb.TagNumber(5)
  set midia(ReferenciaMidia value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasMidia() => $_has(4);
  @$pb.TagNumber(5)
  void clearMidia() => $_clearField(5);
  @$pb.TagNumber(5)
  ReferenciaMidia ensureMidia() => $_ensure(4);

  @$pb.TagNumber(6)
  ListaRespostas get lista => $_getN(5);
  @$pb.TagNumber(6)
  set lista(ListaRespostas value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasLista() => $_has(5);
  @$pb.TagNumber(6)
  void clearLista() => $_clearField(6);
  @$pb.TagNumber(6)
  ListaRespostas ensureLista() => $_ensure(5);
}

/// Representa um item gerado dinamicamente dentro de uma ListaAcoes ou similar no YAML
class GrupoRepetido extends $pb.GeneratedMessage {
  factory GrupoRepetido({
    $core.String? idLista,
    $core.String? idItem,
    $core.String? idTipo,
    $core.Iterable<$core.MapEntry<$core.String, Resposta>>? respostasItem,
  }) {
    final result = create();
    if (idLista != null) result.idLista = idLista;
    if (idItem != null) result.idItem = idItem;
    if (idTipo != null) result.idTipo = idTipo;
    if (respostasItem != null) result.respostasItem.addEntries(respostasItem);
    return result;
  }

  GrupoRepetido._();

  factory GrupoRepetido.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GrupoRepetido.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GrupoRepetido',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'idLista')
    ..aOS(2, _omitFieldNames ? '' : 'idItem')
    ..aOS(3, _omitFieldNames ? '' : 'idTipo')
    ..m<$core.String, Resposta>(4, _omitFieldNames ? '' : 'respostasItem',
        entryClassName: 'GrupoRepetido.RespostasItemEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: Resposta.create,
        valueDefaultOrMaker: Resposta.getDefault,
        packageName: const $pb.PackageName('fixalog'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrupoRepetido clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrupoRepetido copyWith(void Function(GrupoRepetido) updates) =>
      super.copyWith((message) => updates(message as GrupoRepetido))
          as GrupoRepetido;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GrupoRepetido create() => GrupoRepetido._();
  @$core.override
  GrupoRepetido createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GrupoRepetido getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GrupoRepetido>(create);
  static GrupoRepetido? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get idLista => $_getSZ(0);
  @$pb.TagNumber(1)
  set idLista($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdLista() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdLista() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get idItem => $_getSZ(1);
  @$pb.TagNumber(2)
  set idItem($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIdItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearIdItem() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get idTipo => $_getSZ(2);
  @$pb.TagNumber(3)
  set idTipo($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIdTipo() => $_has(2);
  @$pb.TagNumber(3)
  void clearIdTipo() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbMap<$core.String, Resposta> get respostasItem => $_getMap(3);
}

class Registro extends $pb.GeneratedMessage {
  factory Registro({
    $core.String? idSessao,
    $core.String? idProtocolo,
    $core.String? versaoProtocolo,
    $fixnum.Int64? utcTimestampInicio,
    $fixnum.Int64? utcTimestampFim,
    $core.List<$core.int>? assinaturaVisual,
    $core.List<$core.int>? assinaturaDigital,
    $core.String? idMantenedor,
    $core.String? attestationToken,
    $core.Iterable<$core.MapEntry<$core.String, Resposta>>? respostas,
    $core.Iterable<GrupoRepetido>? listas,
    $core.String? yamlConteudo,
  }) {
    final result = create();
    if (idSessao != null) result.idSessao = idSessao;
    if (idProtocolo != null) result.idProtocolo = idProtocolo;
    if (versaoProtocolo != null) result.versaoProtocolo = versaoProtocolo;
    if (utcTimestampInicio != null)
      result.utcTimestampInicio = utcTimestampInicio;
    if (utcTimestampFim != null) result.utcTimestampFim = utcTimestampFim;
    if (assinaturaVisual != null) result.assinaturaVisual = assinaturaVisual;
    if (assinaturaDigital != null) result.assinaturaDigital = assinaturaDigital;
    if (idMantenedor != null) result.idMantenedor = idMantenedor;
    if (attestationToken != null) result.attestationToken = attestationToken;
    if (respostas != null) result.respostas.addEntries(respostas);
    if (listas != null) result.listas.addAll(listas);
    if (yamlConteudo != null) result.yamlConteudo = yamlConteudo;
    return result;
  }

  Registro._();

  factory Registro.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Registro.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Registro',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'idSessao')
    ..aOS(2, _omitFieldNames ? '' : 'idProtocolo')
    ..aOS(3, _omitFieldNames ? '' : 'versaoProtocolo')
    ..aInt64(4, _omitFieldNames ? '' : 'utcTimestampInicio')
    ..aInt64(5, _omitFieldNames ? '' : 'utcTimestampFim')
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'assinaturaVisual', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'assinaturaDigital', $pb.PbFieldType.OY)
    ..aOS(8, _omitFieldNames ? '' : 'idMantenedor')
    ..aOS(9, _omitFieldNames ? '' : 'attestationToken')
    ..m<$core.String, Resposta>(10, _omitFieldNames ? '' : 'respostas',
        entryClassName: 'Registro.RespostasEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: Resposta.create,
        valueDefaultOrMaker: Resposta.getDefault,
        packageName: const $pb.PackageName('fixalog'))
    ..pPM<GrupoRepetido>(11, _omitFieldNames ? '' : 'listas',
        subBuilder: GrupoRepetido.create)
    ..aOS(12, _omitFieldNames ? '' : 'yamlConteudo')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Registro clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Registro copyWith(void Function(Registro) updates) =>
      super.copyWith((message) => updates(message as Registro)) as Registro;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Registro create() => Registro._();
  @$core.override
  Registro createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Registro getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Registro>(create);
  static Registro? _defaultInstance;

  /// --- ENVELOPE ESTRITO DE SEGURANÇA E CONTEXTO ---
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
  $core.List<$core.int> get assinaturaVisual => $_getN(5);
  @$pb.TagNumber(6)
  set assinaturaVisual($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAssinaturaVisual() => $_has(5);
  @$pb.TagNumber(6)
  void clearAssinaturaVisual() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get assinaturaDigital => $_getN(6);
  @$pb.TagNumber(7)
  set assinaturaDigital($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAssinaturaDigital() => $_has(6);
  @$pb.TagNumber(7)
  void clearAssinaturaDigital() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get idMantenedor => $_getSZ(7);
  @$pb.TagNumber(8)
  set idMantenedor($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIdMantenedor() => $_has(7);
  @$pb.TagNumber(8)
  void clearIdMantenedor() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get attestationToken => $_getSZ(8);
  @$pb.TagNumber(9)
  set attestationToken($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAttestationToken() => $_has(8);
  @$pb.TagNumber(9)
  void clearAttestationToken() => $_clearField(9);

  /// --- PAYLOAD DINÂMICO ---
  /// Respostas planas e campos simples do fluxo principal. A chave é o ID definido no YAML.
  @$pb.TagNumber(10)
  $pb.PbMap<$core.String, Resposta> get respostas => $_getMap(9);

  /// Listas de itens criados dinamicamente no formulário (Blocos que podem repetir infinitamente).
  @$pb.TagNumber(11)
  $pb.PbList<GrupoRepetido> get listas => $_getList(10);

  /// Conteúdo raw do YAML usado para gerar este registro (garante recriação perfeita do layout original)
  @$pb.TagNumber(12)
  $core.String get yamlConteudo => $_getSZ(11);
  @$pb.TagNumber(12)
  set yamlConteudo($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasYamlConteudo() => $_has(11);
  @$pb.TagNumber(12)
  void clearYamlConteudo() => $_clearField(12);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
