// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/proto/protos/registro.pb.dart';
import '../models/proto/protos/wizard.pb.dart';
import 'protocol_parser.dart';

/// Função de migração que transforma um [Registro] de uma versão inteira `v` para `v + 1`.
typedef PassoMigracaoProtocolo = void Function(Registro registro);

/// Exceção lançada quando o usuário tenta abrir para edição ou duplicação um [Registro]
/// cuja versão do protocolo é superior à versão suportada pelo aplicativo atual.
class ExcecaoVersaoProtocoloNaoSuportada implements Exception {
  final String idProtocolo;
  final int versaoRegistro;
  final int versaoSuportada;

  const ExcecaoVersaoProtocoloNaoSuportada({
    required this.idProtocolo,
    required this.versaoRegistro,
    required this.versaoSuportada,
  });

  @override
  String toString() =>
      "O relatório utiliza a versão $versaoRegistro do protocolo '$idProtocolo', que é mais recente que a versão suportada por este aplicativo (versão $versaoSuportada). Atualize o aplicativo para editar ou duplicar este relatório.";
}

/// Serviço responsável pela normalização de identificadores legados, cálculo de assinatura
/// estrutural de protocolos YAML e execução de migrações sequenciais em cadeia (`v -> v + 1`).
class MigradorProtocoloRegistro {
  /// Mapeamento de identificadores de protocolo legados (PT) para os identificadores canônicos em inglês.
  static const Map<String, String> _mapaIdsLegados = {
    'manutencao_ferragens': 'maintenance',
    'manutencao': 'maintenance',
    'abertura_via_v1': 'route_opening',
    'abertura_vias': 'route_opening',
    'inspecao_visual_v1': 'visual_inspection',
    'inspecao_visual': 'visual_inspection',
    'registro_expresso': 'express_log',
    'cadastro_material': 'material_registration',
  };

  /// Mapeamento do ID canônico em inglês para o arquivo YAML em `assets/protocols/`.
  static const Map<String, String> _mapaArquivosAsset = {
    'visual_inspection': 'assets/protocols/inspecao_visual.yaml',
    'maintenance': 'assets/protocols/manutencao.yaml',
    'route_opening': 'assets/protocols/abertura_vias.yaml',
    'express_log': 'assets/protocols/registro_expresso.yaml',
    'material_registration': 'assets/protocols/cadastro_material.yaml',
  };

  /// Mapeamento canônico de IDs de blocos legados (PT) para inglês (EN).
  static const Map<String, String> mapaBlocosPtParaEn = {
    'via': 'route',
    'inspecao': 'inspection',
    'avaliacao': 'assessment',
    'acoes': 'actions',
    'bloco_identificacao': 'identification_block',
    'bloco_evidencias': 'evidence_block',
    'identificacao_material': 'material_identification',
    'composicao_materiais': 'material_composition',
  };

