# Pipeline de Lançamento do Aplicativo

## Purpose

Define a esteira automatizada de CI/CD do GitHub Actions para versionamento semântico, compilação multiplataforma (Android e iOS), upload de símbolos de telemetria e publicação automatizada no Google Play Console e App Store Connect (TestFlight e revisão da App Store).

## Requirements

### Requirement: Suporte Híbrido de Assinatura Android e Conformidade iOS
O projeto Android DEVE suportar assinatura de release via variáveis de ambiente e arquivo local, habilitar minificação/otimização R8 em modo completo (`isMinifyEnabled = true`, `isShrinkResources = true`, `android.enableR8.fullMode=true`, `android.r8.optimizedResourceShrinking=true`) com regras ProGuard (`proguard-rules.pro`) preservando metadados de stacktrace e incluir tabela de símbolos nativos (`ndk.debugSymbolLevel = "SYMBOL_TABLE"`) no `.aab` de release; e o projeto iOS DEVE declarar conformidade de criptografia adequada para distribuição automatizada no TestFlight.

#### Scenario: Assinatura de Release e Símbolos Nativos no Gradle
- **WHEN** o build de release Android for executado em ambiente com variáveis de ambiente ou com arquivo `key.properties`
- **THEN** o `build.gradle.kts` DEVE utilizar essas credenciais, aplicar `proguard-rules.pro` com R8 full mode e embutir `debugSymbolLevel = "SYMBOL_TABLE"` para gerar um artefato `.aab` assinado e simbolizado

#### Scenario: Conformidade de Criptografia no iOS
- **WHEN** o pacote iOS for inspecionado para upload no TestFlight
- **THEN** a chave `ITSAppUsesNonExemptEncryption` com valor booleano `false` DEVE estar presente no `Info.plist`

### Requirement: Automação de CI/CD para Google Play e TestFlight
O repositório DEVE (MUST) possuir fluxos automatizados do GitHub Actions em paridade com o ecossistema Aresta (`release_new_app_version.yml`, `build_android.yml`, `build_ios.yml`, `submit_ios_review.yml` e `atualizar_termos_legais.yml`) apoiados por ferramentas determinísticas de versionamento SemVer em Dart (`app/tool/release_tools/`) com espelhamento 1:1 de testes unitários:
1. O workflow orquestrador `release_new_app_version.yml` DEVE receber `bump_type` (`patch`, `minor`, `major`, `custom`), `custom_version`, `enviar_para_producao` e `release_notes`, validar no primeiro passo que `release_notes` possui no máximo 500 caracteres, calcular a versão de release via `calcular_versao_release.dart`, sincronizar o submódulo `app/legal/repo` e a constante `versaoTermosLegaisAtuais`, gerar a tag `v<semver>+<build>`, avançar a branch principal para `<proximo_patch>-dev+<build+1>` via `calcular_proximo_dev.dart` e disparar `build_android`, `build_ios` e (quando `enviar_para_producao == true`) `submit_ios_review`;
2. O workflow `build_android.yml` DEVE compilar o `.aab` de release com `--obfuscate --split-debug-info=build/symbols`, enviar símbolos de debug ao Sentry (`sentry_dart_plugin`) e ao Firebase Crashlytics (`firebase-tools crashlytics:symbols:upload`), publicar os artefatos no GitHub Actions, gravar `build/whatsnew/whatsnew-pt-BR` e enviar o pacote para as faixas `internal,production` (quando `enviar_para_producao == true`) ou `internal` no Google Play;
3. Os workflows `build_ios.yml` e `submit_ios_review.yml` DEVEM compilar o `.ipa` com `<key>uploadSymbols</key><true/>`, enviar os `dSYMs` ao Firebase Crashlytics e símbolos ao Sentry, fazer upload da build para o App Store Connect via `xcrun altool --upload-app` (com `--apple-id "6818883254"`) e, quando `enviar_para_producao == true`, aguardar o processamento no TestFlight via Fastlane (`Fastfile` lane `submeter_revisao`) e submeter automaticamente a versão para revisão da Apple com as notas de lançamento.

#### Scenario: Disparo de Release Unificado
- **WHEN** o workflow `release_new_app_version.yml` é acionado com `bump_type = 'patch'`, `enviar_para_producao = true` e `release_notes` com até 500 caracteres
- **THEN** a esteira valida o tamanho das notas no primeiro passo, calcula a versão de release removendo o sufixo `-dev` e incrementando o build, atualiza os termos legais se houver novos commits, cria a tag Git `v<versao>+<build>`, avança o `pubspec.yaml` para o próximo ciclo `-dev` e aciona `build_android`, `build_ios` e `submit_ios_review`

#### Scenario: Falha Imediata quando Notas de Lançamento Excedem 500 Caracteres
- **WHEN** o workflow `release_new_app_version.yml` é acionado com `release_notes` contendo mais de 500 caracteres
- **THEN** o job `validar_inputs` falha em menos de 10 segundos antes de criar commits, tags ou iniciar compilações móveis

#### Scenario: Compilação e Deploy do Android
- **WHEN** o workflow `build_android.yml` é executado com `enviar_para_producao = true` e `release_notes` preenchido
- **THEN** o runner configura Java 17 e Flutter, gera o `.aab` ofuscado, envia símbolos ao Sentry e Crashlytics, preenche `whatsnew-pt-BR` e publica nas faixas `internal,production` da Google Play Store

#### Scenario: Compilação e Deploy do iOS
- **WHEN** o workflow `build_ios.yml` conclui o envio do `.ipa` para o TestFlight (`apple-id 6818883254`) e `enviar_para_producao` é `true`
- **THEN** o runner macOS envia os `dSYMs` ao Crashlytics e símbolos ao Sentry, publica o `.ipa` via `xcrun altool` e o workflow `submit_ios_review.yml` aguarda o processamento da build na Apple via `FastlaneCore::BuildWatcher` e executa `deliver` para submeter a versão à revisão da App Store com as notas em `pt-BR` e `default`
