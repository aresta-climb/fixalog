## Context

O projeto nasceu com o nome e repositório `fixalog`, mas durante iterações de desenvolvimento foram introduzidos identificadores técnicos e textos visíveis com `FixLog` (por exemplo, `package:fixlog`, `com.arestaclimb.fixlog`, `FixLogApp`, workflows de CI e menções a relatórios). Conforme deliberado em exploração técnica e de produto (@pm e @ux), o nome oficial adotado é **Fixalog** (em Titlecase corrido), e como a aplicação ainda não foi disponibilizada ao público geral nas lojas, todos os identificadores nativos, lógicos, de CI/CD e de governança devem ser sincronizados.

## Goals / Non-Goals

**Goals:**
- Unificar a identidade visual, textual e de marca da aplicação sob o nome `Fixalog`.
- Alterar o `applicationId` e `namespace` do Android para `com.arestaclimb.fixalog` e mover a classe `MainActivity.kt`.
- Alterar o `PRODUCT_BUNDLE_IDENTIFIER` do iOS para `com.arestaclimb.fixalog` e ajustar o `CFBundleDisplayName` para `Fixalog`.
- Sincronizar os workflows de CI/CD em `.github/workflows/` (`build_android.yml` e `build_ios.yml`) com o novo identificador de pacote.
- Renomear o pacote Flutter no `pubspec.yaml` para `name: fixalog` e atualizar todos os imports internos de `package:fixlog/...` para `package:fixalog/...`.
- Renomear o widget principal da aplicação de `FixLogApp` para `FixalogApp`.
- Atualizar títulos de telas, diálogos de conclusão, assuntos de compartilhamento de laudos, metadados de certificados e utilitários legais (`ferramentas/atualizador_legal/`).
- Atualizar a URL canônica dos relatórios técnicos para `https://fixalog.app/v/$sid`.
- Padronizar os cabeçalhos SPDX/MPL-2.0 para `// Copyright (c) 2026 Fixalog Contributors` e sincronizar o teste arquitetural `license_headers_test.dart`.
- Assegurar 100% de aprovação na suíte de testes unitários e de integração, mantendo a cobertura de testes em 100% conforme o `PRINCIPIOS.md`.

**Non-Goals:**
- Não serão feitas alterações estruturais de regras de negócio, layouts de telas ou banco de dados Isar além das atualizações de nomes e imports.
- Não serão alterados os identificadores de outros apps do ecossistema (como `com.arestaclimb.app`).
- Não serão alterados os nomes de arquivos físicos no submódulo upstream `app/legal/repo` (vinculado ao repositório `arestaclimb.com`), mantendo a compatibilidade dos caminhos de asset.

## Decisions

### 1. Adoção da Marca "Fixalog" (Titlecase)
- **Decisão**: Usar `Fixalog` em vez de `FixaLog` (CamelCase) ou `FixLog`.
- **Racional**: Proporciona uma silhueta visual suave (*Bouma shape* contínuo), sonoridade fluida em inglês (sem cortes consonantais bruscos e rimando com *Catalog* e *Travelog*), fácil digitação em smartphones e alinhamento com marcas de esporte/outdoor consagradas.
- **Alternativas consideradas**: `FixaLog` (descartado por fragmentar o nome em dois blocos e dificultar a digitação móvel) e `FixLog` (descartado por soar a utilitário de TI / rastreador de bugs).

### 2. Migração de Identificadores Nativos Móveis e CI/CD
- **Decisão**: Alterar os identificadores nativos para `com.arestaclimb.fixalog` tanto no Android quanto no iOS, bem como nas automações de build/deploy do GitHub Actions.
- **Racional**: Como o app ainda não foi submetido ou lançado publicamente nas lojas de aplicativos, esta é a oportunidade definitiva para estabelecer o identificador correto, evitando discrepâncias permanentes nas lojas e falhas nos pipelines de entrega contínua.
- **Impacto no Android**:
  - `build.gradle.kts`: `namespace = "com.arestaclimb.fixalog"`, `applicationId = "com.arestaclimb.fixalog"`.
  - Estrutura de diretórios: `app/android/app/src/main/kotlin/com/arestaclimb/fixalog/MainActivity.kt`.
  - Workflows: `.github/workflows/build_android.yml` (`packageName: com.arestaclimb.fixalog`).
- **Impacto no iOS**:
  - `Runner.xcodeproj/project.pbxproj`: `PRODUCT_BUNDLE_IDENTIFIER = com.arestaclimb.fixalog;`.
  - `Info.plist`: `CFBundleDisplayName = Fixalog`, `CFBundleName = fixalog`.
  - Workflows: `.github/workflows/build_ios.yml` (`--bundle-id "com.arestaclimb.fixalog"`).

