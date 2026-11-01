# Spec Delta: session-bundle-storage

## MODIFIED Requirements

### Requirement: Exclusão de Sessão (Garbage Collection)
O sistema DEVE (MUST) excluir integralmente o diretório do Session Bundle quando o registro for removido do Histórico pelo usuário.

#### Scenario: Exclusão Limpa
- **WHEN** o usuário exclui um relatório a partir do Histórico
- **THEN** o sistema deleta o registro do banco de dados local SQLite
- **THEN** o sistema exclui a pasta `/documentos/sessoes/<id_sessao>/` recursivamente do disco local
