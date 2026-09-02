## Why

O aplicativo foi iniciado a partir de templates genéricos (`com.example.app` / nome `app`) e com variações legadas do nome (`FixaLog`), o que impede a publicação nas lojas de aplicativos (Google Play e Apple App Store) e gera inconsistência com a marca oficial **FixLog**. Além disso, o projeto necessita de uma esteira automatizada de CI/CD (GitHub Actions) adaptada da experiência do `aresta_app` para realizar compilação, versionamento e distribuição contínua para testes internos (Google Play Internal Testing e TestFlight), levando em consideração os requisitos nativos de compilação da biblioteca Rust (`cargokit`).

Todas as alterações propostas seguem rigorosamente os princípios de engenharia definidos no `PRINCIPIOS.md`, assegurando 100% de cobertura de testes unitários, testes de integração íntegros e escrita estritamente em português brasileiro.

## What Changes

- **Renomeação Completa e Identidade da Aplicação**:
  - Substituição de todas as ocorrências textuais, títulos, classes (ex: `FixaLogApp` → `FixLogApp`), diálogos, termos de uso, certificados criptográficos (`O=FixLog`) e laudos PDF de `FixaLog` para `FixLog` no app inteiro.
  - Alteração do Application ID e Package Name Android para `com.arestaclimb.fixlog`.
  - Alteração do Bundle Identifier iOS para `com.arestaclimb.fixlog`.
  - Alteração do nome de exibição (Display Name) para `FixLog` no Android (`AndroidManifest.xml`) e no iOS (`Info.plist`).
  - Atualização do nome do pacote Flutter no `pubspec.yaml` de `name: app` para `name: fixlog`, com refatoração de todos os imports `package:app/...` para `package:fixlog/...`.
  - Configuração de ícones de lançador (`flutter_launcher_icons`) e tela de abertura (`flutter_native_splash`) com identidade visual temporária estilizada baseada nas cores do FixLog (`#FF6B00` e `#121416`).
- **Configuração Nativa de Assinatura e Conformidade**:
  - Atualização do `build.gradle.kts` do Android com suporte híbrido para assinatura de release (lendo variáveis de ambiente no CI ou `key.properties` localmente).
  - Inclusão da chave `ITSAppUsesNonExemptEncryption` com valor `false` no `Info.plist` do iOS para desbloquear distribuição automatizada no TestFlight.
- **Esteira de CI/CD Automatizada (GitHub Actions)**:
  - Criação do workflow orquestrador `release_new_app_version.yml` com validação de versão semântica, incremento automático de build number, criação de tag e push de versão de desenvolvimento.
  - Criação do sub-workflow `build_android.yml` com suporte a Java 17, Flutter, Rust toolchain (targets NDK) e upload automático para a faixa interna do Google Play Console via conta de serviço.
  - Criação do sub-workflow `build_ios.yml` com suporte a macOS runner, Xcode, Rust toolchain (targets iOS), importação segura de certificados/provisioning profiles no Keychain e upload para TestFlight via `xcrun altool`.
- **Garantia de Qualidade e Conformidade com PRINCIPIOS.md**:
  - Manutenção de 100% de cobertura de testes unitários após todas as alterações de imports, pacotes e strings/asserções.
  - Validação dos testes de integração existentes em `integration_test/`.
  - Todos os comentários, documentações e mensagens em português brasileiro.

## Capabilities

### New Capabilities
- `app-branding-identity`: Configuração formal dos identificadores do pacote (`com.arestaclimb.fixlog`), unificação de todas as referências para `FixLog`, nomes de exibição, ícones adaptativos e splash screen.
- `app-release-pipeline`: Esteira automatizada de build, assinatura e distribuição de artefatos (.aab e .ipa) para Google Play Internal Testing e Apple TestFlight com suporte a compilação nativa Rust.

### Modified Capabilities
<!-- Nenhuma especificação funcional existente teve seus requisitos de negócio alterados. -->

## Impact

- **Código Dart/Flutter**: 
  - Atualização de todos os imports `package:app/*` para `package:fixlog/*` no diretório `app/lib/`, `app/test/` e `app/integration_test/`.
  - Substituição global de `FixaLog` por `FixLog` em classes, títulos de tela, certificados e diálogos.
- **Configurações Nativas**: Modificações em `app/android/app/build.gradle.kts`, `app/android/app/src/main/AndroidManifest.xml`, `MainActivity.kt` (movido para `com/arestaclimb/fixlog/`), `app/ios/Runner/Info.plist` e `app/ios/Runner.xcodeproj/project.pbxproj`.
- **Repositório**: Criação do diretório `.github/workflows/` com os arquivos de automação CI/CD.
- **Dependências**: Adição de `flutter_launcher_icons` e `flutter_native_splash` como `dev_dependencies` no `pubspec.yaml`.
- **Testes e Cobertura**: Atualização das asserções de testes (ex: `crypto_service_test.dart`) e verificação de 100% de cobertura via `flutter test --coverage` e `dart check_cov.dart`.
