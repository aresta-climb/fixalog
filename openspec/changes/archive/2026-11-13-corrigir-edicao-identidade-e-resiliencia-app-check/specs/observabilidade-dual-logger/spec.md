# Spec Delta

## MODIFIED Requirements

### Requirement: Atestação de Integridade via Firebase App Check
O sistema DEVE (MUST) ativar o Firebase App Check (`ServicoAppCheck`) utilizando Play Integrity no Android, App Attest no iOS e provedores de depuração fora de builds de release oficial, fornecendo tokens JWT válidos para o `AutenticacaoNuvemService` e degradando graciosamente sem bloquear o aplicativo quando offline ou quando o UUID de depuração local não estiver cadastrado no Firebase Console em modo de desenvolvimento (`kModoDesenvolvimento`). Quando a obtenção do token falhar por *rate-limit* (`Too many attempts`) ou erro de atestação da API, o `ServicoAppCheck` DEVE (MUST) aplicar uma janela de *cooldown* em memória (5 minutos por padrão) durante a qual chamadas subsequentes a `obterToken(false)` retornam `null` imediatamente sem acionar o canal nativo, e DEVE (MUST) registrar falhas de *rate-limit* (`Too many attempts`) como aviso (`logAviso`) em vez de erro não-tratado (`logError`).

#### Scenario: Obtenção de token App Check sem conexão
- **WHEN** o `AutenticacaoNuvemService` solicita um token ao `ServicoAppCheck` enquanto o dispositivo está sem sinal na montanha
- **THEN** o `ServicoAppCheck` captura a exceção de rede, registra apenas um aviso no `RegistroLogger` e retorna de forma segura sem interromper o fluxo offline do auditor

#### Scenario: Obtenção de token App Check em modo de desenvolvimento sem UUID cadastrado no Firebase Console
- **WHEN** o `ServicoAppCheck.obterToken` é acionado em modo de desenvolvimento (`kModoDesenvolvimento`) e o `DebugAppCheckProvider` falha com `403 App attestation failed` por ausência de registro do UUID local no console do Firebase
- **THEN** o `ServicoAppCheck` captura a falha, registra apenas um aviso contextual (`logAviso`) sem emitir erro no Sentry ou Crashlytics, e retorna `null` para acionar o mock gracioso nos serviços consumidores

#### Scenario: Cooldown em memória e rebaixamento de severidade após rate-limit (Too many attempts)
- **WHEN** `ServicoAppCheck.obterToken` recebe uma exceção contendo `Too many attempts` do SDK nativo do Firebase App Check
- **THEN** o `ServicoAppCheck` registra apenas um aviso (`logAviso`) sem enviar erro ao Sentry, ativa um *cooldown* em memória de 5 minutos e retorna `null` imediatamente nas chamadas seguintes a `obterToken(false)` dentro dessa janela sem invocar novamente o canal nativo
