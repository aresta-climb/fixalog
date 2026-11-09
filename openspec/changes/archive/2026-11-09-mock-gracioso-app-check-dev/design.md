# Design: Mock Gracioso de App Check em Desenvolvimento para Upload e Feedback

## Context

Conforme detalhado em `proposal.md`, quando o Fixalog roda em builds locais (`kModoDesenvolvimento == true`) em um emulador ou dispositivo cujo UUID de depuração do `DebugAppCheckProvider` não foi registrado no Console do Firebase, a chamada nativa `FirebaseAppCheck.instance.getToken()` lança `Exception: [firebase_app_check/unknown] Error returned from API. code: 403 body: App attestation failed`.

Atualmente:
1. `ServicoAppCheck.obterToken()` trata qualquer exceção fora de `RegistroLogger.isFalhaConexaoOuTimeout(e)` como `_logger.logError(...)`, enviando um falso erro para o Sentry e para o Firebase Crashlytics antes de retornar `null`.
2. `AutenticacaoNuvemService._provedorAppCheckPadrao()` converte o `null` retornado por `ServicoAppCheck.instancia.obterToken()` na string estática `'app_check_token_fixalog_padrao'`.
3. `SincronizadorNuvemService` e `ServicoFilaFeedback` não verificam se o token recebido é o fallback local em modo de desenvolvimento e tentam executar chamadas HTTP reais (o que na Edge Function `app-feedback` resulta em `HTTP 403 Invalid Compact JWS` e retentativas infinitas).

## Goals / Non-Goals

**Goals:**
- Garantir que em aparelhos de desenvolvimento **com** UUID de debug registrado no Console do Firebase (ou em produção `kModoReleaseOficial`), o fluxo continue utilizando os servidores reais normalmente.
- Garantir que em aparelhos de desenvolvimento **sem** UUID de debug registrado no Console do Firebase, `ServicoAppCheck.obterToken()` degrade silenciosamente com `logAviso` (sem disparar `logError` para o Sentry/Crashlytics) e acione o *Mock Gracioso* (`📝 [DEBUG MOCK]`) tanto no `SincronizadorNuvemService` quanto no `ServicoFilaFeedback`.
- Preservar 100% de cobertura comportamental nos testes unitários existentes e novos (Princípios III, IV e V do `AGENTS.md`).

**Non-Goals:**
- Não alterar a validação criptográfica de App Check ou OpenPubkey em produção (`kModoReleaseOficial`) nem nos servidores (`cloudflare/fixalog` e `supabase/functions/app-feedback`).

## Decisions

### 1. Tratamento de Falha de Atestação em `ServicoAppCheck.obterToken()`
- **Decisão**:
  - Adicionar o parâmetro opcional `bool emModoDesenvolvimento = kModoDesenvolvimento` no construtor de `ServicoAppCheck` (ou verificar `emModoDesenvolvimento || RegistroLogger.isFalhaConexaoOuTimeout(e)`).
  - Quando `RegistroLogger.isFalhaConexaoOuTimeout(e)` for verdadeiro, manter o `logAviso` atual de falha de conexão.
  - Quando `emModoDesenvolvimento` for verdadeiro (e não for erro de conexão), registrar `_logger.logAviso('🛡️ [ServicoAppCheck] Token do App Check indisponível em modo de desenvolvimento (UUID de debug não registrado): $e')` e retornar `null`, reservando `_logger.logError` para falhas inesperadas de atestação em modo de produção (`!emModoDesenvolvimento`).
- **Racional**: Em `kModoDesenvolvimento`, a ausência de registro do UUID no Firebase Console é uma condição normal de desenvolvimento local/open-source, nunca um bug de aplicação que deva abrir issue no Sentry/Crashlytics.

### 2. Identificação Determinística de Token Real vs. Fallback Local em `AutenticacaoNuvemService`
- **Decisão**:
  - Declarar `static const String tokenAppCheckFallbackLocal = 'app_check_token_fixalog_padrao';` em `AutenticacaoNuvemService`.
  - Adicionar o método estático puro `static bool possuiTokenAppCheckReal(String? token)` que retorna `token != null && token.trim().isNotEmpty && token.trim() != tokenAppCheckFallbackLocal`.
