# Design

## Context

O Fixalog já possui um motor declarativo de formulários baseado em YAML e Protobuf (`DefinicaoProtocolo` em `wizard.proto` e `Registro` em `registro.proto`), persistência de bundles de sessão em disco (`SessionBundleManager`), indexação local no banco `Isar` (`SubmissionRecord`) e pipeline de emissão de relatórios assinados em EPUB 3 (`EpubDocumentBuilder`, `EpubPackagerService`, `XmlDsigSigner`) e PDF Resumido (`PdfPrintSummaryService`).

No entanto, o motor atual possui quatro limitações estruturais para atender ao fluxo de materiais (ver `proposal.md - Why`):
1. O `wizardControllerProvider` é um `NotifierProvider` global único, impedindo que uma tela `WizardScreen` (cadastro de material) seja empilhada sobre outra `WizardScreen` (manutenção em andamento) sem sobrescrever o estado ativo.
2. O renderizador inline (`InlineConteudoRenderer`) suporta campos simples, instruções, seleção de ramo e referência a materiais, mas não renderiza `StepListaAcoes` aninhadas dentro de um item de outra `StepListaAcoes`.
3. O componente `StepRefMateriais` só busca itens dentro de uma lista da própria sessão em memória, não consultando registros de materiais persistidos no catálogo local.
4. O empacotador EPUB 3 e o gerador de PDF processam apenas um único `Registro` plano por vez.

## Goals / Non-Goals

**Goals:**
- Reutilizar integralmente o motor do Wizard (`WizardScreen`, `WizardStateController`, `SessionBundleManager`, `GenerationNotifier`) para o cadastro, assinatura, visualização e edição de materiais.
- Permitir múltiplos `WizardScreen` empilhados na navegação com isolamento total de estado.
- Estender o `wizard.proto` e o motor do Wizard com preenchimento automático de data atual (`preencher_data_atual`), listas repetíveis aninhadas (`StepListaAcoes` inline) e seleção de materiais do catálogo local (`StepRefMateriais` com fonte no catálogo).
- Embutir o pacote EPUB 3 extraído de cada material utilizado dentro de `OEBPS/materiais/<uuid_material>/` no EPUB 3 da manutenção sem duplicar arquivos de mídia e preservando a validade criptográfica do `META-INF/signatures.xml` original do material.
- Unificar no PDF Resumido da manutenção o relatório da via seguido pelas fichas técnicas dos materiais utilizados.
- Manter 100% de cobertura comportamental e espelhamento 1:1 de testes conforme o `AGENTS.md`.

**Non-Goals:**
- Criar uma nova aba na barra de navegação inferior (`BottomNavigationBar`) do aplicativo (a entrada será via card na `NewProtocolScreen` e a gestão via filtro na `HistoryScreen`).
- Sincronização em nuvem de catálogos de materiais entre múltiplos dispositivos neste momento (operação 100% Offline-First).
- Controle quantitativo de baixa de estoque (ex: subtrair 2 parabolts de uma caixa de 50).

## Decisions

### 1. Isolamento de Escopo do `WizardStateController` para Wizards Encadeados
- **Decisão**: Manter o `wizardControllerProvider` padrão, mas envolver cada instância de `WizardScreen` (quando aberta de forma aninhada/modal para cadastro sob demanda) em um `ProviderScope` próprio com override de `wizardControllerProvider` (ou parametrizar o controlador por escopo de sessão), fazendo com que `Navigator.push<String>` retorne o `idSessao` (`uuid`) do material recém-gerado e assinado para o `WizardScreen` pai.
- **Racional**: Ao usar `ProviderScope(overrides: [wizardControllerProvider.overrideWith(WizardStateController.new)])` na rota empilhada, todos os widgets filhos (`CampoSimplesWidget`, `ListaAcoesWidget`, `InlineItemCard`, etc.) continuam lendo `ref.watch(wizardControllerProvider)` sem precisar passar `sessionId` manualmente por dezenas de construtores de widgets, preservando 100% da retrocompatibilidade e isolando completamente a memória da sessão pai e da sessão filha.
- **Alternativas consideradas**:
  - *Converter `wizardControllerProvider` para `.family<WizardState, String>`*: Exigiria propagar o `sessionId` como parâmetro obrigatório em todos os sub-widgets de `wizard_screen.dart` e quebraria a assinatura dos testes existentes sem ganho arquitetural.

