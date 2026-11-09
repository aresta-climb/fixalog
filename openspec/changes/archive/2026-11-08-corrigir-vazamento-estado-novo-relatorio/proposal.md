# Proposal

## Why

Ao abrir ou editar um relatório existente no Histórico, sair da tela do Wizard e em seguida iniciar um novo relatório, os campos de entrada do novo protocolo aparecem indevidamente pré-preenchidos com os dados do relatório antigo devido à renderização do estado residual da sessão anterior no primeiro frame do `WizardScreen` e ao reaproveitamento de estado interno dos `TextFormField` sem chave de sessão. Além disso, o botão final `"GERAR RELATÓRIO"` no card de conclusão ainda exibe o ícone legado `Icons.picture_as_pdf`, que não representa mais o pacote pericial canônico em EPUB 3 assinado digitalmente.

## What Changes

- **Inicialização Limpa de Nova Sessão no Wizard sem Vazamento de Estado Anterior**:
  - Garantir que, ao abrir o `WizardScreen` para um novo protocolo (`isEditing: false`), a árvore de passos (`_StepCard`) não seja renderizada com o estado residual da sessão anterior antes da execução de `loadProtocol`, limpando também as chaves de cards (`_cardKeys`) e vinculando os campos de entrada (`TextFormField` e `_CampoTextoMarkdownArea`) a uma `ValueKey` composta pelo `sessionId` e identificador do campo (`${sessionId}_$fullKey`).
  - Garantir que um novo relatório venha sempre com todos os campos vazios (exceto os campos configurados com `preencher_data_atual: true`, que recebem a data corrente), independentemente de o usuário ter aberto ou editado um relatório antigo no Histórico momentos antes.
- **Atualização do Ícone do Botão `"GERAR RELATÓRIO"` no Card de Conclusão**:
  - Substituir o ícone legado `Icons.picture_as_pdf` no botão `"GERAR RELATÓRIO"` do `SummaryConclusionCard` por um ícone semântico de documento/relatório (`Icons.description_outlined`), condizente com a geração do laudo pericial completo em EPUB 3.

## Capabilities

### New Capabilities

### Modified Capabilities
- `unified-wizard-engine`: Garantir isolamento de estado entre sessões sequenciais (novo relatório nunca herda respostas ou estado de `TextFormField` de um relatório aberto anteriormente no Histórico) e atualizar o ícone do botão `"GERAR RELATÓRIO"` no card de conclusão para não exibir o símbolo restrito a PDF.

## Impact

- `app/lib/features/wizard/views/wizard_screen.dart` (bloqueio de renderização de estado residual no 1º frame ao iniciar novo protocolo, `ValueKey` por `sessionId` nos campos de texto/número e substituição de `Icons.picture_as_pdf` por `Icons.description_outlined` no `SummaryConclusionCard`).
- `app/test/features/wizard/views/wizard_screen_test.dart` (testes de comportamento garantindo que abrir um relatório antigo e depois iniciar um novo relatório resulta em campos vazios e validando o novo ícone do botão `"GERAR RELATÓRIO"`).
