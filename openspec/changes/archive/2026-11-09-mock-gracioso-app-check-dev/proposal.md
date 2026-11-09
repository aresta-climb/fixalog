# Proposal: Mock Gracioso de App Check em Desenvolvimento para Upload e Feedback

## Why

Em builds locais de desenvolvimento (`--debug`, `--profile` ou `--dart-define=RELEASE_LOCAL=true`, onde `kModoDesenvolvimento == true`), o `DebugAppCheckProvider` gera um UUID local que só emite JWTs válidos após ser registrado manualmente no Console do Firebase. Quando esse UUID não está cadastrado (ex.: emuladores recém-criados, dispositivos de contribuidores externos ou execuções locais sem acesso ao painel do Firebase), a chamada `ServicoAppCheck.obterToken()` falha com `403 App attestation failed`, disparando um falso erro (`logError`) para o Sentry e para o Firebase Crashlytics, enquanto o `SincronizadorNuvemService` e o `ServicoFilaFeedback` tentam enviar requisições HTTP reais sem um JWT válido do App Check — ao contrário do `../aresta_app`, que realiza um *Mock Gracioso* local (`📝 [DEBUG MOCK]`).

## What Changes

- **Degradação silenciosa com `logAviso` em `ServicoAppCheck.obterToken()` em modo de desenvolvimento (`app/lib/core/services/servico_app_check.dart`)**:
  - Quando o aplicativo estiver em modo de desenvolvimento (`emModoDesenvolvimento`, cujo padrão é `kModoDesenvolvimento`) ou a falha na obtenção do token for decorrente de atestação não registrada no `DebugAppCheckProvider` (`403` / `App attestation failed`) fora de release oficial, registrar apenas um aviso contextual (`_logger.logAviso`) em vez de `_logger.logError`, evitando falsos positivos no Sentry/Crashlytics e no oráculo do Robô Caótico.
- **Identificação explícita de token de fallback local em `AutenticacaoNuvemService` (`app/lib/core/services/autenticacao_nuvem_service.dart`)**:
  - Expor a constante `AutenticacaoNuvemService.tokenAppCheckFallbackLocal = 'app_check_token_fixalog_padrao'` e o utilitário `AutenticacaoNuvemService.possuiTokenAppCheckReal(String? token)` (retornando `false` quando o token for `null`, vazio ou igual a `tokenAppCheckFallbackLocal`), permitindo que os serviços de sincronização e feedback distingam um JWT real emitido pelo Firebase (quando o UUID de debug está registrado no console ou em produção) da ausência de App Check em desenvolvimento.
- **Mock Gracioso de Upload e Publicação em `SincronizadorNuvemService` (`app/lib/core/services/sincronizador_nuvem_service.dart`)**:
  - Em modo de desenvolvimento (`emModoDesenvolvimento = kModoDesenvolvimento`), quando `!AutenticacaoNuvemService.possuiTokenAppCheckReal(tokenAppCheck)`:
    - Em `_executarEnvioSubmissao`: não realizar chamadas HTTP para `https://fixalog.app`; registrar `📝 [DEBUG MOCK] Upload de laudo concluído localmente (App Check não registrado em dev): <idSessao>` via `_logger.logInfo`, marcar `record.enviadoNuvem = true` no SQLite e emitir `ProgressoPublicacaoLaudo` com `EtapaPublicacaoLaudo.concluidoAtivo`.
    - Em `publicarEAguardarLiberacao`: caso o laudo ainda não esteja marcado como enviado, executar `enviarSubmissao(registro)` (que aplica o mock local) e retornar imediatamente `EtapaPublicacaoLaudo.concluidoAtivo`, liberando o compartilhamento em ambiente de desenvolvimento sem travar no polling remoto.
    - Em `restaurarRelatoriosDaConta`: registrar `📝 [DEBUG MOCK] Restauração de relatórios ignorada localmente (App Check não registrado em dev)` e retornar `0` sem realizar chamadas HTTP.
- **Mock Gracioso de Feedback em `ServicoFilaFeedback` (`app/lib/features/feedback/services/servico_fila_feedback.dart`)**:
  - Em modo de desenvolvimento (`emModoDesenvolvimento = kModoDesenvolvimento`), quando `!AutenticacaoNuvemService.possuiTokenAppCheckReal(tokenAppCheck)`, não enviar requisição HTTP para a Edge Function `app-feedback` (que rejeitaria o token de fallback com HTTP 403); registrar `📝 [DEBUG MOCK] Feedback concluído localmente (App Check não registrado em dev): <idFeedback>` via `_logger.logInfo` e retornar `true` para concluir o item na fila SQLite e limpar o screenshot temporário, espelhando exatamente o comportamento do `../aresta_app`.

## Capabilities

### New Capabilities

### Modified Capabilities
- `observabilidade-dual-logger`: Atualiza o requisito de `Atestação de Integridade via Firebase App Check` para especificar que falhas de atestação em modo de desenvolvimento (`kModoDesenvolvimento`) devem ser registradas como aviso (`logAviso`) sem emitir erro ao Sentry/Crashlytics.
- `sincronizacao-nuvem-laudos`: Atualiza os requisitos de sincronização em segundo plano, restauração e compartilhamento para realizar *Mock Gracioso* local quando em modo de desenvolvimento sem token real do App Check registrado.
- `canal-feedback-offline`: Atualiza o requisito de despacho em segundo plano para realizar *Mock Gracioso* local quando em modo de desenvolvimento sem token real do App Check registrado.

## Impact

- **Core Services (`app/lib/core/services/servico_app_check.dart`, `app/lib/core/services/autenticacao_nuvem_service.dart`, `app/lib/core/services/sincronizador_nuvem_service.dart`)**: Tratamento de aviso em desenvolvimento no `ServicoAppCheck`, helper `possuiTokenAppCheckReal` e *Mock Gracioso* de upload/publicação/restauração no `SincronizadorNuvemService`.
- **Feedback Service (`app/lib/features/feedback/services/servico_fila_feedback.dart`)**: *Mock Gracioso* de despacho de feedback em desenvolvimento sem token real do App Check.
- **Testes Unitários (`app/test/core/services/servico_app_check_test.dart`, `app/test/core/services/autenticacao_nuvem_service_test.dart`, `app/test/core/services/sincronizador_nuvem_service_test.dart`, `app/test/features/feedback/services/servico_fila_feedback_test.dart`)**: Novos cenários de teste comportamental garantindo 100% de cobertura (Princípios III e IV do `AGENTS.md`).
