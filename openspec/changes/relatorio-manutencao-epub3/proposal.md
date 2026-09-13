# Proposta: Migração de Relatórios para EPUB 3 Assinado e Remoção do Arcabouço Rust

## Why

Atualmente, o FixLog tenta compilar e selar relatórios técnicos de manutenção como arquivos PDF híbridos contendo anexos embutidos e assinaturas PKCS#7 manipuladas em baixo nível via Rust (`lopdf` e `flutter_rust_bridge`). Esse modelo apresenta dois bloqueios fundamentais:

1. **Inviabilidade de Vídeos em PDF**: Vídeos curtos de inspeção (sem limitação arbitrária de quantidade, abrangendo quantas proteções e mídias forem catalogadas na via) são essenciais para atestar o estado de proteções fixas, mas o formato PDF não possui suporte moderno ou interoperável para reprodução de vídeo em dispositivos móveis ou navegadores.
2. **Complexidade Excessiva do Rust**: A esteira de compilação cruzada C++/Rust (Cargokit/NDK) gera mais de 8 GB de artefatos intermediários no CI, torna o APK pesado e viola o *Princípio V (Simplicidade e Anti-Abstração)* do repositório, sem que a assinatura PAdES tenha sido concluída com estabilidade.

A adoção do **EPUB 3** como documento canônico mestre resolve ambos os problemas: é um padrão aberto do W3C baseado em ZIP e HTML5/CSS, permitindo reprodução nativa de múltiplos vídeos (`<video>`), fotos em formato WebP (4MP, q=85) com compressão 65% mais eficiente, embutimento direto do Protobuf (`registro.binarypb`) e assinatura digital padronizada (**W3C XML-DSig**) com as chaves ECDSA já existentes no app, tudo implementado em **Dart 100% puro**. As mídias originais permanecem salvas no armazenamento local do dispositivo para permitir re-gerações futuras sem degradação.

Para atender à burocracia de órgãos ambientais e gestores de parques (que utilizam sistemas como o SEI e exigem `.pdf`), o sistema passa a gerar um **PDF Resumido** derivado do mesmo HTML via `@media print`, contendo um cabeçalho explicativo e QR Code com link direto para a versão canônica e interativa na Web.

## What Changes

- **Novo Documento Canônico (EPUB 3)**:
  - Criação de uma biblioteca Dart pura para compilação do container OCF (`mimetype`, `META-INF/container.xml`, `content.opf`, XHTML semântico, CSS responsivo e mídias).
  - Suporte nativo a reprodução de múltiplos vídeos curtos transcodificados em MP4 (H.264 720p CRF 26 / áudio mono 64k / faststart) e fotos WebP através de tags HTML5 `<video controls>` e `<figure>`, sem limites arbitrários de quantidade.
  - Inclusão do arquivo Protobuf bruto (`registro.binarypb`) dentro do container para auditoria automatizada.
  - Assinatura digital do container em conformidade com o padrão **W3C XML-DSig** (`META-INF/signatures.xml`), calculando os hashes SHA-256 dos recursos e assinando com a chave ECDSA (secp256r1) do `CryptoService`.
- **Visualizador no Aplicativo**:
  - Exibição do relatório gerado diretamente dentro do app via `InAppWebView` consumindo o XHTML em cache local, garantindo reprodução instantânea dos vídeos e fluidez visual.
- **Exportação de PDF Resumido Auxiliar**:
  - Geração de PDF a partir do próprio HTML utilizando as folhas de estilo de impressão (`@media print`) e o pacote `printing` nativo do SO.
  - Inclusão automática de cabeçalho no PDF informando que o documento é uma representação impressa resumida.
  - Substituição visual de vídeos no PDF por seus *poster frames* (fotos estáticas de alta resolução) acompanhados de QR Codes individuais para reprodução online.
  - Inclusão de QR Code e link vetorial no cabeçalho apontando para a página canônica da vistoria na Web (`fixlog.app/v/<id>`).
- **Remoção Completa do Rust e FFI (**BREAKING**)**:
  - Remoção de `app/rust`, `app/rust_builder`, `flutter_rust_bridge.yaml` e da dependência `rust_lib_app` no `pubspec.yaml`.
  - Remoção da inicialização `RustLib.init()` em `main.dart` e nos testes de integração.
  - Simplificação drástica do pipeline de CI/CD em `.github/workflows/build_android.yml`, eliminando passos de limpeza de 8 GB do Rust e reduzindo tempos de build.

## Capabilities

### New Capabilities
- `epub3-report`: Geração, empacotamento em ZIP/OCF e assinatura digital XML-DSig de relatórios de manutenção canônicos no formato EPUB 3 em Dart puro.

### Modified Capabilities
- `pdf-generator`: A geração de PDF deixa de utilizar injeção binária em Rust/GoToE e passa a produzir um PDF Resumido para protocolo a partir do HTML/CSS usando a funcionalidade de impressão do SO com QR Codes de rastreabilidade.
- `pdf-xmp-signature`: A exigência de envelopamento PKCS#7 na camada de baixo nível do PDF é transferida para a assinatura digital canônica XML-DSig no EPUB 3, enquanto o PDF atua como documento auxiliar contendo o identificador e link para a fonte da verdade.

## Impact

- **Código Dart (`app/lib`)**:
  - Substituição do `PdfDraftService` por um construtor de documentos XHTML/CSS e empacotador EPUB 3.
  - Refatoração do `GenerationNotifier` para orquestrar a geração do EPUB 3, transcodificação de vídeos com `ffmpeg_kit` e exportação opcional do PDF.
  - Atualização do `main.dart` removendo `RustLib.init()`.
- **Arquitetura e Dependências**:
  - Remoção de `rust_lib_app`, `flutter_rust_bridge`, `cargokit` e de todo o diretório `app/rust`.
  - Adição da dependência `archive` (se ainda não transitiva) para criação de containers ZIP em Dart puro.
- **Pipeline CI/CD**:
  - O workflow de compilação Android/iOS não exigirá mais a instalação de Rustup, Cargo ou Android NDK para compilação nativa de FFI.
  - Atualização do teste de conformidade de CI (`pipeline_ci_android_test.dart`) para refletir a nova realidade enxuta.
