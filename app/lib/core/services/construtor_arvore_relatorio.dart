// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:ui';
import '../l10n/resolvedor_idioma.dart';
import '../models/proto/protos/registro.pb.dart';
import '../models/proto/protos/wizard.pb.dart';
import 'migrador_protocolo_registro.dart';
import 'protocol_parser.dart';

/// Árvore semântica de um relatório gerada pelo cruzamento de [DefinicaoProtocolo] e [Registro].
///
/// Serve como fonte única de verdade para a geração tanto do container interativo EPUB 3
/// quanto do documento impresso PDF Resumido A4, garantindo que ambos reflitam os blocos,
/// rótulos humanos, escolhas de ramos e sub-listas aninhadas do protocolo YAML.
class ArvoreRelatorio {
  final String idProtocolo;
  final String nomeProtocolo;
  final String descricaoProtocolo;
  final String versaoProtocolo;
  final String tituloExibicao;
  final List<BlocoRelatorio> blocos;

  const ArvoreRelatorio({
    required this.idProtocolo,
    required this.nomeProtocolo,
    required this.descricaoProtocolo,
    required this.versaoProtocolo,
    required this.tituloExibicao,
    required this.blocos,
  });
}

/// Seção correspondente a um [Bloco] do protocolo que possui ao menos um nodo preenchido.
class BlocoRelatorio {
  final String id;
  final String titulo;
  final String subtitulo;
  final List<NodoRelatorio> nodos;

  const BlocoRelatorio({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.nodos,
  });
}

/// Elemento semântico base de conteúdo dentro de um bloco ou cartão de lista.
sealed class NodoRelatorio {
  const NodoRelatorio();
}

/// Par de rótulo e valor curto exibido dentro de uma [GradePropriedadesRelatorio].
class PropriedadeCurtaRelatorio {
  final String id;
  final String rotulo;
  final String subrotulo;
  final String valor;

  const PropriedadeCurtaRelatorio({
    required this.id,
    required this.rotulo,
    required this.subrotulo,
    required this.valor,
  });
}

/// Agrupamento de campos simples curtos consecutivos em layout de grade de duas colunas.
class GradePropriedadesRelatorio extends NodoRelatorio {
  final List<PropriedadeCurtaRelatorio> propriedades;

  const GradePropriedadesRelatorio({required this.propriedades});
}

/// Destaque visual para decisões de [StepSelecaoRamo] ou `DROPDOWN` com `LARGE_TILES`.
class DestaqueEscolhaRelatorio extends NodoRelatorio {
  final String id;
  final String rotuloPergunta;
  final String rotuloOpcao;
  final String subrotuloOpcao;

  const DestaqueEscolhaRelatorio({
    required this.id,
    required this.rotuloPergunta,
    required this.rotuloOpcao,
    required this.subrotuloOpcao,
  });
}

/// Bloco de texto longo (`TEXT_AREA` ou Markdown multilinha).
class TextoLongoRelatorio extends NodoRelatorio {
  final String id;
  final String rotulo;
  final String subrotulo;
  final String textoMarkdown;

  const TextoLongoRelatorio({
    required this.id,
    required this.rotulo,
    required this.subrotulo,
    required this.textoMarkdown,
  });
}

/// Item de mídia individual acompanhado do rótulo humano do campo que o originou.
class ItemMidiaRelatorio {
  final String idCampo;
  final String rotuloCampo;
  final ReferenciaMidia midia;

  const ItemMidiaRelatorio({
    required this.idCampo,
    required this.rotuloCampo,
    required this.midia,
  });
}

/// Galeria de mídias (fotos lado a lado, vídeos e documentos PDF) de campos consecutivos.
class GaleriaMidiasRelatorio extends NodoRelatorio {
  final List<ItemMidiaRelatorio> itens;

  const GaleriaMidiasRelatorio({required this.itens});
}

/// Referências a materiais selecionados em um passo [StepRefMateriais].
class ReferenciasMateriaisRelatorio extends NodoRelatorio {
  final String id;
  final String rotulo;
  final String subrotulo;
  final bool origemCatalogo;
  final List<String> uuidsMateriais;

  const ReferenciasMateriaisRelatorio({
    required this.id,
    required this.rotulo,
    required this.subrotulo,
    required this.origemCatalogo,
    required this.uuidsMateriais,
  });
}

