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

@$core.Deprecated('Use arquivoImagemDescriptor instead')
const ArquivoImagem$json = {
  '1': 'ArquivoImagem',
  '2': [
    {'1': 'uuid', '3': 1, '4': 1, '5': 9, '10': 'uuid'},
    {'1': 'tipo_original', '3': 2, '4': 1, '5': 9, '10': 'tipoOriginal'},
    {'1': 'hash_original', '3': 3, '4': 1, '5': 9, '10': 'hashOriginal'},
    {'1': 'tipo_comprimido', '3': 4, '4': 1, '5': 9, '10': 'tipoComprimido'},
    {'1': 'hash_comprimido', '3': 5, '4': 1, '5': 9, '10': 'hashComprimido'},
    {
      '1': 'versao_compressao',
      '3': 6,
      '4': 1,
      '5': 5,
      '10': 'versaoCompressao'
    },
  ],
};

/// Descriptor for `ArquivoImagem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List arquivoImagemDescriptor = $convert.base64Decode(
    'Cg1BcnF1aXZvSW1hZ2VtEhIKBHV1aWQYASABKAlSBHV1aWQSIwoNdGlwb19vcmlnaW5hbBgCIA'
    'EoCVIMdGlwb09yaWdpbmFsEiMKDWhhc2hfb3JpZ2luYWwYAyABKAlSDGhhc2hPcmlnaW5hbBIn'
    'Cg90aXBvX2NvbXByaW1pZG8YBCABKAlSDnRpcG9Db21wcmltaWRvEicKD2hhc2hfY29tcHJpbW'
    'lkbxgFIAEoCVIOaGFzaENvbXByaW1pZG8SKwoRdmVyc2FvX2NvbXByZXNzYW8YBiABKAVSEHZl'
    'cnNhb0NvbXByZXNzYW8=');

@$core.Deprecated('Use arquivoVideoDescriptor instead')
const ArquivoVideo$json = {
  '1': 'ArquivoVideo',
  '2': [
    {'1': 'uuid', '3': 1, '4': 1, '5': 9, '10': 'uuid'},
    {'1': 'tipo_original', '3': 2, '4': 1, '5': 9, '10': 'tipoOriginal'},
    {'1': 'hash_original', '3': 3, '4': 1, '5': 9, '10': 'hashOriginal'},
    {'1': 'tipo_comprimido', '3': 4, '4': 1, '5': 9, '10': 'tipoComprimido'},
    {'1': 'hash_comprimido', '3': 5, '4': 1, '5': 9, '10': 'hashComprimido'},
    {
      '1': 'versao_compressao',
      '3': 6,
      '4': 1,
      '5': 5,
      '10': 'versaoCompressao'
    },
  ],
};

/// Descriptor for `ArquivoVideo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List arquivoVideoDescriptor = $convert.base64Decode(
    'CgxBcnF1aXZvVmlkZW8SEgoEdXVpZBgBIAEoCVIEdXVpZBIjCg10aXBvX29yaWdpbmFsGAIgAS'
    'gJUgx0aXBvT3JpZ2luYWwSIwoNaGFzaF9vcmlnaW5hbBgDIAEoCVIMaGFzaE9yaWdpbmFsEicK'
    'D3RpcG9fY29tcHJpbWlkbxgEIAEoCVIOdGlwb0NvbXByaW1pZG8SJwoPaGFzaF9jb21wcmltaW'
    'RvGAUgASgJUg5oYXNoQ29tcHJpbWlkbxIrChF2ZXJzYW9fY29tcHJlc3NhbxgGIAEoBVIQdmVy'
    'c2FvQ29tcHJlc3Nhbw==');

@$core.Deprecated('Use arquivoAudioDescriptor instead')
const ArquivoAudio$json = {
  '1': 'ArquivoAudio',
  '2': [
    {'1': 'uuid', '3': 1, '4': 1, '5': 9, '10': 'uuid'},
    {'1': 'tipo_original', '3': 2, '4': 1, '5': 9, '10': 'tipoOriginal'},
    {'1': 'hash_original', '3': 3, '4': 1, '5': 9, '10': 'hashOriginal'},
    {'1': 'tipo_comprimido', '3': 4, '4': 1, '5': 9, '10': 'tipoComprimido'},
    {'1': 'hash_comprimido', '3': 5, '4': 1, '5': 9, '10': 'hashComprimido'},
    {
      '1': 'versao_compressao',
      '3': 6,
      '4': 1,
      '5': 5,
      '10': 'versaoCompressao'
    },
  ],
};

