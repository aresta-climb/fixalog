# Design: Telemetria e Breadcrumbs Transversais no Aplicativo Completo

## Context

Conforme identificado na exploração (`proposal.md`), o `fixalog` já possui `ServicoTelemetria` e `RegistroLogger` em `app/lib/core/services/`, mas nenhuma tela, controller ou serviço em `app/lib/features/` invoca o `ServicoTelemetria`. Além disso, ao contrário do `../aresta_app`:
1. Os callbacks padrão de `RegistroLogger` (`FirebaseCrashlytics.instance`) e `ServicoTelemetria` (`FirebaseAnalytics.instance`) não verificam `RegistroLogger.firebaseInicializado`, lançando `[core/no-app]` quando acionados em `flutter test` ou durante campanhas do Robô Caótico.
2. O `fixalog` não possui o `GravadorBreadcrumbs` (buffer circular em memória das últimas 50 ações) integrado ao `ServicoTelemetria` e ao `ServicoFilaFeedback`.

## Goals / Non-Goals

**Goals:**
- Garantir que toda ação relevante de navegação e domínio no `FixalogApp` emita um evento no `ServicoTelemetria`, que simultaneamente:
  1. Registra a entrada no `GravadorBreadcrumbs.instancia` (buffer FIFO de 50 eventos);
  2. Registra um breadcrumb via `RegistroLogger.logInfo` (imprimindo no terminal e enviando `Breadcrumb` ao Sentry e log ao Crashlytics);
  3. Envia o evento analítico ao `FirebaseAnalytics` quando inicializado.
- Proteger `RegistroLogger` e `ServicoTelemetria` para nunca chamarem canais nativos do Firebase quando `RegistroLogger.firebaseInicializado` for `false` (ou `Sentry` quando `!Sentry.isEnabled`).
- Incluir os `breadcrumbs` acumulados no `metadadosJson` do `ServicoFilaFeedback`.
- Manter 100% de cobertura de testes unitários e de widget (Princípios III e IV do `AGENTS.md`) e espelhamento 1:1.

**Non-Goals:**
- Não introduzir novas dependências externas no `pubspec.yaml`.
- Não enviar dados pessoais sensíveis (PII) nos parâmetros de telemetria ou breadcrumbs.

## Decisions

### 1. Arquitetura Unificada: `ServicoTelemetria` -> `GravadorBreadcrumbs` + `RegistroLogger` + `FirebaseAnalytics`
- **Decisão**: Centralizar toda a instrumentação de ações de usuário no `ServicoTelemetria`. Dentro de `ServicoTelemetria.registrarEvento(nome, {parametros})`:
  1. Enriquecer automaticamente com `tier_dispositivo` e `ram_gb` quando `parametros` contiver `duracao_ms`;
  2. Chamar `_gravadorBreadcrumbs.registrar(evento: nome, parametros: parametrosEnriquecidos)`;
  3. Chamar `_logger.logInfo('📈 [ServicoTelemetria] Evento: $nome | Parâmetros: $parametrosEnriquecidos')`;
  4. Chamar `_enviarEventoAnalytics(nome, parametrosEnriquecidos)`.
- **Alternativa considerada**: Espalhar chamadas separadas a `RegistroLogger.logInfo`, `GravadorBreadcrumbs.registrar` e `ServicoTelemetria` em cada widget. Descartada por gerar triplicação e risco de esquecimento, enquanto a centralização no `ServicoTelemetria` replica exatamente o padrão comprovado do `../aresta_app`.

