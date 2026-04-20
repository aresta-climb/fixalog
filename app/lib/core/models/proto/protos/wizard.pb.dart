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

import 'wizard.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'wizard.pbenum.dart';

class DefinicaoProtocolo extends $pb.GeneratedMessage {
  factory DefinicaoProtocolo({
    $core.String? id,
    $core.String? nome,
    $core.String? descricao,
    $core.String? versao,
    $core.Iterable<Bloco>? blocos,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (nome != null) result.nome = nome;
    if (descricao != null) result.descricao = descricao;
    if (versao != null) result.versao = versao;
    if (blocos != null) result.blocos.addAll(blocos);
    return result;
  }

  DefinicaoProtocolo._();

  factory DefinicaoProtocolo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DefinicaoProtocolo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DefinicaoProtocolo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'nome')
    ..aOS(3, _omitFieldNames ? '' : 'descricao')
    ..aOS(4, _omitFieldNames ? '' : 'versao')
    ..pPM<Bloco>(5, _omitFieldNames ? '' : 'blocos', subBuilder: Bloco.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DefinicaoProtocolo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DefinicaoProtocolo copyWith(void Function(DefinicaoProtocolo) updates) =>
      super.copyWith((message) => updates(message as DefinicaoProtocolo))
          as DefinicaoProtocolo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DefinicaoProtocolo create() => DefinicaoProtocolo._();
  @$core.override
  DefinicaoProtocolo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DefinicaoProtocolo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DefinicaoProtocolo>(create);
  static DefinicaoProtocolo? _defaultInstance;

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
  $core.String get descricao => $_getSZ(2);
  @$pb.TagNumber(3)
  set descricao($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescricao() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescricao() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get versao => $_getSZ(3);
  @$pb.TagNumber(4)
  set versao($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVersao() => $_has(3);
  @$pb.TagNumber(4)
  void clearVersao() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<Bloco> get blocos => $_getList(4);
}

/// Um Bloco é uma seção nomeada do wizard (ex: "Materiais", "Ações")
class Bloco extends $pb.GeneratedMessage {
  factory Bloco({
    $core.String? id,
    $core.String? titulo,
    $core.String? subtitulo,
    $core.Iterable<Step>? steps,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (titulo != null) result.titulo = titulo;
    if (subtitulo != null) result.subtitulo = subtitulo;
    if (steps != null) result.steps.addAll(steps);
    return result;
  }

  Bloco._();

  factory Bloco.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Bloco.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Bloco',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'titulo')
    ..aOS(3, _omitFieldNames ? '' : 'subtitulo')
    ..pPM<Step>(4, _omitFieldNames ? '' : 'steps', subBuilder: Step.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Bloco clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Bloco copyWith(void Function(Bloco) updates) =>
      super.copyWith((message) => updates(message as Bloco)) as Bloco;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Bloco create() => Bloco._();
  @$core.override
  Bloco createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Bloco getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Bloco>(create);
  static Bloco? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get titulo => $_getSZ(1);
  @$pb.TagNumber(2)
  set titulo($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitulo() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitulo() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get subtitulo => $_getSZ(2);
  @$pb.TagNumber(3)
  set subtitulo($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSubtitulo() => $_has(2);
  @$pb.TagNumber(3)
  void clearSubtitulo() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<Step> get steps => $_getList(3);
}

enum ConteudoStep_Tipo {
  instrucao,
  campoSimples,
  selecaoRamo,
  listaAcoes,
  refMateriais,
  notSet
}

/// ConteudoStep: um elemento de conteúdo com ID próprio para mapeamento de
/// respostas. Um Step (card) pode ter vários destes, exibidos em sequência.
class ConteudoStep extends $pb.GeneratedMessage {
  factory ConteudoStep({
    $core.String? id,
    StepInstrucao? instrucao,
    StepCampoSimples? campoSimples,
    StepSelecaoRamo? selecaoRamo,
    StepListaAcoes? listaAcoes,
    StepRefMateriais? refMateriais,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (instrucao != null) result.instrucao = instrucao;
    if (campoSimples != null) result.campoSimples = campoSimples;
    if (selecaoRamo != null) result.selecaoRamo = selecaoRamo;
    if (listaAcoes != null) result.listaAcoes = listaAcoes;
    if (refMateriais != null) result.refMateriais = refMateriais;
    return result;
  }

  ConteudoStep._();

  factory ConteudoStep.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConteudoStep.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ConteudoStep_Tipo> _ConteudoStep_TipoByTag =
      {
    2: ConteudoStep_Tipo.instrucao,
    3: ConteudoStep_Tipo.campoSimples,
    4: ConteudoStep_Tipo.selecaoRamo,
    5: ConteudoStep_Tipo.listaAcoes,
    6: ConteudoStep_Tipo.refMateriais,
    0: ConteudoStep_Tipo.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConteudoStep',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4, 5, 6])
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<StepInstrucao>(2, _omitFieldNames ? '' : 'instrucao',
        subBuilder: StepInstrucao.create)
    ..aOM<StepCampoSimples>(3, _omitFieldNames ? '' : 'campoSimples',
        subBuilder: StepCampoSimples.create)
    ..aOM<StepSelecaoRamo>(4, _omitFieldNames ? '' : 'selecaoRamo',
        subBuilder: StepSelecaoRamo.create)
    ..aOM<StepListaAcoes>(5, _omitFieldNames ? '' : 'listaAcoes',
        subBuilder: StepListaAcoes.create)
    ..aOM<StepRefMateriais>(6, _omitFieldNames ? '' : 'refMateriais',
        subBuilder: StepRefMateriais.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConteudoStep clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConteudoStep copyWith(void Function(ConteudoStep) updates) =>
      super.copyWith((message) => updates(message as ConteudoStep))
          as ConteudoStep;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConteudoStep create() => ConteudoStep._();
  @$core.override
  ConteudoStep createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConteudoStep getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConteudoStep>(create);
  static ConteudoStep? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  ConteudoStep_Tipo whichTipo() => _ConteudoStep_TipoByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  void clearTipo() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  StepInstrucao get instrucao => $_getN(1);
  @$pb.TagNumber(2)
  set instrucao(StepInstrucao value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasInstrucao() => $_has(1);
  @$pb.TagNumber(2)
  void clearInstrucao() => $_clearField(2);
  @$pb.TagNumber(2)
  StepInstrucao ensureInstrucao() => $_ensure(1);

  @$pb.TagNumber(3)
  StepCampoSimples get campoSimples => $_getN(2);
  @$pb.TagNumber(3)
  set campoSimples(StepCampoSimples value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCampoSimples() => $_has(2);
  @$pb.TagNumber(3)
  void clearCampoSimples() => $_clearField(3);
  @$pb.TagNumber(3)
  StepCampoSimples ensureCampoSimples() => $_ensure(2);

  @$pb.TagNumber(4)
  StepSelecaoRamo get selecaoRamo => $_getN(3);
  @$pb.TagNumber(4)
  set selecaoRamo(StepSelecaoRamo value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSelecaoRamo() => $_has(3);
  @$pb.TagNumber(4)
  void clearSelecaoRamo() => $_clearField(4);
  @$pb.TagNumber(4)
  StepSelecaoRamo ensureSelecaoRamo() => $_ensure(3);

  @$pb.TagNumber(5)
  StepListaAcoes get listaAcoes => $_getN(4);
  @$pb.TagNumber(5)
  set listaAcoes(StepListaAcoes value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasListaAcoes() => $_has(4);
  @$pb.TagNumber(5)
  void clearListaAcoes() => $_clearField(5);
  @$pb.TagNumber(5)
  StepListaAcoes ensureListaAcoes() => $_ensure(4);

  @$pb.TagNumber(6)
  StepRefMateriais get refMateriais => $_getN(5);
  @$pb.TagNumber(6)
  set refMateriais(StepRefMateriais value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRefMateriais() => $_has(5);
  @$pb.TagNumber(6)
  void clearRefMateriais() => $_clearField(6);
  @$pb.TagNumber(6)
  StepRefMateriais ensureRefMateriais() => $_ensure(5);
}

class Step extends $pb.GeneratedMessage {
  factory Step({
    $core.String? id,
    $core.Iterable<ConteudoStep>? conteudos,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (conteudos != null) result.conteudos.addAll(conteudos);
    return result;
  }

  Step._();

  factory Step.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Step.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Step',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..pPM<ConteudoStep>(2, _omitFieldNames ? '' : 'conteudos',
        subBuilder: ConteudoStep.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Step clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Step copyWith(void Function(Step) updates) =>
      super.copyWith((message) => updates(message as Step)) as Step;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Step create() => Step._();
  @$core.override
  Step createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Step getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Step>(create);
  static Step? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<ConteudoStep> get conteudos => $_getList(1);
}

/// Orientação pura — exibe texto/instrução, não coleta dado algum
class StepInstrucao extends $pb.GeneratedMessage {
  factory StepInstrucao({
    $core.String? titulo,
    $core.String? corpo,
    $core.String? iconName,
    StepInstrucao_NivelAlerta? nivelAlerta,
  }) {
    final result = create();
    if (titulo != null) result.titulo = titulo;
    if (corpo != null) result.corpo = corpo;
    if (iconName != null) result.iconName = iconName;
    if (nivelAlerta != null) result.nivelAlerta = nivelAlerta;
    return result;
  }

  StepInstrucao._();

  factory StepInstrucao.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StepInstrucao.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StepInstrucao',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'titulo')
    ..aOS(2, _omitFieldNames ? '' : 'corpo')
    ..aOS(3, _omitFieldNames ? '' : 'iconName')
    ..aE<StepInstrucao_NivelAlerta>(4, _omitFieldNames ? '' : 'nivelAlerta',
        enumValues: StepInstrucao_NivelAlerta.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StepInstrucao clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StepInstrucao copyWith(void Function(StepInstrucao) updates) =>
      super.copyWith((message) => updates(message as StepInstrucao))
          as StepInstrucao;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StepInstrucao create() => StepInstrucao._();
  @$core.override
  StepInstrucao createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StepInstrucao getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StepInstrucao>(create);
  static StepInstrucao? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get titulo => $_getSZ(0);
  @$pb.TagNumber(1)
  set titulo($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitulo() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitulo() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get corpo => $_getSZ(1);
  @$pb.TagNumber(2)
  set corpo($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCorpo() => $_has(1);
  @$pb.TagNumber(2)
  void clearCorpo() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get iconName => $_getSZ(2);
  @$pb.TagNumber(3)
  set iconName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIconName() => $_has(2);
  @$pb.TagNumber(3)
  void clearIconName() => $_clearField(3);

  @$pb.TagNumber(4)
  StepInstrucao_NivelAlerta get nivelAlerta => $_getN(3);
  @$pb.TagNumber(4)
  set nivelAlerta(StepInstrucao_NivelAlerta value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasNivelAlerta() => $_has(3);
  @$pb.TagNumber(4)
  void clearNivelAlerta() => $_clearField(4);
}

class StepCampoSimples extends $pb.GeneratedMessage {
  factory StepCampoSimples({
    $core.String? label,
    $core.String? sublabel,
    StepCampoSimples_TipoCampo? tipo,
    StepCampoSimples_UiHint? uiHint,
    $core.bool? obrigatorio,
    $core.Iterable<OpcaoCampo>? opcoes,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (sublabel != null) result.sublabel = sublabel;
    if (tipo != null) result.tipo = tipo;
    if (uiHint != null) result.uiHint = uiHint;
    if (obrigatorio != null) result.obrigatorio = obrigatorio;
    if (opcoes != null) result.opcoes.addAll(opcoes);
    return result;
  }

  StepCampoSimples._();

  factory StepCampoSimples.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StepCampoSimples.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StepCampoSimples',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOS(2, _omitFieldNames ? '' : 'sublabel')
    ..aE<StepCampoSimples_TipoCampo>(3, _omitFieldNames ? '' : 'tipo',
        enumValues: StepCampoSimples_TipoCampo.values)
    ..aE<StepCampoSimples_UiHint>(4, _omitFieldNames ? '' : 'uiHint',
        enumValues: StepCampoSimples_UiHint.values)
    ..aOB(5, _omitFieldNames ? '' : 'obrigatorio')
    ..pPM<OpcaoCampo>(6, _omitFieldNames ? '' : 'opcoes',
        subBuilder: OpcaoCampo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StepCampoSimples clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StepCampoSimples copyWith(void Function(StepCampoSimples) updates) =>
      super.copyWith((message) => updates(message as StepCampoSimples))
          as StepCampoSimples;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StepCampoSimples create() => StepCampoSimples._();
  @$core.override
  StepCampoSimples createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StepCampoSimples getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StepCampoSimples>(create);
  static StepCampoSimples? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sublabel => $_getSZ(1);
  @$pb.TagNumber(2)
  set sublabel($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSublabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearSublabel() => $_clearField(2);

  @$pb.TagNumber(3)
  StepCampoSimples_TipoCampo get tipo => $_getN(2);
  @$pb.TagNumber(3)
  set tipo(StepCampoSimples_TipoCampo value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTipo() => $_has(2);
  @$pb.TagNumber(3)
  void clearTipo() => $_clearField(3);

  @$pb.TagNumber(4)
  StepCampoSimples_UiHint get uiHint => $_getN(3);
  @$pb.TagNumber(4)
  set uiHint(StepCampoSimples_UiHint value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasUiHint() => $_has(3);
  @$pb.TagNumber(4)
  void clearUiHint() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get obrigatorio => $_getBF(4);
  @$pb.TagNumber(5)
  set obrigatorio($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasObrigatorio() => $_has(4);
  @$pb.TagNumber(5)
  void clearObrigatorio() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<OpcaoCampo> get opcoes => $_getList(5);
}

class OpcaoCampo extends $pb.GeneratedMessage {
  factory OpcaoCampo({
    $core.String? valor,
    $core.String? label,
    $core.String? sublabel,
    $core.String? iconName,
  }) {
    final result = create();
    if (valor != null) result.valor = valor;
    if (label != null) result.label = label;
    if (sublabel != null) result.sublabel = sublabel;
    if (iconName != null) result.iconName = iconName;
    return result;
  }

  OpcaoCampo._();

  factory OpcaoCampo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpcaoCampo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpcaoCampo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'valor')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'sublabel')
    ..aOS(4, _omitFieldNames ? '' : 'iconName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpcaoCampo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpcaoCampo copyWith(void Function(OpcaoCampo) updates) =>
      super.copyWith((message) => updates(message as OpcaoCampo)) as OpcaoCampo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpcaoCampo create() => OpcaoCampo._();
  @$core.override
  OpcaoCampo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpcaoCampo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpcaoCampo>(create);
  static OpcaoCampo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get valor => $_getSZ(0);
  @$pb.TagNumber(1)
  set valor($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValor() => $_has(0);
  @$pb.TagNumber(1)
  void clearValor() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sublabel => $_getSZ(2);
  @$pb.TagNumber(3)
  set sublabel($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSublabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearSublabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get iconName => $_getSZ(3);
  @$pb.TagNumber(4)
  set iconName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIconName() => $_has(3);
  @$pb.TagNumber(4)
  void clearIconName() => $_clearField(4);
}

class StepSelecaoRamo extends $pb.GeneratedMessage {
  factory StepSelecaoRamo({
    $core.String? label,
    $core.String? sublabel,
    $core.bool? obrigatorio,
    $core.Iterable<Ramo>? ramos,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (sublabel != null) result.sublabel = sublabel;
    if (obrigatorio != null) result.obrigatorio = obrigatorio;
    if (ramos != null) result.ramos.addAll(ramos);
    return result;
  }

  StepSelecaoRamo._();

  factory StepSelecaoRamo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StepSelecaoRamo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StepSelecaoRamo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOS(2, _omitFieldNames ? '' : 'sublabel')
    ..aOB(3, _omitFieldNames ? '' : 'obrigatorio')
    ..pPM<Ramo>(4, _omitFieldNames ? '' : 'ramos', subBuilder: Ramo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StepSelecaoRamo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StepSelecaoRamo copyWith(void Function(StepSelecaoRamo) updates) =>
      super.copyWith((message) => updates(message as StepSelecaoRamo))
          as StepSelecaoRamo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StepSelecaoRamo create() => StepSelecaoRamo._();
  @$core.override
  StepSelecaoRamo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StepSelecaoRamo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StepSelecaoRamo>(create);
  static StepSelecaoRamo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sublabel => $_getSZ(1);
  @$pb.TagNumber(2)
  set sublabel($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSublabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearSublabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get obrigatorio => $_getBF(2);
  @$pb.TagNumber(3)
  set obrigatorio($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasObrigatorio() => $_has(2);
  @$pb.TagNumber(3)
  void clearObrigatorio() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<Ramo> get ramos => $_getList(3);
}

/// Um Ramo tem seu próprio sub-fluxo de Steps (permite branching recursivo)
class Ramo extends $pb.GeneratedMessage {
  factory Ramo({
    $core.String? id,
    $core.String? label,
    $core.String? sublabel,
    $core.String? iconName,
    $core.Iterable<Step>? steps,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (label != null) result.label = label;
    if (sublabel != null) result.sublabel = sublabel;
    if (iconName != null) result.iconName = iconName;
    if (steps != null) result.steps.addAll(steps);
    return result;
  }

  Ramo._();

  factory Ramo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Ramo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ramo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'sublabel')
    ..aOS(4, _omitFieldNames ? '' : 'iconName')
    ..pPM<Step>(5, _omitFieldNames ? '' : 'steps', subBuilder: Step.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ramo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ramo copyWith(void Function(Ramo) updates) =>
      super.copyWith((message) => updates(message as Ramo)) as Ramo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Ramo create() => Ramo._();
  @$core.override
  Ramo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Ramo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Ramo>(create);
  static Ramo? _defaultInstance;

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
  $core.String get sublabel => $_getSZ(2);
  @$pb.TagNumber(3)
  set sublabel($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSublabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearSublabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get iconName => $_getSZ(3);
  @$pb.TagNumber(4)
  set iconName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIconName() => $_has(3);
  @$pb.TagNumber(4)
  void clearIconName() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<Step> get steps => $_getList(4);
}

class StepListaAcoes extends $pb.GeneratedMessage {
  factory StepListaAcoes({
    $core.String? label,
    $core.String? sublabel,
    $core.int? minimo,
    $core.int? maximo,
    $core.Iterable<TipoAcao>? tiposDisponiveis,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (sublabel != null) result.sublabel = sublabel;
    if (minimo != null) result.minimo = minimo;
    if (maximo != null) result.maximo = maximo;
    if (tiposDisponiveis != null)
      result.tiposDisponiveis.addAll(tiposDisponiveis);
    return result;
  }

  StepListaAcoes._();

  factory StepListaAcoes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StepListaAcoes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StepListaAcoes',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOS(2, _omitFieldNames ? '' : 'sublabel')
    ..aI(3, _omitFieldNames ? '' : 'minimo')
    ..aI(4, _omitFieldNames ? '' : 'maximo')
    ..pPM<TipoAcao>(5, _omitFieldNames ? '' : 'tiposDisponiveis',
        subBuilder: TipoAcao.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StepListaAcoes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StepListaAcoes copyWith(void Function(StepListaAcoes) updates) =>
      super.copyWith((message) => updates(message as StepListaAcoes))
          as StepListaAcoes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StepListaAcoes create() => StepListaAcoes._();
  @$core.override
  StepListaAcoes createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StepListaAcoes getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StepListaAcoes>(create);
  static StepListaAcoes? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sublabel => $_getSZ(1);
  @$pb.TagNumber(2)
  set sublabel($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSublabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearSublabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get minimo => $_getIZ(2);
  @$pb.TagNumber(3)
  set minimo($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMinimo() => $_has(2);
  @$pb.TagNumber(3)
  void clearMinimo() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get maximo => $_getIZ(3);
  @$pb.TagNumber(4)
  set maximo($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMaximo() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaximo() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<TipoAcao> get tiposDisponiveis => $_getList(4);
}

/// Um TipoAcao define o sub-fluxo inline de uma categoria de ação
class TipoAcao extends $pb.GeneratedMessage {
  factory TipoAcao({
    $core.String? id,
    $core.String? label,
    $core.String? sublabel,
    $core.String? iconName,
    $core.Iterable<Step>? steps,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (label != null) result.label = label;
    if (sublabel != null) result.sublabel = sublabel;
    if (iconName != null) result.iconName = iconName;
    if (steps != null) result.steps.addAll(steps);
    return result;
  }

  TipoAcao._();

  factory TipoAcao.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TipoAcao.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TipoAcao',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'sublabel')
    ..aOS(4, _omitFieldNames ? '' : 'iconName')
    ..pPM<Step>(5, _omitFieldNames ? '' : 'steps', subBuilder: Step.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TipoAcao clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TipoAcao copyWith(void Function(TipoAcao) updates) =>
      super.copyWith((message) => updates(message as TipoAcao)) as TipoAcao;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TipoAcao create() => TipoAcao._();
  @$core.override
  TipoAcao createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TipoAcao getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TipoAcao>(create);
  static TipoAcao? _defaultInstance;

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
  $core.String get sublabel => $_getSZ(2);
  @$pb.TagNumber(3)
  set sublabel($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSublabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearSublabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get iconName => $_getSZ(3);
  @$pb.TagNumber(4)
  set iconName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIconName() => $_has(3);
  @$pb.TagNumber(4)
  void clearIconName() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<Step> get steps => $_getList(4);
}

class StepRefMateriais extends $pb.GeneratedMessage {
  factory StepRefMateriais({
    $core.String? label,
    $core.String? sublabel,
    $core.String? idStepMateriais,
    $core.bool? obrigatorio,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (sublabel != null) result.sublabel = sublabel;
    if (idStepMateriais != null) result.idStepMateriais = idStepMateriais;
    if (obrigatorio != null) result.obrigatorio = obrigatorio;
    return result;
  }

  StepRefMateriais._();

  factory StepRefMateriais.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StepRefMateriais.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StepRefMateriais',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fixalog'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOS(2, _omitFieldNames ? '' : 'sublabel')
    ..aOS(3, _omitFieldNames ? '' : 'idStepMateriais')
    ..aOB(4, _omitFieldNames ? '' : 'obrigatorio')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StepRefMateriais clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StepRefMateriais copyWith(void Function(StepRefMateriais) updates) =>
      super.copyWith((message) => updates(message as StepRefMateriais))
          as StepRefMateriais;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StepRefMateriais create() => StepRefMateriais._();
  @$core.override
  StepRefMateriais createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StepRefMateriais getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StepRefMateriais>(create);
  static StepRefMateriais? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sublabel => $_getSZ(1);
  @$pb.TagNumber(2)
  set sublabel($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSublabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearSublabel() => $_clearField(2);

  /// ID do ConteudoStep (tipo StepListaAcoes) de onde os materiais vêm.
  /// Ex: "lista_materiais_c" — referencia o ConteudoStep do Bloco 1.
  @$pb.TagNumber(3)
  $core.String get idStepMateriais => $_getSZ(2);
  @$pb.TagNumber(3)
  set idStepMateriais($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIdStepMateriais() => $_has(2);
  @$pb.TagNumber(3)
  void clearIdStepMateriais() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get obrigatorio => $_getBF(3);
  @$pb.TagNumber(4)
  set obrigatorio($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasObrigatorio() => $_has(3);
  @$pb.TagNumber(4)
  void clearObrigatorio() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
