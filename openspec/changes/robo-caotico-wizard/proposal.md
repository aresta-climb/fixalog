# Proposta: Motor de Testes do Robô Caótico para o Wizard de Catalogação

## Why

O fluxo de preenchimento de protocolos periciais de inspeção técnica (`WizardScreen`) no Fixalog é complexo e dinâmico, envolvendo árvores condicionais em YAML/Protobuf, listas aninhadas (`StepListaAcoes`), catálogo de materiais (`StepRefMateriais`), validações de campos obrigatórios, fotos, vídeos, documentos PDF e metadados de GPS. Testes unitários convencionais costumam seguir caminhos felizes (*happy paths*) previsíveis e deixam de detectar combinações caóticas de ações rápidas, rotações de tela e preenchimentos parciais que ocorrem com frequência no manuseio de smartphones em falésias.

Inspirado no motor de caos do `aresta_app`, a introdução do **Robô Caótico** (*Monkey / Fuzzing Testing*) autônomo sobre o `WizardScreen` permite exercitar o aplicativo com milhares de interações aleatórias guiadas por semente determinística (`seed`). O algoritmo de *Delta Debugging* (`ddmin`) reduz automaticamente qualquer falha encontrada à sua sequência mínima de passos, gravando uma receita JSON em `test/caos/caminhos_regressao/` que passa a ser executada em menos de 1 segundo nos testes diários e na esteira de CI, garantindo imunidade permanente a regressões.

## What Changes

- **Motor de Testes Caóticos (`test/caos/motor_robo_caotico.dart`)**:
  - Orquestrador sobre `WidgetTester` capaz de identificar botões, campos de texto, seletores de opções e áreas de scroll visíveis no `WizardScreen`.
  - Sorteio determinístico de ações com controle de cadência de renderização (`pump` de 50 a 350 ms).
- **Algoritmo de Delta Debugging (`test/caos/encolhedor_caminho_crash.dart`)**:
  - Algoritmo de busca binária que recebe uma longa sequência de passos caóticos que resultou em crash e a encolhe para o menor conjunto reprodutível de interações.
- **Modelos de Receita e Seletores Semânticos (`test/caos/receita_crash_robo.dart`)**:
  - Serialização JSON com metadados da falha, semente original, passos mínimos e seletores resilientes por chave ou texto.
- **Suíte de Regressão Permanente (`test/caos/regressao_caminhos_test.dart`)**:
  - Teste automatizado que varre a pasta `test/caos/caminhos_regressao/*.json` e reexecuta todas as receitas registradas no `flutter test` de CI em tempo inferior a 1 segundo.
- **Integração com Relatório de Sentry (`receita_robo_caotico`)**:
  - Em campanhas de teste automatizadas, caso o robô encontre uma exceção, o JSON da receita mínima é anexado ao contexto do evento do Sentry para diagnóstico instantâneo.

## Capabilities

### New Capabilities
- `testes-caoticos-exploratorios`: Motor de testes de estresse exploratório autônomo sobre o wizard de catalogação com redução delta debugging e geração de receitas de regressão.

### Modified Capabilities
*(Nenhuma especificação existente teve seus requisitos de comportamento do app alterados)*

## Impact

- **Ambiente de Testes (`app/test/caos/`)**:
  - Criação da pasta de testes caóticos com motor, encolhedor, gerador de datasets tóxicos e suíte de regressão.
- **Código de Produção**:
  - Não altera comportamento público de produção, exceto por garantir que o `WizardScreen` e seus controladores tratem estados nulos e toques rápidos com resiliência.
- **CI/CD**:
  - Execução contínua das receitas de regressão no GitHub Actions a cada PR.
