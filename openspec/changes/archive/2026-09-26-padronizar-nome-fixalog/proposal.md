## Why

A aplicação foi originalmente concebida sob o nome e repositório `fixalog`, mas decisões intermediárias introduziram variações de nomenclatura como `FixLog` e identificadores como `com.arestaclimb.fixlog`. Sob as óticas de Gestão de Produto (@pm) e Design UX/UI (@ux), o nome `FixLog` remete a utilitários estéreis de tecnologia da informação (como *changelog* ou *syslog*), enquanto a identidade `Fixalog` estabelece um substantivo fluido, de sonoridade internacional (rimando com termos conceituados como *Catalog* e *Travelog*) e com forte personalidade para o ecossistema de montanha e escalada.

Considerando que o aplicativo ainda não foi publicado nas lojas públicas (Google Play e Apple App Store), este é o momento ideal para alinhar completamente todos os identificadores de sistema (`applicationId`, `PRODUCT_BUNDLE_IDENTIFIER`, namespace Dart, pacotes Kotlin e workflows de CI/CD) sem incorrer em quebras de retrocompatibilidade ou débitos técnicos futuros.

## What Changes

- **Padronização da Marca**: Adoção oficial e unificada do nome `Fixalog` (Titlecase contínuo) em todas as telas, cabeçalhos, diálogos, telas de carregamento, laudos, relatórios técnicos em PDF/EPUB e documentos legais.
- **Identificadores Nativos Android**:
  - Atualização do `namespace` e `applicationId` para `com.arestaclimb.fixalog` em `app/android/app/build.gradle.kts`.
  - Migração do pacote Kotlin e movimentação do arquivo `MainActivity.kt` para o diretório `app/android/app/src/main/kotlin/com/arestaclimb/fixalog/MainActivity.kt`.
  - Atualização do rótulo `android:label` para `Fixalog` em `AndroidManifest.xml`.
- **Identificadores Nativos iOS**:
  - Atualização de `PRODUCT_BUNDLE_IDENTIFIER` para `com.arestaclimb.fixalog` em `app/ios/Runner.xcodeproj/project.pbxproj`.
  - Configuração de `CFBundleDisplayName` para `Fixalog` e `CFBundleName` para `fixalog` no `Info.plist`.
- **Automação de CI/CD (GitHub Actions)**:
  - Atualização de `packageName` para `com.arestaclimb.fixalog` em `.github/workflows/build_android.yml`.
  - Atualização de `--bundle-id` e chaves de provisionamento para `com.arestaclimb.fixalog` em `.github/workflows/build_ios.yml`.
- **Módulo e Ecossistema Dart**:
  - Atualização de `name` para `fixalog` em `app/pubspec.yaml`.
  - Refatoração global de imports de `package:fixlog/...` para `package:fixalog/...` em todo o código-fonte (`lib/`), testes unitários (`test/`) e testes de integração (`integration_test/`).
  - Renomeação do widget raiz de `FixLogApp` para `FixalogApp` e título do aplicativo no `MaterialApp` para `'Fixalog'`.
- **Cabeçalhos de Licença SPDX e Governança**:
  - Padronização da linha de copyright autoral para `// Copyright (c) 2026 Fixalog Contributors` em todos os arquivos Dart e Kotlin.
  - Atualização do teste de conformidade arquitetural `app/test/architecture/license_headers_test.dart`.
- **Laudos Técnicos, Mídias e URL Canônica**:
  - Atualização da URL canônica dos relatórios para `https://fixalog.app/v/$sid` em `PdfPrintSummaryService`, `EpubDocumentBuilder` e `VisualizadorRelatorioScreen`.
  - Padronização de textos e assuntos de compartilhamento (EPUB 3 / PDF) em `VisualizadorRelatorioScreen`, `GenerationProgressDialog`, `WizardScreen` e `GenerationProvider`.
- **Emissão de Certificados X.509**:
  - Atualização do campo Organization (`O`) gerado pelo `CryptoService` de `'FixLog'` para `'Fixalog'`.
- **Ferramentas e Submódulo Legal**:
  - Atualização do pacote autônomo `ferramentas/atualizador_legal/` para referenciar `Fixalog`.
  - Preservação da compatibilidade de assets com o submódulo `app/legal/repo` (repositório upstream `arestaclimb.com`), apresentando `Fixalog` nos textos de interface.
- **Testes e Garantia de Qualidade (@qa)**:
  - Manutenção de 100% de cobertura de testes unitários e aprovação integral de todos os testes de integração, arquitetura e conformidade de licença.

## Capabilities

### Modified Capabilities
- `app-branding-identity`: Atualiza os requisitos de nomenclatura e identificadores do aplicativo para adotar `com.arestaclimb.fixalog` no Android, iOS e CI/CD, `fixalog` no pubspec, `Fixalog` como nome oficial de exibição e classe raiz `FixalogApp`, cabeçalhos SPDX padronizados e URLs canônicas em `fixalog.app`.

## Impact

- **Código Nativo e CI/CD**:
  - `app/android/app/build.gradle.kts`
  - `app/android/app/src/main/AndroidManifest.xml`
  - `app/android/app/src/main/kotlin/com/arestaclimb/fixalog/MainActivity.kt` (caminho movido)
  - `app/ios/Runner.xcodeproj/project.pbxproj`
  - `app/ios/Runner/Info.plist`
  - `.github/workflows/build_android.yml`
  - `.github/workflows/build_ios.yml`
- **Código Flutter/Dart**:
  - `app/pubspec.yaml`
  - `app/lib/main.dart`
  - Mais de 100 arquivos em `app/lib/`, `app/test/` e `app/integration_test/` com importações `package:fixlog/...`.
  - Mais de 180 arquivos com cabeçalhos `// Copyright (c) 2026 FixLog Contributors`.
  - Telas e serviços de laudo: `visualizador_relatorio_screen.dart`, `generation_progress_dialog.dart`, `wizard_screen.dart`, `generation_provider.dart`, `crypto_service.dart`, `pdf_print_summary_service.dart`, `epub_document_builder.dart`.
- **Ferramentas**:
  - `ferramentas/atualizador_legal/pubspec.yaml` e arquivos de teste/binário associados.
- **Documentação e OpenSpec**:
  - Atualização da especificação principal em `openspec/specs/app-branding-identity/spec.md`.
