# Design

## Context

Conforme detalhado em `proposal.md`, o teste de campo do upload retomável revelou três gargalos encadeados:
1. A assinatura XML-DSig gerada por `XmlDsigSigner` embutia `<X509Certificate>` mas omitia `<PublicKeyPem>`, levando o Worker a calcular o hash do certificado X.509 em vez do `publicKeyPem` ao validar o `nonce` OIDC (`HTTP 400`).
2. `ClienteHttpFixalogNuvemPadrao.enviarChunkEpub` não lançava exceção em `statusCode >= 400` e o Worker mantinha os 12 blocos em `staging/` mesmo quando a validação final falhava, causando loop de 30 tentativas na UI.
3. `executarModeracaoAssincronaLaudo` passava apenas os primeiros `512 bytes` truncados (`subarray(0, 512)`) para `env.AI.run` sem `try/catch`, falhando na decodificação de imagem no Workers AI e deixando `status_moderacao = 'em_analise'` indefinidamente.

Além disso, a UX de publicação precisava de:
- Botão para fechar o modal (`Continuar em 2º plano` / `✕`);
- Barra de progresso contínua na Etapa 2 alimentada pelo progresso real da verificação no banco Cloudflare D1;
- Notificação nativa *sticky* (`flutter_local_notifications`, análoga ao `../aresta_app`) que acompanha o envio em segundo plano e, ao concluir, permite tocar na notificação para reabrir a `VisualizadorRelatorioScreen` do relatório pronto para compartilhar.

## Goals / Non-Goals

**Goals:**
- Garantir compatibilidade 100% na validação do `nonce` OpenPubkey tanto com `<PublicKeyPem>` explícito quanto extraindo a chave pública SPKI de `<X509Certificate>` (para laudos já assinados).
- Persistir `verificacao_concluida` e `verificacao_total` na tabela `versoes_laudo_fixalog` no Cloudflare D1 e expô-los no endpoint autenticado `GET /api/v1/laudos/:id/status` (restrito ao `user_id` proprietário).
- Enviar os bytes integrais das imagens (`.webp`, `.jpg`, `.png`) ao Cloudflare Workers AI Vision com tratamento de erro (`try/catch` + Sentry) para nunca travar `status_moderacao` em `'em_analise'`.
- Limpar imediatamente do R2 os blocos `staging/` quando a montagem final falhar na validação (`400 Bad Request`) e manter rotina agendada (`scheduled` Cron Trigger) que remove apenas blocos órfãos com mais de **14 dias** (suportando retomada após expedições de mais de 7 dias).
- Exibir barra de progresso contínua nas Etapas 1 e 2 do modal, botão `Continuar em 2º plano` / `✕`, mensagens claras de erro HTTP e notificação *sticky* com navegação para a `VisualizadorRelatorioScreen` ao tocar na notificação de conclusão.

**Non-Goals:**
- Não expor endpoint público sem autenticação para consulta de progresso de moderação (evitando *scraping* e consumo indevido de cota de D1/Workers).
- Não alterar o formato criptográfico ECDSA secp256r1 dos pacotes `.epub`.

## Decisions

### 1. Persistência de Progresso de Verificação no Cloudflare D1 (`versoes_laudo_fixalog`) e Auto-Migração Segura
- **Decisão**:
  - Adicionar as colunas `verificacao_concluida INTEGER NOT NULL DEFAULT 0` e `verificacao_total INTEGER NOT NULL DEFAULT 1` na definição SQL de `versoes_laudo_fixalog` (`aresta_api/sql/fixalog_d1.sql` e `fixalog_d1_sql.ts`).
  - Como o banco D1 de produção já possui a tabela `versoes_laudo_fixalog` criada, o Worker executará de forma idempotente (uma vez por instância de isolate, com `try/catch` ignorando `duplicate column name`) os comandos `ALTER TABLE versoes_laudo_fixalog ADD COLUMN verificacao_concluida INTEGER NOT NULL DEFAULT 0` e `ALTER TABLE versoes_laudo_fixalog ADD COLUMN verificacao_total INTEGER NOT NULL DEFAULT 1`.
  - Durante `executarModeracaoAssincronaLaudo`, o Worker inicializa `verificacao_total = Math.max(1, amostras.length)` e `verificacao_concluida = 0`, atualizando `verificacao_concluida` a cada mídia avaliada e definindo `verificacao_concluida = verificacao_total` ao concluir (`status_moderacao = 'ativo'`).
  - No endpoint `GET /api/v1/laudos/:id/status`, o Worker verifica se o laudo pertence ao `usuario.userId` autenticado (`403 Forbidden` caso pertença a outro usuário) e retorna `verificacao_concluida`, `verificacao_total` e `motivo_moderacao`.
