# Proposta: Canal de Feedback In-App Offline e Aba de Configurações

## Why

Durante auditorias técnicas em vias de escalada, os peritos e conquistadores frequentemente se deparam com comportamentos inesperados, inconsistências em itens de protocolo ou dúvidas sobre o preenchimento que precisam ser reportadas à equipe de desenvolvimento. Atualmente, o FixLog não possui um canal integrado de envio de relatos e conta apenas com um placeholder estático na aba de configurações.

Implementar o **In-App Feedback** com anotações visuais sobre a captura de tela e **fila offline nativa com persistência no banco local SQLite (`sqflite`)** permite que o auditor registre o problema no calor do momento na montanha, com envio automático em segundo plano assim que o dispositivo recuperar conexão. Concomitantemente, a estruturação definitiva da **Aba de Configurações** formaliza a governança pericial, exibindo a chave pública da identidade pericial, os termos de uso aceitos com data/hora e links diretos para a comunidade Aresta Climb no WhatsApp e portal web.

## What Changes

- **In-App Feedback com Anotações Visuais**:
  - Integração do pacote `feedback: ^3.1.0` empacotado em arquitetura desacoplada (`features/feedback/`).
  - Permite desenhar setas, círculos e anotações sobre a tela atual, além de texto descritivo.
  - Compressão local da imagem anotada para WebP/JPEG otimizado antes do armazenamento.
- **Fila Offline com Persistência no SQLite (`FeedbackRecord`)**:
  - Nova tabela SQLite e modelo Dart puro `FeedbackRecord` (com `toMap`/`fromMap`, sem geração de código) contendo mensagem, imagem comprimida, metadados do aparelho e status de envio.
  - Serviço de despacho em segundo plano (`ServicoFilaFeedback`) com tentativa resiliente e detecção de conectividade, testado com banco SQLite `in-memory` (`sqflite_common_ffi`).
- **Aba de Configurações e Governança**:
  - Substituição do placeholder por tela estruturada em `features/settings/views/tela_configuracoes.dart`.
  - Exibição de:
    - Identidade do perito (nome, e-mail, fingerprint da chave criptográfica).
    - Termos de Uso e Política de Privacidade aceitos com versão e timestamp de auditoria.
    - Links externos oficiais: WhatsApp da comunidade Aresta Climb (`https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv`) e Portal (`https://arestaclimb.com`).
    - Botão de acionamento do In-App Feedback.

## Capabilities

### New Capabilities
- `canal-feedback-offline`: Captura de feedback visual com anotações, compressão de imagem e fila local com despacho resiliente.
- `aba-configuracoes-governanca`: Tela de configurações com dados do auditor, termos aceitos e links da comunidade.

### Modified Capabilities
*(Nenhuma especificação existente teve seus requisitos alterados)*

## Impact

- **Código e Dependências**:
  - `app/pubspec.yaml`: adição de `feedback: ^3.1.0`.
  - `app/lib/core/models/local/feedback_record.dart`: nova entidade persistida no SQLite (`sqflite`).
  - `app/lib/features/feedback/`: componentes de captura, compressão e fila.
  - `app/lib/features/home/views/home_screen.dart`: substituição do placeholder de configurações.
