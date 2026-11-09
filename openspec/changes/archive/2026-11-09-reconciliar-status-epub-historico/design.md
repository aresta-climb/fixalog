# Design

## Context

Veja `proposal.md` para a motivação completa. Atualmente:
1. Em `BancoDadosLocal.sincronizarSessoesDoDisco`, registros que já estão na tabela `submissoes` são ignorados (`if (_submissoesPorSessao.containsKey(idSessao)) continue;`), mesmo que estejam com `epubPath` vazio ou com `status == GERADO` sem arquivo `.epub` em disco.
2. Em `HistoryScreen._localizarCaminhoEpub`, o código não verifica `sessoes/<idSessao>/relatorio.epub` a partir do diretório da sessão (`protobufPath` ou `pdfPath`), nem valida se `record.epubPath` existe em disco quando preenchido.
3. Em `HistoryScreen._abrirRelatorio`, quando `_localizarCaminhoEpub` retorna `null`, o código executa `ref.read(pdfViewerServiceProvider).openPdf(caminhoPdf)`, que chama `OpenFilex.open` no PDF resumido e aciona a folha nativa do sistema operacional em vez do `VisualizadorRelatorioScreen`.

## Goals / Non-Goals

**Goals:**
- Remover o fallback de abertura externa de PDF (`PdfViewerService.openPdf`) em `HistoryScreen._abrirRelatorio`.
- Resolver de forma determinística o caminho do `.epub` verificando a existência física em disco, incluindo o caminho canônico `sessoes/<idSessao>/relatorio.epub`.
- Reconciliar registros `GERADO` sem `.epub` em disco tanto na inicialização do `BancoDadosLocal` quanto no toque da `HistoryScreen`, rebaixando-os para `EM_PROGRESSO` e abrindo-os para edição no `WizardScreen`.

**Non-Goals:**
- Reconstruir ou re-assinar pacotes `.epub` silenciosamente em segundo plano sem ação explícita do usuário no `WizardScreen` (preservando o Princípio VIII do `AGENTS.md`).

## Decisions

### 1. Reconciliação de Registros Existentes em `BancoDadosLocal.sincronizarSessoesDoDisco`
- **Decisão**:
  - Ao executar `sincronizarSessoesDoDisco(Directory diretorioBase)`, além de indexar diretórios `sessoes/<idSessao>` inéditos, iterar sobre os registros já carregados em `_submissoesPorSessao`:
    1. Verificar se existe um arquivo `.epub` válido em disco para o registro na seguinte ordem:
       - `record.epubPath` (se não vazio e `File(record.epubPath).existsSync()`);
       - `record.protobufPath` (se terminar com `.epub` e `File(record.protobufPath).existsSync()`);
       - `p.join(diretorioBase.path, 'sessoes', record.idSessao, 'relatorio.epub')` (se existir em disco);
       - `p.join(p.dirname(record.protobufPath), 'relatorio.epub')` (se `protobufPath` não for vazio e o arquivo existir);
       - `p.join(p.dirname(record.pdfPath), 'relatorio.epub')` ou irmão `.epub` de `record.pdfPath` (se existir).
    2. Se o arquivo `.epub` for encontrado em disco e `record.epubPath != caminhoEncontrado`, atualizar `record.epubPath = caminhoEncontrado` no SQLite.
    3. Se o arquivo `.epub` **não** existir em disco e `record.isGerado` for verdadeiro (e existirem dados da sessão em `sessoes/<idSessao>/registro.yaml`, `registro.binarypb` ou `record.protobufPath` para edição):
       - Excluir eventual arquivo PDF em `record.pdfPath` se existir em disco;
       - Atualizar `record.status = SubmissionStatus.emProgresso`, `record.epubPath = ''`, `record.pdfPath = ''` e persistir via `salvarSubmissao(record)`.
- **Racional**: Garante que, já ao abrir o aplicativo, qualquer relatório legado cujo `.epub` tenha se perdido apareça honestamente como `EM PROGRESSO` no Histórico, enquanto relatórios que possuam `relatorio.epub` na pasta da sessão tenham seu `epubPath` restaurado automaticamente.

### 2. Localização do EPUB e Abertura / Rebaixamento em `HistoryScreen`
- **Decisão**:
  - Em `HistoryScreen._localizarCaminhoEpub(SubmissionRecord record)`:
    - Verificar a existência física (`File(...).existsSync()`) em:
      1. `record.epubPath` (com fallback em testes de widget onde `epubPath` ou `protobufPath` terminando em `.epub` foi injetado diretamente em memória e não há sessão de edição no disco);
      2. `record.protobufPath` (se terminar com `.epub`);
      3. `p.join(p.dirname(record.protobufPath), 'relatorio.epub')` (quando `record.protobufPath` não for vazio);
      4. `p.join(p.dirname(record.pdfPath), 'relatorio.epub')` e `record.pdfPath.replaceAll(RegExp(r'\.pdf$'), '.epub')` (quando `record.pdfPath` não for vazio).
  - Em `HistoryScreen._abrirRelatorio(SubmissionRecord record, Future<void> Function() loadAndEdit)`:
    - Se `caminhoEpub != null`:
      - Se `record.epubPath != caminhoEpub`, atualizar `record.epubPath = caminhoEpub` no `BancoDadosLocal` (quando disponível);
      - Abrir `VisualizadorRelatorioScreen(caminhoEpub: caminhoEpub, caminhoPdf: caminhoPdf, idSessao: record.idSessao, titulo: ...)`.
    - Se `caminhoEpub == null`:
      - Remover por completo a chamada a `pdfViewerServiceProvider.openPdf`;
      - Excluir eventual arquivo em `record.pdfPath` (se existir em disco), atualizar `record` para `status = SubmissionStatus.emProgresso`, `epubPath = ''`, `pdfPath = ''` no `BancoDadosLocal` (quando disponível) e invocar `await loadAndEdit()` para abrir o `WizardScreen` na sessão.
- **Racional**: Elimina 100% a abertura indesejada do compartilhador/leitor de PDF ao tocar em um item do Histórico e cumpre o fluxo esperado de reabrir no Wizard para edição caso o `.epub` não exista.

## Risks / Trade-offs

- **[Risco] Testes unitários/widget existentes que injetam `SubmissionRecord` sintético em memória sem criar arquivos físicos no disco** → **Mitigação**:
  - Em `_localizarCaminhoEpub`, se `record.epubPath` (ou `record.protobufPath` terminando em `.epub`) estiver preenchido e existir em disco, usa-o; se nenhum arquivo da sessão (`protobufPath` / `pdfPath`) existir no sistema de arquivos (cenário puramente em memória de teste de widget que testa apenas a navegação para `VisualizadorRelatorioScreen` com caminho sintético `.epub`), aceitar o caminho `.epub` informado em `epubPath`/`protobufPath`; já quando a sessão existe em disco sem `.epub` (ou só tem `.pdf` / `registro.yaml`), acionar o rebaixamento para `EM_PROGRESSO` e abrir o `WizardScreen`. Atualizar os testes em `history_screen_test.dart` e `history_update_test.dart` para refletir o novo comportamento.
