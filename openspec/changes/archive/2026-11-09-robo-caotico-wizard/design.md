# Design: Motor de Testes do Robô Caótico no Aplicativo Completo e Oráculo de Erros/Sentry

## Context

O Fixalog reúne fluxos críticos de campo em múltiplas telas (`HomeScreen`, `NewProtocolScreen`, `WizardScreen` para 5 protocolos YAML em 7 idiomas, `HistoryScreen`, `TelaConfiguracoes`, `IdentitySetupScreen`, `TelaTermosDeUso` e `BetterFeedback`). Inspirado na combinação do `aresta_app` (exploração Flutter via `WidgetTester` e execução em dispositivo via `integration_test`) com o `aresta_db` (`OraculosCaos` que intercepta tanto exceções não tratadas quanto qualquer `logError` emitido por blocos `try/catch`, enviando a receita consolidada ao Sentry após o `ddmin`), projetamos o motor de caos completo do Fixalog. Veja `proposal.md`.

## Goals / Non-Goals

**Goals:**
- Exercitar o **aplicativo inteiro (`FixalogApp`)** montado sobre `BancoDadosLocal.abrirEmMemoria()` (SQLite `:memory:`) e Fakes determinísticos de todas as fronteiras externas (Princípio V do `AGENTS.md`).
- Detectar não apenas crashes e `FlutterError` (`RenderFlex overflow`, falhas de build/layout), mas também **qualquer erro tratado registrado em `RegistroLogger.logError` ou `logCrash`**.
- Reduzir automaticamente a sequência de passos via busca binária (*Delta Debugging* / `ddmin`) com `EncolhedorCaminhoCrash`, mantendo o Sentry liberado o tempo todo quando `reportarAoSentry: true` (contando com a deduplicação nativa de Issues do Sentry) e enviando também o evento com `receita_robo_caotico` anexada ao contexto ao final do `ddmin`.
- Reexecutar todas as receitas `.json` de `app/test/caos/caminhos_regressao/` em `< 1s` no `flutter test` padrão e disponibilizar tanto `robo_caotico_exploratorio_test.dart` (CI/headless) quanto `integration_test/robo_caotico_dispositivo_test.dart` (celular/emulador).

**Non-Goals:**
- Substituir testes unitários e de widget orientados a comportamento (o robô caótico complementa a suíte espelhada 1:1).
- Executar campanhas longas de minutos em todo `flutter test` local sem flag (controlado por `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS`).

## Decisions

### 1. Montagem do Aplicativo Completo (`FixalogApp`) em `AmbienteAppCaos`
- **Decisão**: O `AmbienteAppCaos` inicializa `BancoDadosLocal.abrirEmMemoria()` populado pela `FabricaDatasetCaos` (`TipoDatasetCaos.normal` ou `TipoDatasetCaos.toxico`) e monta o `FixalogApp` completo envolto em `BetterFeedback` e `ProviderScope` com overrides para os Fakes determinísticos (`ServicoGaleriaDispositivoFake`, `VideoTranscoderServiceFake`, `CryptoServiceFake`, `SincronizadorNuvemServiceFake`, `AutenticacaoNuvemServiceFake`, `ServicoFilaFeedbackFake`).
- **Por que**: Garante que o robô navegue organicamente entre todas as abas (`Novo Protocolo`, `Histórico`, `Configurações`), abra e preencha qualquer um dos 5 protocolos no `WizardScreen`, troque o idioma da aplicação em tempo real (testando os 7 idiomas, inclusive RTL em árabe), consulte termos, edite identidade OIDC/ECDSA, acione o feedback in-app e dispare eventos de sincronização/conectividade.

### 2. Oráculo Unificado: Crashes + `FlutterError` + `RegistroLogger.logError`
- **Decisão**: Adicionar no `RegistroLogger` um callback opcional `void Function(String mensagem, Object? erro, StackTrace? stackTrace, {required bool ehCrash})? aoRegistrarErroOuCrash`. Durante cada passo do `MotorRoboCaotico`, `_executarCapturandoErro` monitora simultaneamente:
  1. Exceções lançadas pelo bloco de ação/pump (`excecao_nao_tratada`);
  2. `FlutterError.onError` e `tester.takeException()` (`flutter_error`, como `RenderFlex overflowed`);
  3. Chamadas a `RegistroLogger.instancia.logError` ou `logCrash` (`erro_registrado_log`).
- **Por que**: Muitas falhas reais em produção são capturadas em blocos `try/catch` que chamam `logger.logError(...)` para não derrubar a UI. Sem monitorar o `RegistroLogger`, esses erros passariam despercebidos pelo robô caótico.

### 3. Sentry Liberado o Tempo Todo + Envio da Receita Pós-Shrinking (`ddmin`)
- **Decisão**: Quando `reportarAoSentry: true`, o Sentry permanece ativo e liberado durante toda a campanha (registrando breadcrumbs e enviando em tempo real qualquer `logError`/`logCrash`). Além disso, assim que a sequência mínima `passosMinimos` é isolada pelo `EncolhedorCaminhoCrash` e a `ReceitaCrashRobo` é gerada e salva em `caminhos_regressao/`, o motor envia o evento via `RegistroLogger.instancia.logCrash` (com `HttpOverrides` real dentro de `tester.runAsync` quando em ambiente de teste) contendo `contextosExtras: {'receita_robo_caotico': receita.toJson()}`.
- **Por que**: O próprio Sentry faz a deduplicação automática de eventos repetidos na mesma Issue pelo fingerprint/stacktrace, então manter o Sentry liberado o tempo todo garante que nenhum erro ou breadcrumb seja perdido e anexa a receita mínima pronta para reprodução na Issue.

## Risks / Trade-offs

- [Timeouts em animações contínuas] → Quando `pumpAndSettle` atinge timeout de 2 segundos devido a `CircularProgressIndicator`, o motor captura apenas o timeout de settle e avança com `tester.pump(Duration(milliseconds: 100))`, sem falso positivo.
- [Seletores resilientes entre trocas de idioma] → `SeletorAlvoRobo` prioriza `ValueKey<String>` antes de recorrer a tipo + texto ou tipo + ícone.