- **Racional**: Mantém a compatibilidade retroativa da assinatura `Future<String> obterTokenAppCheck()` (que retorna `tokenAppCheckFallbackLocal` quando `ServicoAppCheck.instancia.obterToken()` retorna `null`), enquanto permite que `SincronizadorNuvemService` e `ServicoFilaFeedback` saibam com precisão se há um JWT real emitido pelo Firebase (ou injetado por um Fake de teste como `'app_check_token_valido'` / `'token_app_check_teste_123'`) ou se caiu no fallback local sem App Check.

### 3. Mock Gracioso em `SincronizadorNuvemService` e `ServicoFilaFeedback`
- **Decisão**:
  - Adicionar a flag injetável `final bool _emModoDesenvolvimento;` (padrão `kModoDesenvolvimento`) nos construtores de `SincronizadorNuvemService` e `ServicoFilaFeedback`.
  - Em `SincronizadorNuvemService`:
    - Quando `_emModoDesenvolvimento && !AutenticacaoNuvemService.possuiTokenAppCheckReal(tokenAppCheck)`:
      1. Em `_executarEnvioSubmissao`: emitir `_logger.logInfo('📝 [DEBUG MOCK] Upload de laudo concluído localmente (App Check não registrado em dev): ${record.idSessao}')`, marcar `record.enviadoNuvem = true`, salvar no SQLite (`await banco?.salvarSubmissao(record)`), emitir `ProgressoPublicacaoLaudo(idSessao: record.idSessao, etapa: EtapaPublicacaoLaudo.concluidoAtivo, blocosEnviados: totalBlocos, totalBlocos: totalBlocos)` e retornar `true`.
      2. Em `publicarEAguardarLiberacao`: obter `tokenAppCheck` antes do loop HTTP; se estiver em mock gracioso, caso `registro != null && !registro.enviadoNuvem`, chamar `await enviarSubmissao(registro)` e em seguida emitir e retornar `ProgressoPublicacaoLaudo(idSessao: idSessao, etapa: EtapaPublicacaoLaudo.concluidoAtivo, blocosEnviados: 1, totalBlocos: 1)`.
      3. Em `restaurarRelatoriosDaConta`: se estiver em mock gracioso, emitir `_logger.logInfo('📝 [DEBUG MOCK] Restauração de relatórios concluída localmente (App Check não registrado em dev).')` e retornar `0`.
  - Em `ServicoFilaFeedback.enviarItemFeedback`:
    - Quando `_emModoDesenvolvimento && !AutenticacaoNuvemService.possuiTokenAppCheckReal(tokenAppCheck)`:
      - Emitir `_logger.logInfo('📝 [DEBUG MOCK] Feedback concluído localmente (App Check não registrado em dev): ${item.idFeedback}')` e retornar `true` sem enviar requisição HTTP.
- **Racional**: Nos testes unitários existentes de `SincronizadorNuvemService` e `ServicoFilaFeedback`, o `AutenticacaoNuvemServiceFake` já fornece `'app_check_token_valido'` (ou `'token_app_check_teste_123'`), para os quais `possuiTokenAppCheckReal` retorna `true` — preservando 100% dos testes de transporte HTTP existentes, enquanto qualquer execução sem token registrado (`null`, `''` ou `tokenAppCheckFallbackLocal`) aciona o mock gracioso.

## Risks / Trade-offs

- **[Risco] Ativar acidentalmente o mock gracioso em build de produção (`kModoReleaseOficial`)** → **Mitigação**: A condição exige `emModoDesenvolvimento` (`!kModoReleaseOficial`) **E** ausência de token real (`!possuiTokenAppCheckReal(token)`). Em builds de release oficial (`kModoReleaseOficial == true`), `_emModoDesenvolvimento` é `false`, garantindo que o mock gracioso jamais seja executado em produção.
