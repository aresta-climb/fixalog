# Proposal

## Why

Ao testar o upload retomável de um laudo real em campo, identificamos três problemas críticos de confiabilidade e experiência do usuário:
1. **Falha na conclusão do upload e da moderação no servidor**:
   - O `META-INF/signatures.xml` gerado pelo app embutia `<X509Certificate>` mas não `<PublicKeyPem>`, fazendo o Worker calcular o hash sobre o certificado X.509 inteiro em vez da chave pública ECDSA ao validar o `nonce` OpenPubkey do token OIDC (`HTTP 400`);
   - O cliente HTTP do app não tratava códigos `HTTP >= 400` no envio de blocos (`enviarChunkEpub`), entrando em loop quando os blocos `0..N-1` já estavam no staging do R2 mas a versão não havia sido criada no D1;
   - A esteira de moderação `executarModeracaoAssincronaLaudo` no Worker passava apenas os primeiros `512 bytes` truncados (`subarray(0, 512)`) para o Cloudflare Workers AI sem `try/catch`, lançando exceção na decodificação de imagem dentro do `ctx.waitUntil` e impedindo a transição de `status_moderacao` para `'ativo'`.
2. **Falta de progresso contínuo na verificação do servidor (Etapa 2)**: Durante a verificação das mídias no servidor (`em_analise`), o usuário não recebia feedback de avanço (barra de progresso real com quantidade de mídias inspecionadas) nem mensagem de erro clara em caso de falha.
3. **Modal bloqueante sem opção de fechar e sem notificação *sticky* em segundo plano**: O modal de publicação não possuía botão para fechar/continuar em segundo plano, e o aplicativo não exibia uma notificação nativa *sticky* (`ongoing: true`) com barra de progresso que se transforma em uma notificação clicável para reabrir o relatório e compartilhar o link assim que a verificação terminar.

## What Changes

- **Correção da Validação XML-DSig/OIDC e Limpeza de Blocos `staging/` no R2**:
  - Incluir `<PublicKeyPem>` explicitamente em `META-INF/signatures.xml` no `XmlDsigSigner` e, no Worker (`verificador_assinatura_laudo.ts`), extrair também a chave pública SPKI diretamente do `<X509Certificate>` como fallback compatível com laudos já assinados.
  - No `PUT /api/v1/laudos/:id/chunk`, remover imediatamente do R2 os blocos `staging/<id>/<sha256>/chunk_*` caso a montagem final falhe na validação `SHA-256` ou `XML-DSig`, evitando que blocos inválidos fiquem presos.
  - Adicionar rotina automática de limpeza (*Garbage Collector* via Cron Trigger `scheduled` no Worker) que remove blocos parciais em `staging/` com mais de **14 dias** (preservando uploads retomáveis de expedições longas de mais de 7 dias).
- **Correção do Workers AI Vision e Progresso de Verificação Persistido no D1**:
  - Em `moderador_midia_ia.ts`, enviar os bytes completos e íntegros de cada imagem (`.webp`, `.jpg`, `.png`) para o Workers AI (sem truncar em 512 bytes), isolando falhas da IA com `try/catch` e reporte ao Sentry para nunca travar a versão eternamente em `'em_analise'`.
  - Persistir no banco Cloudflare D1 (`versoes_laudo_fixalog`) o progresso da verificação (`verificacao_concluida` e `verificacao_total`) à medida que cada mídia é inspecionada, retornando esses campos e eventual `motivo_moderacao` no endpoint autenticado `GET /api/v1/laudos/:id/status` (restrito estritamente ao `user_id` proprietário do laudo para impedir *scraping* de cota).
- **Tratamento Explícito de Erros HTTP, Modal com Botão de Fechar e Barra de Progresso na Etapa 2**:
  - Lançar exceção com a mensagem real do servidor sempre que `consultarStatusLaudo` ou `enviarChunkEpub` receberem `statusCode >= 400`.
  - Adicionar botão de fechar (`✕` / `CONTINUAR EM 2º PLANO`) no modal de publicação da `VisualizadorRelatorioScreen` e exibir uma barra de progresso contínua (`LinearProgressIndicator`) também para a Etapa 2 (`2. Verificando integridade e mídias no servidor (X/Y)`).
- **Notificação Nativa *Sticky* de Upload e Abertura do Relatório ao Concluir**:
  - Criar `GerenciadorNotificacaoUploadLaudo` (seguindo a arquitetura de `flutter_local_notifications` do `../aresta_app`) que exibe uma notificação *sticky* (`ongoing: true`) com barra de progresso combinada durante o envio de blocos e verificação no servidor, transitando para uma notificação de conclusão (`ongoing: false`, `autoCancel: true`) ao atingir `'ativo'`.
  - Ao tocar na notificação de conclusão, o aplicativo abre diretamente a `VisualizadorRelatorioScreen` do respectivo laudo para que o usuário possa clicar imediatamente em **COMPARTILHAR**.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability isolada; os requisitos expandem as capabilities existentes. -->

### Modified Capabilities
- `worker-fixalog-nuvem`: Persistência de `verificacao_concluida` e `verificacao_total` no D1, restrição de `GET /api/v1/laudos/:id/status` ao autor do laudo, envio de bytes completos de imagem ao Workers AI com `try/catch`, extração de chave pública do `<X509Certificate>`, limpeza imediata de `staging/` em falha de validação e limpeza periódica de blocos parciais com mais de 14 dias.
- `sincronizacao-nuvem-laudos`: Tratamento de erros HTTP `>= 400`, barra de progresso contínua na Etapa 2 (verificação no servidor), botão de fechar/continuar em segundo plano no modal e ciclo de vida de notificações nativas *sticky* (`flutter_local_notifications`) com abertura do relatório ao tocar na notificação de conclusão.

## Impact

- **`../aresta_backend/aresta_api`**:
  - `openapi/fixalog.yaml` e clientes gerados (`verificacao_concluida`, `verificacao_total` e `motivo_moderacao` em `RespostaStatusLaudoFixalog` e `RespostaChunkLaudoFixalog`).
  - `sql/fixalog_d1.sql` e `sql/generated/ts/fixalog_d1_sql.ts` (`verificacao_concluida` e `verificacao_total` em `versoes_laudo_fixalog`).
- **`../aresta_backend/cloudflare/fixalog`**:
  - `src/index.ts`, `src/moderador_midia_ia.ts`, `src/verificador_assinatura_laudo.ts`, `src/fakes/ambiente_fixalog_fake.ts` e `wrangler.toml` (Cron Trigger de limpeza de `staging/` > 14 dias).
- **`fixalog/app`**:
  - `pubspec.yaml` (`flutter_local_notifications`).
  - `lib/core/services/xml_dsig_signer.dart`, `lib/features/pdf_generation/providers/generation_provider.dart`.
  - `lib/core/services/gerenciador_notificacao_upload_laudo.dart` (novo) e `test/fakes/plugin_notificacoes_locais_fake.dart` (novo, com testes espelhados 1:1).
  - `lib/core/services/sincronizador_nuvem_service.dart` e `lib/features/pdf_generation/views/visualizador_relatorio_screen.dart`.
