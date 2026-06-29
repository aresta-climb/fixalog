// This is a generated file - do not edit.
//
// Generated from registro.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use registroManutencaoDescriptor instead')
const RegistroManutencao$json = {
  '1': 'RegistroManutencao',
  '2': [
    {'1': 'id_sessao', '3': 1, '4': 1, '5': 9, '10': 'idSessao'},
    {'1': 'id_protocolo', '3': 2, '4': 1, '5': 9, '10': 'idProtocolo'},
    {'1': 'versao_protocolo', '3': 3, '4': 1, '5': 9, '10': 'versaoProtocolo'},
    {
      '1': 'utc_timestamp_inicio',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'utcTimestampInicio'
    },
    {'1': 'utc_timestamp_fim', '3': 5, '4': 1, '5': 3, '10': 'utcTimestampFim'},
    {
      '1': 'materiais',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.fixalog.RegistroMateriais',
      '10': 'materiais'
    },
    {
      '1': 'via',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.fixalog.RegistroVia',
      '10': 'via'
    },
    {
      '1': 'acoes',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.fixalog.AcaoManutencao',
      '10': 'acoes'
    },
    {
      '1': 'avaliacao',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.fixalog.AvaliacaoFinal',
      '10': 'avaliacao'
    },
    {
      '1': 'assinatura_visual',
      '3': 10,
      '4': 1,
      '5': 12,
      '10': 'assinaturaVisual'
    },
    {
      '1': 'assinatura_digital',
      '3': 11,
      '4': 1,
      '5': 12,
      '10': 'assinaturaDigital'
    },
    {'1': 'id_mantenedor', '3': 12, '4': 1, '5': 9, '10': 'idMantenedor'},
  ],
};

/// Descriptor for `RegistroManutencao`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registroManutencaoDescriptor = $convert.base64Decode(
    'ChJSZWdpc3Ryb01hbnV0ZW5jYW8SGwoJaWRfc2Vzc2FvGAEgASgJUghpZFNlc3NhbxIhCgxpZF'
    '9wcm90b2NvbG8YAiABKAlSC2lkUHJvdG9jb2xvEikKEHZlcnNhb19wcm90b2NvbG8YAyABKAlS'
    'D3ZlcnNhb1Byb3RvY29sbxIwChR1dGNfdGltZXN0YW1wX2luaWNpbxgEIAEoA1ISdXRjVGltZX'
    'N0YW1wSW5pY2lvEioKEXV0Y190aW1lc3RhbXBfZmltGAUgASgDUg91dGNUaW1lc3RhbXBGaW0S'
    'OAoJbWF0ZXJpYWlzGAYgASgLMhouZml4YWxvZy5SZWdpc3Ryb01hdGVyaWFpc1IJbWF0ZXJpYW'
    'lzEiYKA3ZpYRgHIAEoCzIULmZpeGFsb2cuUmVnaXN0cm9WaWFSA3ZpYRItCgVhY29lcxgIIAMo'
    'CzIXLmZpeGFsb2cuQWNhb01hbnV0ZW5jYW9SBWFjb2VzEjUKCWF2YWxpYWNhbxgJIAEoCzIXLm'
    'ZpeGFsb2cuQXZhbGlhY2FvRmluYWxSCWF2YWxpYWNhbxIrChFhc3NpbmF0dXJhX3Zpc3VhbBgK'
    'IAEoDFIQYXNzaW5hdHVyYVZpc3VhbBItChJhc3NpbmF0dXJhX2RpZ2l0YWwYCyABKAxSEWFzc2'
    'luYXR1cmFEaWdpdGFsEiMKDWlkX21hbnRlbmVkb3IYDCABKAlSDGlkTWFudGVuZWRvcg==');

@$core.Deprecated('Use registroMateriaisDescriptor instead')
const RegistroMateriais$json = {
  '1': 'RegistroMateriais',
  '2': [
    {
      '1': 'itens',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fixalog.MaterialInstalado',
      '10': 'itens'
    },
  ],
};

