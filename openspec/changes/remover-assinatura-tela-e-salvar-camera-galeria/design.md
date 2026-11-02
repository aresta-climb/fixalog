# Design: Remoção da Assinatura Manuscrita em Tela e Salvamento de Capturas da Câmera no Rolo da Câmera

## Context

Conforme detalhado em `proposal.md`, o Fixalog hoje possui dois mecanismos distintos sob o nome de "assinatura":
1. **Assinatura Digital Criptográfica (W3C XML-DSig)**: executada automaticamente pelo `GenerationNotifier` via `XmlDsigSigner` e `CryptoService` (ECDSA `secp256r1` + certificado X.509) sobre todos os arquivos do container `.epub` (`META-INF/signatures.xml`).
2. **Assinatura Manuscrita em Tela (`SIGNATURE` / `SignatureModal`)**: etapa final nos protocolos YAML (`manutencao_ferragens.yaml` e `cadastro_material.yaml`) que exige um desenho com o dedo na tela para gerar uma imagem PNG avulsa.

Além disso, na captura de fotos e vídeos pela câmera nativa via `image_picker` em `WizardScreen`, os arquivos são gravados apenas no cache temporário privado do aplicativo e copiados para o `SessionBundleManager` interno, nunca sendo registrados no rolo da câmera do sistema operacional (`MediaStore` no Android / `PhotoLibrary` no iOS).

## Goals / Non-Goals

**Goals:**
- Remover integralmente o fluxo de assinatura manuscrita em tela (`SIGNATURE`), o widget `SignatureModal`, a dependência `signature` e os blocos/passos correspondentes nos arquivos YAML de protocolo.
- Garantir compatibilidade retroativa total com sessões e relatórios antigos já gravados no dispositivo (cujo `yamlConteudo` no `registro.binarypb` ou mapa `respostas` ainda contenha `SIGNATURE`, `assinatura_c` ou `mat_assinatura_c`), tanto para abertura/edição quanto para exclusão limpa pelo Histórico.
- Exportar automaticamente para o rolo da câmera do dispositivo todas as fotos e vídeos capturados pela câmera do aplicativo (`_OrigemMidia.fotoCamera` e `_OrigemMidia.videoCamera`), mantendo arquitetura desacoplada (*Library-First*) com Fake determinístico para 100% de cobertura de testes sem mocks.

**Non-Goals:**
- Alterar o funcionamento da assinatura digital criptográfica W3C XML-DSig (`XmlDsigSigner` e `CryptoService`), que permanece como o mecanismo oficial de autenticidade e integridade pericial do laudo.
- Criar álbuns customizados na galeria do celular (as mídias devem ir direto para o rolo da câmera padrão) ou duplicar arquivos que já foram selecionados a partir da galeria.

## Decisions

### 1. Remoção de `SIGNATURE` e Limpeza de Protocolos YAML
- **Decisão**:
  - Remover o step `assinatura` (`assinatura_instrucao` e `assinatura_c`) do Bloco 4 de `app/assets/protocols/manutencao_ferragens.yaml` e atualizar o subtítulo do Bloco 4 para `"Avaliação final das condições da via"`.
  - Remover o Bloco 3 (`encerramento_material` / `assinatura_material` / `mat_assinatura_c`) de `app/assets/protocols/cadastro_material.yaml`.
  - Remover `app/lib/features/wizard/views/widgets/signature_modal.dart`, `app/test/features/wizard/views/widgets/signature_modal_test.dart`, `app/test/integration/signature_capture_flow_test.dart` e a dependência `signature: ^6.4.0` em `app/pubspec.yaml`.
  - Em `WizardScreen`: remover a interceptação de `SIGNATURE` em `_onNextPressed()`, remover o `case StepCampoSimples_TipoCampo.SIGNATURE:` em `_CampoSimplesContent._buildInput()` e alterar o rótulo do botão final em `_NextButton` de `'ASSINAR E CONCLUIR'` para `'CONCLUIR'`.
- **Alternativas consideradas**:
  - *Apenas ocultar o campo nos YAMLs mantendo o `SignatureModal` no código*: descartado porque deixaria código morto e dependência externa desnecessária (`signature`), violando os Princípios IV e VI do `AGENTS.md`.

