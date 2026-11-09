# Tasks: Mock Gracioso de App Check em Desenvolvimento para Upload e Feedback

## 1. Degradação com `logAviso` no `ServicoAppCheck` e Identificação de Token Real no `AutenticacaoNuvemService`

- [x] 1.1 Atualizar `app/test/core/services/servico_app_check_test.dart` (Red) e `app/lib/core/services/servico_app_check.dart` (Green) para adicionar `emModoDesenvolvimento` (padrão `kModoDesenvolvimento`) e registrar `logAviso` quando `obterToken` falhar em modo de desenvolvimento (mantendo `logError` apenas quando `emModoDesenvolvimento == false` e não for falha de rede), verificando 100% de cobertura com `flutter test --coverage test/core/services/servico_app_check_test.dart`
- [x] 1.2 Atualizar `app/test/core/services/autenticacao_nuvem_service_test.dart` (Red) e `app/lib/core/services/autenticacao_nuvem_service.dart` (Green) para adicionar `tokenAppCheckFallbackLocal` e `possuiTokenAppCheckReal(String? token)`, verificando 100% de cobertura com `flutter test --coverage test/core/services/autenticacao_nuvem_service_test.dart`

## 2. Mock Gracioso no `SincronizadorNuvemService` e no `ServicoFilaFeedback`

- [x] 2.1 Atualizar `app/test/core/services/sincronizador_nuvem_service_test.dart` (Red) e `app/lib/core/services/sincronizador_nuvem_service.dart` (Green) para realizar o mock gracioso (`📝 [DEBUG MOCK]`) em `_executarEnvioSubmissao`, `publicarEAguardarLiberacao` e `restaurarRelatoriosDaConta` quando `emModoDesenvolvimento` for `true` e `!AutenticacaoNuvemService.possuiTokenAppCheckReal(tokenAppCheck)`, verificando 100% de cobertura com `flutter test --coverage test/core/services/sincronizador_nuvem_service_test.dart`
- [x] 2.2 Atualizar `app/test/features/feedback/services/servico_fila_feedback_test.dart` (Red) e `app/lib/features/feedback/services/servico_fila_feedback.dart` (Green) para realizar o mock gracioso (`📝 [DEBUG MOCK]`) em `enviarItemFeedback` quando `emModoDesenvolvimento` for `true` e `!AutenticacaoNuvemService.possuiTokenAppCheckReal(tokenAppCheck)`, verificando 100% de cobertura com `flutter test --coverage test/features/feedback/services/servico_fila_feedback_test.dart`

## 3. Validação Integrada e Qualidade Arquitetural

- [x] 3.1 Executar `flutter analyze` e a suíte de testes dos serviços afetados e de arquitetura (`flutter test test/core/services/ test/features/feedback/ test/architecture/`), garantindo zero avisos de lint e 100% de aprovação
