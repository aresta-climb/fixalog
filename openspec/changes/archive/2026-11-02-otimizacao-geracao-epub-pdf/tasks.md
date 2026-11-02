# Tasks

## 1. Otimização de Compressão de Imagens, Vídeos e Escrita Atômica (`MediaCompressorService` e `VideoTranscoderService`)

- [x] 1.1 Atualizar `VideoTranscoderService` para utilizar `-preset veryfast` na transcodificação H.264 720p CRF 26 e extrair o poster frame em JPEG (`<uuid>_poster.jpg`), validando os novos parâmetros em `app/test/features/media/services/video_transcoder_service_test.dart`
- [x] 1.2 Atualizar `MediaCompressorService` para gravar arquivos de forma atômica (`.tmp` -> `rename`), reutilizar artefatos já prontos em disco, deduplicar `Future`s em andamento, controlar paralelismo (pool de imagens e fila de vídeos), gerar `<uuid>_thumb.jpg` (2MP `1440x1440` q=80 JPEG) a partir de `<uuid>.webp` (4MP `2048x2048` q=85 WebP) sem gerar `_thumb.webp` de 600px, e reaproveitar páginas `<uuid>_p<N>_original.jpg` já extraídas de PDFs, verificando tudo em `app/test/features/media/services/media_compressor_service_test.dart`

## 2. Pré-processamento em Background no Wizard e Empacotamento EPUB 3 (`WizardStateController`, `EpubPackagerService` e `GenerationNotifier`)

- [x] 2.1 Disparar o pré-processamento não-bloqueante no `MediaCompressorService` logo após anexar fotos, vídeos e documentos PDF no `WizardStateController`, verificando em `app/test/features/wizard/controllers/wizard_state_controller_test.dart` que os artefatos pré-processados são solicitados sem bloquear o fluxo de captura
- [x] 2.2 Configurar `EpubPackagerService.empacotarEpub` para armazenar arquivos de mídia já comprimidos (`.mp4`, `.webp`, `.jpg`, `.jpeg`, `.png`, `.pdf`) com `CompressionType.none` (`STORE`) e manter `CompressionType.deflate` nos arquivos de texto/XML/Protobuf, validando em `app/test/core/services/epub_packager_service_test.dart`
- [x] 2.3 Atualizar `GenerationNotifier.startGeneration` para processar fotos e documentos pendentes em paralelo (`Future.wait`), usar `<uuid>_poster.jpg`, e remover a chamada legada a `_draftService.drawDraft`, validando em `app/test/features/pdf_generation/providers/generation_provider_test.dart`

## 3. Geração Nativa do PDF Resumido com `package:pdf` (`PdfPrintSummaryService` e `VisualizadorRelatorioScreen`)

- [x] 3.1 Refatorar `PdfPrintSummaryService` para construir o PDF Resumido A4 nativamente com `package:pdf` (`pw.Document` / `pw.MultiPage`), renderizando QR Codes vetoriais (`pw.BarcodeWidget`), textos com Markdown, páginas de comprovantes PDF, materiais anexos e imagens JPEG de 2MP pré-processadas (`pw.MemoryImage`) sem depender de `Printing.convertHtml` / WebView, validando em `app/test/core/services/pdf_print_summary_service_test.dart`
- [x] 3.2 Atualizar `VisualizadorRelatorioScreen` para carregar diretamente os caminhos/bytes das imagens pré-processadas (`<uuid>_thumb.jpg` e `<uuid>_poster.jpg`, com fallback para `.webp`) sem codificação Base64 ao gerar o PDF Resumido sob demanda, validando em `app/test/features/pdf_generation/views/visualizador_relatorio_screen_test.dart`
