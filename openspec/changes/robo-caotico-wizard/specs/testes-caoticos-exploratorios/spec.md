# Spec Delta: Testes Caóticos Exploratórios e Regressão de UI

## Purpose

Fornece motor de testes exploratórios de estresse com navegação aleatória sobre a interface do wizard, redução automática de passos e reprodução determinística de falhas em CI.

## ADDED Requirements

### Requirement: Navegação Caótica Autônoma
O motor de testes DEVE (MUST) descobrir dinamicamente elementos interativos na árvore de widgets do formulário de inspeção e disparar sequências aleatórias determinísticas baseadas em uma semente inteira configurável.

#### Scenario: Execução de passos exploratórios no wizard
- **WHEN** a suíte de testes caóticos é executada com uma semente definida
- **THEN** o robô realiza toques, rolagem e preenchimento de campos de forma reprodutível através de `WidgetTester`

### Requirement: Encolhimento Automático de Sequência de Falha
O sistema de teste DEVE (MUST) aplicar o algoritmo de Delta Debugging para reduzir sequências de ações caóticas que geraram erro até obter a menor combinação necessária de passos para reproduzir o mesmo erro.

#### Scenario: Redução de passos mínimos de um crash
- **WHEN** uma sequência de 50 ações aleatórias provoca uma falha de renderização ou estado nulo
- **THEN** o encolhedor executa busca binária descartando passos redundantes e gera uma receita mínima contendo apenas as interações estritamente essenciais

### Requirement: Reexecução Determinística de Regressão
A suíte de testes DEVE (MUST) carregar automaticamente todas as receitas de falha salvas em formato JSON e reexecutá-las sequencialmente no ambiente de CI em tempo total inferior a um segundo por receita.

#### Scenario: Prevenção de regressão em build de CI
- **WHEN** o comando de teste de regressão é acionado
- **THEN** todas as receitas previamente salvas em `caminhos_regressao` são validadas contra o código atual, garantindo que o bug não ocorra novamente
