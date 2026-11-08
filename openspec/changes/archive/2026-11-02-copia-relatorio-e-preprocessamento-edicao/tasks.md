# Tasks

## 1. Cópia de Arquivos de Mídia entre Sessões no `SessionBundleManager`

- [x] 1.1 Seguindo TDD (Red-Green-Refactor), atualizar `app/test/core/services/session_bundle_manager_test.dart` e `app/lib/core/services/session_bundle_manager.dart` para implementar `copiarArquivosMidiaSessao({required String idSessaoOrigem, required String idSessaoDestino})`, copiando mídias originais (`_original.*`) e pré-processadas (`.webp`, `_thumb.jpg`, `.mp4`, `_poster.jpg`) enquanto ignora `registro.binarypb`, `registro.json`, `*.tmp` e relatórios finais (`fixalog_*.epub`/`fixalog_*.pdf`), validando com `flutter test test/core/services/session_bundle_manager_test.dart`.

## 2. Pré-processamento em 2º Plano no `loadSession` e Duplicação de Sessão no `WizardStateController`

- [x] 2.1 Seguindo TDD (Red-Green-Refactor), atualizar `app/test/features/wizard/controllers/wizard_state_controller_test.dart` e `app/lib/features/wizard/controllers/wizard_state_controller.dart` para que `loadSession` verifique todas as mídias referenciadas na sessão carregada (fotos, vídeos e documentos PDF) e dispare em segundo plano (`unawaited`) o pré-processamento das mídias pendentes via `MediaCompressorService`, validando com `flutter test test/features/wizard/controllers/wizard_state_controller_test.dart`.
- [x] 2.2 Seguindo TDD (Red-Green-Refactor), atualizar `app/test/features/wizard/controllers/wizard_state_controller_test.dart` e `app/lib/features/wizard/controllers/wizard_state_controller.dart` para implementar `duplicarSessao(String idSessaoOrigem)` (clonando o bundle e as respostas para um novo `sessionId`, aplicando o sufixo incremental `(Cópia)`, `(Cópia 2)`, `(Cópia 3)`... sobre o nome base sem duplicar sufixos via `BancoDadosLocal`, atualizando campos com `preencher_data_atual: true` para a data de hoje e salvando o novo registro no SQLite como `EM_PROGRESSO`), validando com `flutter test test/features/wizard/controllers/wizard_state_controller_test.dart`.

## 3. Opção "Criar cópia" e Modal de Carregamento na `HistoryScreen`

- [x] 3.1 Seguindo TDD (Red-Green-Refactor), atualizar `app/test/features/home/views/history_screen_test.dart` e `app/lib/features/home/views/history_screen.dart` para exibir a opção `"Criar cópia"` no menu de 3 pontinhos (`PopupMenuButton`) de todos os registros (`GERADO` e `EM PROGRESSO`, tanto em `MANUTENÇÕES` quanto em `MATERIAIS`), exibir o diálogo de progresso giratório durante a cópia em segundo plano e abrir imediatamente o `WizardScreen` (`isEditing: true`) na nova sessão, validando com `flutter test test/features/home/views/history_screen_test.dart` e `flutter test`.
