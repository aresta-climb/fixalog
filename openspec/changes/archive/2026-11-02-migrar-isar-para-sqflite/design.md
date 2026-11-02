# Design: Migração do Isar para SQLite (`sqflite`) com Testes `In-Memory`

## Context

Atualmente o Fixalog utiliza o `isar_community` para persistir apenas três entidades locais: `AppConfigRecord` (singleton de consentimento legal), `IdentityRecord` (singleton de identificação do mantenedor) e `SubmissionRecord` (catálogo plano de sessões de manutenção e materiais que aponta para os diretórios de *Session Bundle* e arquivos `.binarypb`/`.epub`). Veja `proposal.md` para a motivação completa.

## Goals / Non-Goals

**Goals:**
- Substituir integralmente o `isar_community` por `sqflite` em produção e `sqflite_common_ffi` nos testes.
- Eliminar `build_runner`, `isar_community_generator`, `app/build.yaml` e todos os arquivos `.g.dart` de banco de dados.
- Prover abertura de banco SQLite `:memory:` (`inMemoryDatabasePath`) com `databaseFactoryFfiNoIsolate` para que todos os testes unitários e de widget executem SQL real sem mocks, sem fakes manuais de banco e sem necessidade de `tester.runAsync`.
- Remover a nulabilidade artificial de banco de dados (`Isar?`) nos repositórios, controllers e views, aderindo ao Princípio IV do `AGENTS.md`.
- Manter a atualização reativa da aba de Histórico via `Stream` emitido pelas operações de escrita no banco SQLite.

**Non-Goals:**
- Alterar o formato dos *Session Bundles* no sistema de arquivos ou dos manifestos Protobuf (`registro.binarypb`).
- Utilizar ORMs baseados em geração de código como `drift` ou `floor`.
- Manter dependência transitória do `isar_community` para ler o arquivo binário `default.isar` (em vez disso, os registros de relatórios e rascunhos serão reconstruídos diretamente dos *Session Bundles* já salvos em `app_docs/sessoes/`).

## Decisions

### 1. Driver Direto `sqflite` vs ORM `drift`
- **Decisão**: Utilizar `sqflite` diretamente com modelos Dart puros (`toMap()` / `fromMap()`) encapsulados por um serviço central `BancoDadosLocal` (`app/lib/core/services/banco_dados_local.dart`).
- **Por que**: O esquema relacional possui apenas 3 tabelas planas sem `JOIN`s. O uso de `sqflite` evita substituir o `build_runner` do Isar pelo `build_runner` do `drift`, mantém total simplicidade (Princípio VI) e iguala a stack ao `aresta_app`.
- **Alternativas consideradas**: `drift` (rejeitado por exigir geração de código `.g.dart` e classes `Companion` desnecessárias para 3 tabelas simples).

### 2. Esquema SQLite e Tabelas
- **Decisão**: Definir 3 tabelas explícitas na inicialização (`onCreate`) do `BancoDadosLocal`:
  1. `configuracao_app`: `id INTEGER PRIMARY KEY`, `versao_termos_aceita INTEGER NOT NULL DEFAULT 0`, `data_hora_aceite_termos TEXT` (ISO-8601).
  2. `identidade`: `id INTEGER PRIMARY KEY AUTOINCREMENT`, `nome TEXT NOT NULL`, `clube_associacao TEXT NOT NULL`, `data_registro TEXT NOT NULL`.
  3. `submissoes`: `id INTEGER PRIMARY KEY AUTOINCREMENT`, `id_sessao TEXT NOT NULL UNIQUE`, `id_protocolo TEXT NOT NULL`, `nome_protocolo TEXT NOT NULL`, `titulo_exibicao TEXT NOT NULL`, `tipo_registro TEXT NOT NULL`, `data_inclusao TEXT NOT NULL`, `data_ultima_selecao TEXT`, `hash_assinatura TEXT NOT NULL`, `pdf_path TEXT NOT NULL`, `protobuf_path TEXT NOT NULL`, `enviado_nuvem INTEGER NOT NULL DEFAULT 0`, `status TEXT NOT NULL`.
