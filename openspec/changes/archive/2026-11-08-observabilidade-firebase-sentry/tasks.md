# Tasks: Implementação da Observabilidade Dual (Firebase + Sentry), App Check e Gestão de Memória

## 1. Dependências e Configuração de Plataforma

- [x] 1.1 Adicionar dependências `firebase_core`, `firebase_crashlytics`, `firebase_app_check`, `firebase_analytics`, `firebase_remote_config`, `sentry_flutter: ^10.2.0` e dev_dependency `sentry_dart_plugin: ^3.4.0` em `app/pubspec.yaml` e verificar com `flutter pub get`
- [x] 1.2 Configurar a seção `sentry:` no `app/pubspec.yaml` apontando para o projeto `fixalog` (org Aresta Climb) com `upload_debug_symbols: true` e `upload_source_maps: true`

## 2. Serviço RegistroLogger e Fake Determinístico (Library-First & TDD)

- [x] 2.1 [TDD - Red] Escrever testes unitários em `app/test/core/services/registro_logger_test.dart` (com cabeçalho SPDX) cobrindo `logInfo`, `logAviso`, `logError`, `logFalhaSyncOuDownload`, `logCrash` e o classificador `isFalhaConexaoOuTimeout`
- [x] 2.2 [TDD - Green] Implementar a classe `RegistroLogger` em `app/lib/core/services/registro_logger.dart` com envio dual (Crashlytics + Sentry), injeção de clientes/delegates para testes determinísticos e filtro de falhas transitórias de montanha
- [x] 2.3 [TDD] Implementar a biblioteca test-only `RegistroLoggerFake` em `app/test/fakes/registro_logger_fake.dart` e validar seu contrato com `app/test/fakes/registro_logger_fake_test.dart` (Princípio V do `AGENTS.md`)

## 3. Atestação de Integridade Firebase App Check e Instrumentação de Nuvem

- [x] 3.1 [TDD - Red] Escrever testes unitários em `app/test/core/services/servico_app_check_test.dart` validando ativação em modo release/debug, obtenção de token e degradação graciosa em falhas de rede offline
- [x] 3.2 [TDD - Green] Implementar `ServicoAppCheck` em `app/lib/core/services/servico_app_check.dart` encapsulando `FirebaseAppCheck` e registrando avisos de rede via `RegistroLogger`
- [x] 3.3 [TDD] Integrar `ServicoAppCheck` e `RegistroLogger` em `AutenticacaoNuvemService` (`app/lib/core/services/autenticacao_nuvem_service.dart`) e `SincronizadorNuvemService` (`app/lib/core/services/sincronizador_nuvem_service.dart`), substituindo blocos `catch (_)` silenciosos por `logFalhaSyncOuDownload` e atualizando seus respectivos testes em `app/test/core/services/`

## 4. Gestão Adaptativa de Memória do Hardware

- [x] 4.1 [TDD - Red] Escrever testes unitários em `app/test/core/services/classificador_dispositivo_test.dart` simulando diferentes faixas de memória física (`<= 3 GB`, `4-6 GB`, `>= 8 GB`) e ausência de `/proc/meminfo`
- [x] 4.2 [TDD - Green] Implementar `ClassificadorDispositivo` em `app/lib/core/services/classificador_dispositivo.dart` aplicando o dimensionamento dinâmico de `PaintingBinding.instance.imageCache` (50 MB, 100 MB ou 150 MB)

## 5. Serviços de Apoio Firebase (Configuração Remota e Telemetria)

- [x] 5.1 [TDD] Implementar `ServicoConfiguracaoRemota` em `app/lib/core/services/servico_configuracao_remota.dart` com fallbacks estáticos para operação 100% offline e testes espelhados em `app/test/core/services/servico_configuracao_remota_test.dart`
- [x] 5.2 [TDD] Implementar `ServicoTelemetria` em `app/lib/core/services/servico_telemetria.dart` com testes espelhados em `app/test/core/services/servico_telemetria_test.dart`

## 6. Integração na Inicialização e Automação de CI/CD

- [x] 6.1 Atualizar `app/lib/main.dart` (e `app/test/main_test.dart`) para invocar a inicialização resiliente do Firebase, `ServicoAppCheck`, `ClassificadorDispositivo` e envolver a execução em `SentryFlutter.init` com captura de erros de zona e `PlatformDispatcher.instance.onError`
- [x] 6.2 Atualizar `.github/workflows/build_android.yml` e `.github/workflows/build_ios.yml` adicionando `--obfuscate --split-debug-info=build/symbols` e upload condicional de símbolos com `sentry_dart_plugin`, atualizando também `app/test/architecture/pipeline_ci_android_test.dart`

## 7. Auditoria de Qualidade e Conformidade Arquitetural

- [x] 7.1 Executar os testes arquiteturais (`flutter test test/architecture/`) validando espelhamento 1:1 (`test_structure_mirror_test.dart`), cabeçalhos SPDX (`license_headers_test.dart`) e pipeline CI (`pipeline_ci_android_test.dart`)
- [x] 7.2 Executar a suíte completa de testes (`flutter test --coverage`) e análise estática (`flutter analyze`) garantindo 100% de cobertura nos novos módulos e zero warnings
