# Aba de Configurações e Governança Pericial

## Purpose

Apresenta o seletor multilíngue (7 idiomas), as informações completas da identidade pericial do auditor (local, OIDC OpenPubkey e chave criptográfica ECDSA), os termos legais aceitos com comprovação de auditoria, o acionador de feedback in-app e os canais oficiais da comunidade.

## Requirements

### Requirement: Exibição da Identidade Pericial e Seletor de Idioma
O sistema DEVE (MUST) exibir na aba de configurações (`TelaConfiguracoes`) o seletor de idioma (suportando os 7 idiomas offline) e os dados do perito cadastrado, incluindo nome legível, clube/associação (`IdentityRecord`), status da conta OIDC OpenPubkey (`AutenticacaoNuvemService`), o fingerprint de sua chave criptográfica ECDSA P-256 (`CryptoService`) e o botão para gerenciar a identidade (`IdentitySetupScreen`).

#### Scenario: Visualização do perfil do auditor e troca de idioma
- **WHEN** o usuário acessa a aba de configurações
- **THEN** o sistema exibe o seletor de idiomas (`seletor_idioma_config`) e os dados da identidade pericial e chave criptográfica armazenados localmente

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
