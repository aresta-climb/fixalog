# Tasks

## 1. Reconciliação de Registros Existentes no `BancoDadosLocal`

- [x] 1.1 Adicionar testes comportamentais em `app/test/core/services/banco_dados_local_test.dart` verificando que `sincronizarSessoesDoDisco`: (a) preenche `epubPath` quando o registro já existe no SQLite com `epubPath` vazio mas `sessoes/<idSessao>/relatorio.epub` existe em disco, e (b) rebaixa para `EM_PROGRESSO` (limpando `epubPath` e `pdfPath` e removendo o PDF órfão do disco) registros `GERADO` cujo arquivo `.epub` não existe no disco (Red).
- [x] 1.2 Implementar a reconciliação dos registros existentes em `BancoDadosLocal.sincronizarSessoesDoDisco` (`app/lib/core/services/banco_dados_local.dart`) e verificar aprovação integral e 100% de cobertura em `banco_dados_local_test.dart` (Green/Refactor).

## 2. Remoção do Fallback de PDF e Reabertura no Wizard na `HistoryScreen`

- [x] 2.1 Atualizar os testes em `app/test/features/home/views/history_screen_test.dart` (e `app/integration_test/history_update_test.dart`) para validar que: (a) tocar em um registro `GERADO` com `sessoes/<idSessao>/relatorio.epub` no diretório da sessão (mesmo com `epubPath` vazio e `pdfPath` preenchido) abre o `VisualizadorRelatorioScreen` e atualiza `epubPath`, e (b) tocar em um registro `GERADO` sem arquivo `.epub` em disco rebaixa o status para `EM_PROGRESSO` no SQLite, remove eventual PDF órfão e abre o `WizardScreen` para edição em vez de chamar `PdfViewerService` (Red).
- [x] 2.2 Atualizar `app/lib/features/home/views/history_screen.dart` para remover o fallback `pdfViewerServiceProvider.openPdf`, resolver `relatorio.epub` no diretório da sessão e rebaixar/abrir no `WizardScreen` registros sem `.epub` em disco, garantindo 100% de cobertura em `history_screen_test.dart` (Green/Refactor).

## 3. Verificação Integrada de Qualidade e Cobertura

- [x] 3.1 Executar `flutter analyze`, `flutter test test/architecture/test_structure_mirror_test.dart` e `flutter test --coverage` nos módulos alterados, confirmando 100% de cobertura comportamental e zero avisos.