  /// Mapeamento canônico de IDs de conteúdos legados (PT) para inglês (EN).
  static const Map<String, String> mapaConteudosPtParaEn = {
    'via_aviso': 'route_notice',
    'via_data': 'route_date',
    'via_gps': 'route_gps',
    'via_nome': 'route_name',
    'via_setor': 'route_sector',
    'via_pico': 'route_peak',
    'via_tem_permissao': 'route_has_permission',
    'via_foto_permissao': 'route_permission_media',
    'via_conquistadores': 'route_first_ascensionists',
    'via_graduacao': 'route_grade',
    'via_extensao': 'route_length',
    'via_foto_linha': 'route_line_media',
    'observacoes_gerais': 'general_notes',
    'avaliacao_condicao': 'assessment_condition',
    'avaliacao_comentarios': 'assessment_comments',
    'lista_inspecao_c': 'inspection_list_c',
    'iv_pa_posicao': 'vi_ap_position',
    'iv_pa_estado': 'vi_ap_condition',
    'iv_pa_corrosao': 'vi_ap_corrosion',
    'iv_pa_nota': 'vi_ap_notes',
    'iv_pa_midia': 'vi_ap_media',
    'iv_pr_posicao': 'vi_ba_position',
    'iv_pr_estado': 'vi_ba_condition',
    'iv_pr_corrosao': 'vi_ba_corrosion',
    'iv_pr_nota': 'vi_ba_notes',
    'iv_pr_midia': 'vi_ba_media',
    'iv_ra_descricao': 'vi_re_description',
    'iv_ra_estado': 'vi_re_condition',
    'iv_ra_midia': 'vi_re_media',
    'lista_acoes_c': 'action_list_c',
    'ia_instrucao': 'ai_instruction',
    'ia_foto_antes': 'ai_media_before',
    'ia_resultado': 'ai_result',
    'ia_ap_nota': 'ai_ap_notes',
    'ia_re_torque': 'ai_rt_torque',
    'ia_re_nota': 'ai_rt_notes',
    'ia_sub_aviso': 'ai_rep_notice',
    'ia_sub_ramo': 'ai_rep_branch',
    'ref_mat_reusar_furo': 'ref_mat_reuse_hole',
    'ia_sub_rf_foto': 'ai_rep_rh_media',
    'ref_mat_novo_local': 'ref_mat_new_location',
    'ia_sub_nl_nota': 'ai_rep_nl_notes',
    'ia_sub_nl_foto': 'ai_rep_nl_media',
    'np_instrucao': 'na_instruction',
    'ref_mat_novo_ponto': 'ref_mat_new_anchor',
    'np_foto': 'na_media',
    'rb_aviso': 'lr_notice',
    'rb_tamanho': 'lr_size',
    'rb_foto_antes': 'lr_media_before',
    'rb_foto_depois': 'lr_media_after',
    'lv_foto_antes': 'vc_media_before',
    'lv_nota': 'vc_notes',
    'lv_foto_depois': 'vc_media_after',
    'out_descricao': 'oth_description',
    'ref_mat_outro': 'ref_mat_other',
    'out_foto': 'oth_media',
    'pi_posicao': 'ia_position',
    'ref_mat_protecao': 'ref_mat_protection',
    'pi_foto': 'ia_media',
    'pi_nota': 'ia_notes',
    'pr_posicao': 'ba_position',
    'ref_mat_parada': 'ref_mat_belay',
    'pr_foto': 'ba_media',
    'pr_nota': 'ba_notes',
    'lista_evidencias': 'evidence_list',
    'ev_midia': 'ev_media',
    'ev_descricao': 'ev_description',
    'ref_mat_expresso': 'ref_mat_express',
    'mat_instrucao': 'mat_instruction',
    'mat_nome': 'mat_name',
    'mat_codigo_associacao': 'mat_association_code',
    'mat_data': 'mat_date',
    'lista_itens_material_c': 'material_items_list_c',
    'pb_marca': 'eb_brand',
    'pb_liga': 'eb_alloy',
    'pb_dimensoes': 'eb_dimensions',
    'pb_lote': 'eb_batch',
    'pb_validade': 'eb_expiry',
    'pb_foto': 'eb_media',
    'pb_nf_numero': 'eb_invoice_number',
    'pb_nf_fornecedor': 'eb_invoice_supplier',
    'pb_nf_foto': 'eb_invoice_media',
    'pb_testes': 'eb_tests',
    'pb_detalhes': 'eb_details',
    'ch_marca': 'hg_brand',
    'ch_liga': 'hg_alloy',
    'ch_furo': 'hg_hole_diameter',
    'ch_lote': 'hg_batch',
    'ch_foto': 'hg_media',
    'ch_nf_numero': 'hg_invoice_number',
    'ch_nf_fornecedor': 'hg_invoice_supplier',
    'ch_nf_foto': 'hg_invoice_media',
    'ch_testes': 'hg_tests',
    'ch_detalhes': 'hg_details',
    'ca_marca': 'rh_brand',
    'ca_liga': 'rh_alloy',
    'ca_lote': 'rh_batch',
    'ca_foto': 'rh_media',
    'ca_nf_numero': 'rh_invoice_number',
    'ca_nf_fornecedor': 'rh_invoice_supplier',
    'ca_nf_foto': 'rh_invoice_media',
    'ca_testes': 'rh_tests',
    'ca_detalhes': 'rh_details',
    'aq_marca': 'ca_brand',
    'aq_validade': 'ca_expiry',
    'aq_lote': 'ca_batch',
    'aq_foto': 'ca_media',
    'aq_nf_numero': 'ca_invoice_number',
    'aq_nf_fornecedor': 'ca_invoice_supplier',
    'aq_nf_foto': 'ca_invoice_media',
    'aq_testes': 'ca_tests',
    'aq_detalhes': 'ca_details',
    'cp_marca': 'pq_brand',
    'cp_liga': 'pq_alloy',
    'cp_carga': 'pq_breaking_load',
    'cp_lote': 'pq_batch',
    'cp_foto': 'pq_media',
    'cp_nf_numero': 'pq_invoice_number',
    'cp_nf_fornecedor': 'pq_invoice_supplier',
    'cp_nf_foto': 'pq_invoice_media',
    'cp_testes': 'pq_tests',
    'cp_detalhes': 'pq_details',
    'out_instrucao': 'oth_instruction',
    'out_nf_numero': 'oth_invoice_number',
    'out_nf_fornecedor': 'oth_invoice_supplier',
    'out_nf_foto': 'oth_invoice_media',
    'out_testes': 'oth_tests',
    'out_detalhes': 'oth_details',
    'tq_tipo': 'qt_type',
    'tq_resultado': 'qt_result',
    'tq_foto': 'qt_media',
    'det_titulo': 'det_title',
    'det_descricao': 'det_description',
    'det_foto': 'det_media',
  };

