# Design

## Context

Conforme detalhado em `proposal.md`, o `EpubDocumentBuilder` e o `PdfPrintSummaryService` atualmente iteram sobre `registro.respostas` e `registro.listas` sem interpretar o `registro.yamlConteudo`. O `WizardStateController` já persiste obrigatoriamente o YAML bruto em `registro.yamlConteudo` e armazena:
- Respostas de fluxo principal em `registro.respostas[conteudoId]` (incluindo respostas de sub-steps injetados por `StepSelecaoRamo` no fluxo principal).
- Itens de listas repetíveis (`StepListaAcoes`) em `registro.listas` como `GrupoRepetido(idLista, idItem, idTipo, respostasItem)`.
- Sub-listas aninhadas (uma `StepListaAcoes` dentro dos `steps` de um `TipoAcao`) em `registro.listas` com `idLista = "${subListaConteudoId}__${parentItemId}"`.

Precisamos de uma arquitetura Library-First que interprete qualquer `DefinicaoProtocolo` (`wizard.proto`) cruzado com `Registro` (`registro.proto`) em uma única representação semântica consumida tanto pelo gerador de EPUB 3 quanto pelo gerador de PDF A4.

## Goals / Non-Goals

**Goals:**
- Construir um motor semântico determinístico (`ConstrutorArvoreRelatorio`) em `app/lib/core/services/construtor_arvore_relatorio.dart` que transforme `(Registro)` (com `yamlConteudo` obrigatório) em uma árvore hierárquica de relatório pronta para renderização.
- Eliminar 100% dos *hardcodes* de nomes de campos (ex.: `lista_materiais_c`, `ref_mat`, `mat_nome`, `via_nome`), baseando toda a semântica nos tipos de `ConteudoStep` e `StepCampoSimples` do `wizard.proto`.
- Agrupar visualmente campos curtos adjacentes em grades de 2 colunas e campos de imagem adjacentes (ou múltiplas imagens de um campo) em galerias lado a lado, tanto no XHTML/CSS do EPUB 3 quanto nos widgets `package:pdf` do PDF Resumido.

**Non-Goals:**
- Manter fallbacks para registros sem `yamlConteudo`: o contrato exige `yamlConteudo` válido; se estiver vazio, o construtor lança `FormatException` explícita.
- Alterar o formato binário de persistência (`registro.proto` ou `wizard.proto`) ou a assinatura criptográfica XML-DSig.

## Decisions

### 1. Biblioteca Independente de Árvore Semântica (`ConstrutorArvoreRelatorio`)
- **Decisão**: Criar `app/lib/core/services/construtor_arvore_relatorio.dart` contendo modelos imutáveis em português (`ArvoreRelatorio`, `BlocoRelatorio`, `NodoRelatorio` — polimórfico para `GradePropriedadesRelatorio`, `DestaqueEscolhaRelatorio`, `TextoLongoRelatorio`, `GaleriaMidiasRelatorio`, `ReferenciasMateriaisRelatorio`, `SecaoListaRelatorio`, `ItemListaRelatorio`) e o serviço `ConstrutorArvoreRelatorio`.
- **Racional**: Isola toda a regra de negócio de travessia recursiva do YAML, resolução de `DROPDOWN`/`selecao_ramo`, poda de vazios, omissão de `StepInstrucao` e agrupamento de campos/fotos adjacentes em uma biblioteca pura, testável isoladamente (Princípio II do `AGENTS.md`) e compartilhada entre `EpubDocumentBuilder` e `PdfPrintSummaryService` sem duplicar lógica.
- **Alternativas consideradas**: Fazer o parse do YAML separadamente dentro de `EpubDocumentBuilder` e `PdfPrintSummaryService`. Descartado pois duplicaria a lógica recursiva de ramos e sub-listas aninhadas.

