## Context

O projeto nasceu com o nome e repositório `fixalog`, mas durante iterações de desenvolvimento foram introduzidos identificadores técnicos e textos visíveis com `FixLog` (por exemplo, `package:fixlog`, `com.arestaclimb.fixlog`, `FixLogApp` e menções a relatórios). Conforme deliberado em exploração técnica e de produto (@pm e @ux), o nome oficial adotado é **Fixalog** (em Titlecase corrido), e como a aplicação ainda não foi disponibilizada ao público geral nas lojas, todos os identificadores nativos e lógicos devem ser sincronizados.

## Goals / Non-Goals

**Goals:**
- Unificar a identidade visual, textual e de marca da aplicação sob o nome `Fixalog`.
- Alterar o `applicationId` e `namespace` do Android para `com.arestaclimb.fixalog` e mover a classe `MainActivity.kt`.
- Alterar o `PRODUCT_BUNDLE_IDENTIFIER` do iOS para `com.arestaclimb.fixalog` e ajustar o `CFBundleDisplayName` para `Fixalog`.
- Renomear o pacote Flutter no `pubspec.yaml` para `name: fixalog` e atualizar todos os imports internos de `package:fixlog/...` para `package:fixalog/...`.
- Renomear o widget principal da aplicação de `FixLogApp` para `FixalogApp`.
- Atualizar títulos de telas, relatórios gerados, metadados de certificados e utilitários legais (`ferramentas/atualizador_legal/`).
- Assegurar 100% de aprovação na suíte de testes unitários e de integração, mantendo a cobertura de testes em 100% conforme o `PRINCIPIOS.md`.

**Non-Goals:**
- Não serão feitas alterações estruturais de regras de negócio, layouts de telas ou banco de dados Isar além das atualizações de nomes e imports.
- Não serão alterados os identificadores de outros apps do ecossistema (como `com.arestaclimb.app`).

## Decisions

### 1. Adoção da Marca "Fixalog" (Titlecase)
- **Decisão**: Usar `Fixalog` em vez de `FixaLog` (CamelCase) ou `FixLog`.
- **Racional**: Proporciona uma silhueta visual suave (*Bouma shape* contínuo), sonoridade fluida em inglês (sem cortes consonantais bruscos e rimando com *Catalog* e *Travelog*), fácil digitação em smartphones e alinhamento com marcas de esporte/outdoor consagradas.
- **Alternativas consideradas**: `FixaLog` (descartado por fragmentar o nome em dois blocos e dificultar a digitação móvel) e `FixLog` (descartado por soar a utilitário de TI / rastreador de bugs).

### 2. Migração de Identificadores Nativos Móveis
- **Decisão**: Alterar os identificadores nativos para `com.arestaclimb.fixalog` tanto no Android quanto no iOS.
- **Racional**: Como o app ainda não foi submetido ou lançado publicamente nas lojas de aplicativos, esta é a oportunidade definitiva para estabelecer o identificador correto, evitando discrepâncias permanentes e URLs desalinhadas nas lojas no futuro.
- **Impacto no Android**:
  - `build.gradle.kts`: `namespace = "com.arestaclimb.fixalog"`, `applicationId = "com.arestaclimb.fixalog"`.
  - Estrutura de diretórios: `app/android/app/src/main/kotlin/com/arestaclimb/fixalog/MainActivity.kt`.
- **Impacto no iOS**:
  - `Runner.xcodeproj/project.pbxproj`: `PRODUCT_BUNDLE_IDENTIFIER = com.arestaclimb.fixalog;`.
  - `Info.plist`: `CFBundleDisplayName = Fixalog`, `CFBundleName = fixalog`.

### 3. Renomeação do Módulo Dart e Imports
- **Decisão**: Atualizar o `app/pubspec.yaml` para `name: fixalog` e substituir todas as ocorrências de `package:fixlog/` por `package:fixalog/`.
- **Racional**: O ecossistema Dart utiliza o campo `name` do `pubspec.yaml` como raiz dos imports absolutos. Manter o nome do pacote idêntico ao nome do aplicativo e do repositório garante clareza máxima e previsibilidade para os desenvolvedores e agentes de IA.

### 4. Renomeação da Classe Raiz e Textos Visíveis
- **Decisão**: Renomear `FixLogApp` para `FixalogApp` em `app/lib/main.dart`, atualizar o título do `MaterialApp` para `'Fixalog'`, e atualizar diálogos de progresso e textos de laudos técnicos em PDF e EPUB.

## Risks / Trade-offs

- **[Risco] Imports quebrados em arquivos não mapeados**:
  - *Mitigação*: Uso de busca e substituição rigorosa no projeto e execução de `flutter analyze` e `flutter test` cobrindo 100% do código para garantir que nenhuma dependência quebrada passe despercebida.
- **[Risco] Incompatibilidade de cache do Gradle ou Flutter após renomear pacote nativo**:
  - *Mitigação*: Execução de `flutter clean` seguido de `flutter pub get` para reconstruir os vínculos do build nativo e assets.
- **[Risco] Referências em submódulos ou ferramentas auxiliares**:
  - *Mitigação*: Atualização concomitante de `ferramentas/atualizador_legal/` e validação das suítes de testes isoladas.

## Migration Plan

1. Atualizar o `app/pubspec.yaml` (`name: fixalog`).
2. Executar script/substituição de `package:fixlog/` para `package:fixalog/` em `lib/`, `test/` e `integration_test/`.
3. Renomear `FixLogApp` -> `FixalogApp` e títulos em `main.dart` e testes.
4. Mover a pasta e o arquivo `MainActivity.kt` no Android e atualizar `build.gradle.kts` e `AndroidManifest.xml`.
5. Atualizar os identificadores no projeto iOS (`project.pbxproj` e `Info.plist`).
6. Atualizar referências textuais e de teste em `ferramentas/atualizador_legal/`.
7. Executar `flutter clean && flutter pub get`.
8. Rodar testes de unidade (`flutter test --coverage`) e análise estática (`flutter analyze`).
