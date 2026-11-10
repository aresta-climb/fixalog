# Worker Fixalog na Nuvem

## Purpose

Define o contrato OpenAPI (`fixalog.yaml`), a modelagem de dados no Cloudflare D1 compartilhado (`aresta-catalogo`) e o Cloudflare Worker `fixalog` (`https://fixalog.app`) responsável pela recepção autenticada de laudos, armazenamento sem duplicação no R2 com leitura parcial por *Byte-Range*, renderização web com barra de verificação criptográfica e histórico de versões, e *gatekeeper* de moderação CSAM/NSFW em 3 camadas.

## Requirements

### Requirement: Contrato OpenAPI e Tabelas no Banco D1 Compartilhado (`aresta-catalogo`)
A API de borda do Fixalog DEVE (MUST) ser formalmente especificada em `aresta_api/openapi/fixalog.yaml` e utilizar o banco Cloudflare D1 compartilhado `aresta-catalogo` com as tabelas `chaves_usuario_fixalog`, `laudos_fixalog` (incluindo coluna anulável `escalada_uid` para relacionamento com vias do catálogo Aresta) e `versoes_laudo_fixalog`.

#### Scenario: Persistência estruturada de laudo e versão no D1 compartilhado
- **WHEN** um pacote `.epub` válido é recebido pela API em `PUT /api/v1/laudos/:id`
- **THEN** o Worker registra ou atualiza o metadado mestre em `laudos_fixalog` (incluindo `user_id`, `categoria`, `titulo`, `escalada_uid` se presente no Protobuf e `versao_atual`) e insere o registro imutável da nova versão `v<N>` em `versoes_laudo_fixalog` contendo o `r2_key`, `hash_epub_sha256`, `fingerprint_chave`, `atestado_oidc_jwt`, `indices_zip_json` e `status_moderacao = 'em_analise'`

### Requirement: Verificação de Identidade, App Check, Atestado OIDC e Assinatura XML-DSig no Upload
Ao receber o upload de um laudo ou o registro de uma chave pública, o Worker DEVE (MUST) validar na borda: (1) o token do **Firebase App Check**, (2) o JWT de sessão do **Supabase Auth** (`user_id`), (3) a assinatura e o `nonce = sha256(sha256(chave_publica_pem))` contidos no `atestado_oidc_jwt` emitido pela Google ou Apple (utilizando `<PublicKeyPem>` ou extraindo o *SubjectPublicKeyInfo* diretamente do `<X509Certificate>` quando `<PublicKeyPem>` não estiver explícito no `META-INF/signatures.xml`), e (4) a integridade da assinatura criptográfica `META-INF/signatures.xml` do `.epub` contra a chave pública declarada. O Worker DEVE (MUST) permitir que o mesmo `user_id` envie uma nova versão (`v<N+1>`) de um laudo existente mesmo utilizando um novo par de chaves devidamente vinculado à mesma conta, rejeitando com `403 Forbidden` tentativas de qualquer outro `user_id`.

#### Scenario: Upload de nova versão pelo próprio autor com chave pública autenticada
- **WHEN** o usuário proprietário do laudo (`user_id` idêntico ao autor de `v1`) envia uma atualização assinada por uma chave pública válida vinculada à sua conta (mesma chave ou nova chave com `atestado_oidc_jwt` válido da mesma conta, com `<PublicKeyPem>` explícito ou chave pública extraída de `<X509Certificate>`)
- **THEN** o Worker valida os tokens e a assinatura XML-DSig, calcula `versao = versao_atual + 1` e grava o arquivo em `laudos/<id>/v<N>.epub` no bucket R2 `fixalog-laudos` sem sobrescrever `v1`

#### Scenario: Rejeição de upload por usuário terceiro ou token App Check inválido
- **WHEN** uma requisição tenta enviar uma versão para um `id` já pertencente a outro `user_id` ou apresenta um token Firebase App Check / assinatura XML-DSig inválidos
- **THEN** o Worker rejeita a operação com erro `401 Unauthorized` ou `403 Forbidden` sem gravar dados no R2 ou no D1