- **Por que**: Nomenclatura de tabelas e colunas 100% em português brasileiro (Princípio I), preservando compatibilidade direta com os campos das classes Dart existentes e garantindo unicidade em `id_sessao` via constraint `UNIQUE` nativa do SQLite.

### 3. Bancos `In-Memory` com `databaseFactoryFfiNoIsolate` nos Testes (Princípio V)
- **Decisão**: Criar um construtor/fábrica `BancoDadosLocal.abrirEmMemoria()` que utiliza `databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath, ...)` com o mesmo schema SQL de produção.
- **Por que**:
  - Executa o motor C real do SQLite na memória RAM em menos de 1ms por teste.
  - Por usar `databaseFactoryFfiNoIsolate`, funciona dentro do `FakeAsync` do `testWidgets` sem travar em `pumpAndSettle()` e sem exigir `tester.runAsync`.
  - Dispensa completamente mocks (`mocktail`) ou fakes manuais (`FakeIsarTxn`) para a camada de persistência.

### 4. Reatividade na Aba de Histórico sem Polling
- **Decisão**: O `BancoDadosLocal` (ou `HistoryRepository`) mantém um `StreamController<void>.broadcast()` que emite um evento sempre que uma mutação (`salvarSubmissao`, `deletarSubmissaoPorIdSessao`, etc.) ocorre na tabela `submissoes`. O método `watchHistory()` emite imediatamente a consulta atual ordenada por `data_inclusao DESC` e re-executa a consulta a cada evento do stream.
- **Por que**: Substitui o `.watch(fireImmediately: true)` do Isar com menos de 15 linhas de código Dart puro e determinístico.

### 5. Reindexação Automática a partir de `app_docs/sessoes/` (Auto-Healing e Migração sem Isar)
- **Decisão**: Ao inicializar o `BancoDadosLocal` em arquivo, executar `sincronizarSessoesDoDisco(Directory diretorioBase)`:
  1. Se existirem arquivos `default.isar` ou `default.isar.lock` no diretório base de documentos, removê-los silenciosamente.
  2. Verificar o diretório `<diretorioBase>/sessoes/`. Para cada pasta `<id_sessao>` que não possua registro correspondente (`id_sessao`) na tabela `submissoes`:
     - Ler `registro.binarypb` (ou extrair de `relatorio.epub` se aplicável) deserializando a mensagem Protobuf `Registro`.
     - Determinar `idProtocolo`, `nomeProtocolo` (a partir do `yamlConteudo` ou ID), `tituloExibicao` (buscando as respostas `mat_nome`, `via_nome` ou `nome_via`), `tipoRegistro` (`MATERIAL` quando `idProtocolo == 'cadastro_material'`, caso contrário `MANUTENCAO`) e `dataInclusao` (a partir de `utcTimestampInicio` ou data de modificação da pasta).
     - Verificar se existe `relatorio.epub` na pasta da sessão: se existir, definir `status = 'GERADO'` e `protobufPath = '<pasta>/relatorio.epub'`; caso contrário, definir `status = 'EM_PROGRESSO'` e `protobufPath = '<pasta>/registro.binarypb'`. Se existir PDF resumido na pasta, preencher `pdfPath`.
     - Inserir o `SubmissionRecord` reconstruído na tabela `submissoes`.
- **Por que**: Permite remover o Isar imediatamente sem perder nenhum relatório ou rascunho já criado no celular do usuário, além de dotar o aplicativo de capacidade de *auto-healing* do Histórico a partir dos *Session Bundles*.

## Risks / Trade-offs

- **[Risco] Chamadas síncronas legadas (`getSync`, `findAllSync`, `writeTxnSync`)** → *Mitigação*: No `main.dart`, os dados de configuração inicial (`AppConfigRecord`) serão carregados na inicialização assíncrona do banco (que já usa `await` antes do `runApp`) ou expostos no wrapper do `BancoDadosLocal`, e no `WizardStateController` as operações sobre materiais utilizarão métodos assíncronos ou cache reativo do `BancoDadosLocal`.
- **[Risco] Vazamento de conexões em memória entre testes** → *Mitigação*: Cada `BancoDadosLocal.abrirEmMemoria()` gera uma instância isolada fechada no `tearDown` (`await banco.fechar()`).
