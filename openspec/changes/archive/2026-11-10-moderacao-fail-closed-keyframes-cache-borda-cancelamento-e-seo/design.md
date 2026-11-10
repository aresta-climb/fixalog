# Design

## Context

Veja `proposal.md` para a motivação completa. Os testes reais com o laudo `ae891eb0-5654-46d1-a62e-0dc4ff3c5502` demonstraram a necessidade de:
1. Garantir que a moderação de mídias no Worker opere em modo **fail-closed** com disparo de emergência (`level: 'fatal'`) no Sentry caso qualquer classificador falhe, aceitando automaticamente a licença comunitária do modelo `@cf/meta/llama-3.2-11b-vision-instruct` (`{ prompt: "agree" }`) e inspecionando miniaturas reais de *keyframes* de vídeo extraídas a cada 10s pelo FFmpeg do cliente;
2. Descomprimir fluxos `DEFLATE` (`metodo === 8`) nas leituras parciais do R2 em `GET /v/:id` e corrigir a reescrita de caminhos `midias/` (plural);
3. Cachear na borda (`caches.default`) com TTL de 1 ano (`max-age=31536000`) as páginas e mídias de laudos ativos, invalidando-as apenas em novas versões ou denúncias;
4. Permitir cancelar o upload em 2º plano pela notificação *sticky* e pelo modal, retendo blocos em `staging/` por 7 dias;
5. Expor `/robots.txt`, `/sitemap.xml` e metadados SEO para indexação pelos buscadores.

## Goals / Non-Goals

**Goals:**
- Extrair via FFmpeg no app miniaturas JPEG leves (`scale=-2:360 -q:v 14`, ~10 KB cada) nos instantes `10s, 20s, 30s, 40s, 50s, 60s` até a duração do vídeo (`<uuid>_kf_<N>s.jpg`) e empacotá-las em `OEBPS/midias/`.
- Tornar `executarModeracaoAssincronaLaudo` estritamente **fail-closed**, com rota `GET /__csam_scan/:id/:versao/:caminho?token=<hmac>` para o Cloudflare CSAM Scanning Tool, auto-aceite da licença Llama 3.2 Vision em caso de erro `5016` e alerta `fatal` no Sentry + bloqueio preventivo se qualquer verificador falhar.
- Descomprimir `deflate-raw` em leituras parciais do R2 (`lerBytesEntradaR2`) e corrigir `reescreverCaminhosMidiaXhtml` para `midias?/`.
- Implementar cache de borda (`caches.default`) de 1 ano para `GET /v/:id`, `GET /v/:id/midias/*` e `GET /v/:id/epub`, com purga automática ao criar nova versão ou denunciar.
- Adicionar botão `"Cancelar envio"` na notificação *sticky* e no modal, cancelando imediatamente o envio no `SincronizadorNuvemService` e mantendo blocos em `staging/` por 7 dias no R2.
- Expor `GET /robots.txt` e `GET /sitemap.xml` e enriquecer `renderizarPaginaPublicaLaudo` com `canonical`, `robots` e JSON-LD.

**Non-Goals:**
- Decodificar vídeo H.264 em tempo real via WASM dentro do Worker (o FFmpeg nativo do app já realiza a transcodificação e extrai os *keyframes* assinados no `.epub`).

## Decisions

### 1. Extração de Keyframes Leves a Cada 10s no App (`VideoTranscoderService` + `MediaCompressorService`)
- **Decisão**: Adicionar `extrairKeyframesModeracao` em `VideoTranscoderService` e `extrairKeyframesVideoSessao` em `MediaCompressorService`. Para cada vídeo, além do `<uuid>_poster.jpg` (em `0.5s`), o serviço consulta a duração do vídeo (padrão até 60s) e extrai quadros nos segundos `10, 20, 30, 40, 50, 60` que forem menores que a duração (`-ss <t> -i "<video>" -vf scale=-2:360 -q:v 14 -vframes 1 -y "<uuid>_kf_<t>s.jpg"`).
- **Racional**: Na resolução `360p` com `-q:v 14`, cada JPEG pesa ~8–14 KB (~50 KB no total para um vídeo de 60s), preservando nitidez total para o PhotoDNA (CSAM) e para o Llama 3.2 11B Vision (`S4` / `S12`). Todos os arquivos `<uuid>_kf_<t>s.jpg` são empacotados em `OEBPS/midias/` e assinados no `META-INF/signatures.xml`. No servidor, `executarModeracaoAssincronaLaudo` verifica que todo `.mp4` possui seu `_poster.jpg` e inspeciona todas as imagens `.webp`, `.jpg`, `.jpeg` e `.png` do pacote.

