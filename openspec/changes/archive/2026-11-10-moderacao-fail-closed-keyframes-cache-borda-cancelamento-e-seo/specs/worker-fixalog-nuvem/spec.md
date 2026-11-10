# Spec Delta

## ADDED Requirements

### Requirement: Cache Imutável na Borda de 1 Ano com Invalidação em Novas Versões e Denúncias
Ao servir um relatório ou mídia com `status_moderacao == 'ativo'` em `GET /v/:id`, `GET /v/:id/midias/*` e `GET /v/:id/epub`, o Worker DEVE (MUST) armazenar e consultar a resposta na Cache API de borda da Cloudflare (`caches.default`) com cabeçalho `Cache-Control: public, max-age=31536000, s-maxage=31536000, immutable` (TTL de 1 ano), respondendo diretamente da borda após a primeira abertura sem consultar o D1 ou o R2. Quando uma nova versão (`v2`, `v3`...) de um laudo for aprovada ou quando um laudo sofrer denúncia/bloqueio, o Worker DEVE (MUST) invalidar (`caches.default.delete`) as entradas de cache correspondentes àquele `id_sessao`.

#### Scenario: Segunda abertura de laudo ativo servida diretamente do cache de borda sem acionar D1 ou R2
- **WHEN** um visitante abre `GET https://fixalog.app/v/<id>` pela primeira vez após `status_moderacao == 'ativo'` e um segundo visitante requisita a mesma URL em seguida
- **THEN** a primeira requisição popula `caches.default` com `Cache-Control: public, max-age=31536000, s-maxage=31536000, immutable` e a segunda requisição é respondida imediatamente pelo cache de borda sem executar queries no D1 ou leituras no R2

#### Scenario: Invalidação automática do cache de borda ao publicar nova versão ou receber denúncia
- **WHEN** o autor publica uma nova versão (`v2`) de um laudo já cacheado ou um leitor registra uma denúncia em `POST /api/v1/laudos/:id/denunciar`
- **THEN** o Worker remove a entrada de `https://fixalog.app/v/<id>` do `caches.default` para que a próxima leitura reflita imediatamente a nova versão ou o status suspenso

### Requirement: Indexação para Buscadores via robots.txt, sitemap.xml e Metadados Estruturados
O Worker DEVE (MUST) disponibilizar `GET /robots.txt` (permitindo o rastreamento de `/v/`, bloqueando `/api/` e `/__csam_scan/`, e declarando `Sitemap: https://fixalog.app/sitemap.xml`) e `GET /sitemap.xml` gerado dinamicamente a partir dos laudos com versão ativa no D1 (`status_moderacao == 'ativo'`). Nas páginas de laudo (`GET /v/:id`), o Worker DEVE (MUST) emitir `<meta name="robots" content="noindex, nofollow" />` enquanto `status_moderacao == 'em_analise'` e `<meta name="robots" content="index, follow" />`, `<link rel="canonical" href="https://fixalog.app/v/<id>" />` e dados estruturados JSON-LD (`TechArticle`) quando `status_moderacao == 'ativo'`.

#### Scenario: Consulta ao robots.txt e ao sitemap.xml por indexadores de busca
- **WHEN** um crawler requisita `GET https://fixalog.app/robots.txt` e `GET https://fixalog.app/sitemap.xml`
- **THEN** `/robots.txt` aponta para `https://fixalog.app/sitemap.xml` e `/sitemap.xml` retorna um documento XML `<urlset>` válido contendo exclusivamente as URLs `https://fixalog.app/v/<id_sessao>` cujas versões atuais estejam com `status_moderacao == 'ativo'`

## MODIFIED Requirements

