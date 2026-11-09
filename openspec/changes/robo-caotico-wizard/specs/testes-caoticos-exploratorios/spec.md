# Spec Delta: Testes Caóticos Exploratórios e Regressão de UI

## Purpose

Fornece motor de testes exploratórios de estresse com navegação aleatória determinística sobre os fluxos multi-protocolo e multilíngues do wizard de catalogação, redução automática de passos (`ddmin`) e reprodução determinística de falhas em CI.

## ADDED Requirements

### Requirement: Navegação Caótica Autônoma Multi-Protocolo
O motor de testes DEVE (MUST) descobrir dinamicamente elementos interativos na árvore de widgets do formulário de inspeção (`WizardScreen`, incluindo campos de texto, seletores de ramo condicional, listas de ações, referências de materiais e botões de mídia) e disparar sequências aleatórias determinísticas baseadas em uma semente inteira (`seed`) configurável sobre banco SQLite em memória (`BancoDadosLocal.abrirEmMemoria()`).

#### Scenario: Execução de passos exploratórios determinísticos no wizard
- **WHEN** a suíte de testes caóticos é executada com uma semente (`seed`) definida para um protocolo e idioma
- **THEN** o robô realiza toques, rolagem, seleção de opções e preenchimento de campos com entradas extremas de forma 100% reprodutível através do `WidgetTester`

### Requirement: Encolhimento Automático de Sequência de Falha (Delta Debugging)
O sistema de teste DEVE (MUST) aplicar o algoritmo de Delta Debugging (`ddmin`) para reduzir sequências de ações caóticas que geraram erro (exceção não tratada ou erro de layout/renderização) até obter a menor combinação necessária de passos para reproduzir o mesmo erro, anexando a receita resultante ao `RegistroLogger`.

#### Scenario: Redução de passos mínimos de um crash
- **WHEN** uma sequência de 50 ações aleatórias provoca uma falha de renderização ou exceção de estado
- **THEN** o `EncolhedorCaminhoCrash` executa busca binária descartando passos irrelevantes e produz uma `ReceitaCrashRobo` mínima contendo apenas as interações essenciais

### Requirement: Reexecução Determinística de Regressão
A suíte de testes DEVE (MUST) carregar automaticamente todas as receitas de falha salvas em formato JSON em `app/test/caos/caminhos_regressao/` e reexecutá-las sequencialmente no ambiente de CI em tempo inferior a um segundo por receita.

#### Scenario: Prevenção de regressão em build de CI
- **WHEN** o comando `flutter test` é acionado
- **THEN** todas as receitas previamente salvas em `caminhos_regressao` são reexecutadas contra o código atual, garantindo que nenhum bug anteriormente descoberto pelo robô volte a ocorrer

### Requirement: Campanha Exploratória Controlada por Flag no Workflow de Release
O workflow `.github/workflows/release_new_app_version.yml` DEVE (MUST) expor um input booleano `executar_robo_caotico` com valor padrão `true` no `workflow_dispatch`, executando sempre a suíte padrão (`flutter test`) em um step dedicado e condicionando o step da campanha exploratória de 5 minutos (`robo_caotico_exploratorio_test.dart` com `DURACAO_CAMPANHA_CAOS_SEGUNDOS=300`) ao valor de `inputs.executar_robo_caotico`.

#### Scenario: Execução padrão no lançamento de versão
- **WHEN** o workflow `release_new_app_version.yml` é disparado mantendo `executar_robo_caotico: true`
- **THEN** o job `prepare_release` executa o step de testes unitários/regressão e, em seguida, executa o step de 5 minutos do Robô Caótico antes de criar a tag da versão

#### Scenario: Pulo opcional da campanha de 5 minutos em release emergencial
- **WHEN** o workflow `release_new_app_version.yml` é disparado com `executar_robo_caotico: false`
- **THEN** o job `prepare_release` executa normalmente `flutter analyze` e `flutter test` (incluindo `regressao_caminhos_test.dart`), mas pula o step da campanha exploratória de 5 minutos do Robô Caótico