/// Descriptor for `ArquivoAudio`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List arquivoAudioDescriptor = $convert.base64Decode(
    'CgxBcnF1aXZvQXVkaW8SEgoEdXVpZBgBIAEoCVIEdXVpZBIjCg10aXBvX29yaWdpbmFsGAIgAS'
    'gJUgx0aXBvT3JpZ2luYWwSIwoNaGFzaF9vcmlnaW5hbBgDIAEoCVIMaGFzaE9yaWdpbmFsEicK'
    'D3RpcG9fY29tcHJpbWlkbxgEIAEoCVIOdGlwb0NvbXByaW1pZG8SJwoPaGFzaF9jb21wcmltaW'
    'RvGAUgASgJUg5oYXNoQ29tcHJpbWlkbxIrChF2ZXJzYW9fY29tcHJlc3NhbxgGIAEoBVIQdmVy'
    'c2FvQ29tcHJlc3Nhbw==');

@$core.Deprecated('Use referenciaMidiaDescriptor instead')
const ReferenciaMidia$json = {
  '1': 'ReferenciaMidia',
  '2': [
    {
      '1': 'imagem',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ArquivoImagem',
      '9': 0,
      '10': 'imagem'
    },
    {
      '1': 'video',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ArquivoVideo',
      '9': 0,
      '10': 'video'
    },
    {
      '1': 'audio',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ArquivoAudio',
      '9': 0,
      '10': 'audio'
    },
  ],
  '8': [
    {'1': 'midia'},
  ],
};

/// Descriptor for `ReferenciaMidia`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List referenciaMidiaDescriptor = $convert.base64Decode(
    'Cg9SZWZlcmVuY2lhTWlkaWESMAoGaW1hZ2VtGAEgASgLMhYuZml4YWxvZy5BcnF1aXZvSW1hZ2'
    'VtSABSBmltYWdlbRItCgV2aWRlbxgCIAEoCzIVLmZpeGFsb2cuQXJxdWl2b1ZpZGVvSABSBXZp'
    'ZGVvEi0KBWF1ZGlvGAMgASgLMhUuZml4YWxvZy5BcnF1aXZvQXVkaW9IAFIFYXVkaW9CBwoFbW'
    'lkaWE=');

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
    {
      '1': 'attestation_token',
      '3': 99,
      '4': 1,
      '5': 9,
      '10': 'attestationToken'
    },
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
    'luYXR1cmFEaWdpdGFsEiMKDWlkX21hbnRlbmVkb3IYDCABKAlSDGlkTWFudGVuZWRvchIrChFh'
    'dHRlc3RhdGlvbl90b2tlbhhjIAEoCVIQYXR0ZXN0YXRpb25Ub2tlbg==');

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
    {
      '1': 'foto',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '10': 'foto'
    },
  ],
};

