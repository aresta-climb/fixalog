# Spec Delta: Observabilidade Dual e Logger de Campo

## Purpose

Fornece captura centralizada de eventos, erros e falhas críticas com envio simultâneo para Firebase Crashlytics e Sentry, com filtragem de desconexão em montanha e fila offline.

## ADDED Requirements

### Requirement: Envio Dual de Logs e Exceções
O sistema DEVE (MUST) registrar eventos informativos, avisos e capturar exceções com StackTrace obrigatório, despachando-os simultaneamente para o Firebase Crashlytics e o Sentry quando inicializados.

#### Scenario: Registro de falha operacional
- **WHEN** uma exceção não tratada ou erro operacional for registrado no logger
- **THEN** o sistema envia o evento com stacktrace tanto para o Crashlytics quanto para o Sentry com nível de severidade correspondente

### Requirement: Filtro de Desconexão Transitória em Montanha
O sistema DEVE (MUST) reconhecer falhas decorrentes de perda temporária de sinal de rede, timeout de socket ou indisponibilidade de rota como eventos transitórios de campo, rebaixando-os exclusivamente para breadcrumbs sem acionar alarmes de crash fatal.

#### Scenario: Ocorrência de timeout ou falha de soquete
- **WHEN** uma requisição ou sincronização falhar por falta de conectividade na montanha
- **THEN** o sistema classifica a falha via detector de desconexão e grava apenas um breadcrumb de aviso, sem emitir crash crítico

### Requirement: Enfileiramento Offline em Disco
O sistema DEVE (MUST) persistir localmente em disco os envelopes do Sentry e registros do Crashlytics durante períodos sem sinal de rede, enviando-os automaticamente após a recuperação da conectividade.

#### Scenario: Falha gerada em ambiente sem sinal
- **WHEN** o auditor sofrer um erro com o dispositivo em modo avião ou sem sinal
- **THEN** o sistema retém o evento em fila local segura e o transmite na primeira conexão bem-sucedida
