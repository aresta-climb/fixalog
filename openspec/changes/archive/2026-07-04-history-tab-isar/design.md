## Context

Atualmente, o FixaLog permite criar registros expressos preenchendo um formulário rápido, tirando fotos e gerando um relatório em PDF assinado. No entanto, o histórico dessas submissões não é salvo localmente. A aba "Histórico" no menu principal contém apenas dados de demonstração (mock) inseridos estaticamente na UI. O objetivo é fechar o fluxo persistindo cada geração de relatório e renderizando-os dinamicamente.

## Goals / Non-Goals

**Goals:**
- Persistir dados do relatório no Isar após geração bem sucedida do PDF.
- Adaptar o arquivo `history_screen.dart` para consumir e exibir esses registros em ordem cronológica reversa.
- Integrar a leitura do Isar ao Riverpod, utilizando a infraestrutura atual do app.
- Seguir estritamente TDD (Test-Driven Development) e os preceitos do `PRINCIPIOS.md` (Library-First, Test-First).
- Atingir 100% de cobertura de testes unitários para as lógicas de negócio adicionadas.

**Non-Goals:**
- Sincronização em nuvem desses dados (backend ainda não é o foco; vamos nos ater ao Isar).
- Melhorias ou adições no design visual geral além de preencher a UI existente com dados verdadeiros e ajustar comportamento de scroll.

## Decisions

- **Persistência no generation_provider:** Ao final do fluxo em `startGeneration`, instanciar e salvar um `SubmissionRecord` no Isar, guardando os caminhos e nome do protocolo gerado. Isso garante que só arquivos criados com sucesso entrem no histórico.
- **Provider Local de Histórico:** Criar um `history_provider` na feature `home` (ou em `pdf_generation`) que expõe um Stream ou Future contínuo dos dados do Isar (`SubmissionRecord`). Isso separa as regras de negócio de visualização e mantêm a conformidade com a adoção do Riverpod no projeto.
- **Uso do SubmissionRecord Existente:** O modelo já se encontra implementado e gerado em `lib/core/models/local/submission_record.dart`, dispensando refatoração em outras áreas. Usaremos este modelo.

## Risks / Trade-offs

- **Falha ao Salvar Histórico:** 
  - *Mitigação:* Usaremos as transações seguras do Isar, garantindo que o log não falhe de maneira a corromper a base.
- **Tamanho das listas na tela:** A interface atual tem um número limitado de itens estáticos. Pode haver impacto visual se a lista for muito longa (necessário garantir que a SingleChildScrollView + Column atual, ou adoção de ListView.builder, lide bem).
  - *Mitigação:* Substituiremos a listagem bruta por `ListView.builder` embutido se a performance ditar, ou manteremos `Column` para MVPs rápidos dependendo do layout do gradiente base da tela de histórico.
