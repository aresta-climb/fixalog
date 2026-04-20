// This is a generated file - do not edit.
//
// Generated from wizard.proto.

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

@$core.Deprecated('Use definicaoProtocoloDescriptor instead')
const DefinicaoProtocolo$json = {
  '1': 'DefinicaoProtocolo',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'nome', '3': 2, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'descricao', '3': 3, '4': 1, '5': 9, '10': 'descricao'},
    {'1': 'versao', '3': 4, '4': 1, '5': 9, '10': 'versao'},
    {
      '1': 'blocos',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.fixalog.Bloco',
      '10': 'blocos'
    },
  ],
};

/// Descriptor for `DefinicaoProtocolo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List definicaoProtocoloDescriptor = $convert.base64Decode(
    'ChJEZWZpbmljYW9Qcm90b2NvbG8SDgoCaWQYASABKAlSAmlkEhIKBG5vbWUYAiABKAlSBG5vbW'
    'USHAoJZGVzY3JpY2FvGAMgASgJUglkZXNjcmljYW8SFgoGdmVyc2FvGAQgASgJUgZ2ZXJzYW8S'
    'JgoGYmxvY29zGAUgAygLMg4uZml4YWxvZy5CbG9jb1IGYmxvY29z');

@$core.Deprecated('Use blocoDescriptor instead')
const Bloco$json = {
  '1': 'Bloco',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'titulo', '3': 2, '4': 1, '5': 9, '10': 'titulo'},
    {'1': 'subtitulo', '3': 3, '4': 1, '5': 9, '10': 'subtitulo'},
    {
      '1': 'steps',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.fixalog.Step',
      '10': 'steps'
    },
  ],
};

/// Descriptor for `Bloco`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blocoDescriptor = $convert.base64Decode(
    'CgVCbG9jbxIOCgJpZBgBIAEoCVICaWQSFgoGdGl0dWxvGAIgASgJUgZ0aXR1bG8SHAoJc3VidG'
    'l0dWxvGAMgASgJUglzdWJ0aXR1bG8SIwoFc3RlcHMYBCADKAsyDS5maXhhbG9nLlN0ZXBSBXN0'
    'ZXBz');

@$core.Deprecated('Use conteudoStepDescriptor instead')
const ConteudoStep$json = {
  '1': 'ConteudoStep',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'instrucao',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fixalog.StepInstrucao',
      '9': 0,
      '10': 'instrucao'
    },
    {
      '1': 'campo_simples',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.fixalog.StepCampoSimples',
      '9': 0,
      '10': 'campoSimples'
    },
    {
      '1': 'selecao_ramo',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.fixalog.StepSelecaoRamo',
      '9': 0,
      '10': 'selecaoRamo'
    },
    {
      '1': 'lista_acoes',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.fixalog.StepListaAcoes',
      '9': 0,
      '10': 'listaAcoes'
    },
    {
      '1': 'ref_materiais',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.fixalog.StepRefMateriais',
      '9': 0,
      '10': 'refMateriais'
    },
  ],
  '8': [
    {'1': 'tipo'},
  ],
};

/// Descriptor for `ConteudoStep`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conteudoStepDescriptor = $convert.base64Decode(
    'CgxDb250ZXVkb1N0ZXASDgoCaWQYASABKAlSAmlkEjYKCWluc3RydWNhbxgCIAEoCzIWLmZpeG'
    'Fsb2cuU3RlcEluc3RydWNhb0gAUglpbnN0cnVjYW8SQAoNY2FtcG9fc2ltcGxlcxgDIAEoCzIZ'
    'LmZpeGFsb2cuU3RlcENhbXBvU2ltcGxlc0gAUgxjYW1wb1NpbXBsZXMSPQoMc2VsZWNhb19yYW'
    '1vGAQgASgLMhguZml4YWxvZy5TdGVwU2VsZWNhb1JhbW9IAFILc2VsZWNhb1JhbW8SOgoLbGlz'
    'dGFfYWNvZXMYBSABKAsyFy5maXhhbG9nLlN0ZXBMaXN0YUFjb2VzSABSCmxpc3RhQWNvZXMSQA'
    'oNcmVmX21hdGVyaWFpcxgGIAEoCzIZLmZpeGFsb2cuU3RlcFJlZk1hdGVyaWFpc0gAUgxyZWZN'
    'YXRlcmlhaXNCBgoEdGlwbw==');