/// Descriptor for `RegistroMateriais`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registroMateriaisDescriptor = $convert.base64Decode(
    'ChFSZWdpc3Ryb01hdGVyaWFpcxIwCgVpdGVucxgBIAMoCzIaLmZpeGFsb2cuTWF0ZXJpYWxJbn'
    'N0YWxhZG9SBWl0ZW5z');

@$core.Deprecated('Use materialInstaladoDescriptor instead')
const MaterialInstalado$json = {
  '1': 'MaterialInstalado',
  '2': [
    {'1': 'id_instancia', '3': 1, '4': 1, '5': 9, '10': 'idInstancia'},
    {'1': 'tipo', '3': 2, '4': 1, '5': 9, '10': 'tipo'},
    {'1': 'marca', '3': 3, '4': 1, '5': 9, '10': 'marca'},
    {'1': 'lote', '3': 4, '4': 1, '5': 9, '10': 'lote'},
    {'1': 'liga', '3': 5, '4': 1, '5': 9, '10': 'liga'},
    {'1': 'validade', '3': 6, '4': 1, '5': 9, '10': 'validade'},
    {'1': 'quantidade', '3': 7, '4': 1, '5': 5, '10': 'quantidade'},
    {'1': 'foto', '3': 8, '4': 1, '5': 12, '10': 'foto'},
  ],
};

/// Descriptor for `MaterialInstalado`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List materialInstaladoDescriptor = $convert.base64Decode(
    'ChFNYXRlcmlhbEluc3RhbGFkbxIhCgxpZF9pbnN0YW5jaWEYASABKAlSC2lkSW5zdGFuY2lhEh'
    'IKBHRpcG8YAiABKAlSBHRpcG8SFAoFbWFyY2EYAyABKAlSBW1hcmNhEhIKBGxvdGUYBCABKAlS'
    'BGxvdGUSEgoEbGlnYRgFIAEoCVIEbGlnYRIaCgh2YWxpZGFkZRgGIAEoCVIIdmFsaWRhZGUSHg'
    'oKcXVhbnRpZGFkZRgHIAEoBVIKcXVhbnRpZGFkZRISCgRmb3RvGAggASgMUgRmb3Rv');

@$core.Deprecated('Use registroViaDescriptor instead')
const RegistroVia$json = {
  '1': 'RegistroVia',
  '2': [
    {'1': 'nome_via', '3': 1, '4': 1, '5': 9, '10': 'nomeVia'},
    {'1': 'pico', '3': 2, '4': 1, '5': 9, '10': 'pico'},
    {'1': 'setor', '3': 3, '4': 1, '5': 9, '10': 'setor'},
    {'1': 'latitude', '3': 4, '4': 1, '5': 1, '10': 'latitude'},
    {'1': 'longitude', '3': 5, '4': 1, '5': 1, '10': 'longitude'},
    {'1': 'altitude_m', '3': 6, '4': 1, '5': 1, '10': 'altitudeM'},
    {
      '1': 'permissao_conquistador',
      '3': 7,
      '4': 1,
      '5': 12,
      '10': 'permissaoConquistador'
    },
    {
      '1': 'nome_conquistador',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'nomeConquistador'
    },
  ],
};

/// Descriptor for `RegistroVia`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registroViaDescriptor = $convert.base64Decode(
    'CgtSZWdpc3Ryb1ZpYRIZCghub21lX3ZpYRgBIAEoCVIHbm9tZVZpYRISCgRwaWNvGAIgASgJUg'
    'RwaWNvEhQKBXNldG9yGAMgASgJUgVzZXRvchIaCghsYXRpdHVkZRgEIAEoAVIIbGF0aXR1ZGUS'
    'HAoJbG9uZ2l0dWRlGAUgASgBUglsb25naXR1ZGUSHQoKYWx0aXR1ZGVfbRgGIAEoAVIJYWx0aX'
    'R1ZGVNEjUKFnBlcm1pc3Nhb19jb25xdWlzdGFkb3IYByABKAxSFXBlcm1pc3Nhb0NvbnF1aXN0'
    'YWRvchIrChFub21lX2NvbnF1aXN0YWRvchgIIAEoCVIQbm9tZUNvbnF1aXN0YWRvcg==');

