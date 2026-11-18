# Proposal

## Why

Atualmente, falhas de autenticação OIDC (como HTTP 400 `provider_disabled` no login da Apple) e erros operacionais capturados em blocos `try/catch` de ViewModels e telas são engolidos silenciosamente sem envio ao Sentry/Crashlytics — agravados pelo fato de `RegistroLogger.isFalhaConexaoOuTimeout` classificar qualquer `HttpException` como perda transitória de sinal na montanha sem inspecionar o código HTTP. Além disso, o `AutenticacaoNuvemService` contém um perigoso fallback de credencial sintética de teste em código de produção (`lib/`), ignora cancelamentos voluntários do modal nativo (`cancelado: true`) e exibe o botão de login da Apple no Android sem suporte nativo.

## What Changes

- **Provedores OIDC por plataforma na tela de identidade**: Exibir exclusivamente **Continuar com o Google** no Android (`CredentialManager`) e ambos (**Continuar com o Google** e **Continuar com a Apple**) no iOS (`ASAuthorizationAppleIDProvider`), eliminando fluxos OAuth Web e chaves `.p8` com expiração semestral.
- **BREAKING (Interno): Remoção integral do fallback de conta/token de teste em `lib/`**: Remover `construirIdTokenOidcComNonce` e o retorno de `CredencialOidcBruta` sintética (`usr_*_padrao` / `escalador@privaterelay.appleid.com`) de `AutenticacaoNuvemService`, movendo utilitários de token sintético exclusivamente para `app/test/` (biblioteca Fake determinística).
- **Tratamento explícito de cancelamento e metadados nativos OIDC**: Reconhecer `cancelado == true` retornado pelos canais nativos Android/iOS sem disparar chamada HTTP vazia ao Supabase nem registrar erro no Sentry, ler `nomeCompleto` ou `nomeExibicao` retornados pelo Android/iOS e lançar exceção tipada com `statusCode` (`ExcecaoAutenticacaoOidc`) em falhas HTTP do GoTrue.
- **Classificação inteligente de códigos HTTP no `RegistroLogger`**: Refinar `RegistroLogger.isFalhaConexaoOuTimeout` para inspecionar códigos de status HTTP em exceções tipadas e em `HttpException` — fazendo downgrade para `logAviso` apenas em códigos transitórios (`408`, `429`, `502`, `503`, `504`) ou falhas puras de socket/transporte sem status HTTP, e mantendo erros definitivos (`400`, `401`, `403`, `404`, `422`, `500`, etc.) como erros reportados ao Sentry e Crashlytics.
- **Eliminação de `try/catch` mudos e higienização de mensagens de UI**: Capturar `(e, stackTrace)` e reportar ao `RegistroLogger` nos fluxos operacionais de `IdentityFormViewModel`, `AutenticacaoNuvemService`, `GenerationNotifier`, `HistoryScreen`, `VisualizadorRelatorioScreen` e `SincronizadorNuvemService`, apresentando mensagens amigáveis localizadas na interface em vez de despejar payloads JSON/URLs técnicas.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capacidade introduzida; evolução das capacidades existentes abaixo. -->

### Modified Capabilities
- `autenticacao-oidc-openpubkey`: Restrição de provedores OIDC por plataforma (Google no Android; Google e Apple no iOS), proibição de fallback sintético em produção, tratamento silencioso de cancelamento pelo usuário e exceções tipadas com código de status HTTP.
- `observabilidade-dual-logger`: Inspeção de códigos de status HTTP antes de rebaixar `HttpException`/exceções de API para aviso offline e obrigatoriedade de registro com `StackTrace` em blocos `try/catch` de fluxos operacionais da UI/ViewModels.

## Impact

- **Código de produção (`app/lib/`)**:
  - `app/lib/core/services/autenticacao_nuvem_service.dart`
  - `app/lib/core/services/registro_logger.dart`
  - `app/lib/core/services/sincronizador_nuvem_service.dart`
  - `app/lib/features/identity/viewmodels/identity_form_view_model.dart`
  - `app/lib/features/identity/views/identity_setup_screen.dart`
  - `app/lib/features/pdf_generation/providers/generation_provider.dart`
  - `app/lib/features/pdf_generation/views/visualizador_relatorio_screen.dart`
  - `app/lib/features/home/views/history_screen.dart`
- **Testes e Fakes (`app/test/`)**:
  - `app/test/core/services/autenticacao_nuvem_service_fake.dart` e `autenticacao_nuvem_service_fake_test.dart`
  - `app/test/core/services/autenticacao_nuvem_service_test.dart`
  - `app/test/core/services/registro_logger_test.dart`
  - Testes espelhados dos ViewModels e telas afetados mantendo 100% de cobertura comportamental.
