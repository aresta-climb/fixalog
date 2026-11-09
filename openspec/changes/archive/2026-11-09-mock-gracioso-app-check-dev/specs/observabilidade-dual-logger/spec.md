# Spec Delta: Observabilidade Dual, App Check e Logger de Campo

## MODIFIED Requirements

### Requirement: Atestação de Integridade via Firebase App Check
O sistema DEVE (MUST) ativar o Firebase App Check (`ServicoAppCheck`) utilizando Play Integrity no Android, App Attest no iOS e provedores de depuração fora de builds de release oficial, fornecendo tokens JWT válidos para o `AutenticacaoNuvemService` e degradando graciosamente sem bloquear o aplicativo quando offline ou quando o UUID de depuração local não estiver cadastrado no Firebase Console em modo de desenvolvimento (`kModoDesenvolvimento`).

#### Scenario: Obtenção de token App Check sem conexão
- **WHEN** o `AutenticacaoNuvemService` solicita um token ao `ServicoAppCheck` enquanto o dispositivo está sem sinal na montanha
- **THEN** o `ServicoAppCheck` captura a exceção de rede, registra apenas um aviso no `RegistroLogger` e retorna de forma segura sem interromper o fluxo offline do auditor

#### Scenario: Obtenção de token App Check em modo de desenvolvimento sem UUID cadastrado no Firebase Console
- **WHEN** o `ServicoAppCheck.obterToken` é acionado em modo de desenvolvimento (`kModoDesenvolvimento`) e o `DebugAppCheckProvider` falha com `403 App attestation failed` por ausência de registro do UUID local no console do Firebase
- **THEN** o `ServicoAppCheck` captura a falha, registra apenas um aviso contextual (`logAviso`) sem emitir erro no Sentry ou Crashlytics, e retorna `null` para acionar o mock gracioso nos serviços consumidores
