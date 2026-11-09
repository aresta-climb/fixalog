# Design

## Context

Consulte `proposal.md` para a motivação completa. Atualmente:
1. O `SincronizadorNuvemService` só é acionado pelo botão manual de nuvem na `HistoryScreen` e envia o `.epub` inteiro em uma única requisição `PUT /api/v1/laudos/:id`, sem verificar previamente se o `sha256` já existe no servidor e sem suportar retomada caso a conexão de montanha caia no meio do upload.
2. Na `VisualizadorRelatorioScreen` (e ao abrir o relatório a partir do `GenerationProgressDialog`, que sequer passa `idSessao` ou `titulo`), clicar em Compartilhar disponibiliza 3 opções (EPUB, PDF e Link Web) e libera o link imediatamente sem verificar se o `.epub` já subiu nem se saiu de `status_moderacao == 'em_analise'`.
3. O aplicativo mantém `PdfPrintSummaryService` (~1.100 linhas), `PdfReportService`, `PdfDraftService` e `PdfViewerService` para duplicar localmente em PDF o que `OEBPS/relatorio.xhtml` + `OEBPS/estilo.css` (`@media print`) já fazem nativamente.
4. No Cloudflare Worker (`../aresta_backend/cloudflare/fixalog`), a página `GET /v/:id` não possui meta tags OpenGraph (`og:*`) para preview no WhatsApp, não anexa o corpo dos materiais embutidos (`OEBPS/materiais/<uuid>/OEBPS/relatorio.xhtml`) para impressão unificada no navegador e destaca o link de PDF no cabeçalho ao lado do `.epub`.

## Goals / Non-Goals

**Goals:**
- Eliminar 100% da geração local de PDF no aplicativo móvel, centralizando a impressão/exportação para PDF no navegador (`@media print` / `window.print()`) sobre o `.epub` em `https://fixalog.app/v/:id`.
- Garantir idempotência estrita por `{id_sessao, sha256}` e retomada de upload em blocos fixos de `512 KB` (`524.288 bytes`) para redes 3G/4G instáveis de montanha.
- Garantir que o link público nunca seja compartilhado pelo app enquanto `status_moderacao != 'ativo'`, exibindo um modal claro de progresso em 2 etapas (1. Upload dos blocos; 2. Verificação de segurança no servidor) ou aviso de ausência de internet.
- Executar sincronização periódica e de ciclo de vida em background que detecta Modo Avião / falta de rede em `0ms` via `NetworkInterface.list(includeLoopback: false)` sem drenar bateria.
- Fornecer resumo descritivo rico e meta tags OpenGraph (`og:title`, `og:description`, `og:image`, `og:url`) para preview automático no WhatsApp.

**Non-Goals:**
- Uso de plugins nativos de WorkManager do sistema operacional que rodem com o processo do app encerrado pelo OS (o agendador opera enquanto o processo do app está ativo, na abertura, no `AppLifecycleState.resumed`, após selar um laudo e em timer periódico com *backoff* quando há fila pendente).

## Decisions

### 1. Protocolo de Upload Retomável em Blocos de `512 KB` e Mapeamento `{id_sessao, sha256} -> versao`

- **Decisão**:
  1. O cliente calcula localmente `sha256Hex(epubBytes)` e divide `epubBytes` em blocos de `524288` bytes (`512 KB`).
  2. **Consulta prévia (`GET /api/v1/laudos/:id/status?sha256=<hash>`)**:
     - O Worker consulta `versoes_laudo_fixalog WHERE id_sessao = ? AND hash_epub_sha256 = ?` (ou a versão mais recente se `sha256` for omitido).
     - Se `{id_sessao, sha256}` já existir em `versoes_laudo_fixalog`, retorna `200 OK`:
       ```json
       {
         "id_sessao": "...",
         "sha256": "...",
         "ja_enviado": true,
         "versao": 2,
         "status_moderacao": "ativo",
         "chunks_recebidos": []
       }
       ```
     - Se ainda não existir em `versoes_laudo_fixalog`, o Worker lista os objetos temporários no R2 sob o prefixo `staging/<id_sessao>/<sha256>/chunk_` e retorna:
       ```json
       {
         "id_sessao": "...",
         "sha256": "...",
         "ja_enviado": false,
         "versao": null,
         "status_moderacao": null,
         "chunks_recebidos": [0, 1]
       }
       ```
  3. **Envio apenas dos blocos faltantes (`PUT /api/v1/laudos/:id/chunk?sha256=<hash>&index=<i>&total=<N>`)**:
     - Se `ja_enviado == true`, o cliente não envia nenhum bloco (e se chamar `PUT /chunk` ou `PUT /api/v1/laudos/:id` com um `sha256` já registrado para aquele `id_sessao`, o Worker retorna `409 Conflict` / `200 OK` com `ja_enviado: true` e os dados da versão pronta, sem criar versão duplicada).
     - Para cada índice `i` de `0` até `total - 1` que não esteja em `chunks_recebidos`, o cliente envia o bloco `i` para `PUT /api/v1/laudos/:id/chunk?sha256=<hash>&index=<i>&total=<N>`.
     - O Worker grava `staging/<id_sessao>/<sha256>/chunk_<i>` no R2.Quando todos os `total` blocos (`0..total-1`) estiverem presentes no R2 (verificado ao receber o último bloco `index == total - 1`), o Worker concatena os blocos em memória, verifica `calcularSha256Hex(epubCompleto) === sha256` e `verificarAssinaturaEpubXmlDsig`, grava `laudos/<id>/v<novaVersao>.epub`, insere a linha em `versoes_laudo_fixalog` com `status_moderacao = 'em_analise'`, remove os objetos `staging/<id_sessao>/<sha256>/*` e dispara `executarModeracaoAssincronaLaudo`.
