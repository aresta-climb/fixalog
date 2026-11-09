# Tasks: Motor de Testes do Robô Caótico para o Aplicativo Completo (`FixalogApp`)

## 1. Hook de Oráculo no `RegistroLogger` e Modelos de Receita (Library-First & TDD)

- [x] 1.1 [TDD] Adicionar callback opcional `aoRegistrarErroOuCrash` e flag de teste no `RegistroLogger` (`app/lib/core/services/registro_logger.dart`) e expandir `app/test/core/services/registro_logger_test.dart` garantindo que tanto `logError` quanto `logCrash` notifiquem o oráculo do Robô Caótico
- [x] 1.2 [TDD - Red] Escrever testes unitários em `app/test/caos/receita_crash_robo_test.dart` (com cabeçalho SPDX) validando criação, extração de assinatura, instruções de regressão e serialização/desserialização JSON de `PassoRobo`, `SeletorAlvoRobo` e `ReceitaCrashRobo`
- [x] 1.3 [TDD - Green] Implementar os modelos `PassoRobo`, `SeletorAlvoRobo`, `TipoDatasetCaos`, `TipoAcaoRobo` e `ReceitaCrashRobo` em `app/test/caos/receita_crash_robo.dart`

## 2. Algoritmo de Delta Debugging (`ddmin`)

- [x] 2.1 [TDD - Red] Escrever testes unitários em `app/test/caos/encolhedor_caminho_crash_test.dart` simulando sequências longas de passos (ex.: 40 passos onde apenas 3 passos específicos causam falha combinada) e verificando a redução exata 1-minimal
- [x] 2.2 [TDD - Green] Implementar `EncolhedorCaminhoCrash` em `app/test/caos/encolhedor_caminho_crash.dart` com algoritmo de busca binária determinística (`ddmin`)

## 3. Fábrica de Datasets (`normal` e `toxico`), `AmbienteAppCaos` (App Completo) e `MotorRoboCaotico`

- [x] 3.1 [TDD] Implementar `FabricaDatasetCaos` e `AmbienteAppCaos` em `app/test/caos/fabrica_dataset_caos.dart` montando o `FixalogApp` completo sobre `BancoDadosLocal.abrirEmMemoria()` (com sessões de histórico rascunho/assinadas, catálogo de materiais, identidade e textos extremos nos 7 idiomas) e Fakes determinísticos de fronteira, com seus testes em `app/test/caos/fabrica_dataset_caos_test.dart`
- [x] 3.2 [TDD - Red] Escrever testes de widget para o motor em `app/test/caos/motor_robo_caotico_test.dart` validando: (a) exploração do aplicativo completo (`FixalogApp`), (b) determinismo para uma mesma `seed`, (c) detecção e shrinking tanto de exceções/crashes quanto de erros tratados via `RegistroLogger.logError`, e (d) envio consolidado de `receita_robo_caotico` ao Sentry/Logger
- [x] 3.3 [TDD - Green] Implementar `MotorRoboCaotico` em `app/test/caos/motor_robo_caotico.dart` com oráculo unificado (crashes + `FlutterError` + `RegistroLogger.logError`) e Sentry liberado o tempo todo quando `reportarAoSentry: true`

## 4. Suítes de Regressão Permanente, Campanha Exploratória e Dispositivo

- [x] 4.1 Criar a pasta `app/test/caos/caminhos_regressao/` com uma receita canônica de validação inicial e implementar `app/test/caos/regressao_caminhos_test.dart` para carregar e reexecutar automaticamente todas as receitas `.json`
- [x] 4.2 Implementar a suíte exploratória `app/test/caos/robo_caotico_exploratorio_test.dart` e a suíte de dispositivo `app/integration_test/robo_caotico_dispositivo_test.dart` com suporte a `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS`, `--dart-define=REPORTAR_SENTRY_CAOS` e `--dart-define=SEED_INICIAL_CAOS`

## 5. Integração no Workflow de Release e Auditoria de Qualidade

- [x] 5.1 Atualizar `.github/workflows/release_new_app_version.yml` adicionando o input `executar_robo_caotico` (`type: boolean`, `default: true`, `required: true`) e os steps separados de `flutter analyze`, `Executar Suíte de Testes (TDD & Regressão)` (`flutter test`), `Executar Campanha do Robô Caótico (5 min)` (`if: ${{ inputs.executar_robo_caotico }}`) e upload de artefatos de receitas (`app/test/caos/caminhos_regressao/*.json`) em caso de falha, com validação no teste arquitetural em `app/test/architecture/`
- [x] 5.2 Executar a suíte de testes do módulo caótico (`flutter test test/caos/`) e os testes arquiteturais (`flutter test test/architecture/`) validando espelhamento 1:1 e cabeçalhos SPDX (`license_headers_test.dart`)
- [x] 5.3 Executar `flutter test --coverage` e `flutter analyze` garantindo 100% de cobertura nas alterações de produção e zero warnings
