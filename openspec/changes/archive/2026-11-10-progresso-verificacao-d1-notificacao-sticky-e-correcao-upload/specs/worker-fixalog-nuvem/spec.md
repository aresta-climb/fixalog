# Spec Delta

## ADDED Requirements

### Requirement: Limpeza Automática de Blocos Temporários Expirados Após 14 Dias
O Worker DEVE (MUST) executar uma rotina agendada (*Cron Trigger* via `scheduled`) que inspeciona periodicamente os objetos temporários em `staging/` no bucket R2 `fixalog-laudos` e remove exclusivamente os blocos cujo `uploaded` tenha mais de **14 dias**, preservando blocos parciais de uploads iniciados em expedições de montanha que durem mais de uma semana.

#### Scenario: Preservação de blocos de upload parcial com 10 dias e remoção após 14 dias
- **WHEN** a rotina agendada de limpeza é executada no Worker
- **THEN** o sistema preserva blocos em `staging/` enviados há 10 dias (permitindo retomada após expedições de mais de 7 dias) e remove do R2 blocos órfãos enviados há mais de 14 dias

## MODIFIED Requirements

### Requirement: Verificação de Identidade, App Check, Atestado OIDC e Assinatura XML-DSig no Upload
Ao receber o upload de um laudo ou o registro de uma chave pública, o Worker DEVE (MUST) validar na borda: (1) o token do **Firebase App Check**, (2) o JWT de sessão do **Supabase Auth** (`user_id`), (3) a assinatura e o `nonce = sha256(sha256(chave_publica_pem))` contidos no `atestado_oidc_jwt` emitido pela Google ou Apple (utilizando `<PublicKeyPem>` ou extraindo o *SubjectPublicKeyInfo* diretamente do `<X509Certificate>` quando `<PublicKeyPem>` não estiver explícito no `META-INF/signatures.xml`), e (4) a integridade da assinatura criptográfica `META-INF/signatures.xml` do `.epub` contra a chave pública declarada. O Worker DEVE (MUST) permitir que o mesmo `user_id` envie uma nova versão (`v<N+1>`) de um laudo existente mesmo utilizando um novo par de chaves devidamente vinculado à mesma conta, rejeitando com `403 Forbidden` tentativas de qualquer outro `user_id`.

#### Scenario: Upload de nova versão pelo próprio autor com chave pública autenticada
- **WHEN** o usuário proprietário do laudo (`user_id` idêntico ao autor de `v1`) envia uma atualização assinada por uma chave pública válida vinculada à sua conta (mesma chave ou nova chave com `atestado_oidc_jwt` válido da mesma conta, com `<PublicKeyPem>` explícito ou chave pública extraída de `<X509Certificate>`)
- **THEN** o Worker valida os tokens e a assinatura XML-DSig, calcula `versao = versao_atual + 1` e grava o arquivo em `laudos/<id>/v<N>.epub` no bucket R2 `fixalog-laudos` sem sobrescrever `v1`

#### Scenario: Rejeição de upload por usuário terceiro ou token App Check inválido
- **WHEN** uma requisição tenta enviar uma versão para um `id` já pertencente a outro `user_id` ou apresenta um token Firebase App Check / assinatura XML-DSig inválidos
- **THEN** o Worker rejeita a operação com erro `401 Unauthorized` ou `403 Forbidden` sem gravar dados no R2 ou no D1

