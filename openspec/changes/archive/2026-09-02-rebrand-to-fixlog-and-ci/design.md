## Context

O aplicativo de inventário e vistoria de proteções FixLog foi iniciado como um protótipo com os identificadores e nomes padrão do template Flutter (`com.example.app`, `name: app`, `android:label="app"`, `CFBundleDisplayName: "App"`) e com referências textuais com a grafia legada `FixaLog`.
Para permitir testes reais por escaladores e conquistadores através do Google Play Internal Testing e Apple TestFlight, é necessário oficializar a identidade do app como `com.arestaclimb.fixlog`, unificar toda a nomenclatura interna e externa para `FixLog`, configurar a assinatura de release e automatizar o pipeline de compilação via GitHub Actions, com suporte à compilação da biblioteca de criptografia e processamento nativo em Rust (`cargokit`).

Todas as decisões arquiteturais e passos de implementação são orientados pelo documento `PRINCIPIOS.md` do repositório.

## Goals / Non-Goals

**Goals:**
- Substituir todas as ocorrências de `FixaLog` por `FixLog` no app inteiro (UI, classes, certificados autoassinados X.509, diálogos, títulos e relatórios).
- Unificar a identidade da aplicação como `FixLog` em todas as plataformas (Android, iOS e Dart package).
- Configurar o identificador exclusivo `com.arestaclimb.fixlog`.
- Gerar assets visuais temporários (ícones de aplicativo e splash screen) usando a paleta oficial (`#FF6B00` e `#121416`) para garantir builds válidos e profissionais.
- Permitir assinatura de release híbrida no Android (via variáveis de ambiente no CI ou via `key.properties` local).
- Adicionar conformidade de exportação de criptografia no iOS (`ITSAppUsesNonExemptEncryption = false`).
- Implementar workflows completos do GitHub Actions para release unificado, build Android (.aab com upload na faixa interna do Google Play) e build iOS (.ipa com upload para TestFlight via `xcrun altool`), configurando toolchains do Rust (Cargokit) e NDK/Xcode.
- Assegurar 100% de cobertura de testes unitários e aprovação nos testes de integração.
- Manter todo o código, documentação e mensagens estritamente em português brasileiro.

**Non-Goals:**
- Criação de branding e logotipo final definitivo desenhado por equipe de design (será utilizado asset temporário com identidade visual correspondente).
- Publicação direta na faixa pública/produção das lojas (o foco é na faixa interna e TestFlight).
- Modificação das regras de negócio de cadastro de vistorias, Isar schemas ou protocolos Protobuf.

## Decisions

### 1. Conformidade com os Princípios de Engenharia (`PRINCIPIOS.md`)
- **Tudo em Português (Princípio I)**: Todo o código auxiliar, documentação, commits e comentários adicionados seguirão estritamente o português brasileiro.
- **Library-First e Simplicidade (Princípios II e VI)**: Utilização declarativa das ferramentas consolidadas da comunidade Flutter (`flutter_launcher_icons`, `flutter_native_splash`) sem criar camadas ou scripts proprietários convolutos.
- **100% de Cobertura e Test-First (Princípios III, IV e V)**: Os testes unitários e de integração (`integration_test/`) serão atualizados para os novos caminhos de imports `package:fixlog/` e novas strings `FixLog` (como em `crypto_service_test.dart`), sendo validados via `flutter test --coverage` com 100% de linhas cobertas antes de concluir a mudança.

### 2. Unificação Completa da Nomenclatura para `FixLog`
- **Decisão**: Substituição global de todas as ocorrências de `FixaLog` por `FixLog`.
  - Classe raiz: `FixaLogApp` → `FixLogApp` no `lib/main.dart` e testes de integração.
  - Certificado X.509: Organização `O='FixLog'` em `crypto_service.dart`.
  - Diálogos e telas: Textos informativos de selo, termos de responsabilidade e relatórios.
- **Racional**: Elimina inconsistências de marca e garante que tanto a interface quanto os metadados gerados (PDFs e certificados) reflitam a marca definitiva.

