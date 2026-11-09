# Tasks: Canal de Feedback In-App Offline e Evolução da Aba de Configurações

## 1. Dependências, Modelo SQLite e Migração do `BancoDadosLocal`

- [x] 1.1 Adicionar dependência `feedback: ^3.1.0` (e `url_launcher` se necessário) no `app/pubspec.yaml` e executar `flutter pub get`
- [x] 1.2 [TDD] Criar o modelo `FeedbackRecord` em `app/lib/core/models/local/feedback_record.dart` (com `toMap`/`fromMap` e cabeçalho SPDX) e atualizar `BancoDadosLocal` (`app/lib/core/services/banco_dados_local.dart`) para `_versaoSchema = 3` com a tabela `fila_feedback` e métodos CRUD (`inserirFeedback`, `listarFeedbacksPendentes`, `marcarFeedbackEnviado`)
- [x] 1.3 [TDD] Escrever testes unitários em `app/test/core/models/local/feedback_record_test.dart` e expandir `app/test/core/services/banco_dados_local_test.dart` validando serialização, migração de schema v2→v3 e operações na tabela `fila_feedback` usando `BancoDadosLocal.abrirEmMemoria()`

## 2. Compressão e Serviço de Fila de Feedback (Library-First & TDD)

- [x] 2.1 [TDD] Implementar utilitário `CompressorImagemFeedback` em `app/lib/features/feedback/utils/compressor_imagem_feedback.dart` e seus testes unitários espelhados em `app/test/features/feedback/utils/compressor_imagem_feedback_test.dart`
- [x] 2.2 [TDD - Red] Escrever testes unitários em `app/test/features/feedback/services/servico_fila_feedback_test.dart` validando enfileiramento offline no SQLite em memória, envio HTTP multipart com cabeçalho `X-Firebase-AppCheck`, tratamento de falhas transitórias via `RegistroLogger` e limpeza do arquivo de imagem após sucesso
- [x] 2.3 [TDD - Green] Implementar `ServicoFilaFeedback` em `app/lib/features/feedback/services/servico_fila_feedback.dart` e seu Fake determinístico `ServicoFilaFeedbackFake` em `app/test/fakes/servico_fila_feedback_fake.dart` (+ `servico_fila_feedback_fake_test.dart`)

## 3. Localização Multilíngue (7 Idiomas) e Widgets de Feedback

- [x] 3.1 Adicionar as novas chaves de tradução da `TelaConfiguracoes` e do formulário de feedback nos 7 arquivos `.arb` (`app_pt.arb`, `app_en.arb`, `app_es.arb`, `app_fr.arb`, `app_de.arb`, `app_ar.arb`, `app_ja.arb`), executar `flutter gen-l10n`, garantir o cabeçalho SPDX nos arquivos gerados em `app/lib/core/l10n/generated/` e validar com `flutter test test/architecture/l10n_parity_test.dart`
- [x] 3.2 [TDD] Implementar `ConstrutorFeedbackUsuario` em `app/lib/features/feedback/views/construtor_feedback_usuario.dart` e `BotaoFeedback` em `app/lib/features/feedback/views/botao_feedback.dart`, com seus respectivos testes espelhados em `app/test/features/feedback/views/`
- [x] 3.3 Envolver a aplicação com o provedor `BetterFeedback` em `app/lib/main.dart` (utilizando `ConstrutorFeedbackUsuario`) e atualizar `app/test/main_test.dart`

## 4. Aba de Configurações e Governança Pericial (`TelaConfiguracoes`)

- [x] 4.1 [TDD - Red] Escrever testes de widget em `app/test/features/settings/views/tela_configuracoes_test.dart` cobrindo: seletor de 7 idiomas (`seletor_idioma_config`), exibição de identidade local + OIDC + fingerprint ECDSA, versão e data/hora de aceite dos termos (`versaoTermosAceita` e `dataHoraAceiteTermos`), consulta aos termos, acionamento do `BotaoFeedback` e abertura dos links externos (WhatsApp `https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv` e site `https://arestaclimb.com`)
- [x] 4.2 [TDD - Green] Implementar `TelaConfiguracoes` em `app/lib/features/settings/views/tela_configuracoes.dart` e integrar no `HomeScreen` (`app/lib/features/home/views/home_screen.dart`), garantindo que todos os testes em `app/test/features/home/views/home_screen_test.dart` continuem passando

## 5. Auditoria de Qualidade e Conformidade Arquitetural

- [x] 5.1 Executar os testes arquiteturais (`flutter test test/architecture/`) validando espelhamento 1:1 (`test_structure_mirror_test.dart`), paridade de 7 idiomas (`l10n_parity_test.dart`) e cabeçalhos SPDX (`license_headers_test.dart`)
- [x] 5.2 Executar `flutter test --coverage` e `flutter analyze` garantindo 100% de cobertura nos novos arquivos e zero warnings
