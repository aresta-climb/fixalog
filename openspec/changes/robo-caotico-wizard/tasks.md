# Tasks: Motor de Testes do Robô Caótico para o Wizard de Catalogação

## 1. Modelos de Ação e Seletores Semânticos

- [ ] 1.1 Criar os modelos `PassoRobo`, `SeletorAlvoRobo` e `ReceitaCrashRobo` em `app/test/caos/receita_crash_robo.dart` com suporte à serialização JSON
- [ ] 1.2 [TDD] Escrever testes unitários em `app/test/caos/receita_crash_robo_test.dart` validando serialização e restauração de receitas

## 2. Algoritmo de Delta Debugging (ddmin)

- [ ] 2.1 [TDD - Red] Escrever testes unitários em `app/test/caos/encolhedor_caminho_crash_test.dart` simulando sequências longas de passos com falhas em subconjuntos específicos
- [ ] 2.2 [TDD - Green] Implementar `EncolhedorCaminhoCrash` em `app/test/caos/encolhedor_caminho_crash.dart` com algoritmo de busca binária determinística

## 3. Motor Caótico e Ambiente de Execução

- [ ] 3.1 Implementar `FabricaDatasetCaos` em `app/test/caos/fabrica_dataset_caos.dart` fornecendo dados de teste normais e extremos para os protocolos
- [ ] 3.2 Implementar `MotorRoboCaotico` em `app/test/caos/motor_robo_caotico.dart` descobrindo botões, campos e opções do `WizardScreen` e disparando toques aleatórios guiados por `seed`
- [ ] 3.3 Escrever testes unitários para o motor em `app/test/caos/motor_robo_caotico_test.dart`

## 4. Suítes de Regressão Permanente e Campanha Exploratória

- [ ] 4.1 Criar a suíte permanente `app/test/caos/regressao_caminhos_test.dart` capaz de carregar e reexecutar qualquer receita salva em `app/test/caos/caminhos_regressao/*.json`
- [ ] 4.2 Criar a suíte exploratória `app/test/caos/robo_caotico_exploratorio_test.dart` com ativação condicional via `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS`

## 5. Auditoria de Qualidade

- [ ] 5.1 Executar a suíte de testes do módulo caótico com `flutter test test/caos/`
- [ ] 5.2 Executar análise estática de código (`flutter analyze`) garantindo zero warnings
