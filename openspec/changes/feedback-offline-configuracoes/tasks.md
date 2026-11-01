# Tasks: Canal de Feedback In-App Offline e Aba de Configurações

## 1. Dependências e Modelo SQLite

- [ ] 1.1 Adicionar dependência `feedback: ^3.1.0` no `app/pubspec.yaml` e executar `flutter pub get`
- [ ] 1.2 [TDD] Criar o modelo `FeedbackRecord` em `app/lib/core/models/local/feedback_record.dart` (com `toMap`/`fromMap`) e registrar a tabela `fila_feedback` no serviço de banco SQLite local
- [ ] 1.3 [TDD] Escrever testes unitários em `app/test/core/models/local/feedback_record_test.dart` validando serialização, persistência em banco SQLite `in-memory` e transições de status

## 2. Serviço de Fila e Compressão de Imagens (Library-First & TDD)

- [ ] 2.1 [TDD - Red] Escrever testes unitários em `app/test/features/feedback/services/servico_fila_feedback_test.dart` validando inserção na fila e tentativas de despacho
- [ ] 2.2 [TDD - Green] Implementar `ServicoFilaFeedback` em `app/lib/features/feedback/services/servico_fila_feedback.dart` com suporte a execução offline
- [ ] 2.3 Implementar utilitário `compressor_imagem_feedback.dart` e seus testes unitários espelhados em `test/features/feedback/utils/`

## 3. Integração do Widget de Feedback

- [ ] 3.1 Envolver a raiz da aplicação com o provedor `BetterFeedback` configurado com textos em português no `app/lib/main.dart`
- [ ] 3.2 Criar widget acionador `BotaoFeedback` em `app/lib/features/feedback/views/botao_feedback.dart` com testes de widget espelhados

## 4. Aba de Configurações e Governança Pericial

- [ ] 4.1 [TDD - Red] Escrever testes de widget em `app/test/features/settings/views/tela_configuracoes_test.dart` cobrindo exibição de identidade, versão legal e toque nos links externos
- [ ] 4.2 [TDD - Green] Implementar `TelaConfiguracoes` em `app/lib/features/settings/views/tela_configuracoes.dart`
- [ ] 4.3 Substituir o placeholder `_SettingsPlaceholder` em `app/lib/features/home/views/home_screen.dart` pela `TelaConfiguracoes`

## 5. Testes de Integração e Qualidade

- [ ] 5.1 Escrever teste de integração de ponta a ponta em `app/integration_test/fluxo_feedback_e_configuracoes_test.dart` validando geração de feedback offline e navegação em configurações
- [ ] 5.2 Executar `flutter test --coverage` e `flutter analyze` garantindo conformidade arquitetural integral
