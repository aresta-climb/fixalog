## 1. Biblioteca Autônoma de Geração EPUB 3 (Library-First & TDD)

- [x] 1.1 Criar testes unitários para a geração de marcação XHTML semântica e folha de estilos CSS responsiva com regras de tela e `@media print`, verificando que `flutter test test/core/services/epub_document_builder_test.dart` falha inicialmente (Red).
- [x] 1.2 Implementar `EpubDocumentBuilder` para converter os dados de `Registro` (Protobuf), fotos e referências de vídeo em páginas XHTML semânticas com tags `<video controls>` e poster frames, verificando que os testes passam com 100% de cobertura (Green).
- [x] 1.3 Criar testes unitários para a montagem da estrutura de diretórios OCF e empacotamento ZIP (`mimetype` sem compressão, `META-INF/container.xml`, manifesto `content.opf` e injeção de `registro.binarypb`), verificando que o teste falha inicialmente (Red).
- [x] 1.4 Implementar `EpubPackagerService` utilizando o pacote `archive` para empacotar o container `.epub` físico conforme o padrão EPUB 3, verificando aprovação dos testes unitários com 100% de cobertura (Green).

## 2. Assinatura Digital XML-DSig (W3C OCF)

- [x] 2.1 Criar testes unitários para o cálculo de resumos criptográficos SHA-256 de todos os recursos do manifesto e construção da estrutura XML-DSig (`META-INF/signatures.xml`), verificando falha inicial em `flutter test test/core/services/xml_dsig_signer_test.dart` (Red).
- [x] 2.2 Implementar `XmlDsigSignerService` integrado ao `CryptoService` (ECDSA secp256r1 com SHA-256 e certificado X.509), assinando o manifesto e injetando a assinatura no container, verificando que os testes passam com 100% de cobertura (Green).

## 3. Transcodificação de Vídeo, Compressão WebP e Preservação de Mídias

- [x] 3.1 Criar testes unitários para o serviço de transcodificação de vídeos (H.264 720p CRF 26, mono 64k, faststart), extração de poster frames e compressão de imagens em WebP (4MP q=85) consumindo arquivos `_original`, verificando falha inicial em `flutter test test/features/media/services/video_transcoder_service_test.dart` (Red).
- [x] 3.2 Implementar `VideoTranscoderService` utilizando comandos otimizados do `ffmpeg_kit_flutter_new` (H.264 720p 30fps CRF 26, AAC mono 64k, `-movflags +faststart` e extração de frame aos 0.5s), verificando sucesso dos testes com simulação de execução (Green).
- [x] 3.3 Atualizar `MediaCompressorService` para converter fotos para WebP (4MP, qualidade 85) mantendo os arquivos brutos `_original` intactos no disco local via `SessionBundleManager`, verificando aprovação dos testes unitários com 100% de cobertura (Green).

## 4. Exportação de PDF Resumido Auxiliar (@media print)

- [x] 4.1 Criar testes unitários para a formatação do PDF Resumido contendo o cabeçalho explicativo, link canônico para a Web e substituição visual de vídeos por imagem estática com QR Code individual, verificando falha inicial em `flutter test test/core/services/pdf_print_summary_service_test.dart` (Red).
- [x] 4.2 Implementar `PdfPrintSummaryService` conectando a renderização HTML aos estilos `@media print` e ao pacote nativo `printing` para exportar o arquivo PDF A4 legível, verificando aprovação dos testes (Green).

## 5. Orquestração no Aplicativo e Visualização

- [x] 5.1 Atualizar `GenerationNotifier` em `generation_provider.dart` para orquestrar a esteira completa em Dart puro (compressão de fotos, transcodificação de vídeos, compilação do EPUB 3, assinatura XML-DSig e exportação opcional do PDF), substituindo as antigas chamadas a Rust.
- [x] 5.2 Implementar tela de visualização do relatório no app utilizando WebView local consumindo o documento XHTML descompactado em cache, permitindo reprodução instantânea dos vídeos e botões de compartilhamento do `.epub` e `.pdf`.
- [x] 5.3 Atualizar os testes de widget e testes de integração existentes (`generation_flow_test.dart`, `draft_persistence_flow_test.dart`), verificando que toda a suíte de testes passa com sucesso via `flutter test`.

## 6. Remoção Completa do Arcabouço Rust e Limpeza de CI

- [x] 6.1 Excluir fisicamente os diretórios `app/rust`, `app/rust_builder` e o arquivo `app/flutter_rust_bridge.yaml`.
- [x] 6.2 Remover a dependência `rust_lib_app` de `app/pubspec.yaml` e a chamada `RustLib.init()` em `app/lib/main.dart` e nos testes.
- [x] 6.3 Atualizar os workflows de CI/CD (`.github/workflows/build_android.yml`) e o teste de conformidade de CI (`pipeline_ci_android_test.dart`), eliminando etapas de compilação/limpeza de 8 GB do Rust e verificando execução limpa e verde.
