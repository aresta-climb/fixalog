## Purpose

Define a identidade visual, convenção de nomes de pacotes, identificadores nativos e padrões de branding do Fixalog nas plataformas suportadas.

## Requirements

### Requirement: Oficialização do Nome e Identificadores do Pacote
A aplicação DEVE utilizar o identificador de pacote `com.arestaclimb.fixalog` e o nome visível `Fixalog` em todas as plataformas móveis suportadas (Android e iOS), no módulo Dart (`fixalog`) e nos pipelines de CI/CD.

#### Scenario: Identificadores no Android
- **WHEN** o projeto Android for inspecionado ou compilado
- **THEN** o `namespace` e o `applicationId` no `build.gradle.kts` DEVEM ser `com.arestaclimb.fixalog`, a `MainActivity` DEVE estar no pacote correspondente e o `android:label` no `AndroidManifest.xml` DEVE ser `Fixalog`

#### Scenario: Identificadores no iOS
- **WHEN** o projeto iOS for inspecionado ou compilado no Xcode
- **THEN** o `PRODUCT_BUNDLE_IDENTIFIER` DEVE ser `com.arestaclimb.fixalog` e as chaves `CFBundleDisplayName` e `CFBundleName` no `Info.plist` DEVEM ser `Fixalog`

#### Scenario: Identificadores nos Workflows de CI/CD
- **WHEN** os fluxos de automação do GitHub Actions forem verificados
- **THEN** o `packageName` no `.github/workflows/build_android.yml` e o `--bundle-id` no `.github/workflows/build_ios.yml` DEVEM ser `com.arestaclimb.fixalog`

#### Scenario: Identificador do Pacote Dart
- **WHEN** os arquivos do projeto Flutter forem analisados
- **THEN** o campo `name` no `pubspec.yaml` DEVE ser `fixalog` e todos os imports internos do projeto DEVEM referenciar `package:fixalog/...`

### Requirement: Unificação Global da Nomenclatura FixLog
Todas as referências legadas ao termo `FixLog` DEVEM ser substituídas por `Fixalog` em todo o código-fonte, títulos de telas, classes, diálogos, termos de uso, certificados autoassinados e relatórios gerados.

#### Scenario: Renomeação da Classe Raiz e Título
- **WHEN** o arquivo `main.dart` for executado
- **THEN** o widget principal DEVE ser a classe `FixalogApp` e a propriedade `title` do `MaterialApp` DEVE ser `'Fixalog'`

#### Scenario: Emissão de Certificados X.509
- **WHEN** um certificado autoassinado for emitido pelo `CryptoService`
- **THEN** o campo Organization (`O`) no Subject DEVE ser preenchido com `'Fixalog'`

#### Scenario: Textos de Interface e Diálogos
- **WHEN** diálogos de selagem, telas de introdução, termos e relatórios forem exibidos
- **THEN** todo o texto visível e assuntos de compartilhamento DEVEM utilizar a grafia `'Fixalog'`

#### Scenario: URL Canônica de Relatórios Técnicos
- **WHEN** um relatório técnico for exportado ou tiver seu QR Code gerado
- **THEN** a URL canônica padrão DEVE ser estruturada sob o domínio `'https://fixalog.app/v/<id>'`

#### Scenario: Cabeçalhos de Licença SPDX
- **WHEN** o teste de conformidade `license_headers_test.dart` for executado
- **THEN** todos os arquivos Dart e Kotlin autorais DEVEM conter o cabeçalho `// Copyright (c) 2026 Fixalog Contributors`

### Requirement: Assets de Ícones e Splash Screen
A aplicação DEVE conter assets de ícone de lançador e splash screen configurados com a identidade visual do Fixalog (cores `#121416` e `#FF6B00`).

#### Scenario: Geração de Ícones do Aplicativo
- **WHEN** o comando de geração de ícones for executado via `flutter_launcher_icons`
- **THEN** os ícones de aplicativo em todas as densidades (incluindo Adaptive Icons para Android e AppIcon set para iOS) DEVEM ser gerados sem erros a partir da imagem base

#### Scenario: Configuração de Splash Screen
- **WHEN** o comando de geração de splash screen for executado via `flutter_native_splash`
- **THEN** as telas nativas de carregamento para Android (inclusive Android 12+) e iOS DEVEM exibir o tema do Fixalog

### Requirement: Preservação de Testes e Cobertura Integral
A renomeação global e ajuste de pacotes DEVEM manter a integridade total da suíte de testes unitários e de integração, garantindo 100% de cobertura conforme o `PRINCIPIOS.md`.

#### Scenario: Execução de Testes Unitários com Cobertura
- **WHEN** o comando `flutter test --coverage` for executado após o rebranding
- **THEN** todos os testes unitários DEVEM ser executados com sucesso e a cobertura de linhas DEVE ser de 100%

#### Scenario: Validação de Testes de Integração
- **WHEN** os testes em `integration_test/` forem verificados
- **THEN** nenhum import quebrado DEVE existir e os cenários de integração DEVEM permanecer válidos com `FixalogApp`
