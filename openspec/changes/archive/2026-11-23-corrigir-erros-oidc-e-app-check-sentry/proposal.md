# Proposal

## Why

Dois chamados abertos em produção na release `0.2.9+28` evidenciaram falhas na fronteira nativa de autenticação OIDC e no despacho autenticado via Firebase App Check:
1. **Issue #9 (`FIXALOG-5`)**: Dispositivos sem conta Google cadastrada no Android (como robôs de *Pre-Launch Report* da Google Play ou aparelhos recém-configurados) disparam `NoCredentialException` no `CredentialManager`; o `MainActivity.kt` engole a exceção retornando `null` (e o `AppDelegate.swift` faz o mesmo no cancelamento do `ASWebAuthenticationSession`), fazendo o aplicativo reportar erro genérico de aplicação no Sentry em vez de exibir orientação amigável na tela sem poluir a observabilidade.
2. **Issue #10 (`FIXALOG-6` e `FIXALOG-7`)**: Quando o `ServicoAppCheck.obterToken()` retorna `null` em compilações de loja (emuladores, *cooldown* de *rate-limit* ou instabilidade de rede), `AutenticacaoNuvemService` devolve um texto fixo legado (`'app_check_token_fixalog_padrao'`), fazendo `ServicoFilaFeedback` (e expondo `SincronizadorNuvemService` ao mesmo risco) enviar um JWS inválido que gera `HTTP 403 Invalid Compact JWS`, classificado indevidamente como **Crash Fatal (`fatal: true`)** por `RegistroLogger.logFalhaSyncOuDownload` e repetido indefinidamente pelo `AgendadorSincronizacaoBackground`.

## What Changes

- **Diagnóstico estruturado e tratamento de ausência de conta no canal nativo OIDC (Android e iOS)**:
  - Atualizar `MainActivity.kt` para distinguir `NoCredentialException` (`erroCodigo: 'sem_credencial_dispositivo'`) de cancelamentos (`GetCredentialCancellationException` -> `cancelado: true`) e demais falhas nativas (propagando `erroCodigo` e `erroMensagem` em vez de `null`).
  - Atualizar `AppDelegate.swift` para reconhecer `ASWebAuthenticationSessionError.canceledLogin` no login Google do iOS como `cancelado: true` e propagar `erroCodigo` e `erroMensagem` em falhas nativas de Apple/Google.
  - Tratar ausência de conta cadastrada no dispositivo (`ExcecaoSemCredencialDispositivoOidc` ou flag equivalente em `ExcecaoAutenticacaoOidc`) em `IdentityFormViewModel` registrando apenas `logAviso` (sem enviar erro ao Sentry/Crashlytics) e exibindo a mensagem localizada `identidadeErroSemContaDispositivoOidc` nos 7 idiomas suportados.
- **Remoção definitiva do fallback provisório de App Check em produção**:
  - **BREAKING** (interno): Remover `AutenticacaoNuvemService.tokenAppCheckFallbackLocal` de `app/lib/` e alterar `AutenticacaoNuvemService.obterTokenAppCheck()` para retornar `Future<String?>` (`null` quando `ServicoAppCheck` não emitir um JWT real), eliminando qualquer envio de texto sintético no cabeçalho `X-Firebase-AppCheck`.
  - Em `ServicoFilaFeedback` e `SincronizadorNuvemService`, quando fora de `kModoDesenvolvimento` e sem token real do App Check (`null` ou vazio), abortar a tentativa de rede silenciosamente com `logAviso`, preservando os itens pendentes localmente no SQLite sem disparar requisições HTTP inválidas.
- **Calibração de severidade em `RegistroLogger.logFalhaSyncOuDownload`**:
  - Alterar o ramo de falhas não-transitórias de `logFalhaSyncOuDownload` de `logCrash` (`fatal: true`) para `logError` (`fatal: false`), mantendo envio completo de `StackTrace` ao Sentry/Crashlytics e notificação ao oráculo do Robô Caótico, porém reservando `fatal: true` para crashes reais não tratados.
- **Teto de retentativas automáticas por ciclo no `AgendadorSincronizacaoBackground`**:
  - Encerrar o agendamento periódico automático na sessão corrente após esgotar a sequência de *backoff* (`30s -> 60s -> 120s`), retomando novas tentativas quando o aplicativo voltar ao primeiro plano (`aoRetomarAplicativo`) ou quando uma nova ação iniciar o monitoramento (`iniciarMonitoramento`).

## Capabilities

### New Capabilities
<!-- Nenhuma nova capacidade introduzida. -->

### Modified Capabilities
- `autenticacao-oidc-openpubkey`: Propagar diagnóstico nativo estruturado em Android/iOS, tratar cancelamento do login Google no iOS como silencioso, tratar ausência de conta Google cadastrada no dispositivo com `logAviso` e mensagem localizada sem abrir erro no Sentry, e retornar `null` em `obterTokenAppCheck()` quando indisponível (removendo o fallback textual provisório).
- `canal-feedback-offline`: Suspender silenciosamente o despacho HTTP em produção quando o token do Firebase App Check estiver ausente (`null`/vazio), mantendo o relato na fila SQLite sem enviar cabeçalho falso nem gerar `HTTP 403`.
- `sincronizacao-nuvem-laudos`: Suspender tentativas HTTP de upload/status/restauração em produção quando o token do Firebase App Check estiver ausente (`null`/vazio) e limitar o ciclo automático do `AgendadorSincronizacaoBackground` ao término da progressão de *backoff* até a próxima retomada do aplicativo.
- `observabilidade-dual-logger`: Registrar falhas definitivas de sincronização capturadas em `logFalhaSyncOuDownload` como erro operacional não-fatal (`logError`, `fatal: false`) em vez de crash fatal (`logCrash`).

## Impact

- **Plataformas Nativas**: `app/android/app/src/main/kotlin/com/arestaclimb/fixalog/MainActivity.kt` e `app/ios/Runner/AppDelegate.swift`.
- **Serviços Core e Features**: `autenticacao_nuvem_service.dart`, `registro_logger.dart`, `agendador_sincronizacao_background.dart`, `sincronizador_nuvem_service.dart`, `servico_fila_feedback.dart` e `identity_form_view_model.dart`.
- **Internacionalização**: Adição de `identidadeErroSemContaDispositivoOidc` nos 7 arquivos `.arb` (`pt`, `en`, `es`, `fr`, `de`, `ar`, `ja`) e regeneração de `app_localizations*.dart`.
- **Testes e Fakes**: Atualização dos testes espelhados 1:1 e de `AutenticacaoNuvemServiceFake` para refletir `Future<String?> obterTokenAppCheck()` e os novos contratos comportamentais com 100% de cobertura.
