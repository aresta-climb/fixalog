// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:flutter_test/flutter_test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fixalog/core/models/proto/protos/registro.pb.dart';
import 'package:fixalog/core/services/construtor_arvore_relatorio.dart';

void main() {
  const yamlProtocoloCompleto = '''
protocolo:
  id: protocolo_teste
  nome: "Protocolo de Vistoria Completa"
  descricao: "Descrição do protocolo de teste"
  versao: "2.1.0"
  blocos:
    - id: bloco_materiais
      titulo: "Bloco 1 — Materiais"
      subtitulo: "Seleção do catálogo"
      steps:
        - id: step_mat
          conteudos:
            - id: inst_mat
              instrucao:
                titulo: "Dica de preenchimento"
                corpo: "Esta instrução não deve ir para o relatório"
                nivel_alerta: INFO
            - id: selecao_catalogo
              ref_materiais:
                label: "Materiais selecionados"
                sublabel: "Do catálogo local"
                origem_catalogo: true
                obrigatorio: true

    - id: bloco_identificacao
      titulo: "Bloco 2 — Identificação"
      subtitulo: "Dados gerais"
      steps:
        - id: step_id
          conteudos:
            - id: gps_base
              campo_simples:
                label: "Coordenada GPS"
                tipo: GPS
                obrigatorio: true
            - id: titulo_registro
              campo_simples:
                label: "Nome da Rota"
                sublabel: "Identificador principal"
                tipo: TEXT
                obrigatorio: true
            - id: qtd_protecoes
              campo_simples:
                label: "Quantidade de Proteções"
                tipo: NUMBER
            - id: nota_inteira
              campo_simples:
                label: "Grau de Exposição"
                tipo: NUMBER
            - id: autorizado
              campo_simples:
                label: "Possui Autorização?"
                tipo: BOOLEAN
            - id: tipo_rocha
              campo_simples:
                label: "Tipo de Rocha"
                tipo: DROPDOWN
                opcoes:
                  - valor: granito
                    label: "Granito Gnaisse"
                  - valor: calcario
                    label: "Calcário"
            - id: campo_opcional_vazio
              campo_simples:
                label: "Campo Opcional Não Preenchido"
                tipo: TEXT
                obrigatorio: false
            - id: observacoes_longas
              campo_simples:
                label: "Observações Técnicas"
                sublabel: "Markdown suportado"
                tipo: TEXT
                ui_hint: TEXT_AREA
            - id: condicao_final
              campo_simples:
                label: "Condição Final"
                tipo: DROPDOWN
                ui_hint: LARGE_TILES
                opcoes:
                  - valor: liberada
                    label: "Liberada para Escalada"
                    sublabel: "Segurança verificada"
            - id: decisao_acesso
              selecao_ramo:
                label: "Estado da Trilha"
                ramos:
                  - id: trilha_bloqueada
                    label: "Trilha com Obstáculo"
                    sublabel: "Requer desvio"
                    steps:
                      - id: step_desvio
                        conteudos:
                          - id: distancia_desvio
                            campo_simples:
                              label: "Distância do Desvio (m)"
                              tipo: NUMBER

    - id: bloco_vazio
      titulo: "Bloco 3 — Opcional Vazio"
      subtitulo: "Não deve aparecer se nada foi preenchido"
      steps:
        - id: step_vazio
          conteudos:
            - id: texto_vazio
              campo_simples:
                label: "Anotação Extra"
                tipo: TEXT

    - id: bloco_acoes
      titulo: "Bloco 4 — Intervenções"
      subtitulo: "Lista de ações e sub-listas"
      steps:
        - id: step_acoes
          conteudos:
            - id: lista_intervencoes
              lista_acoes:
                label: "Intervenções Realizadas"
                sublabel: "Registro detalhado"
                minimo: 1
                tipos_disponiveis:
                  - id: troca_ancoragem
                    label: "Troca de Ancoragem"
                    sublabel: "Substituição completa"
                    steps:
                      - id: step_ta
                        conteudos:
                          - id: inst_ta
                            instrucao:
                              titulo: "Atenção ao torque"
                              corpo: "Instrução interna"
                              nivel_alerta: PERIGO
                          - id: foto_antes
                            campo_simples:
                              label: "Foto Antes"
                              tipo: IMAGE
                          - id: foto_depois
                            campo_simples:
                              label: "Foto Depois"
                              tipo: IMAGE
                          - id: resultado_ta
                            selecao_ramo:
                              label: "Método Utilizado"
                              ramos:
                                - id: quimico
                                  label: "Fixação Química"
                                  sublabel: "Ampola epóxi"
                                  steps:
                                    - id: step_quimico
                                      conteudos:
                                        - id: mat_usado
                                          ref_materiais:
                                            label: "Material Aplicado"
                                            id_step_materiais: "selecao_catalogo"
                                        - id: sub_testes
                                          lista_acoes:
                                            label: "Ensaios de Arrancamento"
                                            sublabel: "Testes aplicados no ponto"
                                            tipos_disponiveis:
                                              - id: ensaio_tracao
                                                label: "Ensaio de Tração"
                                                sublabel: "Dinamômetro"
                                                steps:
                                                  - id: step_et
                                                    conteudos:
                                                      - id: carga_kn
                                                        campo_simples:
                                                          label: "Carga Aplicada (kN)"
                                                          tipo: TEXT
''';

  group('ConstrutorArvoreRelatorio', () {
    test('lança FormatException quando yamlConteudo está vazio no Registro', () {
      final construtor = ConstrutorArvoreRelatorio();
      final registroSemYaml = Registro(idSessao: 'sessao-1', idProtocolo: 'p1');

      expect(
        () => construtor.construir(registroSemYaml),
        throwsFormatException,
      );
      expect(
        () => ConstrutorArvoreRelatorio.extrairUuidsMateriaisReferenciados(
          registroSemYaml,
        ),
        throwsFormatException,
      );
    });

    test(
      'constrói árvore traduzindo rótulos do YAML, omitindo instruções e vazios e agrupando propriedades e mídias',
      () {
        final construtor = ConstrutorArvoreRelatorio();
        final registro = Registro(
          idSessao: 'sessao-123',
          idProtocolo: 'protocolo_teste',
          versaoProtocolo: '2.1.0',
          yamlConteudo: yamlProtocoloCompleto,
          listas: [
            GrupoRepetido(
              idLista: 'lista_intervencoes',
              idItem: 'item_1',
              idTipo: 'troca_ancoragem',
            )..respostasItem.addAll({
                'foto_antes': Resposta(
                  midia: ReferenciaMidia(
                    imagem: ArquivoImagem(uuid: 'img-antes'),
                  ),
                ),
                'foto_depois': Resposta(
                  midia: ReferenciaMidia(
                    imagem: ArquivoImagem(uuid: 'img-depois'),
                  ),
                ),
                'resultado_ta': Resposta(texto: 'quimico'),
                'mat_usado': Resposta(texto: 'uuid-mat-1'),
              }),
            GrupoRepetido(
              idLista: 'sub_testes__item_1',
              idItem: 'sub_1',
              idTipo: 'ensaio_tracao',
            )..respostasItem.addAll({
                'carga_kn': Resposta(texto: '25 kN'),
              }),
          ],
        )..respostas.addAll({
            'selecao_catalogo': Resposta(
              lista: ListaRespostas(
                valores: [
                  Resposta(texto: 'uuid-mat-1'),
                  Resposta(texto: 'uuid-mat-2'),
                ],
              ),
            ),
            'gps_base': Resposta(texto: '-22.9519, -43.2105'),
            'titulo_registro': Resposta(texto: 'Via dos Italianos'),
            'qtd_protecoes': Resposta(numero: 12.5),
            'nota_inteira': Resposta(inteiro: Int64(3)),
            'autorizado': Resposta(booleano: true),
            'tipo_rocha': Resposta(texto: 'granito'),
            'observacoes_longas': Resposta(texto: 'Rocha **sã** no início.'),
            'condicao_final': Resposta(texto: 'liberada'),
            'decisao_acesso': Resposta(texto: 'trilha_bloqueada'),
            'distancia_desvio': Resposta(numero: 45),
          });

        final arvore = construtor.construir(registro);

        expect(arvore.idProtocolo, equals('protocolo_teste'));
        expect(arvore.nomeProtocolo, equals('Protocolo de Vistoria Completa'));
        expect(arvore.versaoProtocolo, equals('2.1.0'));
        expect(arvore.tituloExibicao, equals('Via dos Italianos'));

        // Bloco 3 (bloco_vazio) deve ter sido omitido por não possuir respostas
        expect(arvore.blocos.map((b) => b.id).toList(), [
          'bloco_materiais',
          'bloco_identificacao',
          'bloco_acoes',
        ]);

        // Bloco 1: apenas ReferenciasMateriaisRelatorio (StepInstrucao foi omitido)
        final bloco1 = arvore.blocos[0];
        expect(bloco1.titulo, equals('Bloco 1 — Materiais'));
        expect(bloco1.nodos.length, equals(1));
        final nodoMat = bloco1.nodos.first as ReferenciasMateriaisRelatorio;
        expect(nodoMat.rotulo, equals('Materiais selecionados'));
        expect(nodoMat.origemCatalogo, isTrue);
        expect(nodoMat.uuidsMateriais, equals(['uuid-mat-1', 'uuid-mat-2']));

        // Bloco 2: Grade de propriedades + TextoLongo + Destaque LARGE_TILES + Destaque SelecaoRamo + Grade do sub-step
        final bloco2 = arvore.blocos[1];
        expect(bloco2.nodos.length, equals(5));

        final grade = bloco2.nodos[0] as GradePropriedadesRelatorio;
        expect(
          grade.propriedades.map((p) => '${p.rotulo}: ${p.valor}').toList(),
          equals([
            'Coordenada GPS: -22.9519, -43.2105',
            'Nome da Rota: Via dos Italianos',
            'Quantidade de Proteções: 12.5',
            'Grau de Exposição: 3',
            'Possui Autorização?: Sim',
            'Tipo de Rocha: Granito Gnaisse',
          ]),
        );

        final textoLongo = bloco2.nodos[1] as TextoLongoRelatorio;
        expect(textoLongo.rotulo, equals('Observações Técnicas'));
        expect(textoLongo.textoMarkdown, equals('Rocha **sã** no início.'));

        final destaqueTile = bloco2.nodos[2] as DestaqueEscolhaRelatorio;
        expect(destaqueTile.rotuloPergunta, equals('Condição Final'));
        expect(destaqueTile.rotuloOpcao, equals('Liberada para Escalada'));
        expect(destaqueTile.subrotuloOpcao, equals('Segurança verificada'));

        final destaqueRamo = bloco2.nodos[3] as DestaqueEscolhaRelatorio;
        expect(destaqueRamo.rotuloPergunta, equals('Estado da Trilha'));
        expect(destaqueRamo.rotuloOpcao, equals('Trilha com Obstáculo'));
        expect(destaqueRamo.subrotuloOpcao, equals('Requer desvio'));

        final gradeDesvio = bloco2.nodos[4] as GradePropriedadesRelatorio;
        expect(
          gradeDesvio.propriedades.single.rotulo,
          equals('Distância do Desvio (m)'),
        );
        expect(gradeDesvio.propriedades.single.valor, equals('45'));

        // Bloco 4: Lista de intervenções com fotos agrupadas em galeria, ramo expandido e sub-lista aninhada
        final blocoAcoes = arvore.blocos[2];
        final secaoLista = blocoAcoes.nodos.single as SecaoListaRelatorio;
        expect(secaoLista.rotulo, equals('Intervenções Realizadas'));
        expect(secaoLista.itens.length, equals(1));

        final item1 = secaoLista.itens.single;
        expect(item1.indiceFormatado, equals('#1'));
        expect(item1.rotuloTipo, equals('Troca de Ancoragem'));
        expect(item1.subrotuloTipo, equals('Substituição completa'));

        expect(item1.nodos.length, equals(4));

        final galeria = item1.nodos[0] as GaleriaMidiasRelatorio;
        expect(
          galeria.itens.map((i) => i.rotuloCampo).toList(),
          equals(['Foto Antes', 'Foto Depois']),
        );

        final ramoItem = item1.nodos[1] as DestaqueEscolhaRelatorio;
        expect(ramoItem.rotuloPergunta, equals('Método Utilizado'));
        expect(ramoItem.rotuloOpcao, equals('Fixação Química'));

        final refMatItem = item1.nodos[2] as ReferenciasMateriaisRelatorio;
        expect(refMatItem.rotulo, equals('Material Aplicado'));
        expect(refMatItem.origemCatalogo, isFalse);
        expect(refMatItem.uuidsMateriais, equals(['uuid-mat-1']));

        final subLista = item1.nodos[3] as SecaoListaRelatorio;
        expect(subLista.rotulo, equals('Ensaios de Arrancamento'));
        final subItem = subLista.itens.single;
        expect(subItem.indiceFormatado, equals('#1.1'));
        expect(subItem.rotuloTipo, equals('Ensaio de Tração'));
        final gradeSubItem = subItem.nodos.single as GradePropriedadesRelatorio;
        expect(
          gradeSubItem.propriedades.single.rotulo,
          equals('Carga Aplicada (kN)'),
        );
        expect(gradeSubItem.propriedades.single.valor, equals('25 kN'));
      },
    );

    test(
      'extrai UUIDs de materiais referenciados pelo tipo StepRefMateriais e resolve fallback de título',
      () {
        final registro = Registro(
          idSessao: 's-2',
          idProtocolo: 'protocolo_teste',
          yamlConteudo: yamlProtocoloCompleto,
          listas: [
            GrupoRepetido(
              idLista: 'lista_intervencoes',
              idItem: 'it1',
              idTipo: 'tipo_desconhecido',
            )..respostasItem.addAll({
                'mat_usado': Resposta(
                  lista: ListaRespostas(
                    valores: [Resposta(texto: 'mat-c')],
                  ),
                ),
              }),
          ],
        )..respostas.addAll({
            'selecao_catalogo': Resposta(texto: 'mat-a, mat-b'),
            'autorizado': Resposta(booleano: false),
            'tipo_rocha': Resposta(texto: 'valor_desconhecido'),
            'condicao_final': Resposta(texto: 'opcao_nao_listada'),
            'observacoes_longas': Resposta(
              lista: ListaRespostas(
                valores: [
                  Resposta(
                    midia: ReferenciaMidia(
                      imagem: ArquivoImagem(uuid: 'img-extra'),
                    ),
                  ),
                ],
              ),
            ),
          });

        final uuids =
            ConstrutorArvoreRelatorio.extrairUuidsMateriaisReferenciados(
              registro,
            );
        expect(uuids, equals(['mat-a', 'mat-b', 'mat-c']));

        final arvore = ConstrutorArvoreRelatorio().construir(
          registro,
          fallbackTitulo: 'Título Fallback',
        );
        expect(arvore.tituloExibicao, equals('Título Fallback'));
        expect(
          ConstrutorArvoreRelatorio.extrairTituloExibicao(
            registro,
            fallback: 'Título Direto',
          ),
          equals('Título Direto'),
        );

        final arvoreSemFallback = ConstrutorArvoreRelatorio().construir(
          registro,
        );
        expect(
          arvoreSemFallback.tituloExibicao,
          equals('Protocolo de Vistoria Completa'),
        );

        final arvoreTraduzidaEn = ConstrutorArvoreRelatorio().construir(
          registro,
          codigoIdioma: 'en',
          traducoes: {
            'protocolo': {'nome': 'Full Inspection Protocol'},
            'conteudos': {
              'autorizado': {'label': 'Has Authorization?'},
            },
          },
        );
        expect(arvoreTraduzidaEn.nomeProtocolo, equals('Full Inspection Protocol'));
        final gradeEn = arvoreTraduzidaEn.blocos[1].nodos[0] as GradePropriedadesRelatorio;
        expect(
          gradeEn.propriedades.map((p) => '${p.rotulo}: ${p.valor}').toList(),
          contains('Has Authorization?: No'),
        );
      },
    );
  });
}
