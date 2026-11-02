# Design: Motor de Testes do Robô Caótico e Regressão de UI

## Context

O assistente de catalogação pericial do FixLog (`WizardScreen`) gerencia estados complexos com validação contínua de formulários. O ecossistema Aresta possui um motor comprovado de testes caóticos com shrinking determinístico. Veja a motivação em `proposal.md`.

## Goals / Non-Goals

**Goals:**
- Implementar um motor de macaco caótico (*Monkey Testing*) em Dart puro sobre a API do `WidgetTester`.
- Garantir capacidade de encolhimento automático de passos via busca binária (*ddmin*).
- Integrar com o pipeline de CI rodando todas as receitas de regressão existentes em tempo recorde (< 1s por receita).
- Anexar a receita do robô caótico ao Sentry em caso de falhas durante campanhas noturnas.

**Non-Goals:**
- Substituir testes unitários e de widget orientados a comportamento (o robô caótico complementa, não substitui).
- Executar campanhas aleatórias longas em todo commit local (o teste diário roda apenas as receitas de regressão consolidadas).

## Decisions

### 1. Foco Inicial no `WizardScreen` e `NewProtocolScreen` com Banco SQLite `In-Memory`
- **Decisão**: Configurar o `motor_robo_caotico.dart` para inicializar a árvore de widgets a partir do formulário de protocolo técnico com banco SQLite em memória (`BancoDadosLocal.abrirEmMemoria()`) e os fakes de fronteira de hardware em `app/test/fakes/` (`ServicoGaleriaDispositivoFake`, etc.).
- **Por que**: É a área de maior densidade lógica e com mais entradas do usuário, onde o retorno sobre o investimento de testes de fuzzing é mais alto, exercitando inclusive o auto-save reativo no SQLite `:memory:` sem I/O bloqueante.

### 2. Algoritmo Delta Debugging (`ddmin`)
- **Decisão**: Implementar a classe `EncolhedorCaminhoCrash` que particiona a lista de passos em pedaços e remove subconjuntos até que nenhum passo adicional possa ser removido sem que o teste volte a passar.
- **Por que**: Sequências caóticas de 100 passos são impossíveis de analisar visualmente por um desenvolvedor humano; a versão encolhida de 3 ou 4 passos isola a causa raiz imediatamente.

### 3. Execução Silenciosa por Padrão no CI Diário
- **Decisão**: O arquivo `robo_caotico_exploratorio_test.dart` lê a variável `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS`. Se for 0 (padrão), o teste é ignorado instantaneamente. Já o `regressao_caminhos_test.dart` roda sempre.
- **Por que**: Impede lentidão no desenvolvimento diário e permite rodar campanhas exploratórias longas (ex: 5 minutos) apenas em cron jobs noturnos ou antes de releases.

## Risks / Trade-offs

- [Testes de renderização lentos] → O robô utiliza passos curtos com `pump(Duration(milliseconds: 50))` em vez de aguardar animações longas a cada clique, reduzindo o tempo de execução.
- [Dependência de texto mutável em botões] → O modelo `SeletorAlvoRobo` combina chaves semânticas (`Key`), tipo do widget e texto para evitar que pequenas mudanças de rótulo quebrem receitas gravadas.