@$core.Deprecated('Use acaoManutencaoDescriptor instead')
const AcaoManutencao$json = {
  '1': 'AcaoManutencao',
  '2': [
    {'1': 'id_instancia', '3': 1, '4': 1, '5': 9, '10': 'idInstancia'},
    {'1': 'id_tipo_acao', '3': 2, '4': 1, '5': 9, '10': 'idTipoAcao'},
    {'1': 'utc_timestamp', '3': 3, '4': 1, '5': 3, '10': 'utcTimestamp'},
    {
      '1': 'inspecao',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.fixalog.DetalheInspecao',
      '9': 0,
      '10': 'inspecao'
    },
    {
      '1': 'novo_ponto',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.fixalog.DetalheNovoPonto',
      '9': 0,
      '10': 'novoPonto'
    },
    {
      '1': 'remocao_bloco',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.fixalog.DetalheRemocaoBloco',
      '9': 0,
      '10': 'remocaoBloco'
    },
    {
      '1': 'limpeza',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.fixalog.DetalheLimpeza',
      '9': 0,
      '10': 'limpeza'
    },
    {
      '1': 'outro',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.fixalog.DetalheAcaoCustomizada',
      '9': 0,
      '10': 'outro'
    },
  ],
  '8': [
    {'1': 'detalhes'},
  ],
};

/// Descriptor for `AcaoManutencao`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List acaoManutencaoDescriptor = $convert.base64Decode(
    'Cg5BY2FvTWFudXRlbmNhbxIhCgxpZF9pbnN0YW5jaWEYASABKAlSC2lkSW5zdGFuY2lhEiAKDG'
    'lkX3RpcG9fYWNhbxgCIAEoCVIKaWRUaXBvQWNhbxIjCg11dGNfdGltZXN0YW1wGAMgASgDUgx1'
    'dGNUaW1lc3RhbXASNgoIaW5zcGVjYW8YCiABKAsyGC5maXhhbG9nLkRldGFsaGVJbnNwZWNhb0'
    'gAUghpbnNwZWNhbxI6Cgpub3ZvX3BvbnRvGAsgASgLMhkuZml4YWxvZy5EZXRhbGhlTm92b1Bv'
    'bnRvSABSCW5vdm9Qb250bxJDCg1yZW1vY2FvX2Jsb2NvGAwgASgLMhwuZml4YWxvZy5EZXRhbG'
    'hlUmVtb2Nhb0Jsb2NvSABSDHJlbW9jYW9CbG9jbxIzCgdsaW1wZXphGA0gASgLMhcuZml4YWxv'
    'Zy5EZXRhbGhlTGltcGV6YUgAUgdsaW1wZXphEjcKBW91dHJvGA4gASgLMh8uZml4YWxvZy5EZX'
    'RhbGhlQWNhb0N1c3RvbWl6YWRhSABSBW91dHJvQgoKCGRldGFsaGVz');

@$core.Deprecated('Use detalheInspecaoDescriptor instead')
const DetalheInspecao$json = {
  '1': 'DetalheInspecao',
  '2': [
    {
      '1': 'tipo_ancoragem_original',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'tipoAncoragemOriginal'
    },
    {
      '1': 'material_original',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'materialOriginal'
    },
    {'1': 'foto_antes', '3': 3, '4': 1, '5': 12, '10': 'fotoAntes'},
    {'1': 'video_antes', '3': 4, '4': 1, '5': 12, '10': 'videoAntes'},
    {
      '1': 'resultado',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.fixalog.DetalheInspecao.ResultadoInspecao',
      '10': 'resultado'
    },
    {
      '1': 'substituicao',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.fixalog.DetalheSubstituicao',
      '10': 'substituicao'
    },
  ],
  '4': [DetalheInspecao_ResultadoInspecao$json],
};