### 2. Migração Transparente e Exclusão Resiliente de Relatórios Antigos
- **Decisão**:
  - **No `ProtocolParser.fromYaml`**: ao fazer o parse dos blocos e steps de um YAML (inclusive YAMLs antigos persistidos em `registro.yamlConteudo`), filtrar e descartar qualquer `ConteudoStep` cujo `campo_simples.tipo` seja `'SIGNATURE'` (bem como instruções de assinatura legadas `assinatura_instrucao` / `mat_assinatura_instrucao`). Caso um `Step` fique sem `conteudos` após a filtragem (ex.: `id: assinatura` ou `id: assinatura_material`), o `Step` é omitido; caso um `Bloco` fique sem `steps` (ex.: `id: encerramento_material`), o `Bloco` também é omitido.
  - **No `WizardStateController.loadSession`**:
    - Remover silenciosamente as chaves legadas `assinatura_c` e `mat_assinatura_c` do mapa `allAnswers` carregado e substituir `yamlStr` pelo protocolo atualizado dos assets caso `yamlStr` contenha `SIGNATURE` em protocolos conhecidos (`manutencao_ferragens` ou `cadastro_material`).
  - **No `HistoryRepository.deleteRecord`**:
    - Envolver cada exclusão física de arquivo (`record.pdfPath`, eventual arquivo `.epub` irmão derivado de `pdfPath.replaceAll('.pdf', '.epub')`, `record.protobufPath` quando `.epub`, e `_sessionManager.deleteSessionBundle(record.idSessao)`) em blocos `try/catch` independentes e garantir que a remoção do `SubmissionRecord` no banco local ocorra mesmo se algum arquivo antigo já não existir ou falhar no sistema de arquivos.
- **Racional**: Garante que nenhum usuário com relatórios antigos em andamento ou concluídos sofra exceções ao abrir, editar, re-gerar ou excluir esses relatórios após a atualização.

### 3. Serviço de Fronteira `ServicoGaleriaDispositivo` e Fake Determinístico
- **Decisão**:
  - Criar `ServicoGaleriaDispositivo` em `app/lib/features/media/services/servico_galeria_dispositivo.dart` exposto via `servicoGaleriaDispositivoProvider` (Riverpod).
  - Interface pública limpa e em português:
    - `Future<void> salvarFotoNoRoloDaCamera(String caminhoArquivo)`
    - `Future<void> salvarVideoNoRoloDaCamera(String caminhoArquivo)`
  - Implementação padrão utilizando o pacote `gal` (`Gal.putImage(caminhoArquivo)` e `Gal.putVideo(caminhoArquivo)` sem parâmetro `album`, o que grava diretamente no rolo da câmera padrão do Android/iOS), com injeção opcional de callbacks para testabilidade da implementação concreta.
  - Configurar permissões nativas para salvamento no rolo da câmera:
    - `AndroidManifest.xml`: `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />` (no Android 10+ / API 29+, a inserção via `MediaStore` não requer permissão extra).
    - `Info.plist`: `<key>NSPhotoLibraryAddUsageDescription</key>` explicando o salvamento das fotos e vídeos capturados durante a vistoria no rolo da câmera.
  - Criar `ServicoGaleriaDispositivoFake` em `app/test/fakes/servico_galeria_dispositivo_fake.dart` (e seu teste espelhado `app/test/fakes/servico_galeria_dispositivo_fake_test.dart`) que registra em memória as listas `fotosSalvas` e `videosSalvos` e permite configurar `deveFalhar = true` para simular erros de permissão/I/O determinísticos.
  - Em `WizardScreen`, ao capturar foto (`_OrigemMidia.fotoCamera`) ou vídeo (`_OrigemMidia.videoCamera`), acionar `saveMediaAnswer` (que persiste no `SessionBundleManager`) e chamar `servicoGaleria.salvarFotoNoRoloDaCamera` / `salvarVideoNoRoloDaCamera` dentro de um `try/catch` silencioso para nunca comprometer o anexo pericial caso a galeria externa falhe.

## Risks / Trade-offs

- **[Permissão negada pelo usuário no iOS ao salvar no rolo da câmera]** → O `ServicoGaleriaDispositivo` e a chamada no `WizardScreen` tratam qualquer exceção de permissão ou I/O de forma isolada, garantindo que a foto/vídeo já capturada pela câmera seja salva normalmente no `SessionBundleManager` do relatório.
- **[Arquivos Protobuf gerados (`wizard.pb.dart` / `fixalog.pb.dart`)]** → No schema `wizard.proto`, o valor `SIGNATURE = 7` no enum `TipoCampo` pode ser mantido apenas a nível de wire-format Protobuf (ou ignorado no parser Dart) para evitar quebra binária de desserialização, enquanto todo o código Dart de aplicação, parser YAML e UI deixa de produzir ou exibir `SIGNATURE`.

## Migration Plan

1. Ao atualizar o aplicativo, sessões antigas salvas em disco (`registro.binarypb`) que contenham `tipo: SIGNATURE` no `yamlConteudo` terão os passos de assinatura filtrados automaticamente pelo `ProtocolParser.fromYaml` e `WizardStateController.loadSession`.
2. Relatórios `.epub` antigos já gerados continuarão abrindo normalmente no `VisualizadorRelatorioScreen` e poderão ser excluídos sem erro pelo `HistoryRepository.deleteRecord`.
