# Proposal

## Why

Atualmente, a moderação de mídias de laudos no Cloudflare Worker (`aresta-fixalog-worker`) compartilha o orçamento de CPU/tempo da requisição de upload (podendo ser interrompida pela plataforma quando um laudo possui ~15 imagens) ou dependeria de um *Cron Trigger* a cada minuto (`* * * * *`) que consome ~1.440 invocações/queries D1 diárias mesmo sem nenhum upload pendente. Além disso, a esteira de CI/CD do Fixalog está defasada em relação à esteira madura do `aresta_app`, carecendo de ferramentas em Dart para cálculo SemVer determinístico (`tool/release_tools/`), upload de símbolos para Sentry e Firebase Crashlytics, publicação de notas de lançamento (`whatsnew-pt-BR`) e submissão automatizada para revisão na App Store via Fastlane (`submit_ios_review.yml`).

## What Changes

- **Moderação em Segundo Plano Auto-Encadeada com Zero Consumo Ocioso (`aresta-fixalog-worker`)**:
  - Remoção do *Cron Trigger* de 1 em 1 minuto (`* * * * *`) do `wrangler.toml`, mantendo apenas o Cron diário (`0 4 * * *`) para limpeza de blocos temporários expirados.
  - Adição do *Service Binding* auto-referenciado `SELF` (`service = "aresta-fixalog-worker"`) no `wrangler.toml` e rota interna autenticada via HMAC-SHA256 `POST /__internal/moderar/:idSessao/v:versao`.
  - Processamento da moderação CSAM/NSFW em lotes curtos por invocação (`TAMANHO_MAXIMO_POR_INVOCACAO = 3` imagens), persistindo `verificacao_concluida` no D1 e auto-encadeando o próximo lote via `ctx.waitUntil(env.SELF.fetch(...))` com orçamento renovado de CPU e *wall-clock* até concluir `verificacao_total` (`status_moderacao = 'ativo'`), com retentativa automática (`tentativa` até 3) em caso de falha transitória antes de acionar o bloqueio *fail-closed*.
  - Resposta estruturada em JSON (`{"reasoning": "...", "verdict": "SAFE" | "UNSAFE_S4" | "UNSAFE_S12"}`) no modelo `@cf/meta/llama-3.2-11b-vision-instruct` para eliminar falsos positivos causados por menções às categorias no texto explicativo e anexar o `reasoning` aos alertas de bloqueio no Sentry.
- **Paridade Completa de CI/CD de Lançamento com o `aresta_app`**:
  - Introdução do módulo `app/tool/release_tools/` (`gerenciador_semver.dart`, `calcular_versao_release.dart`, `atualizar_versao_pubspec.dart`, `calcular_proximo_dev.dart`) com espelhamento 1:1 de testes unitários em `app/test/tool/release_tools/`.
  - Atualização de `.github/workflows/release_new_app_version.yml` para receber `bump_type` (`patch`, `minor`, `major`, `custom`), `custom_version`, `enviar_para_producao` e `release_notes` (validado em `<= 500` caracteres no primeiro passo), sincronizar o submódulo de termos legais antes da tag e orquestrar `build_android`, `build_ios` e `submit_ios_review`.
  - Atualização de `.github/workflows/build_android.yml` e `.github/workflows/build_ios.yml` com upload de símbolos de debug para Sentry e Firebase Crashlytics, cache de SwiftPM, geração de `whatsnew-pt-BR` e seleção dinâmica de faixas (`internal,production` vs `internal`).
  - Adição de `.github/workflows/submit_ios_review.yml` e configuração Fastlane em `app/ios/fastlane/` (`Gemfile` e `Fastfile`) para aguardar o processamento da build no TestFlight e submeter automaticamente a versão na App Store Connect (`com.arestaclimb.fixalog` / Apple ID `6818883254`).

## Capabilities

### New Capabilities

*(Nenhuma nova capacidade isolada; evoluímos as capacidades existentes de nuvem e pipeline de release).*

### Modified Capabilities
- `worker-fixalog-nuvem`: Execução da moderação CSAM/NSFW em lotes curtos auto-encadeados via Service Binding (`env.SELF`) e rota interna autenticada por HMAC (`POST /__internal/moderar/:idSessao/v:versao`), sem *Cron Trigger* de 1 minuto, e saída estruturada JSON (`reasoning` + `verdict`) no Workers AI.
- `app-release-pipeline`: Paridade da esteira de release do Fixalog com o Aresta App, incluindo `app/tool/release_tools/`, sincronização de termos legais no release, upload de símbolos Sentry/Crashlytics, suporte a `release_notes` e `enviar_para_producao`, e submissão automatizada para revisão na App Store via Fastlane (`submit_ios_review.yml`).

## Impact

- **Backend Cloudflare Worker (`aresta_backend/cloudflare/fixalog`)**:
  - `wrangler.toml`: remoção do cron `"* * * * *"` e adição de `[[services]] binding = "SELF"`.
  - `src/moderador_midia_ia.ts`, `src/index.ts` e `src/moderador_midia_ia.test.ts`: suporte a limite de imagens por invocação, geração/validação de token HMAC interno e encadeamento via `env.SELF.fetch`.
- **Aplicativo e CI/CD (`fixalog`)**:
  - `app/lib/core/config/ferramentas_lancamento/` (ou `app/tool/release_tools/`) e respectivos testes espelhados em `app/test/`.
  - `app/ios/fastlane/Fastfile` e `app/ios/fastlane/Gemfile`.
  - `.github/workflows/release_new_app_version.yml`, `.github/workflows/build_android.yml`, `.github/workflows/build_ios.yml` e `.github/workflows/submit_ios_review.yml`.
