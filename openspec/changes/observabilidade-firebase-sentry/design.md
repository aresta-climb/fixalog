# Design: Arquitetura de Observabilidade Dual e Gestão de Memória

## Context

O FixLog opera primariamente em locais remotos de montanha sem conexão com a internet. O aplicativo utiliza Flutter, Riverpod e SQLite (`sqflite`), manipulando imagens fotográficas de proteções fixas e relatórios técnicos. Veja a motivação completa em `proposal.md`.

## Goals / Non-Goals

**Goals:**
- Fornecer observabilidade unificada através de uma única interface (`RegistroLogger`) que alimenta o Sentry e o Firebase Crashlytics simultaneamente.
- Filtrar falhas transitórias de conectividade de modo que ausência de sinal 4G seja tratada como evento normal de campo, sem alarmes falsos de erro fatal.
- Fornecer biblioteca de fake determinístico (`RegistroLoggerFake`) e overrides para garantir 100% de cobertura de testes unitários sem mocks (Princípios III, IV e V).
- Prevenir crashes nativos por falta de memória através de teto adaptativo de `imageCache`.
- Configurar upload automatizado de símbolos no CI do GitHub Actions para desofuscação de stack traces.

**Non-Goals:**
- Implementar envio de feedback do usuário (escopo da Proposta 2).
- Implementar testes de estresse exploratório (escopo da Proposta 3).
- Realizar sincronização de dados de catálogo pericial via Firebase (o FixLog permanece 100% offline-first com persistência local em SQLite e Session Bundles).

## Decisions

### 1. Envio Dual via `RegistroLogger` com Inicialização Resiliente
- **Decisão**: Criar a classe singleton `RegistroLogger` em `app/lib/core/services/registro_logger.dart` que abstrai chamadas para `FirebaseCrashlytics.instance` e `Sentry`.
- **Por que**: Evita acoplamento direto de telas e serviços com SDKs externos. Se o Firebase ou Sentry falharem ao inicializar (ou estiverem ausentes em ambiente de teste/desktop), o logger mantém operação local via `debugPrint` sem derrubar o aplicativo.
- **Alternativas consideradas**: Usar apenas Firebase Crashlytics (perde a integração rica com alertas no WhatsApp e a skill MCP do Sentry) ou usar apenas Sentry (perde a telemetria do Play Console e os Vitals de hardware).

### 2. Reconhecimento de Falhas de Montanha (`isFalhaConexaoOuTimeout`)
- **Decisão**: O `RegistroLogger` inspeciona erros de rede via `isFalhaConexaoOuTimeout(error)`, identificando `SocketException`, `TimeoutException`, `HttpException` e códigos HTTP 502/503/504/429.
- **Por que**: Em montanha, desconexão é o estado padrão, não uma exceção de software. Rebaixar esses erros para breadcrumbs (`logAviso`) evita ruído e fadiga de alertas na equipe de engenharia.

### 3. Fakes Determinísticos para Testes (Princípio V)
- **Decisão**: Criar `registro_logger_fake.dart` em `app/test/fakes/` (e seu teste espelhado `app/test/fakes/registro_logger_fake_test.dart`) com capacidade de registrar chamadas em memória e simular falhas, sem utilizar `mocktail` ou `mockito`.
- **Por que**: O `AGENTS.md` proíbe estritamente mocks para código interno e exige fakes testados como bibliotecas de primeira classe em `app/test/fakes/`.

### 4. Classificação de Memória por `/proc/meminfo`
- **Decisão**: No Android, ler `/proc/meminfo` (com injeção de provedor para testes determinísticos) para obter a memória física real e aplicar o teto de `imageCache` correspondente:
  - ≤ 3 GB RAM: 50 MB
  - 4–6 GB RAM: 100 MB
  - ≥ 8 GB RAM: 150 MB
- **Por que**: Evita que celulares modestos travem por OutOfMemory ao abrir o mosaico de fotos da via de escalada.

## Risks / Trade-offs

- [Inicialização do Firebase sem rede na montanha] → `initFirebase` é executado com tratamento de exceção não-bloqueante; Remote Config tem fallbacks estáticos em código e nunca atrasa o carregamento inicial da interface.
- [Impacto de performance do Sentry em aparelhos antigos] → Taxa de amostragem de rastreamento de performance configurada em 0% ou ativada apenas sob demanda; desativado envio de PII por padrão.
- [Símbolos desofuscados no CI] → A esteira do GitHub Actions valida a presença de `SENTRY_AUTH_TOKEN` antes de prosseguir com a publicação de releases.
