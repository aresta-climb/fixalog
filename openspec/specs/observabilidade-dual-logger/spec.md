# Observabilidade Dual, App Check e Logger de Campo

## Purpose

Fornece captura centralizada de eventos, erros e falhas críticas com envio simultâneo para Firebase Crashlytics e Sentry, atestação de integridade via Firebase App Check e filtragem inteligente de desconexão em montanha com fila offline.

## Requirements

### Requirement: Envio Dual de Logs e Exceções
O sistema DEVE (MUST) registrar eventos informativos, avisos e capturar exceções com StackTrace obrigatório através do `RegistroLogger`, despachando-os simultaneamente para o Firebase Crashlytics e o Sentry quando inicializados.

#### Scenario: Registro de falha operacional
- **WHEN** uma exceção não tratada ou erro operacional inesperado for registrado no `RegistroLogger`
- **THEN** o sistema envia o evento com stacktrace tanto para o Crashlytics quanto para o Sentry com nível de severidade correspondente

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

### Requirement: Atestação de Integridade via Firebase App Check
O sistema DEVE (MUST) ativar o Firebase App Check (`ServicoAppCheck`) utilizando Play Integrity no Android, App Attest no iOS e provedores de depuração fora de builds de release oficial, fornecendo tokens JWT válidos para o `AutenticacaoNuvemService` e degradando graciosamente sem bloquear o aplicativo quando offline ou quando o UUID de depuração local não estiver cadastrado no Firebase Console em modo de desenvolvimento (`kModoDesenvolvimento`). Quando a obtenção do token falhar por *rate-limit* (`Too many attempts`) ou erro de atestação da API, o `ServicoAppCheck` DEVE (MUST) aplicar uma janela de *cooldown* em memória (5 minutos por padrão) durante a qual chamadas subsequentes a `obterToken(false)` retornam `null` imediatamente sem acionar o canal nativo, e DEVE (MUST) registrar falhas de *rate-limit* (`Too many attempts`) como aviso (`logAviso`) em vez de erro não-tratado (`logError`).

#### Scenario: Obtenção de token App Check sem conexão
- **WHEN** o `AutenticacaoNuvemService` solicita um token ao `ServicoAppCheck` enquanto o dispositivo está sem sinal na montanha
- **THEN** o `ServicoAppCheck` captura a exceção de rede, registra apenas um aviso no `RegistroLogger` e retorna de forma segura sem interromper o fluxo offline do auditor

#### Scenario: Obtenção de token App Check em modo de desenvolvimento sem UUID cadastrado no Firebase Console
- **WHEN** o `ServicoAppCheck.obterToken` é acionado em modo de desenvolvimento (`kModoDesenvolvimento`) e o `DebugAppCheckProvider` falha com `403 App attestation failed` por ausência de registro do UUID local no console do Firebase
- **THEN** o `ServicoAppCheck` captura a falha, registra apenas um aviso contextual (`logAviso`) sem emitir erro no Sentry ou Crashlytics, e retorna `null` para acionar o mock gracioso nos serviços consumidores

#### Scenario: Cooldown em memória e rebaixamento de severidade após rate-limit (Too many attempts)
- **WHEN** `ServicoAppCheck.obterToken` recebe uma exceção contendo `Too many attempts` do SDK nativo do Firebase App Check
- **THEN** o `ServicoAppCheck` registra apenas um aviso (`logAviso`) sem enviar erro ao Sentry, ativa um *cooldown* em memória de 5 minutos e retorna `null` imediatamente nas chamadas seguintes a `obterToken(false)` dentro dessa janela sem invocar novamente o canal nativo

### Requirement: Enfileiramento Offline em Disco
O sistema DEVE (MUST) persistir localmente em disco os envelopes do Sentry e registros do Crashlytics durante períodos sem sinal de rede, enviando-os automaticamente após a recuperação da conectividade.

#### Scenario: Falha gerada em ambiente sem sinal
- **WHEN** o auditor sofrer um erro de software com o dispositivo em modo avião ou sem sinal
- **THEN** o sistema retém o evento em fila local segura e o transmite na primeira conexão bem-sucedida

### Requirement: Hook de Inspeção de Erros e Crashes para Oráculos de Teste
O `RegistroLogger` DEVE (MUST) expor um callback opcional de inspeção (`aoRegistrarErroOuCrash`) que é invocado sincronamente sempre que `logError` ou `logCrash` for chamado (e a falha não for classificada como desconexão transitória), permitindo que o `MotorRoboCaotico` detecte erros tratados pela aplicação em tempo real sem bloquear o envio ao Sentry.

#### Scenario: Interceptação de erro tratado durante passo do Robô Caótico
- **WHEN** um fluxo interno do aplicativo captura uma exceção num bloco `try/catch` e invoca `RegistroLogger.instancia.logError(...)` ou `logCrash(...)` enquanto um hook `aoRegistrarErroOuCrash` está ativo
- **THEN** o `RegistroLogger` notifica o hook com a mensagem, a exceção, o `StackTrace` e a flag `fatal`, além de prosseguir normalmente com o envio ao Sentry quando ativo

### Requirement: Proteção de Inicialização Nativa nos Callbacks Padrão
O `RegistroLogger` e o `ServicoTelemetria` DEVEM (MUST) verificar se o Firebase Core (`RegistroLogger.firebaseInicializado`) e o Sentry (`Sentry.isEnabled`) estão efetivamente inicializados antes de invocar os canais nativos padrão de `FirebaseCrashlytics`, `FirebaseAnalytics` e `Sentry`, evitando exceções `[core/no-app]` durante testes automatizados, campanhas do Robô Caótico ou operação sem Firebase.

#### Scenario: Emissão de breadcrumb e telemetria sem Firebase inicializado
- **WHEN** `ServicoTelemetria.instancia.registrarEvento` ou `RegistroLogger.instancia.logInfo` é chamado durante um teste de widget ou sessão do Robô Caótico sem `Firebase.initializeApp`
- **THEN** o log informativo é impresso no console local e enviado ao Sentry (se `Sentry.isEnabled` for `true`), ignorando silenciosamente as chamadas nativas ao Firebase sem lançar exceção nem acionar `logError`

### Requirement: Encaminhamento Obrigatório de Exceções Tratadas na Interface e ViewModels
Todo bloco `try/catch` em fluxos operacionais de autenticação, persistência de identidade, geração de relatórios EPUB/PDF, carregamento/duplicação de histórico e publicação manual DEVE (MUST) capturar o `StackTrace` original e encaminhar a falha à camada central de observabilidade (exceto em cancelamentos voluntários do usuário ou validações locais de formulário), apresentando apenas mensagens amigáveis e localizadas ao usuário sem expor payloads JSON ou URLs técnicas cruas.

#### Scenario: Falha de autenticação OIDC ou geração de relatório tratada pelo ViewModel
- **WHEN** ocorre uma exceção inesperada ou erro HTTP definitivo durante o login OIDC, salvamento de identidade, geração de pacote EPUB/PDF ou abertura/duplicação de sessão no histórico
- **THEN** o sistema registra a exceção com seu `StackTrace` no Sentry e no Crashlytics (respeitando o filtro de desconexão transitória quando aplicável) e exibe uma mensagem localizada amigável na interface

