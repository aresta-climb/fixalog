# Proposal

## Why

Atualmente, os protocolos de manutenção exigem que o mantenedor cadastre manualmente todos os materiais na hora da escalada dentro da própria sessão da via, sem reutilização entre manutenções e sem espaço para documentar processos prévios realizados na oficina (como fabricação própria de chumbadores químicos com corte e repassivação, testes de qualidade e notas fiscais). Permitir o cadastro prévio (ou sob demanda) de materiais e conjuntos como registros assinados independentes — e embuti-los de forma íntegra nos relatórios de manutenção — elimina o retrabalho em parede e eleva a rastreabilidade pericial dos equipamentos instalados.

## What Changes

- **Novo Protocolo de Cadastro de Materiais (`cadastro_material.yaml`) e Entrada na Tela Inicial**:
  - Inclusão de um novo card na tela inicial (`NewProtocolScreen`) para abertura do protocolo de cadastro de materiais guiado pelo motor do Wizard.
  - Suporte ao registro de um único material ou de um conjunto/kit de materiais (via `StepListaAcoes`), assinados conjuntamente ao final.
  - Padronização das 6 categorias de material: `"Chumbador Mecânico / Parabolt"`, `"Chapeleta"`, `"Chapeleta com Argola"`, `"Ancoragem Química"`, `"Costura permanente"` (com campos pré-selecionados de produto pronto) e `"Outro"` (focado diretamente nos detalhes livres).
  - Seção universal padronizada dentro de cada material cadastrado contendo: **Nota Fiscal / Comprovante**, **Testes de Qualidade** e **Detalhes / Processo de Fabricação** (lista repetível livre com texto, fotos e vídeos curtos).
- **Evoluções no Motor do Wizard (`wizard.proto`, `WizardStateController`, `WizardScreen`)**:
  - Isolamento do estado do Wizard por instância/escopo (deixando de ser um singleton global único) para permitir abrir o Wizard de Cadastro de Material de forma empilhada durante uma manutenção em andamento.
  - Suporte a preenchimento automático da data atual (editável pelo usuário) em campos do tipo `DATE`.
  - Suporte a listas repetíveis aninhadas (`StepListaAcoes` renderizado dentro de itens de outra `StepListaAcoes`), viabilizando as sub-listas de testes e detalhes/etapas para cada material.
  - Evolução da seleção de materiais na manutenção para listar os materiais cadastrados no aplicativo (ordenados pela data de última seleção) ou cadastrar um novo material na hora abrindo a mesma tela dedicada.
- **Separação no Histórico (`HistoryScreen` e `SubmissionRecord`)**:
  - Distinção entre registros de **Manutenções** e registros de **Materiais** no banco local Isar (`SubmissionRecord`) e na tela de Histórico, permitindo visualizar, exportar/compartilhar isoladamente, editar e re-assinar materiais.
- **Composição de Relatórios EPUB 3 e PDF Resumido**:
  - No EPUB 3 da manutenção, inclusão sem duplicação do conteúdo extraído do `.epub` de cada material utilizado dentro de `OEBPS/materiais/<uuid_material>/`, mantendo o `registro.binarypb` e o `META-INF/signatures.xml` originais do material intactos para validação criptográfica independente.
  - Criação de hiperlinks ao longo do relatório da manutenção apontando para as páginas dos materiais anexados, com botão de retorno para voltar ao ponto de leitura anterior.
  - No PDF Resumido da manutenção, unificação em um único arquivo PDF contendo o relatório da manutenção seguido pelos relatórios dos materiais utilizados.
  - Atualização automática para a versão mais recente assinada do material caso o relatório da manutenção seja re-gerado no futuro (com fallback para a cópia já embutida caso o material tenha sido removido do catálogo).

## Capabilities

### New Capabilities
- `catalogo-materiais`: Cadastro, catalogação, edição, re-assinatura e seleção de materiais ou conjuntos de manutenção (comprados prontos ou de fabricação própria), com suporte padronizado a notas fiscais, testes de qualidade e detalhes/etapas de fabricação.

### Modified Capabilities
- `unified-wizard-engine`: Isolamento de estado para múltiplos Wizards encadeados, inicialização automática editável de data atual em campos `DATE`, renderização de `StepListaAcoes` aninhadas e seleção de materiais cadastrados localmente.
- `history-tracking`: Categorização e exibição separada de materiais cadastrados e manutenções realizadas na tela de Histórico, com rastreamento de última seleção.
- `epub3-report`: Aninhamento da estrutura extraída do EPUB 3 assinado de cada material dentro de `OEBPS/materiais/<uuid>/` no container EPUB 3 da manutenção, com navegação por links de ida e volta e preservação da assinatura original do material.
- `pdf-generator`: Inclusão sequencial dos relatórios dos materiais utilizados ao final do documento PDF resumido da manutenção.

## Impact

- **Schemas Protobuf**: `app/protos/wizard.proto` e `app/protos/registro.proto` (e arquivos `.pb.dart` gerados).
- **Banco Local (Isar)**: `app/lib/core/models/local/submission_record.dart` (novos campos de categoria/tipo, título de exibição e timestamp de última seleção).
- **Protocolos YAML**: Novo `app/assets/protocols/cadastro_material.yaml` e atualização de `app/assets/protocols/manutencao_ferragens.yaml`.
- **Motor do Wizard**: `app/lib/features/wizard/controllers/wizard_state_controller.dart` e `app/lib/features/wizard/views/wizard_screen.dart`.
- **Home e Histórico**: `app/lib/features/home/views/new_protocol_screen.dart`, `app/lib/features/home/views/history_screen.dart` e `app/lib/features/home/providers/history_provider.dart`.
- **Serviços de Relatório (EPUB 3 e PDF)**: `app/lib/core/services/epub_document_builder.dart`, `app/lib/core/services/epub_packager_service.dart`, `app/lib/core/services/pdf_print_summary_service.dart`, `app/lib/features/pdf_generation/providers/generation_provider.dart` e `app/lib/features/pdf_generation/views/visualizador_relatorio_screen.dart`.
