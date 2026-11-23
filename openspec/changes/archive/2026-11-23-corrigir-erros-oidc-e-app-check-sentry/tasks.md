# Tasks

## 1. Internacionalização e Severidade do Logger Central

- [x] 1.1 Adicionar a chave `identidadeErroSemContaDispositivoOidc` nos 7 dicionários `app/lib/core/l10n/arb/app_*.arb` (`pt`, `en`, `es`, `fr`, `de`, `ar`, `ja`), executar `flutter gen-l10n` em `app/` e verificar nos testes de localização que todos os 7 idiomas geram a mensagem esperada.
- [x] 1.2 Escrever teste orientado a comportamento (*Red*) em `app/test/core/services/registro_logger_test.dart` verificando que `logFalhaSyncOuDownload` registra falhas definitivas via `logError` (`fatal: false` no Sentry, no Crashlytics e em `aoRegistrarErroOuCrash`) e rebaixa desconexões para `logAviso`; implementar a mudança (*Green*) em `app/lib/core/services/registro_logger.dart` e confirmar 100% de cobertura em `registro_logger.dart`.

## 2. Canal Nativo OIDC Estruturado e Remoção do Fallback Provisório de App Check

- [x] 2.1 Atualizar `app/android/app/src/main/kotlin/com/arestaclimb/fixalog/MainActivity.kt` e `app/ios/Runner/AppDelegate.swift` para retornar diagnóstico estruturado (`erroCodigo` e `erroMensagem`), tratar `NoCredentialException` no Android como `erroCodigo: "sem_credencial_dispositivo"` e tratar `ASWebAuthenticationSessionError.canceledLogin` no Google iOS como `cancelado: true`, validando sintaxe e compilação limpa.
- [x] 2.2 Atualizar a biblioteca de testes `app/test/core/services/autenticacao_nuvem_service_fake.dart` e seu teste espelhado `app/test/core/services/autenticacao_nuvem_service_fake_test.dart` para suportar `Future<String?> obterTokenAppCheck()` (incluindo `null`) e simulação de `semCredencialDispositivo: true` em `ExcecaoAutenticacaoOidc`, verificando 100% de aprovação em `flutter test test/core/services/autenticacao_nuvem_service_fake_test.dart`.
- [x] 2.3 Escrever testes (*Red*) em `app/test/core/services/autenticacao_nuvem_service_test.dart` e `app/test/features/identity/viewmodels/identity_form_view_model_test.dart` validando: (a) remoção de `tokenAppCheckFallbackLocal` e retorno `null` em `obterTokenAppCheck()` quando `ServicoAppCheck` retorna `null`; (b) propagação de `codigoErroNativo` e `semCredencialDispositivo: true` em `ExcecaoAutenticacaoOidc`; e (c) registro exclusivo de `logAviso` (zero `logError`) e exibição de `identidadeErroSemContaDispositivoOidc` em `IdentityFormViewModel.autenticarComProvedor` quando `semCredencialDispositivo` for `true`.
- [x] 2.4 Implementar as alterações (*Green* + *Refactor*) em `app/lib/core/services/autenticacao_nuvem_service.dart` e `app/lib/features/identity/viewmodels/identity_form_view_model.dart`, verificando 100% de cobertura comportamental em ambos os arquivos.

## 3. Proteção de App Check em Produção e Teto de Backoff em Segundo Plano

- [x] 3.1 Escrever testes (*Red*) em `app/test/features/feedback/services/servico_fila_feedback_test.dart` validando que, em produção (`emModoDesenvolvimento: false`), quando `obterTokenAppCheck()` retorna `null` ou vazio, nenhuma requisição HTTP é disparada, apenas `logAviso` é emitido (zero erros no Sentry) e o item permanece pendente no SQLite; implementar (*Green*) em `app/lib/features/feedback/services/servico_fila_feedback.dart` mantendo 100% de cobertura.
- [x] 3.2 Escrever testes (*Red*) em `app/test/core/services/sincronizador_nuvem_service_test.dart` validando que `enviarSubmissao`, `publicarEAguardarLiberacao` e `restaurarRelatoriosDaConta` suspendem chamadas HTTP com `logAviso` (sem erro no Sentry) quando `emModoDesenvolvimento: false` e `obterTokenAppCheck()` retorna `null`; implementar (*Green*) em `app/lib/core/services/sincronizador_nuvem_service.dart` mantendo 100% de cobertura.
- [x] 3.3 Escrever testes (*Red*) em `app/test/core/services/agendador_sincronizacao_background_test.dart` validando que o agendador consome os intervalos de *backoff* (`30s -> 60s -> 120s`) uma única vez, desliga `timerAtivo` ao esgotar a sequência e reinicia `indiceBackoffAtual = 0` ao chamar `aoRetomarAplicativo()` ou `iniciarMonitoramento()`; implementar (*Green*) em `app/lib/core/services/agendador_sincronizacao_background.dart` mantendo 100% de cobertura.

## 4. Verificação Integral de Qualidade e Cobertura

- [x] 4.1 Executar `flutter analyze --fatal-infos --fatal-warnings`, a suíte completa `flutter test --coverage` em `app/` (incluindo `test_structure_mirror_test.dart`) e verificar 100% de cobertura de linhas em todos os módulos Dart alterados.