### 3. Renomeação do Módulo Dart e Imports
- **Decisão**: Atualizar o `app/pubspec.yaml` para `name: fixalog` e substituir todas as ocorrências de `package:fixlog/` por `package:fixalog/`.
- **Racional**: O ecossistema Dart utiliza o campo `name` do `pubspec.yaml` como raiz dos imports absolutos. Manter o nome do pacote idêntico ao nome do aplicativo e do repositório garante clareza máxima e previsibilidade para os desenvolvedores e agentes de IA.

### 4. Renomeação da Classe Raiz e Textos Visíveis
- **Decisão**: Renomear `FixLogApp` para `FixalogApp` em `app/lib/main.dart`, atualizar o título do `MaterialApp` para `'Fixalog'`, e atualizar diálogos de progresso (`'Selando Laudo Fixalog'`), fallbacks (`'Relatório Fixalog'`) e assuntos de compartilhamento (`'Relatório Técnico Fixalog (EPUB 3)'` e `'Relatório Técnico Resumido Fixalog (PDF)'`).

### 5. Padronização dos Cabeçalhos SPDX e Governança
- **Decisão**: Atualizar a linha de copyright autoral para `// Copyright (c) 2026 Fixalog Contributors` em todos os arquivos autorais Dart e Kotlin, ajustando a constante `expectedLine2` em `license_headers_test.dart`.
- **Racional**: Manter a coerência autoral e jurídica em todo o código-fonte, garantindo que o teste de conformidade de licença continue validando o repositório com 100% de precisão.

### 6. Domínio Canônico de Relatórios e Metadados X.509
- **Decisão**: Atualizar a URL canônica para `https://fixalog.app/v/$sid` e o campo Organization do certificado X.509 gerado pelo `CryptoService` para `'Fixalog'`.
- **Racional**: O relatório exportado e seu QR Code devem refletir a identidade definitiva da plataforma.

### 7. Isolamento de Assets do Submódulo Legal
- **Decisão**: Preservar os caminhos dos assets `legal/repo/public/docs/termos-de-uso-fixlog.md` e `politica-de-privacidade-fixlog.md`, enquanto a interface e os termos de consentimento referenciam a marca `Fixalog`.
- **Racional**: Evita quebras ou estado sujo no submódulo Git upstream até que o repositório central `arestaclimb.com` seja atualizado.

## Risks / Trade-offs

- **[Risco] Imports quebrados em arquivos não mapeados**:
  - *Mitigação*: Uso de busca e substituição rigorosa no projeto e execução de `flutter analyze` e `flutter test` cobrindo 100% do código para garantir que nenhuma dependência quebrada passe despercebida.
- **[Risco] Incompatibilidade de cache do Gradle ou Flutter após renomear pacote nativo**:
  - *Mitigação*: Execução de `flutter clean` seguido de `flutter pub get` para reconstruir os vínculos do build nativo e assets.
- **[Risco] Falha no teste de cabeçalhos de licença**:
  - *Mitigação*: Atualização atômica do teste de arquitetura `license_headers_test.dart` e substituição simultânea nos arquivos autorais.

## Migration Plan

1. Atualizar o `app/pubspec.yaml` (`name: fixalog`).
2. Executar script/substituição de `package:fixlog/` para `package:fixalog/` em `lib/`, `test/` e `integration_test/`.
3. Renomear `FixLogApp` -> `FixalogApp` e títulos em `main.dart` e testes.
4. Mover a pasta e o arquivo `MainActivity.kt` no Android e atualizar `build.gradle.kts` e `AndroidManifest.xml`.
5. Atualizar os identificadores no projeto iOS (`project.pbxproj` e `Info.plist`).
6. Atualizar os identificadores nos workflows do GitHub Actions (`.github/workflows/build_android.yml` e `build_ios.yml`).
7. Atualizar cabeçalhos de copyright SPDX e sincronizar `license_headers_test.dart`.
8. Atualizar strings de UI, assuntos de laudos, fallbacks, `O=Fixalog` no `CryptoService` e URL canônica `fixalog.app`.
9. Atualizar referências textuais e de teste em `ferramentas/atualizador_legal/`.
10. Executar `flutter clean && flutter pub get`.
11. Rodar testes de unidade (`flutter test --coverage`), testes de arquitetura e análise estática (`flutter analyze`).
