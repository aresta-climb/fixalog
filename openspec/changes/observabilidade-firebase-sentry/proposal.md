# Proposta: Infraestrutura de Observabilidade Dual (Firebase + Sentry) e Gestão de Memória

## Why

Atualmente, o FixLog opera sem qualquer mecanismo centralizado de telemetria, captura de erros ou observabilidade de falhas em campo. Quando um auditor ou escalador enfrenta um crash inesperado durante uma perícia em ambiente remoto de montanha, o erro é silencioso e inviabiliza diagnósticos rápidos. Além disso, a manipulação de múltiplas fotografias de alta resolução de proteções fixas e paradas sem gestão de memória adaptativa impõe alto risco de falha por esgotamento de memória (*OutOfMemory* / SIGSEGV).

Adotar o **Sentry** (integrado ao ecossistema Aresta Climb e seus roteadores de alertas no WhatsApp e GitHub Issues) em conjunto com o **Firebase** (Crashlytics, Remote Config e Analytics para métricas de plataforma e controle dinâmico de versões) resolve essa lacuna com custo operacional zero. Um serviço unificado (`RegistroLogger`) com filtro inteligente de instabilidades transitórias de montanha garante que perda de sinal 4G não polua o rastreador de incidentes, enquanto o armazenamento local (*outbox*) e a gestão adaptativa de cache de imagens garantem resiliência total em conformidade com o princípio de 100% Offline-First.

## What Changes

- **Integração Dual Firebase + Sentry**:
  - Configuração do projeto Firebase dedicado `com-arestaclimb-fixlog` (`firebase_core`, `firebase_crashlytics`, `firebase_analytics`, `firebase_remote_config`).
  - Adição do SDK `sentry_flutter: ^10.2.0` no aplicativo e do plugin `sentry_dart_plugin: ^3.4.0` para desofuscação.
- **Serviço Centralizado `RegistroLogger` (`lib/core/services/registro_logger.dart`)**:
  - Abstração centralizada para log de informações (`logInfo`), avisos (`logAviso`), erros operacionais (`logError`) e falhas críticas (`logCrash`).
  - Reconhecimento automático de instabilidade de conectividade e quedas de rede via `isFalhaConexaoOuTimeout`, rebaixando erros de rede para breadcrumbs e evitando alertas espúrios.
  - Fila offline automática em disco para despacho assíncrono pós-reconexão.
  - Implementação *test-only* de `RegistroLoggerFake` para assegurar fidelidade de produção sem uso de mocks no código interno (Princípio V).
- **Gestão Adaptativa de Memória (`lib/core/services/classificador_dispositivo.dart`)**:
  - Leitura da capacidade de RAM do hardware e dimensionamento do teto de `imageCache` do Flutter (50 MB a 150 MB) para prevenir falhas nativas de OOM durante catalogação de fotos.
- **Esteira de CI/CD com Upload de Símbolos**:
  - Atualização do workflow de build para compilar com `--obfuscate --split-debug-info=build/symbols` e realizar upload automático dos símbolos no Sentry e Crashlytics.

## Capabilities

### New Capabilities
- `observabilidade-dual-logger`: Serviço de logging e captura de exceções dual (Sentry + Crashlytics) com filtro de desconexão de montanha e fila offline.
- `gestao-memoria-dispositivo`: Classificação dinâmica de RAM e dimensionamento de cache de imagens para prevenção de OOM.

### Modified Capabilities
*(Nenhuma especificação existente teve seus requisitos de comportamento alterados)*

## Impact

- **Código e Dependências**:
  - `app/pubspec.yaml`: inclusão de `firebase_core`, `firebase_crashlytics`, `firebase_analytics`, `firebase_remote_config`, `sentry_flutter` e `sentry_dart_plugin`.
  - `app/lib/main.dart`: inicialização coordenada do Firebase e `SentryFlutter.init`.
  - `app/lib/core/services/`: criação de `registro_logger.dart`, `classificador_dispositivo.dart`, `servico_configuracao_remota.dart` e `servico_telemetria.dart`.
- **Infraestrutura**:
  - Chaves e segredos cadastrados no GitHub Actions (`SENTRY_AUTH_TOKEN`, `FIREBASE_SERVICE_ACCOUNT_JSON`).
