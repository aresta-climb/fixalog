# Spec Delta

## MODIFIED Requirements

### Requirement: Proteção de Requisições com Firebase App Check
Todas as requisições de registro de chave pública e upload de relatórios para a nuvem DEVEM (MUST) incluir um token válido do Firebase App Check emitido pelo atestador nativo do dispositivo (`Play Integrity` no Android e `App Attest` / `DeviceCheck` no iOS), além do JWT de sessão do Supabase. O provedor de token App Check NUNCA DEVE (MUST NOT) retornar textos fixos ou tokens sintéticos provisórios em código de produção quando a atestação falhar, estiver em *cooldown* ou sem rede, devendo retornar `null` para indicar ausência de token real.

#### Scenario: Envio de requisição autenticada com atestado de integridade do dispositivo
- **WHEN** o aplicativo envia o registro de uma chave pública ou o upload de um arquivo `.epub` para a API do Fixalog
- **THEN** a requisição inclui o cabeçalho `Authorization: Bearer <supabase_jwt>` e o cabeçalho `X-Firebase-AppCheck: <app_check_token>`

#### Scenario: Retorno nulo sem token provisório quando a atestação App Check não está disponível
- **WHEN** o atestador do Firebase App Check retorna `null` por falta de conectividade, *cooldown* ativo ou ambiente de emulador sem atestação
- **THEN** o serviço de autenticação retorna `null` ao consumidor sem substituir por qualquer string sintética de fallback

### Requirement: Proibição de Credenciais Sintéticas de Fallback em Produção
O sistema JAMAIS DEVE (MUST NOT) gerar tokens OIDC sintéticos locais ou sessões de conta fictícias quando o canal nativo de autenticação retornar nulo, estiver indisponível ou devolver token vazio. O canal nativo DEVE (MUST) propagar o código e a descrição diagnóstica das falhas nativas ao código Dart. Quando o sistema operacional informar ausência de credencial/conta cadastrada no aparelho (como dispositivos Android sem conta Google adicionada nas configurações do sistema), o aplicativo DEVE (MUST) interromper a autenticação exibindo mensagem localizada orientando o usuário a adicionar uma conta Google no dispositivo e registrar apenas um aviso contextual (`logAviso`), sem abrir alerta de erro no Sentry ou Crashlytics. Demais falhas não decorrentes de cancelamento ou falta de conectividade DEVEM (MUST) resultar em falha explícita registrada na observabilidade.

#### Scenario: Resposta nula ou sem token do canal nativo falha explicitamente
- **WHEN** o seletor nativo de autenticação retorna resposta nula, `idToken` vazio ou falha de plataforma inesperada sem flag de cancelamento nem indicação de ausência de conta no aparelho
- **THEN** o sistema interrompe a autenticação sem persistir sessão local nem invocar fallback sintético, registra o erro operacional com diagnóstico nativo na observabilidade e exibe mensagem amigável na interface

#### Scenario: Dispositivo Android sem conta Google cadastrada exibe orientação sem reportar bug
- **WHEN** o usuário ou um robô de testes aciona "Continuar com o Google" em um aparelho Android sem nenhuma conta Google configurada no sistema operacional (`NoCredentialException` / ausência de credenciais disponíveis)
- **THEN** o sistema interrompe o estado de carregamento, registra apenas um aviso operacional (`logAviso`) sem enviar erro ao Sentry ou Crashlytics, e exibe mensagem localizada instruindo o usuário a adicionar uma conta Google nas configurações do aparelho

### Requirement: Tratamento Silencioso de Cancelamento Voluntário pelo Usuário
Quando o usuário fechar ou cancelar voluntariamente o modal nativo de autenticação (`cancelado == true`, incluindo o fechamento do `CredentialManager` no Android, o cancelamento do `ASAuthorizationController` da Apple e o botão Cancelar do `ASWebAuthenticationSession` do Google no iOS), o sistema DEVE (MUST) interromper o estado de carregamento sem enviar requisição ao servidor de autenticação, sem exibir alerta de erro na interface e sem registrar falha na observabilidade.

#### Scenario: Usuário cancela o modal do Face ID ou seletor de contas Google
- **WHEN** o usuário toca em cancelar ou fecha o modal nativo de login da Apple ou do Google (tanto no seletor nativo Android quanto na janela OAuth in-app do iOS)
- **THEN** o sistema restaura a tela para o estado interativo inicial sem exibir `SnackBar` de erro e sem enviar exceção ao Sentry ou Crashlytics
