# Tasks

## 1. Remoção da Assinatura Manuscrita nos Protocolos, Parser e Controlador (com Suporte a Legado)

- [x] 1.1 [RED] Atualizar `app/test/core/services/protocol_parser_test.dart` e `app/test/features/wizard/controllers/wizard_state_controller_test.dart` com testes validando que os protocolos `manutencao_ferragens.yaml` e `cadastro_material.yaml` não possuem passos de assinatura manuscrita (`SIGNATURE`) e que o `ProtocolParser` / `loadSession` filtram e ignoram silenciosamente blocos, passos e respostas legadas (`SIGNATURE`, `assinatura_c`, `mat_assinatura_c`) de sessões antigas, verificando que os novos testes falham inicialmente
- [x] 1.2 [GREEN] Remover os passos/blocos de assinatura de `app/assets/protocols/manutencao_ferragens.yaml` e `app/assets/protocols/cadastro_material.yaml` e atualizar `app/lib/core/services/protocol_parser.dart` e `app/lib/features/wizard/controllers/wizard_state_controller.dart` para filtrar conteúdos/passos/blocos `SIGNATURE` e limpar respostas legadas de assinatura ao carregar sessões antigas, verificando que `flutter test test/core/services/protocol_parser_test.dart test/features/wizard/controllers/wizard_state_controller_test.dart` passa com 100% de sucesso

## 2. Remoção do `SignatureModal` e Limpeza do `WizardScreen`

- [x] 2.1 [RED] Atualizar `app/test/features/wizard/views/wizard_screen_test.dart` para validar que o botão do último passo exibe `"CONCLUIR"` (sem abrir modal de assinatura) e avança diretamente para o card de conclusão, e remover `app/test/features/wizard/views/widgets/signature_modal_test.dart` e `app/test/integration/signature_capture_flow_test.dart`
- [x] 2.2 [GREEN] Remover `app/lib/features/wizard/views/widgets/signature_modal.dart`, remover a dependência `signature` de `app/pubspec.yaml` e limpar todas as referências a `SignatureModal` e `StepCampoSimples_TipoCampo.SIGNATURE` em `app/lib/features/wizard/views/wizard_screen.dart`, verificando que `flutter test test/features/wizard/views/wizard_screen_test.dart` e `flutter test test/test_structure_mirror_test.dart` passam

## 3. Exclusão Resiliente de Relatórios Antigos no Histórico

- [x] 3.1 [RED] Adicionar testes orientados a comportamento em `app/test/features/home/providers/history_provider_test.dart` e `app/test/features/home/views/history_screen_test.dart` exercitando a exclusão de relatórios antigos contendo arquivo `.epub` irmão de `pdfPath`, arquivos ausentes e artefatos de assinatura legados, verificando que falham antes da mudança
- [x] 3.2 [GREEN] Atualizar `HistoryRepository.deleteRecord` em `app/lib/features/home/providers/history_provider.dart` para remover com resiliência (`try/catch` isolado por artefato) o arquivo `pdfPath`, eventual `.epub` irmão (`pdfPath` substituindo `.pdf` por `.epub`), `protobufPath` e o diretório `SessionBundleManager`, garantindo a exclusão no banco local sem erros e verificando que `flutter test test/features/home/` passa integralmente

## 4. Biblioteca `ServicoGaleriaDispositivo` e Fake Determinístico

- [x] 4.1 Adicionar o pacote `gal` em `app/pubspec.yaml` e configurar as declarações de permissão de escrita no rolo da câmera em `app/android/app/src/main/AndroidManifest.xml` e `app/ios/Runner/Info.plist`, verificando que `flutter pub get` conclui sem erros
- [x] 4.2 [RED] Criar os testes unitários espelhados `app/test/features/media/services/servico_galeria_dispositivo_test.dart` e `app/test/fakes/servico_galeria_dispositivo_fake_test.dart` validando o salvamento de fotos e vídeos no rolo da câmera e a simulação determinística de falhas
- [x] 4.3 [GREEN] Implementar `app/lib/features/media/services/servico_galeria_dispositivo.dart` (com `servicoGaleriaDispositivoProvider`) e `app/test/fakes/servico_galeria_dispositivo_fake.dart` com docstrings em português, verificando que ambos os arquivos de teste e `test_structure_mirror_test.dart` passam com 100% de cobertura

## 5. Integração da Captura de Câmera com o Rolo da Câmera no `WizardScreen`

- [x] 5.1 [RED] Adicionar testes de comportamento em `app/test/features/wizard/views/wizard_screen_test.dart` utilizando `ServicoGaleriaDispositivoFake` para verificar que: (a) fotos e vídeos capturados pela câmera são salvos no `SessionBundleManager` e no rolo da câmera; (b) mídias escolhidas da galeria não são duplicadas no rolo da câmera; e (c) falhas no `ServicoGaleriaDispositivo` não impedem o anexo da mídia na sessão
- [x] 5.2 [GREEN] Integrar `servicoGaleriaDispositivoProvider` na captura de foto (`_OrigemMidia.fotoCamera`) e vídeo (`_OrigemMidia.videoCamera`) em `app/lib/features/wizard/views/wizard_screen.dart` com tratamento resiliente de erros, verificando que `flutter test test/features/wizard/views/wizard_screen_test.dart` passa integralmente

## 6. Verificação de Integração, Espelhamento 1:1 e Cobertura

- [x] 6.1 Executar a suíte completa de testes (`flutter test` e `test_structure_mirror_test.dart`) e `flutter analyze` em `app/`, verificando zero avisos de lint, espelhamento 1:1 estrito e 100% dos testes passando
