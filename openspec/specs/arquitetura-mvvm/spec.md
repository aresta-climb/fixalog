## ADDED Requirements

### Requirement: O sistema deve adotar o Repository Pattern
O acesso a dados via Isar deve ser abstraído em Repositories para permitir que a camada de visualização não conheça detalhes de implementação do banco de dados.

#### Scenario: Leitura de Identidade
- **WHEN** O ViewModel solicita a Identidade atual
- **THEN** O ViewModel deve invocar `IdentityRepository.getIdentity()` ao invés de `isar.identityRecords.where().findFirst()`

### Requirement: O sistema deve adotar ViewModels
Os componentes de estado para as views devem ser nomeados como ViewModels e não devem manter dependência direta de contexto de banco.

#### Scenario: Submissão de Formulário
- **WHEN** A View envia os dados para o ViewModel
- **THEN** O ViewModel valida a regra de negócio e despacha para o Repository, atualizando o `State` reativamente.
