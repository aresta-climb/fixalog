# Tasks: Telemetria e Breadcrumbs Transversais no Aplicativo Completo

## 1. Buffer Circular de Breadcrumbs e Proteção de Inicialização Core (`GravadorBreadcrumbs`, `RegistroLogger` e `ServicoTelemetria`)

- [x] 1.1 Escrever testes unitários (Red) em `app/test/core/services/gravador_breadcrumbs_test.dart` e implementar `GravadorBreadcrumbs` em `app/lib/core/services/gravador_breadcrumbs.dart` (buffer circular FIFO de 50 eventos com `registrar`, `obterBreadcrumbs`, `limpar`, `total` e `resetarParaTestes`), verificando 100% de cobertura com `flutter test test/core/services/gravador_breadcrumbs_test.dart`
- [x] 1.2 Proteger os callbacks padrão de `RegistroLogger` (`app/lib/core/services/registro_logger.dart`) com `firebaseInicializado` e `Sentry.isEnabled` e atualizar `app/test/core/services/registro_logger_test.dart`, verificando 100% de cobertura com `flutter test --coverage test/core/services/registro_logger_test.dart`
- [x] 1.3 Integrar `GravadorBreadcrumbs` ao `ServicoTelemetria` (`app/lib/core/services/servico_telemetria.dart`), proteger os callbacks padrão com `RegistroLogger.firebaseInicializado`, adicionar todos os métodos tipados de telemetria (`registrarNavegacaoAba`, `registrarInicioProtocolo`, `registrarEtapaWizard`, `registrarEscolhaRamoWizard`, `registrarAcaoListaWizard`, `registrarAcaoMidiaWizard`, `registrarGeracaoLaudoEpub`, `registrarAcaoHistorico`, `registrarAcaoVisualizadorRelatorio`, `registrarAceiteTermosUso`, `registrarSalvarIdentidade`, `registrarAcaoConfiguracoes`, `registrarAberturaLinkExterno`, `registrarSincronizacaoNuvem`, `registrarAcaoFeedback`) e validar 100% de cobertura em `app/test/core/services/servico_telemetria_test.dart`

## 2. Instrumentação de Navegação Principal e Fluxo do Wizard

- [x] 2.1 Instrumentar a troca de abas na `HomeScreen` (`app/lib/features/home/views/home_screen.dart`) com `ServicoTelemetria.instancia.registrarNavegacaoAba` e atualizar `app/test/features/home/views/home_screen_test.dart`, verificando com `flutter test test/features/home/views/home_screen_test.dart`
- [x] 2.2 Instrumentar `WizardStateController` (`app/lib/features/wizard/controllers/wizard_state_controller.dart`) e `WizardScreen` (`app/lib/features/wizard/views/wizard_screen.dart`) para emitir eventos e breadcrumbs em `loadProtocol`, `loadExistingSession`, `nextStep`, `previousStep`, `chooseRamo`, `addListItem`, `removeListItem`, `toggleExpandListItem`, `adicionarMidiaEmBackground`, `removerMidia` e captura GPS, verificando com `flutter test test/features/wizard/`

## 3. Instrumentação de Geração de Laudo EPUB 3, Histórico e Visualizador

- [x] 3.1 Instrumentar `GenerationNotifier` (`app/lib/features/pdf_generation/providers/generation_provider.dart`) para medir a duração (`duracao_ms`) e emitir `registrarGeracaoLaudoEpub`, verificando com `flutter test test/features/pdf_generation/providers/generation_provider_test.dart`
- [x] 3.2 Instrumentar `HistoryScreen` (`app/lib/features/home/views/history_screen.dart`) e `VisualizadorRelatorioScreen` (`app/lib/features/pdf_generation/views/visualizador_relatorio_screen.dart`) para emitir `registrarAcaoHistorico` e `registrarAcaoVisualizadorRelatorio`, verificando com `flutter test test/features/home/views/history_screen_test.dart test/features/pdf_generation/views/visualizador_relatorio_screen_test.dart`

## 4. Instrumentação de Onboarding, Identidade, Configurações, Sync e Feedback com Breadcrumbs

- [x] 4.1 Instrumentar `TelaTermosDeUso` (`app/lib/features/onboarding/views/tela_termos_de_uso.dart`), `IdentityFormViewModel` (`app/lib/features/identity/viewmodels/identity_form_view_model.dart`), `TelaConfiguracoes` (`app/lib/features/settings/views/tela_configuracoes.dart`) e `SincronizadorNuvemService` (`app/lib/core/services/sincronizador_nuvem_service.dart`), verificando os respectivos testes unitários e de widget
- [x] 4.2 Integrar `GravadorBreadcrumbs.instancia.obterBreadcrumbs()` nos metadados do `ServicoFilaFeedback` (`app/lib/features/feedback/services/servico_fila_feedback.dart`) e emitir `registrarAcaoFeedback`, atualizando `app/test/features/feedback/services/servico_fila_feedback_test.dart` e verificando 100% de cobertura

## 5. Validação Integrada com o Robô Caótico e Qualidade Arquitetural

- [x] 5.1 Executar a suíte do Robô Caótico (`flutter test test/caos/ test/architecture/`) e uma campanha exploratória rápida (`--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=3`) verificando que os breadcrumbs são impressos no terminal em tempo real, o espelhamento 1:1 passa e `flutter analyze` reporta zero avisos
