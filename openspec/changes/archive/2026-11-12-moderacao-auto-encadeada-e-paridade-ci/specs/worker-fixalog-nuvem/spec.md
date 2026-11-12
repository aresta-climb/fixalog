# Spec Delta

## MODIFIED Requirements

### Requirement: Gatekeeper de Moderação CSAM e NSFW em 3 Camadas com Extração de I-Frames no Servidor
Todo laudo recém-enviado DEVE (MUST) iniciar obrigatoriamente com `status_moderacao = 'em_analise'`, permanecendo inacessível ao público (exibindo tela de processamento em `GET /v/:id` e bloqueando `GET /v/:id/midias/*`) até a conclusão da auditoria de segurança em segundo plano. Para evitar o esgotamento do orçamento de CPU/tempo de uma única invocação em relatórios com muitas imagens e não consumir cota ociosa com *Cron Triggers* por minuto, o pipeline de moderação no Worker DEVE (MUST) executar em **lotes curtos auto-encadeados** via *Service Binding* (`env.SELF`) sobre uma rota interna autenticada por HMAC-SHA256 (`POST /__internal/moderar/:idSessao/v:versao`) e operar estritamente em modo **fail-closed** (nunca aprovando o laudo se qualquer etapa de verificação falhar):
1. Extrair diretamente do `.epub` no servidor todas as imagens (`.webp`, `.jpg`, `.jpeg`, `.png`), incluindo obrigatoriamente o *poster* (`<uuid>_poster.jpg`) e as miniaturas de *keyframes* a cada 10s (`<uuid>_kf_<N>s.jpg`) de cada vídeo `.mp4` (rejeitando o laudo caso exista um `.mp4` sem seu `_poster.jpg` correspondente), registrando inicialmente `verificacao_total` e `verificacao_concluida = 0` na tabela `versoes_laudo_fixalog` do D1;
2. Processar no máximo `3` imagens por invocação interna (`TAMANHO_MAXIMO_LOTE_POR_INVOCACAO = 3`) a partir do índice `verificacao_concluida` atual, submetendo cada imagem do lote a uma requisição `GET https://fixalog.app/__csam_scan/:id/:versao/:caminho?token=<hmac>` na zona `fixalog.app` (que serve os bytes reais da imagem com `Content-Type: image/*` para inspeção na borda pelo **Cloudflare CSAM Scanning Tool** PhotoDNA NCMEC/Interpol);
3. Classificar cada imagem do lote no **Cloudflare Workers AI** (`@cf/meta/llama-3.2-11b-vision-instruct` com categorias de segurança `S4: Child Sexual Exploitation` e `S12: Sexual Content`) exigindo saída estruturada em JSON (`{"reasoning": "...", "verdict": "SAFE" | "UNSAFE_S4" | "UNSAFE_S12"}`) para isolar o veredito final do raciocínio intermediário. Caso o Workers AI retorne o erro `5016` exigindo aceite de licença (`submit the prompt 'agree'`), o Worker DEVE enviar automaticamente `{ prompt: "agree" }` ao modelo e repetir a classificação da imagem na mesma execução;
4. Atualizar incrementalmente `verificacao_concluida` no D1 ao final do lote e, caso `verificacao_concluida < verificacao_total`, disparar automaticamente via `ctx.waitUntil` uma nova invocação `POST /__internal/moderar/:idSessao/v:versao?etapa=<verificacao_concluida>&token=<hmac>` no *Service Binding* `env.SELF` (com orçamento renovado de CPU e tempo).
Se todas as imagens forem aprovadas sem erros técnicos (`verificacao_concluida == verificacao_total`), o Worker DEVE (MUST) atualizar `status_moderacao = 'ativo'`. Se qualquer imagem for sinalizada por CSAM ou NSFW, o Worker DEVE (MUST) definir `status_moderacao = 'bloqueado'` e disparar alerta imediato para `alertas.arestaclimb.com` e Sentry contendo o campo `reasoning` retornado pelo modelo. Se ocorrer falha técnica transitória em um lote e o número de tentativas for menor que `3`, o Worker DEVE re-encadear a invocação incrementando `tentativa`; se a falha persistir após as retentativas ou não houver binding `env.AI`, o Worker DEVE (MUST) abortar a aprovação (**fail-closed**), definir `status_moderacao = 'bloqueado'` com `motivo_moderacao = 'ERRO_TECNICO_VERIFICACAO: ...'` e disparar um evento de **emergência (`level: 'fatal'`)** no Sentry e em `alertas.arestaclimb.com`.

