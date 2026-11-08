# Spec Delta

## ADDED Requirements

### Requirement: Criação de Cópia de Relatório Existente pelo Histórico
A tela de Histórico DEVE disponibilizar a opção "Criar cópia" no menu de opções (3 pontinhos) de todos os registros (`GERADO` e `EM PROGRESSO`, tanto de Manutenções quanto de Materiais). Ao acioná-la, o sistema DEVE exibir um indicador de progresso enquanto clona os dados e arquivos de mídia para uma nova sessão independente (`EM_PROGRESSO`), aplicando sufixo incremental `(Cópia)` / `(Cópia N)` ao título, atualizando campos de data atual para a data de hoje e abrindo imediatamente o `WizardScreen` na nova sessão.

#### Scenario: Criar primeira cópia de um relatório ou material existente
- **WHEN** o usuário abre o menu de 3 pontinhos de um registro intitulado `"Via do Diedro"` e seleciona `"Criar cópia"`
- **THEN** o sistema exibe um modal de carregamento com indicador giratório, copia todas as respostas, listas e arquivos de mídia (originais e pré-processados) para um novo `sessionId`, define o nome/título da cópia como `"Via do Diedro (Cópia)"`, atualiza campos configurados com `preencher_data_atual` para a data de hoje, salva o novo registro como `EM_PROGRESSO` e abre imediatamente o `WizardScreen` carregado na nova sessão

#### Scenario: Incremento automático do sufixo ao criar múltiplas cópias
- **WHEN** já existe um registro intitulado `"Kit Parabolt Inox (Cópia)"` e o usuário seleciona `"Criar cópia"` a partir de `"Kit Parabolt Inox"` ou de `"Kit Parabolt Inox (Cópia)"`
- **THEN** o sistema nomeia a nova cópia como `"Kit Parabolt Inox (Cópia 2)"` (e `"Kit Parabolt Inox (Cópia 3)"` na próxima, sucessivamente)
