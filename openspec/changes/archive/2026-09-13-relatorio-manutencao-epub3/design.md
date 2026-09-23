# Documento de Design Técnico: Relatórios em EPUB 3 Assinado e Descontinuação do Rust

## Context

O FixLog cataloga proteções fixas em vias de escalada e registra dados de vistoria técnica. Anteriormente, a geração de relatórios baseava-se em um rascunho de PDF em Dart (`PdfDraftService`) que seria selado por uma biblioteca em Rust (`app/rust`) via `flutter_rust_bridge` para embutir arquivos e injetar assinaturas PKCS#7. Conforme analisado em `proposal.md`, esse arranjo bloqueava a inclusão de múltiplos vídeos de inspeção e impunha um custo operacional e de CI desproporcional (mais de 8 GB em artefatos de compilação intermediários).

Este design define como estruturar a esteira de geração em Dart 100% puro, construindo um container EPUB 3 canônico assinado com W3C XML-DSig e permitindo a exportação de um PDF Resumido para protocolo burocrático via `@media print`.

## Goals / Non-Goals

**Goals:**
- Implementar uma biblioteca autônoma em Dart puro (*Library-First*) para construção e empacotamento de containers EPUB 3 válidos (OCF/W3C).
- Gerar páginas XHTML semânticas com suporte nativo a tags `<video controls>` para qualquer quantidade de fotos e vídeos de inspeção coletados na vistoria, com escalonamento dinâmico do container.
- Implementar a assinatura digital no padrão W3C XML-DSig (`META-INF/signatures.xml`) utilizando o par de chaves ECDSA secp256r1 e certificados X.509 já gerenciados pelo `CryptoService`.
- Empacotar o arquivo bruto `registro.binarypb` dentro do container EPUB 3 para consumo automatizado.
- Permitir a exportação de um PDF Resumido A4 diretamente do documento visual via regras de impressão do SO (`@media print` e pacote `printing`), contendo cabeçalho explicativo e QR Code direcionando para a página canônica da vistoria (`fixlog.app/v/<id>`).
- Remover integralmente o código Rust (`app/rust`, `app/rust_builder`, `cargokit`, `flutter_rust_bridge`) e restabelecer um ambiente de build Flutter 100% limpo e ágil.

**Non-Goals:**
- Implementar a infraestrutura de backend em nuvem nesta mudança (o escopo do app é gerar o EPUB, o PDF auxiliar e montar o contrato de URL canônica `fixlog.app/v/<id>`).
- Implementar um leitor de livros digitais genérico (o app utilizará uma `InAppWebView` otimizada para renderizar o próprio relatório gerado).
- Assinar o PDF auxiliar com PAdES/PKCS#7 (o PDF atua como representação impressa sem travas, livre para ser assinado no Gov.br pelo usuário).

## Decisions

### 1. Biblioteca Autônoma de Geração de EPUB 3 (Dart Puro)
- **Decisão**: Criar a biblioteca `EpubReportBuilder` sob a arquitetura *Library-First* definida no `PRINCIPIOS.md`.
- **Estrutura do Container**:
  - `mimetype`: Armazenado sem compressão (método `STORE`) nos primeiros bytes do arquivo ZIP com o conteúdo `application/epub+zip`.
  - `META-INF/container.xml`: Aponta para o arquivo de manifesto `OEBPS/content.opf`.
  - `META-INF/signatures.xml`: Contém a assinatura W3C XML-DSig.
  - `OEBPS/content.opf`: Declara metadados da sessão (Dublin Core), manifesto completo de itens (XHTML, CSS, imagens WebP, vídeos MP4, protobuf) e o spine de leitura.
  - `OEBPS/relatorio.xhtml`: Marcação semântica com `<section>` para cada proteção, `<figure>` para fotos e `<video controls>` para os clips.
  - `OEBPS/estilo.css`: Design responsivo moderno no tema escuro/claro com regras específicas de tela e `@media print`.
  - `OEBPS/midias/`: Arquivos `.webp` (4MP q=85) e `.mp4` (H.264 720p CRF 26 / mono 64k / faststart).
  - `OEBPS/dados/registro.binarypb`: Arquivo Protobuf original da vistoria.
- **Alternativas consideradas**:
  - Usar bibliotecas genéricas de EPUB do pub.dev: Descartado, pois a maioria foca apenas em leitura (*EPUB parser*) ou não suporta empacotamento customizado com injeção de XML-DSig e Protobuf.
  - Manter o gerador em Rust com `zip-rs`: Descartado para cumprir o princípio de simplicidade e eliminar o gargalo de FFI.

### 2. Transcodificação e Calibração de Mídias (Vídeo, Foto e Preservação de Originais)
- **Decisão**: Padronizar as mídias em formatos oficiais *Core Media Types* do EPUB 3.3 com máxima eficiência de armazenamento e reprodução universal:
  - **Vídeo (FFmpegKit)**: Transcodificação para H.264 (perfil High) em 720p a 30 fps com CRF 26, áudio mono AAC a 64 kbps e `-movflags +faststart`. Cada clip de 15 segundos atinge ~1.1 MB a 1.4 MB com nitidez macro preservada e início imediato de reprodução. Extração automática de um *poster frame* (`.webp`/`.jpg`) no tempo 00:00.5.
  - **Foto (`flutter_image_compress`)**: Compressão em **WebP (4MP, qualidade 85)**, atingindo ~350 KB a 550 KB por imagem (~65% mais leve que o JPEG 95 anterior, sem ruídos visíveis).
  - **Preservação de Mídias Originais**: O `SessionBundleManager` mantém os arquivos brutos gravados com o sufixo `_original` (ex: `<uuid>_original.mp4`, `<uuid>_original.jpg`) no diretório da sessão. Isso permite re-gerações ou re-exportações futuras a partir da matriz sem perda acumulada de compressão.
