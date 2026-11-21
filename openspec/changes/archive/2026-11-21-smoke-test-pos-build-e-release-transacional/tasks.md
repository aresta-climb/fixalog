# Tasks

## 1. Módulo de Jornada Smoke e Limpeza Anti-Mocking no Aplicativo

- [x] 1.1 Refatorar `app/integration_test/generation_flow_test.dart` substituindo `mocktail` e stubs ad-hoc pelas bibliotecas determinísticas `*_fake.dart` existentes (com testes espelhados 100% verdes via `flutter test`)
- [x] 1.2 Implementar em TDD (`app/lib/core/smoke_ci/configuracao_smoke_ci.dart` e `app/test/core/smoke_ci/configuracao_smoke_ci_test.dart`) a leitura e validação estrita de loopback (`127.0.0.1`, `localhost`, `10.0.2.2`) e token efêmero via `MethodChannel` de smoke, verificando 100% de cobertura
- [x] 1.3 Implementar em TDD (`app/lib/core/smoke_ci/executor_jornada_smoke.dart`, `app/lib/core/smoke_ci/main_smoke_ci.dart` e respectivos `_test.dart`) o executor da jornada pericial ponta a ponta (aceite de Termos no SQLite, chaves ECDSA no `FlutterSecureStorage`, login OIDC, certificado X.509, mídia foto/vídeo/PDF, geração e assinatura XML-DSig do `.epub`, extração/abertura e envio de `POST /__smoke__/relatorio`) mantendo `lib/main.dart` sem referências a smoke e atualizando `README.md`
- [x] 1.4 Adicionar teste arquitetural garantindo que `app/lib/main.dart` e os módulos de produção fora de `core/smoke_ci/` jamais importam `core/smoke_ci/`

## 2. Guardas de Compilação Condicional Nativa (Android e iOS)

- [x] 2.1 Configurar `buildFeatures { buildConfig = true }` e `BuildConfig.ARESTA_SMOKE_CI` (padrão `false`, ativável via `-ParestaSmokeCi=true` / `ORG_GRADLE_PROJECT_arestaSmokeCi=true`) em `app/android/app/build.gradle.kts` e implementar em `MainActivity.kt` o canal `com.arestaclimb.fixalog/smoke_ci` e o desvio OIDC loopback restritos a `BuildConfig.ARESTA_SMOKE_CI && ehEmuladorAndroid()`, validando conformidade SPDX via `license_headers_test.dart`
- [x] 2.2 Implementar em `app/ios/Runner/AppDelegate.swift`, estritamente dentro de `#if targetEnvironment(simulator)`, a leitura de `ARESTA_SMOKE_SERVER`/`ARESTA_SMOKE_TOKEN` em loopback, o canal `com.arestaclimb.fixalog/smoke_ci` e o desvio OIDC local com cálculo `sha256Hex(rawNonce)` nativo

## 3. Ferramentas CLI de Auditoria Binária, Servidor Loopback e Orquestrador Smoke

- [x] 3.1 Implementar em TDD (`app/tool/release_tools/auditar_binario_loja.dart` e `app/test/tool/release_tools/auditar_binario_loja_test.dart`) o auditor de `.aab` e `.ipa` oficiais verificando ausência absoluta de marcadores de smoke e presença de bibliotecas nativas obrigatórias e `ITSAppUsesNonExemptEncryption=false`
- [x] 3.2 Implementar em TDD (`app/tool/release_tools/servidor_smoke_ci.dart` e `app/test/tool/release_tools/servidor_smoke_ci_test.dart`) o micro-servidor HTTP loopback OIDC/GoTrue (`/__smoke__/oidc-token`, `/auth/v1/token` validando `SHA-256(rawNonce)`, rotas REST/Storage mínimas e `/__smoke__/relatorio`)
- [x] 3.3 Implementar em TDD (`app/tool/release_tools/smoke_test_pacote.dart` e `app/test/tool/release_tools/smoke_test_pacote_test.dart`) o orquestrador CLI multiplataforma (`android` com `bundletool` Cold Start do `.aab` puro + execução do APK de smoke via `adb`; `ios` com auditoria `codesign`/`otool` do `.ipa` + execução no Simulator via `xcrun simctl`, incluindo desofuscação via `flutter symbolize` em caso de falha)

## 4. Topologia Transacional de Release nos Workflows GitHub Actions e Validação

- [x] 4.1 Reestruturar `.github/workflows/release_new_app_version.yml`, `.github/workflows/build_android.yml` e `.github/workflows/build_ios.yml` para a topologia de 4 estágios (`validar_e_preparar` sem push -> `build_e_smoke` Android KVM e iOS Simulator -> `cortar_versao` com `git push --atomic` -> `publicar` nas lojas/Sentry/Crashlytics), adicionando o input `publicar_nas_lojas` (padrão `true`)
- [x] 4.2 Atualizar `app/test/architecture/pipeline_ci_android_test.dart` validando os novos estágios transacionais, o input `publicar_nas_lojas`, a auditoria binária, o smoke test e a paridade de publicação, e executar `flutter analyze --fatal-infos --fatal-warnings` e `flutter test --coverage` com 100% de aprovação
