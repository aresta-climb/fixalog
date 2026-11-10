# Proposal

## Why

Os testes de campo com o primeiro laudo publicado em produção (`ae891eb0-5654-46d1-a62e-0dc4ff3c5502`) e a auditoria dos eventos no Sentry (`ARESTA-BACKEND-2`) revelaram cinco necessidades críticas de segurança, renderização, performance na borda, experiência de usuário e indexação:
1. **Moderação Fail-Closed, Licença do Llama 3.2 Vision e Keyframes Reais de Vídeo**: O modelo `@cf/meta/llama-3.2-11b-vision-instruct` no Cloudflare Workers AI lançou `AiError: 5016` exigindo o envio prévio de `{ prompt: "agree" }`, as fatias brutas de bytes `.mp4` não são imagens decodificáveis pela IA, a sub-requisição CSAM via `POST` batia em `404` (pois o CSAM Scanning Tool da Cloudflare opera sobre respostas `GET` de imagens na zona), e o pipeline operava em modo *fail-open* (aprovando o laudo mesmo quando o classificador falhava). O sistema precisa operar estritamente em modo **fail-closed** (falhando a verificação e disparando alerta de emergência `fatal` no Sentry caso CSAM ou Workers AI falhem) e empacotar no `.epub` miniaturas JPEG leves (`360p`) a cada 10 segundos de vídeo além do `_poster.jpg`.
2. **Descompressão DEFLATE e Caminhos `midias/` na Renderização Web (`GET /v/:id`)**: O Worker lia os bytes de `OEBPS/relatorio.xhtml` e `OEBPS/estilo.css` via *Byte-Range* do R2 sem descomprimir entradas com método `DEFLATE` (`metodo = 8`), despejando binário comprimido na página HTML, além de buscar apenas `midia/` no singular em vez de `midias/` no plural.
3. **Cache Imutável na Borda (`caches.default`) com TTL de 1 Ano**: Após a primeira abertura de um laudo ativo (`GET /v/:id`, `/v/:id/midias/*`, `/v/:id/epub`), a resposta deve ficar em cache na borda da Cloudflare (`caches.default` + `Cache-Control: public, max-age=31536000`) por 1 ano para não consumir leituras repetidas no D1/R2, com invalidação automática apenas quando uma nova versão (`v2`, `v3`...) for publicada ou quando o laudo sofrer denúncia/bloqueio.
4. **Botão de Cancelamento da Sincronização em 2º Plano e Retenção de 7 Dias em `staging/`**: O usuário precisa poder cancelar um upload em andamento tanto pelo botão na notificação *sticky* quanto pelo modal de publicação, pausando o reenvio automático daquele laudo enquanto o servidor preserva os blocos já enviados em `staging/` por 7 dias.
5. **Indexação para Buscadores (`/robots.txt`, `/sitemap.xml` e SEO)**: Os relatórios ativos precisam ser indexáveis pelo Google e outros crawlers através de um `/robots.txt`, um `/sitemap.xml` dinâmico alimentado pelo D1 e metadados canônicos/JSON-LD.

## What Changes

- **Moderação Fail-Closed, Auto-Agree do Llama 3.2 Vision, Rota GET para CSAM Scan e Alerta Fatal no Sentry**:
  - Atualizar `moderador_midia_ia.ts` e `index.ts` para expor a rota interna assinada por HMAC `GET /__csam_scan/:id/:versao/:caminho?token=<hmac>` servindo a imagem real com `Content-Type: image/*` através da zona `fixalog.app` para inspeção pelo Cloudflare CSAM Scanning Tool.
  - Em `moderador_midia_ia.ts`, tratar automaticamente o erro `5016` (`submit the prompt 'agree'`) enviando `{ prompt: "agree" }` ao `@cf/meta/llama-3.2-11b-vision-instruct` e repetindo a inferência.
  - Tornar a esteira estritamente **fail-closed**: qualquer falha técnica não recuperada na sub-requisição CSAM ou no Workers AI (ou ausência do binding `env.AI` em produção) DEVE abortar a aprovação, gravar `status_moderacao = 'bloqueado'` com `motivo_moderacao = 'ERRO_TECNICO_VERIFICACAO: ...'` no D1 e disparar um evento de emergência (`level: 'fatal'`) no Sentry e em `alertas.arestaclimb.com`.
- **Extração e Empacotamento de Keyframes Leves a Cada 10s de Vídeo no EPUB 3**:
  - Atualizar `VideoTranscoderService`, `MediaCompressorService` e `GenerationNotifier` para extrair via FFmpeg, além do `<uuid>_poster.jpg`, miniaturas JPEG altamente comprimidas (`360p`, `-q:v 14`, ~10 KB por quadro) a cada 10 segundos de vídeo (`<uuid>_kf_10s.jpg`, `<uuid>_kf_20s.jpg`, ...) e empacotá-las em `OEBPS/midias/` assinadas no `META-INF/signatures.xml`.
  - No Worker (`moderador_midia_ia.ts`), inspecionar todas as imagens empacotadas (`.webp`, `.jpg`, `.jpeg`, `.png`, incluindo `_poster.jpg` e `_kf_*s.jpg`) e exigir que todo vídeo `.mp4` possua ao menos seu `_poster.jpg` e keyframes correspondentes empacotados, sem enviar fatias brutas de stream `.mp4` para o modelo de visão.
