# Spec Delta

## MODIFIED Requirements

### Requirement: Filtro de Desconexão Transitória em Montanha
O sistema DEVE (MUST) reconhecer falhas decorrentes de perda temporária de sinal de rede, timeout de socket ou indisponibilidade transitória de gateway/rate-limit (códigos HTTP `408`, `429`, `502`, `503` e `504`) como eventos transitórios de campo, rebaixando-os exclusivamente para breadcrumbs de aviso sem acionar alarmes de erro não-fatal ou crash. O sistema DEVE (MUST) inspecionar o código de status HTTP presente em exceções de resposta HTTP (incluindo `HttpException` que contenha código de status da resposta) antes de classificá-las como falha de conexão, garantindo que códigos definitivos de erro de cliente, autenticação, configuração ou servidor (como `400`, `401`, `403`, `404`, `422` e `500`) NUNCA sejam rebaixados para aviso offline.

#### Scenario: Ocorrência de timeout ou falha de soquete na sincronização
- **WHEN** uma requisição de sincronização ou autenticação falhar por falta de conectividade na montanha (`SocketException`, `TimeoutException`, `HttpException` pura de transporte sem status HTTP definitivo ou resposta HTTP `408`/`429`/`502`/`503`/`504`)
- **THEN** o sistema classifica a falha como transitória e grava apenas um breadcrumb de aviso (`logAviso`), sem emitir alerta de erro no Sentry ou Crashlytics

#### Scenario: Erro HTTP definitivo do servidor ou configuração de provedor OIDC
- **WHEN** o servidor de autenticação ou API retornar um código HTTP definitivo (como `400 provider_disabled`, `401`, `403`, `404`, `422` ou `500`)
- **THEN** o sistema NÃO classifica o evento como desconexão transitória e registra a falha com `StackTrace` como erro no Sentry e no Crashlytics

## ADDED Requirements

### Requirement: Encaminhamento Obrigatório de Exceções Tratadas na Interface e ViewModels
Todo bloco `try/catch` em fluxos operacionais de autenticação, persistência de identidade, geração de relatórios EPUB/PDF, carregamento/duplicação de histórico e publicação manual DEVE (MUST) capturar o `StackTrace` original e encaminhar a falha à camada central de observabilidade (exceto em cancelamentos voluntários do usuário ou validações locais de formulário), apresentando apenas mensagens amigáveis e localizadas ao usuário sem expor payloads JSON ou URLs técnicas cruas.

#### Scenario: Falha de autenticação OIDC ou geração de relatório tratada pelo ViewModel
- **WHEN** ocorre uma exceção inesperada ou erro HTTP definitivo durante o login OIDC, salvamento de identidade, geração de pacote EPUB/PDF ou abertura/duplicação de sessão no histórico
- **THEN** o sistema registra a exceção com seu `StackTrace` no Sentry e no Crashlytics (respeitando o filtro de desconexão transitória quando aplicável) e exibe uma mensagem localizada amigável na interface