@$core.Deprecated('Use detalheInspecaoDescriptor instead')
const DetalheInspecao_ResultadoInspecao$json = {
  '1': 'ResultadoInspecao',
  '2': [
    {'1': 'APROVADO', '2': 0},
    {'1': 'REAPERTO_REALIZADO', '2': 1},
    {'1': 'SUBSTITUIR', '2': 2},
  ],
};

/// Descriptor for `DetalheInspecao`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detalheInspecaoDescriptor = $convert.base64Decode(
    'Cg9EZXRhbGhlSW5zcGVjYW8SNgoXdGlwb19hbmNvcmFnZW1fb3JpZ2luYWwYASABKAlSFXRpcG'
    '9BbmNvcmFnZW1PcmlnaW5hbBIrChFtYXRlcmlhbF9vcmlnaW5hbBgCIAEoCVIQbWF0ZXJpYWxP'
    'cmlnaW5hbBIdCgpmb3RvX2FudGVzGAMgASgMUglmb3RvQW50ZXMSHwoLdmlkZW9fYW50ZXMYBC'
    'ABKAxSCnZpZGVvQW50ZXMSSAoJcmVzdWx0YWRvGAUgASgOMiouZml4YWxvZy5EZXRhbGhlSW5z'
    'cGVjYW8uUmVzdWx0YWRvSW5zcGVjYW9SCXJlc3VsdGFkbxJACgxzdWJzdGl0dWljYW8YBiABKA'
    'syHC5maXhhbG9nLkRldGFsaGVTdWJzdGl0dWljYW9SDHN1YnN0aXR1aWNhbyJJChFSZXN1bHRh'
    'ZG9JbnNwZWNhbxIMCghBUFJPVkFETxAAEhYKElJFQVBFUlRPX1JFQUxJWkFETxABEg4KClNVQl'
    'NUSVRVSVIQAg==');

@$core.Deprecated('Use detalheSubstituicaoDescriptor instead')
const DetalheSubstituicao$json = {
  '1': 'DetalheSubstituicao',
  '2': [
    {'1': 'estrategia', '3': 1, '4': 1, '5': 9, '10': 'estrategia'},
    {'1': 'foto_durante', '3': 2, '4': 1, '5': 12, '10': 'fotoDurante'},
    {'1': 'foto_depois', '3': 3, '4': 1, '5': 12, '10': 'fotoDepois'},
    {
      '1': 'ids_materiais_usados',
      '3': 4,
      '4': 3,
      '5': 9,
      '10': 'idsMateriaisUsados'
    },
    {'1': 'torque_nm', '3': 5, '4': 1, '5': 2, '10': 'torqueNm'},
    {
      '1': 'autorizacao_confirmada',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'autorizacaoConfirmada'
    },
    {
      '1': 'justificativa_novo_local',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'justificativaNovoLocal'
    },
    {'1': 'observacoes', '3': 8, '4': 1, '5': 9, '10': 'observacoes'},
  ],
};

/// Descriptor for `DetalheSubstituicao`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detalheSubstituicaoDescriptor = $convert.base64Decode(
    'ChNEZXRhbGhlU3Vic3RpdHVpY2FvEh4KCmVzdHJhdGVnaWEYASABKAlSCmVzdHJhdGVnaWESIQ'
    'oMZm90b19kdXJhbnRlGAIgASgMUgtmb3RvRHVyYW50ZRIfCgtmb3RvX2RlcG9pcxgDIAEoDFIK'
    'Zm90b0RlcG9pcxIwChRpZHNfbWF0ZXJpYWlzX3VzYWRvcxgEIAMoCVISaWRzTWF0ZXJpYWlzVX'
    'NhZG9zEhsKCXRvcnF1ZV9ubRgFIAEoAlIIdG9ycXVlTm0SNQoWYXV0b3JpemFjYW9fY29uZmly'
    'bWFkYRgGIAEoCFIVYXV0b3JpemFjYW9Db25maXJtYWRhEjgKGGp1c3RpZmljYXRpdmFfbm92b1'
    '9sb2NhbBgHIAEoCVIWanVzdGlmaWNhdGl2YU5vdm9Mb2NhbBIgCgtvYnNlcnZhY29lcxgIIAEo'
    'CVILb2JzZXJ2YWNvZXM=');

