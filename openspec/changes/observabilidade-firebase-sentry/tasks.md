# Tasks: Implementação da Observabilidade Dual (Firebase + Sentry)

## 1. Dependências e Configuração de Plataforma

- [ ] 1.1 Adicionar dependências `firebase_core`, `firebase_crashlytics`, `firebase_analytics`, `firebase_remote_config`, `sentry_flutter: ^10.2.0` e `sentry_dart_plugin: ^3.4.0` em `app/pubspec.yaml` e verificar com `flutter pub get`
- [ ] 1.2 Configurar a seção `sentry:` no `app/pubspec.yaml` apontando para o projeto `fixlog` com upload de símbolos e mapas ativado

## 2. Serviço RegistroLogger (Library-First & TDD)

- [ ] 2.1 [TDD - Red] Escrever testes unitários em `app/test/core/services/registro_logger_test.dart` cobrindo `logInfo`, `logAviso`, `logError`, `logCrash` e o filtro `isFalhaConexaoOuTimeout`
- [ ] 2.2 [TDD - Green] Implementar a classe `RegistroLogger` em `app/lib/core/services/registro_logger.dart` com envio dual e proteção de falhas transitórias
- [ ] 2.3 Implementar a biblioteca test-only `RegistroLoggerFake` em `app/test/fakes/registro_logger_fake.dart` e validar com `app/test/fakes/registro_logger_fake_test.dart` (Princípio V)

## 3. Gestão Adaptativa de Memória do Hardware

- [ ] 3.1 [TDD - Red] Escrever testes unitários em `app/test/core/services/classificador_dispositivo_test.dart` simulando diferentes faixas de memória física
- [ ] 3.2 [TDD - Green] Implementar `ClassificadorDispositivo` em `app/lib/core/services/classificador_dispositivo.dart` aplicando o dimensionamento de `imageCache`

## 4. Serviços de Apoio Firebase (Configuração Remota e Telemetria)

- [ ] 4.1 [TDD] Implementar `ServicoConfiguracaoRemota` em `app/lib/core/services/servico_configuracao_remota.dart` com fallbacks estáticos para modo offline e testes espelhados em `servico_configuracao_remota_test.dart`
- [ ] 4.2 [TDD] Implementar `ServicoTelemetria` em `app/lib/core/services/servico_telemetria.dart` com testes espelhados em `servico_telemetria_test.dart`

## 5. Integração na Inicialização e Testes de Fronteira

- [ ] 5.1 Atualizar `app/lib/main.dart` para invocar a inicialização do Firebase e envolver a aplicação no `SentryFlutter.init`
- [ ] 5.2 Escrever teste de integração de fronteira em `app/integration_test/inicializacao_observabilidade_test.dart` validando boot sem conectividade

## 6. Automação de CI/CD e Desofuscação

- [ ] 6.1 Atualizar `.github/workflows/build_android.yml` adicionando o passo de desofuscação e upload de símbolos com `sentry_dart_plugin` e flags `--split-debug-info=build/symbols`

## 7. Auditoria de Qualidade

- [ ] 7.1 Executar a suíte completa de testes unitários com medição de cobertura (`flutter test --coverage`) e verificar 100% de cobertura nos novos serviços
- [ ] 7.2 Executar análise estática de código (`flutter analyze`) garantindo conformidade arquitetural