- **Descompressão DEFLATE, Correção de Caminhos `midias/` e Cache na Borda de 1 Ano (`caches.default`)**:
  - Em `extrator_indice_epub.ts` e `index.ts`, descomprimir via `DecompressionStream("deflate-raw")` qualquer entrada com `metodo === 8` (`DEFLATE`) lida parcialmente do R2 (`OEBPS/relatorio.xhtml`, `OEBPS/estilo.css` e relatórios de materiais aninhados).
  - Em `renderizador_pagina_laudo.ts`, atualizar `reescreverCaminhosMidiaXhtml` e `extrairResumoMidiasDoIndice` para suportar tanto `midias/` (plural) quanto `midia/` (singular) e links `materiais/<uuid>/OEBPS/relatorio.xhtml`.
  - Adicionar cache na borda (`caches.default` + `Cache-Control: public, max-age=31536000, s-maxage=31536000, immutable`) com TTL de **1 ano** em `GET /v/:id`, `GET /v/:id/midias/*` e `GET /v/:id/epub` quando `status_moderacao == 'ativo'`, invalidando automaticamente as chaves do laudo em `caches.default` quando uma nova versão for publicada ou quando o laudo for denunciado/suspenso.
- **Cancelamento de Upload em 2º Plano (Notificação Sticky + Modal) e Expiração de 7 Dias no R2**:
  - Adicionar ação nativa `"Cancelar envio"` (`cancelar_upload`) na notificação *sticky* do `GerenciadorNotificacaoUploadLaudo` e botão `"CANCELAR ENVIO"` no modal de publicação da `VisualizadorRelatorioScreen`.
  - Adicionar suporte a cancelamento imediato (`cancelarPublicacao(idSessao)`) no `SincronizadorNuvemService`, interrompendo o envio de blocos/polling, fechando a notificação *sticky* e pausando o reenvio automático em 2º plano daquela sessão até que o usuário acione o compartilhamento novamente.
  - Ajustar `PRAZO_EXPIRACAO_STAGING_MS` no Worker para **7 dias** (`7 * 24 * 60 * 60 * 1000`), mantendo blocos já enviados disponíveis para retomada por 1 semana.
- **Indexação e Mapa de Site (`GET /robots.txt`, `GET /sitemap.xml` e Meta Tags SEO)**:
  - Adicionar `GET /robots.txt` e `GET /sitemap.xml` (listando todos os laudos com versão ativa no D1) no Worker `fixalog`, além de `<link rel="canonical">`, `<meta name="robots">` (`noindex, nofollow` em análise; `index, follow` quando ativo) e JSON-LD (`TechArticle`) nas páginas de laudos.

## Capabilities

### New Capabilities

### Modified Capabilities
- `worker-fixalog-nuvem`: Moderação *fail-closed* com auto-aceite da licença Llama 3.2 Vision, rota `GET /__csam_scan/*` para o CSAM Scanning Tool, alerta de emergência `fatal` no Sentry em falhas técnicas, descompressão `DEFLATE` na leitura parcial do R2, correção dos caminhos `midias/`, cache na borda (`caches.default`) com TTL de 1 ano e invalidação em novas versões/denúncias, retenção de `staging/` por 7 dias e rotas `/robots.txt` e `/sitemap.xml`.
- `sincronizacao-nuvem-laudos`: Botão de cancelamento de sincronização na notificação *sticky* e no modal de publicação, interrompendo imediatamente o envio e pausando a fila automática para o laudo cancelado.
- `epub3-report`: Extração via FFmpeg e empacotamento assinado no EPUB 3 de miniaturas JPEG leves (`360p`) de *keyframes* a cada 10 segundos de vídeo (`<uuid>_kf_<N>s.jpg`) além do `<uuid>_poster.jpg`.

## Impact

- **`../aresta_backend/cloudflare/fixalog`**: `src/moderador_midia_ia.ts`, `src/extrator_indice_epub.ts`, `src/renderizador_pagina_laudo.ts`, `src/index.ts`, `src/fakes/ambiente_fixalog_fake.ts` e respectivos testes `.test.ts`.
- **`../aresta_backend/supabase/functions/compartilhado/relator_sentry.ts`**: Suporte a nível de severidade customizável (`level: "error" | "fatal"`) no envelope do Sentry.
- **`fixalog/app`**: `lib/features/media/services/video_transcoder_service.dart`, `lib/features/media/services/media_compressor_service.dart`, `lib/features/pdf_generation/providers/generation_provider.dart`, `lib/core/services/gerenciador_notificacao_upload_laudo.dart`, `lib/core/services/sincronizador_nuvem_service.dart`, `lib/features/pdf_generation/views/visualizador_relatorio_screen.dart` e todos os arquivos `_test.dart` espelhados.
