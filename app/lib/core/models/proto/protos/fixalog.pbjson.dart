// This is a generated file - do not edit.
//
// Generated from fixalog.proto.

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

@$core.Deprecated('Use protocoloDescriptor instead')
const Protocolo$json = {
  '1': 'Protocolo',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'nome', '3': 2, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'descricao', '3': 4, '4': 1, '5': 9, '10': 'descricao'},
    {
      '1': 'campos',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.fixalog.Campo',
      '10': 'campos'
    },
  ],
};

/// Descriptor for `Protocolo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protocoloDescriptor = $convert.base64Decode(
    'CglQcm90b2NvbG8SDgoCaWQYASABKAlSAmlkEhIKBG5vbWUYAiABKAlSBG5vbWUSHAoJZGVzY3'
    'JpY2FvGAQgASgJUglkZXNjcmljYW8SJgoGY2FtcG9zGAMgAygLMg4uZml4YWxvZy5DYW1wb1IG'
    'Y2FtcG9z');

@$core.Deprecated('Use opcaoDescriptor instead')
const Opcao$json = {
  '1': 'Opcao',
  '2': [
    {'1': 'valor', '3': 1, '4': 1, '5': 9, '10': 'valor'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'sublabel', '3': 3, '4': 1, '5': 9, '10': 'sublabel'},
    {'1': 'icon_name', '3': 4, '4': 1, '5': 9, '10': 'iconName'},
  ],
};

/// Descriptor for `Opcao`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List opcaoDescriptor = $convert.base64Decode(
    'CgVPcGNhbxIUCgV2YWxvchgBIAEoCVIFdmFsb3ISFAoFbGFiZWwYAiABKAlSBWxhYmVsEhoKCH'
    'N1YmxhYmVsGAMgASgJUghzdWJsYWJlbBIbCglpY29uX25hbWUYBCABKAlSCGljb25OYW1l');

@$core.Deprecated('Use campoDescriptor instead')
const Campo$json = {
  '1': 'Campo',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'sublabel', '3': 3, '4': 1, '5': 9, '10': 'sublabel'},
    {
      '1': 'tipo',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.fixalog.Campo.Tipo',
      '10': 'tipo'
    },
    {
      '1': 'ui_hint',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.fixalog.Campo.UIHint',
      '10': 'uiHint'
    },
    {'1': 'obrigatorio', '3': 6, '4': 1, '5': 8, '10': 'obrigatorio'},
    {
      '1': 'opcoes',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.fixalog.Opcao',
      '10': 'opcoes'
    },
  ],
  '4': [Campo_Tipo$json, Campo_UIHint$json],
};

@$core.Deprecated('Use campoDescriptor instead')
const Campo_Tipo$json = {
  '1': 'Tipo',
  '2': [
    {'1': 'TEXT', '2': 0},
    {'1': 'NUMBER', '2': 1},
    {'1': 'DROPDOWN', '2': 2},
    {'1': 'IMAGE', '2': 3},
    {'1': 'BOOLEAN', '2': 4},
    {'1': 'GPS', '2': 5},
    {'1': 'VIDEO', '2': 6},
    {'1': 'SIGNATURE', '2': 7},
  ],
};

@$core.Deprecated('Use campoDescriptor instead')
const Campo_UIHint$json = {
  '1': 'UIHint',
  '2': [
    {'1': 'DEFAULT', '2': 0},
    {'1': 'LARGE_TILES', '2': 1},
    {'1': 'CAMERA_ACTION', '2': 2},
  ],
};

