# Tasks

## 1. Schema Protobuf e Geração de Código

- [x] 1.1 Adicionar a mensagem `ArquivoDocumento` (`uuid`, `tipo_original`, `hash_original`, `nome_original`, `quantidade_paginas`, `hashes_paginas_webp`) e o campo `ArquivoDocumento documento = 4` no `oneof midia` de `ReferenciaMidia` em `app/protos/registro.proto`, recompilar os arquivos `.pb.dart` e verificar que os testes em `app/test/` continuam compilando e passando

## 2. Serviços de Seleção, Rasterização de PDF e SessionBundleManager

- [x] 2.1 Implementar `SeletorDocumentoService` em `app/lib/features/media/services/seletor_documento_service.dart` com seu teste espelhado 1:1 `app/test/features/media/services/seletor_documento_service_test.dart`, verificando execução verde via `flutter test`
- [x] 2.2 Implementar via TDD o método de rasterização de páginas PDF para imagens `.webp` (`<uuid>_p1.webp` .. `<uuid>_pN.webp`) em `MediaCompressorService` (`app/lib/features/media/services/media_compressor_service.dart`), validando o comportamento com PDF de 1 e múltiplas páginas em `app/test/features/media/services/media_compressor_service_test.dart`
- [x] 2.3 Implementar via TDD o suporte a documentos PDF em `SessionBundleManager` e `WizardStateController` (`saveDocumentAnswerBytes` / `saveDocumentAnswer`) para salvar `<uuid>_original.pdf` intacto, rasterizar as páginas `<uuid>_p<N>.webp` e armazenar `ReferenciaMidia` com `ArquivoDocumento` e hashes SHA-256 calculados, verificando com `flutter test test/core/services/session_bundle_manager_test.dart test/features/wizard/`

## 3. Captura de PDF no Wizard e Catálogo de Materiais

- [x] 3.1 Adicionar opção "Selecionar Arquivo PDF" no modal de captura de mídia/documento do `WizardScreen` (e exibição visual de documento PDF anexado com nome original e contagem de páginas), validando via testes de widget em `app/test/features/wizard/views/wizard_screen_test.dart`
- [x] 3.2 Atualizar `app/assets/protocols/cadastro_material.yaml` nos campos de Nota Fiscal / Comprovante e Testes de Qualidade para indicar o suporte a Foto ou PDF e validar em `app/test/core/services/protocol_parser_test.dart`

## 4. Empacotamento no EPUB 3, Visualizador e PDF Resumido

- [x] 4.1 Atualizar `EpubDocumentBuilder`, `EpubPackagerService` e `GenerationNotifier` (via TDD) para empacotar `OEBPS/midias/<uuid>.pdf` intacto no manifesto (`application/pdf`) e assinar no `META-INF/signatures.xml`, empacotar todas as páginas `OEBPS/midias/<uuid>_p<N>.webp`, e renderizar no `relatorio.xhtml` as páginas em sequência junto ao link para abrir/baixar o PDF original, verificando com `flutter test test/core/services/epub_document_builder_test.dart test/core/services/epub_packager_service_test.dart test/features/pdf_generation/`
- [x] 4.2 Atualizar `VisualizadorRelatorioScreen` para carregar todas as páginas `.webp` de `ArquivoDocumento` ao gerar o PDF resumido sob demanda e tratar a abertura/compartilhamento de documentos `.pdf` anexados, verificando com `flutter test test/features/pdf_generation/views/visualizador_relatorio_screen_test.dart`
- [x] 4.3 Atualizar `PdfPrintSummaryService` e `PdfDraftService` (via TDD) para renderizar sequencialmente todas as páginas rasterizadas (`<uuid>_p1.webp` .. `<uuid>_pN.webp`) dos documentos PDF anexados, verificando com `flutter test test/core/services/pdf_print_summary_service_test.dart test/features/pdf_generation/services/pdf_draft_service_test.dart`

## 5. Validação de Integração e Espelhamento 1:1

- [x] 5.1 Executar `flutter test test/architecture/test_structure_mirror_test.dart` e a suíte completa `flutter test` para garantir 100% de espelhamento 1:1 e todos os testes passando sem regressões
