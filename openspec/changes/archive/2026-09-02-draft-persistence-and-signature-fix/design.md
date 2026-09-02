## Context

O aplicativo FixaLog opera offline-first para documentação técnica de proteções fixas de escalada. O preenchimento ocorre no `WizardScreen` orquestrado pelo `WizardStateController`, e os registros salvos são gerenciados pelo `SessionBundleManager` (arquivos físicos na pasta `/sessoes/<sessionId>/`) e indexados pelo banco local `Isar` (`SubmissionRecord`).

Atualmente:
1. O widget `SignatureModal` dentro de `Dialog` não recebe restrições explícitas de largura, gerando exceção de hit test em render box sem tamanho (`Cannot hit test a render box with no size`).
2. O `WizardStateController` mantém todo o preenchimento em memória volátil, salvando no disco e no Isar apenas na conclusão do PDF. Saídas acidentais descartam todo o trabalho.
3. Não há diferenciação de status entre rascunho em progresso e relatório gerado, e re-edições não salvavam alterações parciais no histórico.

Esta proposta segue rigorosamente os princípios de engenharia definidos no `PRINCIPIOS.md`.

## Alinhamento com PRINCIPIOS.md

- **I. Tudo em Português**: Toda a documentação, comentários, identificadores, nomes de variáveis, métodos e mensagens de teste são estritamente em português brasileiro (ex: `status`, `dataInclusao`, `nomeProtocolo`, `STATUS_EM_PROGRESSO`, `STATUS_GERADO`, `salvarRascunhoContinuo`).
- **II. Library-First**: Componentes e controladores são modulares, autossuficientes e desacoplados. O `WizardStateController` gerencia o estado e persistência sem acoplamento direto com a árvore de widgets, e o `SessionBundleManager` provê I/O isolado.
- **III. 100% de unit test coverage**: Todo o código introduzido ou modificado possui 100% de cobertura de testes unitários e de widgets.
- **IV. Imperativo do Teste em Primeiro Lugar (TDD)**: O ciclo Red-Green-Refactor é aplicado obrigatoriamente. Os testes falham inicialmente antes do código de produção ser implementado.
- **V. Testes de Integração em Primeiro Lugar**: Testes de fronteira e fluxo ponta a ponta (como preenchimento parcial -> saída da tela -> validação no histórico -> retomada do wizard) são estruturados antes do detalhamento unitário profundo.
- **VI. Simplicidade e Anti-Abstração**: Sem metaprogramação ou camadas complexas de indireção. O auto-save reutiliza o método direto de escrita binária Protobuf em disco e operações nativas do Isar.

## Goals / Non-Goals

**Goals:**
- Eliminar o crash do `SignatureModal` garantindo dimensões finitas e delimitadas através de `LayoutBuilder`.
- Implementar persistência contínua e reativa de rascunhos no disco (`registro.binarypb`) e no Isar (`SubmissionRecord`) durante todo o preenchimento.
- Introduzir enum/campo de status (`status: 'EM_PROGRESSO' | 'GERADO'`) em `SubmissionRecord` com suporte a migração retroativa.
- Fazer com que qualquer alteração em um relatório previamente gerado transicione seu status de volta para `EM_PROGRESSO`.
- Atualizar a interface do `HistoryScreen` para exibir badges visuais claros e abrir a tela adequada ao tocar (Wizard para `EM_PROGRESSO`, PDF para `GERADO`).
- Garantir a gravação de dados pendentes ao sair da tela via `PopScope`.

**Non-Goals:**
- Criação de ramificações/múltiplas versões clonadas do mesmo relatório (o modelo mantém o princípio de Sessão Única e Registro Canônico).
- Sincronização em nuvem de rascunhos incompletos (o escopo é estritamente armazenamento local e offline-first).

## Decisions

### 1. Dimensionamento do Modal de Assinatura via `LayoutBuilder`
- **Decisão**: Utilizar `LayoutBuilder` dentro de `SignatureModal` para repassar `constraints.maxWidth` explicitamente para o widget `Signature(controller: _controller, width: constraints.maxWidth, height: 200)`.
- **Alternativas consideradas**:
  - *Largura fixa em pixels (ex: 300)*: Não se adapta bem a diferentes tamanhos de tela e orientações.
  - *MediaQuery*: Não considera os paddings internos reais do `Dialog`.
