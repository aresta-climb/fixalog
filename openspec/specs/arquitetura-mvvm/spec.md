# Arquitetura MVVM e Repositórios

## Purpose

Define o padrão arquitetural de separação entre camada de visualização (Views), gerenciamento de estado reativo (ViewModels/Controllers) e abstração de persistência local em SQLite (Repositories).

## Requirements

### Requirement: O sistema deve adotar o Repository Pattern
O acesso a dados via banco de dados local SQLite (`sqflite`) DEVE (MUST) ser abstraído em Repositories ou no serviço `BancoDadosLocal` para permitir que a camada de visualização não conheça detalhes de consultas SQL.

#### Scenario: Leitura de Identidade
- **WHEN** O ViewModel solicita a Identidade atual
- **THEN** O ViewModel deve invocar `IdentityRepository.getCurrentIdentity()` ao invés de executar queries diretas na tabela SQLite de identidade

### Requirement: O sistema deve adotar ViewModels
Os componentes de estado para as views devem ser nomeados como ViewModels e não devem manter dependência direta de contexto de banco.

#### Scenario: Submissão de Formulário
- **WHEN** A View envia os dados para o ViewModel
- **THEN** O ViewModel valida a regra de negócio e despacha para o Repository, atualizando o `State` reativamente.
