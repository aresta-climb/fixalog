## Context

O relatório canônico e auditável do FixLog é o container EPUB 3 (XHTML responsivo assinado via XML-DSig contendo fotos em 2048x2048 e vídeos em 720p). O PDF Resumido para protocolo burocrático e órgãos públicos é derivado da mesma árvore XHTML semântica utilizando estilos `@media print`.

Ver `proposal.md` para motivação e problemas de performance identificados na implementação anterior.

## Goals / Non-Goals

**Goals:**
- Desacoplar a geração do PDF do fluxo do Wizard, reduzindo o tempo de conclusão da vistoria de ~25s para menos de 2s.
- Gerar miniaturas leves de impressão (máximo 600x600 px em WebP, qualidade 70, ~30-40 KB) no bundle da sessão (`<uuid>_thumb.webp`) durante o processamento das fotos.
- Gerar o PDF Resumido sob demanda com feedback visual rápido quando o usuário clica em "Versão Resumida (PDF)".
- Persistir o caminho do PDF gerado no Isar (`SubmissionRecord.pdfPath`) para compartilhamentos subsequentes instantâneos.
- Preservar o XHTML com `@media print` como fonte única da verdade para design e apresentação visual, sem duplicar código com widgets de PDF.

**Non-Goals:**
- Não alterar a calibração de alta qualidade das imagens do EPUB 3 (que continuam em 2048x2048 a 85% de qualidade).
- Não reescrever o PDF em widgets imperativos (`package:pdf`), preservando a consistência com o visualizador XHTML.

## Decisions

### Decisão 1: Pré-geração de miniaturas no bundle da sessão
- **Abordagem**: Durante o método `comprimirFotoSessao` em `MediaCompressorService`, além de salvar `<uuid>.webp` (2048x2048), salva-se também `<uuid>_thumb.webp` (600x600).
- **Racional**: A compressão nativa via `FlutterImageCompress` leva apenas ~15-20 ms adicionais por foto no Wizard. Quando o PDF for solicitado, não há overhead de processamento de imagem; o HTML é montado imediatamente lendo os bytes das miniaturas.
- **Alternativa considerada**: Redimensionar em memória no momento de gerar o PDF. Descartada para manter o serviço de exportação de PDF focado em formatação e sem dependência direta de compressores de imagem.

### Decisão 2: Uso de Data URIs em Base64 com miniaturas leves
- **Abordagem**: Injetar as miniaturas no HTML de impressão utilizando `data:image/webp;base64,...`.
- **Racional**: O Android WebView bloqueia acessos a esquemas `file://` por padrão no Android 11+ porque o plugin `printing` não expõe `setAllowFileAccess(true)`. Com miniaturas de 30-40 KB, o documento HTML completo tem menos de 200 KB, que o Chromium processa e imprime em ~1 a 2 segundos.
- **Alternativa considerada**: Tentar passar URLs `file://`. Descartada por incompatibilidade comprovada com a sandbox do WebView no Android 11+.

### Decisão 3: Geração sob demanda com indicador no `VisualizadorRelatorioScreen`
- **Abordagem**: No método `_compartilharPdf()`, se `_caminhoPdfFinal` for nulo, exibe um diálogo de progresso simples ("Gerando PDF resumido..."), executa `_pdfSummaryService.exportarPdfResumido()`, atualiza o registro no banco Isar e prossegue com o compartilhamento nativo.
- **Racional**: Evita qualquer atraso prévio para usuários que só querem visualizar ou compartilhar o EPUB canônico.

## Risks / Trade-offs

- **[Risco] Laudos legados ou antigos sem arquivo `_thumb.webp` pré-existente**
  → **Mitigação**: O `PdfPrintSummaryService` verifica se a miniatura existe; caso contrário, faz fallback gracioso para a imagem `<uuid>.webp` principal.
- **[Risco] Timeout ou falha no motor nativo de impressão em dispositivos com pouca memória**
  → **Mitigação**: Manter timeout de segurança de 15 segundos com bloco try/catch e mensagem amigável ao usuário via SnackBar em caso de exceção.
