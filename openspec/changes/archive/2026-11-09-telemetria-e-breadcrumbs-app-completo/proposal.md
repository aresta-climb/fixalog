# Proposal: Telemetria e Breadcrumbs Transversais no Aplicativo Completo

## Why

Atualmente o `ServicoTelemetria` e o `RegistroLogger` existem em `app/lib/core/services/`, mas não estão conectados às telas, controllers e providers de funcionalidades (`app/lib/features/`). Como consequência, a navegação do usuário (e do Robô Caótico) não emite breadcrumbs no terminal, no Sentry ou no Firebase Crashlytics, nem alimenta um buffer circular de histórico (`GravadorBreadcrumbs`) para enriquecer os relatos de feedback offline enviados ao GitHub, além de `ServicoTelemetria` e `RegistroLogger` invocarem canais nativos do Firebase sem checar se o SDK foi inicializado.

## What Changes

- **Criação do `GravadorBreadcrumbs` (`app/lib/core/services/gravador_breadcrumbs.dart`)**: Buffer circular FIFO em memória (capacidade padrão de 50 eventos) que registra cronologicamente cada evento disparado pelo `ServicoTelemetria` com timestamp UTC e parâmetros, nos moldes do `../aresta_app`.
- **Proteção de Inicialização Nativa no `RegistroLogger` e `ServicoTelemetria`**:
  - O `RegistroLogger` passa a verificar `firebaseInicializado` e `Sentry.isEnabled` nos callbacks padrão antes de acionar `FirebaseCrashlytics.instance` ou `Sentry`, evitando exceções espúrias `[core/no-app]` no terminal durante `flutter test` e campanhas do Robô Caótico.
  - O `ServicoTelemetria` passa a registrar automaticamente todo evento no `GravadorBreadcrumbs.instancia`, emitir o log/breadcrumb via `RegistroLogger.logInfo` (imprimindo no terminal e enviando breadcrumb ao Sentry/Crashlytics) e só invocar `FirebaseAnalytics.instance` quando `RegistroLogger.firebaseInicializado` for `true`.
- **Expansão do Catálogo de Eventos do `ServicoTelemetria` e Instrumentação do App Inteiro**:
  - **Navegação Principal (`HomeScreen`)**: `registrarNavegacaoAba` (`novo_protocolo`, `historico`, `configuracoes`).
  - **Seleção e Preenchimento do Wizard (`NewProtocolScreen`, `WizardScreen`, `WizardStateController`)**: `registrarInicioProtocolo`, `registrarEtapaWizard` (`avancar_etapa`, `voltar_etapa`, `ir_para_resumo`), `registrarEscolhaRamoWizard`, `registrarAcaoListaWizard` (`adicionar_item`, `remover_item`, `expandir_item`) e `registrarAcaoMidiaWizard` (`foto`, `video`, `documento_pdf`, `gps`).
  - **Geração de Laudo EPUB 3, Histórico e Visualizador (`GenerationNotifier`, `HistoryScreen`, `VisualizadorRelatorioScreen`)**: `registrarGeracaoLaudoEpub`, `registrarAcaoHistorico` (`abrir_relatorio`, `editar_rascunho`, `excluir_registro`, `filtrar_materiais`) e `registrarAcaoVisualizadorRelatorio` (`compartilhar_link_web`, `exportar_epub`, `abrir_externo`, `publicar_nuvem`).
  - **Onboarding, Identidade, Configurações, Sync e Feedback (`TelaTermosDeUso`, `IdentityFormViewModel`, `TelaConfiguracoes`, `SincronizadorNuvemService`, `ServicoFilaFeedback`)**: `registrarAceiteTermosUso`, `registrarSalvarIdentidade`, `registrarAcaoConfiguracoes` (troca de idioma, login/logout OIDC, abrir termos, editar identidade), `registrarAberturaLinkExterno`, `registrarSincronizacaoNuvem` e `registrarAcaoFeedback`.
- **Enriquecimento do `ServicoFilaFeedback` com Breadcrumbs**: O `metadadosJson` persistido na tabela `fila_feedback` passa a incluir a lista `breadcrumbs` obtida de `GravadorBreadcrumbs.instancia.obterBreadcrumbs()`.

## Capabilities

### New Capabilities
- `telemetria-e-breadcrumbs-app`: Instrumentação transversal de telemetria e breadcrumbs em todas as jornadas do aplicativo (navegação de abas, protocolos do wizard, listas repetíveis, captura de mídia/GPS, geração de laudos EPUB 3, histórico, visualizador, onboarding, identidade, configurações e sincronização) integrada ao `GravadorBreadcrumbs`.

### Modified Capabilities
- `observabilidade-dual-logger`: Verificação de inicialização nativa (`firebaseInicializado` e `Sentry.isEnabled`) nos callbacks padrão do `RegistroLogger` e `ServicoTelemetria` para operação limpa em testes automatizados, modo offline e Robô Caótico.
- `canal-feedback-offline`: Inclusão automática do histórico circular de ações recentes (`breadcrumbs` do `GravadorBreadcrumbs`) nos metadados do `FeedbackRecord` enfileirado pelo `ServicoFilaFeedback`.

## Impact

- **Serviços Core (`app/lib/core/services/`)**: `gravador_breadcrumbs.dart` (novo), `servico_telemetria.dart` e `registro_logger.dart`.
- **Features Instrumentadas (`app/lib/features/`)**: `home_screen.dart`, `new_protocol_screen.dart`, `history_screen.dart`, `wizard_screen.dart`, `wizard_state_controller.dart`, `generation_provider.dart`, `visualizador_relatorio_screen.dart`, `tela_configuracoes.dart`, `identity_form_view_model.dart`, `tela_termos_de_uso.dart`, `servico_fila_feedback.dart` e `sincronizador_nuvem_service.dart`.
- **Testes (`app/test/`)**: Novos testes espelhados 1:1 (`gravador_breadcrumbs_test.dart`) e atualização dos testes unitários/widgets para validar a emissão de breadcrumbs e 100% de cobertura.
