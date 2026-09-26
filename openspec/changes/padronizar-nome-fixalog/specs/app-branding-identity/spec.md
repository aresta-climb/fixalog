## MODIFIED Requirements

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