  /// Mapeamento canônico de IDs de ramos legados (PT) para inglês (EN).
  static const Map<String, String> mapaRamosPtParaEn = {
    'aprovado': 'approved',
    'reaperto': 'retightened',
    'substituir': 'replace',
    'reusar_furo': 'reuse_hole',
    'novo_local': 'new_location',
  };

  /// Mapeamento canônico de IDs de tipos de ação legados (PT) para inglês (EN).
  static const Map<String, String> mapaTiposAcaoPtParaEn = {
    'protecao_ancoragem': 'anchor_protection',
    'parada_rapel': 'belay_rappel_station',
    'rocha_ambiente': 'rock_environment',
    'inspecao_ancoragem': 'anchor_inspection',
    'novo_ponto': 'new_anchor_point',
    'remocao_bloco': 'loose_rock_removal',
    'limpeza_vegetacao': 'vegetation_cleaning',
    'outro': 'other',
    'protecao_instalada': 'installed_protection',
    'item_evidencia': 'evidence_item',
    'parabolt': 'expansion_bolt',
    'chapeleta': 'hanger',
    'chapeleta_argola': 'ring_hanger',
    'ancoragem_quimica': 'chemical_anchor',
    'costura_permanente': 'permanent_quickdraw',
    'teste_qualidade': 'quality_test',
    'detalhe_item': 'manufacturing_detail',
  };

  /// Mapeamento canônico de valores de opções legados (PT) para inglês (EN).
  static const Map<String, String> mapaOpcoesPtParaEn = {
    'bom': 'good',
    'desgastado': 'worn',
    'critico': 'critical',
    'informativo': 'informative',
    'atencao': 'warning',
    'liberada': 'open',
    'liberada_restricao': 'open_with_restrictions',
    'interditada': 'closed',
    'em_conquista': 'project_in_progress',
    'pequeno': 'small',
    'medio': 'medium',
    'grande': 'large',
    'aco_inox_316': 'stainless_steel_316',
    'aco_inox_304': 'stainless_steel_304',
    'aco_galvanizado': 'galvanized_steel',
    'titanio': 'titanium',
    'outro': 'other',
  };

