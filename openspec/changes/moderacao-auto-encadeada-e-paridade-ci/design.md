# Design

## Context

Conforme detalhado em `proposal.md`, precisamos resolver duas frentes complementares:
1. No backend Cloudflare Worker (`aresta-fixalog-worker`), garantir que a moderação CSAM/NSFW em 3 camadas processe laudos com qualquer quantidade de fotos e keyframes sem estourar o orçamento de execução de uma única invocação e sem desperdiçar cota ociosa com um *Cron Trigger* de 1 em 1 minuto (`* * * * *`).
2. No repositório `fixalog`, alinhar 100% da esteira de CI/CD de lançamento (`.github/workflows/*`, `app/tool/release_tools/*` e `app/ios/fastlane/*`) com a arquitetura comprovada do `aresta_app`, respeitando a regra de espelhamento 1:1 de testes do `AGENTS.md`.

## Goals / Non-Goals

**Goals:**
- Garantir **zero consumo ocioso de Worker/D1** quando nenhum laudo está sendo enviado, removendo `"* * * * *"` do `wrangler.toml`.
- Processar a moderação de mídias em lotes curtos (`TAMANHO_MAXIMO_POR_INVOCACAO = 3` imagens) com auto-encadeamento via *Service Binding* (`env.SELF.fetch`) sobre a rota autenticada `POST /__internal/moderar/:idSessao/v:versao`.
- Manter 100% de paridade funcional entre os workflows de release do `fixalog` e do `aresta_app`, com testes unitários espelhados para todas as ferramentas Dart de release.

**Non-Goals:**
- Introduzir dependências pagas como Cloudflare Queues ou migrar o Worker para Cloudflare Workflows beta.
- Alterar o formato criptográfico do pacote `.epub` assinado.

## Decisions

### 1. Auto-Encadeamento em Lotes via Service Binding (`env.SELF`) vs Cron `* * * * *` ou Cloudflare Workflows
- **Decisão**: Utilizar um *Service Binding* auto-referenciado (`binding = "SELF"`, `service = "aresta-fixalog-worker"`) combinado com uma rota interna assinada por HMAC-SHA256 (`POST /__internal/moderar/:idSessao/v:versao?etapa=<n>&tentativa=<t>&token=<hmac>`).
- **Racional**:
  - Cada chamada `env.SELF.fetch(...)` dispara uma nova invocação independente do Worker com orçamento de CPU e *wall-clock* (30s) completamente zerado.
  - Processando no máximo `3` imagens por invocação (1 batch paralelo de 3 imagens no CSAM Scan + Llama 3.2 Vision), cada invocação leva ~4–6 segundos, longe do limite de timeout da Cloudflare.
  - Ao final do lote, o Worker persiste `verificacao_concluida` no D1 e, se `verificacao_concluida < verificacao_total`, agenda `ctx.waitUntil(dispararProximoLoteModeracao(...))` chamando `env.SELF.fetch`.
  - Se `env.SELF` não estiver definido (ex.: testes unitários isolados que invocam `executarModeracaoEmSegundoPlano` sem binding de serviço), o código pode processar até o limite solicitado ou encadear via `fetch` injetável, mantendo testabilidade determinística em memória.
- **Alternativas descartadas**:
  - *Cron `* * * * *`*: Consome 1.440 invocações e leituras D1 por dia mesmo com o sistema ocioso.
  - *Cloudflare Workflows*: Possui cota gratuita menor e adiciona acoplamento de estado externo ao D1.

### 2. Organização e Espelhamento 1:1 das Ferramentas de Release (`release_tools`)
- **Decisão**: Posicionar os scripts de linha de comando em `app/tool/release_tools/` (`gerenciador_semver.dart`, `calcular_versao_release.dart`, `atualizar_versao_pubspec.dart`, `calcular_proximo_dev.dart`), idêntico ao `aresta_app/frontend/tool/release_tools/`, e criar os testes unitários correspondentes em `app/test/tool/release_tools/`.
- **Racional**:
  - O validador `app/test/test_structure_mirror_test.dart` inspeciona `app/lib/`, portanto arquivos em `app/tool/release_tools/` não quebram o espelhamento de `lib/`, e ainda assim adicionaremos toda a suíte `app/test/tool/release_tools/*_test.dart` para garantir cobertura comportamental de 100% dos utilitários de release.

### 3. Resiliência Gradual para Secrets Opcionais de Telemetria no CI (`SENTRY_AUTH_TOKEN` e `FIREBASE_SERVICE_ACCOUNT_JSON`)
- **Decisão**: Nos workflows `build_android.yml` e `build_ios.yml`, executar os passos de upload de símbolos do Sentry (`sentry_dart_plugin`) e do Firebase Crashlytics verificando a presença de `SENTRY_AUTH_TOKEN` e `FIREBASE_SERVICE_ACCOUNT_JSON` (emitindo `::warning::` claro se ainda não configurados no repositório e executando em modo *fail-fast* assim que configurados).
- **Racional**: Evita bloquear um lançamento emergencial caso o administrador atualize primeiro apenas `ANDROID_PLAY_STORE_CONFIG_JSON`, mas garante execução automática assim que os 3 secrets estiverem sincronizados.

## Risks / Trade-offs

- **[Risco] Falha transitória de rede ou rate-limit do Workers AI no meio de um lote auto-encadeado** → **Mitigação**: Se um lote lançar exceção técnica e `tentativa < 3`, a rota `/__internal/moderar` re-encadeia o mesmo lote (`etapa = verificacao_concluida` atual) com `tentativa + 1` após um breve backoff; somente se esgotar as 3 tentativas o laudo entra em `status_moderacao = 'bloqueado'` (*fail-closed*) e alerta o Sentry.
- **[Risco] Limite de profundidade de subrequests na mesma cadeia síncrona** → **Mitigação**: Ao disparar a chamada via `ctx.waitUntil(env.SELF.fetch(...))` após persistir no D1 e retornar `202 Accepted` imediatamente na invocação anterior, ou caso a Cloudflare imponha limite de encadeamento em laudos gigantes (>45 imagens), cada lote processa até 4 imagens por invocação (suportando até 60–120 imagens em poucas etapas).