### 2. Representação de Listas Aninhadas (`StepListaAcoes` dentro de `StepListaAcoes`)
- **Decisão**: No `WizardStateController`, quando uma `StepListaAcoes` é renderizada dentro de um item de lista pai (`parentItemId`), a chave da sub-lista no mapa `state.lists` e `state.expandedListItems` será composta no formato `"${subListConteudoId}__${parentItemId}"` — seguindo exatamente a convenção já adotada para respostas inline em `state.answers` (`"${conteudoId}__${itemId}"`). Na serialização para `Registro.listas` (`GrupoRepetido`), o campo `id_lista` armazenará `"${subListConteudoId}__${parentItemId}"`, permitindo reconstrução exata e determinística em `loadSession()`.
- **Racional**: Reaproveita o modelo de chave composta já consolidado no controlador e evita quebrar a estrutura binária de `GrupoRepetido` em `registro.proto`.
- **Alternativas consideradas**:
  - *Criar recursão infinita de mensagens `GrupoRepetido` dentro de `GrupoRepetido` no Protobuf*: Aumentaria a complexidade do parser de relatórios sem necessidade, já que a chave composta `"${idLista}__${idItemPai}"` resolve o vínculo pai-filho em $O(1)$.

### 3. Padronização do Protocolo `cadastro_material.yaml`
- **Decisão**: Definir `app/assets/protocols/cadastro_material.yaml` com:
  1. **Bloco 1 (Identificação Geral)**: `mat_nome` (`TEXT`, obrigatório — usado como título de exibição no Histórico e no seletor), `mat_codigo_associacao` (`TEXT`, opcional) e `mat_data` (`DATE` com `preencher_data_atual: true`).
  2. **Bloco 2 (Lista de Materiais — `StepListaAcoes`, mínimo 1)**: Permite registrar um único material ou um conjunto de materiais. Disponibiliza os 6 tipos (`parabolt`, `chapeleta`, `chapeleta_argola`, `ancoragem_quimica`, `costura_permanente`, `outro`). Os 5 primeiros possuem seus campos pré-definidos de produto pronto no início; o tipo `outro` possui apenas identificação livre; e **todos os 6 tipos** compartilham a mesma estrutura final composta por:
     - Campos de **Nota Fiscal / Comprovante** (foto/comprovante e descrição/fornecedor opcionais);
     - Sub-lista `StepListaAcoes` de **Testes de Qualidade** (`0..N` itens com descrição, foto e vídeo curto);
     - Sub-lista `StepListaAcoes` de **Detalhes / Processo de Fabricação** (`0..N` itens com título/etapa, descrição livre, foto e vídeo curto).
  3. **Bloco 3 (Declaração e Assinatura)**: Campo `SIGNATURE` obrigatório para emissão do EPUB 3 assinado.
- **Racional**: Garante que qualquer material (comprado pronto ou fabricado em oficina, individual ou em conjunto) siga um contrato uniforme para renderização nos relatórios e auditoria.

### 4. Evolução do `StepRefMateriais` e Integração com o Catálogo Local (`Isar`)
- **Decisão**:
  - Adicionar em `SubmissionRecord` (`submission_record.dart`):
    - `tipoRegistro`: `'MANUTENCAO'` (padrão) ou `'MATERIAL'` (identificado pelo `idProtocolo == 'cadastro_material'` ou metadado de categoria no protocolo).
    - `tituloExibicao`: Nome amigável extraído da resposta principal do protocolo (ex: `mat_nome` para materiais ou `via_nome` para manutenções), com fallback para `nomeProtocolo`.
    - `dataUltimaSelecao`: `DateTime?` atualizado sempre que um material é selecionado em uma manutenção.
  - Em `manutencao_ferragens.yaml`, o **Bloco 1** passa a usar um `StepRefMateriais` com `origem_catalogo: true` (selecionando materiais gerados do catálogo local, ordenados por `dataUltimaSelecao` decrescente e depois `dataInclusao` decrescente, com botão `+ CADASTRAR NOVO MATERIAL`).
  - Nos passos de ações na via (**Bloco 3** de `manutencao_ferragens.yaml`), os campos `StepRefMateriais` (que apontam para o passo do Bloco 1) permitem marcar quais dos materiais selecionados no Bloco 1 foram aplicados naquela ação específica (ou selecionar/cadastrar diretamente).
- **Racional**: Mantém o fluxo natural em parede: no início da manutenção o mantenedor marca quais materiais do seu catálogo levou para a via (ou cadastra um na hora), e em cada proteção/ação marca com um toque qual daqueles materiais instalou.