/// Descriptor for `MaterialInstalado`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List materialInstaladoDescriptor = $convert.base64Decode(
    'ChFNYXRlcmlhbEluc3RhbGFkbxIhCgxpZF9pbnN0YW5jaWEYASABKAlSC2lkSW5zdGFuY2lhEh'
    'IKBHRpcG8YAiABKAlSBHRpcG8SFAoFbWFyY2EYAyABKAlSBW1hcmNhEhIKBGxvdGUYBCABKAlS'
    'BGxvdGUSEgoEbGlnYRgFIAEoCVIEbGlnYRIaCgh2YWxpZGFkZRgGIAEoCVIIdmFsaWRhZGUSHg'
    'oKcXVhbnRpZGFkZRgHIAEoBVIKcXVhbnRpZGFkZRIsCgRmb3RvGAggASgLMhguZml4YWxvZy5S'
    'ZWZlcmVuY2lhTWlkaWFSBGZvdG8=');

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
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
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
    'R1ZGVNEk8KFnBlcm1pc3Nhb19jb25xdWlzdGFkb3IYByABKAsyGC5maXhhbG9nLlJlZmVyZW5j'
    'aWFNaWRpYVIVcGVybWlzc2FvQ29ucXVpc3RhZG9yEisKEW5vbWVfY29ucXVpc3RhZG9yGAggAS'
    'gJUhBub21lQ29ucXVpc3RhZG9y');

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
    {
      '1': 'foto_antes',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '10': 'fotoAntes'
    },
    {
      '1': 'video_antes',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '10': 'videoAntes'
    },
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
    'cmlnaW5hbBI3Cgpmb3RvX2FudGVzGAMgASgLMhguZml4YWxvZy5SZWZlcmVuY2lhTWlkaWFSCW'
    'ZvdG9BbnRlcxI5Cgt2aWRlb19hbnRlcxgEIAEoCzIYLmZpeGFsb2cuUmVmZXJlbmNpYU1pZGlh'
    'Ugp2aWRlb0FudGVzEkgKCXJlc3VsdGFkbxgFIAEoDjIqLmZpeGFsb2cuRGV0YWxoZUluc3BlY2'
    'FvLlJlc3VsdGFkb0luc3BlY2FvUglyZXN1bHRhZG8SQAoMc3Vic3RpdHVpY2FvGAYgASgLMhwu'
    'Zml4YWxvZy5EZXRhbGhlU3Vic3RpdHVpY2FvUgxzdWJzdGl0dWljYW8iSQoRUmVzdWx0YWRvSW'
    '5zcGVjYW8SDAoIQVBST1ZBRE8QABIWChJSRUFQRVJUT19SRUFMSVpBRE8QARIOCgpTVUJTVElU'
    'VUlSEAI=');

@$core.Deprecated('Use detalheSubstituicaoDescriptor instead')
const DetalheSubstituicao$json = {
  '1': 'DetalheSubstituicao',
  '2': [
    {'1': 'estrategia', '3': 1, '4': 1, '5': 9, '10': 'estrategia'},
    {
      '1': 'foto_durante',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '10': 'fotoDurante'
    },
    {
      '1': 'foto_depois',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '10': 'fotoDepois'
    },
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
    'ChNEZXRhbGhlU3Vic3RpdHVpY2FvEh4KCmVzdHJhdGVnaWEYASABKAlSCmVzdHJhdGVnaWESOw'
    'oMZm90b19kdXJhbnRlGAIgASgLMhguZml4YWxvZy5SZWZlcmVuY2lhTWlkaWFSC2ZvdG9EdXJh'
    'bnRlEjkKC2ZvdG9fZGVwb2lzGAMgASgLMhguZml4YWxvZy5SZWZlcmVuY2lhTWlkaWFSCmZvdG'
    '9EZXBvaXMSMAoUaWRzX21hdGVyaWFpc191c2Fkb3MYBCADKAlSEmlkc01hdGVyaWFpc1VzYWRv'
    'cxIbCgl0b3JxdWVfbm0YBSABKAJSCHRvcnF1ZU5tEjUKFmF1dG9yaXphY2FvX2NvbmZpcm1hZG'
    'EYBiABKAhSFWF1dG9yaXphY2FvQ29uZmlybWFkYRI4ChhqdXN0aWZpY2F0aXZhX25vdm9fbG9j'
    'YWwYByABKAlSFmp1c3RpZmljYXRpdmFOb3ZvTG9jYWwSIAoLb2JzZXJ2YWNvZXMYCCABKAlSC2'
    '9ic2VydmFjb2Vz');

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
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '10': 'fotoLocalEscolhido'
    },
    {
      '1': 'foto_instalado',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '10': 'fotoInstalado'
    },
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
    'dWRlGAMgASgBUglsb25naXR1ZGUSSgoUZm90b19sb2NhbF9lc2NvbGhpZG8YBCABKAsyGC5maX'
    'hhbG9nLlJlZmVyZW5jaWFNaWRpYVISZm90b0xvY2FsRXNjb2xoaWRvEj8KDmZvdG9faW5zdGFs'
    'YWRvGAUgASgLMhguZml4YWxvZy5SZWZlcmVuY2lhTWlkaWFSDWZvdG9JbnN0YWxhZG8SMAoUaW'
    'RzX21hdGVyaWFpc191c2Fkb3MYBiADKAlSEmlkc01hdGVyaWFpc1VzYWRvcxIgCgtvYnNlcnZh'
    'Y29lcxgHIAEoCVILb2JzZXJ2YWNvZXM=');

