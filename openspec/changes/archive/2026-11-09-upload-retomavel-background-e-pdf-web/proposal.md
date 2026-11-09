# Proposal

## Why

Atualmente, quando o mantenedor sela ou re-edita um laudo no aplicativo, o upload para a nuvem (`fixalog.app`) não é disparado automaticamente nem aguarda o término da moderação antes de abrir o compartilhamento — resultando em erro `404 (Laudo não encontrado)` ao compartilhar o link, ausência de retomada caso a conexão de montanha caia no meio do envio e falta de meta tags OpenGraph (`og:*`) para preview rico no WhatsApp. Além disso, o aplicativo mantém mais de 1.500 linhas de código duplicadas (`PdfPrintSummaryService` e serviços auxiliares) apenas para recriar localmente em PDF o mesmo layout `@media print` que o container `.epub` já possui nativamente para impressão via navegador.

## What Changes

- **BREAKING (Simplificação Arquitetural — Remoção do Gerador de PDF Local no App)**:
  - Remover integralmente a geração local de arquivos PDF no aplicativo móvel (`PdfPrintSummaryService`, `PdfReportService`, `PdfDraftService`, `PdfViewerService` e a opção de gerar/compartilhar PDF em `VisualizadorRelatorioScreen`), mantendo apenas um utilitário enxuto de geração de QR Code SVG para o `EpubDocumentBuilder`.
  - Concentrar 100% da exportação para PDF na interface web pública (`https://fixalog.app/v/:id`) através de uma opção secundária/discreta (**"Exportar para PDF / Imprimir"**) que aciona o motor `@media print` do navegador sobre o `.epub` (incluindo automaticamente ao final do documento impresso as fichas completas dos materiais anexados em `OEBPS/materiais/<uuid>/OEBPS/relatorio.xhtml`).
- **Mapeamento `{id_sessao, sha256} -> versao` e Upload Retomável em Blocos (`512 KB`)**:
  - O cliente calcula o `sha256` do `.epub` localmente e consulta `GET /api/v1/laudos/:id/status?sha256=<hash>` antes de enviar bytes.
  - Se o par `{id_sessao, sha256}` já existir no servidor, o upload é rejeitado/dispensado com aviso de que aquela versão exata já foi enviada, retornando a versão existente e seu `status_moderacao` atual (`ativo` ou `em_analise`). Uma nova versão (`v<N+1>`) só é criada quando um `sha256` inédito é enviado para aquele `id_sessao`.
  - Para evitar re-enviar dados já transmitidos quando o sinal 3G/4G de montanha cai no meio do envio, o `.epub` é transmitido em blocos fixos de `512 KB` (`PUT /api/v1/laudos/:id/chunk?sha256=<hash>&index=<i>&total=<N>`). Caso a conexão caia, a consulta de status informa quais blocos (`chunks_recebidos`) o servidor já possui no R2 para aquele `sha256`, retomando o envio exatamente do bloco onde parou.
- **Disparo Automático ao Selar e Agendador de Background Econômico (Modo Avião)**:
  - Ao finalizar a selagem de qualquer laudo ou material (`GenerationNotifier`), o upload em segundo plano é iniciado imediatamente no `SincronizadorNuvemService` (com *single-flight* por `idSessao` e progresso observável).
  - Um serviço agendador periódico e reativo ao ciclo de vida (`AgendadorSincronizacaoBackground`) processa periodicamente as filas pendentes de laudos (`SincronizadorNuvemService`) e de feedbacks (`ServicoFilaFeedback`), verificando antes `NetworkInterface.list(includeLoopback: false)` para abortar instantaneamente em `0ms` caso o dispositivo esteja em **Modo Avião** ou sem interface de rede ativa (preservando bateria) e desligando o timer quando não houver itens pendentes.
