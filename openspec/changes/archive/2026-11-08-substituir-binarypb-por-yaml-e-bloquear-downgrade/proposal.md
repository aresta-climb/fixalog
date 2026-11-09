# Proposal

## Why

Atualmente, os dados estruturados do relatório dentro do container assinado (`.epub`) e na pasta local da sessão (`sessoes/<id>/`) são persistidos no formato binário opaco do Protobuf (`registro.binarypb`). Como o formato binário do Protobuf armazena apenas os números das tags (`1`, `2`, `10`, `11`...) sem os nomes dos campos, um arquivo `.epub` aberto daqui a 20 anos sem as ferramentas ou schemas compilados originais não seria legível diretamente por humanos. Além disso, precisamos garantir que, caso um aplicativo desatualizado tente abrir para **editar ou duplicar** um relatório criado em uma versão mais nova do protocolo (`versaoOrigem > versaoAlvo`), a edição seja explicitamente recusada com orientação para atualizar o aplicativo, evitando corrupção silenciosa ou downgrade indevido de dados.

## What Changes

- **Substituição de `registro.binarypb` por `registro.yaml` Canônico e Tipado**:
  - **BREAKING (Formato Interno do Manifesto)**: Substituir a gravação binária `registro.binarypb` pela serialização textual legível `registro.yaml` tanto na sessão local (`sessoes/<id_sessao>/registro.yaml`) quanto dentro do pacote EPUB 3 (`OEBPS/dados/registro.yaml`, assinado criptograficamente via `META-INF/signatures.xml`).
  - Criar a biblioteca dedicada `SerializadorYamlRegistro` (`app/lib/core/services/serializador_yaml_registro.dart`) que serializa a instância Protobuf `Registro` para YAML determinístico legível por humanos (via `toProto3Json()` e bloco multiline `|` para `yamlConteudo`) e desserializa `registro.yaml` de volta para uma instância Protobuf `Registro` estaticamente tipada e validada (via `loadYaml()` + `mergeFromProto3Json()`).
  - Manter fallback transparente de leitura para arquivos `registro.binarypb` legados já existentes no dispositivo ou em pacotes `.epub` antigos, convertendo-os para `registro.yaml` ao salvar.
- **Empacotamento dos Schemas `.proto` (`registro.proto` e `wizard.proto`) no `.epub` e Trava de Sincronia**:
  - Declarar o diretório `protos/` diretamente nos `assets` do `app/pubspec.yaml` (sem duplicar arquivos no repositório) para que a fonte única da verdade (`app/protos/registro.proto` e `app/protos/wizard.proto`) seja empacotada e assinada em `OEBPS/dados/registro.proto` e `OEBPS/dados/wizard.proto` dentro de todo container `.epub` selado, tornando cada laudo 100% autodescritivo pelos próximos 20+ anos.
  - Implementar uma trava automatizada de validação que compara os `message` e campos definidos em `app/protos/registro.proto` e `app/protos/wizard.proto` contra os descritores `BuilderInfo` (`info_`) das classes Dart geradas (`registro.pb.dart` e `wizard.pb.dart`), impedindo que os `.proto` empacotados no `.epub` fiquem defasados em relação ao código compilado.
- **Bloqueio Explícito de Downgrade ao Editar/Duplicar Relatórios (`versaoOrigem > versaoAlvo`)**:
  - Atualizar `MigradorProtocoloRegistro.migrarRegistro` para continuar migrando sempre para a versão mais nova do protocolo quando `versaoOrigem <= versaoAlvo`, mas **recusar imediatamente** a operação (lançando `ExcecaoVersaoProtocoloNaoSuportada`) quando `versaoOrigem > versaoAlvo`, instruindo o usuário a atualizar o aplicativo para editar ou duplicar aquele relatório. A visualização somente-leitura do `.epub` (`VisualizadorRelatorioScreen`) permanece permitida em qualquer versão.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability isolada; os comportamentos estendem as capabilities existentes de empacotamento EPUB 3, armazenamento de sessão e migração de protocolos. -->

### Modified Capabilities
- `epub3-report`: Substitui `OEBPS/dados/registro.binarypb` por `OEBPS/dados/registro.yaml` acompanhado dos schemas formais `OEBPS/dados/registro.proto` e `OEBPS/dados/wizard.proto` assinados digitalmente no `META-INF/signatures.xml`, mantendo compatibilidade de leitura com `.binarypb` legados e validação de sincronia `.proto` ↔ classes geradas.
- `session-bundle-storage`: Atualiza a persistência do manifesto da sessão em `sessoes/<id_sessao>/registro.yaml` (convertido de/para `Registro` Protobuf estaticamente tipado) com fallback de leitura para `registro.binarypb` legado.
- `protocolos-vistoria-e-migracao`: Adiciona a recusa explícita de downgrade (`versaoOrigem > versaoAlvo`) ao carregar um registro para edição ou duplicação no motor de migração.

## Impact

- **Arquivos de Configuração e Assets**:
  - `app/pubspec.yaml` (inclusão de `protos/` na lista de `assets` do Flutter).
- **Novos Serviços e Testes (Espelhamento 1:1)**:
  - `app/lib/core/services/serializador_yaml_registro.dart` e `app/test/core/services/serializador_yaml_registro_test.dart`.
- **Serviços e Controladores Atualizados**:
  - `app/lib/core/services/migrador_protocolo_registro.dart` e `app/test/core/services/migrador_protocolo_registro_test.dart`
  - `app/lib/core/services/session_bundle_manager.dart` e `app/test/core/services/session_bundle_manager_test.dart`
  - `app/lib/core/services/epub_packager_service.dart` e `app/test/core/services/epub_packager_service_test.dart`
  - `app/lib/core/services/banco_dados_local.dart` e `app/test/core/services/banco_dados_local_test.dart`
  - `app/lib/features/pdf_generation/providers/generation_provider.dart` e `app/test/features/pdf_generation/providers/generation_provider_test.dart`
  - `app/lib/features/pdf_generation/views/visualizador_relatorio_screen.dart` e `app/test/features/pdf_generation/views/visualizador_relatorio_screen_test.dart`
  - `app/lib/features/wizard/controllers/wizard_state_controller.dart` e `app/test/features/wizard/controllers/wizard_state_controller_test.dart`