### Requirement: Armazenamento Único no R2 e Leitura Parcial por Byte-Range de Mídias Internas do EPUB
O Worker DEVE (MUST) armazenar no bucket R2 `fixalog-laudos` exclusivamente o arquivo `.epub` completo de cada versão (`laudos/<id>/v<N>.epub`), sem extrair nem duplicar fotos ou vídeos como objetos separados no R2. No momento do upload, o Worker DEVE (MUST) ler o Diretório Central ZIP do `.epub`, mapear o deslocamento (*offset* em bytes) e tamanho de cada arquivo interno armazenado em modo `STORE` e persistir esse mapa em `indices_zip_json`. Nas requisições `GET /v/:id/midias/*`, o Worker DEVE (MUST) servir as fotos (`.webp`, `.jpg`, `.png`), documentos (`.pdf`) e *streaming* de vídeos (`.mp4` com suporte a cabeçalho HTTP `Range` / `206 Partial Content`) realizando leituras parciais de intervalo de bytes (`range: { offset, length }`) diretamente sobre o arquivo `.epub` no R2, aplicando cabeçalho `Cache-Control: public, max-age=31536000, immutable`.

#### Scenario: Streaming de vídeo MP4 com suporte a HTTP Range direto de dentro do EPUB no R2
- **WHEN** o navegador solicita `GET /v/<id>/midias/<uuid>.mp4` com o cabeçalho `Range: bytes=0-65535` para um laudo com `status_moderacao = 'ativo'`
- **THEN** o Worker consulta o `offset` e `length` de `OEBPS/midias/<uuid>.mp4` no `indices_zip_json`, executa uma leitura parcial no R2 de `offset + 0` com tamanho `65536` sobre `laudos/<id>/v<N>.epub` e retorna `206 Partial Content` com os bytes exatos do vídeo e cabeçalhos de cache imutável na CDN

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

### Requirement: Canal de Denúncia Pública de Relatório (`POST /api/v1/laudos/:id/denunciar`)
A página web `https://fixalog.app/v/:id` DEVE (MUST) disponibilizar um botão **"Denunciar relatório"** que envia o motivo da denúncia para `POST /api/v1/laudos/:id/denunciar`. Se a denúncia indicar conteúdo grave/ilegal ou atingir o limiar de segurança, o Worker DEVE (MUST) suspender preventivamente a exibição pública (`status_moderacao = 'em_analise'` ou `'suspenso'`) e disparar alerta prioritário para `alertas.arestaclimb.com`.

#### Scenario: Leitor denuncia um relatório pela página web
- **WHEN** um visitante aciona o botão "Denunciar relatório" em `https://fixalog.app/v/:id>` e confirma o motivo da denúncia
- **THEN** o Worker registra a denúncia, envia um alerta imediato com o link e metadados do laudo para `alertas.arestaclimb.com` e oculta preventivamente o relatório em caso de denúncia de violação grave de segurança

### Requirement: Upload Retomável em Blocos e Mapeamento Idempotente por SHA-256
O Worker DEVE (MUST) disponibilizar o endpoint autenticado `GET /api/v1/laudos/:id/status?sha256=<hash>` (exigindo `X-Firebase-AppCheck`, JWT do Supabase e verificando que o `user_id` autenticado é o proprietário do laudo quando o laudo já existir no D1) e o endpoint de recepção de blocos `PUT /api/v1/laudos/:id/chunk?sha256=<hash>&index=<i>&total=<N>`. O servidor DEVE (MUST) mapear cada versão pelo par `{id_sessao, hash_epub_sha256}`:
- Se o `sha256` informado já existir em `versoes_laudo_fixalog` para aquele `id_sessao`, o endpoint de status DEVE retornar `{ ja_enviado: true, versao, status_moderacao, motivo_moderacao, verificacao_concluida, verificacao_total }`, e qualquer tentativa de novo upload com o mesmo `sha256` DEVE ser respondida sem duplicar a versão;
- Se o `sha256` ainda não estiver finalizado, o endpoint de status DEVE retornar a lista `chunks_recebidos` já armazenados temporariamente no R2 (`staging/<id_sessao>/<sha256>/chunk_<i>`), permitindo que o cliente envie apenas os blocos faltantes;
- Ao receber o último bloco de um `sha256` inédito, o Worker DEVE concatenar os blocos, validar que o hash SHA-256 e a assinatura `META-INF/signatures.xml` conferem, criar a nova versão sequencial `v<N>`, remover os blocos temporários e iniciar a moderação assíncrona; caso a validação do pacote concatenado falhe (`400 Bad Request`), o Worker DEVE remover imediatamente do R2 os blocos `staging/<id_sessao>/<sha256>/chunk_*` daquele hash inválido.

