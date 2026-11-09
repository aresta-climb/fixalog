# Tasks

## 1. Isolamento de Estado ao Iniciar Novo Relatório após Abrir/Editar Relatório Antigo

- [x] 1.1 Escrever teste de widget (Red) em `app/test/features/wizard/views/wizard_screen_test.dart` simulando a abertura/edição de um relatório antigo com respostas preenchidas (`isEditing: true`), saída da tela e posterior abertura de um novo relatório (`isEditing: false`), verificando que todos os campos de texto e número iniciam vazios sem herdar valores da sessão anterior
- [x] 1.2 Implementar (Green/Refactor) em `app/lib/features/wizard/views/wizard_screen.dart` o controle `_protocoloInicializado` em `_WizardScreenState` (evitando renderizar `_StepCard`s com o estado residual da sessão anterior no 1º frame) e adicionar `ValueKey('input_${sessionId}_$fullKey')` nos campos `TextFormField` e `_CampoTextoMarkdownArea` em `_CampoSimplesContent._buildInput`, verificando que o teste `1.1` passa

## 2. Atualização do Ícone do Botão `"GERAR RELATÓRIO"` no Card de Conclusão

- [x] 2.1 Escrever/atualizar teste de widget (Red) em `app/test/features/wizard/views/wizard_screen_test.dart` verificando que o botão `"GERAR RELATÓRIO"` no `SummaryConclusionCard` exibe o ícone `Icons.description_outlined` e não exibe `Icons.picture_as_pdf`
- [x] 2.2 Substituir (Green/Refactor) o ícone `Icons.picture_as_pdf` por `Icons.description_outlined` no botão `"GERAR RELATÓRIO"` do `SummaryConclusionCard` em `app/lib/features/wizard/views/wizard_screen.dart` e executar `flutter test test/features/wizard/views/wizard_screen_test.dart` e `flutter test test/test_structure_mirror_test.dart` garantindo 100% de aprovação
