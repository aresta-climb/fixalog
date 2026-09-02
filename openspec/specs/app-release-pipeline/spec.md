## ADDED Requirements

### Requirement: Suporte Híbrido de Assinatura Android e Conformidade iOS
O projeto Android DEVE suportar assinatura de release via variáveis de ambiente e arquivo local, e o projeto iOS DEVE declarar conformidade de criptografia adequada para distribuição automatizada no TestFlight.

#### Scenario: Assinatura de Release no Gradle
- **WHEN** o build de release Android for executado em ambiente com variáveis de ambiente ou com arquivo `key.properties`
- **THEN** o `build.gradle.kts` DEVE utilizar essas credenciais para gerar um artefato `.aab` assinado

#### Scenario: Conformidade de Criptografia no iOS
- **WHEN** o pacote iOS for inspecionado para upload no TestFlight
- **THEN** a chave `ITSAppUsesNonExemptEncryption` com valor booleano `false` DEVE estar presente no `Info.plist`

### Requirement: Automação de CI/CD para Google Play e TestFlight
O repositório DEVE possuir fluxos automatizados do GitHub Actions para versionamento, compilação de código nativo Rust e deploy automático nas faixas internas das lojas, escritos em conformidade com o `PRINCIPIOS.md`.

#### Scenario: Disparo de Release Unificado
- **WHEN** o workflow `release_new_app_version.yml` for acionado com um número de versão superior à versão atual
- **THEN** a esteira DEVE atualizar o `pubspec.yaml`, criar a tag Git correspondente, commitar o ciclo de desenvolvimento subsequente com mensagens em português e acionar as compilações de Android e iOS

#### Scenario: Compilação e Deploy do Android
- **WHEN** o workflow `build_android.yml` for executado
- **THEN** o runner DEVE configurar Java 17, Flutter, Rust toolchain com targets Android, compilar o bundle `.aab` e publicá-lo na faixa interna do Google Play Console

#### Scenario: Compilação e Deploy do iOS
- **WHEN** o workflow `build_ios.yml` for executado
- **THEN** o runner macOS DEVE configurar Xcode, Flutter, Rust toolchain com targets iOS, importar os certificados de assinatura e enviar o `.ipa` para o TestFlight via `xcrun altool`
