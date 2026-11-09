# Proposta: Motor de Testes do Robô Caótico para o Wizard de Catalogação e Multi-Protocolos

## Why

O fluxo de preenchimento de protocolos periciais de inspeção técnica (`WizardScreen` e `NewProtocolScreen`) no Fixalog evoluiu significativamente e tornou-se altamente dinâmico, envolvendo 5 protocolos YAML traduzidos em 7 idiomas (`bolt_maintenance`, `route_opening`, `visual_inspection`, `material_registration`, `incident_report`), árvores condicionais (`StepSelecaoRamo`), listas aninhadas repetíveis (`StepListaAcoes`), vínculo cruzado com o catálogo de materiais no SQLite (`StepRefMateriais`), anexos de fotos, vídeos com corte de 60s, documentos PDF, duplicação de relatórios a partir do histórico e auto-save reativo em YAML/Protobuf. Testes unitários convencionais seguem caminhos previsíveis e deixam de detectar combinações caóticas de toques rápidos, alternância de ramos condicionais, mudanças de idioma (incluindo RTL em árabe) e preenchimentos parciais que ocorrem no manuseio em falésias.

Inspirado no motor de caos do `aresta_app`, a introdução do **Robô Caótico** (*Monkey / Fuzzing Testing*) autônomo sobre o `WizardScreen` permite exercitar o aplicativo com milhares de interações aleatórias guiadas por semente determinística (`seed`), utilizando banco SQLite real em memória (`BancoDadosLocal.abrirEmMemoria()`) e Fakes determinísticos de hardware. O algoritmo de *Delta Debugging* (`ddmin`) reduz automaticamente qualquer falha encontrada à sua sequência mínima de passos, gravando uma receita JSON em `app/test/caos/caminhos_regressao/` que passa a ser executada em menos de 1 segundo nos testes diários e na esteira de CI, garantindo imunidade permanente a regressões.

## What Changes

- **Motor de Testes Caóticos (`app/test/caos/motor_robo_caotico.dart`)**:
  - Orquestrador sobre `WidgetTester` capaz de descobrir botões, campos de texto, seletores de opções, ramos condicionais (`StepSelecaoRamo`), listas de ações (`StepListaAcoes`), seletores de materiais (`StepRefMateriais`), anexos de mídia/documento e áreas de scroll visíveis no `WizardScreen`.
  - Inicialização isolada e 100% determinística com `BancoDadosLocal.abrirEmMemoria()` e as bibliotecas de Fakes de fronteira (`ServicoGaleriaDispositivoFake`, `VideoTranscoderServiceFake`, `CryptoServiceFake`, `SincronizadorNuvemServiceFake`, `AutenticacaoNuvemServiceFake`, `RegistroLoggerFake`).
  - Sorteio determinístico de ações com controle de cadência de renderização (`pump` de 50 a 350 ms) e suporte aos 7 idiomas suportados (incluindo verificação de overflow visual em `ar` e `ja`).
- **Gerador de Datasets e Cenários Tóxicos (`app/test/caos/fabrica_dataset_caos.dart`)**:
  - Geração determinística de strings extremas (textos longos, caracteres especiais, emojis, scripts RTL/CJK, números limites) e pré-população opcional de materiais registrados no SQLite em memória.
- **Algoritmo de Delta Debugging (`app/test/caos/encolhedor_caminho_crash.dart`)**:
  - Algoritmo de busca binária (`ddmin`) que recebe uma longa sequência de passos caóticos que resultou em falha (exceção não tratada, erro de renderização/overflow ou falha de asserção) e a encolhe para o menor subconjunto reprodutível de interações.
- **Modelos de Receita e Seletores Semânticos (`app/test/caos/receita_crash_robo.dart`)**:
  - Serialização JSON com metadados da falha, semente original, protocolo/idioma alvo, passos mínimos e seletores resilientes por chave (`Key`), tipo de widget ou texto.
- **Suíte de Regressão Permanente (`app/test/caos/regressao_caminhos_test.dart`)**:
  - Teste automatizado que varre a pasta `app/test/caos/caminhos_regressao/*.json` e reexecuta todas as receitas registradas no `flutter test` de CI em tempo inferior a 1 segundo por receita.
- **Integração com `RegistroLogger` e Sentry (`receita_robo_caotico`)**:
  - Em campanhas de teste exploratórias (`robo_caotico_exploratorio_test.dart`), caso o robô encontre uma exceção, o JSON da receita mínima encolhida é anexado ao contexto do `RegistroLogger.instance.logCrash` para diagnóstico imediato.
- **Integração no Workflow de Release (`.github/workflows/release_new_app_version.yml`)**:
  - Adição do input booleano opcional `executar_robo_caotico` (`default: true`, `required: true`) no `workflow_dispatch`.
  - Separação explícita no job `prepare_release` entre a etapa sempre obrigatória (`flutter analyze` e `flutter test` para TDD + receitas de regressão) e a etapa `Executar Campanha do Robô Caótico (5 min)` condicionada a `if: ${{ inputs.executar_robo_caotico }}` (executando `flutter test test/caos/robo_caotico_exploratorio_test.dart --dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=300 --dart-define=REPORTAR_SENTRY_CAOS=true --timeout=10m`), seguida do upload de artefatos de receitas em caso de falha.

## Capabilities

### New Capabilities
- `testes-caoticos-exploratorios`: Motor de testes de estresse exploratório autônomo sobre os fluxos multi-protocolo do wizard de catalogação com redução delta debugging (`ddmin`) e geração de receitas de regressão.

### Modified Capabilities
*(Nenhuma especificação canônica existente em `openspec/specs/` teve seus requisitos de comportamento do app alterados)*

## Impact

- **Ambiente de Testes (`app/test/caos/`)**:
  - Criação da biblioteca de testes caóticos (`receita_crash_robo.dart`, `encolhedor_caminho_crash.dart`, `fabrica_dataset_caos.dart`, `motor_robo_caotico.dart`), seus respectivos testes unitários espelhados (`*_test.dart`) e as suítes `regressao_caminhos_test.dart` e `robo_caotico_exploratorio_test.dart`.
- **Código de Produção**:
  - Não altera contratos públicos de produção; eventuais fragilidades descobertas no `WizardScreen` durante a validação inicial serão corrigidas com suas respectivas receitas salvas em `caminhos_regressao/`.
- **CI/CD**:
  - Execução contínua e automática das receitas de regressão (`regressao_caminhos_test.dart`) em toda execução do `flutter test`.
  - Atualização do `.github/workflows/release_new_app_version.yml` para validar `flutter analyze`, `flutter test` e rodar a campanha de 5 minutos do Robô Caótico controlada pela flag `executar_robo_caotico` (`default: true`).
