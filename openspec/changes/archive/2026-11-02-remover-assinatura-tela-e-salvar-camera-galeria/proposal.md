# Proposta: Remoção da Assinatura Manuscrita em Tela e Salvamento de Capturas da Câmera no Rolo da Câmera

## Why

Atualmente, os protocolos de manutenção e cadastro de materiais exigem uma assinatura manuscrita desenhada com o dedo na tela (`SIGNATURE` / `SignatureModal`) ao final do preenchimento, o que gera uma imagem rasterizada sem valor criptográfico e causa atrito de usabilidade em ambiente de parede/falésia — especialmente porque o laudo já possui assinatura digital criptográfica real (W3C XML-DSig com ECDSA `secp256r1` e certificado X.509 em `META-INF/signatures.xml`). Além disso, quando o mantenedor tira fotos ou grava vídeos diretamente pela câmera através do aplicativo, essas mídias ficam restritas ao diretório privado da sessão do Fixalog e não aparecem no rolo da câmera do celular, contrariando a expectativa natural do usuário de ter suas fotos e vídeos de campo salvos também na galeria do dispositivo.

## What Changes

- **BREAKING**: **Remoção completa do suporte a assinatura manuscrita (`SIGNATURE`)**:
  - Remoção da etapa/bloco de assinatura manuscrita nos protocolos `app/assets/protocols/manutencao_ferragens.yaml` (`assinatura` / `assinatura_c`) e `app/assets/protocols/cadastro_material.yaml` (Bloco 3 `encerramento_material` / `mat_assinatura_c`).
  - Remoção do widget `SignatureModal` (`app/lib/features/wizard/views/widgets/signature_modal.dart`), de seu teste espelhado e da dependência `signature` no `pubspec.yaml`.
  - Remoção do tratamento de `SIGNATURE` no `WizardScreen`, `WizardStateController` e `ProtocolParser`, alterando o rótulo do botão do último passo no Wizard de `"ASSINAR E CONCLUIR"` para `"CONCLUIR"`.
  - Manutenção integral da assinatura digital criptográfica W3C XML-DSig (`XmlDsigSigner` + `CryptoService`) durante a geração do container EPUB 3.
- **Compatibilidade e Exclusão Resiliente de Relatórios Antigos**:
  - Tratamento automático em `ProtocolParser` e `WizardStateController.loadSession` para ignorar/filtrar passos e conteúdos legados do tipo `SIGNATURE` (bem como respostas `assinatura_c` e `mat_assinatura_c`) armazenados no `yamlConteudo` e `respostas` de sessões antigas, permitindo abrir, editar e re-gerar relatórios antigos sem erro.
  - Blindagem de `HistoryRepository.deleteRecord` para excluir com resiliência todos os artefatos associados a relatórios antigos ou atuais (`.pdf`, `.epub` principal ou irmão e diretório de sessão `SessionBundleManager`), garantindo que a exclusão no histórico nunca falhe mesmo diante de arquivos ausentes ou legados.
- **Cópia Automática de Fotos e Vídeos da Câmera para o Rolo da Câmera**:
  - Criação do serviço de fronteira `ServicoGaleriaDispositivo` (`app/lib/features/media/services/servico_galeria_dispositivo.dart`) e sua biblioteca de Fake determinístico (`app/test/fakes/servico_galeria_dispositivo_fake.dart`).
  - Ao capturar foto (`_OrigemMidia.fotoCamera`) ou gravar vídeo (`_OrigemMidia.videoCamera`) pela câmera no `WizardScreen`, além de persistir a mídia original no `SessionBundleManager`, o aplicativo exporta uma cópia diretamente para o rolo da câmera do dispositivo (sem criar álbum separado e sem duplicar mídias escolhidas da galeria).
  - Operação tolerante a falhas (*best-effort*): caso o sistema operacional negue permissão ou ocorra erro ao salvar na galeria externa, a mídia permanece salva normalmente na sessão pericial do relatório.

## Capabilities

### New Capabilities
*(Nenhuma nova capability de nível de sistema introduzida; os comportamentos estendem as capabilities existentes do motor do Wizard, catálogo de materiais e histórico)*

### Modified Capabilities
- `unified-wizard-engine`: Remoção do componente de assinatura manuscrita (`SIGNATURE` / `SignatureModal`), migração transparente de sessões legadas com `SIGNATURE` no YAML salvo e exportação automática para o rolo da câmera das fotos e vídeos capturados pela câmera nativa.
- `catalogo-materiais`: Conclusão do cadastro de materiais sem etapa de assinatura manuscrita em tela, mantendo a assinatura digital criptográfica XML-DSig na geração do pacote EPUB 3.
- `history-tracking`: Exclusão resiliente de registros e relatórios antigos (incluindo limpeza segura de `.pdf`, `.epub` irmão e bundle de sessão) e edição sem erros de registros legados.

## Impact

- **Protocolos YAML**: `app/assets/protocols/manutencao_ferragens.yaml`, `app/assets/protocols/cadastro_material.yaml`.
- **Motor do Wizard e Serviços**: `app/lib/features/wizard/views/wizard_screen.dart`, `app/lib/features/wizard/controllers/wizard_state_controller.dart`, `app/lib/core/services/protocol_parser.dart`, `app/lib/features/home/providers/history_provider.dart`.
- **Remoções**: `app/lib/features/wizard/views/widgets/signature_modal.dart`, `app/test/features/wizard/views/widgets/signature_modal_test.dart`, pacote `signature` em `app/pubspec.yaml`.
- **Mídia e Galeria**: Novo serviço `app/lib/features/media/services/servico_galeria_dispositivo.dart`, Fake determinístico em `app/test/fakes/servico_galeria_dispositivo_fake.dart`, configurações de permissão em `AndroidManifest.xml` / `Info.plist` e dependência de salvamento no rolo da câmera (`gal`).
