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
