# Design

## Context

Consulte `proposal.md` para a motivação completa e `specs/` para os contratos de comportamento exigidos. Atualmente, `AutenticacaoNuvemService` em `app/lib/core/services/autenticacao_nuvem_service.dart` utiliza `HttpException` do `dart:io` para respostas HTTP `4xx`/`5xx` do Supabase GoTrue e mantém um bloco residual de fallback sintético (`construirIdTokenOidcComNonce` e `usr_*_padrao`) em código de produção. Em paralelo, `RegistroLogger.isFalhaConexaoOuTimeout` trata qualquer `HttpException` como queda de conexão sem verificar códigos HTTP, e cinco fluxos de UI/ViewModels capturam `catch (e)` sem `StackTrace` nem envio ao `RegistroLogger`.

## Goals / Non-Goals

**Goals:**
- Garantir zero caminhos de sessão falsa ou token OIDC sintético em `app/lib/`, preservando utilitários determinísticos exclusivamente em `app/test/`.
- Diferenciar com precisão erros transitórios de transporte/gateway (`408, 429, 502, 503, 504`, `SocketException`, `TimeoutException`) de erros HTTP definitivos (`400, 401, 403, 404, 422, 500`), tanto em exceções tipadas quanto em `HttpException`.
- Garantir que todas as exceções operacionais tratadas em ViewModels e telas cheguem ao Sentry e ao Crashlytics com `StackTrace` íntegro, sem vazar JSON/URLs cruas para o usuário.
- Exibir apenas provedores OIDC suportados nativamente por sistema operacional (Google no Android; Google e Apple no iOS).

**Non-Goals:**
- Implementar fluxo OAuth Web para Sign in with Apple no Android (descartado deliberadamente para evitar dependência de *Services ID* web e rotação semestral de chaves `.p8`).
- Alterar o código do repositório irmão `../aresta_app` dentro desta mudança (que será tratado em proposta dedicada no próprio repositório `aresta_app`).

## Decisions

### 1. Exceções Tipadas de Autenticação OIDC e Remoção Integral do Fallback em `lib/`

- **Decisão**:
  - Introduzir em `autenticacao_nuvem_service.dart` duas exceções explícitas e testáveis:
    1. `ExcecaoAutenticacaoCancelada`: lançada quando o canal nativo retorna `{'cancelado': true}`.
    2. `ExcecaoAutenticacaoOidc`: contendo `mensagem`, `statusCode` opcional (`int?`), `codigoErroServidor` opcional (`String?`, ex.: `provider_disabled`) e `uri` opcional (`Uri?`), lançada em respostas não-2xx de `trocarIdTokenNoSupabase` ou quando o canal nativo retorna `null`, `idToken` vazio, `PlatformException` ou `MissingPluginException`.
  - Mover `construirIdTokenOidcComNonce` de `AutenticacaoNuvemService` (`app/lib/`) para `AutenticacaoNuvemServiceFake` (`app/test/core/services/autenticacao_nuvem_service_fake.dart`), garantindo que os testes existentes continuem construindo JWTs determinísticos com `nonce` válido sem poluir o binário de produção.
  - Ler `(respostaNativa['nomeCompleto'] ?? respostaNativa['nomeExibicao'])` para compatibilizar o retorno de `MainActivity.kt` (`nomeExibicao`) e `AppDelegate.swift` (`nomeCompleto`).
- **Alternativas consideradas**:
  - *Proteger o fallback sintético com `kDebugMode`*: Descartado porque viola os Princípios V e VI do `AGENTS.md` (código de teste infiltrado em produção e risco de mascarar falhas de integração nativa durante o desenvolvimento).

### 2. Inspeção de Código HTTP em `RegistroLogger.isFalhaConexaoOuTimeout`