@$core.Deprecated('Use stepDescriptor instead')
const Step$json = {
  '1': 'Step',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'conteudos',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fixalog.ConteudoStep',
      '10': 'conteudos'
    },
  ],
};

/// Descriptor for `Step`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stepDescriptor = $convert.base64Decode(
    'CgRTdGVwEg4KAmlkGAEgASgJUgJpZBIzCgljb250ZXVkb3MYAiADKAsyFS5maXhhbG9nLkNvbn'
    'RldWRvU3RlcFIJY29udGV1ZG9z');

@$core.Deprecated('Use stepInstrucaoDescriptor instead')
const StepInstrucao$json = {
  '1': 'StepInstrucao',
  '2': [
    {'1': 'titulo', '3': 1, '4': 1, '5': 9, '10': 'titulo'},
    {'1': 'corpo', '3': 2, '4': 1, '5': 9, '10': 'corpo'},
    {'1': 'icon_name', '3': 3, '4': 1, '5': 9, '10': 'iconName'},
    {
      '1': 'nivel_alerta',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.fixalog.StepInstrucao.NivelAlerta',
      '10': 'nivelAlerta'
    },
  ],
  '4': [StepInstrucao_NivelAlerta$json],
};

@$core.Deprecated('Use stepInstrucaoDescriptor instead')
const StepInstrucao_NivelAlerta$json = {
  '1': 'NivelAlerta',
  '2': [
    {'1': 'INFO', '2': 0},
    {'1': 'ATENCAO', '2': 1},
    {'1': 'PERIGO', '2': 2},
  ],
};

/// Descriptor for `StepInstrucao`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stepInstrucaoDescriptor = $convert.base64Decode(
    'Cg1TdGVwSW5zdHJ1Y2FvEhYKBnRpdHVsbxgBIAEoCVIGdGl0dWxvEhQKBWNvcnBvGAIgASgJUg'
    'Vjb3JwbxIbCglpY29uX25hbWUYAyABKAlSCGljb25OYW1lEkUKDG5pdmVsX2FsZXJ0YRgEIAEo'
    'DjIiLmZpeGFsb2cuU3RlcEluc3RydWNhby5OaXZlbEFsZXJ0YVILbml2ZWxBbGVydGEiMAoLTm'
    'l2ZWxBbGVydGESCAoESU5GTxAAEgsKB0FURU5DQU8QARIKCgZQRVJJR08QAg==');

@$core.Deprecated('Use stepCampoSimplesDescriptor instead')
const StepCampoSimples$json = {
  '1': 'StepCampoSimples',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'sublabel', '3': 2, '4': 1, '5': 9, '10': 'sublabel'},
    {
      '1': 'tipo',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.fixalog.StepCampoSimples.TipoCampo',
      '10': 'tipo'
    },
    {
      '1': 'ui_hint',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.fixalog.StepCampoSimples.UiHint',
      '10': 'uiHint'
    },
    {'1': 'obrigatorio', '3': 5, '4': 1, '5': 8, '10': 'obrigatorio'},
    {
      '1': 'opcoes',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.fixalog.OpcaoCampo',
      '10': 'opcoes'
    },
  ],
  '4': [StepCampoSimples_TipoCampo$json, StepCampoSimples_UiHint$json],
};

@$core.Deprecated('Use stepCampoSimplesDescriptor instead')
const StepCampoSimples_TipoCampo$json = {
  '1': 'TipoCampo',
  '2': [
    {'1': 'TEXT', '2': 0},
    {'1': 'NUMBER', '2': 1},
    {'1': 'DROPDOWN', '2': 2},
    {'1': 'IMAGE', '2': 3},
    {'1': 'BOOLEAN', '2': 4},
    {'1': 'GPS', '2': 5},
    {'1': 'VIDEO', '2': 6},
    {'1': 'SIGNATURE', '2': 7},
    {'1': 'DATE', '2': 8},
  ],
};

