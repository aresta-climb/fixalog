## Why

Durante o uso do FixaLog em campo, dois problemas críticos prejudicam a experiência do usuário:
1. **Crash ao abrir assinatura digital**: Ao tocar no campo de assinatura do mantenedor, a aplicação quebra com a exceção `Cannot hit test a render box with no size`, impossibilitando a coleta de assinaturas digitais nos relatórios.
2. **Perda de relatórios em andamento e falta de rastreamento de rascunhos**: Se o usuário sai da tela do wizard ou fecha o aplicativo durante o preenchimento, todas as respostas são perdidas porque a persistência só ocorria ao final da geração do PDF. Além disso, ao editar um relatório já gerado, as alterações não eram salvas como rascunho em progresso no histórico nem invalidavam o status do relatório até a re-geração.

Esta proposta resolve ambos os problemas seguindo rigorosamente os 5 princípios de engenharia definidos no `PRINCIPIOS.md` (Tudo em Português, Library-First, 100% Cobertura de Testes Unitários, TDD / Test-First, Testes de Integração em Primeiro Lugar e Simplicidade / Anti-Abstração).

## What Changes

- **Correção do Modal de Assinatura**: Envolve o widget `Signature` em `LayoutBuilder` com restrições de largura explícitas no `SignatureModal` para evitar render boxes sem tamanho durante o hit test de toque.
- **Auto-Save Reativo Contínuo no Wizard**: O `WizardStateController` passa a persistir automaticamente no disco (`registro.binarypb` no Session Bundle) e atualizar a entrada correspondente no banco local `Isar` (`SubmissionRecord`) a cada alteração de campo, mídia capturada, adição de item ou escolha de ramo (com debounce para digitação de texto).
- **Garantia de Flush ao Sair**: Uso de `PopScope` no `WizardScreen` para garantir que qualquer estado pendente seja gravado antes de sair da tela.
- **Ciclo de Vida e Status de Relatórios**: 
  - Adiciona campo de rastreamento de status em `SubmissionRecord` (`status: 'EM_PROGRESSO' | 'GERADO'`).
  - Relatórios em preenchimento aparecem no Histórico com tag e status `EM_PROGRESSO`.
  - Ao concluir a geração do PDF, o status passa para `GERADO`.
  - Ao editar um relatório já gerado, qualquer nova alteração transiciona imediatamente o status de volta para `EM_PROGRESSO` (o PDF anterior deixa de ser acessado como versão atual até ser re-gerado).
- **Interação Contextual no Histórico**:
  - Tocar em um card com status `EM_PROGRESSO` abre diretamente o `WizardScreen` carregando a sessão para continuar o preenchimento de onde o usuário parou.
  - Tocar em um card com status `GERADO` abre diretamente o visualizador do PDF.

## Capabilities

### Modified Capabilities
- `unified-wizard-engine`: Adiciona auto-save contínuo de estado no disco/Isar durante o preenchimento, persistência de rascunhos e correção de dimensionamento no modal de assinatura digital.
- `history-tracking`: Suporte a relatórios em progresso no histórico, diferenciação visual e de fluxo entre relatórios `EM_PROGRESSO` e `GERADO`, e transição de estado ao re-editar relatórios.

## Impact

- **Código afetado**:
  - `app/lib/features/wizard/views/widgets/signature_modal.dart`
  - `app/lib/features/wizard/controllers/wizard_state_controller.dart`
  - `app/lib/features/wizard/views/wizard_screen.dart`
  - `app/lib/core/models/local/submission_record.dart` (e geração do `.g.dart`)
  - `app/lib/features/home/views/history_screen.dart`
  - `app/lib/features/home/providers/history_provider.dart`
  - `app/lib/features/pdf_generation/providers/generation_provider.dart`
- **Dependências**: Nenhuma nova dependência externa necessária.
- **Migração de dados**: Registros legados no Isar sem status explícito serão tratados como `GERADO` caso possuam `pdfPath` válido, ou `EM_PROGRESSO` caso contrário.
