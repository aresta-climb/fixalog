# Spec Delta: arquitetura-mvvm

## MODIFIED Requirements

### Requirement: O sistema deve adotar o Repository Pattern
O acesso a dados via banco de dados local SQLite (`sqflite`) DEVE (MUST) ser abstraído em Repositories ou no serviço `BancoDadosLocal` para permitir que a camada de visualização não conheça detalhes de consultas SQL.

#### Scenario: Leitura de Identidade
- **WHEN** O ViewModel solicita a Identidade atual
- **THEN** O ViewModel deve invocar `IdentityRepository.getCurrentIdentity()` ao invés de executar queries diretas na tabela SQLite de identidade
