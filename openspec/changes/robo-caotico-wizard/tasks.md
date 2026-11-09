# Tasks: Motor de Testes do Robô Caótico para o Wizard de Catalogação

## 1. Modelos de Ação e Seletores Semânticos (Library-First & TDD)

- [ ] 1.1 [TDD - Red] Escrever testes unitários em `app/test/caos/receita_crash_robo_test.dart` (com cabeçalho SPDX) validando criação, igualdade e serialização/desserialização JSON de `PassoRobo`, `SeletorAlvoRobo` e `ReceitaCrashRobo`
- [ ] 1.2 [TDD - Green] Implementar os modelos `PassoRobo`, `SeletorAlvoRobo` e `ReceitaCrashRobo` em `app/test/caos/receita_crash_robo.dart`

## 2. Algoritmo de Delta Debugging (`ddmin`)

- [ ] 2.1 [TDD - Red] Escrever testes unitários em `app/test/caos/encolhedor_caminho_crash_test.dart` simulando sequências longas de passos (ex.: 40 passos onde apenas 3 passos específicos causam falha combinada) e verificando a redução exata
- [ ] 2.2 [TDD - Green] Implementar `EncolhedorCaminhoCrash` em `app/test/caos/encolhedor_caminho_crash.dart` com algoritmo de busca binária determinística (`ddmin`)

## 3. Fábrica de Datasets Tóxicos e Motor Caótico

- [ ] 3.1 [TDD] Implementar `FabricaDatasetCaos` em `app/test/caos/fabrica_dataset_caos.dart` (fornecendo entradas extremas de texto, números, scripts RTL/CJK, seleção dos 5 protocolos YAML e 7 idiomas, além de sementes de materiais no SQLite) e seus testes unitários em `app/test/caos/fabrica_dataset_caos_test.dart`
- [ ] 3.2 [TDD - Red] Escrever testes de widget para o motor em `app/test/caos/motor_robo_caotico_test.dart` validando descoberta de elementos no `WizardScreen`, determinismo para uma mesma `seed`, captura de falhas e integração com `RegistroLoggerFake`
- [ ] 3.3 [TDD - Green] Implementar `MotorRoboCaotico` em `app/test/caos/motor_robo_caotico.dart` utilizando `BancoDadosLocal.abrirEmMemoria()` e os Fakes determinísticos de fronteira (`ServicoGaleriaDispositivoFake`, `VideoTranscoderServiceFake`, `CryptoServiceFake`, `SincronizadorNuvemServiceFake`, `AutenticacaoNuvemServiceFake`, `RegistroLoggerFake`)

## 4. Suítes de Regressão Permanente e Campanha Exploratória

- [ ] 4.1 Criar a pasta `app/test/caos/caminhos_regressao/` com uma receita canônica de validação inicial e implementar `app/test/caos/regressao_caminhos_test.dart` para carregar e reexecutar automaticamente todas as receitas `.json`
- [ ] 4.2 Implementar a suíte exploratória `app/test/caos/robo_caotico_exploratorio_test.dart` com suporte a `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS`, encolhimento automático via `EncolhedorCaminhoCrash`, gravação da receita mínima em `caminhos_regressao/` e envio do contexto `receita_robo_caotico` ao `RegistroLogger`

## 5. Integração no Workflow de Release e Auditoria de Qualidade

- [ ] 5.1 Atualizar `.github/workflows/release_new_app_version.yml` adicionando o input `executar_robo_caotico` (`type: boolean`, `default: true`, `required: true`) e os steps separados de `flutter analyze`, `Executar Suíte de Testes (TDD & Regressão)` (`flutter test`), `Executar Campanha do Robô Caótico (5 min)` (`if: ${{ inputs.executar_robo_caotico }}`) e upload de artefatos de receitas (`app/test/caos/caminhos_regressao/*.json`) em caso de falha, com teste arquitetural correspondente em `app/test/architecture/`
- [ ] 5.2 Executar a suíte de testes do módulo caótico (`flutter test test/caos/`) e os testes arquiteturais (`flutter test test/architecture/`) validando espelhamento 1:1 e cabeçalhos SPDX (`license_headers_test.dart`)
- [ ] 5.3 Executar análise estática de código (`flutter analyze`) garantindo zero warnings
