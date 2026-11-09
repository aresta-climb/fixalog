# Spec Delta: Observabilidade Dual, App Check e Logger de Campo

## Purpose

Fornece captura centralizada de eventos, erros e falhas críticas com envio simultâneo para Firebase Crashlytics e Sentry, atestação de integridade via Firebase App Check e filtragem inteligente de desconexão em montanha com fila offline.

## ADDED Requirements

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
O sistema DEVE (MUST) ativar o Firebase App Check (`ServicoAppCheck`) utilizando Play Integrity no Android, App Attest no iOS e provedores de depuração fora de builds de release oficial, fornecendo tokens JWT válidos para o `AutenticacaoNuvemService` e degradando graciosamente sem bloquear o aplicativo quando offline.

#### Scenario: Obtenção de token App Check sem conexão
- **WHEN** o `AutenticacaoNuvemService` solicita um token ao `ServicoAppCheck` enquanto o dispositivo está sem sinal na montanha
- **THEN** o `ServicoAppCheck` captura a exceção de rede, registra apenas um aviso no `RegistroLogger` e retorna de forma segura sem interromper o fluxo offline do auditor

### Requirement: Enfileiramento Offline em Disco
O sistema DEVE (MUST) persistir localmente em disco os envelopes do Sentry e registros do Crashlytics durante períodos sem sinal de rede, enviando-os automaticamente após a recuperação da conectividade.

#### Scenario: Falha gerada em ambiente sem sinal
- **WHEN** o auditor sofrer um erro de software com o dispositivo em modo avião ou sem sinal
- **THEN** o sistema retém o evento em fila local segura e o transmite na primeira conexão bem-sucedida