  /// Campos cujos valores textuais representam escolhas de `opcoes` ou `ramos`.
  static const Set<String> _camposComValorCodificado = {
    'vi_ap_condition',
    'vi_ba_condition',
    'vi_re_condition',
    'assessment_condition',
    'ai_result',
    'ai_rep_branch',
    'lr_size',
    'eb_alloy',
    'hg_alloy',
    'rh_alloy',
    'pq_alloy',
  };

  /// Versões inteiras atuais e assinaturas estruturais SHA-256 oficiais de cada protocolo em `assets/protocols/`.
  static const Map<String, ({int versaoAtual, String assinaturaEstrutural})>
      versoesEAssinaturasAtuais = {
    'visual_inspection': (
      versaoAtual: 3,
      assinaturaEstrutural:
          '314d76cbf8f7221ee8efc395f0a83697086979d1e8d5d4880dae5756181a827b',
    ),
    'maintenance': (
      versaoAtual: 3,
      assinaturaEstrutural:
          'df3a8ae4707df3701c8657249e412d4844bd2bf263991a4f38dab0403e0fd0b3',
    ),
    'route_opening': (
      versaoAtual: 3,
      assinaturaEstrutural:
          '504cc12e322d065147d6d9116f13d62a84ba83b365b8a16db68e4f583c4d55f4',
    ),
    'express_log': (
      versaoAtual: 3,
      assinaturaEstrutural:
          '7e71b39a3b487def9e1fd40f8631da2f27bf58f634cbd338ff434a1eea75358b',
    ),
    'material_registration': (
      versaoAtual: 2,
      assinaturaEstrutural:
          'e5a3fb8720ca4b495d0123bf337ff040920d0c588bca72672790f9314102423e',
    ),
  };

  /// Cadeia oficial de migradores (`versaoOrigem -> PassoMigracaoProtocolo`) por protocolo canônico.
  static final Map<String, Map<int, PassoMigracaoProtocolo>>
      migradoresPorProtocolo = {
    'maintenance': {
      1: _migrarManutencaoV1ParaV2,
      2: _migrarIdsPortuguesParaIngles,
    },
    'route_opening': {
      1: _migrarAberturaViasV1ParaV2,
      2: _migrarIdsPortuguesParaIngles,
    },
    'visual_inspection': {
      1: _migrarInspecaoVisualV1ParaV2,
      2: _migrarIdsPortuguesParaIngles,
    },
    'express_log': {
      1: _migrarRegistroExpressoV1ParaV2,
      2: _migrarIdsPortuguesParaIngles,
    },
    'material_registration': {
      1: _migrarIdsPortuguesParaIngles,
    },
  };

  /// Normaliza um identificador de protocolo legado para o identificador canônico atual em inglês.
  static String normalizarIdProtocolo(String idProtocoloBruto) {
    final limpo = idProtocoloBruto.trim();
    return _mapaIdsLegados[limpo] ?? limpo;
  }

  /// Normaliza um identificador de conteúdo legado (PT) para o ID canônico em inglês,
  /// preservando eventual sufixo `__<idItem>`.
  static String normalizarIdConteudo(String idConteudoBruto) {
    final limpo = idConteudoBruto.trim();
    if (limpo.contains('__')) {
      final partes = limpo.split('__');
      final base = mapaConteudosPtParaEn[partes.first] ?? partes.first;
      return '${base}__${partes.sublist(1).join('__')}';
    }
    return mapaConteudosPtParaEn[limpo] ?? limpo;
  }

  /// Normaliza um valor de opção ou ramo legado (PT) para o valor canônico em inglês.
  static String normalizarValorOpcao(String valorBruto) {
    final limpo = valorBruto.trim();
    return mapaOpcoesPtParaEn[limpo] ?? mapaRamosPtParaEn[limpo] ?? limpo;
  }

  /// Retorna o caminho do asset YAML canônico correspondente ao [idProtocoloBruto].
  static String caminhoAssetParaProtocolo(String idProtocoloBruto) {
    final idCanonico = normalizarIdProtocolo(idProtocoloBruto);
    return _mapaArquivosAsset[idCanonico] ?? 'assets/protocols/$idCanonico.yaml';
  }

