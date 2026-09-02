## 1. Rebranding do Pacote Dart, Código e Nomenclatura FixLog

- [x] 1.1 Atualizar `pubspec.yaml` com o nome `name: fixlog` e adicionar as dependências `flutter_launcher_icons` e `flutter_native_splash` como `dev_dependencies`.
- [x] 1.2 Atualizar todos os imports de `package:app/` para `package:fixlog/` em `app/lib/`, `app/test/` e `app/integration_test/`.
- [x] 1.3 Substituir todas as referências ao termo `FixaLog` por `FixLog` em `app/lib/`, `app/test/`, `app/integration_test/` e `README.md` (renomeando classe `FixLogApp`, textos de UI, diálogos, títulos e `O=FixLog` no certificado X.509).
- [x] 1.4 Atualizar as asserções dos testes unitários correspondentes (ex: verificação de `FixLog` em `app/test/core/services/crypto_service_test.dart`).
- [x] 1.5 Executar `flutter test --coverage` e validar com `check_cov.dart` para assegurar 100% de cobertura nos testes unitários após a renomeação (Princípio III de `PRINCIPIOS.md`).
- [x] 1.6 Validar a integridade sintática e de imports dos testes de integração em `app/integration_test/` utilizando `FixLogApp` (Princípio V de `PRINCIPIOS.md`).

## 2. Identidade Visual e Assets Temporários

- [x] 2.1 Criar asset gráfico de alta resolução temporário com a identidade do FixLog (fundo grafite `#121416` e elemento em laranja resgate `#FF6B00`).
- [x] 2.2 Configurar o bloco `flutter_launcher_icons` no `pubspec.yaml` e executar a geração dos ícones nativos Android e iOS.
- [x] 2.3 Configurar o bloco `flutter_native_splash` no `pubspec.yaml` e executar a geração da splash screen.

## 3. Configurações Nativas Android

- [x] 3.1 Atualizar `namespace` e `applicationId` para `com.arestaclimb.fixlog` no arquivo `app/android/app/build.gradle.kts`.
- [x] 3.2 Refatorar o pacote da `MainActivity.kt` e mover o arquivo para a pasta `app/android/app/src/main/kotlin/com/arestaclimb/fixlog/MainActivity.kt`.
- [x] 3.3 Atualizar o atributo `android:label` para `FixLog` no `app/android/app/src/main/AndroidManifest.xml`.
- [x] 3.4 Configurar o bloco `signingConfigs` no `app/android/app/build.gradle.kts` para suportar leitura de variáveis de ambiente (`KEY_ALIAS`, `KEY_PASSWORD`, etc.) com fallback para o arquivo local `key.properties`.

## 4. Configurações Nativas iOS

- [x] 4.1 Atualizar `PRODUCT_BUNDLE_IDENTIFIER` para `com.arestaclimb.fixlog` em todas as configurações do `app/ios/Runner.xcodeproj/project.pbxproj`.
- [x] 4.2 Atualizar `CFBundleDisplayName` e `CFBundleName` para `FixLog` no arquivo `app/ios/Runner/Info.plist`.
- [x] 4.3 Inserir a chave `ITSAppUsesNonExemptEncryption` com valor `<false/>` no `app/ios/Runner/Info.plist`.

## 5. Workflows de CI/CD (GitHub Actions) em Português

- [x] 5.1 Criar o workflow orquestrador `.github/workflows/release_new_app_version.yml` configurado para o diretório `./app`, bump de versão semântica, mensagens de commit em português e disparo em cascata.
- [x] 5.2 Criar o sub-workflow `.github/workflows/build_android.yml` com suporte a Java 17, Flutter, Rust toolchain (targets NDK), compilação do `.aab` e upload para a faixa interna do Google Play.
- [x] 5.3 Criar o sub-workflow `.github/workflows/build_ios.yml` com suporte a macOS runner, Xcode, Rust toolchain (targets iOS), importação segura de certificados no Keychain e upload para TestFlight via `xcrun altool`.

## 6. Verificação e Conformidade com PRINCIPIOS.md

- [x] 6.1 Executar `flutter analyze` no diretório `app/` garantindo zero warnings ou erros de lint.
- [x] 6.2 Executar `flutter test --coverage` e validar com `dart check_cov.dart` assegurando 100% de cobertura de testes unitários (inegociável).
