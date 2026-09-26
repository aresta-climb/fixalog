## Why

A geração do relatório técnico no fluxo de finalização do Wizard atualmente tenta gerar simultaneamente o documento canônico EPUB 3 e a versão resumida em PDF para impressão. Enquanto o EPUB 3 (com vídeos, fotos e assinatura XML-DSig) é gerado em menos de 2 segundos, a conversão do PDF pelo motor nativo de impressão consome de 15 a 30 segundos (ou atinge o timeout de segurança) porque injeta imagens completas de 4 Megapixels (2048x2048) codificadas em Base64 no HTML, sobrecarregando o processamento do Chromium/WebView em 600 DPI.

Além disso, o documento oficial e canônico do FixLog é o container EPUB 3; o PDF resumido é necessário apenas quando o usuário deseja explicitamente compartilhar ou imprimir a versão impressa para protocolos burocráticos e órgãos públicos. Esta mudança torna a conclusão do Wizard quase instantânea (< 2 segundos) desacoplando a geração do PDF e otimiza a conversão para levar ~1-2 segundos através de miniaturas de impressão leves pré-geradas na sessão.

## What Changes

- **Geração de miniaturas de impressão na compressão da sessão**: Durante o processamento das fotos no Wizard, o `MediaCompressorService` passa a gerar também uma versão miniatura leve de impressão (600x600 WebP, ~30-40 KB) salva no bundle da sessão (`<uuid>_thumb.webp`).
- **Geração do PDF sob demanda (Lazy)**: O pipeline principal do `generationProvider` no Wizard passa a gerar exclusivamente o container canônico EPUB 3 assinado digitalmente, concluindo a etapa de selagem do laudo em menos de 2 segundos.
- **Exportação do PDF no compartilhamento**: A geração do PDF Resumido é disparada sob demanda quando o usuário clica em "Versão Resumida (PDF)" na tela de visualização do relatório ou no Histórico.
- **Cache local do PDF gerado**: Uma vez gerado o PDF sob demanda, o arquivo é gravado no disco e associado ao registro da sessão (`SubmissionRecord.pdfPath`), permitindo compartilhamentos subsequentes instantâneos.
- **Injeção de miniaturas leves no HTML de impressão**: O serviço de exportação de PDF utiliza as miniaturas de ~40 KB em vez das imagens completas de 1.5 MB, reduzindo o HTML para < 200 KB e acelerando drasticamente o spooler de impressão nativo.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capacidade introduzida -->

### Modified Capabilities
- `pdf-generator`: A geração do PDF Resumido torna-se assíncrona/sob demanda no compartilhamento, consumindo miniaturas leves de impressão e mantendo cache em disco.
- `media-compressor`: Adiciona suporte à geração de miniaturas leves de impressão (600x600 WebP) no bundle da sessão durante a compressão de imagens.

## Impact

- **Código modificado**:
  - `app/lib/features/media/services/media_compressor_service.dart`: geração da miniatura de impressão no bundle.
  - `app/lib/features/pdf_generation/providers/generation_provider.dart`: remoção da geração síncrona do PDF durante a finalização do Wizard.
  - `app/lib/features/pdf_generation/views/visualizador_relatorio_screen.dart`: geração lazy do PDF ao selecionar a opção no modal de compartilhamento, com indicador de progresso.
  - `app/lib/features/home/views/history_screen.dart`: suporte à resolução ou geração sob demanda se o usuário solicitar o PDF pelo histórico.
- **Performance e UX**:
  - Tempo de conclusão do Wizard reduzido de ~25 segundos para < 2 segundos.
  - Tempo de geração do PDF Resumido reduzido de ~20-30 segundos para ~1,5 segundo.
