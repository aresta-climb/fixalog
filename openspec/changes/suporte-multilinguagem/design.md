# Design: Suporte Multilinguagem e Internacionalização Completa (i18n/l10n)

## Context

Atualmente o Fixalog possui textos em português brasileiro hardcoded diretamente nos widgets de UI (`main.dart`, `HomeScreen`, `IdentitySetupScreen`, `TelaTermosDeUso`, `WizardScreen`), nos 5 protocolos YAML em `app/assets/protocols/`, nos documentos legais em `legal/repo/public/docs/` e nos construtores de laudos (`EpubDocumentBuilder`, `EpubPackagerService`, `PdfPrintSummaryService`, `PdfReportService`). Além disso:
- O `ThemeData` em `app/lib/main.dart` referencia `SpaceGrotesk` e `Inter`, mas não há fontes embutidas no `pubspec.yaml`.
- O `PdfPrintSummaryService` usa `package:pdf` sem tema de fontes customizado, caindo na fonte interna *Helvetica* (restrita a Latin-1), que falha ao renderizar caracteres em Árabe (`ar`) ou Japonês (`ja`).
- O `test_structure_mirror_test.dart` e o `license_headers_test.dart` exigem espelhamento 1:1 e cabeçalho SPDX MPL-2.0 para todo arquivo autoral em `app/lib/`.

Consulte `proposal.md` para a motivação e escopo funcional.

## Goals / Non-Goals

**Goals:**
- Suportar 7 idiomas desde a base (`pt`, `en`, `es`, `fr`, `de`, `ar`, `ja`) com fallback automático para Inglês (`en`).
- Manter o código-fonte Dart, testes e especificações OpenSpec em português brasileiro (PT-BR), padronizando os identificadores técnicos canônicos de protocolos e persistência (wire format) em inglês (atualizando o Princípio I do `AGENTS.md`).
- Garantir que o pacote `.epub` assinado e o PDF Resumido sejam 100% autocontidos e determinísticos no idioma ativo do usuário no momento da emissão, usando a família **Google Noto Sans** em todas as plataformas (Android, iOS, EPUB 3 e PDF).
- Preservar 100% de cobertura comportamental e conformidade com `test_structure_mirror_test.dart` e `license_headers_test.dart`.

**Non-Goals:**
- Reescrever nomes de classes, métodos ou variáveis do código-fonte Dart existente para inglês.
- Permitir que um arquivo `.epub` já emitido e assinado criptograficamente mude de idioma após a assinatura (o laudo pericial é um artefato estático no idioma em que foi gerado).
- Baixar fontes ou traduções da internet em tempo de execução (tudo deve operar 100% offline na montanha).

## Decisions

### 1. Mecanismo de Localização da UI (Camada 1): `flutter_localizations` + `.arb` (`flutter gen-l10n`)
- **Decisão**: Utilizar o mecanismo oficial do Flutter (`flutter_localizations` + `intl` + arquivos `.arb` em `app/lib/core/l10n/arb/app_<locale>.arb`) gerando código estático em `app/lib/core/l10n/generated/` via `l10n.yaml`.
- **Configuração para Conformidade Arquitetural**:
  - Configurar `header` no `app/l10n.yaml` com as duas linhas SPDX/MPL-2.0 (`// SPDX-License-Identifier: MPL-2.0` e `// Copyright (c) 2026 Fixalog Contributors`) para satisfazer `license_headers_test.dart`.
  - Adicionar `relativePath.startsWith('core/l10n/generated/')` na lista de artefatos de codegen ignorados em `app/test/architecture/test_structure_mirror_test.dart` (ao lado de `.g.dart` e `.pb.dart`).
  - Criar um módulo autoral enxuto `app/lib/core/l10n/ resolvedor_idioma.dart` (com seu respectivo `resolvedor_idioma_test.dart`) responsável pela regra de negócio de resolução do locale (preferência salva no SQLite → locale do SO se suportado → fallback `Locale('en')`) e um Provedor Riverpod (`idiomaAtivoProvider`) observado pelo `MaterialApp`.
