# Spec Delta: Aba de Configurações e Governança Pericial

## Purpose

Apresenta as informações da identidade do auditor pericial, os termos legais aceitos com comprovação de auditoria e os canais de contato com a comunidade.

## ADDED Requirements

### Requirement: Exibição da Identidade Pericial
O sistema DEVE (MUST) exibir na aba de configurações os dados do perito cadastrado, incluindo nome legível, e-mail institucional e o identificador/fingerprint de sua chave criptográfica utilizada na assinatura dos laudos.

#### Scenario: Visualização do perfil do auditor
- **WHEN** o usuário acessa a aba de configurações
- **THEN** o sistema exibe os dados da identidade pericial armazenados no banco de dados local SQLite

### Requirement: Histórico de Auditoria dos Termos de Uso
O sistema DEVE (MUST) exibir a versão dos termos de uso e política de privacidade atualmente aceita, juntamente com a data e hora exata em que o consentimento foi registrado.

#### Scenario: Auditoria de conformidade legal
- **WHEN** a tela de configurações é carregada
- **THEN** os metadados `versaoTermosAceita` e `dataHoraAceiteTermos` são apresentados de forma clara e auditável

### Requirement: Links de Contato e Comunidade
O sistema DEVE (MUST) disponibilizar botões de redirecionamento seguro para o WhatsApp oficial da comunidade Aresta Climb e para o portal institucional, acionando o navegador externo ou aplicativo nativo correspondente.

#### Scenario: Acesso ao grupo de suporte da comunidade
- **WHEN** o usuário toca no botão de acesso à comunidade WhatsApp
- **THEN** o sistema aciona o link `https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv` externamente
