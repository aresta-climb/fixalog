# Proposal

## Why

Nos relatórios de pré-lançamento da Google Play Store (*Pre-Launch Report / Robo Test*) até a versão `v0.2.7+24`, o aplicativo apresentou falha nativa `SIGSEGV: Segfault` (**Issue #6** / Sentry `FIXALOG-2`) no emulador `OnePlus8Pro` (`Android 11`, `QKR1.191246.002`, `x86_64`, `288x448`, `106 dpi`) exatamente entre `79 ms` e `308 ms` após iniciar a transição `MaterialPageRoute` para a `IdentitySetupScreen` (100% das vezes ao tocar em `editar_identidade` na `TelaConfiguracoes`, além da transição pós-`aceitar_termos_uso`), enquanto a renderização declarativa da mesma tela pelo `_StartupRouter` operou por mais de 22 segundos sem qualquer falha. A causa raiz é a convergência, durante os `300 ms` da transição `ZoomPageTransitionsBuilder(allowSnapshotting: true)`, da captura de texturas GPU *offscreen* (`SnapshotWidget`) sobre 3 camadas simultâneas de `BackdropFilter(ImageFilter.blur(sigmaX: 150, sigmaY: 150))` na `HomeScreen`, combinada ao único `Scaffold(backgroundColor: Colors.transparent)` com `LinearGradient` de 3 paradas da `IdentitySetupScreen` e à mutação síncrona de `TextEditingController` dentro de `build()` quando `carregarSessaoExistente()` retorna no meio da animação — agravada pela ausência de `ndk.debugSymbolLevel = "SYMBOL_TABLE"` e `android.r8.optimizedResourceShrinking=true` na configuração de release Android.

## What Changes

- **Desativação de Snapshotting Offscreen em Transições de Rota e Roteamento Declarativo no Onboarding (`app/lib/main.dart`, `app/lib/features/onboarding/views/tela_termos_de_uso.dart`)**:
  - Configurar `pageTransitionsTheme` no `darkTheme` do `FixalogApp` com `ZoomPageTransitionsBuilder(allowSnapshotting: false)` para impedir que o `SnapshotWidget` aloque texturas *offscreen* (`OffsetLayer.toImageSync`) durante transições de rota em GPUs virtuais Android 11.
  - Permitir que o `_StartupRouter` reaja declarativamente ao aceite dos termos de uso e à conclusão do cadastro inicial de identidade sem depender de `Navigator.pushReplacement` sobre a rota raiz.
- **Substituição de `BackdropFilter(blur: 150)` por `RadialGradient` Nativo (`new_protocol_screen.dart`, `history_screen.dart`, `tela_configuracoes.dart`, `wizard_screen.dart`)**:
  - Remover os 4 usos de `BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 150, sigmaY: 150))` que borravam círculos decorativos estáticos de fundo e substituí-los por `BoxDecoration` com `RadialGradient` equivalente, preservando o visual atmosférico com custo zero de *framebuffer readback* na GPU (cumprindo o Princípio IX de orçamento de meio frame).
- **Saneamento Gráfico e de Ciclo de Vida da `IdentitySetupScreen` (`identity_setup_screen.dart`, `identity_form_view_model.dart`)**:
  - Substituir `Scaffold(backgroundColor: Colors.transparent)` por `Scaffold(backgroundColor: const Color(0xFF2D3328))` opaco e `LinearGradient` padrão de 2 cores (sem `stops: [0.0, 0.5, 1.0]`), além de exibir botão de retorno (`botao_voltar_identidade`) no cabeçalho quando a tela estiver empilhada (`Navigator.canPop(context)`).
  - Inicializar `_nomeController` e `_clubeController` sincronamente no `initState()` a partir do estado/identidade já carregados, fazer `carregarSessaoExistente()` consultar também a identidade local (`IdentityRepository.getCurrentIdentity()`) como fallback, mover a sincronização de texto dos controladores para fora da árvore de pintura e invalidar `currentIdentityProvider`, `hasIdentityProvider` e `sessaoOidcConfigProvider` ao concluir ou trocar de conta.
- **Alinhamento da Compilação de Release Android e Símbolos Nativos com o Ecossistema Aresta (`build.gradle.kts`, `gradle.properties`, `proguard-rules.pro`)**:
  - Configurar `isMinifyEnabled = true`, `isShrinkResources = true`, `proguardFiles(...)` e `ndk { debugSymbolLevel = "SYMBOL_TABLE" }` em `app/android/app/build.gradle.kts`.
  - Adicionar `app/android/app/proguard-rules.pro` e habilitar `android.enableR8.fullMode=true` e `android.r8.optimizedResourceShrinking=true` em `app/android/gradle.properties`.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capacidade introduzida. -->

### Modified Capabilities
- `aba-configuracoes-governanca`: Especificar que a abertura e edição na `IdentitySetupScreen` operam com fundo opaco, transições sem *snapshotting* de textura GPU *offscreen*, pré-preenchimento síncrono a partir da sessão/identidade local sem mutação de controladores durante o `build()`, botão de retorno quando empilhada e invalidação reativa dos provedores de identidade e sessão OIDC.
- `app-release-pipeline`: Especificar a configuração explícita de R8 Full Mode, redução otimizada de recursos (`android.r8.optimizedResourceShrinking=true`), regras ProGuard e geração de tabela de símbolos nativos (`debugSymbolLevel = "SYMBOL_TABLE"`) no build de release Android.

## Impact

- `app/lib/main.dart` e `app/test/main_test.dart`
- `app/lib/features/identity/views/identity_setup_screen.dart` e `app/test/features/identity/views/identity_setup_screen_test.dart`
- `app/lib/features/identity/viewmodels/identity_form_view_model.dart` e `app/test/features/identity/viewmodels/identity_form_view_model_test.dart`
- `app/lib/features/home/views/new_protocol_screen.dart`, `app/lib/features/home/views/history_screen.dart`, `app/lib/features/settings/views/tela_configuracoes.dart` e `app/lib/features/wizard/views/wizard_screen.dart`
- `app/android/app/build.gradle.kts`, `app/android/app/proguard-rules.pro` e `app/android/gradle.properties`
