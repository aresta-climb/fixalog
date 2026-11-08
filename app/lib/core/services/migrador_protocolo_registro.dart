// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/proto/protos/registro.pb.dart';
import '../models/proto/protos/wizard.pb.dart';
import 'protocol_parser.dart';

/// Função de migração que transforma um [Registro] de uma versão inteira `v` para `v + 1`.
typedef PassoMigracaoProtocolo = void Function(Registro registro);

/// Serviço responsável pela normalização de identificadores legados, cálculo de assinatura
/// estrutural de protocolos YAML e execução de migrações sequenciais em cadeia (`v -> v + 1`).
class MigradorProtocoloRegistro {
  /// Mapeamento de identificadores legados para os identificadores canônicos atuais.
  static const Map<String, String> _mapaIdsLegados = {
    'manutencao_ferragens': 'manutencao',
    'abertura_via_v1': 'abertura_vias',
    'inspecao_visual_v1': 'inspecao_visual',
  };

  /// Versões inteiras atuais e assinaturas estruturais SHA-256 oficiais de cada protocolo em `assets/protocols/`.
  static const Map<String, ({int versaoAtual, String assinaturaEstrutural})>
      versoesEAssinaturasAtuais = {
    'inspecao_visual': (
      versaoAtual: 2,
      assinaturaEstrutural:
          'd70d063a83c882b396e06e38479acbda1f901e39ceacd9ef44a442553d9a6810',
    ),
    'manutencao': (
      versaoAtual: 2,
      assinaturaEstrutural:
          'cfdfeb836a034529ce71818a030b723a411b23b930785176453a237161f9fe42',
    ),
    'abertura_vias': (
      versaoAtual: 2,
      assinaturaEstrutural:
          '22a0e6289ecf612b6d315875713c5fb7f6443c38144921a40e692592912737e7',
    ),
    'registro_expresso': (
      versaoAtual: 2,
      assinaturaEstrutural:
          '07103e5219b380ebe5f95b19888c3fdf488c9a401aa5a304227513f50431f81e',
    ),
    'cadastro_material': (
      versaoAtual: 1,
      assinaturaEstrutural:
          'a72031c1e6749ea48025aecec5a63906e3bd1f659d4dc3c014112469aa46a923',
    ),
  };

  /// Cadeia oficial de migradores (`versaoOrigem -> PassoMigracaoProtocolo`) por protocolo canônico.
  static final Map<String, Map<int, PassoMigracaoProtocolo>>
      migradoresPorProtocolo = {
    'manutencao': {
      1: _migrarManutencaoV1ParaV2,
    },
    'abertura_vias': {
      1: _migrarAberturaViasV1ParaV2,
    },
    'inspecao_visual': {
      1: _migrarInspecaoVisualV1ParaV2,
    },
    'registro_expresso': {
      1: _migrarRegistroExpressoV1ParaV2,
    },
  };

  /// Normaliza um identificador de protocolo legado para o identificador canônico atual.
  static String normalizarIdProtocolo(String idProtocoloBruto) {
    final limpo = idProtocoloBruto.trim();
    return _mapaIdsLegados[limpo] ?? limpo;
  }

  /// Retorna o caminho do asset YAML canônico correspondente ao [idProtocoloBruto].
  static String caminhoAssetParaProtocolo(String idProtocoloBruto) {
    final idCanonico = normalizarIdProtocolo(idProtocoloBruto);
    return 'assets/protocols/$idCanonico.yaml';
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
      final id = entrada.key;
      final proto = ProtocolParser.fromYaml(entrada.value);
      final versaoNoYaml = ProtocolParser.extrairVersaoInteira(proto.versao);
      final assinaturaCalculada = calcularAssinaturaEstrutural(proto);

      final esperado = mapaAssinaturas[id];
      if (esperado == null) {
        erros.add(
          'O protocolo "$id" não possui versão e assinatura estrutural registradas em MigradorProtocoloRegistro.',
        );
        continue;
      }

      if (versaoNoYaml != esperado.versaoAtual) {
        erros.add(
          'O protocolo "$id" declara versao $versaoNoYaml, mas a versão registrada em MigradorProtocoloRegistro é ${esperado.versaoAtual}.',
        );
      }

      if (assinaturaCalculada != esperado.assinaturaEstrutural) {
        erros.add(
          'A assinatura estrutural de "$id" (versao $versaoNoYaml) mudou para "$assinaturaCalculada" (esperado "${esperado.assinaturaEstrutural}"). Incremente a versão inteira do YAML e registre o migrador correspondente.',
        );
      }

      if (versaoNoYaml > 1) {
        final passos = mapaMigradores[id] ?? const {};
        for (var v = 1; v < versaoNoYaml; v++) {
          if (!passos.containsKey(v)) {
            erros.add(
              'O protocolo "$id" está na versão $versaoNoYaml, mas não possui migrador registrado para a transição $v -> ${v + 1}.',
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
    final atual = registro.respostas['via_data']?.texto.trim() ?? '';
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
    _renomearChaveMapa(registro.respostas, 'graduacao_proposta', 'via_graduacao');
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
}
