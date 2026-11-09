# Proposta: Canal de Feedback In-App Offline e Evolução da Aba de Configurações

## Why

Durante auditorias técnicas em vias de escalada, os peritos e conquistadores frequentemente se deparam com comportamentos inesperados, inconsistências em itens de protocolo ou dúvidas sobre o preenchimento que precisam ser reportadas à equipe de desenvolvimento. Atualmente, o Fixalog não possui um canal integrado de envio de relatos em campo. Além disso, a aba de configurações (`_SettingsPlaceholder` em `HomeScreen`), embora já contenha o seletor de 7 idiomas e o atalho para a tela de identidade OIDC, ainda não exibe o resumo auditável da identidade pericial ativa (nome, clube, provedor OIDC e fingerprint ECDSA P-256), o histórico de aceite dos Termos de Uso (`versaoTermosAceita` e `dataHoraAceiteTermos`) nem os canais oficiais de governança e suporte da comunidade Aresta Climb.

Implementar o **In-App Feedback** com anotações visuais sobre a captura de tela e **fila offline nativa persistida no `BancoDadosLocal` (`sqflite`)** permite que o auditor registre o problema no calor do momento na montanha, com envio automático em segundo plano assim que o dispositivo recuperar conexão. Concomitantemente, extrair e evoluir a **Aba de Configurações** (`TelaConfiguracoes`) consolida a governança pericial, preservando o seletor multilíngue e a gestão de conta OIDC já existentes.

## What Changes

- **In-App Feedback com Anotações Visuais (`app/lib/features/feedback/`)**:
  - Integração do pacote `feedback: ^3.1.0` com formulário customizado (`ConstrutorFeedbackUsuario`) adaptado ao tema escuro do Fixalog e traduzido nos 7 idiomas suportados.
  - Permite desenhar setas, círculos e anotações sobre a tela atual, além de texto descritivo e categorização do relato.
  - Compressão local da imagem anotada (`CompressorImagemFeedback`) antes do armazenamento em disco.
- **Fila Offline com Persistência no `BancoDadosLocal` SQLite (`FeedbackRecord`)**:
  - Migração do `BancoDadosLocal` (`app/lib/core/services/banco_dados_local.dart`) para `_versaoSchema = 3`, adicionando a tabela `fila_feedback` e métodos CRUD para enfileiramento e despacho.
  - Modelo Dart puro `FeedbackRecord` (`app/lib/core/models/local/feedback_record.dart` com `toMap`/`fromMap`, zero `build_runner`) contendo mensagem, caminho da imagem comprimida, metadados do aparelho/protocolo, timestamp e status de envio.
  - Serviço de despacho em segundo plano (`ServicoFilaFeedback`) com autenticação via cabeçalho `X-Firebase-AppCheck` (`AutenticacaoNuvemService` / `ServicoAppCheck`), registro de falhas transitórias via `RegistroLogger` e testes com SQLite real em memória (`BancoDadosLocal.abrirEmMemoria()`).
- **Evolução da Aba de Configurações e Governança (`TelaConfiguracoes`)**:
  - Extração e evolução de `_SettingsPlaceholder` (`HomeScreen`) para `app/lib/features/settings/views/tela_configuracoes.dart`, **preservando integralmente** os widgets e chaves existentes do seletor de 7 idiomas (`seletor_idioma_config`, `dropdown_idioma_config`, `opcao_idioma_<locale>`) e do cartão de acesso à identidade (`card_identidade_config`, `botao_gerenciar_identidade_config`).
  - Adição das seções de governança pericial:
    - Resumo da identidade pericial configurada: nome, clube/associação (`IdentityRecord`), status da sessão OIDC OpenPubkey (`AutenticacaoNuvemService`) e fingerprint da chave pública ECDSA P-256 (`CryptoService`).
    - Auditoria de conformidade legal: versão aceita (`versaoTermosAceita`), timestamp exato de consentimento (`dataHoraAceiteTermos`) e acesso para leitura dos Termos de Uso e Política de Privacidade no idioma ativo.
    - Links externos oficiais: Comunidade Aresta Climb no WhatsApp (`https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv`) e Portal Web (`https://arestaclimb.com`).
    - Botão de acionamento direto do In-App Feedback (`BotaoFeedback`).
- **Paridade Multilíngue (7 Idiomas)**:
  - Adição das novas chaves de tradução nos 7 arquivos `.arb` (`pt`, `en`, `es`, `fr`, `de`, `ar`, `ja`) e regeneração de `app_localizations*.dart` em conformidade com `l10n_parity_test.dart`.

## Capabilities

### New Capabilities
- `canal-feedback-offline`: Captura de feedback visual com anotações, compressão de imagem e fila local no `BancoDadosLocal` (SQLite) com despacho resiliente autenticado via App Check.
- `aba-configuracoes-governanca`: Tela de configurações com seletor de 7 idiomas, dados completos do auditor (identidade local + OIDC + chave ECDSA), auditoria de termos aceitos, acionador de feedback e links da comunidade.

### Modified Capabilities
*(Nenhuma especificação canônica existente em `openspec/specs/` teve seus requisitos alterados)*

## Impact

- **Código e Dependências**:
  - `app/pubspec.yaml`: adição de `feedback: ^3.1.0` e `url_launcher` (se necessário para abertura externa multiplataforma).
  - `app/lib/core/services/banco_dados_local.dart`: migração para schema v3 com tabela `fila_feedback`.
  - `app/lib/core/models/local/feedback_record.dart`: nova entidade persistida no SQLite.
  - `app/lib/features/feedback/`: componentes de captura (`botao_feedback.dart`, `construtor_feedback_usuario.dart`), compressão (`compressor_imagem_feedback.dart`) e fila (`servico_fila_feedback.dart`).
  - `app/lib/features/settings/views/tela_configuracoes.dart`: nova tela de configurações extraída e expandida a partir de `home_screen.dart`.
  - `app/lib/core/l10n/arb/app_*.arb`: novas chaves de localização nos 7 idiomas suportados.