/// Cartão numerado representando uma instância preenchida dentro de uma [SecaoListaRelatorio].
class ItemListaRelatorio {
  final String idItem;
  final String indiceFormatado;
  final String idTipo;
  final String rotuloTipo;
  final String subrotuloTipo;
  final List<NodoRelatorio> nodos;

  const ItemListaRelatorio({
    required this.idItem,
    required this.indiceFormatado,
    required this.idTipo,
    required this.rotuloTipo,
    required this.subrotuloTipo,
    required this.nodos,
  });
}

/// Seção de lista repetível ([StepListaAcoes]) contendo um ou mais cartões [ItemListaRelatorio].
class SecaoListaRelatorio extends NodoRelatorio {
  final String id;
  final String rotulo;
  final String subrotulo;
  final List<ItemListaRelatorio> itens;

  const SecaoListaRelatorio({
    required this.id,
    required this.rotulo,
    required this.subrotulo,
    required this.itens,
  });
}

/// Motor semântico que constrói a [ArvoreRelatorio] a partir da definição YAML do protocolo
/// contida obrigatoriamente em `registro.yamlConteudo` e das respostas coletadas no [Registro].
class ConstrutorArvoreRelatorio {
  const ConstrutorArvoreRelatorio();

  static DefinicaoProtocolo _obterProtocoloValidado(
    Registro registro, {
    String? codigoIdioma,
    Map<String, dynamic>? traducoes,
  }) {
    final yaml = registro.yamlConteudo.trim();
    if (yaml.isEmpty) {
      throw const FormatException(
        'O registro não possui yamlConteudo definido. A geração de relatórios exige a definição YAML do protocolo.',
      );
    }
    return ProtocolParser.fromYaml(
      yaml,
      codigoIdioma: codigoIdioma,
      traducoes: traducoes,
    );
  }

  /// Extrai todas as [ReferenciaMidia] presentes em uma [Resposta],
  /// seja como mídia única (`resp.hasMidia()`) ou dentro de `resp.lista`.
  static List<ReferenciaMidia> extrairMidiasDeResposta(Resposta? resp) {
    if (resp == null) return const [];
    if (resp.hasMidia()) return [resp.midia];
    if (resp.hasLista()) {
      return resp.lista.valores
          .where((v) => v.hasMidia())
          .map((v) => v.midia)
          .toList();
    }
    return const [];
  }

  /// Extrai a lista de strings não vazias de uma [Resposta] (seja em `texto` separado por vírgula ou em `lista`).
  static List<String> extrairTextosDeResposta(Resposta? resp) {
    if (resp == null) return const [];
    final resultado = <String>[];
    if (resp.hasTexto()) {
      for (final parte in resp.texto.split(',')) {
        final limpo = parte.trim();
        if (limpo.isNotEmpty) {
          resultado.add(limpo);
        }
      }
    } else if (resp.hasLista()) {
      for (final item in resp.lista.valores) {
        if (item.hasTexto() && item.texto.trim().isNotEmpty) {
          resultado.add(item.texto.trim());
        }
      }
    }
    return resultado;
  }

  static void _coletarIdsCamposRefMateriaisEmSteps(
    List<Step> steps,
    Set<String> destino,
  ) {
    for (final step in steps) {
      for (final conteudo in step.conteudos) {
        if (conteudo.hasRefMateriais()) {
          destino.add(conteudo.id);
        } else if (conteudo.hasSelecaoRamo()) {
          for (final ramo in conteudo.selecaoRamo.ramos) {
            _coletarIdsCamposRefMateriaisEmSteps(ramo.steps, destino);
          }
        } else if (conteudo.hasListaAcoes()) {
          for (final tipo in conteudo.listaAcoes.tiposDisponiveis) {
            _coletarIdsCamposRefMateriaisEmSteps(tipo.steps, destino);
          }
        }
      }
    }
  }