- **Justificativa**: `LayoutBuilder` obtém com precisão a largura calculada após a aplicação dos insets do diálogo, evitando `Size.zero` ou dimensões infinitas.

### 2. Auto-Save Reativo no `WizardStateController`
- **Decisão**: Disparar a rotina de salvamento (`saveSession`) assincronamente a cada mutação de estado.
  - Operações estruturais (fotos, vídeos, assinaturas, itens de lista, seleção de ramo, referências): salvamento imediato.
  - Entradas de texto: debounce de 400ms com timer gerenciado no controller para evitar excesso de I/O em digitações rápidas.
  - Ao fechar a tela ou navegar (`PopScope` e `dispose`): flush imediato de qualquer salvamento pendente.
- **Alternativas consideradas**:
  - *Salvar apenas ao avançar de card*: Risco de perder o card atual se o aplicativo for fechado pelo sistema operacional.
- **Justificativa**: Serializar Protobuf binário (`writeToBuffer()`) de 2KB leva menos de 2ms no dispositivo móvel, tornando o auto-save imperceptível e altamente seguro.

### 3. Modelo de Status em `SubmissionRecord`
- **Decisão**: Adicionar o campo `String status = 'EM_PROGRESSO'` no `SubmissionRecord` (constantes `STATUS_EM_PROGRESSO = 'EM_PROGRESSO'` e `STATUS_GERADO = 'GERADO'`).
  - Quando um novo protocolo é iniciado: `status = 'EM_PROGRESSO'`, `pdfPath = ''`.
  - Quando a geração do PDF conclui com sucesso no `GenerationNotifier`: `status = 'GERADO'`, `pdfPath = <caminho>`.
  - Tratamento retroativo: caso `status` esteja vazio, se `pdfPath.isNotEmpty` considera `'GERADO'`, caso contrário `'EM_PROGRESSO'`.
- **Alternativas consideradas**:
  - *Apenas verificar `pdfPath.isEmpty`*: Não atende ao caso em que um relatório já gerado é reaberto e modificado, onde o arquivo antigo ainda existe no disco mas o registro atualizado está em progresso.

### 4. Transição de Estado em Relatórios Re-editados
- **Decisão**: Quando o usuário carrega uma sessão existente (`loadSession`) e realiza qualquer alteração (respostas, mídias, etc.), o controller atualiza o `SubmissionRecord` para `status = 'EM_PROGRESSO'`.
- **Justificativa**: O relatório modificado não reflete mais fielmente o PDF físico antigo. O card no histórico passa a exibir `EM_PROGRESSO` e tocar nele retoma o preenchimento no Wizard até nova geração de PDF.

### 5. Navegação e Ações no `HistoryScreen`
- **Decisão**: 
  - Toque no card:
    - Se `status == 'EM_PROGRESSO'`: invoca `loadSession` e abre `WizardScreen(initialYaml: yaml, isEditing: true)`.
    - Se `status == 'GERADO'`: abre o PDF diretamente via `PdfViewerService`.
  - Menu de contexto (⋮):
    - `EM_PROGRESSO`: Opções "Continuar preenchimento" e "Excluir".
    - `GERADO`: Opções "Editar", "Abrir PDF" e "Excluir".
  - Badges visuais:
    - `EM_PROGRESSO`: Badge com fundo âmbar/laranja e texto `EM PROGRESSO`.
    - `GERADO`: Badge com fundo verde/laranja e texto `GERADO`.

## Risks / Trade-offs

- **[Risco: I/O assíncrono durante saída abrupta do app]** → **Mitigação**: Uso de `PopScope` no `WizardScreen` aguardando a finalização de qualquer `saveSession` pendente antes de permitir o pop do navigator.
- **[Risco: Conflito de Schema no Isar]** → **Mitigação**: Campo `status` com valor padrão `'EM_PROGRESSO'`, re-gerando os arquivos com `build_runner` (`submission_record.g.dart`) e incluindo lógica de fallback em tempo de execução.