### 2. Guarda de Inicialização Nativa nos Callbacks Padrão
- **Decisão**:
  - Em `RegistroLogger`:
    - `_enviarLogCrashlyticsPadrao`: só chama `FirebaseCrashlytics.instance.log(mensagem)` se `firebaseInicializado` for `true`.
    - `_enviarErroCrashlyticsPadrao`: só chama `FirebaseCrashlytics.instance.recordError(...)` se `firebaseInicializado` for `true`.
    - `_enviarBreadcrumbSentryPadrao`: só chama `Sentry.addBreadcrumb(breadcrumb)` se `Sentry.isEnabled` for `true`.
    - `_enviarExcecaoSentryPadrao`: só chama `Sentry.captureException(...)` se `Sentry.isEnabled` for `true`.
  - Em `ServicoTelemetria`:
    - `_configurarColetaPadrao`: só chama `FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(...)` se `RegistroLogger.firebaseInicializado` for `true`.
    - `_enviarEventoPadrao`: só chama `FirebaseAnalytics.instance.logEvent(...)` se `RegistroLogger.firebaseInicializado` for `true`.
  - Nos testes unitários de `registro_logger_test.dart` e `servico_telemetria_test.dart`, os callbacks injetados via construtor continuam sendo chamados diretamente, preservando 100% de testabilidade determinística sem depender de estado global do Firebase.

### 3. Pontos de Instrumentação no Aplicativo Completo
- **`HomeScreen`**: Ao trocar de aba no `_FixalogBottomBar`, chamar `ServicoTelemetria.instancia.registrarNavegacaoAba(nomeAba)`.
- **`NewProtocolScreen` e `WizardStateController`**:
  - `loadProtocol`: `registrarInicioProtocolo(protocol.id, idioma: ..., modo: 'novo')`.
  - `loadExistingSession`: `registrarInicioProtocolo(protocol.id, idioma: ..., modo: 'edicao')`.
  - `nextStep` / `previousStep`: `registrarEtapaWizard(acao: 'avancar_etapa' | 'voltar_etapa', idProtocolo: ..., stepId: ..., indice: ...)`.
  - `chooseRamo`: `registrarEscolhaRamoWizard(idProtocolo: ..., conteudoId: ..., opcao: ...)`.
  - `addListItem` / `removeListItem` / `toggleExpandListItem`: `registrarAcaoListaWizard(acao: ..., conteudoId: ..., tipoId: ...)`.
  - `adicionarMidiaEmBackground` / `removerMidia` / captura GPS em `WizardScreen`: `registrarAcaoMidiaWizard(acao: ..., tipoMidia: ...)`.
- **`GenerationNotifier`**: Medir `Stopwatch` durante `generateReport` e chamar `registrarGeracaoLaudoEpub(idProtocolo: ..., duracaoMs: ..., assinado: ...)`.
- **`HistoryScreen`**: Ao abrir relatório, editar rascunho, excluir registro ou alternar filtro Vias/Materiais, chamar `registrarAcaoHistorico(acao: ..., idProtocolo: ...)`.
- **`VisualizadorRelatorioScreen`**: Ao compartilhar link web, exportar EPUB, abrir arquivo externo ou iniciar publicação na nuvem, chamar `registrarAcaoVisualizadorRelatorio(acao: ...)`.
- **`TelaTermosDeUso`, `IdentityFormViewModel`, `TelaConfiguracoes`, `SincronizadorNuvemService`, `ServicoFilaFeedback`**:
  - `registrarAceiteTermosUso(versaoLegal)`
  - `registrarSalvarIdentidade(possuiClube: ...)`
  - `registrarAcaoConfiguracoes(acao, {detalhe})` e `registrarAberturaLinkExterno(url, origem: 'configuracoes')`
  - `registrarSincronizacaoNuvem(enviados: ..., falhas: ...)`
  - `registrarAcaoFeedback(acao, {categoria})` e inclusão de `'breadcrumbs': _gravadorBreadcrumbs.obterBreadcrumbs()` no `metadados` do `ServicoFilaFeedback`.

## Risks / Trade-offs

- **[Risco] Ruído excessivo em digitação caractere a caractere no Wizard** → **Mitigação**: Não disparar telemetria a cada tecla digitada em `setAnswer` de campo de texto; registrar eventos nas transições estruturais (início de protocolo, avanço/volta de etapa, escolha de ramo, adição/remoção de item de lista, anexo de mídia/GPS e geração de relatório).
- **[Risco] Cobertura de testes de 100% nos arquivos modificados** → **Mitigação**: Manter defaults nos parâmetros opcionais e exercitar todos os novos métodos de `ServicoTelemetria` e `GravadorBreadcrumbs` em seus respectivos arquivos `*_test.dart`.