  /// Extrai de um [registro] o conjunto ordenado de UUIDs de materiais referenciados
  /// em quaisquer elementos [StepRefMateriais] declarados no protocolo YAML.
  static List<String> extrairUuidsMateriaisReferenciados(Registro registro) {
    final protocolo = _obterProtocoloValidado(registro);
    final idsRefMateriais = <String>{};
    for (final bloco in protocolo.blocos) {
      _coletarIdsCamposRefMateriaisEmSteps(bloco.steps, idsRefMateriais);
    }

    final uuids = <String>{};
    for (final entrada in registro.respostas.entries) {
      final chaveNorm = MigradorProtocoloRegistro.normalizarIdConteudo(
        entrada.key,
      );
      if (idsRefMateriais.contains(entrada.key) ||
          idsRefMateriais.contains(chaveNorm)) {
        uuids.addAll(extrairTextosDeResposta(entrada.value));
      }
    }
    for (final grupo in registro.listas) {
      for (final entrada in grupo.respostasItem.entries) {
        final chaveNorm = MigradorProtocoloRegistro.normalizarIdConteudo(
          entrada.key,
        );
        if (idsRefMateriais.contains(entrada.key) ||
            idsRefMateriais.contains(chaveNorm)) {
          uuids.addAll(extrairTextosDeResposta(entrada.value));
        }
      }
    }

    return uuids.toList();
  }

  static Resposta? _obterRespostaCompativel(
    Map<String, Resposta> escopo,
    String idConteudo,
  ) {
    final direta = escopo[idConteudo];
    if (direta != null) return direta;
    for (final e in escopo.entries) {
      if (MigradorProtocoloRegistro.normalizarIdConteudo(e.key) == idConteudo) {
        return e.value;
      }
    }
    return null;
  }

  /// Determina o título principal de exibição de um [registro] buscando o primeiro
  /// `StepCampoSimples` do tipo `TEXT` preenchido no fluxo principal do protocolo YAML.
  static String extrairTituloExibicao(
    Registro registro, {
    DefinicaoProtocolo? protocolo,
    String fallback = '',
  }) {
    final def = protocolo ?? _obterProtocoloValidado(registro);
    for (final bloco in def.blocos) {
      for (final step in bloco.steps) {
        for (final conteudo in step.conteudos) {
          if (conteudo.hasCampoSimples() &&
              conteudo.campoSimples.tipo == StepCampoSimples_TipoCampo.TEXT) {
            final valor =
                _obterRespostaCompativel(registro.respostas, conteudo.id)
                    ?.texto
                    .trim() ??
                '';
            if (valor.isNotEmpty) {
              return valor;
            }
          }
        }
      }
    }
    final fb = fallback.trim();
    return fb.isNotEmpty ? fb : def.nome;
  }

  /// Constrói a [ArvoreRelatorio] completa do [registro], omitindo `StepInstrucao` e campos vazios.
  ArvoreRelatorio construir(
    Registro registro, {
    String fallbackTitulo = '',
    String? codigoIdioma,
    Map<String, dynamic>? traducoes,
  }) {
    final protocolo = _obterProtocoloValidado(
      registro,
      codigoIdioma: codigoIdioma,
      traducoes: traducoes,
    );
    final tituloExibicao = extrairTituloExibicao(
      registro,
      protocolo: protocolo,
      fallback: fallbackTitulo,
    );

    final blocosResolvidos = <BlocoRelatorio>[];
    for (final bloco in protocolo.blocos) {
      final nodosBrutos = _resolverSteps(
        steps: bloco.steps,
        registro: registro,
        respostasEscopo: registro.respostas,
        codigoIdioma: codigoIdioma,
      );
      final nodosConsolidados = _consolidarNodos(nodosBrutos);
      if (nodosConsolidados.isNotEmpty) {
        blocosResolvidos.add(
          BlocoRelatorio(
            id: bloco.id,
            titulo: bloco.titulo,
            subtitulo: bloco.subtitulo,
            nodos: nodosConsolidados,
          ),
        );
      }
    }

    return ArvoreRelatorio(
      idProtocolo: protocolo.id,
      nomeProtocolo: protocolo.nome,
      descricaoProtocolo: protocolo.descricao,
      versaoProtocolo: protocolo.versao,
      tituloExibicao: tituloExibicao,
      blocos: blocosResolvidos,
    );
  }