@$core.Deprecated('Use stepCampoSimplesDescriptor instead')
const StepCampoSimples_UiHint$json = {
  '1': 'UiHint',
  '2': [
    {'1': 'DEFAULT', '2': 0},
    {'1': 'LARGE_TILES', '2': 1},
    {'1': 'CAMERA_ACTION', '2': 2},
    {'1': 'TEXT_AREA', '2': 3},
  ],
};

/// Descriptor for `StepCampoSimples`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stepCampoSimplesDescriptor = $convert.base64Decode(
    'ChBTdGVwQ2FtcG9TaW1wbGVzEhQKBWxhYmVsGAEgASgJUgVsYWJlbBIaCghzdWJsYWJlbBgCIA'
    'EoCVIIc3VibGFiZWwSNwoEdGlwbxgDIAEoDjIjLmZpeGFsb2cuU3RlcENhbXBvU2ltcGxlcy5U'
    'aXBvQ2FtcG9SBHRpcG8SOQoHdWlfaGludBgEIAEoDjIgLmZpeGFsb2cuU3RlcENhbXBvU2ltcG'
    'xlcy5VaUhpbnRSBnVpSGludBIgCgtvYnJpZ2F0b3JpbxgFIAEoCFILb2JyaWdhdG9yaW8SKwoG'
    'b3Bjb2VzGAYgAygLMhMuZml4YWxvZy5PcGNhb0NhbXBvUgZvcGNvZXMidAoJVGlwb0NhbXBvEg'
    'gKBFRFWFQQABIKCgZOVU1CRVIQARIMCghEUk9QRE9XThACEgkKBUlNQUdFEAMSCwoHQk9PTEVB'
    'ThAEEgcKA0dQUxAFEgkKBVZJREVPEAYSDQoJU0lHTkFUVVJFEAcSCAoEREFURRAIIkgKBlVpSG'
    'ludBILCgdERUZBVUxUEAASDwoLTEFSR0VfVElMRVMQARIRCg1DQU1FUkFfQUNUSU9OEAISDQoJ'
    'VEVYVF9BUkVBEAM=');

@$core.Deprecated('Use opcaoCampoDescriptor instead')
const OpcaoCampo$json = {
  '1': 'OpcaoCampo',
  '2': [
    {'1': 'valor', '3': 1, '4': 1, '5': 9, '10': 'valor'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'sublabel', '3': 3, '4': 1, '5': 9, '10': 'sublabel'},
    {'1': 'icon_name', '3': 4, '4': 1, '5': 9, '10': 'iconName'},
  ],
};

/// Descriptor for `OpcaoCampo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List opcaoCampoDescriptor = $convert.base64Decode(
    'CgpPcGNhb0NhbXBvEhQKBXZhbG9yGAEgASgJUgV2YWxvchIUCgVsYWJlbBgCIAEoCVIFbGFiZW'
    'wSGgoIc3VibGFiZWwYAyABKAlSCHN1YmxhYmVsEhsKCWljb25fbmFtZRgEIAEoCVIIaWNvbk5h'
    'bWU=');

@$core.Deprecated('Use stepSelecaoRamoDescriptor instead')
const StepSelecaoRamo$json = {
  '1': 'StepSelecaoRamo',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'sublabel', '3': 2, '4': 1, '5': 9, '10': 'sublabel'},
    {'1': 'obrigatorio', '3': 3, '4': 1, '5': 8, '10': 'obrigatorio'},
    {
      '1': 'ramos',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.fixalog.Ramo',
      '10': 'ramos'
    },
  ],
};

/// Descriptor for `StepSelecaoRamo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stepSelecaoRamoDescriptor = $convert.base64Decode(
    'Cg9TdGVwU2VsZWNhb1JhbW8SFAoFbGFiZWwYASABKAlSBWxhYmVsEhoKCHN1YmxhYmVsGAIgAS'
    'gJUghzdWJsYWJlbBIgCgtvYnJpZ2F0b3JpbxgDIAEoCFILb2JyaWdhdG9yaW8SIwoFcmFtb3MY'
    'BCADKAsyDS5maXhhbG9nLlJhbW9SBXJhbW9z');

@$core.Deprecated('Use ramoDescriptor instead')
const Ramo$json = {
  '1': 'Ramo',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'sublabel', '3': 3, '4': 1, '5': 9, '10': 'sublabel'},
    {'1': 'icon_name', '3': 4, '4': 1, '5': 9, '10': 'iconName'},
    {
      '1': 'steps',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.fixalog.Step',
      '10': 'steps'
    },
  ],
};

