# Proposta: Suporte Multilinguagem e Internacionalização Completa (i18n/l10n)

## Why

O Fixalog será utilizado por conquistadores, mantenedores e federações de escalada fora do Brasil, exigindo que toda a experiência do aplicativo opere nativamente em múltiplos idiomas mantendo a operação 100% offline na montanha e a integridade pericial dos laudos gerados. Padronizar desde já os 7 idiomas (`pt`, `en`, `es`, `fr`, `de`, `ar`, `ja`), os identificadores canônicos de protocolo em inglês e a tipografia universal com a família Google Noto Sans garante cobertura para escrita latina expandida (alemão), direita-para-esquerda/RTL (árabe) e ideogramas CJK (japonês) na interface, nos protocolos YAML, nos termos legais e nos relatórios EPUB 3 e PDF Resumido.

## What Changes

- **Governança de Engenharia (`AGENTS.md`)**:
  - Atualização do **Princípio I (Tudo em Português)** para formalizar a exceção de internacionalização: todo o código-fonte Dart, testes, docstrings e especificações OpenSpec permanecem obrigatoriamente em português brasileiro (PT-BR), enquanto **identificadores técnicos canônicos de protocolos e persistência (wire format)** devem ser em **inglês** e **arquivos de localização (`.arb`, `i18n/*.yaml`, documentos legais `.md`)** contêm as traduções nos respectivos idiomas suportados.
- **Infraestrutura de Localização da UI (Camada 1) e Persistência de Idioma**:
  - Suporte oficial a 7 idiomas: Português (`pt`), Inglês (`en`), Espanhol (`es`), Francês (`fr`), Alemão (`de`), Árabe (`ar` — RTL) e Japonês (`ja` — CJK), com **fallback padrão para Inglês (`en`)** quando o idioma do sistema operacional não estiver entre os 7 suportados.
  - Integração do `flutter_localizations` e `intl` com arquivos `.arb` (`app/lib/core/l10n/arb/app_<locale>.arb`) e geração estática via `flutter gen-l10n` em `app/lib/core/l10n/generated/` (com cabeçalho SPDX MPL-2.0 automático e isenção de codegen em `test_structure_mirror_test.dart`).
  - Persistência da preferência de idioma do usuário no banco local SQLite (`AppConfigRecord.idiomaPreferido` na tabela `configuracao_app`), com seletor de idioma no topo da `TelaTermosDeUso` (primeiro acesso) e na aba de Configurações.
- **Catálogo de Protocolos YAML Multilíngue com IDs Canônicos em Inglês (Camada 2)**:
  - **BREAKING (Wire Format de Protocolos)**: Migração dos arquivos YAML estruturais em `app/assets/protocols/` para utilizar identificadores técnicos canônicos em inglês (`id` de protocolo, blocos, steps, conteúdos e `valor` de opções de dropdown/ramos), mantendo compatibilidade retroativa de leitura para sessões antigas.
  - Criação de dicionários de tradução por idioma em `app/assets/protocols/i18n/<locale>/<protocol_id>.yaml` separados da definição estrutural única do protocolo.
  - Evolução do `ProtocolParser` para injetar os textos traduzidos (`nome`, `descricao`, `titulo`, `subtitulo`, `corpo`, `label`, `sublabel`) do idioma ativo no objeto `DefinicaoProtocolo` (Protobuf) com fallback para `en`/`pt`.
- **Laudos Periciais EPUB 3 e PDF Resumido no Idioma do Usuário + Padronização Google Noto Sans (Camada 3)**:
  - Padronização tipográfica universal com a família **Google Noto Sans** (`NotoSans`, `NotoSansArabic`, `NotoSansJP` em `app/assets/fonts/`) compartilhada entre a UI do App (Android/iOS, substituindo as referências inexistentes a `SpaceGrotesk` e `Inter`), o EPUB 3 e o PDF Resumido.
  - Geração estática dos relatórios EPUB 3 (`EpubDocumentBuilder`, `EpubPackagerService`) e PDF Resumido (`PdfPrintSummaryService`) no idioma ativo do usuário no momento da emissão, traduzindo cabeçalhos e resolvendo rótulos de campos e valores de opções a partir do dicionário do protocolo (enquanto o `registro.binarypb` preserva os IDs canônicos em inglês).
  - Empacotamento seletivo da fonte `Noto Sans` correspondente ao idioma do relatório dentro de `OEBPS/fonts/` no pacote `.epub` (declarada via `@font-face` no `estilo.css`, listada no `content.opf` com `media-type="font/ttf"` e assinada criptograficamente no `META-INF/signatures.xml`) e suporte completo a `dir="rtl"` / `pw.TextDirection.rtl` para Árabe.
