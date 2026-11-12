# Tasks

## 1. Moderação em Lotes Auto-Encadeados no Cloudflare Worker (`aresta-fixalog-worker`)

- [x] 1.1 Atualizar `wrangler.toml` em `aresta_backend/cloudflare/fixalog/` removendo `"* * * * *"` de `crons` (mantendo apenas `["0 4 * * *"]`) e adicionando o Service Binding `[[services]] binding = "SELF" service = "aresta-fixalog-worker"`, verificando que a configuração é válida.
- [x] 1.2 Escrever testes TDD em `aresta_backend/cloudflare/fixalog/src/moderador_midia_ia.test.ts` e `src/index.test.ts` cobrindo o processamento limitado por lote (`limitePorInvocacao`), geração/validação do token HMAC interno e auto-encadeamento via `env.SELF.fetch("https://fixalog.app/__internal/moderar/...")` até concluir todas as imagens (`status_moderacao = 'ativo'`), bem como rejeição `403` para token inválido e retentativa automática (`tentativa < 3`) antes de *fail-closed*.
- [x] 1.3 Implementar `gerarTokenModeracaoInterna`, `validarTokenModeracaoInterna`, suporte a `limiteImagensPorLote` em `executarModeracaoEmSegundoPlano` (`src/moderador_midia_ia.ts`) e a rota `POST /__internal/moderar/:idSessao/v:versao` com encadeamento via `env.SELF` em `src/index.ts`, verificando que todos os testes `deno test -A` passam e realizando o deploy em produção (`npx wrangler deploy`).

## 2. Ferramentas de Versionamento SemVer (`app/tool/release_tools/`) e Testes Espelhados

- [x] 2.1 Criar os testes unitários orientados a comportamento em `app/test/tool/release_tools/` (`gerenciador_semver_test.dart`, `calcular_versao_release_test.dart`, `atualizar_versao_pubspec_test.dart`, `calcular_proximo_dev_test.dart`) cobrindo decomposição SemVer, remoção de `-dev`, incremento de build, bump `patch`/`minor`/`major`/`custom` e avanço para o próximo ciclo `-dev`.
- [x] 2.2 Implementar `gerenciador_semver.dart`, `calcular_versao_release.dart`, `atualizar_versao_pubspec.dart` e `calcular_proximo_dev.dart` em `app/tool/release_tools/` e verificar que `flutter test test/tool/release_tools/` e `flutter test test/test_structure_mirror_test.dart` passam com 100% de sucesso.

## 3. Paridade Completa dos Workflows de CI/CD e Fastlane iOS

- [x] 3.1 Criar `app/ios/fastlane/Gemfile` e `app/ios/fastlane/Fastfile` configurados para o identificador `com.arestaclimb.fixalog` e Apple ID `6818883254` (lane `submeter_revisao` com `FastlaneCore::BuildWatcher` e `deliver`).
- [x] 3.2 Criar `.github/workflows/submit_ios_review.yml` e atualizar `.github/workflows/release_new_app_version.yml`, `.github/workflows/build_android.yml` e `.github/workflows/build_ios.yml` com paridade completa em relação ao `aresta_app` (validação de `release_notes <= 500`, sincronização de termos legais no release, upload de símbolos Sentry e Firebase Crashlytics, `whatsnew-pt-BR`, seleção de faixas `internal,production` vs `internal` e encadeamento do `submit_ios_review`), verificando a validade sintática dos YAMLs e da suíte de testes do repositório.