### Requirement: Gatekeeper de Moderação CSAM e NSFW em 3 Camadas com Extração de I-Frames no Servidor
Todo laudo recém-enviado DEVE (MUST) iniciar obrigatoriamente com `status_moderacao = 'em_analise'`, permanecendo inacessível ao público (exibindo tela de processamento em `GET /v/:id` e bloqueando `GET /v/:id/midias/*`) até a conclusão da auditoria de segurança em segundo plano (`ctx.waitUntil`). O pipeline de moderação no Worker DEVE (MUST):
1. Extrair diretamente do `.epub` no servidor todas as imagens (`.webp`, `.jpg`, `.png`) e **todos os I-Frames (keyframes) de cada vídeo `.mp4`** (1 a cada 10s mais o primeiro e o último quadro, decodificados no próprio Worker a partir da tabela `moov/stss` do MP4 sem confiar em miniaturas enviadas pelo cliente), registrando inicialmente `verificacao_total` e `verificacao_concluida = 0` na tabela `versoes_laudo_fixalog` do D1;
2. Submeter todas as fotos e *I-Frames* extraídos a sub-requisições na zona `fixalog.app` para inspeção automática pelo **Cloudflare CSAM Scanning Tool** (hashes PhotoDNA NCMEC/Interpol);
3. Classificar todas as imagens completas (`.webp`, `.jpg`, `.png`, enviando os bytes integrais sem truncamento) no **Cloudflare Workers AI** (`@cf/meta/llama-3.2-11b-vision-instruct` / `@cf/llava-hf/llava-1.5-7b-hf` com categorias de segurança `S4: Child Sexual Exploitation` e `S12: Sexual Content`), envolvendo a chamada ao modelo em tratamento de exceções (`try/catch` com reporte ao Sentry) para que indisponibilidades ou erros de decodificação na IA não interrompam o término da verificação;
4. Atualizar incrementalmente `verificacao_concluida` no D1 a cada mídia inspecionada.
Se todas as mídias forem aprovadas, o Worker DEVE (MUST) atualizar `status_moderacao = 'ativo'` e `verificacao_concluida = verificacao_total`. Se qualquer foto ou *I-Frame* for sinalizado por CSAM ou NSFW, o Worker DEVE (MUST) definir `status_moderacao = 'bloqueado'`, isolar/remover o arquivo do acesso no R2 e disparar alerta imediato para `alertas.arestaclimb.com`.

#### Scenario: Bloqueio preventivo enquanto o relatório está em análise
- **WHEN** alguém acessa `https://fixalog.app/v/<id>` ou qualquer rota de mídia `/v/<id>/midias/*` enquanto `status_moderacao` é `'em_analise'`
- **THEN** o Worker não entrega nenhuma imagem, vídeo ou arquivo `.epub` e retorna uma página informando que o relatório está passando pela verificação automática de integridade e segurança

#### Scenario: Aprovação automática de laudo contendo apenas fotos e vídeos legítimos de escalada
- **WHEN** o pipeline assíncrono no Worker analisa todas as fotos (com seus bytes completos) e todos os *I-Frames* extraídos dos vídeos de um laudo de escalada e nenhum sinal CSAM ou NSFW é detectado
- **THEN** o Worker incrementa `verificacao_concluida` no D1 a cada amostra e, ao finalizar, atualiza `status_moderacao` para `'ativo'` no D1 e libera imediatamente a visualização pública em `https://fixalog.app/v/<id>`

#### Scenario: Bloqueio imediato e alerta quando um I-Frame de vídeo ou foto contém conteúdo impróprio
- **WHEN** qualquer foto ou *I-Frame* extraído de um vídeo `.mp4` é classificado como impróprio (`S4` ou `S12` no Workers AI ou match no CSAM Scanning Tool)
- **THEN** o Worker atualiza `status_moderacao = 'bloqueado'`, bloqueia permanentemente o acesso público ao pacote no R2 e envia notificação imediata de incidente para `alertas.arestaclimb.com`

#### Scenario: Resiliência quando o modelo Workers AI lança erro técnico inesperado
- **WHEN** a chamada `env.AI.run` lança uma exceção técnica inesperada durante a análise de uma imagem
- **THEN** o Worker captura a exceção, reporta o erro técnico ao Sentry e conclui a transição de estado no D1 sem deixar a versão travada perpetuamente em `'em_analise'`

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