### Requirement: Visualizador Web (`fixalog.app/v/:id`) com Barra de Verificação Criptográfica e Seletor de Versões
Ao acessar `GET https://fixalog.app/v/:id` (ou `?v=<N>`), para um laudo com `status_moderacao = 'ativo'`, o Worker DEVE (MUST) ler e descomprimir (suportando tanto entradas `STORE` `metodo = 0` quanto entradas comprimidas com `DEFLATE` `metodo = 8` via `DecompressionStream("deflate-raw")`) o relatório `OEBPS/relatorio.xhtml`, a folha `OEBPS/estilo.css` e as seções dos materiais anexados (`OEBPS/materiais/<uuid>/OEBPS/relatorio.xhtml`), reescrevendo caminhos relativos de mídia (`midias/...` no plural e `midia/...` no singular) e links de materiais (`materiais/<uuid>/OEBPS/relatorio.xhtml` e `materiais/<uuid>/relatorio.xhtml`), acompanhados de uma barra superior fixa de verificação pericial contendo:
- Selo de verificação criptográfica da assinatura ECDSA (`META-INF/signatures.xml`) e validação do vínculo OIDC Google/Apple + App Check;
- Nome do mantenedor, Clube/Associação e data/hora da assinatura;
- *Fingerprint* abreviado da chave pública (`SHA-256`) e **contador dinâmico** do total de laudos ativos assinados por aquela chave pública;
- Seletor de histórico de versões (`v1`, `v2`, ...) permitindo inspecionar qualquer versão anterior e ver se houve mudança de chave entre versões;
- Botão principal para baixar o pacote `.epub` original assinado, opção secundária/discreta para exportar/imprimir em `.pdf` pelo navegador (`window.print()`) e botão **"Denunciar relatório"**.

#### Scenario: Renderização de relatório cujo XHTML e CSS estão comprimidos com DEFLATE no EPUB
- **WHEN** um navegador acessa `GET https://fixalog.app/v/<id>` de um laudo ativo cujo `OEBPS/relatorio.xhtml` e `OEBPS/estilo.css` estão armazenados com método ZIP `DEFLATE` (`metodo = 8`) e referenciam imagens em `midias/<uuid>.webp`
- **THEN** o Worker descomprime os fluxos `deflate-raw`, injeta o CSS e o HTML legíveis na página e reescreve os atributos `src`/`poster`/`href` de `midias/...` para `/v/<id>/midias/OEBPS/midias/...`

#### Scenario: Abertura de relatório via QR Code de vídeo rola até o vídeo e exibe dados criptográficos
- **WHEN** um usuário escaneia um QR Code apontando para `https://fixalog.app/v/<id>#video-<uuid>` de um laudo ativo
- **THEN** a página web carrega a barra superior de verificação criptográfica (com autor, clube, *fingerprint*, contagem atualizada de laudos da chave e versão atual) e posiciona a rolagem diretamente no elemento `<div id="video-<uuid>">` pronto para reprodução

#### Scenario: Inspeção de versão anterior pelo seletor de versões
- **WHEN** um laudo possui versões `v1` e `v2` e o leitor seleciona `v1` no seletor da barra superior (`https://fixalog.app/v/<id>?v=1`)
- **THEN** o Worker renderiza o conteúdo, as mídias e os metadados de assinatura correspondentes exatamente ao arquivo `laudos/<id>/v1.epub`, exibindo um aviso de que existe uma versão mais recente (`v2`)

### Requirement: Gatekeeper de Moderação CSAM e NSFW em 3 Camadas com Extração de I-Frames no Servidor
Todo laudo recém-enviado DEVE (MUST) iniciar obrigatoriamente com `status_moderacao = 'em_analise'`, permanecendo inacessível ao público (exibindo tela de processamento em `GET /v/:id` e bloqueando `GET /v/:id/midias/*`) até a conclusão da auditoria de segurança em segundo plano (`ctx.waitUntil`). O pipeline de moderação no Worker DEVE (MUST) operar estritamente em modo **fail-closed** (nunca aprovando o laudo se qualquer etapa de verificação falhar):
1. Extrair diretamente do `.epub` no servidor todas as imagens (`.webp`, `.jpg`, `.jpeg`, `.png`), incluindo obrigatoriamente o *poster* (`<uuid>_poster.jpg`) e as miniaturas de *keyframes* a cada 10s (`<uuid>_kf_<N>s.jpg`) de cada vídeo `.mp4` (rejeitando o laudo caso exista um `.mp4` sem seu `_poster.jpg` correspondente), registrando inicialmente `verificacao_total` e `verificacao_concluida = 0` na tabela `versoes_laudo_fixalog` do D1;
2. Submeter cada imagem extraída a uma requisição `GET https://fixalog.app/__csam_scan/:id/:versao/:caminho?token=<hmac>` na zona `fixalog.app` (que serve os bytes reais da imagem com `Content-Type: image/*` para inspeção na borda pelo **Cloudflare CSAM Scanning Tool** PhotoDNA NCMEC/Interpol);
3. Classificar cada imagem completa no **Cloudflare Workers AI** (`@cf/meta/llama-3.2-11b-vision-instruct` com categorias de segurança `S4: Child Sexual Exploitation` e `S12: Sexual Content`). Caso o Workers AI retorne o erro `5016` exigindo aceite de licença (`submit the prompt 'agree'`), o Worker DEVE enviar automaticamente `{ prompt: "agree" }` ao modelo e repetir a classificação da imagem na mesma execução;
4. Atualizar incrementalmente `verificacao_concluida` no D1 a cada imagem inspecionada.
Se todas as imagens forem aprovadas sem erros técnicos, o Worker DEVE (MUST) atualizar `status_moderacao = 'ativo'` e `verificacao_concluida = verificacao_total`. Se qualquer imagem for sinalizada por CSAM ou NSFW, o Worker DEVE (MUST) definir `status_moderacao = 'bloqueado'` e disparar alerta imediato para `alertas.arestaclimb.com` e Sentry. Se ocorrer **qualquer falha técnica** na sub-requisição CSAM ou no Workers AI (ou ausência do binding `env.AI`), o Worker DEVE (MUST) abortar a aprovação (**fail-closed**), definir `status_moderacao = 'bloqueado'` com `motivo_moderacao = 'ERRO_TECNICO_VERIFICACAO: ...'` e disparar um evento de **emergência (`level: 'fatal'`)** no Sentry e em `alertas.arestaclimb.com`.

