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
O sistema DEVE (MUST) reconhecer falhas decorrentes de perda temporária de sinal de rede, timeout de socket ou indisponibilidade transitória de servidor (incluindo durante a sincronização de laudos EPUB 3 no `SincronizadorNuvemService` e autenticação no `AutenticacaoNuvemService`) como eventos transitórios de campo, rebaixando-os exclusivamente para breadcrumbs sem acionar alarmes de erro não-fatal ou crash.

#### Scenario: Ocorrência de timeout ou falha de soquete na sincronização
- **WHEN** uma requisição do `SincronizadorNuvemService` ou `AutenticacaoNuvemService` falhar por falta de conectividade na montanha (`SocketException` ou `TimeoutException`)
- **THEN** o sistema classifica a falha via `RegistroLogger.isFalhaConexaoOuTimeout` e grava apenas um breadcrumb de aviso (`logAviso`), sem emitir alerta de erro no Sentry ou Crashlytics

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