- **Fluxo de Compartilhamento Seguro no App (Aguardando Saída de `em_analise`)**:
  - Ao clicar em **Compartilhar** na `VisualizadorRelatorioScreen` (ou abrir o relatório recém-selado a partir do `GenerationProgressDialog` passando `idSessao` e `titulo` reais), o app nunca libera o link enquanto o laudo estiver pendente de upload ou com `status_moderacao == 'em_analise'`.
  - Exibe um modal de progresso em duas etapas (**1. Enviando laudo para fixalog.app** com barra de progresso dos blocos -> **2. Verificando integridade e mídias no servidor** via polling de status) e só abre a gaveta nativa de compartilhamento com o resumo descritivo e o link `https://fixalog.app/v/<idSessao>` quando o servidor confirmar `status_moderacao == 'ativo'`.
  - Caso o dispositivo esteja sem internet no momento do clique em Compartilhar, exibe um aviso claro informando que é necessária conexão com a internet para publicar o laudo e gerar o link de compartilhamento.
- **Resumo Descritivo Rico e Meta Tags OpenGraph (`og:*`) para WhatsApp**:
  - Extração de um resumo estruturado do laudo (protocolo, nome da via/setor/material, autor/clube, quantidade de itens/proteções e mídias) tanto para o texto compartilhado pelo app quanto para as meta tags OpenGraph (`og:title`, `og:description`, `og:image`, `og:url`, `og:type`, `twitter:card`) renderizadas pelo Worker em `GET /v/:id` (apontando `og:image` para a primeira foto do laudo).

## Capabilities

### New Capabilities

### Modified Capabilities
- `sincronizacao-nuvem-laudos`: Adiciona disparo imediato de upload em background ao selar laudo, protocolo de upload retomável em blocos de `512 KB` indexado por `{id_sessao, sha256}`, agendador periódico econômico com detecção de Modo Avião (`NetworkInterface.list`) e bloqueio de compartilhamento até confirmação remota de `status_moderacao == 'ativo'`.
- `worker-fixalog-nuvem`: Adiciona endpoint `GET /api/v1/laudos/:id/status?sha256=<hash>`, upload retomável por blocos (`PUT /api/v1/laudos/:id/chunk`), deduplicação/versionamento estrito por `{id_sessao, hash_epub_sha256}`, meta tags OpenGraph (`og:title`, `og:description`, `og:image`) para preview no WhatsApp, concatenação de materiais anexos para `@media print` e botão discreto de exportação/impressão de PDF no navegador.
- `pdf-generator`: Substitui a geração nativa de PDF no aplicativo móvel pela geração de PDF no navegador (`@media print` / `window.print()`) a partir do `.epub` publicado em `fixalog.app/v/:id`.

## Impact

- **Aplicativo Flutter (`fixalog/app`)**:
  - Remoção de `app/lib/core/services/pdf_print_summary_service.dart`, `app/lib/core/services/pdf_report_service.dart`, `app/lib/core/services/pdf_viewer_service.dart`, `app/lib/features/pdf_generation/services/pdf_draft_service.dart` e seus respectivos testes espelhados, movendo a geração de QR Code SVG para `app/lib/core/services/gerador_qr_code_svg.dart` (ou `EpubDocumentBuilder`).
  - Evolução de `app/lib/core/services/sincronizador_nuvem_service.dart` (upload retomável em blocos de `512 KB`, cálculo de `sha256`, consulta de status/moderação e progresso observável) e criação de `app/lib/core/services/agendador_sincronizacao_background.dart`.
  - Atualização de `GenerationNotifier`, `GenerationProgressDialog`, `VisualizadorRelatorioScreen` e `HistoryScreen`.
- **Cloudflare Worker e Contrato OpenAPI (`../aresta_backend`)**:
  - Evolução de `../aresta_backend/aresta_api/openapi/fixalog.yaml`, `../aresta_backend/cloudflare/fixalog/src/index.ts` e `../aresta_backend/cloudflare/fixalog/src/renderizador_pagina_laudo.ts`.