/// Descriptor for `Campo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List campoDescriptor = $convert.base64Decode(
    'CgVDYW1wbxIOCgJpZBgBIAEoCVICaWQSFAoFbGFiZWwYAiABKAlSBWxhYmVsEhoKCHN1YmxhYm'
    'VsGAMgASgJUghzdWJsYWJlbBInCgR0aXBvGAQgASgOMhMuZml4YWxvZy5DYW1wby5UaXBvUgR0'
    'aXBvEi4KB3VpX2hpbnQYBSABKA4yFS5maXhhbG9nLkNhbXBvLlVJSGludFIGdWlIaW50EiAKC2'
    '9icmlnYXRvcmlvGAYgASgIUgtvYnJpZ2F0b3JpbxImCgZvcGNvZXMYByADKAsyDi5maXhhbG9n'
    'Lk9wY2FvUgZvcGNvZXMiZQoEVGlwbxIICgRURVhUEAASCgoGTlVNQkVSEAESDAoIRFJPUERPV0'
    '4QAhIJCgVJTUFHRRADEgsKB0JPT0xFQU4QBBIHCgNHUFMQBRIJCgVWSURFTxAGEg0KCVNJR05B'
    'VFVSRRAHIjkKBlVJSGludBILCgdERUZBVUxUEAASDwoLTEFSR0VfVElMRVMQARIRCg1DQU1FUk'
    'FfQUNUSU9OEAI=');

@$core.Deprecated('Use submissaoProtocoloDescriptor instead')
const SubmissaoProtocolo$json = {
  '1': 'SubmissaoProtocolo',
  '2': [
    {'1': 'id_sessao', '3': 1, '4': 1, '5': 9, '10': 'idSessao'},
    {'1': 'id_protocolo', '3': 2, '4': 1, '5': 9, '10': 'idProtocolo'},
    {'1': 'utc_timestamp_gps', '3': 3, '4': 1, '5': 3, '10': 'utcTimestampGps'},
    {
      '1': 'assinatura_visual',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'assinaturaVisual'
    },
    {
      '1': 'respostas',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.fixalog.RespostaCampo',
      '10': 'respostas'
    },
    {
      '1': 'digital_assinatura_do_hash',
      '3': 6,
      '4': 1,
      '5': 12,
      '10': 'digitalAssinaturaDoHash'
    },
  ],
};

/// Descriptor for `SubmissaoProtocolo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List submissaoProtocoloDescriptor = $convert.base64Decode(
    'ChJTdWJtaXNzYW9Qcm90b2NvbG8SGwoJaWRfc2Vzc2FvGAEgASgJUghpZFNlc3NhbxIhCgxpZF'
    '9wcm90b2NvbG8YAiABKAlSC2lkUHJvdG9jb2xvEioKEXV0Y190aW1lc3RhbXBfZ3BzGAMgASgD'
    'Ug91dGNUaW1lc3RhbXBHcHMSKwoRYXNzaW5hdHVyYV92aXN1YWwYBCABKAxSEGFzc2luYXR1cm'
    'FWaXN1YWwSNAoJcmVzcG9zdGFzGAUgAygLMhYuZml4YWxvZy5SZXNwb3N0YUNhbXBvUglyZXNw'
    'b3N0YXMSOwoaZGlnaXRhbF9hc3NpbmF0dXJhX2RvX2hhc2gYBiABKAxSF2RpZ2l0YWxBc3Npbm'
    'F0dXJhRG9IYXNo');

@$core.Deprecated('Use respostaCampoDescriptor instead')
const RespostaCampo$json = {
  '1': 'RespostaCampo',
  '2': [
    {'1': 'id_campo', '3': 1, '4': 1, '5': 9, '10': 'idCampo'},
    {'1': 'valor_texto', '3': 2, '4': 1, '5': 9, '10': 'valorTexto'},
    {'1': 'valor_midia', '3': 3, '4': 1, '5': 12, '10': 'valorMidia'},
  ],
};

/// Descriptor for `RespostaCampo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List respostaCampoDescriptor = $convert.base64Decode(
    'Cg1SZXNwb3N0YUNhbXBvEhkKCGlkX2NhbXBvGAEgASgJUgdpZENhbXBvEh8KC3ZhbG9yX3RleH'
    'RvGAIgASgJUgp2YWxvclRleHRvEh8KC3ZhbG9yX21pZGlhGAMgASgMUgp2YWxvck1pZGlh');