  List<NodoRelatorio> _resolverSteps({
    required List<Step> steps,
    required Registro registro,
    required Map<String, Resposta> respostasEscopo,
    String? idItemPai,
    String prefixoIndice = '',
    String? codigoIdioma,
  }) {
    final nodos = <NodoRelatorio>[];

    for (final step in steps) {
      for (final conteudo in step.conteudos) {
        if (conteudo.hasInstrucao()) {
          continue;
        }

        if (conteudo.hasCampoSimples()) {
          _resolverCampoSimples(
            conteudo: conteudo,
            resposta: _obterRespostaCompativel(respostasEscopo, conteudo.id),
            destino: nodos,
            codigoIdioma: codigoIdioma,
          );
        } else if (conteudo.hasSelecaoRamo()) {
          final selecao = conteudo.selecaoRamo;
          final valorRamo =
              _obterRespostaCompativel(respostasEscopo, conteudo.id)
                  ?.texto
                  .trim() ??
              '';
          if (valorRamo.isNotEmpty) {
            final valorRamoNorm =
                MigradorProtocoloRegistro.normalizarValorOpcao(valorRamo);
            final ramo = selecao.ramos
                .cast<Ramo?>()
                .firstWhere(
                  (r) => r?.id == valorRamo || r?.id == valorRamoNorm,
                  orElse: () => null,
                );
            if (ramo != null) {
              nodos.add(
                DestaqueEscolhaRelatorio(
                  id: conteudo.id,
                  rotuloPergunta: selecao.label,
                  rotuloOpcao: ramo.label,
                  subrotuloOpcao: ramo.sublabel,
                ),
              );
              nodos.addAll(
                _resolverSteps(
                  steps: ramo.steps,
                  registro: registro,
                  respostasEscopo: respostasEscopo,
                  idItemPai: idItemPai,
                  prefixoIndice: prefixoIndice,
                  codigoIdioma: codigoIdioma,
                ),
              );
            }
          }
        } else if (conteudo.hasRefMateriais()) {
          final refMat = conteudo.refMateriais;
          final uuids = extrairTextosDeResposta(
            _obterRespostaCompativel(respostasEscopo, conteudo.id),
          );
          if (uuids.isNotEmpty) {
            nodos.add(
              ReferenciasMateriaisRelatorio(
                id: conteudo.id,
                rotulo: refMat.label,
                subrotulo: refMat.sublabel,
                origemCatalogo: refMat.origemCatalogo,
                uuidsMateriais: uuids,
              ),
            );
          }
        } else if (conteudo.hasListaAcoes()) {
          final listaAcoes = conteudo.listaAcoes;
          final chaveLista = idItemPai != null
              ? '${conteudo.id}__$idItemPai'
              : conteudo.id;
          final grupos = registro.listas
              .where(
                (g) =>
                    g.idLista == chaveLista ||
                    MigradorProtocoloRegistro.normalizarIdConteudo(g.idLista) ==
                        chaveLista,
              )
              .toList();

          final itensResolvidos = <ItemListaRelatorio>[];
          for (var i = 0; i < grupos.length; i++) {
            final grupo = grupos[i];
            final numItem = i + 1;
            final indiceStr = prefixoIndice.isEmpty
                ? '#$numItem'
                : '$prefixoIndice.$numItem';

            final tipoNorm =
                MigradorProtocoloRegistro.mapaTiposAcaoPtParaEn[grupo.idTipo] ??
                    grupo.idTipo;
            final tipoAcao = listaAcoes.tiposDisponiveis
                .cast<TipoAcao?>()
                .firstWhere(
                  (t) => t?.id == grupo.idTipo || t?.id == tipoNorm,
                  orElse: () => null,
                );

            if (tipoAcao != null) {
              final nodosFilhos = _consolidarNodos(
                _resolverSteps(
                  steps: tipoAcao.steps,
                  registro: registro,
                  respostasEscopo: grupo.respostasItem,
                  idItemPai: grupo.idItem,
                  prefixoIndice: indiceStr,
                  codigoIdioma: codigoIdioma,
                ),
              );
              if (nodosFilhos.isNotEmpty) {
                itensResolvidos.add(
                  ItemListaRelatorio(
                    idItem: grupo.idItem,
                    indiceFormatado: indiceStr,
                    idTipo: grupo.idTipo,
                    rotuloTipo: tipoAcao.label,
                    subrotuloTipo: tipoAcao.sublabel,
                    nodos: nodosFilhos,
                  ),
                );
              }
            }
          }

          if (itensResolvidos.isNotEmpty) {
            nodos.add(
              SecaoListaRelatorio(
                id: conteudo.id,
                rotulo: listaAcoes.label,
                subrotulo: listaAcoes.sublabel,
                itens: itensResolvidos,
              ),
            );
          }
        }
      }
    }

    return nodos;
  }

