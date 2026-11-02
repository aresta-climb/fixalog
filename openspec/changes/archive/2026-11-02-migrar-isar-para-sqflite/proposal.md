# Proposta: Migração do Banco de Dados Local do Isar para SQLite (`sqflite`)

## Why

O Fixalog adotou inicialmente o Isar (`isar_community`) como banco de dados local, mas a evolução arquitetural para *Session Bundles* e manifestos Protobuf (`registro.binarypb`) reduziu o papel do banco local a apenas três tabelas planas de metadados e singletons (`AppConfigRecord`, `IdentityRecord` e `SubmissionRecord`). Além de o pacote original do Isar estar descontinuado, ele exige `build_runner` para gerar milhares de linhas em arquivos `.g.dart`, dificulta a execução de testes de widget (forçando a nulabilidade artificial `Isar?` por todo o código de produção) e diverge do restante do ecossistema **Aresta Climb** (`aresta_app`), que já utiliza `sqflite`.

Migrar para **`sqflite`** (com **`sqflite_common_ffi`** rodando instâncias SQLite reais `:memory:` em todos os testes unitários e de widget) unifica a stack com o Aresta, elimina integralmente o `build_runner` e os pacotes `isar_community*`, remove os desvios defensivos `if (isar != null)` do código de produção e eleva a fidelidade dos testes sem necessidade de mocks ou fakes manuais de banco de dados.

## What Changes

- **BREAKING (Interno): Substituição do Isar pelo `sqflite`**:
  - Remoção das dependências `isar_community`, `isar_community_flutter_libs`, `isar_community_generator`, `build_runner` e do arquivo `app/build.yaml`.
  - Remoção dos arquivos gerados `app_config_record.g.dart`, `identity_record.g.dart` e `submission_record.g.dart`.
  - Adição de `sqflite` em `dependencies` e `sqflite_common_ffi` em `dev_dependencies` no `app/pubspec.yaml`.
- **Módulo de Banco de Dados SQLite (`BancoDadosLocal` / `provedorBancoDados`)**:
  - Criação de serviço centralizado em `app/lib/core/services/banco_dados_local.dart` responsável pela abertura e criação das tabelas SQLite (`configuracao_app`, `identidade`, `submissoes`) tanto em arquivo local (produção) quanto em memória (`inMemoryDatabasePath` via `databaseFactoryFfiNoIsolate` para testes).
- **Reconstrução Automática de Sessões pelo Disco (`reindexarSessoesDoDisco`) e Limpeza do Isar Legado**:
  - Rotina automática executada na abertura do `BancoDadosLocal` que inspeciona `app_docs/sessoes/<id_sessao>/`, lê os manifestos `registro.binarypb` (e verifica a presença de `relatorio.epub` / `.pdf`) e reconstrói no SQLite todos os registros `SubmissionRecord` (rascunhos e relatórios gerados, de manutenção ou material) que ainda não estejam indexados, garantindo perda zero dos relatórios existentes no celular sem manter dependência do Isar.
  - Exclusão automática de arquivos residuais `default.isar` e `default.isar.lock` caso existam no diretório de documentos.
- **Modelos Locais em Dart Puro (Princípio I e VI)**:
  - Conversão de `AppConfigRecord`, `IdentityRecord` e `SubmissionRecord` para classes Dart puras com serialização explícita `toMap()` / `fromMap()`, sem anotações nem geração de código.
- **Reatividade e Eliminação de Nulabilidade Artificial (Princípio IV)**:
  - Substituição do `isarProvider` (`Isar?`) por provedor de banco de dados SQLite e repositórios com notificação reativa via `StreamController` / Riverpod para o Histórico (`HistoryRepository`), eliminando checagens defensivas de banco nulo nos controllers e telas.
- **Suíte de Testes 100% `in-memory` SQLite (Princípio V)**:
  - Atualização de todos os testes unitários, de widget e de integração para utilizarem instâncias reais de SQLite em memória (`:memory:`), removendo `FakeIsarTxn`, `FakeAppConfigCollection` e downloads de binários do Isar (`Isar.initializeIsarCore`).
- **Governança e Documentação**:
  - Atualização de `AGENTS.md`, `README.md` e `openspec/config.yaml` refletindo o SQLite (`sqflite`) como banco de dados local oficial do Fixalog.

## Capabilities

### New Capabilities
*(Nenhuma nova capacidade funcional externa é introduzida; trata-se de modernização da infraestrutura de persistência local)*

### Modified Capabilities
- `arquitetura-mvvm`: Atualiza o requisito do padrão Repository para abstrair o acesso ao banco local SQLite (`sqflite`) em vez do Isar.
- `history-tracking`: Atualiza os requisitos de persistência e listagem de rascunhos e relatórios (`SubmissionRecord`) para utilizar o banco local SQLite.
- `onboarding-terms`: Atualiza os requisitos de verificação e gravação da auditoria de aceite dos termos (`AppConfigRecord`) para o banco local SQLite.
- `session-bundle-storage`: Atualiza o requisito de exclusão de sessão para remover o registro correspondente do banco local SQLite.
- `unified-wizard-engine`: Atualiza o requisito do pipeline de persistência unificado do Wizard para sincronizar o status da sessão no banco local SQLite.

## Impact

- **Dependências (`app/pubspec.yaml` e `app/build.yaml`)**:
  - Remoção de `isar_community`, `isar_community_flutter_libs`, `isar_community_generator` e `build_runner`.
  - Adição de `sqflite` e `sqflite_common_ffi`.
- **Modelos e Serviços (`app/lib/core/`)**:
  - `app/lib/core/services/banco_dados_local.dart` (novo).
  - `app/lib/core/models/local/app_config_record.dart`, `identity_record.dart`, `submission_record.dart` (refatorados para Dart puro com `toMap`/`fromMap`).
- **Features e Fluxos (`app/lib/features/` e `app/lib/main.dart`)**:
  - `app/lib/main.dart`, `tela_termos_de_uso.dart`, `identity_repository.dart`, `identity_form_view_model.dart`, `history_provider.dart`, `wizard_state_controller.dart`, `generation_provider.dart`, `visualizador_relatorio_screen.dart`.
- **Testes (`app/test/` e `app/integration_test/`)**:
  - Migração integral dos testes para SQLite `in-memory` (`sqflite_common_ffi`).
