# Tasks

## 1. Classificação de Códigos HTTP no `RegistroLogger`

- [x] 1.1 Escrever testes orientados a comportamento (*Red*) em `app/test/core/services/registro_logger_test.dart` validando que `isFalhaConexaoOuTimeout` e `logFalhaSyncOuDownload` rebaixam para `logAviso` apenas falhas puras de transporte (`SocketException`, `TimeoutException`, `HttpException` sem status HTTP) e códigos HTTP transitórios (`408, 429, 502, 503, 504`), enquanto enviam erros HTTP definitivos (`400 provider_disabled`, `401`, `403`, `404`, `422`, `500` — tanto em exceções tipadas quanto em `HttpException`) como erro real para o Sentry e Crashlytics, verificando a falha inicial com `flutter test test/core/services/registro_logger_test.dart`.
- [x] 1.2 Implementar a inspeção de códigos HTTP em `app/lib/core/services/registro_logger.dart` (*Green* + *Refactor* com docstrings em PT-BR) e confirmar 100% de cobertura em `flutter test --coverage test/core/services/registro_logger_test.dart`.

## 2. Remoção do Fallback Sintético e Exceções Tipadas no `AutenticacaoNuvemService`

- [x] 2.1 Mover a construção de `id_token` OIDC sintético (`construirIdTokenOidcComNonce`) para a biblioteca de testes `app/test/core/services/autenticacao_nuvem_service_fake.dart`, adicionar suporte a simulação determinística de `ExcecaoAutenticacaoCancelada` e `ExcecaoAutenticacaoOidc` no Fake e atualizar `app/test/core/services/autenticacao_nuvem_service_fake_test.dart`, verificando com `flutter test test/core/services/autenticacao_nuvem_service_fake_test.dart`.
- [x] 2.2 Escrever testes (*Red*) em `app/test/core/services/autenticacao_nuvem_service_test.dart` validando: (a) remoção total de sessão sintética quando o canal nativo retorna `null`, `idToken` vazio ou `MissingPluginException`/`PlatformException`; (b) lançamento de `ExcecaoAutenticacaoCancelada` quando `cancelado == true` sem invocar HTTP no Supabase; (c) leitura de `nomeExibicao` além de `nomeCompleto`; e (d) lançamento de `ExcecaoAutenticacaoOidc` com `statusCode` e `codigoErroServidor` em respostas HTTP não-2xx do GoTrue.
- [x] 2.3 Implementar `ExcecaoAutenticacaoCancelada`, `ExcecaoAutenticacaoOidc` e a remoção integral do fallback de teste em `app/lib/core/services/autenticacao_nuvem_service.dart` (*Green* + *Refactor*), confirmando 100% de cobertura em `flutter test --coverage test/core/services/autenticacao_nuvem_service_test.dart`.

## 3. Botões OIDC por Plataforma e Observabilidade em Identidade (`IdentityFormViewModel` e `IdentitySetupScreen`)

- [x] 3.1 Atualizar e expandir os testes (*Red*) em `app/test/features/identity/viewmodels/identity_form_view_model_test.dart` e `app/test/features/identity/views/identity_setup_screen_test.dart` verificando: (a) em `TargetPlatform.android` apenas `botao_login_google` é exibido; (b) em `TargetPlatform.iOS` ambos `botao_login_google` e `botao_login_apple` são exibidos; (c) cancelamento pelo usuário (`ExcecaoAutenticacaoCancelada`) encerra `isLoading` sem `SnackBar` e sem chamar `logError`; e (d) falhas OIDC/HTTP definitivas e falhas em `submitIdentity` invocam `RegistroLogger.logError` com `StackTrace` e exibem mensagem amigável sem despejar JSON/URI crua.
- [x] 3.2 Implementar as melhorias em `app/lib/features/identity/viewmodels/identity_form_view_model.dart`, `app/lib/features/identity/views/identity_setup_screen.dart` e chaves de localização correspondentes nos 7 arquivos `.arb` (`flutter gen-l10n`), validando 100% de cobertura nos testes de identidade.

## 4. Eliminação de `try/catch` Mudos nos Fluxos de Relatórios, Histórico e Sincronização

- [x] 4.1 Escrever testes (*Red*) em `app/test/features/pdf_generation/providers/generation_provider_test.dart`, `app/test/features/pdf_generation/views/visualizador_relatorio_screen_test.dart`, `app/test/features/home/views/history_screen_test.dart` e `app/test/core/services/sincronizador_nuvem_service_test.dart` garantindo que exceções capturadas nesses fluxos registram o erro com `StackTrace` no `RegistroLogger` (usando `RegistroLoggerFake`).
- [x] 4.2 Implementar o encaminhamento `catch (e, stackTrace)` ao `RegistroLogger` em `generation_provider.dart`, `visualizador_relatorio_screen.dart`, `history_screen.dart` e `sincronizador_nuvem_service.dart` (*Green* + *Refactor*), verificando a aprovação e 100% de cobertura nos respectivos testes espelhados.

## 5. Verificação de Integração e Conformidade Arquitetural

- [x] 5.1 Executar `flutter analyze`, `test_structure_mirror_test.dart` e a suíte completa `flutter test --coverage` em `app/`, confirmando zero avisos estáticos, espelhamento 1:1 intacto e 100% de cobertura comportamental.
