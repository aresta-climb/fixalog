# Testes Caóticos Exploratórios e Regressão no Aplicativo Completo

## Purpose

Fornece motor de testes exploratórios de estresse com navegação aleatória determinística sobre o aplicativo completo (`FixalogApp`), oráculo unificado de crashes e erros tratados (`RegistroLogger.logError`), redução automática de passos (`ddmin`), envio consolidado ao Sentry e reprodução determinística de falhas em CI e em dispositivos.

## Requirements

### Requirement: Navegação Caótica Autônoma no Aplicativo Completo
O motor de testes DEVE (MUST) montar a árvore completa do aplicativo (`FixalogApp` com `BetterFeedback` e `ProviderScope`) sobre banco SQLite em memória (`BancoDadosLocal.abrirEmMemoria()`) populado com perfis de dados `normal` e `toxico`, descobrindo dinamicamente elementos interativos em todas as telas (`HomeScreen`, `NewProtocolScreen`, `WizardScreen` nos 5 protocolos YAML, `HistoryScreen`, `TelaConfiguracoes` nos 7 idiomas, `IdentitySetupScreen` e `TelaTermosDeUso`) e executando sequências determinísticas guiadas por `seed`.

#### Scenario: Exploração determinística multi-tela e multi-protocolo
- **WHEN** uma sessão do `MotorRoboCaotico` é executada com uma semente (`seed`) e um perfil de dataset (`normal` ou `toxico`)
- **THEN** o robô interage com abas, formulários do wizard, histórico, troca de idiomas e configurações de maneira 100% determinística e reprodutível através do `WidgetTester`

### Requirement: Oráculo Unificado de Crashes, Erros de Renderização e Erros Registrados no Logger
O motor de testes DEVE (MUST) detectar como falha da sessão não apenas exceções não tratadas e erros de framework/layout (`FlutterError.onError`, como `RenderFlex overflow`), mas também qualquer erro tratado registrado pela aplicação em `RegistroLogger.logError` ou `RegistroLogger.logCrash`.

#### Scenario: Detecção de erro tratado capturado por try/catch interno
- **WHEN** uma interação sorteada pelo robô dispara uma falha capturada por um bloco `try/catch` que invoca `RegistroLogger.instancia.logError`
- **THEN** o oráculo do `MotorRoboCaotico` intercepta a chamada ao logger, classifica o passo como falha reproduzível (`erro_registrado_log`) e inicia o encolhimento da receita

### Requirement: Encolhimento Automático (Delta Debugging) e Envio ao Sentry com Telemetria Liberada
O sistema de teste DEVE (MUST) aplicar o algoritmo de Delta Debugging (`ddmin`) via `EncolhedorCaminhoCrash` para reduzir sequências de ações que geraram crash ou erro até a menor combinação necessária de passos, mantendo o Sentry liberado o tempo todo durante a campanha (`reportarAoSentry: true`) e enviando ao final a falha com `receita_robo_caotico` nos contextos extras.

#### Scenario: Redução de passos mínimos e notificação ao Sentry
- **WHEN** uma sequência de ações aleatórias provoca um crash, `FlutterError` ou `RegistroLogger.logError` durante uma campanha com `reportarAoSentry: true`
- **THEN** o Sentry permanece liberado em tempo real (agrupando ocorrências repetidas na mesma Issue por deduplicação nativa) e, ao concluir o `EncolhedorCaminhoCrash`, recebe a `ReceitaCrashRobo` mínima em `RegistroLogger.logCrash`

### Requirement: Reexecução Determinística de Regressão e Suporte a Dispositivo
A suíte de testes DEVE (MUST) carregar automaticamente todas as receitas JSON em `app/test/caos/caminhos_regressao/` através de `regressao_caminhos_test.dart` em toda execução do `flutter test`, além de disponibilizar `robo_caotico_exploratorio_test.dart` e `integration_test/robo_caotico_dispositivo_test.dart` para campanhas por tempo em CI ou dispositivo/emulador.

#### Scenario: Prevenção de regressão em build de CI
- **WHEN** o comando `flutter test` é acionado
- **THEN** todas as receitas salvas em `caminhos_regressao` são reexecutadas contra o aplicativo completo em menos de um segundo por receita

### Requirement: Campanha Exploratória Controlada por Flag no Workflow de Release
O workflow `.github/workflows/release_new_app_version.yml` DEVE (MUST) expor um input booleano `executar_robo_caotico` com valor padrão `true` no `workflow_dispatch`, executando sempre a suíte padrão (`flutter test`) em um step dedicado e condicionando o step da campanha exploratória de 5 minutos (`robo_caotico_exploratorio_test.dart` com `DURACAO_CAMPANHA_CAOS_SEGUNDOS=300` e `REPORTAR_SENTRY_CAOS=true`) ao valor de `inputs.executar_robo_caotico`.

#### Scenario: Execução padrão no lançamento de versão
- **WHEN** o workflow `release_new_app_version.yml` é disparado mantendo `executar_robo_caotico: true`
- **THEN** o job `prepare_release` executa o step de testes unitários/regressão e, em seguida, executa o step de 5 minutos do Robô Caótico reportando eventuais falhas ao Sentry e fazendo upload das receitas JSON como artefato

#### Scenario: Pulo opcional da campanha de 5 minutos em release emergencial
- **WHEN** o workflow `release_new_app_version.yml` é disparado com `executar_robo_caotico: false`
- **THEN** o job `prepare_release` executa normalmente `flutter analyze` e `flutter test` (incluindo `regressao_caminhos_test.dart`), mas pula o step da campanha exploratória de 5 minutos
