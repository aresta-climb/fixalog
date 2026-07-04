## 1. Setup e Dependências

- [x] 1.1 Adicionar dependências de mídias no `pubspec.yaml` (`flutter_image_compress`, `ffmpeg_kit_flutter`, `pdf`).
- [x] 1.2 Adicionar `flutter_riverpod` no `pubspec.yaml`.
- [x] 1.3 Inicializar projeto Rust e configurar o `flutter_rust_bridge_codegen`.
- [x] 1.4 Adicionar dependências no `Cargo.toml` (`lopdf`, `sha2`, `openssl` ou similar para CMS).

## 2. Testes de Integração e TDD (Fronteiras)

- [x] 2.1 Criar suite de testes de integração (`integration_test/`) para validar o fluxo Dart -> FFI -> Rust -> Disco falhando (Red).
- [x] 2.2 Criar arquivos `_test.dart` e `_test.rs` para todas as bibliotecas projetadas abaixo (TDD Red Phase).

## 3. Core Rust (Motor de PDF e Criptografia)

- [x] 3.1 Implementar testes unitários locais em Rust (`pdf_engine_test.rs` e `crypto_signer_test.rs`) para manipulação binária (100% coverage).
- [x] 3.2 Implementar `pdf_engine.rs` (Green Phase): Lógica de injeção de arquivos como `EmbeddedFiles` (PDF/A-3).
- [x] 3.3 Implementar `pdf_engine.rs` (Green Phase): Geração de `ByteRange` e placeholder para a assinatura.
- [x] 3.4 Implementar `crypto_signer.rs` (Green Phase): Leitura em stream pulando o ByteRange para calcular SHA-256.
- [x] 3.5 Implementar `crypto_signer.rs` (Green Phase): Gerar assinatura autoassinada e envelopar em CMS (PKCS#7).
- [x] 3.6 Implementar `api.rs` (FFI): Expor a função principal de geração e configurar envio de eventos assíncronos (StreamSink).
- [x] 3.7 Refatoração (Refactor Phase) para manter o código Rust declarativo e simples.

## 4. Serviços Flutter (Dart - Library First)

- [x] 4.1 Implementar `_test.dart` correspondentes garantindo 100% de cobertura.
- [x] 4.2 Implementar `MediaCompressorService`: Rotinas de compressão com `ffmpeg` (vídeo/áudio) e compressão de imagem.
- [x] 4.3 Implementar `PdfDraftService`: Desenho do rascunho visual do PDF contendo os *thumbnails*, textos e anotações GoToE (`/Launch`).
- [x] 4.4 Implementar `GenerationRecoveryService`: Controle de flags de processamento e lógica do *Garbage Collector* para limpar a pasta de cache.

## 5. Interface e Estado (Riverpod)

- [x] 5.1 Criar testes de widget e state (`generation_provider_test.dart`).
- [x] 5.2 Criar os *Providers* do Riverpod (`generation_provider.dart`) para encapsular as chamadas FFI do Rust e o progresso.
- [x] 5.3 Criar o widget `GenerationProgressDialog` que escuta ativamente o Provider.
- [x] 5.4 Integrar o botão final do formulário de laudo para acionar todo o pipeline via Provider.
- [x] 5.5 Rodar suite de testes completa e checar relatório de 100% Coverage.