- **Decisão**:
  ```mermaid
  flowchart TD
      A["Erro recebido em isFalhaConexaoOuTimeout"] --> B{"Possui statusCode explícito ou código HTTP na mensagem?"}
      B -->|"Sim: 408, 429, 502, 503, 504"| C["Retorna true (logAviso / Breadcrumb)"]
      B -->|"Sim: 400..499 ou 500..599 (exceto transitórios)"| D["Retorna false (logError / Sentry Issue)"]
      B -->|"Não possui status HTTP"| E{"É SocketException, TimeoutException ou HttpException pura de transporte?"}
      E -->|"Sim"| C
      E -->|"Não"| D
  ```
  - Extrair um helper puro em `RegistroLogger` que verifica primeiro se o objeto possui código HTTP explícito (ex.: `ExcecaoAutenticacaoOidc.statusCode`, `ExcecaoApiFixalogNuvem.statusCode`, `int` direto ou padrão de status HTTP `(4\d\d|5\d\d)` dentro de `HttpException.message`):
    - Se houver código HTTP identificado: retorna `true` **somente** para `{408, 429, 502, 503, 504}`; qualquer outro código `4xx`/`5xx` (como `400`, `401`, `403`, `404`, `422`, `500`) retorna imediatamente `false`, impedindo que `error is HttpException` engula erros de API!
    - Se não houver código HTTP na resposta (ex.: `HttpException: Connection closed before full header was received`, `SocketException`, `TimeoutException`, `HandshakeException`): mantém o retorno `true` para preservar o silêncio em falta de sinal na montanha.
- **Alternativas consideradas**:
  - *Remover `HttpException` completamente de `isFalhaConexaoOuTimeout`*: Descartado porque o `HttpClient` nativo do `dart:io` lança `HttpException` sem código HTTP quando a antena de celular perde sinal no meio do download dos cabeçalhos na rocha. Inspecionar o código HTTP resolve ambos os casos sem falsos positivos.

### 3. Visibilidade do Botão Apple por Plataforma e Padronização dos `try/catch` de UI/ViewModels

- **Decisão**:
  - Em `IdentitySetupScreen`, renderizar o botão `botao_login_apple` apenas quando `Theme.of(context).platform == TargetPlatform.iOS` (ou parâmetro/plataforma equivalente testável via `ThemeData(platform: TargetPlatform.iOS)` / `TargetPlatform.android` nos widget tests, sem acoplamento estático a `Platform.isIOS` que dificultaria testes multiplataforma).
  - Em `IdentityFormViewModel.autenticarComProvedor`:
    - `on ExcecaoAutenticacaoCancelada`: apenas restaura `isLoading: false, errorMessage: null` silenciosamente.
    - `catch (e, stackTrace)`: se `RegistroLogger.isFalhaConexaoOuTimeout(e)` for verdadeiro, chama `logAviso` e define mensagem localizada de falta de conexão; caso contrário, chama `RegistroLogger.instancia.logError` com `stackTrace` e define mensagem localizada limpa na UI (sem expor JSON/URI crua).
  - Aplicar o mesmo padrão `catch (e, stackTrace)` com `RegistroLogger.instancia.logError` em:
    - `IdentityFormViewModel.submitIdentity`
    - `GenerationNotifier.generateAll` (`generation_provider.dart`)
    - `HistoryScreen` (carregar sessão e duplicar relatório)
    - `VisualizadorRelatorioScreen` (ações de abertura/exportação/compartilhamento)
    - `SincronizadorNuvemService.publicarEAguardarLiberacao` (usando `logFalhaSyncOuDownload` com `stackTrace`).

## Risks / Trade-offs

- **[Testes existentes que dependiam do fallback automático do `MethodChannel` não registrado]** → **Mitigação**: Atualizar os testes unitários e de widget para injetarem explicitamente `AutenticacaoNuvemServiceFake` (ou handler de canal simulado nos testes de fronteira de `AutenticacaoNuvemService`), aumentando a fidelidade de produção conforme o Princípio V do `AGENTS.md`.
- **[Usuários em testes de widget rodando em host Windows/Linux onde `TargetPlatform` padrão no Flutter Test é `android`]** → **Mitigação**: Nos testes específicos do botão da Apple em `identity_setup_screen_test.dart`, configurar `ThemeData(platform: TargetPlatform.iOS)` e adicionar um teste explícito validando que em `TargetPlatform.android` apenas o botão Google é exibido.