- **Alternativas consideradas**:
  - H.265 (HEVC) para vídeo: Descartado, pois não é Core Media Type no EPUB 3.3 e gera tela preta no Chrome/Edge em Windows sem codecs proprietários pagos da Microsoft.
  - AVIF para fotos: Descartado, pois não é Core Media Type no EPUB 3.3 (exigiria fallback), não tem suporte no `flutter_image_compress` e consome CPU/bateria excessiva no celular.

### 3. Assinatura Digital Padronizada W3C XML-DSig
- **Decisão**: A assinatura do container utiliza a recomendação oficial W3C XML-DSig (RFC 3275):
  - Algoritmo de Digest: SHA-256 (`http://www.w3.org/2001/04/xmlenc#sha256`).
  - Algoritmo de Assinatura: ECDSA com SHA-256 (`http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256`) sobre a curva secp256r1.
  - O arquivo `META-INF/signatures.xml` calcula e lista `<Reference URI="...">` com o `<DigestValue>` de cada arquivo em `OEBPS/`.
  - O bloco `<SignedInfo>` consolidado é assinado com a chave privada do mantenedor pelo `CryptoService`, e o certificado autoassinado X.509 em Base64 é inserido em `<X509Certificate>`.
- **Alternativas consideradas**:
  - Assinatura CMS/PKCS#7 externa: Descartado, pois o XML-DSig é o padrão normativo da especificação EPUB 3 Open Container Format (OCF).

### 4. PDF Resumido Derivado via `@media print` e QR Codes
- **Decisão**: O PDF de protocolo deixa de ser um documento desenhado separadamente com `pdf/widgets.dart` e passa a ser uma renderização direta do documento visual via `@media print` e o pacote `printing`:
  - **Cabeçalho Informativo**: Renderizado apenas no modo de impressão, indicando que o documento é uma representação auxiliar e contendo o QR Code principal que redireciona para `https://fixlog.app/v/<id_da_sessao>`.
  - **Tratamento de Vídeo**: No CSS de impressão, tags `<video>` recebem `display: none` e são substituídas pelo *poster frame* estático com um mini QR Code dedicado para visualização daquele clip online.
  - **Compatibilidade com Assinaturas Oficiais**: Como o PDF é limpo e não contém assinaturas binárias engessadas, o gestor do parque ou o escalador pode assinar o PDF no portal **Gov.br** (ICP-Brasil) para trâmite no SEI sem quebrar nenhuma validação.

### 5. Descontinuação Integral do Arcabouço Rust
- **Decisão**: Excluir fisicamente:
  - Diretório `app/rust/` e `app/rust_builder/`.
  - Arquivo de configuração `app/flutter_rust_bridge.yaml`.
  - Referência `rust_lib_app` no `app/pubspec.yaml`.
  - Chamada `RustLib.init()` em `app/lib/main.dart` e testes associados.
  - Passos de limpeza e toolchains de Rust no CI (`.github/workflows/build_android.yml` e testes de conformidade de CI).

## Risks / Trade-offs

- **[Risco: Tamanho do arquivo EPUB com alto volume de vídeos]** → *Mitigação*: A esteira de compressão do FFmpegKit e `flutter_image_compress` processa em lote com H.264 720p CRF 26 e WebP 4MP q=85, garantindo escalabilidade linear e previsível (~1.2 MB por vídeo e ~400 KB por foto), exibindo barra de progresso detalhada e não bloqueante na interface para qualquer quantidade de mídias.
- **[Risco: Falta de leitor de EPUB nativo no Windows ou Android dos gestores]** → *Mitigação*: O aplicativo fornece o PDF Resumido para protocolo com QR Code, enquanto o relatório completo pode ser inspecionado diretamente no app ou via página Web limpa em qualquer navegador.
- **[Risco: Quebra de testes de integração existentes vinculados a RustLib]** → *Mitigação*: Atualizar e refatorar os testes de integração para testar a nova esteira `GenerationNotifier` 100% em Dart puro, garantindo que a suíte passe com 100% de cobertura.

## Migration Plan

1. **Fase 1: Módulo do Construtor EPUB 3 (TDD e Library-First)**
   - Desenvolver testes unitários para a criação da estrutura de arquivos OCF e manifestos.
   - Implementar `EpubReportBuilder`, montagem do XHTML/CSS e empacotamento com `archive`.
2. **Fase 2: Assinatura XML-DSig**
   - Desenvolver testes unitários para cálculo de hashes dos recursos e geração de `META-INF/signatures.xml`.
   - Conectar com `CryptoService` (ECDSA secp256r1).
3. **Fase 3: Refatoração da Esteira de Geração e Exportação de PDF**
   - Atualizar `GenerationNotifier` para orquestrar transcodificação de vídeos, geração do EPUB e emissão do PDF Resumido com `@media print`.
   - Implementar visualização no app com WebView local.
4. **Fase 4: Remoção do Rust e Limpeza de Dependências**
   - Remover pastas `app/rust`, `app/rust_builder` e configurações do `pubspec.yaml`.
   - Atualizar `main.dart`, testes arquiteturais e workflows de CI.