- **Alternativas consideradas**: Dicionários dinâmicos em YAML/JSON para a UI foram descartados em favor do `.arb` para garantir verificação de chaves em tempo de compilação e integração nativa com os delegates de Material/Cupertino (calendários `DATE` e espelhamento `RTL` automático no Árabe).

### 2. Persistência de Preferência de Idioma no SQLite (`AppConfigRecord`)
- **Decisão**: Adicionar o campo `String? idiomaPreferido` (coluna `idioma_preferido TEXT` na tabela `configuracao_app`) em `AppConfigRecord` e migração incremental (`ALTER TABLE configuracao_app ADD COLUMN idioma_preferido TEXT`) em `BancoDadosLocal`.
- **Racional**: Centraliza as configurações globais do dispositivo na tabela singleton existente usada logo no boot (`_StartupRouter` em `main.dart`), permitindo que a troca de idioma funcione imediatamente já na `TelaTermosDeUso` antes mesmo de existir identidade pericial criada.

### 3. Protocolos YAML (Camada 2): Estrutura Canônica Única em Inglês + Dicionários Sidecar por Idioma
- **Decisão**:
  - Manter um único arquivo estrutural por protocolo em `app/assets/protocols/` contendo apenas a lógica, tipos (`TEXT`, `DROPDOWN`, `IMAGE`, `VIDEO`, `GPS`, `DATE`, `BOOLEAN`), obrigatoriedade e identificadores técnicos canônicos em inglês (ex.: `route_opening_v1`, `visual_inspection_v1`, `hardware_maintenance_v1`, `material_catalog`, `express_log_v1`).
  - Armazenar os textos traduzíveis em arquivos por idioma em `app/assets/protocols/i18n/<locale>/<protocol_id>.yaml`, estruturados como um mapa plano ou hierárquico indexado pelos IDs canônicos:
    ```yaml
    protocolo:
      nome: "Route Opening"
      descricao: "Technical record of new climbing route development."
    blocos:
      route_identification:
        titulo: "Route Identification"
        subtitulo: "Technical data of the new line."
    conteudos:
      route_name:
        label: "Suggested Name"
        sublabel: "Name given to the route by the first ascensionist(s)."
    opcoes:
      stainless_steel_316:
        label: "316 Stainless Steel"
    ```
  - O `ProtocolParser.fromYaml(String yamlContent, {Map<String, dynamic>? traducoes})` aplica o overlay de tradução (com fallback para os textos padrão em inglês do YAML estrutural) e retorna o mesmo `DefinicaoProtocolo` (Protobuf) já consumido pelo `WizardStateController` e `WizardScreen`.
  - Para manter compatibilidade retroativa com rascunhos/sessões antigas já salvas no SQLite com IDs legados em português, um mapeador de compatibilidade preserva a leitura de sessões existentes.
- **Alternativas consideradas**: Duplicar os 5 YAMLs completos 7 vezes (35 arquivos) foi descartado pelo alto risco de divergência estrutural (especialmente em `cadastro_material.yaml`, que possui 703 linhas). Mapas inline de 7 idiomas no mesmo arquivo também foram descartados por inflarem `cadastro_material.yaml` para mais de 3.500 linhas.