@$core.Deprecated('Use detalheNovoPontoDescriptor instead')
const DetalheNovoPonto$json = {
  '1': 'DetalheNovoPonto',
  '2': [
    {
      '1': 'autorizacao_confirmada',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'autorizacaoConfirmada'
    },
    {'1': 'latitude', '3': 2, '4': 1, '5': 1, '10': 'latitude'},
    {'1': 'longitude', '3': 3, '4': 1, '5': 1, '10': 'longitude'},
    {
      '1': 'foto_local_escolhido',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'fotoLocalEscolhido'
    },
    {'1': 'foto_instalado', '3': 5, '4': 1, '5': 12, '10': 'fotoInstalado'},
    {
      '1': 'ids_materiais_usados',
      '3': 6,
      '4': 3,
      '5': 9,
      '10': 'idsMateriaisUsados'
    },
    {'1': 'observacoes', '3': 7, '4': 1, '5': 9, '10': 'observacoes'},
  ],
};

/// Descriptor for `DetalheNovoPonto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detalheNovoPontoDescriptor = $convert.base64Decode(
    'ChBEZXRhbGhlTm92b1BvbnRvEjUKFmF1dG9yaXphY2FvX2NvbmZpcm1hZGEYASABKAhSFWF1dG'
    '9yaXphY2FvQ29uZmlybWFkYRIaCghsYXRpdHVkZRgCIAEoAVIIbGF0aXR1ZGUSHAoJbG9uZ2l0'
    'dWRlGAMgASgBUglsb25naXR1ZGUSMAoUZm90b19sb2NhbF9lc2NvbGhpZG8YBCABKAxSEmZvdG'
    '9Mb2NhbEVzY29saGlkbxIlCg5mb3RvX2luc3RhbGFkbxgFIAEoDFINZm90b0luc3RhbGFkbxIw'
    'ChRpZHNfbWF0ZXJpYWlzX3VzYWRvcxgGIAMoCVISaWRzTWF0ZXJpYWlzVXNhZG9zEiAKC29ic2'
    'VydmFjb2VzGAcgASgJUgtvYnNlcnZhY29lcw==');

@$core.Deprecated('Use detalheRemocaoBlocoDescriptor instead')
const DetalheRemocaoBloco$json = {
  '1': 'DetalheRemocaoBloco',
  '2': [
    {'1': 'foto_antes', '3': 1, '4': 1, '5': 12, '10': 'fotoAntes'},
    {'1': 'foto_depois', '3': 2, '4': 1, '5': 12, '10': 'fotoDepois'},
    {'1': 'observacoes', '3': 3, '4': 1, '5': 9, '10': 'observacoes'},
  ],
};

/// Descriptor for `DetalheRemocaoBloco`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detalheRemocaoBlocoDescriptor = $convert.base64Decode(
    'ChNEZXRhbGhlUmVtb2Nhb0Jsb2NvEh0KCmZvdG9fYW50ZXMYASABKAxSCWZvdG9BbnRlcxIfCg'
    'tmb3RvX2RlcG9pcxgCIAEoDFIKZm90b0RlcG9pcxIgCgtvYnNlcnZhY29lcxgDIAEoCVILb2Jz'
    'ZXJ2YWNvZXM=');

