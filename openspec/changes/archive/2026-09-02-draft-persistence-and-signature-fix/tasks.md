## 1. Testes de Integração em Primeiro Lugar (Fase Vermelha / Red)

- [x] 1.1 Criar teste de integração para o fluxo completo de auto-save: preenchimento parcial -> saída da tela -> exibição no histórico como `EM_PROGRESSO` -> retomada e conclusão.
- [x] 1.2 Criar teste de integração para abertura e captura de assinatura digital no `WizardScreen` garantindo ausência de exceção de hit test.

## 2. Correção do Modal de Assinatura (TDD)

- [x] 2.1 [RED] Escrever teste de widget para `SignatureModal` verificando o layout com restrições e resposta a toques.
- [x] 2.2 [GREEN] Envolver o widget `Signature` em `LayoutBuilder` no `SignatureModal` fornecendo `constraints.maxWidth` e altura definida.
- [x] 2.3 [REFACTOR] Assegurar código limpo, sem complexidade desnecessária e com 100% de cobertura nos testes de assinatura.

## 3. Modelo de Dados e Status do Isar (TDD)

- [x] 3.1 [RED] Escrever testes unitários em `submission_record_test.dart` para o campo `status` e tratamento de compatibilidade com registros legados.
- [x] 3.2 [GREEN] Adicionar campo `String status = 'EM_PROGRESSO'` no modelo `SubmissionRecord` e executar `build_runner` para re-gerar `submission_record.g.dart`.
- [x] 3.3 [GREEN] Atualizar `GenerationNotifier` para persistir `SubmissionRecord` com `status = 'GERADO'` após a conclusão do PDF.
- [x] 3.4 [REFACTOR] Verificar conformidade das classes de persistência com os princípios de simplicidade e nomenclatura em português.

## 4. Auto-Save Contínuo e Ciclo de Vida no Wizard (TDD)

- [x] 4.1 [RED] Escrever testes unitários em `wizard_state_controller_persistence_test.dart` para o auto-save reativo assíncrono em todas as mutações e transição para `EM_PROGRESSO` ao editar.
- [x] 4.2 [GREEN] Implementar persistência contínua assíncrona (com debounce para campos textuais) no `WizardStateController`.
- [x] 4.3 [GREEN] Implementar transição de status para `EM_PROGRESSO` ao modificar respostas em relatórios existentes no `WizardStateController`.
- [x] 4.4 [GREEN] Adicionar `PopScope` no `WizardScreen` para flush imediato de dados pendentes antes de fechar a tela.
- [x] 4.5 [REFACTOR] Refatorar rotinas de auto-save garantindo desacoplamento, robustez e ausência de vazamento de memória com timers.

## 5. Interface e Interações do Histórico (TDD)

- [x] 5.1 [RED] Escrever testes de widget em `history_screen_test.dart` cobrindo a exibição de badges (`EM PROGRESSO` e `GERADO`), toque contextual e opções de menu.
- [x] 5.2 [GREEN] Atualizar `HistoryScreen` com os badges visuais apropriados (`EM PROGRESSO` em âmbar e `GERADO` em verde/laranja).
- [x] 5.3 [GREEN] Ajustar o toque do card para retomar preenchimento no `WizardScreen` se `EM_PROGRESSO` ou abrir PDF se `GERADO`.
- [x] 5.4 [GREEN] Ajustar opções contextuais do menu de 3 pontinhos conforme o status do registro.
- [x] 5.5 [REFACTOR] Executar suite completa de testes garantindo 100% de cobertura e aprovação em todos os testes.
