## MODIFIED Requirements

### Requirement: Exibição da Identidade Pericial e Seletor de Idioma
O sistema DEVE (MUST) exibir na aba de configurações (`TelaConfiguracoes`) o seletor de idioma (suportando os 7 idiomas offline) e os dados do perito cadastrado, incluindo nome legível, clube/associação (`IdentityRecord`), status da conta OIDC OpenPubkey (`AutenticacaoNuvemService`), o fingerprint de sua chave criptográfica ECDSA P-256 (`CryptoService`) e o botão para gerenciar a identidade (`IdentitySetupScreen`). Ao abrir a `IdentitySetupScreen` a partir da `TelaConfiguracoes` (quando já existe uma identidade/sessão salva anteriormente), o sistema DEVE (MUST) renderizar a tela com fundo opaco e transições de rota sem *snapshotting* de texturas GPU *offscreen* (`allowSnapshotting: false`), reiniciar o estado de conclusão do formulário (`isSuccess: false`), pré-preencher sincronamente os campos com os dados atuais da sessão/identidade local sem mutar controladores durante o `build()`, exibir botão de retorno (`botao_voltar_identidade`) quando empilhada e, ao confirmar a edição, invalidar os provedores de identidade/sessão e desempilhar a rota (`Navigator.pop`) retornando à `TelaConfiguracoes` em vez de empilhar uma nova instância duplicada da `HomeScreen`.

#### Scenario: Visualização do perfil do auditor e troca de idioma
- **WHEN** o usuário acessa a aba de configurações
- **THEN** o sistema exibe o seletor de idiomas (`seletor_idioma_config`) e os dados da identidade pericial e chave criptográfica armazenados localmente

#### Scenario: Abertura da tela de edição de identidade após conclusão prévia do onboarding
- **WHEN** o usuário já concluiu o cadastro inicial de identidade (`isSuccess` foi `true` anteriormente) e toca em "Vincular / Editar Conta OIDC" (`botao_gerenciar_identidade_config`) na `TelaConfiguracoes`
- **THEN** o sistema reinicia `isSuccess` para `false`, pré-preenche sincronamente os campos com os dados atuais da sessão/identidade sem mutar controladores dentro do `build()`, exibe o botão de retorno no cabeçalho e mantém a `IdentitySetupScreen` aberta sem fechar automaticamente

#### Scenario: Retorno para a aba de configurações ao salvar edição de identidade
- **WHEN** o usuário edita seus dados na `IdentitySetupScreen` aberta a partir da `TelaConfiguracoes` e confirma o salvamento
- **THEN** o sistema persiste a identidade atualizada, invalida os provedores de identidade e sessão OIDC e desempilha a rota (`Navigator.pop`), retornando para a `TelaConfiguracoes` existente sem empilhar uma segunda `HomeScreen`
