# Spec Delta

## ADDED Requirements

### Requirement: Estruturação Semântica do Relatório Guiada pelo Protocolo YAML
O sistema DEVE construir o documento `relatorio.xhtml` do EPUB 3 interpretando obrigatoriamente a definição do protocolo contida em `registro.yamlConteudo`. O relatório DEVE organizar as seções pelos `Bloco`s do protocolo e traduzir todos os identificadores de campos, opções de `DROPDOWN`, escolhas de `selecao_ramo`, listas (`lista_acoes`) e referências de materiais (`ref_materiais`) para seus rótulos humanos (`label` e `sublabel`) definidos no YAML, sem exibir chaves internas brutas.

#### Scenario: Renderização de protocolo com blocos, dropdowns e ramos traduzidos
- **WHEN** o sistema gera o relatório EPUB 3 de um registro contendo `yamlConteudo` preenchido com blocos, campos `DROPDOWN` e escolhas de `selecao_ramo`
- **THEN** o `relatorio.xhtml` exibe o nome e versão do protocolo no cabeçalho, divide as seções pelos títulos e subtítulos dos `Bloco`s e apresenta os `label` e `sublabel` humanos de cada pergunta e opção escolhida em vez dos IDs técnicos

### Requirement: Omissão de Instruções do Wizard e de Campos Opcionais Vazios no Relatório
Ao gerar o relatório EPUB 3, o sistema DEVE omitir integralmente todos os elementos de orientação (`StepInstrucao`) e DEVE ocultar quaisquer campos opcionais, listas repetíveis, passos ou blocos que não possuam respostas preenchidas no registro.

#### Scenario: Protocolo contendo instruções de preenchimento e campos opcionais em branco
- **WHEN** um registro é compilado para EPUB 3 a partir de um protocolo que possui cards `instrucao` e campos ou sub-listas opcionais não preenchidos pelo usuário
- **THEN** nenhum título ou corpo de `StepInstrucao` é incluído no `relatorio.xhtml` e os campos, sub-listas e blocos sem respostas são omitidos do documento final

### Requirement: Aninhamento Recursivo de Ramos Condicionais e Sub-listas no EPUB 3
O gerador do relatório EPUB 3 DEVE expandir os passos internos de cada ramo condicional escolhido (`StepSelecaoRamo`) na sequência imediata da decisão e DEVE aninhar visualmente todas as sub-listas repetíveis (`StepListaAcoes` vinculadas a um item pai via sufixo `__<idItemPai>`) dentro do cartão do item pai correspondente, em qualquer nível de profundidade.

#### Scenario: Material com sub-listas de testes de qualidade e etapas de fabricação
- **WHEN** o relatório EPUB 3 de um material contendo componentes com sub-listas de "Testes de Qualidade" e "Detalhes e Processo de Fabricação" é gerado
- **THEN** cada teste de qualidade e etapa de fabricação é renderizado aninhado dentro do cartão do respectivo componente pai, exibindo o rótulo da sub-lista e do tipo de item sem expor o sufixo `__<idItemPai>`

#### Scenario: Ação de manutenção com seleção de ramo recursiva
- **WHEN** uma ação de manutenção possui uma escolha condicional (`selecao_ramo`) que abre sub-passos e outra escolha condicional aninhada
- **THEN** o cartão da ação renderiza na ordem exata a primeira decisão, os sub-passos intermediários, a segunda decisão e os campos finais preenchidos

### Requirement: Layout Visual de Grades de Propriedades, Galerias de Mídia e Sumário no EPUB 3
O documento `relatorio.xhtml` e sua folha `estilo.css` DEVEM agrupar campos simples curtos em grade de propriedades, destacar escolhas de `LARGE_TILES` e `selecao_ramo`, exibir fotos em layout de galeria lado a lado (grid responsivo) acompanhadas do `label` do campo correspondente, e o documento `nav.xhtml` DEVE listar os nomes reais dos materiais anexados em vez de seus UUIDs.

#### Scenario: Comparação visual de fotos Antes e Depois em uma ação
- **WHEN** um passo ou item de ação contém campos de imagem preenchidos (como "Foto antes da intervenção" e "Foto após instalação")
- **THEN** o `relatorio.xhtml` renderiza as imagens em uma galeria em grid identificada pelo `label` de cada campo

#### Scenario: Sumário de navegação com nomes dos materiais anexados
- **WHEN** o pacote EPUB 3 de uma manutenção é empacotado com materiais aninhados
- **THEN** o arquivo `OEBPS/nav.xhtml` exibe os títulos de exibição dos materiais nos links de navegação