#### Scenario: Bloqueio preventivo enquanto o relatório está em análise
- **WHEN** alguém acessa `https://fixalog.app/v/<id>` ou qualquer rota de mídia `/v/<id>/midias/*` enquanto `status_moderacao` é `'em_analise'`
- **THEN** o Worker não entrega nenhuma imagem, vídeo ou arquivo `.epub` e retorna uma página informando que o relatório está passando pela verificação automática de integridade e segurança

#### Scenario: Aprovação automática de laudo contendo apenas fotos e vídeos legítimos de escalada
- **WHEN** o pipeline assíncrono no Worker analisa todas as fotos, posters e keyframes de vídeo (`_kf_*s.jpg`) via `GET /__csam_scan/*` e Workers AI (incluindo auto-envio de `{ prompt: "agree" }` se solicitado pelo erro `5016`) e nenhum sinal CSAM/NSFW ou erro técnico ocorre
- **THEN** o Worker incrementa `verificacao_concluida` no D1 a cada amostra e, ao finalizar, atualiza `status_moderacao` para `'ativo'` no D1 e libera a visualização pública em `https://fixalog.app/v/<id>`

#### Scenario: Bloqueio imediato e alerta quando um I-Frame de vídeo ou foto contém conteúdo impróprio
- **WHEN** qualquer foto, poster ou keyframe de vídeo é classificado como impróprio (`S4` ou `S12` no Workers AI ou `451`/`403` no CSAM Scanning Tool)
- **THEN** o Worker atualiza `status_moderacao = 'bloqueado'`, bloqueia o acesso público ao pacote e envia notificação imediata de incidente para `alertas.arestaclimb.com` e Sentry

#### Scenario: Resiliência quando o modelo Workers AI lança erro técnico inesperado
- **WHEN** a sub-requisição `GET /__csam_scan/*` ou a chamada `env.AI.run` falha com erro técnico mesmo após a tentativa de recuperação
- **THEN** o Worker opera em modo *fail-closed* (NÃO aprova o laudo), grava `status_moderacao = 'bloqueado'` com `motivo_moderacao` indicando a falha de verificação e envia um alerta de emergência com `level: "fatal"` para o Sentry e `alertas.arestaclimb.com`

### Requirement: Limpeza Automática de Blocos Temporários Expirados Após 14 Dias
O Worker DEVE (MUST) executar uma rotina agendada (*Cron Trigger* via `scheduled`) que inspeciona periodicamente os objetos temporários em `staging/` no bucket R2 `fixalog-laudos` e remove exclusivamente os blocos cujo `uploaded` tenha mais de **7 dias**, preservando blocos parciais de uploads pausados ou cancelados pelo usuário por até uma semana caso ele decida retomar o envio.

#### Scenario: Preservação de blocos de upload parcial com 10 dias e remoção após 14 dias
- **WHEN** a rotina agendada de limpeza é executada no Worker
- **THEN** o sistema preserva blocos em `staging/` enviados há 5 dias (permitindo retomada caso o usuário mude de ideia após cancelar) e remove do R2 blocos órfãos enviados há mais de 7 dias
