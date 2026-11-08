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
Ao receber o upload de um laudo ou o registro de uma chave pública, o Worker DEVE (MUST) validar na borda: (1) o token do **Firebase App Check**, (2) o JWT de sessão do **Supabase Auth** (`user_id`), (3) a assinatura e o `nonce = sha256(sha256(chave_publica_pem))` contidos no `atestado_oidc_jwt` emitido pela Google ou Apple, e (4) a integridade da assinatura criptográfica `META-INF/signatures.xml` do `.epub` contra a chave pública declarada. O Worker DEVE (MUST) permitir que o mesmo `user_id` envie uma nova versão (`v<N+1>`) de um laudo existente mesmo utilizando um novo par de chaves devidamente vinculado à mesma conta, rejeitando com `403 Forbidden` tentativas de qualquer outro `user_id`.

#### Scenario: Upload de nova versão pelo próprio autor com chave pública autenticada
- **WHEN** o usuário proprietário do laudo (`user_id` idêntico ao autor de `v1`) envia uma atualização assinada por uma chave pública válida vinculada à sua conta (mesma chave ou nova chave com `atestado_oidc_jwt` válido da mesma conta)
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
Ao acessar `GET https://fixalog.app/v/:id` (ou `?v=<N>`), para um laudo com `status_moderacao = 'ativo'`, o Worker DEVE (MUST) renderizar o relatório XHTML acompanhado de uma barra superior fixa de verificação pericial contendo:
- Selo de verificação criptográfica da assinatura ECDSA (`META-INF/signatures.xml`) e validação do vínculo OIDC Google/Apple + App Check;
- Nome do mantenedor, Clube/Associação e data/hora da assinatura;
- *Fingerprint* abreviado da chave pública (`SHA-256`) e **contador dinâmico em tempo real** (consultado no D1) do total de laudos ativos assinados por aquela chave pública;
- Seletor de histórico de versões (`v1`, `v2`, ...) permitindo inspecionar qualquer versão anterior e ver se houve mudança de chave entre versões;
- Botões para baixar o pacote `.epub` original assinado, gerar/baixar o sumário `.pdf` para impressão e acionar o botão **"Denunciar relatório"**.

#### Scenario: Abertura de relatório via QR Code de vídeo rola até o vídeo e exibe dados criptográficos
- **WHEN** um usuário escaneia um QR Code apontando para `https://fixalog.app/v/<id>#video-<uuid>` de um laudo ativo
- **THEN** a página web carrega a barra superior de verificação criptográfica (com autor, clube, *fingerprint*, contagem atualizada de laudos da chave e versão atual) e posiciona a rolagem diretamente no elemento `<div id="video-<uuid>">` pronto para reprodução

#### Scenario: Inspeção de versão anterior pelo seletor de versões
- **WHEN** um laudo possui versões `v1` e `v2` e o leitor seleciona `v1` no seletor da barra superior (`https://fixalog.app/v/<id>?v=1`)
- **THEN** o Worker renderiza o conteúdo, as mídias e os metadados de assinatura correspondentes exatamente ao arquivo `laudos/<id>/v1.epub`, exibindo um aviso de que existe uma versão mais recente (`v2`)

### Requirement: Gatekeeper de Moderação CSAM e NSFW em 3 Camadas com Extração de I-Frames no Servidor
Todo laudo recém-enviado DEVE (MUST) iniciar obrigatoriamente com `status_moderacao = 'em_analise'`, permanecendo inacessível ao público (exibindo tela de processamento em `GET /v/:id` e bloqueando `GET /v/:id/midias/*`) até a conclusão da auditoria de segurança em segundo plano (`ctx.waitUntil`). O pipeline de moderação no Worker DEVE (MUST):
1. Extrair diretamente do `.epub` no servidor todas as imagens (`.webp`, `.jpg`, `.png`) e **todos os I-Frames (keyframes) de cada vídeo `.mp4`** (1 a cada 10s mais o primeiro e o último quadro, decodificados no próprio Worker a partir da tabela `moov/stss` do MP4 sem confiar em miniaturas enviadas pelo cliente);
2. Submeter todas as fotos e *I-Frames* extraídos a sub-requisições na zona `fixalog.app` para inspeção automática pelo **Cloudflare CSAM Scanning Tool** (hashes PhotoDNA NCMEC/Interpol);
3. Classificar todas as fotos e *I-Frames* extraídos no **Cloudflare Workers AI** (`@cf/meta/llama-3.2-11b-vision-instruct` / `@cf/llava-hf/llava-1.5-7b-hf` com categorias de segurança `S4: Child Sexual Exploitation` e `S12: Sexual Content`).
Se todas as mídias forem aprovadas, o Worker DEVE (MUST) atualizar `status_moderacao = 'ativo'`. Se qualquer foto ou *I-Frame* for sinalizado por CSAM ou NSFW, o Worker DEVE (MUST) definir `status_moderacao = 'bloqueado'`, isolar/remover o arquivo do acesso no R2 e disparar alerta imediato para `alertas.arestaclimb.com`.

#### Scenario: Bloqueio preventivo enquanto o relatório está em análise
- **WHEN** alguém acessa `https://fixalog.app/v/<id>` ou qualquer rota de mídia `/v/<id>/midias/*` enquanto `status_moderacao` é `'em_analise'`
- **THEN** o Worker não entrega nenhuma imagem, vídeo ou arquivo `.epub` e retorna uma página informando que o relatório está passando pela verificação automática de integridade e segurança

#### Scenario: Aprovação automática de laudo contendo apenas fotos e vídeos legítimos de escalada
- **WHEN** o pipeline assíncrono no Worker analisa todas as fotos e todos os *I-Frames* extraídos dos vídeos de um laudo de escalada e nenhum sinal CSAM ou NSFW é detectado
- **THEN** o Worker atualiza `status_moderacao` para `'ativo'` no D1 e libera imediatamente a visualização pública em `https://fixalog.app/v/<id>`

#### Scenario: Bloqueio imediato e alerta quando um I-Frame de vídeo ou foto contém conteúdo impróprio
- **WHEN** qualquer foto ou *I-Frame* extraído de um vídeo `.mp4` é classificado como impróprio (`S4` ou `S12` no Workers AI ou match no CSAM Scanning Tool)
- **THEN** o Worker atualiza `status_moderacao = 'bloqueado'`, bloqueia permanentemente o acesso público ao pacote no R2 e envia notificação imediata de incidente para `alertas.arestaclimb.com`

### Requirement: Canal de Denúncia Pública de Relatório (`POST /api/v1/laudos/:id/denunciar`)
A página web `https://fixalog.app/v/:id` DEVE (MUST) disponibilizar um botão **"Denunciar relatório"** que envia o motivo da denúncia para `POST /api/v1/laudos/:id/denunciar`. Se a denúncia indicar conteúdo grave/ilegal ou atingir o limiar de segurança, o Worker DEVE (MUST) suspender preventivamente a exibição pública (`status_moderacao = 'em_analise'` ou `'suspenso'`) e disparar alerta prioritário para `alertas.arestaclimb.com`.

#### Scenario: Leitor denuncia um relatório pela página web
- **WHEN** um visitante aciona o botão "Denunciar relatório" em `https://fixalog.app/v/:id>` e confirma o motivo da denúncia
- **THEN** o Worker registra a denúncia, envia um alerta imediato com o link e metadados do laudo para `alertas.arestaclimb.com` e oculta preventivamente o relatório em caso de denúncia de violação grave de segurança
