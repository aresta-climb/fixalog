# Proposal

## Why

Atualmente, ao clicar em um relatório já gerado na tela de Histórico (`HistoryScreen`), caso `record.epubPath` esteja vazio no SQLite (como ocorre em registros criados antes da introdução da coluna `epub_path`, onde `saveSession()` sobrescreveu `protobuf_path` com `registro.binarypb`/`registro.yaml`), o método `_localizarCaminhoEpub` não procura o pacote canônico `sessoes/<idSessao>/relatorio.epub` (procurando apenas um inexistente `fixalog_<idSessao>.epub`) e cai em um fallback que aciona `PdfViewerService.openPdf(caminhoPdf)` via `OpenFilex.open`. Isso faz o sistema operacional abrir a interface nativa de compartilhamento/abertura externa do PDF em vez do nosso visualizador `VisualizadorRelatorioScreen` (com o EPUB renderizado e a barra inferior de compartilhamento), ou manter como `GERADO` relatórios cujo arquivo `.epub` assinado não existe mais no disco.

## What Changes

- **Remoção do fallback de abertura direta de PDF na `HistoryScreen`**:
  - Eliminar a chamada a `PdfViewerService.openPdf` ao tocar em um relatório no Histórico.
  - Sempre que o arquivo `.epub` existir em disco, abrir o `VisualizadorRelatorioScreen` (que exibe o EPUB 3 no WebView e disponibiliza a barra inferior para compartilhar EPUB, PDF resumido ou link web).
- **Resolução completa do caminho `sessoes/<idSessao>/relatorio.epub`**:
  - Atualizar a localização do EPUB na `HistoryScreen` e no `BancoDadosLocal` para verificar a existência real em disco do arquivo em: (1) `record.epubPath`, (2) `record.protobufPath` (se terminar com `.epub`), (3) `sessoes/<idSessao>/relatorio.epub` (a partir do diretório da sessão / `protobufPath` / `pdfPath`), e (4) irmão `.epub` do `pdfPath`, persistindo `record.epubPath` no SQLite quando encontrado.
- **Reconciliação de status para `EM_PROGRESSO` quando o `.epub` não existir**:
  - Em `BancoDadosLocal.sincronizarSessoesDoDisco`, reconciliar também os registros já existentes na tabela `submissoes`: se o `relatorio.epub` existir na pasta da sessão e `epubPath` estiver vazio, preencher `epubPath`; se o registro estiver com `status == GERADO` mas nenhum arquivo `.epub` existir em disco, rebaixar o registro para `EM_PROGRESSO`, limpar `epubPath` e `pdfPath` e remover eventual PDF órfão do disco.
  - Na `HistoryScreen`, caso o usuário toque em um registro listado como `GERADO` cujo arquivo `.epub` não seja encontrado em disco, rebaixar imediatamente o registro para `EM_PROGRESSO` no banco SQLite e abrir a sessão no `WizardScreen` (`loadAndEdit`) para revisão e nova geração/assinatura do relatório.

## Capabilities

### New Capabilities

### Modified Capabilities
- `history-tracking`: Remoção do fallback de abertura externa de PDF no Histórico, resolução do caminho canônico `sessoes/<id_sessao>/relatorio.epub` e rebaixamento automático para `EM_PROGRESSO` (com abertura no `WizardScreen` para edição) quando um registro `GERADO` não possuir arquivo `.epub` assinado em disco.

## Impact

- `app/lib/core/services/banco_dados_local.dart` e `app/test/core/services/banco_dados_local_test.dart`
- `app/lib/features/home/views/history_screen.dart` e `app/test/features/home/views/history_screen_test.dart`
- `app/integration_test/history_update_test.dart`
