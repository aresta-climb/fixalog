# Proposal

## Why

Atualmente, o pipeline de lançamento do Fixalog valida o aplicativo apenas na Dart VM de Linux (`flutter test` e campanha do Robô Caótico) e envia diretamente o `.aab` e o `.ipa` compilados com R8, `--obfuscate` e bibliotecas C/C++ nativas para o Google Play Console e App Store Connect — além de cortar o commit/tag da versão antes mesmo de saber se ambos os sistemas operacionais compilaram com sucesso. Em lojas móveis não existe rollback instantâneo nem reaproveitamento de `versionCode`, tornando essencial validar os binários reais pós-build (incluindo login OIDC, Keystore/Keychain ECDSA, compressão WebP, transcodificação FFmpeg H.264, rasterização PDF e geração de EPUB 3 assinado) sem deixar nenhum resquício de código de teste nos artefatos enviados às lojas.

## What Changes

- Criação da capacidade de **Smoke Test Pós-Build Segregado por Compilação Condicional** para Android (emulador KVM `x86_64`) e iOS (iOS Simulator `arm64` + auditoria estrutural do `.ipa` `iphoneos`):
  - O pacote oficial da loja (`.aab` e `.ipa` a partir de `lib/main.dart`) é compilado com as chaves de smoke desligadas (`BuildConfig.ARESTA_SMOKE_CI = false` no Android e exclusão via `#if targetEnvironment(simulator)` no iOS), auditado binariamente para provar ausência total de símbolos/rotas de smoke e validado em Cold Start puro no emulador Android;
  - Um artefato gêmeo descartável de CI (`--release --obfuscate` com o mesmo R8, `proguard-rules.pro`, NDK, CocoaPods, `ffmpeg_kit`, `sqflite`, `flutter_secure_storage`, `printing` e `webview_flutter`, apontando para um entrypoint dedicado `lib/core/smoke_ci/main_smoke_ci.dart` restrito a hardware de emulador/simulador e loopback local) executa a jornada ponta a ponta: aceite dos Termos de Uso, geração de chave ECDSA no cofre do SO, login OIDC via `MethodChannel` nativo contra servidor GoTrue local, emissão de certificado X.509, criação de sessão com foto + vídeo + PDF anexado, geração do pacote `.epub` assinado com XML-DSig e abertura no `VisualizadorRelatorioScreen`.
- Reestruturação da esteira de CI/CD (`release_new_app_version.yml`, `build_android.yml` e `build_ios.yml`) para **Topologia Transacional em Quatro Estágios**:
  1. Validação rápida (`flutter analyze`, `flutter test`, Robô Caótico) e preparação do pacote candidato da versão sem tocar na branch remota;
  2. Compilação + Auditoria Binária + Smoke Test pós-build em paralelo para Android e iOS;
  3. Corte atômico da versão (`git push --atomic` de commits e tag) **somente após** todas as plataformas habilitadas passarem no build e no smoke test;
  4. Publicação sincronizada dos artefatos aprovados (sem recompilar) para Sentry, Firebase Crashlytics, Google Play Console e App Store Connect, com parâmetro `publicar_nas_lojas` permitindo disparos completos de validação interna de CI sem publicar nas lojas nem criar tags.
- Refatoração de `app/integration_test/generation_flow_test.dart` para eliminar mocks internos (`MockFlutterSecureStorage`, `FakePrintingPlatform` com `mocktail` e stubs ad-hoc) em conformidade integral com o Princípio V do `AGENTS.md`.

## Capabilities

### New Capabilities
- `smoke-test-pos-build`: Validação funcional automatizada pós-build em Android Emulator KVM e iOS Simulator exercitando login OIDC nativo, cofre criptográfico ECDSA, FFmpeg, WebP, PDF e geração/visualização de EPUB 3 assinado via compilação condicional estritamente ausente dos binários das lojas.

### Modified Capabilities
- `app-release-pipeline`: Evolução do pipeline de release unificado para topologia transacional (build e smoke test antes do corte atômico de tag/versão e publicação nas lojas) e suporte ao modo de validação sem publicação nas lojas (`publicar_nas_lojas`).

## Impact

- **Código Dart (`app/lib/core/smoke_ci/` e `app/tool/release_tools/`)**: Novo módulo de auto-execução da jornada de smoke isolado fora do grafo de `lib/main.dart`, servidor HTTP local OIDC/GoTrue e utilitários CLI de auditoria binária e orquestração de emulador/simulador, com 100% de espelhamento e cobertura em `app/test/`.
- **Camada Nativa (`app/android/app/build.gradle.kts`, `MainActivity.kt` e `app/ios/Runner/AppDelegate.swift`)**: Guarda de compilação condicional (`BuildConfig.ARESTA_SMOKE_CI` + verificação de hardware QEMU no Android; `#if targetEnvironment(simulator)` no iOS) para emissão de token OIDC via loopback exclusivamente em ambiente de emulador/simulador de CI.
- **CI/CD (`.github/workflows/release_new_app_version.yml`, `build_android.yml`, `build_ios.yml`)**: Separação entre estágios `build_e_smoke` e `publicar`, corte transacional de versão via `git push --atomic` e suíte `pipeline_ci_android_test.dart` atualizada.