- **Documentos Legais Multilíngues (Camada 4)**:
  - Tradução dos Termos de Uso e da Política de Privacidade em `legal/repo/public/docs/<locale>/` para os 7 idiomas suportados.
  - Padronização do link interno para a Política de Privacidade usando alvo canônico (`#privacy-policy`), eliminando o acoplamento à palavra `"privacidade"` na `TelaTermosDeUso`.

## Capabilities

### New Capabilities
- `internacionalizacao-app`: Infraestrutura central de internacionalização nos 7 idiomas (`pt`, `en`, `es`, `fr`, `de`, `ar`, `ja`), detecção de locale com fallback para `en`, persistência no `AppConfigRecord`, tipografia universal `Noto Sans`, tradução da UI via `.arb` e resolução de dicionários i18n para protocolos YAML com IDs canônicos em inglês.

### Modified Capabilities
- `onboarding-terms`: Exibição dos Termos de Uso e Política de Privacidade no idioma ativo, seletor de idioma no topo da tela inicial de aceite e interceptação do link de privacidade por âncora canônica independente do idioma.
- `epub3-report`: Emissão do documento EPUB 3 no idioma ativo do usuário (`lang` e `dir="rtl"` quando aplicável), exibição de rótulos e opções traduzidos do protocolo e empacotamento seletivo das fontes `Noto Sans` do idioma do laudo em `OEBPS/fonts/` cobertas pela assinatura digital XML-DSig.
- `pdf-generator`: Emissão do PDF Resumido A4 no idioma ativo do usuário com rótulos e opções traduzidos, suporte a direção RTL para árabe e carregamento offline das fontes TTF locais da família `Noto Sans` (`NotoSans`, `NotoSansArabic`, `NotoSansJP`).

## Impact

- **Governança e Arquitetura**:
  - `AGENTS.md`: atualização do Princípio I.
  - `app/test/architecture/test_structure_mirror_test.dart`: inclusão de `core/l10n/generated/` na lista de diretórios de codegen ignorados pelo espelhamento 1:1.
- **Dependências e Assets (`app/pubspec.yaml` e `app/l10n.yaml`)**:
  - Adição de `flutter_localizations` (SDK) e `intl` em `dependencies`, flag `generate: true` e declaração da família `NotoSans` (`NotoSans-Regular.ttf`, `NotoSans-Bold.ttf`, `NotoSansArabic-Regular.ttf`, `NotoSansArabic-Bold.ttf`, `NotoSansJP-Regular.ttf`, `NotoSansJP-Bold.ttf`) em `app/assets/fonts/`.
  - Novos diretórios de assets: `app/assets/protocols/i18n/<locale>/` e `legal/repo/public/docs/<locale>/`.
- **Banco de Dados e Modelos Locais**:
  - `app/lib/core/models/local/app_config_record.dart` e `app/lib/core/services/banco_dados_local.dart`: adição da coluna `idioma_preferido` (migração incremental segura da tabela `configuracao_app`).
- **Serviços Core e Telas**:
  - `app/lib/core/services/protocol_parser.dart`, `epub_document_builder.dart`, `epub_packager_service.dart`, `pdf_print_summary_service.dart`, `pdf_report_service.dart`.
  - Telas em `app/lib/main.dart`, `app/lib/features/onboarding/`, `app/lib/features/identity/`, `app/lib/features/home/`, `app/lib/features/wizard/` e `app/lib/features/pdf_generation/`.