### 2. Algoritmo Recursivo Unificado para Fluxo Principal e Itens Inline (`_resolverSteps`)
- **Decisão**: A resolução de uma lista de `Step`s recebe um contexto de escopo de respostas:
  - No escopo raiz (`idItemPai == null`), lê respostas de `registro.respostas[conteudo.id]` e listas de `registro.listas.where((g) => g.idLista == conteudo.id)`.
  - No escopo de um item de lista (`idItemPai != null`), lê respostas de `grupoAtual.respostasItem[conteudo.id]` e sub-listas de `registro.listas.where((g) => g.idLista == '${conteudo.id}__$idItemPai')`.
  - Ao encontrar `ConteudoStep_Tipo.instrucao`: ignora imediatamente.
  - Ao encontrar `ConteudoStep_Tipo.selecaoRamo`: busca o valor textual da resposta; se preenchido, localiza o `Ramo` correspondente em `selecaoRamo.ramos`, emite um `DestaqueEscolhaRelatorio(rotulo: selecaoRamo.label, valorEscolhido: ramo.label, subrotuloEscolhido: ramo.sublabel)` e invoca recursivamente `_resolverSteps(ramo.steps)` no mesmo escopo de respostas.
  - Ao encontrar `ConteudoStep_Tipo.listaAcoes`: busca os `GrupoRepetido` correspondentes ao escopo; se houver itens preenchidos, para cada `GrupoRepetido` localiza o `TipoAcao` em `listaAcoes.tiposDisponiveis`, resolve recursivamente `_resolverSteps(tipoAcao.steps, idItemPai: grupo.idItem, respostasEscopo: grupo.respostasItem)` e monta o `ItemListaRelatorio` numerado (`#1`, `#2`, ou `#1.1` em sub-listas).

### 3. Coleta de UUIDs de Materiais e Resolução de Títulos pelo Schema (`StepRefMateriais`)
- **Decisão**: O método `extrairUuidsMateriaisReferenciados(Registro)` passa a percorrer a `DefinicaoProtocolo` (via `ProtocolParser.fromYaml(registro.yamlConteudo)`) identificando todos os `ConteudoStep` onde `hasRefMateriais()` e `refMateriais.origemCatalogo == true` (ou qualquer `hasRefMateriais()` cujos valores sejam UUIDs de materiais externos), extraindo os UUIDs selecionados sem depender de nomes fixos de chaves.
- **Racional**: Permite que qualquer protocolo futuro declare um campo `ref_materiais` com qualquer `id` e tenha seus materiais automaticamente empacotados, linkados no EPUB e anexados no PDF.

### 4. Agrupamento Visual Inteligente (Grades de Propriedades e Galerias Lado a Lado)
- **Decisão**: Durante a consolidação dos nodos de um escopo (Bloco ou Item de Lista):
  - Campos simples curtos consecutivos (`TEXT` sem `TEXT_AREA`, `NUMBER`, `DATE`, `BOOLEAN`, `GPS`, e `DROPDOWN` sem `LARGE_TILES` que não possuam mídias anexadas) são agrupados em um único bloco `GradePropriedadesRelatorio(itens: [...])`, renderizado como CSS Grid de 2 colunas no EPUB e como grade de 2 colunas (`pw.Row` em pares) no PDF.
  - Campos de mídia consecutivos (ou um campo com múltiplas fotos) geram `GaleriaMidiasRelatorio`, onde cada foto carrega o `label` do seu `StepCampoSimples` (ex.: *"Foto antes da remoção"*, *"Foto após remoção"*). No EPUB e no PDF, fotos são dispostas em grid de 2 colunas lado a lado, permitindo comparação imediata Antes/Depois e reduzindo drasticamente a altura vertical do relatório.

## Risks / Trade-offs

- **[Risco] Testes existentes que instanciam `Registro()` sem `yamlConteudo`** → **Mitigação**: Como decidimos exigir `yamlConteudo` sem fallbacks legados, atualizaremos os testes unitários e de widgets existentes que testam geração de EPUB/PDF para fornecerem um YAML de protocolo válido no `Registro`, mantendo 100% de fidelidade com o comportamento real do app.
