# Proposal

## Why

Após o primeiro lançamento do aplicativo na faixa interna do Google Play Console, os testes automatizados de pré-lançamento (Google Play Pre-Launch Report no Firebase Test Lab) e a telemetria do Sentry revelaram dois problemas operacionais:
1. **Auto-fechamento imediato e crash (`SIGSEGV`, Issue #6 / `FIXALOG-2`) ao editar identidade nas Configurações**: Como `identityFormViewModelProvider` mantém `isSuccess: true` após o onboarding inicial e `carregarSessaoExistente()` não limpa essa flag ao reabrir a `IdentitySetupScreen`, o listener da tela dispara imediatamente durante a transição de entrada e executa `pushReplacement(HomeScreen())`, impedindo o usuário de editar sua conta OIDC, empilhando uma `HomeScreen` duplicada e provocando `SIGSEGV` ~300ms após o clique em `editar_identidade`.
2. **Tempestade de chamadas e alertas de `Too many attempts` no `ServicoAppCheck` (Issues #7 e #8 / `FIXALOG-3` e `FIXALOG-4`)**: Quando a obtenção de token do Firebase App Check falha em ciclos de sincronização em background (seja por emulador do Pre-Launch Report, configuração pendente do Play Integrity ou rate-limit nativo `Too many attempts`), o `ServicoAppCheck` não possui janela de *cooldown* em memória e registra cada tentativa subsequente de `Too many attempts` como `logError` no Sentry.

## What Changes

- **Reset de Estado e Navegação Segura na Edição de Identidade (`IdentityFormViewModel` e `IdentitySetupScreen`)**:
  - Atualizar `IdentityFormViewModel.carregarSessaoExistente()` para sempre limpar `isSuccess: false` e `errorMessage: null` ao carregar a sessão na abertura da tela,mesmo quando `sessao == null`.
  - Atualizar o listener de `IdentitySetupScreen` para reagir apenas à transição `!(previous?.isSuccess ?? false) && next.isSuccess`, retornando à tela anterior (`Navigator.pop`) quando aberta via pilha de navegação (`canPop() == true`) ou navegando via `pushReplacement` para `HomeScreen` no onboarding inicial.
  - Atualizar os campos de texto (`_nomeController` e `_clubeController`) ao abrir a edição para refletir os dados atuais da sessão carregada.
- **Cooldown em Memória e Classificação de Rate-Limit no `ServicoAppCheck`**:
  - Adicionar janela de *cooldown* em memória (padrão de 5 minutos, com relógio injetável para testes determinísticos) em `ServicoAppCheck.obterToken()` após falhas de atestação ou *rate-limit*, retornando `null` imediatamente em chamadas subsequentes sem `forcarAtualizacao` enquanto o *cooldown* estiver ativo.
  - Classificar erros de *rate-limit* (`Too many attempts`) como aviso (`logAviso`) em vez de erro não-tratado (`logError`), evitando poluição de alertas no Sentry durante sincronizações periódicas em background.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capacidade introduzida. -->

### Modified Capabilities
- `aba-configuracoes-governanca`: Garante que o acionamento de gerenciamento de identidade (`IdentitySetupScreen`) a partir da `TelaConfiguracoes` reinicie o estado transitório de submissão (`isSuccess: false`), permaneça aberto para edição e desempilhe a rota ao concluir sem duplicar a `HomeScreen`.
- `observabilidade-dual-logger`: Adiciona *cooldown* em memória no `ServicoAppCheck.obterToken` após falhas de atestação e rebaixa exceções de *rate-limit* (`Too many attempts`) para `logAviso`.

## Impact

- `app/lib/features/identity/viewmodels/identity_form_view_model.dart` e `app/test/features/identity/viewmodels/identity_form_view_model_test.dart`
- `app/lib/features/identity/views/identity_setup_screen.dart` e `app/test/features/identity/views/identity_setup_screen_test.dart`
- `app/lib/core/services/servico_app_check.dart` e `app/test/core/services/servico_app_check_test.dart`
