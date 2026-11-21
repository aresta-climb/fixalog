# Módulo Smoke CI (`app/lib/core/smoke_ci/`)

Contém o ponto de entrada alternativo (`main_smoke_ci.dart`) e o executor da jornada funcional pós-build (`executor_jornada_smoke.dart`) utilizados exclusivamente pelos artefatos descartáveis de CI (`--target=lib/core/smoke_ci/main_smoke_ci.dart`).

## Garantias de Isolamento e Segurança

- **Ausência nos binários das lojas**: `app/lib/main.dart` e os demais módulos de produção jamais importam `core/smoke_ci/` (invariante verificada automaticamente por `app/test/architecture/isolamento_smoke_ci_test.dart` e pela auditoria binária `auditar_binario_loja.dart`).
- **Restrição dupla de execução**: `ConfiguracaoSmokeCi` exige protocolo HTTP sobre endereços exclusivos de loopback local (`127.0.0.1`, `localhost` ou `10.0.2.2`) e token efêmero fornecido pelo canal nativo compilado condicionalmente apenas para emulador Android QEMU (`BuildConfig.ARESTA_SMOKE_CI`) e iOS Simulator (`#if targetEnvironment(simulator)`).
