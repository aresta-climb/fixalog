## ADDED Requirements

### Requirement: Hook de Inspeção de Erros e Crashes para Oráculos de Teste
O `RegistroLogger` DEVE (MUST) expor um callback opcional de inspeção (`aoRegistrarErroOuCrash`) que é invocado sincronamente sempre que `logError` ou `logCrash` for chamado (e a falha não for classificada como desconexão transitória), permitindo que o `MotorRoboCaotico` detecte erros tratados pela aplicação em tempo real sem bloquear o envio ao Sentry.

#### Scenario: Interceptação de erro tratado durante passo do Robô Caótico
- **WHEN** um fluxo interno do aplicativo captura uma exceção num bloco `try/catch` e invoca `RegistroLogger.instancia.logError(...)` ou `logCrash(...)` enquanto um hook `aoRegistrarErroOuCrash` está ativo
- **THEN** o `RegistroLogger` notifica o hook com a mensagem, a exceção, o `StackTrace` e a flag `fatal`, além de prosseguir normalmente com o envio ao Sentry quando ativo
