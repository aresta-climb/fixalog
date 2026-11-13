# Design

## Context

Veja `proposal.md` para a motivação completa. Dois componentes precisam de ajustes pontuais mantendo 100% de cobertura de testes e espelhamento 1:1 conforme `AGENTS.md`:
1. `IdentityFormViewModel` (`app/lib/features/identity/viewmodels/identity_form_view_model.dart`) e `IdentitySetupScreen` (`app/lib/features/identity/views/identity_setup_screen.dart`).
2. `ServicoAppCheck` (`app/lib/core/services/servico_app_check.dart`).

## Goals / Non-Goals

**Goals:**
- Impedir que `IdentitySetupScreen` dispare navegação automática imediata ao ser aberta a partir de `TelaConfiguracoes` quando `state.isSuccess` já era `true` de uma submissão anterior.
- Desempilhar (`Navigator.pop`) ao concluir a edição quando `IdentitySetupScreen` foi empilhada sobre outra rota (`Navigator.canPop(context) == true`), preservando `pushReplacement(HomeScreen())` apenas no fluxo de onboarding inicial.
- Evitar chamadas repetitivas ao canal nativo `FirebaseAppCheck.getToken` e alertas redundantes no Sentry quando o dispositivo encontra *rate-limit* (`Too many attempts`) ou falha de atestação.

**Non-Goals:**
- Alterar o contrato de autenticação OIDC ou a assinatura criptográfica ECDSA P-256 dos laudos.

## Decisions

### 1. Ciclo de Vida de `isSuccess` no `IdentityFormViewModel` e Navegação Contextual na `IdentitySetupScreen`
- **Decisão**:
  - Em `IdentityFormViewModel.carregarSessaoExistente()`, sempre limpar `isSuccess: false` e `errorMessage: null` antes de consultar `_autenticacaoService.obterSessaoAtual()`, e preservar `isSuccess: false` ao atualizar `sessaoNuvem`, `nomeSugerido` e `clubeSugerido`.
  - Em `IdentitySetupScreen`, no `ref.listen<IdentityFormState>`, verificar `!(previous?.isSuccess ?? false) && next.isSuccess` antes de navegar. Quando essa transição ocorrer: se `Navigator.of(context).canPop()` for `true`, executar `Navigator.of(context).pop()`; caso contrário, executar `Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()))`.
  - Também invalidar `currentIdentityProvider` após `submitIdentity` ou `pop` para que a `TelaConfiguracoes` reflita imediatamente o novo nome/clube editado.
- **Alternativas consideradas**:
  - Tornar `identityFormViewModelProvider` `autoDispose`: descartado isoladamente porque diversos testes e fluxos observam o provider e ainda assim uma rota empilhada sobre `TelaConfiguracoes` não deve usar `pushReplacement(HomeScreen())` quando `canPop()` é verdadeiro.

### 2. Cooldown Determinístico no `ServicoAppCheck`
- **Decisão**:
  - Adicionar ao `ServicoAppCheck` um parâmetro opcional `DateTime Function()? relogio` (padrão `DateTime.now`) e `Duration duracaoCooldownFalha` (padrão `Duration(minutes: 5)`).
  - Quando `_obterTokenAppCheck` lançar uma exceção que não seja falha transitória de conexão (`!RegistroLogger.isFalhaConexaoOuTimeout(e)`):
    - Registrar o instante de expiração do *cooldown* (`_cooldownAte = _relogio().add(duracaoCooldownFalha)`).
    - Se a mensagem do erro contiver `too many attempts` (case-insensitive), registrar via `_logger.logAviso(...)` em vez de `_logger.logError(...)`.
  - No início de `obterToken([bool forcarAtualizacao = false])`, se `!forcarAtualizacao` e `_cooldownAte != null && _relogio().isBefore(_cooldownAte!)`, retornar `null` imediatamente sem chamar `_obterTokenAppCheck`.
- **Alternativas consideradas**:
  - Usar `Future.delayed` ou timers ativos: descartado pois um simples timestamp comparado com `relogio()` não aloca timers pendentes em testes de widget e é 100% determinístico.

## Risks / Trade-offs

- **[Risco] Bloqueio temporário após falha pontual de App Check** → Mitigação: Se o chamador passar `forcarAtualizacao: true`, o *cooldown* em memória é ignorado e uma nova tentativa real é feita.