#### Scenario: Bloqueio preventivo enquanto o relatório está em análise
- **WHEN** alguém acessa `https://fixalog.app/v/<id>` ou qualquer rota de mídia `/v/<id>/midias/*` enquanto `status_moderacao` é `'em_analise'`
- **THEN** o Worker não entrega nenhuma imagem, vídeo ou arquivo `.epub` e retorna uma página informando que o relatório está passando pela verificação automática de integridade e segurança

#### Scenario: Aprovação automática de laudo contendo apenas fotos e vídeos legítimos de escalada
- **WHEN** o pipeline assíncrono no Worker analisa todas as fotos, posters e keyframes de vídeo (`_kf_*s.jpg`) em lotes auto-encadeados via `env.SELF` e Workers AI (incluindo auto-envio de `{ prompt: "agree" }` se solicitado pelo erro `5016`) e nenhum sinal CSAM/NSFW ou erro técnico ocorre
- **THEN** o Worker incrementa `verificacao_concluida` no D1 a cada lote e, ao finalizar `verificacao_total`, atualiza `status_moderacao` para `'ativo'` no D1 e libera a visualização pública em `https://fixalog.app/v/<id>`

#### Scenario: Bloqueio imediato e alerta quando um I-Frame de vídeo ou foto contém conteúdo impróprio
- **WHEN** qualquer foto, poster ou keyframe de vídeo retorna `"verdict": "UNSAFE_S12"` ou `"UNSAFE_S4"` no JSON do Workers AI (ou `451`/`403` no CSAM Scanning Tool)
- **THEN** o Worker atualiza `status_moderacao = 'bloqueado'`, interrompe o auto-encadeamento e envia notificação imediata de incidente para `alertas.arestaclimb.com` e Sentry incluindo o `reasoning` explicativo do modelo nos metadados do evento

#### Scenario: Resiliência quando o modelo Workers AI lança erro técnico inesperado
- **WHEN** a chamada `env.AI.run` falha com erro técnico persistente mesmo após as retentativas automáticas do lote
- **THEN** o Worker opera em modo *fail-closed* (NÃO aprova o laudo), grava `status_moderacao = 'bloqueado'` com `motivo_moderacao` indicando a falha de verificação e envia um alerta de emergência com `level: "fatal"` para o Sentry e `alertas.arestaclimb.com`

#### Scenario: Moderação autônoma auto-encadeada em múltiplos lotes sem polling do cliente
- **WHEN** um laudo com 15 imagens termina o upload dos blocos em `PUT /api/v1/laudos/:id/chunk` e o aplicativo cliente é fechado imediatamente
- **THEN** o Worker dispara a rota interna `POST /__internal/moderar/:id/v1` via `env.SELF`, analisa 3 imagens por invocação atualizando `verificacao_concluida` (`3`, `6`, `9`, `12`, `15`), auto-encadeia cada lote subsequente com orçamento renovado de CPU/tempo e, ao concluir `15/15`, atualiza `status_moderacao = 'ativo'` sem depender de *Cron Trigger* de 1 minuto nem de *polling* do aplicativo

#### Scenario: Rejeição de chamada externa não autorizada na rota interna de moderação
- **WHEN** um cliente externo envia `POST /__internal/moderar/<id>/v1` sem um token HMAC-SHA256 válido
- **THEN** o Worker rejeita a requisição com `403 Forbidden` sem executar processamento

#### Scenario: Aprovação sem falso positivo quando o raciocínio cita categorias mas o veredito estruturado é SAFE
- **WHEN** o modelo `@cf/meta/llama-3.2-11b-vision-instruct` analisa a foto de uma mão segurando uma ferramenta de escalada e retorna `{"reasoning": "A hand holding a red saw blade. No S4 or S12 content is present.", "verdict": "SAFE"}`
- **THEN** o avaliador JSON lê exclusivamente o campo `verdict === "SAFE"` e aprova a imagem sem falso positivo