@$core.Deprecated('Use detalheRemocaoBlocoDescriptor instead')
const DetalheRemocaoBloco$json = {
  '1': 'DetalheRemocaoBloco',
  '2': [
    {
      '1': 'foto_antes',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '10': 'fotoAntes'
    },
    {
      '1': 'foto_depois',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '10': 'fotoDepois'
    },
    {'1': 'observacoes', '3': 3, '4': 1, '5': 9, '10': 'observacoes'},
  ],
};

/// Descriptor for `DetalheRemocaoBloco`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detalheRemocaoBlocoDescriptor = $convert.base64Decode(
    'ChNEZXRhbGhlUmVtb2Nhb0Jsb2NvEjcKCmZvdG9fYW50ZXMYASABKAsyGC5maXhhbG9nLlJlZm'
    'VyZW5jaWFNaWRpYVIJZm90b0FudGVzEjkKC2ZvdG9fZGVwb2lzGAIgASgLMhguZml4YWxvZy5S'
    'ZWZlcmVuY2lhTWlkaWFSCmZvdG9EZXBvaXMSIAoLb2JzZXJ2YWNvZXMYAyABKAlSC29ic2Vydm'
    'Fjb2Vz');

@$core.Deprecated('Use detalheLimpezaDescriptor instead')
const DetalheLimpeza$json = {
  '1': 'DetalheLimpeza',
  '2': [
    {
      '1': 'foto_antes',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '10': 'fotoAntes'
    },
    {
      '1': 'foto_depois',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '10': 'fotoDepois'
    },
    {'1': 'observacoes', '3': 3, '4': 1, '5': 9, '10': 'observacoes'},
  ],
};

/// Descriptor for `DetalheLimpeza`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detalheLimpezaDescriptor = $convert.base64Decode(
    'Cg5EZXRhbGhlTGltcGV6YRI3Cgpmb3RvX2FudGVzGAEgASgLMhguZml4YWxvZy5SZWZlcmVuY2'
    'lhTWlkaWFSCWZvdG9BbnRlcxI5Cgtmb3RvX2RlcG9pcxgCIAEoCzIYLmZpeGFsb2cuUmVmZXJl'
    'bmNpYU1pZGlhUgpmb3RvRGVwb2lzEiAKC29ic2VydmFjb2VzGAMgASgJUgtvYnNlcnZhY29lcw'
    '==');

@$core.Deprecated('Use detalheAcaoCustomizadaDescriptor instead')
const DetalheAcaoCustomizada$json = {
  '1': 'DetalheAcaoCustomizada',
  '2': [
    {'1': 'descricao', '3': 1, '4': 1, '5': 9, '10': 'descricao'},
    {
      '1': 'foto',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '10': 'foto'
    },
    {
      '1': 'video',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '10': 'video'
    },
    {'1': 'observacoes', '3': 4, '4': 1, '5': 9, '10': 'observacoes'},
  ],
};

/// Descriptor for `DetalheAcaoCustomizada`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detalheAcaoCustomizadaDescriptor = $convert.base64Decode(
    'ChZEZXRhbGhlQWNhb0N1c3RvbWl6YWRhEhwKCWRlc2NyaWNhbxgBIAEoCVIJZGVzY3JpY2FvEi'
    'wKBGZvdG8YAiABKAsyGC5maXhhbG9nLlJlZmVyZW5jaWFNaWRpYVIEZm90bxIuCgV2aWRlbxgD'
    'IAEoCzIYLmZpeGFsb2cuUmVmZXJlbmNpYU1pZGlhUgV2aWRlbxIgCgtvYnNlcnZhY29lcxgEIA'
    'EoCVILb2JzZXJ2YWNvZXM=');

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
