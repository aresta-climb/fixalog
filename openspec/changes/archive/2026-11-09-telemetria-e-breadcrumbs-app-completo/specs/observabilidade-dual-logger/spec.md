## ADDED Requirements

### Requirement: Proteção de Inicialização Nativa nos Callbacks Padrão
O `RegistroLogger` e o `ServicoTelemetria` DEVEM (MUST) verificar se o Firebase Core (`RegistroLogger.firebaseInicializado`) e o Sentry (`Sentry.isEnabled`) estão efetivamente inicializados antes de invocar os canais nativos padrão de `FirebaseCrashlytics`, `FirebaseAnalytics` e `Sentry`, evitando exceções `[core/no-app]` durante testes automatizados, campanhas do Robô Caótico ou operação sem Firebase.

#### Scenario: Emissão de breadcrumb e telemetria sem Firebase inicializado
- **WHEN** `ServicoTelemetria.instancia.registrarEvento` ou `RegistroLogger.instancia.logInfo` é chamado durante um teste de widget ou sessão do Robô Caótico sem `Firebase.initializeApp`
- **THEN** o log informativo é impresso no console local e enviado ao Sentry (se `Sentry.isEnabled` for `true`), ignorando silenciosamente as chamadas nativas ao Firebase sem lançar exceção nem acionar `logError`