### 4. Padronização Universal com Google Noto Sans e Empacotamento Seletivo nos Laudos (Camada 3)
- **Decisão**:
  - Incluir em `app/assets/fonts/` os arquivos TTF estáticos sob licença SIL OFL:
    - `NotoSans-Regular.ttf` e `NotoSans-Bold.ttf` (cobre `pt`, `en`, `es`, `fr`, `de`).
    - `NotoSansArabic-Regular.ttf` e `NotoSansArabic-Bold.ttf` (cobre `ar`).
    - `NotoSansJP-Regular.ttf` e `NotoSansJP-Bold.ttf` (cobre `ja`).
  - **Na UI (Android/iOS)**: Declarar a família `NotoSans` no `pubspec.yaml` e no `ThemeData` global, removendo todas as referências hardcoded a `SpaceGrotesk` e `Inter`.
  - **No EPUB 3 (`EpubDocumentBuilder` + `EpubPackagerService`)**:
    - Gerar `relatorio.xhtml` e `nav.xhtml` com `lang="<locale>"` e, quando `locale == 'ar'`, adicionar `dir="rtl"`.
    - Resolver os nomes dos campos (`chave`) e os valores de opções/ramos a partir do dicionário do protocolo no idioma ativo, exibindo rótulos humanos traduzidos no XHTML enquanto `OEBPS/dados/registro.binarypb` conserva os IDs canônicos em inglês.
    - Incluir em `OEBPS/fonts/` **apenas** os arquivos `.ttf` necessários para o idioma do relatório gerado (`NotoSans` sempre; `+ NotoSansArabic` se `ar`; `+ NotoSansJP` se `ja`), declarados via `@font-face` no `OEBPS/estilo.css`, listados no `<manifest>` do `OEBPS/content.opf` com `media-type="font/ttf"`, comprimidos com `DEFLATE` no ZIP e assinados no `META-INF/signatures.xml`.
  - **No PDF Resumido (`PdfPrintSummaryService` + `PdfReportService`)**:
    - Carregar sob demanda via `rootBundle` os mesmos arquivos `.ttf` de `assets/fonts/` para o idioma do relatório, configurando `pw.ThemeData.withFont(base: ..., bold: ..., fontFallback: [...])` e envolvendo a página em `pw.Directionality(textDirection: pw.TextDirection.rtl)` quando `locale == 'ar'`.

### 5. Documentos Legais Multilíngues e Âncora Canônica (Camada 4)
- **Decisão**: Organizar os arquivos Markdown em `legal/repo/public/docs/<locale>/termos-de-uso-fixalog.md` e `politica-de-privacidade-fixalog.md` para os 7 idiomas (mantendo cópia ou fallback em `en`) e padronizar o link interno para a Política de Privacidade nos 7 arquivos usando `[...](#privacy-policy)`. Na `TelaTermosDeUso`, detectar `link == '#privacy-policy' || link.contains('politica-de-privacidade')`.

## Risks / Trade-offs

- **[Risco] Tamanho do binário da fonte japonesa (`NotoSansJP`) nos assets** → **Mitigação**: Empacotar apenas os pesos `Regular` e `Bold` estáticos nos assets do app e só injetar `NotoSansJP` dentro dos pacotes `.epub` e `.pdf` quando o relatório for efetivamente emitido em Japonês (`ja`) ou contiver caracteres CJK.
- **[Risco] Expansão de texto em Alemão (`de`) com `TextScaler` de `1.25x` causar overflow em botões/barras** → **Mitigação**: Usar `Flexible`/`Expanded` e testes de widget parametrizados nos 7 idiomas (incluindo `de` e `ar`) para validar ausência de `RenderFlex overflowed`.
- **[Risco] Chave ausente em algum dos 7 arquivos `.arb` ou dicionários YAML de protocolo** → **Mitigação**: Criar um teste automatizado de arquitetura/contrato que verifica paridade 100% de chaves entre os 7 idiomas tanto para `.arb` quanto para `assets/protocols/i18n/<locale>/*.yaml`.

## Migration Plan

1. Atualizar `AGENTS.md` (Princípio I) e `test_structure_mirror_test.dart`.
2. Adicionar fontes `NotoSans*` em `app/assets/fonts/` e configurar `l10n.yaml` + `.arb` para os 7 idiomas.
3. Evoluir `AppConfigRecord` e `BancoDadosLocal` (versão do schema SQLite com `ALTER TABLE` seguro para `idioma_preferido`).
4. Migrar os 5 protocolos YAML para IDs canônicos em inglês com dicionários `i18n/<locale>/` e atualizar `ProtocolParser`.
5. Internacionalizar `EpubDocumentBuilder`, `EpubPackagerService` e `PdfPrintSummaryService` com resolução de rótulos, suporte RTL e fontes `Noto Sans`.
6. Internacionalizar `TelaTermosDeUso` (com documentos legais nos 7 idiomas e seletor no topo) e demais telas da UI (`IdentitySetupScreen`, `HomeScreen`, `NewProtocolScreen`, `HistoryScreen`, `WizardScreen`, `VisualizadorRelatorioScreen`).
