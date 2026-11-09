# Proposal

## Why

Atualmente, o caminho do pacote `.epub` gerado pelo `GenerationNotifier` é gravado no campo `SubmissionRecord.protobufPath` (originalmente concebido para o manifesto `registro.binarypb`) e em um caminho aleatório fora da pasta da sessão (`<appDir>/fixalog_report_<timestamp>.epub`). Quando o usuário sai do `WizardScreen` para voltar ao Histórico, o `PopScope` dispara `flushAutoSave() -> saveSession()`, que sobrescreve `record.protobufPath` com `sessoes/<idSessao>/registro.binarypb` e mantém o `record.pdfPath` antigo. Como resultado:
1. Clicar no relatório gerado no Histórico não encontra mais o `.epub` e abre diretamente o PDF antigo no leitor externo;
2. A re-geração de um relatório existente nunca invalida o `record.pdfPath` em cache, fazendo o aplicativo exibir o PDF antigo (pré-redesenho, com dump de chaves do Protobuf) e sem aplicar os dicionários de tradução de protocolos (`assets/protocols/i18n/<locale>/*.yaml`).

## What Changes

- **Separação explícita entre `protobufPath` e `epubPath` no `SubmissionRecord` e SQLite (v3)**:
  - Adicionar o campo dedicado `epubPath` (`epub_path` na tabela `submissoes` do SQLite, com migração automática na versão 3 do banco para mover valores `.epub` legados de `protobuf_path` para `epub_path`).
  - `protobufPath` passa a apontar exclusivamente para `sessoes/<idSessao>/registro.binarypb`, e `epubPath` aponta para `sessoes/<idSessao>/relatorio.epub`.
- **Padronização do caminho do EPUB no `SessionBundleManager`**:
  - Adicionar `getEpubFilePath({required String sessionId})` retornando `sessoes/<sessionId>/relatorio.epub` (alinhado com `BancoDadosLocal.sincronizarSessoesDoDisco` e `SincronizadorNuvemService`).
  - Atualizar `WizardScreen` e `GenerationNotifier` para gerarem o EPUB sempre no caminho padronizado da sessão e removerem eventuais arquivos `.epub` legados fora da pasta da sessão.
- **Proteção no `WizardStateController` (`flushAutoSave` e `saveSession`)**:
  - `flushAutoSave()` só deve persistir a sessão caso `state.possuiAlteracoesPendentes` seja verdadeiro.
  - `saveSession()` deve preservar `existingRecord.epubPath` quando o status permanecer `GERADO` e limpar `pdfPath` (e excluir o PDF em cache) quando o registro voltar para `EM_PROGRESSO`.
- **Invalidação obrigatória do cache de PDF na re-geração do EPUB**:
  - Ao concluir `GenerationNotifier.startGeneration`, excluir do disco qualquer arquivo PDF antigo (`existingRecord.pdfPath` e `sessionManager.getReportFilePath`), gravar `record.pdfPath = ''` e emitir `state.pdfPath = null`, garantindo que o próximo compartilhamento ou visualização de PDF gere um novo documento A4 atualizado.
- **Integração de traduções de protocolos (`i18n`) e fontes Noto Sans via `rootBundle` no PDF Resumido**:
  - Em `VisualizadorRelatorioScreen._executarGeracaoPdfPadrao`, resolver o idioma efetivo (`ResolvedorIdioma`) e carregar os dicionários `assets/protocols/i18n/<locale>/<idProtocolo>.yaml` (para o relatório principal e materiais anexos), repassando `codigoIdioma` e `traducoesProtocolo` para `PdfPrintSummaryService`.
  - Atualizar o carregamento de fontes Noto Sans em `PdfPrintSummaryService` para suportar `rootBundle` em dispositivos móveis com fallback para `File` em testes unitários.

## Capabilities

### New Capabilities

### Modified Capabilities
- `history-tracking`: Separação de `epubPath` e `protobufPath` no `SubmissionRecord`/SQLite, padronização do caminho `sessoes/<idSessao>/relatorio.epub` e abertura consistente do `VisualizadorRelatorioScreen` ao tocar em relatórios gerados no Histórico.
- `pdf-generator`: Invalidação automática do cache `pdfPath` ao editar ou re-gerar o EPUB e aplicação dos dicionários de tradução de protocolos (`i18n`) e fontes Noto Sans na geração sob demanda do PDF Resumido.

## Impact

- `app/lib/core/models/local/submission_record.dart` e `app/test/core/models/local/submission_record_test.dart`
- `app/lib/core/services/banco_dados_local.dart` e `app/test/core/services/banco_dados_local_test.dart`
- `app/lib/core/services/session_bundle_manager.dart` e `app/test/core/services/session_bundle_manager_test.dart`
- `app/lib/core/services/sincronizador_nuvem_service.dart` e `app/test/core/services/sincronizador_nuvem_service_test.dart`
- `app/lib/core/services/pdf_print_summary_service.dart` e `app/test/core/services/pdf_print_summary_service_test.dart`
- `app/lib/features/pdf_generation/providers/generation_provider.dart` e `app/test/features/pdf_generation/providers/generation_provider_test.dart`
- `app/lib/features/pdf_generation/views/visualizador_relatorio_screen.dart` e `app/test/features/pdf_generation/views/visualizador_relatorio_screen_test.dart`
- `app/lib/features/wizard/controllers/wizard_state_controller.dart` e `app/test/features/wizard/controllers/wizard_state_controller_test.dart`
- `app/lib/features/wizard/views/wizard_screen.dart` e `app/test/features/wizard/views/wizard_screen_test.dart`
- `app/lib/features/home/providers/history_provider.dart`, `app/lib/features/home/views/history_screen.dart` e respectivos testes
