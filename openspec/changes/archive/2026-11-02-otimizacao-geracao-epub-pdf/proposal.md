# Proposal

## Why

Atualmente, a selagem do relatório oficial em EPUB 3 leva de 1 a 2 minutos porque toda a compressão de imagens, rasterização redundante de PDFs, transcodificação de vídeos (em `-preset fast`) e recompressão DEFLATE de mídias binárias dentro do ZIP ocorrem de forma síncrona/sequencial apenas ao final do Wizard. Além disso, a geração sob demanda do PDF Resumido é ainda mais lenta porque converte todas as imagens em strings Base64 gigantescas e utiliza `Printing.convertHtml` (WebView oculto + Spooler de Impressão do Android) em vez de construir o PDF nativamente em Dart com imagens pré-processadas.

## What Changes

- **Pré-processamento de mídias em segundo plano com escrita atômica e fallback paralelo**:
  - Iniciar a compressão de fotos/páginas de PDF (em pool paralelo controlado) e a transcodificação de vídeos (em fila) assim que o usuário anexa a mídia no Wizard.
  - Utilizar escrita atômica em arquivos temporários (`.tmp` seguido de `rename`) para garantir que interrupções ou fechamento do aplicativo nunca deixem arquivos corrompidos pela metade.
  - No momento de selar o relatório (`startGeneration`), reutilizar imediatamente as mídias já pré-processadas em disco, aguardar tarefas em andamento e processar em paralelo apenas as mídias que eventualmente ainda não tenham sido concluídas.
  - Eliminar a re-rasterização duplicada de documentos PDF quando as páginas já foram extraídas na sessão e remover a chamada legada a `PdfDraftService.drawDraft`.
- **Otimização de formatos de imagem, miniaturas de 2MP JPEG e FFmpeg `veryfast`**:
  - Manter a geração de `<uuid>.webp` em 4MP (`2048x2048`, qualidade 85) para o pacote EPUB 3.
  - Substituir o antigo `<uuid>_thumb.webp` (600px) por `<uuid>_thumb.jpg` em **JPEG de 2MP (`1440x1440`, qualidade 80)**, gerado a partir da imagem de 4MP já redimensionada (evitando decodificar duas vezes a foto bruta de alta resolução da câmera).
  - Extrair o *poster frame* dos vídeos diretamente em formato JPEG (`<uuid>_poster.jpg`), servindo simultaneamente como capa do `<video poster="...">` no EPUB 3 e como imagem estática no PDF Resumido.
  - Calibrar a transcodificação de vídeo H.264 720p CRF 26 no FFmpeg de `-preset fast` para `-preset veryfast`, reduzindo pela metade o tempo de CPU com impacto mínimo de tamanho.
- **Empacotamento EPUB 3 com compressão ZIP seletiva (`STORE` vs. `DEFLATE`)**:
  - Configurar `CompressionType.none` (`STORE`) no `EpubPackagerService` para arquivos de mídia já comprimidos (`.mp4`, `.webp`, `.jpg`, `.jpeg`, `.png`, `.pdf`), aplicando `CompressionType.deflate` exclusivamente a arquivos textuais e metadados (`.xhtml`, `.css`, `.opf`, `.xml`, `.binarypb`).
- **Geração nativa do PDF Resumido sob demanda com `package:pdf`**:
  - Substituir a pipeline baseada em `Printing.convertHtml` (WebView + Base64) no `PdfPrintSummaryService` e `VisualizadorRelatorioScreen` por geração direta em Dart puro via `package:pdf` (`pw.MultiPage`), injetando os arquivos JPEG de 2MP pré-processados (`<uuid>_thumb.jpg` e `<uuid>_poster.jpg`) diretamente na árvore PDF (`/DCTDecode`) e desenhando QR Codes vetoriais nativamente.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability isolada; os requisitos evoluem capabilities existentes. -->

### Modified Capabilities
- `media-compressor`: Atualização dos requisitos de compressão para incluir pré-processamento assíncrono com escrita atômica, geração de miniaturas de impressão em JPEG de 2MP (`<uuid>_thumb.jpg`) a partir da imagem reduzida, poster de vídeo em JPEG (`<uuid>_poster.jpg`) e calibração FFmpeg com `-preset veryfast`.
- `epub3-report`: Atualização do empacotamento ZIP para armazenar mídias já comprimidas com `CompressionType.none` (`STORE`), reutilizar ativos pré-processados com fallback paralelo e suportar poster de vídeo em `.jpg`.
- `pdf-generator`: Substituição da conversão HTML/WebView por construção nativa via `package:pdf` sob demanda, consumindo diretamente as imagens JPEG de 2MP pré-processadas sem re-processamento ou codificação Base64.

## Impact

- `app/lib/features/media/services/media_compressor_service.dart`
- `app/lib/features/media/services/video_transcoder_service.dart`
- `app/lib/features/wizard/controllers/wizard_state_controller.dart`
- `app/lib/features/pdf_generation/providers/generation_provider.dart`
- `app/lib/core/services/epub_packager_service.dart`
- `app/lib/core/services/pdf_print_summary_service.dart`
- `app/lib/features/pdf_generation/views/visualizador_relatorio_screen.dart`
- Respectivos arquivos de teste espelhados em `app/test/`
