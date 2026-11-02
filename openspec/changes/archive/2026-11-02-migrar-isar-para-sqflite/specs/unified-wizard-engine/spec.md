# Spec Delta: unified-wizard-engine

## MODIFIED Requirements

### Requirement: Pipeline de Persistência Unificado
O motor do Wizard DEVE (MUST) persistir continuamente as alterações no manifesto Protobuf (`registro.binarypb`) e no banco local SQLite (`SubmissionRecord`) durante todo o ciclo de preenchimento, garantindo que nenhum progresso seja perdido caso o usuário saia da tela ou feche o app. Ao finalizar a última tela do Wizard, o motor consolida o registro para a geração do relatório final.

#### Scenario: Auto-Save Reativo durante o Preenchimento
- **WHEN** o usuário altera uma resposta de texto, captura uma mídia, seleciona um ramo ou adiciona um item de lista no Wizard
- **THEN** o `WizardStateController` serializa o estado para `registro.binarypb` no Session Bundle
- **THEN** o registro correspondente no banco local SQLite é criado ou atualizado com status `EM_PROGRESSO`

#### Scenario: Flush ao Fechar a Tela
- **WHEN** o usuário sai do `WizardScreen` antes de concluir a geração
- **THEN** qualquer estado pendente é persistido em disco e no banco local SQLite
- **THEN** a sessão fica disponível no Histórico com status `EM_PROGRESSO`

#### Scenario: Geração Final
- **WHEN** o usuário clica em "GERAR RELATÓRIO" no final do Wizard
- **THEN** as mídias são hasheadas (SHA-256) e movidas para o SessionBundle
- **THEN** o manifesto `.binarypb` é gerado
- **THEN** o registro no banco local SQLite é atualizado para o status `GERADO` após a conclusão do relatório
- **THEN** a task de geração do relatório é disparada com o diálogo de progresso
