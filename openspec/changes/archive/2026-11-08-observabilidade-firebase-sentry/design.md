# Design: Arquitetura de Observabilidade Dual, App Check e Gestão de Memória

## Context

O Fixalog opera primariamente em locais remotos de montanha sem conexão com a internet. O aplicativo utiliza Flutter, Riverpod, banco local SQLite (`BancoDadosLocal` via `sqflite`), pacotes periciais EPUB 3 assinados com XML-DSig/OpenPubkey (`AutenticacaoNuvemService`) e sincronização automática em segundo plano com a nuvem (`SincronizadorNuvemService` apontando para `https://fixalog.app`). Veja a motivação completa em `proposal.md`.

## Goals / Non-Goals

**Goals:**
- Fornecer observabilidade unificada através de uma única interface (`RegistroLogger`) que alimenta o Sentry e o Firebase Crashlytics simultaneamente.
- Filtrar falhas transitórias de conectividade de modo que ausência de sinal 4G na montanha (durante sincronização de EPUBs, renovação de token OIDC ou obtenção de token App Check) seja tratada como evento normal de campo, sem alarmes falsos de erro fatal.
- Integrar o `ServicoAppCheck` (`firebase_app_check`) ao `AutenticacaoNuvemService` para fornecer tokens reais do Play Integrity (Android) e App Attest (iOS) ao `SincronizadorNuvemService`.
- Fornecer biblioteca de fake determinístico (`RegistroLoggerFake`) e injeção de dependências para garantir 100% de cobertura de testes unitários sem mocks (Princípios III, IV e V do `AGENTS.md`).
- Prevenir crashes nativos por falta de memória através de teto adaptativo de `imageCache` (`ClassificadorDispositivo`).
- Configurar compilação ofuscada e upload automatizado de símbolos no CI do GitHub Actions (Android e iOS) para desofuscação de stack traces.

**Non-Goals:**
- Implementar envio de feedback visual do usuário (escopo da Proposta 2: `feedback-offline-configuracoes`).
- Implementar testes de estresse exploratório no Wizard (escopo da Proposta 3: `robo-caotico-wizard`).
- Substituir o protocolo de sincronização de laudos periciais (que permanece via `SincronizadorNuvemService` e pacotes EPUB 3).

## Decisions

### 1. Envio Dual via `RegistroLogger` com Inicialização Resiliente
- **Decisão**: Criar a classe `RegistroLogger` em `app/lib/core/services/registro_logger.dart` que abstrai chamadas para `FirebaseCrashlytics.instance` e `Sentry`, expondo `logInfo`, `logAviso`, `logError`, `logFalhaSyncOuDownload` e `logCrash`.
- **Por que**: Evita acoplamento direto de telas e serviços (como `SincronizadorNuvemService`, `AutenticacaoNuvemService` e `EpubPackagerService`) com SDKs externos. Se o Firebase ou Sentry falharem ao inicializar (ou não estiverem ativos em testes unitários/desktop), o logger opera localmente de forma segura sem derrubar o aplicativo.
- **Alternativas consideradas**: Usar apenas Firebase Crashlytics (perde a integração com alertas no WhatsApp, GitHub Issues e a skill MCP do Sentry) ou usar apenas Sentry (perde a telemetria integrada ao ecossistema Firebase/Google Play).

### 2. Reconhecimento de Falhas de Montanha (`isFalhaConexaoOuTimeout`)
- **Decisão**: O `RegistroLogger` inspeciona erros de rede via `isFalhaConexaoOuTimeout(error)`, identificando `SocketException`, `TimeoutException`, `HttpException`, erros de handshake TLS interrompido e códigos HTTP 502/503/504/429.
- **Por que**: Em montanha, desconexão é o estado padrão, não um defeito de software. Quando `SincronizadorNuvemService` ou `AutenticacaoNuvemService` encontram essas falhas, `logFalhaSyncOuDownload` rebaixa-as automaticamente para breadcrumbs (`logAviso`), enquanto erros inesperados (ex.: falha de serialização, HTTP 400/500 por bug de contrato) são enviados como erros reais (`logError`).

### 3. Atestação com `ServicoAppCheck` Integrada ao `AutenticacaoNuvemService`
- **Decisão**: Criar `ServicoAppCheck` em `app/lib/core/services/servico_app_check.dart` (inspirado no `validador_app.dart` do `aresta_app`), selecionando `AndroidPlayIntegrityProvider` / `AppleAppAttestProvider` em builds de release oficial e `AndroidDebugProvider` / `AppleDebugProvider` em desenvolvimento/profile. Conectar `ServicoAppCheck.instance.obterToken()` ao provedor padrão de `AutenticacaoNuvemService`.
- **Por que**: O `SincronizadorNuvemService` já envia o cabeçalho `X-Firebase-AppCheck` para `https://fixalog.app/api/v1/laudos`, mas `AutenticacaoNuvemService` retornava uma string fixa de placeholder. Com `ServicoAppCheck`, o worker na nuvem pode validar a autenticidade da instalação sem bloquear o uso offline (se `obterToken()` falhar por falta de rede, registra breadcrumb via `RegistroLogger` e mantém fallback gracioso).

### 4. Fakes Determinísticos e Espelhamento 1:1 (Princípios III e V)
- **Decisão**: Criar `registro_logger_fake.dart` em `app/test/fakes/` (e seu teste espelhado `app/test/fakes/registro_logger_fake_test.dart`) registrando chamadas em memória para inspeção comportamental nos testes, sem utilizar `mocktail` ou `mockito`. Todo arquivo criado em `app/lib/core/services/*.dart` terá seu respectivo `app/test/core/services/*_test.dart` e cabeçalho SPDX/MPL-2.0.
- **Por que**: Validado automaticamente por `test_structure_mirror_test.dart` e `license_headers_test.dart`.

### 5. Classificação de Memória por `/proc/meminfo` (`ClassificadorDispositivo`)
- **Decisão**: No Android, ler `/proc/meminfo` (com injeção de função leitora para testes determinísticos em memória) para obter a RAM física total e aplicar o teto de `imageCache` correspondente:
  - ≤ 3 GB RAM (`PorteMemoriaDispositivo.baixo`): 50 MB
  - 4–6 GB RAM (`PorteMemoriaDispositivo.medio`): 100 MB
  - ≥ 8 GB RAM (`PorteMemoriaDispositivo.alto`): 150 MB
- **Por que**: Evita que celulares intermediários ou de entrada sofram *OutOfMemory* ao manipular dezenas de fotos de proteções fixas e renderizar sumários em PDF.

## Risks / Trade-offs

- [Inicialização do Firebase/Sentry sem rede na montanha] → A inicialização é executada com proteção não-bloqueante; `ServicoConfiguracaoRemota` possui valores padrão estáticos em código e nunca bloqueia o primeiro frame da interface.
- [Impacto de performance do Sentry em aparelhos antigos] → Taxa de amostragem de tracing configurada de forma conservadora e envio automático de PII desativado por padrão (`sendDefaultPii = false`).
- [Símbolos desofuscados no CI] → As esteiras `build_android.yml` e `build_ios.yml` compilam com `--obfuscate --split-debug-info=build/symbols` e executam o `sentry_dart_plugin` quando `SENTRY_AUTH_TOKEN` está configurado nos segredos do repositório.
