# Design: Canal de Feedback In-App Offline e Evolução da Aba de Configurações

## Context

O Fixalog é utilizado em ambientes de montanha onde o contato com desenvolvedores é frequentemente impossibilitado pela ausência de sinal. Recentemente, o aplicativo migrou toda a sua persistência local para SQLite puro via `BancoDadosLocal` (`sqflite` em produção e `BancoDadosLocal.abrirEmMemoria()` nos testes), adicionou autenticação OIDC OpenPubkey (`AutenticacaoNuvemService`), suporte a 7 idiomas offline (`ResolvedorIdioma`) e evoluiu a aba de configurações inicial em `HomeScreen`. Veja a motivação completa em `proposal.md`.

## Goals / Non-Goals

**Goals:**
- Fornecer tela interativa para anotações visuais e comentários sobre capturas de tela em qualquer tela do app (incluindo o `WizardScreen` e `VisualizadorRelatorioScreen`).
- Garantir persistência 100% offline na tabela `fila_feedback` do `BancoDadosLocal` (SQLite schema v3) para que nenhum relato se perca sem rede.
- Integrar o envio de feedback com o token `X-Firebase-AppCheck` (`AutenticacaoNuvemService` / `ServicoAppCheck`) e com o filtro de rede de montanha do `RegistroLogger`.
- Extrair `_SettingsPlaceholder` de `HomeScreen` para `TelaConfiguracoes`, preservando o seletor de 7 idiomas e o botão de gestão OIDC já testados, e adicionando a exibição detalhada da identidade pericial, auditoria dos termos aceitos (`versaoTermosAceita` e `dataHoraAceiteTermos`) e links diretos da comunidade.
- Manter paridade absoluta nos 7 idiomas (`pt`, `en`, `es`, `fr`, `de`, `ar`, `ja`), espelhamento 1:1 de testes e zero uso de mocks (Princípios I, III, IV e V do `AGENTS.md`).

**Non-Goals:**
- Criar infraestrutura de backend inédita (o envio utiliza o endpoint de feedback do ecossistema Aresta/Fixalog protegido por App Check).
- Alterar o fluxo de assinatura criptográfica de laudos na tela de configurações (a gestão de chaves e login OIDC permanece delegada à `IdentitySetupScreen`).

## Decisions

### 1. Entidade `FeedbackRecord` e Migração Schema v3 no `BancoDadosLocal`
- **Decisão**: Criar o modelo Dart puro `class FeedbackRecord` em `app/lib/core/models/local/feedback_record.dart` (com `toMap()` e `fromMap()`) e atualizar `BancoDadosLocal` (`app/lib/core/services/banco_dados_local.dart`) de `_versaoSchema = 2` para `_versaoSchema = 3`, criando a tabela `fila_feedback` (tanto em `onCreate` quanto em `onUpgrade` quando `oldVersion < 3`). Nos testes unitários e de widget, utilizar sempre `BancoDadosLocal.abrirEmMemoria()`.
- **Por que**: Segue estritamente o padrão estabelecido para `AppConfigRecord`, `IdentityRecord` e `SubmissionRecord` no `BancoDadosLocal`, respeitando os Princípios V (Anti-Mocking, SQLite `:memory:` real), VI (Simplicidade, zero `build_runner`) e VIII (100% Offline-First).

### 2. Despacho Resiliente com `ServicoFilaFeedback`, App Check e `RegistroLogger`
- **Decisão**: O `ServicoFilaFeedback` (`app/lib/features/feedback/services/servico_fila_feedback.dart`) recebe o `BancoDadosLocal`, um cliente HTTP (`http.Client` injetável), o `AutenticacaoNuvemService` (para anexar o cabeçalho `X-Firebase-AppCheck` e metadados opcionais do auditor) e utiliza `RegistroLogger.instance.logFalhaSyncOuDownload` em caso de falha de envio.
- **Por que**: Quando o auditor envia um feedback sem sinal na falésia, o registro fica salvo em `fila_feedback` com `enviado = 0` e a imagem comprimida permanece no diretório de suporte da aplicação. Qualquer falha de conexão durante tentativa de envio é tratada como breadcrumb no `RegistroLogger` (sem poluir o Sentry), e o arquivo de imagem local é removido do disco assim que o envio recebe HTTP 2xx.

### 3. Preservação de Contrato na Extração da `TelaConfiguracoes`
- **Decisão**: Ao substituir `_SettingsPlaceholder` em `app/lib/features/home/views/home_screen.dart` por `TelaConfiguracoes` (`app/lib/features/settings/views/tela_configuracoes.dart`), manter exatamente as chaves semânticas `Key('seletor_idioma_config')`, `Key('dropdown_idioma_config')`, `Key('opcao_idioma_<locale>')`, `Key('card_identidade_config')` e `Key('botao_gerenciar_identidade_config')`, adicionando cartões estruturados para:
  1. **Identidade Pericial e Chave Criptográfica**: exibe nome e clube (`IdentityRecord`), conta OIDC vinculada (`SessaoOidcIdentidade`) e o fingerprint SHA-256 truncado da chave pública ECDSA P-256 (`CryptoService`).
  2. **Governança e Termos Legais**: exibe `versaoTermosAceita` e `dataHoraAceiteTermos` (de `AppConfigRecord`), com botão para consultar os Termos de Uso e Política de Privacidade (`TelaTermosDeUso` em modo de consulta).
  3. **Suporte, Feedback e Comunidade**: botão `BotaoFeedback` para abrir a captura de tela anotada e botões externos para o WhatsApp da comunidade (`https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv`) e site oficial (`https://arestaclimb.com`) através de callback/serviço injetável para testes determinísticos.
- **Por que**: Garante que nenhum teste existente em `home_screen_test.dart` quebre e entrega uma tela de configurações completa e auditável.

### 4. Compressão Local Pré-Armazenamento (`CompressorImagemFeedback`)
- **Decisão**: Redimensionar e comprimir a captura de tela anotada antes de gravar no disco local, mantendo tamanho reduzido para transmissão rápida em redes móveis instáveis (3G/4G de aproximação).
- **Por que**: Economiza espaço de armazenamento no aparelho do auditor e evita timeouts no envio multipart.

## Risks / Trade-offs

- [Acúmulo de capturas de tela no disco] → O `ServicoFilaFeedback` remove o arquivo de imagem local imediatamente após confirmação de recebimento (HTTP 2xx) pelo servidor.
- [Paridade de tradução nos 7 idiomas] → O teste arquitetural `l10n_parity_test.dart` falha caso qualquer chave adicionada em `app_pt.arb` não esteja presente nos outros 6 idiomas ou caso `flutter gen-l10n` não tenha sido executado (com cabeçalho SPDX preservado nos arquivos gerados).