/// Descriptor for `Ramo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ramoDescriptor = $convert.base64Decode(
    'CgRSYW1vEg4KAmlkGAEgASgJUgJpZBIUCgVsYWJlbBgCIAEoCVIFbGFiZWwSGgoIc3VibGFiZW'
    'wYAyABKAlSCHN1YmxhYmVsEhsKCWljb25fbmFtZRgEIAEoCVIIaWNvbk5hbWUSIwoFc3RlcHMY'
    'BSADKAsyDS5maXhhbG9nLlN0ZXBSBXN0ZXBz');

@$core.Deprecated('Use stepListaAcoesDescriptor instead')
const StepListaAcoes$json = {
  '1': 'StepListaAcoes',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'sublabel', '3': 2, '4': 1, '5': 9, '10': 'sublabel'},
    {'1': 'minimo', '3': 3, '4': 1, '5': 5, '10': 'minimo'},
    {'1': 'maximo', '3': 4, '4': 1, '5': 5, '10': 'maximo'},
    {
      '1': 'tipos_disponiveis',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.fixalog.TipoAcao',
      '10': 'tiposDisponiveis'
    },
  ],
};

/// Descriptor for `StepListaAcoes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stepListaAcoesDescriptor = $convert.base64Decode(
    'Cg5TdGVwTGlzdGFBY29lcxIUCgVsYWJlbBgBIAEoCVIFbGFiZWwSGgoIc3VibGFiZWwYAiABKA'
    'lSCHN1YmxhYmVsEhYKBm1pbmltbxgDIAEoBVIGbWluaW1vEhYKBm1heGltbxgEIAEoBVIGbWF4'
    'aW1vEj4KEXRpcG9zX2Rpc3Bvbml2ZWlzGAUgAygLMhEuZml4YWxvZy5UaXBvQWNhb1IQdGlwb3'
    'NEaXNwb25pdmVpcw==');

@$core.Deprecated('Use tipoAcaoDescriptor instead')
const TipoAcao$json = {
  '1': 'TipoAcao',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'sublabel', '3': 3, '4': 1, '5': 9, '10': 'sublabel'},
    {'1': 'icon_name', '3': 4, '4': 1, '5': 9, '10': 'iconName'},
    {
      '1': 'steps',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.fixalog.Step',
      '10': 'steps'
    },
  ],
};

/// Descriptor for `TipoAcao`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tipoAcaoDescriptor = $convert.base64Decode(
    'CghUaXBvQWNhbxIOCgJpZBgBIAEoCVICaWQSFAoFbGFiZWwYAiABKAlSBWxhYmVsEhoKCHN1Ym'
    'xhYmVsGAMgASgJUghzdWJsYWJlbBIbCglpY29uX25hbWUYBCABKAlSCGljb25OYW1lEiMKBXN0'
    'ZXBzGAUgAygLMg0uZml4YWxvZy5TdGVwUgVzdGVwcw==');

@$core.Deprecated('Use stepRefMateriaisDescriptor instead')
const StepRefMateriais$json = {
  '1': 'StepRefMateriais',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'sublabel', '3': 2, '4': 1, '5': 9, '10': 'sublabel'},
    {'1': 'id_step_materiais', '3': 3, '4': 1, '5': 9, '10': 'idStepMateriais'},
    {'1': 'obrigatorio', '3': 4, '4': 1, '5': 8, '10': 'obrigatorio'},
  ],
};

/// Descriptor for `StepRefMateriais`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stepRefMateriaisDescriptor = $convert.base64Decode(
    'ChBTdGVwUmVmTWF0ZXJpYWlzEhQKBWxhYmVsGAEgASgJUgVsYWJlbBIaCghzdWJsYWJlbBgCIA'
    'EoCVIIc3VibGFiZWwSKgoRaWRfc3RlcF9tYXRlcmlhaXMYAyABKAlSD2lkU3RlcE1hdGVyaWFp'
    'cxIgCgtvYnJpZ2F0b3JpbxgEIAEoCFILb2JyaWdhdG9yaW8=');