- **Racional**: O limite mínimo de Multipart Upload nativo do S3/R2 é `5 MiB` por parte, o que impediria dividir laudos de `1 MB` a `4.5 MB`. O staging de blocos de `512 KB` no R2 funciona para qualquer tamanho de arquivo, fornece progresso real na UI a cada `512 KB` e garante que uma queda de sinal aos 80% preserve os blocos já salvos.

### 2. Agendador de Background Econômico com Verificação de Modo Avião (`AgendadorSincronizacaoBackground`)

- **Decisão**:
  - Criar `app/lib/core/services/agendador_sincronizacao_background.dart` integrando `SincronizadorNuvemService` e `ServicoFilaFeedback`.
  - Antes de qualquer ciclo de sincronização, invocar uma função injetável `Future<bool> Function() verificadorRedeAtiva` cuja implementação padrão executa:
    ```dart
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.any,
    );
    return interfaces.isNotEmpty;
    ```
  - Se retornar `false` (Modo Avião ou sem Wi-Fi/Dados Móveis), aborta imediatamente sem acordar o rádio ou chamar Firebase/Supabase.
  - O agendador é acionado:
    1. Ao selar um laudo (`GenerationNotifier.generateReport`);
    2. Na inicialização e ao retomar o app (`AppLifecycleState.resumed`);
    3. Em um timer periódico com *backoff* (`30s -> 60s -> 120s`) que permanece ativo apenas enquanto existirem laudos (`status == GERADO && !enviadoNuvem`) ou feedbacks pendentes no SQLite.

### 3. Remoção do Gerador de PDF Local e Impressão Web Unificada (`fixalog.app/v/:id`)

- **Decisão**:
  - Extrair o método estático `gerarQrCodeSvg` para `EpubDocumentBuilder.gerarQrCodeSvg` e remover `PdfPrintSummaryService`, `PdfReportService`, `PdfDraftService` e `PdfViewerService` do aplicativo Flutter.
  - Em `GenerationProgressDialog`, passar `idSessao` e `titulo` (adicionados ao `GenerationState`) para `VisualizadorRelatorioScreen`.
  - Na `VisualizadorRelatorioScreen`, remover toda a geração/compartilhamento de PDF local. O botão principal **Compartilhar** aciona o fluxo de compartilhamento do Link Web (`_compartilharLinkWebComVerificacao`), enquanto o menu secundário na `AppBar` permite exportar/abrir o arquivo `.epub` assinado local.
  - No Worker (`renderizador_pagina_laudo.ts` e `index.ts`):
    - Extrair de dentro do `.epub` no R2 não apenas `OEBPS/relatorio.xhtml`, mas também os `OEBPS/materiais/<uuid>/OEBPS/relatorio.xhtml` referenciados, anexando-os ao final da página dentro de `<section class="anexo-materiais-impressao">` para que, ao acionar **Exportar para PDF / Imprimir** (`window.print()` ou `?print=1`), o navegador imprima o laudo principal seguido das fichas completas dos materiais anexos.
    - Colocar a ação de PDF em um menu/botão secundário discreto (`Exportar PDF / Imprimir`) na barra superior e adicionar `@media print { .barra-verificacao-fixalog { display: none !important; } }` + disparo automático de `window.print()` quando `?print=1` estiver presente na URL.

### 4. Meta Tags OpenGraph (`og:*`) e Resumo Rico do Laudo

- **Decisão**:
  - Criar em `extrator_MetadadosXhtml` (no Worker) e no `SincronizadorNuvemService` (no App) a extração de um resumo estruturado a partir do XHTML/YAML do laudo:
    - **Título Rico**: `<Nome do Protocolo> — <Título da Via/Setor/Material>` (ex.: `Manutenção de Ferragens — Via Paredão Sul`).
    - **Descrição Rica (`og:description`)**: `Autor: <Nome> (<Clube>) • <N> itens/proteções • <F> foto(s), <V> vídeo(s) • Assinado digitalmente ECDSA P-256 (Fixalog v<Versão>)`.
    - **Imagem (`og:image`)**: Primeira imagem `OEBPS/midias/*.webp` ou `*.jpg` encontrada no `indices_zip_json`, exposta via URL absoluta `https://fixalog.app/v/<id>/midias/<caminho>?v=<versao>`.

## Risks / Trade-offs

- **[Blocos órfãos em `staging/` no R2 caso um upload seja abandonado para sempre]** → **Mitigação**: Os blocos temporários têm chave determinística `staging/<id_sessao>/<sha256>/chunk_<i>`, são removidos imediatamente na finalização do upload e podem ter regra de expiração de 7 dias no bucket R2.
- **[Moderação assíncrona demorar alguns segundos em laudos com muitos vídeos]** → **Mitigação**: Como o upload já começa em background no instante em que o usuário clica em "Selar Laudo", quando o usuário abre a visualização e clica em "Compartilhar", na maioria das vezes o upload e a moderação já terminaram ou estão nos segundos finais da Etapa 2.