### 5. Aninhamento Bit-a-Bit no EPUB 3 e Fusão no PDF Resumido
- **Decisão**:
  - **Estrutura no EPUB 3 da Manutenção**:
    - Para cada `uuid_material` referenciado na manutenção, o `GenerationNotifier` localiza o `.epub` assinado daquele material no catálogo local (ou, em caso de re-geração onde o material foi excluído do catálogo, lê a cópia já existente dentro do `.epub` anterior da manutenção).
    - O conteúdo do `.epub` do material (exceto `mimetype`) é extraído e incluído sob o prefixo `OEBPS/materiais/<uuid_material>/` no arquivo ZIP do EPUB da manutenção (contendo `OEBPS/materiais/<uuid_material>/META-INF/signatures.xml`, `OEBPS/materiais/<uuid_material>/OEBPS/relatorio.xhtml`, `OEBPS/materiais/<uuid_material>/OEBPS/dados/registro.binarypb`, `OEBPS/materiais/<uuid_material>/OEBPS/midias/...`).
    - Todos esses arquivos são adicionados ao mapa `recursosAssinatura` da manutenção para que o `META-INF/signatures.xml` da manutenção assine o conjunto completo, enquanto o `OEBPS/materiais/<uuid_material>/META-INF/signatures.xml` permanece intacto e verificável isoladamente em relação à subpasta `OEBPS/materiais/<uuid_material>/`.
  - **Links de Ida e Volta**:
    - No `OEBPS/relatorio.xhtml` da manutenção, cada referência a um material renderiza um hiperlink `<a href="materiais/<uuid_material>/OEBPS/relatorio.xhtml">Ver Ficha do Material: <Nome></a>` (além de uma seção de índice de materiais anexos no final do relatório da manutenção e no `nav.xhtml`).
    - No `EpubDocumentBuilder`, o XHTML gerado possui no topo uma barra/botão de retorno (`javascript:history.back()`) visível quando aberto via navegação interna, permitindo ao leitor clicar para ver os detalhes do material e voltar exatamente ao ponto de leitura da manutenção.
  - **Fusão no PDF Resumido**:
    - O `PdfPrintSummaryService.exportarPdfResumido` recebe (além do `Registro` principal da manutenção) a lista de registros e mídias dos materiais vinculados (lidos de `OEBPS/materiais/<uuid_material>/`), adicionando ao final do mesmo documento PDF uma seção de **Anexos: Materiais Utilizados** com as fichas completas de cada material.

## Risks / Trade-offs

- **[Risco] Exclusão acidental de um material do catálogo que já foi usado em uma manutenção em andamento (`EM_PROGRESSO`)** → **Mitigação**: Se uma manutenção já foi gerada (`GERADO`), o `.epub` da manutenção já contém a pasta `OEBPS/materiais/<uuid>/` embutida. Caso o material seja excluído do catálogo antes de uma re-geração, o gerador faz fallback para os arquivos já embutidos no `.epub` anterior da manutenção.
- **[Risco] Conflito de caminhos relativos de mídias e CSS no EPUB aninhado** → **Mitigação**: Como o material fica em `OEBPS/materiais/<uuid>/OEBPS/relatorio.xhtml` junto com seu próprio `estilo.css` e sua pasta `midias/`, todas as referências internas do XHTML do material (`href="estilo.css"`, `src="midias/..."`) continuam resolvendo perfeitamente para os arquivos dentro de `OEBPS/materiais/<uuid>/OEBPS/` sem precisar reescrever o HTML assinado do material (o que invalidaria a assinatura original dele!).

## Migration Plan

1. Atualizar `wizard.proto` e `registro.proto` (se aplicável) e regerar os arquivos Dart Protobuf (`protoc`).
2. Atualizar `SubmissionRecord` e regerar `submission_record.g.dart` (`build_runner`), mantendo valores default compatíveis para registros já existentes no Isar (`tipoRegistro = 'MANUTENCAO'`).
3. Evoluir `WizardStateController` e `WizardScreen` (isolamento via `ProviderScope`, `preencher_data_atual`, `StepListaAcoes` inline e `StepRefMateriais` conectado ao catálogo).
4. Criar `app/assets/protocols/cadastro_material.yaml`, atualizar `app/assets/protocols/manutencao_ferragens.yaml`, `NewProtocolScreen` e `HistoryScreen`.
5. Atualizar `EpubDocumentBuilder`, `EpubPackagerService`, `GenerationNotifier`, `VisualizadorRelatorioScreen` e `PdfPrintSummaryService` para suportar o aninhamento de materiais no EPUB 3 e a concatenação no PDF Resumido.