@$core.Deprecated('Use detalheLimpezaDescriptor instead')
const DetalheLimpeza$json = {
  '1': 'DetalheLimpeza',
  '2': [
    {'1': 'foto_antes', '3': 1, '4': 1, '5': 12, '10': 'fotoAntes'},
    {'1': 'foto_depois', '3': 2, '4': 1, '5': 12, '10': 'fotoDepois'},
    {'1': 'observacoes', '3': 3, '4': 1, '5': 9, '10': 'observacoes'},
  ],
};

/// Descriptor for `DetalheLimpeza`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detalheLimpezaDescriptor = $convert.base64Decode(
    'Cg5EZXRhbGhlTGltcGV6YRIdCgpmb3RvX2FudGVzGAEgASgMUglmb3RvQW50ZXMSHwoLZm90b1'
    '9kZXBvaXMYAiABKAxSCmZvdG9EZXBvaXMSIAoLb2JzZXJ2YWNvZXMYAyABKAlSC29ic2VydmFj'
    'b2Vz');

@$core.Deprecated('Use detalheAcaoCustomizadaDescriptor instead')
const DetalheAcaoCustomizada$json = {
  '1': 'DetalheAcaoCustomizada',
  '2': [
    {'1': 'descricao', '3': 1, '4': 1, '5': 9, '10': 'descricao'},
    {'1': 'foto', '3': 2, '4': 1, '5': 12, '10': 'foto'},
    {'1': 'video', '3': 3, '4': 1, '5': 12, '10': 'video'},
    {'1': 'observacoes', '3': 4, '4': 1, '5': 9, '10': 'observacoes'},
  ],
};

/// Descriptor for `DetalheAcaoCustomizada`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detalheAcaoCustomizadaDescriptor = $convert.base64Decode(
    'ChZEZXRhbGhlQWNhb0N1c3RvbWl6YWRhEhwKCWRlc2NyaWNhbxgBIAEoCVIJZGVzY3JpY2FvEh'
    'IKBGZvdG8YAiABKAxSBGZvdG8SFAoFdmlkZW8YAyABKAxSBXZpZGVvEiAKC29ic2VydmFjb2Vz'
    'GAQgASgJUgtvYnNlcnZhY29lcw==');

@$core.Deprecated('Use avaliacaoFinalDescriptor instead')
const AvaliacaoFinal$json = {
  '1': 'AvaliacaoFinal',
  '2': [
    {
      '1': 'resultado',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.fixalog.AvaliacaoFinal.ResultadoGeral',
      '10': 'resultado'
    },
    {'1': 'observacoes', '3': 2, '4': 1, '5': 9, '10': 'observacoes'},
  ],
  '4': [AvaliacaoFinal_ResultadoGeral$json],
};

@$core.Deprecated('Use avaliacaoFinalDescriptor instead')
const AvaliacaoFinal_ResultadoGeral$json = {
  '1': 'ResultadoGeral',
  '2': [
    {'1': 'APROVADO', '2': 0},
    {'1': 'APROVADO_COM_RESSALVAS', '2': 1},
    {'1': 'REQUER_NOVA_VISITA', '2': 2},
  ],
};

/// Descriptor for `AvaliacaoFinal`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List avaliacaoFinalDescriptor = $convert.base64Decode(
    'Cg5BdmFsaWFjYW9GaW5hbBJECglyZXN1bHRhZG8YASABKA4yJi5maXhhbG9nLkF2YWxpYWNhb0'
    'ZpbmFsLlJlc3VsdGFkb0dlcmFsUglyZXN1bHRhZG8SIAoLb2JzZXJ2YWNvZXMYAiABKAlSC29i'
    'c2VydmFjb2VzIlIKDlJlc3VsdGFkb0dlcmFsEgwKCEFQUk9WQURPEAASGgoWQVBST1ZBRE9fQ0'
    '9NX1JFU1NBTFZBUxABEhYKElJFUVVFUl9OT1ZBX1ZJU0lUQRAC');
