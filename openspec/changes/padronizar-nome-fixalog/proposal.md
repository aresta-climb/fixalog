## Why

A aplicação foi originalmente concebida sob o nome e repositório `fixalog`, mas decisões intermediárias introduziram variações de nomenclatura como `FixLog` e identificadores como `com.arestaclimb.fixlog`. Sob as óticas de Gestão de Produto (@pm) e Design UX/UI (@ux), o nome `FixLog` remete a utilitários estéreis de tecnologia da informação (como *changelog* ou *syslog*), enquanto a identidade `Fixalog` estabelece um substantivo fluido, de sonoridade internacional (rimando com termos conceituados como *Catalog* e *Travelog*) e com forte personalidade para o ecossistema de montanha e escalada.

Considerando que o aplicativo ainda não foi publicado nas lojas públicas (Google Play e Apple App Store), este é o momento ideal para alinhar completamente todos os identificadores de sistema (`applicationId`, `PRODUCT_BUNDLE_IDENTIFIER`, namespace Dart e pacotes Kotlin) sem incorrer em quebras de retrocompatibilidade ou débitos técnicos futuros.

## What Changes

- **Padronização da Marca**: Adoção oficial e unificada do nome `Fixalog` (Titlecase contínuo) em todas as telas, cabeçalhos, diálogos, telas de carregamento, laudos, relatórios técnicos em PDF/EPUB e documentos legais.
- **Identificadores Nativos Android**:
  - Atualização do `namespace` e `applicationId` para `com.arestaclimb.fixalog` em `app/android/app/build.gradle.kts`.
  - Migração do pacote Kotlin e movimentação do arquivo `MainActivity.kt` para o diretório `app/android/app/src/main/kotlin/com/arestaclimb/fixalog/MainActivity.kt`.
  - Atualização do rótulo `android:label` para `Fixalog` em `AndroidManifest.xml`.
- **Identificadores Nativos iOS**:
  - Atualização de `PRODUCT_BUNDLE_IDENTIFIER` para `com.arestaclimb.fixalog` em `app/ios/Runner.xcodeproj/project.pbxproj`.
  - Configuração de `CFBundleDisplayName` para `Fixalog` e `CFBundleName` para `fixalog` no `Info.plist`.
- **Módulo e Ecossistema Dart**:
  - Atualização de `name` para `fixalog` em `app/pubspec.yaml`.
  - Refatoração global de imports de `package:fixlog/...` para `package:fixalog/...` em todo o código-fonte (`lib/`), testes unitários (`test/`) e testes de integração (`integration_test/`).
  - Renomeação do widget raiz de `FixLogApp` para `FixalogApp` e título do aplicativo no `MaterialApp` para `'Fixalog'`.
- **Ferramentas e Auditoria Legal**:
  - Atualização do pacote `ferramentas/atualizador_legal/` e documentações de termos de uso para referenciar `Fixalog`.
- **Testes e Garantia de Qualidade (@qa)**:
  - Manutenção de 100% de cobertura de testes unitários e aprovação integral de todos os testes de integração e conformidade de licença.

## Capabilities

### Modified Capabilities
- `app-branding-identity`: Atualiza os requisitos de nomenclatura e identificadores do aplicativo para adotar `com.arestaclimb.fixalog` no Android/iOS, `fixalog` no pubspec e `Fixalog` como nome oficial de exibição e classe raiz `FixalogApp`.

## Impact

- **Código Nativo**:
  - `app/android/app/build.gradle.kts`
  - `app/android/app/src/main/AndroidManifest.xml`
  - `app/android/app/src/main/kotlin/com/arestaclimb/fixalog/MainActivity.kt` (caminho movido)
  - `app/ios/Runner.xcodeproj/project.pbxproj`
  - `app/ios/Runner/Info.plist`
- **Código Flutter/Dart**:
  - `app/pubspec.yaml`
  - `app/lib/main.dart`
  - Aproximadamente 50 arquivos em `app/lib/`, `app/test/` e `app/integration_test/` com importação de pacote.
- **Ferramentas**:
  - `ferramentas/atualizador_legal/pubspec.yaml` e arquivos de teste/binário associados.
- **Documentação e OpenSpec**:
  - Atualização da especificação principal em `openspec/specs/app-branding-identity/spec.md`.