  /// Calcula uma assinatura estrutural determinística SHA-256 sobre a árvore de IDs,
  /// tipos, obrigatoriedade, opções, ramos e listas de um [DefinicaoProtocolo].
  static String calcularAssinaturaEstrutural(DefinicaoProtocolo protocolo) {
    final buffer = StringBuffer()..write('proto:${protocolo.id}|');
    for (final bloco in protocolo.blocos) {
      buffer.write('bloco:${bloco.id}|');
      _serializarStepsParaAssinatura(bloco.steps, buffer);
    }
    return sha256.convert(utf8.encode(buffer.toString())).toString();
  }

  static void _serializarStepsParaAssinatura(
    List<Step> steps,
    StringBuffer buffer,
  ) {
    for (final step in steps) {
      buffer.write('step:${step.id}[(');
      for (final c in step.conteudos) {
        final tipo = c.whichTipo();
        buffer.write('c:${c.id}:${tipo.name}');
        if (tipo == ConteudoStep_Tipo.campoSimples) {
          final cs = c.campoSimples;
          final opcoes = cs.opcoes.map((o) => o.valor).join(',');
          buffer.write(
            ':{t=${cs.tipo.name},ob=${cs.obrigatorio},dt=${cs.preencherDataAtual},op=$opcoes}',
          );
        } else if (tipo == ConteudoStep_Tipo.selecaoRamo) {
          final sr = c.selecaoRamo;
          buffer.write(':{ob=${sr.obrigatorio},ramos=[');
          for (final r in sr.ramos) {
            buffer.write('r:${r.id}(');
            _serializarStepsParaAssinatura(r.steps, buffer);
            buffer.write(')');
          }
          buffer.write(']}');
        } else if (tipo == ConteudoStep_Tipo.listaAcoes) {
          final la = c.listaAcoes;
          buffer.write(':{min=${la.minimo},max=${la.maximo},tipos=[');
          for (final t in la.tiposDisponiveis) {
            buffer.write('t:${t.id}(');
            _serializarStepsParaAssinatura(t.steps, buffer);
            buffer.write(')');
          }
          buffer.write(']}');
        } else if (tipo == ConteudoStep_Tipo.refMateriais) {
          final rm = c.refMateriais;
          buffer.write(
            ':{cat=${rm.origemCatalogo},step=${rm.idStepMateriais},ob=${rm.obrigatorio}}',
          );
        }
        buffer.write(';');
      }
      buffer.write(')]');
    }
  }

  /// Executa a migração em cadeia (`v -> v + 1`) de um [registro] até atingir a versão
  /// declarada em [yamlAtual], atualizando `idProtocolo`, `versaoProtocolo` e `yamlConteudo`.
  static void migrarRegistro(
    Registro registro, {
    required String yamlAtual,
    Map<String, Map<int, PassoMigracaoProtocolo>>? migradoresCustomizados,
  }) {
    registro.respostas.remove('assinatura_c');
    registro.respostas.remove('mat_assinatura_c');

    final protoAtual = ProtocolParser.fromYaml(yamlAtual);
    final idCanonico = normalizarIdProtocolo(
      registro.idProtocolo.isNotEmpty ? registro.idProtocolo : protoAtual.id,
    );
    final versaoOrigem =
        ProtocolParser.extrairVersaoInteira(registro.versaoProtocolo);
    final versaoAlvo = ProtocolParser.extrairVersaoInteira(protoAtual.versao);

    if (versaoOrigem > versaoAlvo) {
      throw ExcecaoVersaoProtocoloNaoSuportada(
        idProtocolo: idCanonico,
        versaoRegistro: versaoOrigem,
        versaoSuportada: versaoAlvo,
      );
    }

    final tabela = migradoresCustomizados ?? migradoresPorProtocolo;
    final passosDoProtocolo = tabela[idCanonico];

    for (var v = versaoOrigem; v < versaoAlvo; v++) {
      final passo = passosDoProtocolo?[v];
      if (passo != null) {
        passo(registro);
      }
    }

    registro
      ..idProtocolo = idCanonico
      ..versaoProtocolo = '$versaoAlvo'
      ..yamlConteudo = yamlAtual;
  }

