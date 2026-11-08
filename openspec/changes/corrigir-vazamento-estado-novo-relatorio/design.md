# Design

## Context

Conforme detalhado em `proposal.md` e `specs/unified-wizard-engine/spec.md`, precisamos corrigir dois pontos na camada de interface do Wizard (`app/lib/features/wizard/views/wizard_screen.dart`):
1. O vazamento de estado de campos de texto (`TextFormField`) quando o usuário abre/edita um relatório antigo no Histórico, fecha a tela e depois abre um novo relatório (`WizardScreen(initialYaml: ..., isEditing: false)`).
2. O ícone legado `Icons.picture_as_pdf` exibido no botão `"GERAR RELATÓRIO"` do `SummaryConclusionCard`.

## Goals / Non-Goals

**Goals:**
- Impedir que o 1º frame do `WizardScreen` (quando `isEditing: false`) monte a árvore de `_StepCard`s utilizando o `WizardState` residual da sessão anterior antes da execução de `loadProtocol`.
- Garantir que os widgets de entrada de texto (`TextFormField` de `TEXT`, `DATE`, `NUMBER` e `_CampoTextoMarkdownArea` de `TEXT_AREA`) em `_CampoSimplesContent` recebam uma `ValueKey` composta pelo `sessionId` e pela chave completa do campo (`${sessionId}_$fullKey`), impedindo que o Flutter reaproveite o `FormFieldState` entre sessões distintas.
- Atualizar o ícone do botão `"GERAR RELATÓRIO"` em `SummaryConclusionCard` de `Icons.picture_as_pdf` para `Icons.description_outlined`.

**Non-Goals:**
- Alterar o contrato de persistência de sessões (`SessionBundleManager` ou banco local) ou o fluxo de edição (`isEditing: true`), que já carrega a sessão antes da navegação.

## Decisions

### 1. Controle de Inicialização no `_WizardScreenState`
- **Decisão**: Introduzir um estado booleano `_protocoloInicializado` em `_WizardScreenState`, inicializado como `widget.isEditing` no `initState()`.
  - Quando `!widget.isEditing`, o callback de `addPostFrameCallback` limpa `_cardKeys.clear()`, chama `ref.read(wizardControllerProvider.notifier).loadProtocol(...)` e, se `mounted`, marca `setState(() => _protocoloInicializado = true)`.
  - Em `build(BuildContext context)`, exibir a tela de carregamento (`CircularProgressIndicator`) enquanto `!_protocoloInicializado || state.protocol == null`.
- **Racional**: No Riverpod, mutações de provedores não devem ocorrer sincronamente durante `initState` ou `build`. Ao aguardar `_protocoloInicializado == true` antes de construir os `_StepCard`s, evitamos completamente que o Frame 1 monte os cards e os `TextFormField`s com os dados da sessão antiga que ainda estavam no `wizardControllerProvider`.
- **Alternativas consideradas**:
  - Converter `wizardControllerProvider` para `.autoDispose`: Descartado porque diversos fluxos e testes leem o estado do controlador ou disparam `flushAutoSave` durante o pop da rota; manter o controle explícito de inicialização no `WizardScreen` combinado com `ValueKey` por `sessionId` resolve o problema sem quebrar contratos existentes.

### 2. `ValueKey` Vinculada ao `sessionId` nos Campos de Entrada
- **Decisão**: Em `_CampoSimplesContent._buildInput`, obter o `sessionId` atual do `wizardControllerProvider` e a chave completa do campo (`final fullKey = listItemId != null ? '${conteudoId}__$listItemId' : conteudoId`) e atribuir `key: ValueKey('input_${sessionId}_$fullKey')` aos widgets `_CampoTextoMarkdownArea` e `TextFormField` (`TEXT`, `DATE` e `NUMBER`).
- **Racional**: No Flutter, `TextFormField(initialValue: ...)` só lê `initialValue` uma única vez dentro de `FormFieldState.initState()`. Vincular a `Key` do widget ao `sessionId` e ao `fullKey` garante por construção que qualquer troca de sessão crie um novo `FormFieldState` limpo.

### 3. Ícone do Botão `"GERAR RELATÓRIO"` no `SummaryConclusionCard`
- **Decisão**: Substituir `icon: const Icon(Icons.picture_as_pdf)` por `icon: const Icon(Icons.description_outlined)` no `ElevatedButton.icon` do `SummaryConclusionCard`.
- **Racional**: O relatório principal gerado pelo Fixalog é um pacote pericial EPUB 3 assinado digitalmente (com resumo em PDF apenas como opção secundária de compartilhamento/impressão). `Icons.description_outlined` representa semanticamente um laudo/relatório técnico sem induzir o usuário a pensar que o artefato primário é apenas um PDF.

## Risks / Trade-offs

- **[Risk] Testes de widget existentes aguardarem apenas um `pump()` sem `pumpAndSettle()`** → **Mitigação**: Os testes de `WizardScreen` já utilizam `pumpAndSettle()` após `pumpWidget` (pois `loadProtocol` já rodava em `addPostFrameCallback`), portanto aguardar `_protocoloInicializado` no `addPostFrameCallback` mantém total compatibilidade com a suíte existente.
