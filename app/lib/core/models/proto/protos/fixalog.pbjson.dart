// This is a generated file - do not edit.
//
// Generated from protos/fixalog.proto.

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
    'CglQcm90b2NvbG8SDgoCaWQYASABKAlSAmlkEhIKBG5vbWUYAiABKAlSBG5vbWUSJgoGY2FtcG'
    '9zGAMgAygLMg4uZml4YWxvZy5DYW1wb1IGY2FtcG9z');

@$core.Deprecated('Use campoDescriptor instead')
const Campo$json = {
  '1': 'Campo',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {
      '1': 'tipo',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.fixalog.Campo.Tipo',
      '10': 'tipo'
    },
    {'1': 'obrigatorio', '3': 4, '4': 1, '5': 8, '10': 'obrigatorio'},
    {'1': 'opcoes', '3': 5, '4': 3, '5': 9, '10': 'opcoes'},
  ],
  '4': [Campo_Tipo$json],
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
  ],
};

/// Descriptor for `Campo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List campoDescriptor = $convert.base64Decode(
    'CgVDYW1wbxIOCgJpZBgBIAEoCVICaWQSFAoFbGFiZWwYAiABKAlSBWxhYmVsEicKBHRpcG8YAy'
    'ABKA4yEy5maXhhbG9nLkNhbXBvLlRpcG9SBHRpcG8SIAoLb2JyaWdhdG9yaW8YBCABKAhSC29i'
    'cmlnYXRvcmlvEhYKBm9wY29lcxgFIAMoCVIGb3Bjb2VzIlYKBFRpcG8SCAoEVEVYVBAAEgoKBk'
    '5VTUJFUhABEgwKCERST1BET1dOEAISCQoFSU1BR0UQAxILCgdCT09MRUFOEAQSBwoDR1BTEAUS'
    'CQoFVklERU8QBg==');

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
