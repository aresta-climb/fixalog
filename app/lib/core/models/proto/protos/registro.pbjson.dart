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

@$core.Deprecated('Use listaRespostasDescriptor instead')
const ListaRespostas$json = {
  '1': 'ListaRespostas',
  '2': [
    {
      '1': 'valores',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fixalog.Resposta',
      '10': 'valores'
    },
  ],
};

/// Descriptor for `ListaRespostas`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listaRespostasDescriptor = $convert.base64Decode(
    'Cg5MaXN0YVJlc3Bvc3RhcxIrCgd2YWxvcmVzGAEgAygLMhEuZml4YWxvZy5SZXNwb3N0YVIHdm'
    'Fsb3Jlcw==');

@$core.Deprecated('Use respostaDescriptor instead')
const Resposta$json = {
  '1': 'Resposta',
  '2': [
    {'1': 'texto', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'texto'},
    {'1': 'numero', '3': 2, '4': 1, '5': 1, '9': 0, '10': 'numero'},
    {'1': 'inteiro', '3': 3, '4': 1, '5': 3, '9': 0, '10': 'inteiro'},
    {'1': 'booleano', '3': 4, '4': 1, '5': 8, '9': 0, '10': 'booleano'},
    {
      '1': 'midia',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ReferenciaMidia',
      '9': 0,
      '10': 'midia'
    },
    {
      '1': 'lista',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.fixalog.ListaRespostas',
      '9': 0,
      '10': 'lista'
    },
  ],
  '8': [
    {'1': 'valor'},
  ],
};

/// Descriptor for `Resposta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List respostaDescriptor = $convert.base64Decode(
    'CghSZXNwb3N0YRIWCgV0ZXh0bxgBIAEoCUgAUgV0ZXh0bxIYCgZudW1lcm8YAiABKAFIAFIGbn'
    'VtZXJvEhoKB2ludGVpcm8YAyABKANIAFIHaW50ZWlybxIcCghib29sZWFubxgEIAEoCEgAUghi'
    'b29sZWFubxIwCgVtaWRpYRgFIAEoCzIYLmZpeGFsb2cuUmVmZXJlbmNpYU1pZGlhSABSBW1pZG'
    'lhEi8KBWxpc3RhGAYgASgLMhcuZml4YWxvZy5MaXN0YVJlc3Bvc3Rhc0gAUgVsaXN0YUIHCgV2'
    'YWxvcg==');

@$core.Deprecated('Use grupoRepetidoDescriptor instead')
const GrupoRepetido$json = {
  '1': 'GrupoRepetido',
  '2': [
    {'1': 'id_lista', '3': 1, '4': 1, '5': 9, '10': 'idLista'},
    {'1': 'id_item', '3': 2, '4': 1, '5': 9, '10': 'idItem'},
    {'1': 'id_tipo', '3': 3, '4': 1, '5': 9, '10': 'idTipo'},
    {
      '1': 'respostas_item',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.fixalog.GrupoRepetido.RespostasItemEntry',
      '10': 'respostasItem'
    },
  ],
  '3': [GrupoRepetido_RespostasItemEntry$json],
};

@$core.Deprecated('Use grupoRepetidoDescriptor instead')
const GrupoRepetido_RespostasItemEntry$json = {
  '1': 'RespostasItemEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fixalog.Resposta',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `GrupoRepetido`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grupoRepetidoDescriptor = $convert.base64Decode(
    'Cg1HcnVwb1JlcGV0aWRvEhkKCGlkX2xpc3RhGAEgASgJUgdpZExpc3RhEhcKB2lkX2l0ZW0YAi'
    'ABKAlSBmlkSXRlbRIXCgdpZF90aXBvGAMgASgJUgZpZFRpcG8SUAoOcmVzcG9zdGFzX2l0ZW0Y'
    'BCADKAsyKS5maXhhbG9nLkdydXBvUmVwZXRpZG8uUmVzcG9zdGFzSXRlbUVudHJ5Ug1yZXNwb3'
    'N0YXNJdGVtGlMKElJlc3Bvc3Rhc0l0ZW1FbnRyeRIQCgNrZXkYASABKAlSA2tleRInCgV2YWx1'
    'ZRgCIAEoCzIRLmZpeGFsb2cuUmVzcG9zdGFSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use registroDescriptor instead')
const Registro$json = {
  '1': 'Registro',
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
      '1': 'assinatura_visual',
      '3': 6,
      '4': 1,
      '5': 12,
      '10': 'assinaturaVisual'
    },
    {
      '1': 'assinatura_digital',
      '3': 7,
      '4': 1,
      '5': 12,
      '10': 'assinaturaDigital'
    },
    {'1': 'id_mantenedor', '3': 8, '4': 1, '5': 9, '10': 'idMantenedor'},
    {
      '1': 'attestation_token',
      '3': 9,
      '4': 1,
      '5': 9,
      '10': 'attestationToken'
    },
    {
      '1': 'respostas',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.fixalog.Registro.RespostasEntry',
      '10': 'respostas'
    },
    {
      '1': 'listas',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.fixalog.GrupoRepetido',
      '10': 'listas'
    },
    {'1': 'yaml_conteudo', '3': 12, '4': 1, '5': 9, '10': 'yamlConteudo'},
  ],
  '3': [Registro_RespostasEntry$json],
};

@$core.Deprecated('Use registroDescriptor instead')
const Registro_RespostasEntry$json = {
  '1': 'RespostasEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fixalog.Resposta',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `Registro`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registroDescriptor = $convert.base64Decode(
    'CghSZWdpc3RybxIbCglpZF9zZXNzYW8YASABKAlSCGlkU2Vzc2FvEiEKDGlkX3Byb3RvY29sbx'
    'gCIAEoCVILaWRQcm90b2NvbG8SKQoQdmVyc2FvX3Byb3RvY29sbxgDIAEoCVIPdmVyc2FvUHJv'
    'dG9jb2xvEjAKFHV0Y190aW1lc3RhbXBfaW5pY2lvGAQgASgDUhJ1dGNUaW1lc3RhbXBJbmljaW'
    '8SKgoRdXRjX3RpbWVzdGFtcF9maW0YBSABKANSD3V0Y1RpbWVzdGFtcEZpbRIrChFhc3NpbmF0'
    'dXJhX3Zpc3VhbBgGIAEoDFIQYXNzaW5hdHVyYVZpc3VhbBItChJhc3NpbmF0dXJhX2RpZ2l0YW'
    'wYByABKAxSEWFzc2luYXR1cmFEaWdpdGFsEiMKDWlkX21hbnRlbmVkb3IYCCABKAlSDGlkTWFu'
    'dGVuZWRvchIrChFhdHRlc3RhdGlvbl90b2tlbhgJIAEoCVIQYXR0ZXN0YXRpb25Ub2tlbhI+Cg'
    'lyZXNwb3N0YXMYCiADKAsyIC5maXhhbG9nLlJlZ2lzdHJvLlJlc3Bvc3Rhc0VudHJ5UglyZXNw'
    'b3N0YXMSLgoGbGlzdGFzGAsgAygLMhYuZml4YWxvZy5HcnVwb1JlcGV0aWRvUgZsaXN0YXMSIw'
    'oNeWFtbF9jb250ZXVkbxgMIAEoCVIMeWFtbENvbnRldWRvGk8KDlJlc3Bvc3Rhc0VudHJ5EhAK'
    'A2tleRgBIAEoCVIDa2V5EicKBXZhbHVlGAIgASgLMhEuZml4YWxvZy5SZXNwb3N0YVIFdmFsdW'
    'U6AjgB');
