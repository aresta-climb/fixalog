# Design

## Context

Conforme detalhado em `proposal.md`, a análise forense dos 5 eventos do `FIXALOG-2` (**Issue #6**) no Sentry revelou que 100% dos crashes `SIGSEGV` no emulador `OnePlus8Pro` (`Android 11`, `QKR1.191246.002`, `x86_64`, `288x448`, `106 dpi`) ocorreram dentro da janela de `79 ms` a `308 ms` da animação de transição `MaterialPageRoute` para a `IdentitySetupScreen`, antes de qualquer novo clique do robô do Google Play Pre-Launch Report. Em contrapartida, quando a `IdentitySetupScreen` foi renderizada declarativamente pelo `_StartupRouter` na rota raiz (sem transição `MaterialPageRoute`), permaneceu em tela por mais de 22 segundos executando fluxos completos de login OIDC, logout, permissões e salvamento sem qualquer falha.

## Goals / Non-Goals

**Goals:**
- Eliminar completamente a alocação de texturas GPU *offscreen* (`SnapshotWidget` via `OffsetLayer.toImageSync`) durante transições de rota e erradicar os 4 passes de `BackdropFilter(ImageFilter.blur(sigmaX: 150, sigmaY: 150))` em tela cheia.
- Tornar a `IdentitySetupScreen` visualmente opaca (`Scaffold(backgroundColor: const Color(0xFF2D3328))` com gradiente linear padrão de 2 cores) e livre de mutações síncronas de `TextEditingController` durante o `build()`.
- Garantir transição declarativa limpa no `_StartupRouter` ao aceitar os termos e concluir o onboarding inicial, além de prover botão de retorno explícito quando a `IdentitySetupScreen` for empilhada a partir da `TelaConfiguracoes`.
- Alinhar a configuração de release Android (`build.gradle.kts`, `gradle.properties`, `proguard-rules.pro`) com o `aresta_app`, incluindo `ndk.debugSymbolLevel = "SYMBOL_TABLE"` e `android.r8.optimizedResourceShrinking=true`.

**Non-Goals:**
- Alterar o contrato criptográfico OpenPubkey ou a persistência local em SQLite / `FlutterSecureStorage`.

## Decisions

### Decisão 1: `ZoomPageTransitionsBuilder(allowSnapshotting: false)` e Roteamento Declarativo no `_StartupRouter`
- **Escolha**:
  1. Configurar `pageTransitionsTheme` no `darkTheme` de `FixalogApp` (`app/lib/main.dart`) definindo `ZoomPageTransitionsBuilder(allowSnapshotting: false)` para `TargetPlatform.android`.
  2. Converter `_StartupRouter` para reagir declarativamente ao aceite de termos (`aoAceitar: () => setState(() {})` passado à `TelaTermosDeUso`) e invalidar `hasIdentityProvider` ao concluir o cadastro inicial na `IdentitySetupScreen`, preservando o fallback `Navigator.pushReplacement` apenas quando `TelaTermosDeUso` ou `IdentitySetupScreen` forem montadas isoladamente em testes de widget sem `_StartupRouter`.
- **Racional**: O `SnapshotWidget` do `ZoomPageTransitionsBuilder` (ativo por padrão no Material 3 com `allowSnapshotting: true`) força `OffsetLayer.toImageSync()` em texturas GPU *offscreen* durante os `300 ms` da transição. Desativar `allowSnapshotting` mantém a mesma animação visual usando composição direta na árvore de camadas da GPU, sem alocar nem descartar texturas *offscreen* intermediárias.

### Decisão 2: Substituição de `BackdropFilter(ImageFilter.blur(150, 150))` por `RadialGradient`
- **Escolha**: Substituir os círculos decorativos combinados com `BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 150, sigmaY: 150))` em `NewProtocolScreen`, `HistoryScreen`, `TelaConfiguracoes` e `WizardScreen` por `Container`s com `BoxDecoration(gradient: RadialGradient(...))`.
- **Racional**: Os 3 `BackdropFilter`s dentro do `IndexedStack` da `HomeScreen` serviam exclusivamente para suavizar círculos verdes estáticos de fundo (`Color(0xFF1B3D2F)`). Um `RadialGradient` produz exatamente o mesmo brilho atmosférico difuso em uma única passagem de shader, eliminando 3 capturas de *framebuffer* em tempo real e cumprindo estritamente o Princípio IX do `AGENTS.md` (orçamento de meio frame).

### Decisão 3: Fundo Opaco, Pré-preenchimento Síncrono no `initState` e Sincronização Fora do `build()` na `IdentitySetupScreen`
- **Escolha**:
  1. Em `IdentitySetupScreen`, substituir `Scaffold(backgroundColor: Colors.transparent)` por `Scaffold(backgroundColor: const Color(0xFF2D3328))` e usar `LinearGradient` de 2 cores (`[Color(0xFF2D3328), Color(0xFF455A46)]`) sem `stops`.
  2. No `initState()` de `_IdentitySetupScreenState`, pré-preencher imediatamente `_nomeController.text` e `_clubeController.text` a partir dos valores já disponíveis em `identityFormViewModelProvider` ou `currentIdentityProvider.valueOrNull` antes do primeiro frame.
  3. Em `IdentityFormViewModel.carregarSessaoExistente()`, consultar também `_repository.getCurrentIdentity()` para garantir que o nome e o clube salvos localmente no SQLite sejam sempre carregados mesmo quando a sessão OIDC tiver campos vazios, e aplicar atualizações subsequentes aos `TextEditingController`s apenas quando o valor realmente divergir.
  4. Exibir um `IconButton` de retorno (`key: const Key('botao_voltar_identidade')`) no cabeçalho quando `Navigator.of(context).canPop()` for verdadeiro, e invalidar `currentIdentityProvider`, `hasIdentityProvider` e `sessaoOidcConfigProvider` ao salvar ou trocar de conta.
- **Racional**: Evita que a `IdentitySetupScreen` sofra reconstrução estrutural ou dispare mutações de `TextInput` no meio da animação de entrada (`79ms–300ms`).

### Decisão 4: Paridade de Compilação Release Android (`R8` e `SYMBOL_TABLE`)
- **Escolha**: Configurar `isMinifyEnabled = true`, `isShrinkResources = true`, `proguardFiles(...)` e `ndk { debugSymbolLevel = "SYMBOL_TABLE" }` no `buildTypes.release` de `app/android/app/build.gradle.kts`, criar `app/android/app/proguard-rules.pro` e adicionar `android.enableR8.fullMode=true` e `android.r8.optimizedResourceShrinking=true` em `app/android/gradle.properties`.
- **Racional**: Garante que o encolhedor de recursos do R8 preserve a integridade das tabelas `resources.arsc` em *Split APKs* e que símbolos nativos completos sejam gerados e enviados ao Google Play Console e ao Sentry.

## Risks / Trade-offs

- **[Risco] Testes de widget que montam `TelaTermosDeUso` ou `IdentitySetupScreen` diretamente sem `_StartupRouter`** $\rightarrow$ **Mitigação**: Manter o comportamento de `Navigator.pushReplacement` quando `aoAceitar` for nulo em `TelaTermosDeUso` e quando `Navigator.canPop()` for falso em `IdentitySetupScreen` (após invalidar `hasIdentityProvider`), garantindo 100% de compatibilidade com todos os testes isolados e com o roteador declarativo.
