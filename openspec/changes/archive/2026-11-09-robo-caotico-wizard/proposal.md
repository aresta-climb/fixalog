# Proposta: Motor de Testes do Robô Caótico para o Aplicativo Completo (`FixalogApp`)

## Why

O Fixalog evoluiu para um ecossistema completo de auditoria pericial offline-first contendo múltiplas telas e fluxos integrados: `TelaTermosDeUso` (onboarding legal), `IdentitySetupScreen` (identidade local + OIDC OpenPubkey + chaves ECDSA P-256), `HomeScreen` com suas 3 abas (`NewProtocolScreen`, `HistoryScreen` e `TelaConfiguracoes`), `BetterFeedback` (captura e anotação de tela) e o `WizardScreen` com 5 protocolos YAML traduzidos em 7 idiomas (`bolt_maintenance`, `route_opening`, `visual_inspection`, `material_registration`, `incident_report`), árvores condicionais (`StepSelecaoRamo`), listas aninhadas repetíveis (`StepListaAcoes`), vínculo cruzado com o catálogo de materiais (`StepRefMateriais`), anexos multimídia e geração de pacotes EPUB 3 / PDF assinados.

Inspirado nos motores de caos do `aresta_app` e do `aresta_db` (`OraculosCaos`), o **Robô Caótico** (*Monkey / Fuzzing Testing*) deve montar e exercitar **o aplicativo inteiro (`FixalogApp`)** com milhares de interações aleatórias guiadas por semente determinística (`seed`), utilizando banco SQLite real em memória (`BancoDadosLocal.abrirEmMemoria()`) e Fakes determinísticos de hardware. Além de capturar crashes e erros de layout (`FlutterError` / `RenderFlex overflow`), o oráculo do robô deve interceptar **qualquer erro registrado via `RegistroLogger.logError` ou `logCrash`** (mesmo quando capturado por um `try/catch` interno), aplicar o algoritmo de *Delta Debugging* (`ddmin`) para reduzir a falha à sua sequência mínima de passos, gravar a receita JSON em `app/test/caos/caminhos_regressao/` e enviar o evento consolidado com a receita encolhida ao Sentry.

## What Changes

- **Oráculo de Erros e Crashes no `RegistroLogger` (`app/lib/core/services/registro_logger.dart`)**:
  - Adição de um listener/hook opcional de inspeção (`aoRegistrarErroOuCrash`) no `RegistroLogger` para que o `MotorRoboCaotico` detecte imediatamente qualquer chamada a `logError` ou `logCrash` ocorrida durante um passo na aplicação (mesmo dentro de um `try/catch`), mantendo o Sentry liberado o tempo todo durante a campanha (`reportarAoSentry: true`) e enviando também a receita encolhida (`receita_robo_caotico`) ao final do `ddmin`.
- **Motor de Testes Caóticos no Aplicativo Completo (`app/test/caos/motor_robo_caotico.dart`)**:
  - Orquestrador sobre `WidgetTester` que monta o `FixalogApp` completo (com `ProviderScope` e `BetterFeedback`) e descobre dinamicamente todos os widgets interativos visíveis (abas da `HomeScreen`, cartões de protocolo na `NewProtocolScreen`, filtros/ações na `HistoryScreen`, seletores de idioma/termos/identidade/feedback na `TelaConfiguracoes`, e todos os blocos/steps do `WizardScreen`).
  - Interceptação unificada de: (1) exceções não tratadas, (2) `FlutterError.onError` (incluindo `RenderFlex overflow` nos 7 idiomas e modo RTL em árabe) e (3) erros tratados reportados em `RegistroLogger.logError` / `logCrash`.
- **Gerador de Datasets e Ambiente do App (`app/test/caos/fabrica_dataset_caos.dart`)**:
  - `AmbienteAppCaos` e `FabricaDatasetCaos` com perfis `TipoDatasetCaos.normal` e `TipoDatasetCaos.toxico` populando `BancoDadosLocal.abrirEmMemoria()` (configuração de termos/idioma, identidade pericial, catálogo de materiais, rascunhos e laudos assinados no histórico com textos extremos, scripts RTL/CJK e Markdown/YAML limites) e injetando os Fakes determinísticos (`ServicoGaleriaDispositivoFake`, `VideoTranscoderServiceFake`, `CryptoServiceFake`, `SincronizadorNuvemServiceFake`, `AutenticacaoNuvemServiceFake`, `ServicoFilaFeedbackFake`).
- **Algoritmo de Delta Debugging (`app/test/caos/encolhedor_caminho_crash.dart`)**:
  - Algoritmo de busca binária (`ddmin`) que reduz qualquer sequência de passos que gerou crash, erro de layout ou `RegistroLogger.logError` até o menor subconjunto reprodutível.
- **Modelos de Receita e Seletores Semânticos (`app/test/caos/receita_crash_robo.dart`)**:
  - Serialização JSON com metadados da falha (`oraculo`: `excecao_nao_tratada`, `flutter_error` ou `erro_registrado_log`), semente original, dataset (`normal`/`toxico`), passos mínimos e seletores resilientes.
- **Suíte de Regressão, Campanha Exploratória e Teste em Dispositivo**:
  - `app/test/caos/regressao_caminhos_test.dart`: reexecuta todas as receitas de `app/test/caos/caminhos_regressao/*.json` em `< 1s` por receita no `flutter test`.
  - `app/test/caos/robo_caotico_exploratorio_test.dart`: campanha por tempo (`--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS`) com envio ao Sentry (`--dart-define=REPORTAR_SENTRY_CAOS=true`).
  - `app/integration_test/robo_caotico_dispositivo_test.dart`: execução da campanha caótica diretamente em dispositivo físico ou emulador Android/iOS.
- **Integração no Workflow de Release (`.github/workflows/release_new_app_version.yml`)**:
  - Adição do input booleano `executar_robo_caotico` (`default: true`, `required: true`) no `workflow_dispatch`, executando `flutter analyze`, `flutter test` e a campanha de 5 minutos do Robô Caótico com upload de artefatos JSON em caso de falha.

## Capabilities

### New Capabilities
- `testes-caoticos-exploratorios`: Motor de testes de estresse exploratório autônomo sobre o aplicativo completo (`FixalogApp`), com oráculo de crashes e erros (`logError`), redução delta debugging (`ddmin`), envio consolidado ao Sentry e geração de receitas de regressão.

### Modified Capabilities
- `observabilidade-dual-logger`: Suporte a hook de inspeção de erros (`aoRegistrarErroOuCrash`) no `RegistroLogger` para detecção determinística de erros tratados durante campanhas do Robô Caótico.

## Impact

- **Código de Produção**:
  - Adição de callback opcional de observação de erros/crashes no `RegistroLogger` (`app/lib/core/services/registro_logger.dart`).
- **Ambiente de Testes (`app/test/caos/` e `app/integration_test/`)**:
  - Criação de `receita_crash_robo.dart`, `encolhedor_caminho_crash.dart`, `fabrica_dataset_caos.dart`, `motor_robo_caotico.dart`, seus testes espelhados (`*_test.dart`), `regressao_caminhos_test.dart`, `robo_caotico_exploratorio_test.dart` e `app/integration_test/robo_caotico_dispositivo_test.dart`.
- **CI/CD**:
  - Atualização do `.github/workflows/release_new_app_version.yml` e teste arquitetural correspondente.
