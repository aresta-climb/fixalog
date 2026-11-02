# Design

## Context

Consulte `proposal.md` para a motivação completa. Atualmente:
1. O `WizardStateController` salva apenas os arquivos brutos (`<uuid>_original.jpg`, `<uuid>_original.mp4`, `<uuid>_original.pdf` e `<uuid>_p<N>_original.jpg`) durante o preenchimento. Toda a compressão WebP, re-rasterização de PDF e transcodificação FFmpeg acontece de forma sequencial dentro de `GenerationNotifier.startGeneration`.
2. Para cada foto, `MediaCompressorService.comprimirImagemSessao` decodifica a foto original de alta resolução duas vezes (uma para gerar `_thumb.webp` de 600px e outra para gerar `.webp` de 2048px). Além disso, `rasterizarDocumentoPdfSessao` re-executa `Printing.raster` sobre o PDF original mesmo quando as páginas já foram extraídas pelo `SeletorDocumentoService` no Wizard.
3. `EpubPackagerService.empacotarEpub` aplica `CompressionType.deflate` em Dart puro a todos os arquivos do pacote, desperdiçando dezenas de segundos de CPU sobre vídeos `.mp4` e imagens `.webp`.
4. `PdfPrintSummaryService` e `VisualizadorRelatorioScreen` constroem uma string HTML gigante com todas as imagens codificadas em Base64 e invocam `Printing.convertHtml` (WebView do sistema + `PrintDocumentAdapter` IPC do Android).

## Goals / Non-Goals

**Goals:**
- Reduzir o tempo percebido de selagem do EPUB 3 ao final do Wizard por meio de pré-processamento em segundo plano com escrita atômica, paralelismo controlado, calibração FFmpeg `-preset veryfast` e armazenamento `STORE` (`CompressionType.none`) para mídias no ZIP.
- Reduzir o tempo de geração sob demanda do PDF Resumido para ~1 segundo construindo o PDF diretamente via `package:pdf` (`pw.MultiPage`) e embutindo imagens JPEG de 2MP (`<uuid>_thumb.jpg` e `<uuid>_poster.jpg`) sem recodificação de pixels (`/DCTDecode`).

**Non-Goals:**
- Alterar o esquema Protobuf (`registro.proto` / `wizard.proto`) ou o formato criptográfico `META-INF/signatures.xml` (W3C XML-DSig).
- Introduzir serviços nativos em segundo plano do sistema operacional (`WorkManager` / `ForegroundService`); a garantia contra fechamento abrupto do app é assegurada pela escrita atômica (`.tmp` -> `rename`) combinada à reconciliação paralela no `startGeneration`.

## Decisions

### 1. Coordenador de Pré-processamento em Background com Escrita Atômica e Reconciliação Final
- **Decisão**: Centralizar no `MediaCompressorService` o controle de tarefas de compressão por `(sessionId, mediaUuid)` mantendo um mapa em memória de `Future`s em andamento (`_tarefasEmAndamento`) e utilizando um semáforo/pool de concorrência (até 3 imagens simultâneas; 1 vídeo FFmpeg por vez em paralelo às imagens).
  - Toda gravação de mídia derivada escreve primeiro em `<caminho>.tmp` e executa `renameSync`/`rename` para o caminho definitivo somente ao concluir com bytes válidos (`length > 0`).
  - No `WizardStateController`, logo após salvar `<uuid>_original.*` (e páginas `<uuid>_p<N>_original.jpg`), dispara-se de forma não-bloqueante (`unawaited`) o pré-processamento no `MediaCompressorService`.
  - No `GenerationNotifier.startGeneration`, cada mídia chama o mesmo método de `MediaCompressorService`:
    - Se o arquivo final já existir em disco (`existsSync() && lengthSync() > 0`), retorna imediatamente sem re-processar.
    - Se houver uma `Future` em andamento para aquela mídia em `_tarefasEmAndamento`, aguarda a mesma `Future`.
    - Caso contrário, executa o processamento (com `Future.wait` em lotes paralelos para as imagens pendentes).
- **Alternativas consideradas**:
  - *Processar apenas no final em paralelo*: ainda deixaria toda a carga de FFmpeg e compressão acumulada no momento do clique em "GERAR RELATÓRIO".