- **Alternativas consideradas**:
  - *Salvar progresso em arquivo JSON no R2*: Descartado a pedido do usuário por ser semanticamente inadequado para estado relacional de versão e mais caro em operações de escrita/leitura do que o D1.

### 2. Extração de Chave Pública de `<X509Certificate>` + Inclusão de `<PublicKeyPem>`
- **Decisão**:
  - No app (`XmlDsigSigner.gerarAssinaturaXml` e `GenerationNotifier`), incluir opcionalmente `publicKeyPem` para gravar `<PublicKeyPem>` dentro de `<KeyInfo>` em novos laudos.
  - No Worker (`verificador_assinatura_laudo.ts`), implementar `extrairPublicKeyPemDeCertificadoX509(certBase64)` que localiza a sequência ASN.1 OID de chave pública EC (`1.2.840.10045.2.1` + curva `prime256v1` `1.2.840.10045.3.1.7`, cabeçalho SPKI de 26 bytes seguido do `BIT STRING` de 66 bytes da chave pública P-256) dentro do DER do certificado X.509 e reconstrói exatamente o `-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----` gerado pelo `CryptoUtils.encodeEcPublicKeyToPem`. Assim, tanto laudos novos quanto o laudo `v2` que já foi assinado no celular do usuário passam na verificação do `nonce` OIDC!

### 3. Limpeza Imediata em Falha de Montagem e Cron de 14 Dias para `staging/`
- **Decisão**:
  - Em `PUT /api/v1/laudos/:id/chunk`, quando todos os blocos `0..total-1` estão presentes, se o hash `SHA-256` não bater ou `persistirVersaoEpubValidada` retornar erro `400`, o Worker chama `await env.LAUDOS_BUCKET.delete(chavesStaging)` antes de responder `400`.
  - Além disso, em `GET /api/v1/laudos/:id/status`, se `versaoEncontrada == null` mas existirem blocos órfãos de uma tentativa anterior com erro, ou via *Cron Trigger* diário (`0 4 * * *` em `wrangler.toml`, função `limparStagingExpiradoNoR2` chamada no handler `scheduled`), o Worker remove objetos em `staging/` com `uploaded` anterior a **14 dias** (`14 * 24 * 60 * 60 * 1000 ms`).

### 4. Notificação *Sticky* (`GerenciadorNotificacaoUploadLaudo`) e Reabertura da `VisualizadorRelatorioScreen`
- **Decisão**:
  - Adicionar `flutter_local_notifications` ao `app/pubspec.yaml` e criar `GerenciadorNotificacaoUploadLaudo` em `app/lib/core/services/gerenciador_notificacao_upload_laudo.dart` com `PluginNotificacoesLocaisFake` em `app/test/fakes/plugin_notificacoes_locais_fake.dart`.
  - Integrar o gerenciador ao `SincronizadorNuvemService`:
    - Durante `EtapaPublicacaoLaudo.enviandoBlocos` (0% a 50% do progresso global) e `EtapaPublicacaoLaudo.aguardandoVerificacaoServidor` (50% a 99% proporcional a `verificacaoConcluida / verificacaoTotal`), atualiza a notificação *sticky* (`ongoing: true`).
    - Ao atingir `EtapaPublicacaoLaudo.concluidoAtivo`, cancela a notificação *sticky* e exibe a notificação de conclusão (`ongoing: false`, `autoCancel: true`, `payload: idSessao`).
    - Quando o usuário toca na notificação de conclusão, o callback `aoSelecionarNotificacao(idSessao)` consulta a submissão no `BancoDadosLocal` e navega (via `navigatorKey` global do `FixalogApp`) para a `VisualizadorRelatorioScreen` daquele laudo.

## Risks / Trade-offs

- **[Risk] Limite de tamanho de payload no Workers AI para imagens muito grandes** → **Mitigation**: As imagens dentro do `.epub` já são comprimidas pelo `MediaCompressorService` em WebP otimizado; ainda assim, o bloco `try/catch` em torno de `env.AI.run` garante que qualquer erro do modelo seja reportado ao Sentry sem travar a liberação do laudo.
- **[Risk] Permissão de notificação negada pelo usuário no Android 13+ / iOS** → **Mitigation**: Todas as chamadas ao `GerenciadorNotificacaoUploadLaudo` capturam falhas silenciosamente, garantindo que o upload e o modal na tela funcionem normalmente mesmo sem permissão de notificação no sistema operacional.