  void _resolverCampoSimples({
    required ConteudoStep conteudo,
    required Resposta? resposta,
    required List<NodoRelatorio> destino,
    String? codigoIdioma,
  }) {
    if (resposta == null) return;
    final campo = conteudo.campoSimples;

    String valorBruto = '';
    if (resposta.hasBooleano()) {
      if (codigoIdioma != null) {
        final l10n = ResolvedorIdioma.obterTraducoes(Locale(codigoIdioma));
        valorBruto = resposta.booleano ? l10n.comumSim : l10n.comumNao;
      } else {
        valorBruto = resposta.booleano ? 'Sim' : 'Não';
      }
    } else if (resposta.hasInteiro()) {
      valorBruto = resposta.inteiro.toString();
    } else if (resposta.hasNumero()) {
      final numVal = resposta.numero;
      valorBruto = numVal == numVal.truncateToDouble()
          ? numVal.toInt().toString()
          : numVal.toString();
    } else if (resposta.hasTexto()) {
      valorBruto = resposta.texto.trim();
    }

    if (valorBruto.isNotEmpty) {
      if (campo.tipo == StepCampoSimples_TipoCampo.DROPDOWN) {
        final valorNorm =
            MigradorProtocoloRegistro.normalizarValorOpcao(valorBruto);
        final opcao = campo.opcoes
            .cast<OpcaoCampo?>()
            .firstWhere(
              (o) => o?.valor == valorBruto || o?.valor == valorNorm,
              orElse: () => null,
            );
        final rotuloOpcao =
            (opcao != null && opcao.label.isNotEmpty) ? opcao.label : valorBruto;
        final subrotuloOpcao = opcao?.sublabel ?? '';

        if (campo.uiHint == StepCampoSimples_UiHint.LARGE_TILES) {
          destino.add(
            DestaqueEscolhaRelatorio(
              id: conteudo.id,
              rotuloPergunta: campo.label,
              rotuloOpcao: rotuloOpcao,
              subrotuloOpcao: subrotuloOpcao,
            ),
          );
        } else {
          destino.add(
            GradePropriedadesRelatorio(
              propriedades: [
                PropriedadeCurtaRelatorio(
                  id: conteudo.id,
                  rotulo: campo.label,
                  subrotulo: campo.sublabel,
                  valor: rotuloOpcao,
                ),
              ],
            ),
          );
        }
      } else if (campo.uiHint == StepCampoSimples_UiHint.TEXT_AREA) {
        destino.add(
          TextoLongoRelatorio(
            id: conteudo.id,
            rotulo: campo.label,
            subrotulo: campo.sublabel,
            textoMarkdown: valorBruto,
          ),
        );
      } else {
        destino.add(
          GradePropriedadesRelatorio(
            propriedades: [
              PropriedadeCurtaRelatorio(
                id: conteudo.id,
                rotulo: campo.label,
                subrotulo: campo.sublabel,
                valor: valorBruto,
              ),
            ],
          ),
        );
      }
    }

    final midias = extrairMidiasDeResposta(resposta);
    if (midias.isNotEmpty) {
      destino.add(
        GaleriaMidiasRelatorio(
          itens: midias
              .map(
                (m) => ItemMidiaRelatorio(
                  idCampo: conteudo.id,
                  rotuloCampo: campo.label,
                  midia: m,
                ),
              )
              .toList(),
        ),
      );
    }
  }

  List<NodoRelatorio> _consolidarNodos(List<NodoRelatorio> brutos) {
    final resultado = <NodoRelatorio>[];
    for (final nodo in brutos) {
      if (nodo is GradePropriedadesRelatorio &&
          resultado.isNotEmpty &&
          resultado.last is GradePropriedadesRelatorio) {
        final anterior = resultado.removeLast() as GradePropriedadesRelatorio;
        resultado.add(
          GradePropriedadesRelatorio(
            propriedades: [...anterior.propriedades, ...nodo.propriedades],
          ),
        );
      } else if (nodo is GaleriaMidiasRelatorio &&
          resultado.isNotEmpty &&
          resultado.last is GaleriaMidiasRelatorio) {
        final anterior = resultado.removeLast() as GaleriaMidiasRelatorio;
        resultado.add(
          GaleriaMidiasRelatorio(
            itens: [...anterior.itens, ...nodo.itens],
          ),
        );
      } else {
        resultado.add(nodo);
      }
    }
    return resultado;
  }
}
