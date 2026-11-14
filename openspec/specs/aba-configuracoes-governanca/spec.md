# Aba de Configurações e Governança Pericial

## Purpose

Apresenta o seletor multilíngue (7 idiomas), as informações completas da identidade pericial do auditor (local, OIDC OpenPubkey e chave criptográfica ECDSA), os termos legais aceitos com comprovação de auditoria, o acionador de feedback in-app e os canais oficiais da comunidade.

## Requirements

### Requirement: Exibição da Identidade Pericial e Seletor de Idioma
O sistema DEVE (MUST) exibir na aba de configurações (`TelaConfiguracoes`) o seletor de idioma (suportando os 7 idiomas offline) e os dados do perito cadastrado, incluindo nome legível, clube/associação (`IdentityRecord`), status da conta OIDC OpenPubkey (`AutenticacaoNuvemService`), o fingerprint de sua chave criptográfica ECDSA P-256 (`CryptoService`) e o botão para gerenciar a identidade (`IdentitySetupScreen`). Ao abrir a `IdentitySetupScreen` a partir da `TelaConfiguracoes` (quando já existe uma identidade/sessão salva anteriormente), o sistema DEVE (MUST):
1. Pré-preencher sincronamente os controladores de Nome e Clube já no primeiro frame (`initState`) com os dados existentes no estado/banco local (`IdentityFormState` ou `IdentityRecord`), evitando mutação de texto no meio da animação de transição de rota;
2. Reiniciar o estado de conclusão do formulário (`isSuccess: false`) e recuperar o perfil local (`IdentityRepository.getCurrentIdentity()`) como fallback caso a sessão OIDC não traga nome ou clube preenchidos, mantendo a tela aberta para editar o Nome/Clube ou trocar a conta OIDC;
3. Renderizar um `Scaffold` com fundo opaco (`Color(0xFF2D3328)`), gradiente linear simples de duas paradas e transições de rota sem captura offscreen (`ZoomPageTransitionsBuilder(allowSnapshotting: false)`), além de exibir um botão de retorno (`botao_voltar_identidade`) no cabeçalho quando a rota puder ser desempilhada (`Navigator.canPop(context)`);
4. Ao confirmar a edição, invalidar `currentIdentityProvider`, `hasIdentityProvider` e `sessaoOidcConfigProvider` e desempilhar a rota (`Navigator.pop`) retornando à `TelaConfiguracoes` em vez de empilhar uma nova instância duplicada da `HomeScreen`.

#### Scenario: Visualização do perfil do auditor e troca de idioma
- **WHEN** o usuário acessa a aba de configurações
- **THEN** o sistema exibe o seletor de idiomas (`seletor_idioma_config`) e os dados da identidade pericial e chave criptográfica armazenados localmente

#### Scenario: Abertura da tela de edição de identidade após conclusão prévia do onboarding
- **WHEN** o usuário já concluiu o cadastro inicial de identidade (`isSuccess` foi `true` anteriormente) e toca em "Vincular / Editar Conta OIDC" (`botao_gerenciar_identidade_config`) na `TelaConfiguracoes`
- **THEN** o sistema pré-preenche sincronamente os campos já no primeiro frame com os dados atuais da sessão ou da identidade local (`IdentityRecord`), reinicia `isSuccess` para `false`, exibe o botão de retorno (`botao_voltar_identidade`) e mantém a `IdentitySetupScreen` aberta sem fechar automaticamente

#### Scenario: Cancelamento da edição de identidade pelo botão voltar
- **WHEN** o usuário abre a `IdentitySetupScreen` empilhada a partir da `TelaConfiguracoes` e toca no botão de voltar (`botao_voltar_identidade`)
- **THEN** o sistema desempilha a rota (`Navigator.pop`) retornando à `TelaConfiguracoes` sem alterar a identidade salva

#### Scenario: Retorno para a aba de configurações ao salvar edição de identidade
- **WHEN** o usuário edita seus dados na `IdentitySetupScreen` aberta a partir da `TelaConfiguracoes` e confirma o salvamento
- **THEN** o sistema persiste a identidade atualizada, invalida `currentIdentityProvider`, `hasIdentityProvider` e `sessaoOidcConfigProvider` e desempilha a rota (`Navigator.pop`), retornando para a `TelaConfiguracoes` existente sem empilhar uma segunda `HomeScreen`

### Requirement: Histórico de Auditoria dos Termos de Uso
O sistema DEVE (MUST) exibir a versão dos termos de uso e política de privacidade atualmente aceita (`versaoTermosAceita`), juntamente com a data e hora exata em que o consentimento foi registrado (`dataHoraAceiteTermos`) e opção para consultar o texto legal vigente.

#### Scenario: Auditoria de conformidade legal
- **WHEN** a `TelaConfiguracoes` é carregada
- **THEN** os metadados `versaoTermosAceita` e `dataHoraAceiteTermos` de `AppConfigRecord` são apresentados de forma clara e auditável

### Requirement: Links de Contato, Comunidade e Acionamento de Feedback
O sistema DEVE (MUST) disponibilizar na `TelaConfiguracoes` o botão de acionamento do feedback in-app (`BotaoFeedback`) e botões de redirecionamento externo para o WhatsApp oficial da comunidade Aresta Climb (`https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv`) e para o portal institucional (`https://arestaclimb.com`).

#### Scenario: Acesso ao grupo de suporte da comunidade
- **WHEN** o usuário toca no botão de acesso à comunidade WhatsApp
- **THEN** o sistema aciona a abertura externa da URL `https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv`
