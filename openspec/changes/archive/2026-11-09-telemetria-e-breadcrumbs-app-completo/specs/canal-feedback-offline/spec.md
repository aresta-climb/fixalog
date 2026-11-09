## ADDED Requirements

### Requirement: Anexo Automático de Breadcrumbs nos Metadados do Feedback
O `ServicoFilaFeedback` DEVE (MUST) incluir automaticamente a lista cronológica de eventos recentes obtida de `GravadorBreadcrumbs.instancia.obterBreadcrumbs()` no campo `breadcrumbs` do `metadadosJson` de cada `FeedbackRecord` enfileirado.

#### Scenario: Enfileiramento de feedback após navegação pelo aplicativo
- **WHEN** o auditor realiza ações no aplicativo e envia um relato através do `ServicoFilaFeedback.enfileirarEDespacharFeedback`
- **THEN** o `metadadosJson` salvo no `FeedbackRecord` contém a chave `breadcrumbs` com a lista das últimas ações registradas no `GravadorBreadcrumbs`
