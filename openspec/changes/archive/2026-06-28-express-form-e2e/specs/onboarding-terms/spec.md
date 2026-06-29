## ADDED Requirements

### Requirement: Exibição dos Termos de Uso
O sistema DEVE checar no banco de dados local (Isar) se a versão atual dos termos já foi aceita pelo usuário.

#### Scenario: Termos ainda não aceitos
- **WHEN** o aplicativo inicializa e a `acceptedTermsVersion` na tabela `AppConfigRecord` não confere com a versão exigida
- **THEN** o sistema roteia o usuário para a tela `TermsOfUseScreen`

#### Scenario: Termos já aceitos
- **WHEN** o aplicativo inicializa e a `acceptedTermsVersion` está atualizada
- **THEN** o sistema prossegue para a tela de Identidade ou HomeScreen sem exibir os termos

### Requirement: Aceite e Solicitação de Permissões
O sistema DEVE solicitar permissões de Câmera e Localização e persistir o status de aceite.

#### Scenario: Aceite do usuário
- **WHEN** o usuário clica em "Aceitar e Continuar"
- **THEN** o sistema aciona os diálogos nativos solicitando permissão para GPS e Câmera
- **THEN** o sistema salva a versão aceita no `AppConfigRecord`
- **THEN** o sistema avança no roteamento inicial do aplicativo
