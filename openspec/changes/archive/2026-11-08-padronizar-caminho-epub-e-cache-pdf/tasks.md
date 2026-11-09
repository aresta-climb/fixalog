# Tasks

## 1. Modelo `SubmissionRecord`, SQLite v3 (`epub_path`) e `SessionBundleManager`

- [x] 1.1 Atualizar os testes em `app/test/core/models/local/submission_record_test.dart`, `app/test/core/services/banco_dados_local_test.dart`, `app/test/core/services/session_bundle_manager_test.dart` e `app/test/core/services/sincronizador_nuvem_service_test.dart` validando o campo `epubPath` (`epub_path`), a migração do SQLite para v3, `getEpubFilePath(sessionId)` apontando para `sessoes/<sessionId>/relatorio.epub`, `obterSubmissaoPorEpubPath` e o uso de `epubPath` na sincronização em nuvem (Red).
- [x] 1.2 Implementar `epubPath` em `app/lib/core/models/local/submission_record.dart`, a coluna `epub_path` e migração v3 em `app/lib/core/services/banco_dados_local.dart`, `getEpubFilePath` em `app/lib/core/services/session_bundle_manager.dart` e atualizar `app/lib/core/services/sincronizador_nuvem_service.dart`, garantindo 100% de aprovação e cobertura nos testes do grupo 1 (Green/Refactor).

## 2. Ciclo de Vida do EPUB e Invalidação do Cache de PDF (`WizardStateController`, `GenerationNotifier` e `HistoryScreen`)

- [x] 2.1 Atualizar os testes em `app/test/features/wizard/controllers/wizard_state_controller_test.dart`, `app/test/features/wizard/views/wizard_screen_test.dart`, `app/test/features/pdf_generation/providers/generation_provider_test.dart`, `app/test/features/home/providers/history_provider_test.dart` e `app/test/features/home/views/history_screen_test.dart` validando que: (a) `flushAutoSave` não sobrescreve sessão sem alterações pendentes, (b) `saveSession` preserva `epubPath` e invalida `pdfPath` ao voltar para `EM_PROGRESSO`, (c) `GenerationNotifier.startGeneration` grava o EPUB em `sessoes/<sid>/relatorio.epub` (`record.epubPath`), preserva `record.protobufPath` e invalida/exclui o PDF antigo, e (d) `HistoryScreen` abre sempre `VisualizadorRelatorioScreen` a partir de `record.epubPath` (Red).
- [x] 2.2 Implementar as alterações em `app/lib/features/wizard/controllers/wizard_state_controller.dart`, `app/lib/features/wizard/views/wizard_screen.dart`, `app/lib/features/pdf_generation/providers/generation_provider.dart`, `app/lib/features/home/providers/history_provider.dart` e `app/lib/features/home/views/history_screen.dart`, garantindo 100% de aprovação e cobertura nos testes do grupo 2 (Green/Refactor).

## 3. Traduções de Protocolos (`i18n`) e Fontes Noto Sans no PDF Resumido (`PdfPrintSummaryService` e `VisualizadorRelatorioScreen`)

- [x] 3.1 Atualizar os testes em `app/test/core/services/pdf_print_summary_service_test.dart` e `app/test/features/pdf_generation/views/visualizador_relatorio_screen_test.dart` validando o carregamento de fontes Noto Sans via `rootBundle` (com fallback para arquivo), a aplicação de dicionários `assets/protocols/i18n/<locale>/<id>.yaml` tanto no protocolo principal quanto nos materiais anexos do PDF Resumido e a resolução da submissão por `epubPath` (Red).
- [x] 3.2 Implementar o pré-carregamento assíncrono de fontes e suporte a `traducoesProtocolo` por anexo em `app/lib/core/services/pdf_print_summary_service.dart` e a resolução de idioma/traduções de protocolo em `app/lib/features/pdf_generation/views/visualizador_relatorio_screen.dart`, garantindo 100% de aprovação e cobertura nos testes do grupo 3 (Green/Refactor).

## 4. Verificação Integrada de Cobertura e Análise Estática

- [x] 4.1 Executar `flutter analyze`, `flutter test test/architecture/test_structure_mirror_test.dart` e a suíte de testes com `--coverage` sobre todos os módulos tocados, garantindo 100% de cobertura comportamental e zero avisos do analisador.
