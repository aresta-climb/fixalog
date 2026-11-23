# Spec Delta

## MODIFIED Requirements

### Requirement: Filtro de Desconexão Transitória em Montanha
O sistema DEVE (MUST) reconhecer falhas decorrentes de perda temporária de sinal de rede, timeout de socket, indisponibilidade transitória de gateway/rate-limit (códigos HTTP `408`, `429`, `502`, `503` e `504`) ou falhas nativas de transporte offline nos SDKs do Firebase e na pilha `NSURLErrorDomain` / `CFNetwork` do iOS/macOS (incluindo `FirebaseException` com código `network-error`, `network_error` ou `network-request-failed`, `Failed to get installations token` e `The Internet connection appears to be offline`) como eventos transitórios de campo, rebaixando-os exclusivamente para breadcrumbs de aviso sem acionar alarmes de erro não-fatal ou crash. O sistema DEVE (MUST) inspecionar o código de status HTTP presente em exceções de resposta HTTP (incluindo `HttpException` que contenha código de status da resposta) antes de classificá-las como falha de conexão, garantindo que códigos definitivos de erro de cliente, autenticação, configuração ou servidor (como `400`, `401`, `403`, `404`, `422` e `500`) NUNCA sejam rebaixados para aviso offline. Quando uma falha definitiva ocorrer dentro de rotinas tratadas de sincronização ou comunicação em segundo plano (`logFalhaSyncOuDownload`), o sistema DEVE (MUST) registrá-la como erro operacional não-fatal (`fatal: false` / `SentryLevel.error`), reservando o nível de crash (`fatal: true` / `SentryLevel.fatal`) exclusivamente para exceções não tratadas capturadas pelos tratadores globais da aplicação.

#### Scenario: Ocorrência de timeout, falha de soquete ou erro nativo offline do iOS na sincronização
- **WHEN** uma requisição de sincronização, busca de configuração ou autenticação falhar por falta de conectividade na montanha (`SocketException`, `TimeoutException`, `FirebaseException` `network-error` / `Failed to get installations token`, erro `NSURLErrorDomain` offline do iOS, `HttpException` pura de transporte sem status HTTP definitivo ou resposta HTTP `408`/`429`/`502`/`503`/`504`)
- **THEN** o sistema classifica a falha como transitória e grava apenas um breadcrumb de aviso (`logAviso`), sem emitir alerta de erro no Sentry ou Crashlytics

#### Scenario: Erro HTTP definitivo do servidor ou configuração de provedor OIDC
- **WHEN** o servidor de autenticação ou API retornar um código HTTP definitivo (como `400 provider_disabled`, `401`, `403`, `404`, `422` ou `500`)
- **THEN** o sistema NÃO classifica o evento como desconexão transitória e registra a falha com `StackTrace` como erro não-fatal (`fatal: false`) no Sentry e no Crashlytics

#### Scenario: Falha definitiva em sincronização de segundo plano registra erro não-fatal
- **WHEN** `logFalhaSyncOuDownload` recebe uma falha não-transitória capturada em bloco `try/catch` (ex.: `HTTP 400`, `HTTP 403` ou erro de validação de pacote)
- **THEN** o logger encaminha a exceção com `StackTrace` ao Sentry e ao Crashlytics com `fatal: false` (`SentryLevel.error`) e notifica o hook `aoRegistrarErroOuCrash` com `fatal: false`, sem acionar alarmes de crash fatal de processo
