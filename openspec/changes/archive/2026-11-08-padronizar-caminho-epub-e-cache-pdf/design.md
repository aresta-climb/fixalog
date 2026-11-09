# Design

## Context

Veja `proposal.md` para a motivação completa. Atualmente:
1. `SubmissionRecord` armazena o caminho do `.epub` na coluna `protobuf_path` (`protobufPath`), que é sobrescrita por `WizardStateController.saveSession()` com `sessoes/<idSessao>/registro.binarypb` quando o usuário sai do `WizardScreen` (`PopScope -> flushAutoSave()`).
2. `WizardScreen` passa `<appDir>/fixalog_report_<timestamp>.pdf` para `GenerationNotifier.startGeneration`, gravando o `.epub` fora da pasta da sessão (`sessoes/<idSessao>/`), enquanto `BancoDadosLocal.sincronizarSessoesDoDisco` e `SincronizadorNuvemService` esperam `sessoes/<idSessao>/relatorio.epub`.
3. `GenerationNotifier.startGeneration` preserva `existingRecord.pdfPath` ao re-gerar um relatório existente, mantendo em cache o PDF antigo.
4. `VisualizadorRelatorioScreen._executarGeracaoPdfPadrao` invoca `PdfPrintSummaryService.exportarPdfResumido` sem repassar o `codigoIdioma` ativo nem carregar os dicionários `assets/protocols/i18n/<locale>/<id>.yaml`, e `PdfPrintSummaryService.carregarFonteNotoSans` lê apenas via `File('assets/fonts/...')` (que funciona nos testes desktop, mas falha no bundle de assets mobile se não houver carregamento via `rootBundle`).

## Goals / Non-Goals

**Goals:**
- Separar `protobufPath` (`registro.binarypb`) e `epubPath` (`relatorio.epub`) em `SubmissionRecord` e na tabela `submissoes` do SQLite (versão 3 com migração transparente).
- Padronizar o caminho do pacote EPUB dentro do diretório da sessão (`sessoes/<idSessao>/relatorio.epub`) via `SessionBundleManager.getEpubFilePath(sessionId: ...)`.
- Impedir que `flushAutoSave()` / `saveSession()` apague o `epubPath` ou grave desnecessariamente quando não houver alterações pendentes.
- Invalidar e remover do disco qualquer PDF em cache (`pdfPath`) ao editar uma sessão ou re-gerar seu EPUB.
- Garantir que a geração sob demanda do PDF Resumido carregue os dicionários `i18n` dos protocolos (principal e materiais anexos) e as fontes Noto Sans via `rootBundle` (com fallback para `File` em testes).

**Non-Goals:**
- Alterar o formato binário `registro.binarypb` ou a assinatura `META-INF/signatures.xml`.

## Decisions

### 1. Coluna `epub_path` no SQLite (v3) e Padronização no `SessionBundleManager`
- **Decisão**:
  - Adicionar `String epubPath = '';` em `SubmissionRecord` mapeado para a coluna `epub_path TEXT NOT NULL DEFAULT ''` na tabela `submissoes`.
  - Incrementar a versão do SQLite em `BancoDadosLocal` de `2` para `3`. Em `_atualizarEsquema` (quando `oldVersion < 3`), executar:
    1. `ALTER TABLE submissoes ADD COLUMN epub_path TEXT NOT NULL DEFAULT ''`
    2. Migrar registros onde `protobuf_path LIKE '%.epub'`: copiar `protobuf_path` para `epub_path`.
  - Adicionar `Future<String> getEpubFilePath({required String sessionId})` em `SessionBundleManager`, retornando `p.join(dir.path, 'relatorio.epub')`.
  - Adicionar `Future<SubmissionRecord?> obterSubmissaoPorEpubPath(String epubPath)` em `BancoDadosLocal` (mantendo `obterSubmissaoPorProtobufPath` compatível).
- **Racional**: Elimina a ambiguidade semântica entre o manifesto Protobuf editável e o pacote EPUB assinado, mantendo todos os artefatos da sessão encapsulados em `sessoes/<idSessao>/`.

### 2. Ciclo de Vida de `epubPath` e `pdfPath` no `WizardStateController` e `GenerationNotifier`
- **Decisão**:
  - Em `WizardStateController.flushAutoSave()`: só chamar `saveSession()` se `state.possuiAlteracoesPendentes` for `true`.
  - Em `WizardStateController.saveSession()`:
    - `record.protobufPath = p.join(sessionDir.path, 'registro.binarypb')`
    - `record.epubPath = existingRecord?.epubPath ?? ''`
    - Se `targetStatus == SubmissionStatus.emProgresso`, limpar `record.pdfPath = ''` e excluir o arquivo PDF antigo se existir em disco.
  - Em `GenerationNotifier.startGeneration()`:
    - Quando `sessionId` for informado, gravar o EPUB no caminho canônico `await _sessionManager.getEpubFilePath(sessionId: sid)` (e remover eventual `.epub` legado de `existingRecord.epubPath` ou `existingRecord.protobufPath` caso estivesse em outro caminho).
    - Invalidar sempre o PDF em cache: se `existingRecord?.pdfPath` existir em disco (ou `await _sessionManager.getReportFilePath(sessionId: sid)` existir), deletar o arquivo `.pdf`, gravar `record.pdfPath = ''` e emitir `state.pdfPath = null`.
- **Racional**: Garante que re-gerar um relatório sempre produza um novo PDF atualizado na próxima solicitação e que sair do Wizard nunca perca a referência ao EPUB.

### 3. Localização de Protocolos (`i18n`) e Fontes Noto Sans Assíncronas no PDF Resumido
- **Decisão**:
  - Em `PdfPrintSummaryService`, adicionar suporte a carregamento de fontes via `rootBundle.load('assets/fonts/$nomeArquivo')` antes do fallback `File('assets/fonts/$nomeArquivo')`, pré-carregando as fontes necessárias em `gerarPdfResumidoBytes` antes de construir o `pw.ThemeData`.
  - Em `VisualizadorRelatorioScreen._executarGeracaoPdfPadrao`, obter o idioma efetivo (`ResolvedorIdioma`) e carregar os mapas YAML de tradução (`assets/protocols/i18n/<locale>/<idProtocolo>.yaml`) tanto para o `registro` principal quanto para cada `RelatorioMaterialAnexo`, passando `codigoIdioma` e `traducoesProtocolo` para `pdfService.exportarPdfResumido`.
- **Racional**: Alinha a renderização do PDF Resumido com a do EPUB 3 tanto em testes unitários quanto em dispositivos Android/iOS reais.

## Risks / Trade-offs

- **[Risco] Relatórios antigos no dispositivo do usuário ainda com `.epub` salvo em `<appDir>/fixalog_report_<ts>.epub` ou com `protobufPath` já sobrescrito para `registro.binarypb`** → **Mitigação**:
  - Na migração v3 do SQLite e em `HistoryScreen._localizarCaminhoEpub`, verificar em ordem: (1) `record.epubPath`, (2) `record.protobufPath` se terminar com `.epub`, e (3) `sessoes/<record.idSessao>/relatorio.epub`.
  - Ao re-gerar no `GenerationNotifier`, o novo EPUB passa a ser salvo em `sessoes/<idSessao>/relatorio.epub` e registrado em `record.epubPath`, limpando o PDF antigo.