  /// Valida a Trava A (assinatura estrutural do YAML vs. versão atual registrada) e a
  /// Trava B (existência de todos os migradores `1 .. (N-1)` para protocolos na versão `N > 1`).
  static List<String> validarContratoProtocolos(
    Map<String, String> yamlsPorId, {
    Map<String, ({int versaoAtual, String assinaturaEstrutural})>?
        assinaturasEsperadas,
    Map<String, Map<int, PassoMigracaoProtocolo>>? migradores,
  }) {
    final erros = <String>[];
    final mapaAssinaturas = assinaturasEsperadas ?? versoesEAssinaturasAtuais;
    final mapaMigradores = migradores ?? migradoresPorProtocolo;

    for (final entrada in yamlsPorId.entries) {
      final id = normalizarIdProtocolo(entrada.key);
      final proto = ProtocolParser.fromYaml(entrada.value);
      final versaoNoYaml = ProtocolParser.extrairVersaoInteira(proto.versao);
      final assinaturaCalculada = calcularAssinaturaEstrutural(proto);

      final esperado = mapaAssinaturas[id] ?? mapaAssinaturas[entrada.key];
      if (esperado == null) {
        erros.add(
          'O protocolo "${entrada.key}" não possui versão e assinatura estrutural registradas em MigradorProtocoloRegistro.',
        );
        continue;
      }

      if (versaoNoYaml != esperado.versaoAtual) {
        erros.add(
          'O protocolo "${entrada.key}" declara versao $versaoNoYaml, mas a versão registrada em MigradorProtocoloRegistro é ${esperado.versaoAtual}.',
        );
      }

      if (assinaturaCalculada != esperado.assinaturaEstrutural) {
        erros.add(
          'A assinatura estrutural de "${entrada.key}" (versao $versaoNoYaml) mudou para "$assinaturaCalculada" (esperado "${esperado.assinaturaEstrutural}"). Incremente a versão inteira do YAML e registre o migrador correspondente.',
        );
      }

      if (versaoNoYaml > 1) {
        final passos =
            mapaMigradores[id] ?? mapaMigradores[entrada.key] ?? const {};
        for (var v = 1; v < versaoNoYaml; v++) {
          if (!passos.containsKey(v)) {
            erros.add(
              'O protocolo "${entrada.key}" está na versão $versaoNoYaml, mas não possui migrador registrado para a transição $v -> ${v + 1}.',
            );
          }
        }
      }
    }

    return erros;
  }