### 3. Renomeação do pacote Dart para `fixlog`
- **Decisão**: Alterar `name: app` para `name: fixlog` no `pubspec.yaml` e substituir todas as ocorrências de `package:app/` por `package:fixlog/` em todo o código e testes.
- **Alternativa Considerada**: Manter `name: app` internamente e mudar apenas o nome visível nas lojas. Rejeitado porque gera inconsistência, fragiliza testes e mantém débito técnico.

### 4. Estratégia de Identificadores e Pacotes Nativos
- **Decisão**: 
  - Android: `applicationId = "com.arestaclimb.fixlog"`, `namespace = "com.arestaclimb.fixlog"`, mover `MainActivity.kt` para `kotlin/com/arestaclimb/fixlog/MainActivity.kt`.
  - iOS: `PRODUCT_BUNDLE_IDENTIFIER = com.arestaclimb.fixlog;` no `project.pbxproj`.
- **Racional**: Google Play e Apple rejeitam pacotes com namespace `example`.

### 5. Assinatura Híbrida no Gradle (`build.gradle.kts`)
- **Decisão**: Adaptar o padrão utilizado no `aresta_app` onde o bloco `signingConfigs` no `build.gradle.kts` busca primeiramente variáveis de ambiente (`KEY_ALIAS`, `KEY_PASSWORD`, `STORE_FILE`, `STORE_PASSWORD`) e, se ausentes, recorre ao arquivo local `key.properties`.
- **Racional**: Permite que desenvolvedores façam builds locais sem expor segredos, ao mesmo tempo em que a esteira de CI/CD assina os pacotes dinamicamente a partir dos secrets do GitHub.

### 6. Compilação Rust no GitHub Actions
- **Decisão**: Nos runners do GitHub Actions:
  - No job Android (`ubuntu-latest`): Instalar a toolchain Rust via `dtolnay/rust-toolchain` e adicionar os targets Android (`aarch64-linux-android`, `armv7-linux-androideabi`, `x86_64-linux-android`, `i686-linux-android`).
  - No job iOS (`macos-latest`): Instalar a toolchain Rust e adicionar os targets iOS (`aarch64-apple-ios`, `aarch64-apple-ios-sim`, `x86_64-apple-ios`).
- **Racional**: Como o Fixlog usa `rust_lib_app` via Cargokit para criptografia e geração de PDF, o ambiente de compilação de CI necessita dos compiladores cruzados instalados.

### 7. Configuração de Ícones e Splash Temporários
- **Decisão**: Utilizar `flutter_launcher_icons` e `flutter_native_splash` apontando para um asset SVG/PNG gerado com a paleta oficial (Fundo Grafite Escuro `#121416`, Detalhes Laranja Resgate `#FF6B00`).
- **Racional**: Garante que o build do app gere ícones de alta densidade (inclusive Adaptive Icons para Android 8+ e tamanhos variados para iOS) sem necessidade de recorte manual de dezenas de arquivos de imagem.

## Risks / Trade-offs

- **[Risco] Quebra de asserções em testes ao renomear FixaLog para FixLog** → **Mitigação**: Atualizar todas as asserções de testes correspondentes (ex: `crypto_service_test.dart` verificando `O=FixLog`) e rodar a suíte completa com `flutter test`.
- **[Risco] Quebra de imports no Dart durante o rename de `package:app`** → **Mitigação**: Executar busca e substituição rigorosa em `lib/`, `test/` e `integration_test/`, seguida de `flutter test --coverage` para validar 100% dos testes unitários e de integração.
- **[Risco] Falha de compilação NDK / Rust no runner do GitHub Actions** → **Mitigação**: Especificar explicitamente o Java 17, NDK compatível (conforme `ndkVersion` do Flutter) e os targets necessários do `rustup`.
- **[Risco] Rejeição do TestFlight por falta de descrições de privacidade** → **Mitigação**: O `Info.plist` já contém as justificativas de Câmera, Localização e Biometria, e adicionaremos `ITSAppUsesNonExemptEncryption = false` para desabilitar o bloqueio de conformidade de criptografia padrão.