#### Scenario: Retomada de upload após queda de conexão no meio dos blocos
- **WHEN** um cliente envia os blocos `0` e `1` de um laudo de 4 blocos para `PUT /api/v1/laudos/:id/chunk` e a conexão cai antes do bloco `2`
- **THEN** ao consultar `GET /api/v1/laudos/:id/status?sha256=<hash>`, o Worker retorna `ja_enviado: false` e `chunks_recebidos: [0, 1]`, permitindo que o cliente envie apenas os blocos `2` e `3` para concluir a versão

#### Scenario: Rejeição de re-upload quando o mesmo SHA-256 já foi enviado
- **WHEN** o cliente tenta enviar um pacote ou consultar status para um `{id_sessao, sha256}` que já consta em `versoes_laudo_fixalog`
- **THEN** o Worker não cria uma nova versão duplicada e informa que o `sha256` já foi processado, retornando o número da versão correspondente, seu `status_moderacao` atual e o progresso `verificacao_concluida` / `verificacao_total`

#### Scenario: Limpeza imediata dos blocos em staging quando a validação do pacote concatenado falha
- **WHEN** o último bloco de um upload é recebido, mas o pacote concatenado falha na verificação de hash SHA-256 ou assinatura XML-DSig
- **THEN** o Worker deleta imediatamente todos os blocos `staging/<id_sessao>/<sha256>/chunk_*` no R2 e retorna `400 Bad Request` com o motivo detalhado do erro

#### Scenario: Bloqueio de consulta de status por usuário não proprietário
- **WHEN** um usuário autenticado tenta consultar `GET /api/v1/laudos/:id/status` de um laudo pertencente a outro `user_id`
- **THEN** o Worker rejeita a consulta com `403 Forbidden`

### Requirement: Meta Tags OpenGraph e Resumo Descritivo para Preview no WhatsApp
Ao renderizar `GET https://fixalog.app/v/:id`, o Worker DEVE (MUST) incluir no `<head>` as meta tags OpenGraph (`og:title`, `og:description`, `og:url`, `og:type`, `og:site_name`, `og:image` e `twitter:card`) contendo um resumo estruturado do laudo (tipo de protocolo, nome da via/setor/material, nome do mantenedor/clube e resumo de itens/mídias) e apontando `og:image` para a primeira foto disponível no pacote `.epub` quando `status_moderacao == 'ativo'`.

#### Scenario: Geração de preview rico ao compartilhar link no WhatsApp
- **WHEN** o crawler do WhatsApp ou navegador requisita `GET https://fixalog.app/v/<id>` de um laudo ativo
- **THEN** o HTML retornado inclui `og:title` com o protocolo e título específico do laudo, `og:description` com o autor, clube e resumo do conteúdo inspecionado, e `og:image` apontando para a primeira imagem do relatório

### Requirement: Limpeza Automática de Blocos Temporários Expirados Após 14 Dias
O Worker DEVE (MUST) executar uma rotina agendada (*Cron Trigger* via `scheduled`) que inspeciona periodicamente os objetos temporários em `staging/` no bucket R2 `fixalog-laudos` e remove exclusivamente os blocos cujo `uploaded` tenha mais de **7 dias**, preservando blocos parciais de uploads pausados ou cancelados pelo usuário por até uma semana caso ele decida retomar o envio.

#### Scenario: Preservação de blocos de upload parcial com 10 dias e remoção após 14 dias
- **WHEN** a rotina agendada de limpeza é executada no Worker
- **THEN** o sistema preserva blocos em `staging/` enviados há 5 dias (permitindo retomada caso o usuário mude de ideia após cancelar) e remove do R2 blocos órfãos enviados há mais de 7 dias

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