### 2. Pipeline de Imagem em Dois Estágios: Original -> 4MP WebP (EPUB) -> 2MP JPEG (PDF)
- **Decisão**:
  - Estágio 1: A partir de `<uuid>_original.jpg/png` (ou `<uuid>_p<N>_original.jpg` já extraído pelo `SeletorDocumentoService`), gerar `<uuid>.webp` (`2048x2048`, qualidade 85, `CompressFormat.webp`) para o EPUB 3.
  - Estágio 2: A partir do próprio `<uuid>.webp` recém-gerado (que já está em 4MP, muito mais leve de decodificar que o original de 12–48MP da câmera), gerar `<uuid>_thumb.jpg` (`1440x1440` ~2MP, qualidade 80, `CompressFormat.jpeg`) para o PDF Resumido.
  - Para vídeos: extrair o poster aos 0.5s diretamente como `<uuid>_poster.jpg` (usado tanto no `<video poster="midias/<uuid>_poster.jpg">` do EPUB 3 quanto no PDF Resumido).
  - Parar de gerar `_thumb.webp` de 600px.
- **Racional**: O formato PDF incorpora streams JPEG diretamente via filtro `/DCTDecode` sem decodificar nem recomprimir pixels em Dart (`pw.MemoryImage`), tornando a inserção de dezenas de fotos de 2MP praticamente instantânea (< 5 ms).

### 3. Reaproveitamento das Páginas de PDF Já Extraídas no Wizard
- **Decisão**: Em `MediaCompressorService.rasterizarDocumentoPdfSessao`, verificar primeiro se já existem páginas `<uuid>_p<N>.webp` prontas ou `<uuid>_p<N>_original.jpg` extraídas pelo `SeletorDocumentoService` no momento do anexo. Só invocar `Printing.raster` sobre `<uuid>_original.pdf` como fallback caso as páginas não tenham sido extraídas previamente.

### 4. Compressão Seletiva no `EpubPackagerService` (`STORE` para Mídias, `DEFLATE` para Textos)
- **Decisão**: Em `EpubPackagerService.empacotarEpub`, criar um método auxiliar `_deveArmazenarSemCompressao(String caminho)` que retorna `true` para `.mp4`, `.webp`, `.jpg`, `.jpeg`, `.png` e `.pdf`, atribuindo `..compression = CompressionType.none` aos respectivos `ArchiveFile` (tanto em `OEBPS/midias/` quanto em `OEBPS/materiais/`). Arquivos `.xhtml`, `.css`, `.opf`, `.xml` e `.binarypb` permanecem com `CompressionType.deflate`.

### 5. Construção Nativa do PDF Resumido com `package:pdf` em `PdfPrintSummaryService`
- **Decisão**: Refatorar `PdfPrintSummaryService.gerarPdfResumidoBytes` para construir o documento PDF A4 diretamente via `package:pdf` (`pw.Document` / `pw.MultiPage`), utilizando:
  - `pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: ...)` para os QR Codes institucionais e de cada vídeo (100% vetoriais, sem necessidade de converter SVG em Base64).
  - `pw.MemoryImage(bytesJpeg)` alimentado pelos bytes dos arquivos `<uuid>_thumb.jpg` (2MP) e `<uuid>_poster.jpg` pré-processados (com fallback para decodificação caso um material externo possua apenas `.webp`).
  - Renderização estruturada de cabeçalho de versão resumida, metadados da sessão, respostas (com formatação Markdown: cabeçalhos, listas, negrito, itálico, código, tachado e parágrafos), itens de listas repetidas, páginas de documentos PDF anexados e seções de fichas técnicas dos `materiaisAnexos`.
  - Manter `gerarHtmlParaImpressao` e `gerarQrCodeSvg` para compatibilidade com a geração de QR Codes SVG do EPUB 3 e testes unitários de marcação.

## Risks / Trade-offs

- **[Risco] Consumo de memória ao pré-processar muitas fotos de câmera simultaneamente** → Mitigação: Limitar o pool de compressão de imagens em segundo plano a no máximo 3 tarefas concorrentes e 1 tarefa FFmpeg de vídeo por vez.
- **[Risco] Sessões antigas ou materiais aninhados que só possuam `.webp` sem `_thumb.jpg`** → Mitigação: Ao montar o PDF Resumido, caso `<uuid>_thumb.jpg` não exista em disco, converter o `<uuid>.webp` existente para `.jpg` sob demanda (e salvar em cache como `<uuid>_thumb.jpg` na sessão) antes de passar ao `package:pdf`.
