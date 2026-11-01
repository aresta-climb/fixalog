# Tasks: Migração do Banco de Dados Local do Isar para SQLite (`sqflite`)

## 1. Dependências e Remoção do Isar / Build Runner

- [ ] 1.1 Atualizar `app/pubspec.yaml` substituindo `isar_community`, `isar_community_flutter_libs`, `isar_community_generator` e `build_runner` por `sqflite` (em `dependencies`) e `sqflite_common_ffi` + `sqlite3_flutter_libs` se necessário (em `dev_dependencies`), remover `app/build.yaml` e os arquivos `.g.dart` (`app_config_record.g.dart`, `identity_record.g.dart`, `submission_record.g.dart`), verificando que `flutter pub get` executa com sucesso.

## 2. Modelos Locais em Dart Puro e Serviço `BancoDadosLocal` (Library-First & TDD)

- [ ] 2.1 [TDD] Reescrever os testes unitários espelhados `app/test/core/models/local/app_config_record_test.dart`, `identity_record_test.dart` e `submission_record_test.dart` validando serialização (`toMap`/`fromMap`) e persistência real em banco SQLite `:memory:`, e converter `app/lib/core/models/local/app_config_record.dart`, `identity_record.dart` e `submission_record.dart` para classes Dart puras sem anotações do Isar, verificando que os 3 arquivos de teste passam com 100% de cobertura.
- [ ] 2.2 [TDD] Criar `app/test/core/services/banco_dados_local_test.dart` e implementar `app/lib/core/services/banco_dados_local.dart` (com `abrirEmArquivo`, `abrirEmMemoria` via `databaseFactoryFfiNoIsolate`, operações CRUD para `configuracao_app`, `identidade` e `submissoes`, e stream reativo de submissões), verificando que `flutter test test/core/services/banco_dados_local_test.dart` passa com 100% de cobertura.

## 3. Migração de Onboarding, Identidade e Histórico (TDD & In-Memory SQLite)

- [ ] 3.1 [TDD] Atualizar `app/lib/main.dart`, `app/lib/features/onboarding/views/tela_termos_de_uso.dart` e seus testes espelhados (`app/test/main_test.dart` e `app/test/features/onboarding/views/tela_termos_de_uso_test.dart`) para usar `BancoDadosLocal` em memória (removendo `FakeIsarTxn` e `FakeAppConfigCollection`), verificando que os testes de widget passam com 100% de cobertura.
- [ ] 3.2 [TDD] Atualizar `app/lib/features/identity/repositories/identity_repository.dart`, `app/lib/features/identity/viewmodels/identity_form_view_model.dart` e seus testes (`app/test/features/identity/repositories/identity_repository_test.dart` e `identity_form_view_model_test.dart`) para operar sobre `BancoDadosLocal` em memória, verificando que os testes passam com 100% de cobertura.
- [ ] 3.3 [TDD] Atualizar `app/lib/features/home/providers/history_provider.dart` e `app/test/features/home/providers/history_provider_test.dart` para observar e excluir submissões via `BancoDadosLocal` em memória, verificando que os testes passam com 100% de cobertura.

## 4. Migração do Motor do Wizard e Geração/Visualização de Relatórios

- [ ] 4.1 [TDD] Atualizar `app/lib/features/wizard/controllers/wizard_state_controller.dart` e seus testes (`wizard_state_controller_test.dart` e `wizard_state_controller_persistence_test.dart`) para persistir rascunhos e consultar materiais via `BancoDadosLocal` em memória, verificando que toda a suíte de testes do Wizard passa.
- [ ] 4.2 [TDD] Atualizar `app/lib/features/pdf_generation/providers/generation_provider.dart`, `app/lib/features/pdf_generation/views/visualizador_relatorio_screen.dart` e seus respectivos testes espelhados para gravar e atualizar `SubmissionRecord` no `BancoDadosLocal`, verificando que os testes passam com 100% de cobertura.

## 5. Testes de Integração, Documentação e Verificação Global

- [ ] 5.1 Atualizar os testes de integração em `app/integration_test/` (`draft_persistence_flow_test.dart`, `fluxo_termos_de_uso_test.dart`, `history_update_test.dart`) para inicializar `BancoDadosLocal` com SQLite real, verificando que não resta nenhuma referência a `isar` em `app/`.
- [ ] 5.2 Atualizar `AGENTS.md`, `README.md`, `docs/ROTEIRO_INTEGRACAO_ARESTA.md` e `openspec/config.yaml` substituindo as menções ao Isar por SQLite (`sqflite`) e documentando a diretriz de testes com banco SQLite `:memory:`.
- [ ] 5.3 Executar `flutter analyze`, `flutter test test/architecture/test_structure_mirror_test.dart` e `flutter test --coverage` garantindo zero avisos de lint, espelhamento 1:1 intacto e 100% de cobertura comportamental.
