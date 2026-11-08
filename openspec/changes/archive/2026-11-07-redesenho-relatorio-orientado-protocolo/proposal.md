# Proposal

## Why

Atualmente, os geradores de relatório em EPUB 3 (`EpubDocumentBuilder` / `EpubPackagerService`) e PDF Resumido (`PdfPrintSummaryService`) ignoram o `yamlConteudo` salvo no `Registro` Protobuf e iteram diretamente sobre os mapas brutos de `respostas` e `listas`. Isso produz um documento difícil de ler e acompanhar, com chaves técnicas internas (`via_tem_permissao`, `pb_liga: aco_inox_316`, `lista_itens_material_c (parabolt)`), ausência da divisão por Blocos do protocolo, fotos empilhadas sem contexto lado a lado e sub-listas aninhadas (como testes de qualidade e etapas de fabricação de materiais) desconectadas visualmente do item pai (`pb_testes__<idItem>`). Precisamos que a geração de relatórios siga a mesma filosofia declarativa e universal do Wizard: um motor único guiado pelo YAML do protocolo (`DefinicaoProtocolo`) capaz de estruturar e estilizar qualquer protocolo com hierarquia clara, rótulos humanos e aninhamento recursivo.

## What Changes

- **BREAKING**: O `Registro.yamlConteudo` passa a ser obrigatório para a construção dos relatórios em EPUB 3 e PDF Resumido, eliminando a renderização por despejo de chaves brutas e removendo *hardcodes* específicos de protocolo (como verificações nominais de `lista_materiais_c` ou `ref_mat`).
- **Novo Motor Semântico de Árvore de Relatório (`ConstrutorArvoreRelatorio`)**: Biblioteca independente em `app/lib/core/services/` que cruza `DefinicaoProtocolo` (via `ProtocolParser.fromYaml(registro.yamlConteudo)`) e `Registro` para produzir uma árvore semântica unificada do documento:
  - Organiza o relatório em seções correspondentes aos `Bloco`s do protocolo (`titulo` e `subtitulo`).
  - Traduz todos os identificadores de campos (`StepCampoSimples`), opções (`OpcaoCampo` em `DROPDOWN`), escolhas condicionais (`StepSelecaoRamo` / `Ramo`), listas (`StepListaAcoes` / `TipoAcao`) e referências de materiais (`StepRefMateriais`) para seus respectivos `label` e `sublabel` humanos definidos no YAML.
  - Expande recursivamente os passos (`steps`) dos ramos condicionais escolhidos (`StepSelecaoRamo`) na ordem exata do fluxo.
  - Aninha recursivamente sub-listas (`StepListaAcoes` cujos grupos têm `idLista` no formato `<idSubLista>__<idItemPai>`) dentro do Card do item pai correspondente, em qualquer profundidade.
  - Omite integralmente os elementos `StepInstrucao` (orientações de preenchimento exclusivas do Wizard) do relatório final.
  - Oculta automaticamente campos opcionais, sub-listas, passos e blocos que não possuam respostas preenchidas.
- **Redesenho Visual do Relatório EPUB 3 (`EpubDocumentBuilder` e `EpubPackagerService`)**:
  - Cabeçalho rico exibindo o nome do protocolo (`protocolo.nome`), descrição, versão, data/hora formatada e metadados de sessão.
  - Layout estruturado por Blocos e Cards, agrupando campos simples curtos (`TEXT` sem `TEXT_AREA`, `NUMBER`, `DATE`, `BOOLEAN`, `GPS`, `DROPDOWN` padrão) em grades compactas de propriedades (2 colunas responsivas), escolhas de destaque (`LARGE_TILES` e `StepSelecaoRamo`) como *badges* com subtítulo, textos longos (`TEXT_AREA`) com formatação Markdown e fotos (`IMAGE`) em galerias lado a lado (grid de 2 colunas) identificadas pelo `label` de cada campo.
  - Atualização do `nav.xhtml` no `EpubPackagerService` para exibir os títulos reais dos materiais anexados em vez dos seus UUIDs brutos.
- **Redesenho Editorial do PDF Resumido A4 (`PdfPrintSummaryService`)**:
  - Consumo da mesma árvore semântica (`ConstrutorArvoreRelatorio`) para renderizar o documento A4 nativo (`package:pdf`) com cabeçalho institucional refinado, numeração de páginas no rodapé, blocos bem delimitados, tabelas/grades de 2 colunas para propriedades curtas, galerias de fotos lado a lado (ex.: "Foto antes" e "Foto após" na mesma linha), cards numerados para itens de lista com sub-listas aninhadas visualmente e fichas técnicas anexas formatadas com o mesmo motor.

## Capabilities

### New Capabilities

### Modified Capabilities
- `epub3-report`: Passa a exigir `yamlConteudo` e construir o `relatorio.xhtml` e o `nav.xhtml` a partir da árvore semântica do protocolo (`DefinicaoProtocolo`), renderizando blocos, cards aninhados recursivamente, rótulos humanos do YAML, grades de propriedades e galerias de fotos lado a lado, omitindo `StepInstrucao` e campos vazios.
- `pdf-generator`: Passa a construir o PDF Resumido A4 (principal e anexos de materiais) a partir da mesma árvore semântica orientada ao protocolo YAML, organizando blocos, cards com sub-listas aninhadas, grades de 2 colunas para campos curtos e fotos com rótulos humanos, omitindo `StepInstrucao` e campos vazios.

## Impact

- **Código Afetado**:
  - `app/lib/core/services/construtor_arvore_relatorio.dart` (nova biblioteca de domínio para resolução da árvore semântica do relatório) e seu teste espelhado `app/test/core/services/construtor_arvore_relatorio_test.dart`.
  - `app/lib/core/services/epub_document_builder.dart` e `app/test/core/services/epub_document_builder_test.dart`.
  - `app/lib/core/services/epub_packager_service.dart` e `app/test/core/services/epub_packager_service_test.dart`.
  - `app/lib/core/services/pdf_print_summary_service.dart` e `app/test/core/services/pdf_print_summary_service_test.dart`.
  - `app/lib/features/pdf_generation/providers/generation_provider.dart` e `app/lib/features/pdf_generation/views/visualizador_relatorio_screen.dart` (e respectivos testes espelhados) para repassar títulos e garantir que os registros de teste possuam `yamlConteudo` válido.
- **Dependências**: Nenhuma nova dependência externa necessária (utiliza `yaml`, `protobuf` e `pdf` já presentes no projeto).