### 2. Moderação Fail-Closed, Rota `GET /__csam_scan/*` e Alerta Fatal no Sentry
- **Decisão**:
  1. **Rota `GET /__csam_scan/:idSessao/:versao/:caminho`**: Assinada com token HMAC derivado do hash do `.epub` (`calcularSha256Hex("${idSessao}:${versao}:${caminho}:${ env.CSAM_SCAN_SECRET ?? 'fixalog_csam_internal' }")`), serve os bytes descomprimidos da imagem do R2 com `Content-Type: image/webp` ou `image/jpeg`. Durante a moderação, o Worker faz `GET https://fixalog.app/__csam_scan/...` (passando pelo proxy da zona `fixalog.app` onde o CSAM Scanning Tool atua sobre respostas `GET` de imagens). Se retornar `451` ou `403`, bloqueia com `CSAM_SCAN_TOOL_MATCH`. Se retornar qualquer status diferente de `200` ou lançar exceção de rede em produção, aciona **fail-closed**.
  2. **Auto-Agree do Llama 3.2 Vision**: Se `env.AI.run(MODELO_VISION_MODERACAO, ...)` lançar erro contendo `5016` ou `submit the prompt 'agree'`, o Worker executa `await env.AI.run(MODELO_VISION_MODERACAO, { prompt: "agree" })` e repete imediatamente a chamada de classificação da imagem.
  3. **Fail-Closed e Alerta Fatal**: Se `env.AI` não estiver disponível ou se `env.AI.run` falhar mesmo após o retry, o Worker **jamais** aprova o laudo: ele chama `relatarErroSentry` com `nivel: "fatal"`, aciona `dispararAlertaSegurancaFixalog` (`tipoEvento: "EMERGENCIA_FALHA_MODERACAO"`) e grava no D1 `status_moderacao = 'bloqueado'` e `motivo_moderacao = 'ERRO_TECNICO_VERIFICACAO: ...'`.

### 3. Descompressão `DEFLATE` no R2 e Cache de Borda de 1 Ano (`caches.default`)
- **Decisão**:
  - Criar `lerBytesEntradaDoR2(bucket, r2Key, entrada)` em `extrator_indice_epub.ts`: faz `bucket.get(r2Key, { range: { offset: entrada.offset, length: entrada.length } })` e, se `entrada.metodo === 8`, descomprime via `DecompressionStream("deflate-raw")`. Usar essa função em `GET /v/:id` para `OEBPS/relatorio.xhtml`, `OEBPS/estilo.css` e `OEBPS/materiais/*/relatorio.xhtml`.
  - Em `GET /v/:id`, `GET /v/:id/midias/*` (sem `Range` parcial) e `GET /v/:id/epub`, consultar `caches.default.match(chaveCache)` no início da requisição. Quando `status_moderacao === 'ativo'`, armazenar a resposta em `caches.default.put(chaveCache, res.clone())` com `Cache-Control: public, max-age=31536000, s-maxage=31536000, immutable`.
  - Ao criar uma nova versão em `processarPacoteEpubValidado` ou ao suspender um laudo em `POST /api/v1/laudos/:id/denunciar` / bloqueio, remover de `caches.default` as URLs canônicas do laudo (`https://fixalog.app/v/<id>` e `/sitemap.xml`).

### 4. Cancelamento de Sincronização em 2º Plano e Retenção de 7 Dias no R2
- **Decisão**:
  - No `GerenciadorNotificacaoUploadLaudo`, incluir `AndroidNotificationAction('cancelar_upload', 'Cancelar envio', showsUserInterface: true, cancelNotification: true)` na notificação *sticky* e expor `streamCancelamentosSolicitados` (além de callback `aoSolicitarCancelamento`).
  - No `SincronizadorNuvemService`, manter `_sessoesCanceladasPeloUsuario = <String>{}` e `_uploadsEmAndamentoCancelados = <String>{}`. O método `cancelarPublicacao(String idSessao)` marca a sessão como cancelada, interrompe o loop de envio de chunks e de polling, cancela a notificação *sticky* e emite `EtapaPublicacaoLaudo.canceladoPeloUsuario`. Enquanto `idSessao` estiver em `_sessoesCanceladasPeloUsuario`, `sincronizarPendentes()` (chamado em background) pula aquela sessão; quando o usuário toca explicitamente em **Compartilhar** (`publicarEAguardarLiberacao`), `idSessao` é removido de `_sessoesCanceladasPeloUsuario` e retoma o upload a partir dos chunks já salvos no R2!
  - No Worker (`index.ts`), alterar `PRAZO_EXPIRACAO_STAGING_MS` para `7 * 24 * 60 * 60 * 1000` (7 dias).

## Risks / Trade-offs

- **[Risco] Cache de borda servir página desatualizada após upload de `v2`** → **Mitigação**: `processarPacoteEpubValidado` e `POST /api/v1/laudos/:id/denunciar` invocam `purgarCacheBordaLaudo(env, idSessao)` removendo `https://fixalog.app/v/<id>` e `https://fixalog.app/sitemap.xml` de `caches.default`.
- **[Risco] Primeiro envio de imagem ao Llama 3.2 Vision retornar erro 5016 de licença** → **Mitigação**: Tratamento automático com envio imediato de `{ prompt: "agree" }` e retry transparente da mesma imagem antes de considerar falha técnica.