  static String _formatarDataDeTimestamp(Registro registro) {
    final ts = registro.utcTimestampInicio.toInt();
    final dt = ts > 0
        ? DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true)
        : DateTime.now();
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year}';
  }

  static void _preencherViaDataSeAusente(Registro registro) {
    final atual = (registro.respostas['route_date'] ??
                registro.respostas['via_data'])
            ?.texto
            .trim() ??
        '';
    if (atual.isEmpty) {
      registro.respostas['via_data'] = Resposta(
        texto: _formatarDataDeTimestamp(registro),
      );
    }
  }

  static void _renomearChaveMapa(
    Map<String, Resposta> mapa,
    String chaveAntiga,
    String chaveNova,
  ) {
    final valor = mapa.remove(chaveAntiga);
    if (valor != null && !mapa.containsKey(chaveNova)) {
      mapa[chaveNova] = valor;
    }
  }

  static void _migrarManutencaoV1ParaV2(Registro registro) {
    registro.respostas.remove('lista_materiais_c');
    _preencherViaDataSeAusente(registro);

    for (final grupo in registro.listas) {
      _renomearChaveMapa(
        grupo.respostasItem,
        'ia_sub_rf_materiais',
        'ref_mat_reusar_furo',
      );
      _renomearChaveMapa(
        grupo.respostasItem,
        'ia_rf_ref_materiais',
        'ref_mat_reusar_furo',
      );
      _renomearChaveMapa(
        grupo.respostasItem,
        'ia_sub_nl_materiais',
        'ref_mat_novo_local',
      );
      _renomearChaveMapa(
        grupo.respostasItem,
        'ia_nl_ref_materiais',
        'ref_mat_novo_local',
      );
      _renomearChaveMapa(
        grupo.respostasItem,
        'np_materiais',
        'ref_mat_novo_ponto',
      );
      _renomearChaveMapa(
        grupo.respostasItem,
        'np_ref_materiais',
        'ref_mat_novo_ponto',
      );
    }
  }

  static void _migrarAberturaViasV1ParaV2(Registro registro) {
    _renomearChaveMapa(registro.respostas, 'nome_via', 'via_nome');
    _renomearChaveMapa(registro.respostas, 'graduacao', 'via_graduacao');
    _renomearChaveMapa(
      registro.respostas,
      'graduacao_proposta',
      'via_graduacao',
    );
    _renomearChaveMapa(registro.respostas, 'setor_gps', 'via_gps');
    _renomearChaveMapa(registro.respostas, 'foto_linha', 'via_foto_linha');
    _preencherViaDataSeAusente(registro);
  }

  static void _migrarInspecaoVisualV1ParaV2(Registro registro) {
    _preencherViaDataSeAusente(registro);

    final estado = registro.respostas.remove('estado_geral');
    final corrosao = registro.respostas.remove('corrosao');
    final foto = registro.respostas.remove('foto_evidencia');

    if (estado != null || corrosao != null || foto != null) {
      final item = GrupoRepetido(
        idLista: 'lista_inspecao_c',
        idItem: 'migrado_1',
        idTipo: 'protecao_ancoragem',
      );
      item.respostasItem['iv_pa_posicao'] = Resposta(texto: 'Proteção 1');
      if (estado != null) item.respostasItem['iv_pa_estado'] = estado;
      if (corrosao != null) item.respostasItem['iv_pa_corrosao'] = corrosao;
      if (foto != null) item.respostasItem['iv_pa_midia'] = foto;
      registro.listas.add(item);
    }
  }

  static void _migrarRegistroExpressoV1ParaV2(Registro registro) {
    _renomearChaveMapa(registro.respostas, 'gps', 'via_gps');
    _preencherViaDataSeAusente(registro);

    for (final grupo in registro.listas) {
      if (grupo.idLista == 'lista_fotos') {
        grupo
          ..idLista = 'lista_evidencias'
          ..idTipo = 'item_evidencia';
        _renomearChaveMapa(grupo.respostasItem, 'foto', 'ev_midia');
        _renomearChaveMapa(grupo.respostasItem, 'video', 'ev_midia');
        _renomearChaveMapa(grupo.respostasItem, 'descricao', 'ev_descricao');
      }
    }
  }

  static void _migrarMapaRespostasPtParaEn(Map<String, Resposta> mapa) {
    final entradas = mapa.entries.toList();
    mapa.clear();
    for (final e in entradas) {
      final novaChave = normalizarIdConteudo(e.key);
      final baseChave = novaChave.split('__').first;
      final resp = e.value;
      if (_camposComValorCodificado.contains(baseChave) &&
          resp.whichValor() == Resposta_Valor.texto &&
          resp.texto.isNotEmpty) {
        resp.texto = normalizarValorOpcao(resp.texto);
      }
      mapa[novaChave] = resp;
    }
  }

  /// Migra identificadores estruturais de respostas, listas, tipos de ação e valores de opções
  /// do formato legado em português para os identificadores canônicos em inglês.
  static void _migrarIdsPortuguesParaIngles(Registro registro) {
    _migrarMapaRespostasPtParaEn(registro.respostas);
    for (final grupo in registro.listas) {
      grupo.idLista = normalizarIdConteudo(grupo.idLista);
      grupo.idTipo = mapaTiposAcaoPtParaEn[grupo.idTipo] ?? grupo.idTipo;
      _migrarMapaRespostasPtParaEn(grupo.respostasItem);
    }
  }
}
