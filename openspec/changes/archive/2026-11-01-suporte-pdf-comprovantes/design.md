# Design: Suporte a Upload e Empacotamento de PDFs em Comprovantes e Laudos

## Context

Conforme descrito em `proposal.md`, notas fiscais eletrônicas (DANFE/NF-e) e certificados metalúrgicos/laudos de tração frequentemente vêm em formato PDF de uma ou múltiplas páginas e podem conter assinaturas digitais externas (ex.: gov.br / ICP-Brasil). Atualmente, `ReferenciaMidia` em `registro.proto` suporta apenas `ArquivoImagem`, `ArquivoVideo` e `ArquivoAudio`, e o `WizardScreen` oferece apenas captura via câmera ou galeria de imagens para campos `IMAGE`.

O aplicativo já depende de `printing: ^5.14.3` em `app/pubspec.yaml`, que fornece `Printing.raster(Uint8List, dpi: ...)` para converter páginas de um documento PDF em imagens bitmap de forma nativa e offline.

## Goals / Non-Goals

**Goals:**
- Preservar o arquivo `.pdf` original bit-a-bit desde a seleção até o empacotamento final em `OEBPS/midias/<uuid>.pdf` dentro do EPUB 3, garantindo que assinaturas digitais originais (gov.br / ICP-Brasil) do PDF anexado permaneçam verificáveis e que o próprio `.pdf` também seja coberto pelo `META-INF/signatures.xml` do Fixalog.
- Gerar uma imagem `.webp` otimizada por página (`<uuid>_p1.webp`, `<uuid>_p2.webp`, ...) no momento da anexação do PDF, permitindo leitura imediata inline no `relatorio.xhtml` (com link para abrir/baixar o `.pdf` original) e inclusão direta de todas as páginas no PDF Resumido (`PdfGeneratorService`).
- Manter 100% de testabilidade determinística sem mocks internos (`AGENTS.md` Princípios III, IV e V), abstraindo a seleção de arquivos e a rasterização de PDF através de fronteiras injetáveis com Fakes determinísticos testados (`*_fake.dart` / `*_fake_test.dart`).

**Non-Goals:**
- Embutir um leitor de PDF nativo dentro da WebView do EPUB 3 via `<iframe src="...pdf">` (leitores EPUB e WebViews mobile não têm suporte uniforme a PDF inline; por isso renderizamos as páginas `.webp` no XHTML e fornecemos o link direto para o `.pdf` original).
- Validar criptograficamente assinaturas ICP-Brasil/gov.br internas do PDF anexado dentro do app (o Fixalog preserva o binário intacto para auditoria externa e o assina no container EPUB).

## Decisions

### 1. Modelagem Protobuf (`ArquivoDocumento` em `ReferenciaMidia`)
- **Decisão**: Adicionar a mensagem `ArquivoDocumento` em `app/protos/registro.proto` e incluí-la como `ArquivoDocumento documento = 4;` dentro do `oneof midia` de `ReferenciaMidia`:
  ```protobuf
  message ArquivoDocumento {
    string uuid = 1;
    string tipo_original = 2; // "application/pdf"
    string hash_original = 3; // SHA-256 do arquivo .pdf original intacto
    string nome_original = 4; // Ex: "nfe_chumbadores.pdf"
    int32 quantidade_paginas = 5;
    repeated string hashes_paginas_webp = 6; // SHA-256 de <uuid>_p1.webp, <uuid>_p2.webp, ...
  }
  ```
- **Racional**: Segue exatamente o mesmo padrão de rastreabilidade criptográfica de `ArquivoImagem` e `ArquivoVideo`, armazenando tanto o hash do documento matriz (`.pdf`) quanto os hashes individuais de cada página `.webp` gerada, permitindo mapear determinísticamente os arquivos `<uuid>_p1.webp` .. `<uuid>_pN.webp` sem precisar listar o diretório.
- **Alternativas consideradas**: Reutilizar `ArquivoImagem` com `tipo_original = "application/pdf"` — descartado porque um PDF pode ter múltiplas páginas (1 PDF -> $N$ imagens `.webp`), o que quebraria a cardinalidade 1:1 de `hash_webp` em `ArquivoImagem`.

### 2. Pipeline de Rasterização e Armazenamento no `SessionBundleManager`
- **Decisão**: Ao selecionar um arquivo PDF no Wizard:
  1. O arquivo original é salvo intacto na pasta da sessão como `<uuid>_original.pdf` e seu hash SHA-256 é calculado (`hash_original`).
  2. O serviço de compressão/rasterização converte cada página do PDF em uma imagem WebP salva na pasta da sessão como `<uuid>_p1.webp`, `<uuid>_p2.webp`, ..., `<uuid>_pN.webp`, calculando o SHA-256 de cada página (`hashes_paginas_webp`).
  3. Um método dedicado no `SessionBundleManager` (`processarESalvarDocumentoPdf`) coordena essa operação e retorna a `ReferenciaMidia` preenchida com `ArquivoDocumento`.
- **Racional**: Realizar a rasterização no momento do anexo (ou via `MediaCompressorService`) garante que a sessão já possua todas as páginas `.webp` prontas e validadas, mantendo a geração do EPUB 3 e do PDF Resumido rápida e uniforme.

### 3. Fronteira de Seleção de Arquivo e Rasterização Testável (Fakes Determinísticos)
- **Decisão**:
  - Criar uma interface enxuta `SeletorDocumentoService` (em `app/lib/features/media/services/seletor_documento_service.dart`) responsável por selecionar um arquivo `.pdf` do dispositivo (usando `file_picker`), acompanhada de `SeletorDocumentoServiceFake` em `app/test/` para testes de widget e integração.
  - Adicionar no `MediaCompressorService` o método `rasterizarPdfEmWebp(File arquivoPdf, Directory diretorioDestino, String uuid)` (com callback/rasterizador injetável que por padrão usa `Printing.raster` a ~150 DPI e codifica em WebP/imagem otimizada), permitindo que `MediaCompressorServiceFake` gere páginas `.webp` determinísticas em memória/disco temporário durante os testes.
- **Racional**: Cumpre estritamente o Princípio V do `AGENTS.md` (Fidelidade de Produção e Bibliotecas `test-only` de Fakes Determinísticos com espelhamento 1:1).

### 4. Representação no EPUB 3 (`EpubGeneratorService`) e Visualizador
- **Decisão**:
  - Copiar `<uuid>_original.pdf` para `OEBPS/midias/<uuid>.pdf` e declarar no `content.opf` com `media-type="application/pdf"`.
  - Copiar cada `<uuid>_p<i+1>.webp` para `OEBPS/midias/<uuid>_p<i+1>.webp` e declarar no `content.opf` com `media-type="image/webp"`.
  - Todos esses arquivos (`OEBPS/midias/<uuid>.pdf` e `OEBPS/midias/<uuid>_p<i+1>.webp`) entram automaticamente na árvore de assinatura `META-INF/signatures.xml`.
  - No `relatorio.xhtml` (tanto no corpo principal quanto na seção de comprovantes de `CatalogoMateriais`), renderizar um bloco `.documento-pdf-container` contendo:
    - Um cabeçalho/botão de ação com link `<a href="midias/<uuid>.pdf" download="<nome_original>" class="link-pdf-original">📄 Baixar / Abrir PDF Original (<nome_original>)</a>`.
    - A sequência de imagens `<img src="midias/<uuid>_p1.webp" ... />`, `<img src="midias/<uuid>_p2.webp" ... />` identificadas com `"Página k de N"`.
  - Na tela de visualização do relatório (`EpubViewerScreen`), interceptar cliques em links `.pdf` locais para abrir/compartilhar o arquivo PDF original extraído usando o visualizador/compartilhador do sistema (`Printing.sharePdf` ou `Share.shareXFiles`), permitindo que o perito verifique o PDF original com assinatura gov.br diretamente pelo app.

### 5. Representação no PDF Resumido (`PdfGeneratorService`)
- **Decisão**: Quando uma `ReferenciaMidia` (ou comprovante de `ItemMaterial` / `TesteQualidadeMaterial`) contiver `documento`, o `PdfGeneratorService` carrega todas as imagens `<uuid>_p1.webp` .. `<uuid>_pN.webp` da sessão e as renderiza em sequência no documento PDF resumido, acompanhadas do cabeçalho com o `nome_original` do documento e o indicador `"Página k de N"`.

## Risks / Trade-offs

- **[Risk] PDFs com muitas páginas aumentando o tempo de anexo ou tamanho do pacote** → **Mitigação**: Rasterizar em resolução equilibrada de leitura documental (150 DPI) e comprimir em WebP (qualidade 80), mantendo cada página A4 de texto/nota fiscal com ~50–120 KB, além de exibir indicador de carregamento durante o processamento do documento.
- **[Risk] PDF corrompido ou protegido por senha selecionado pelo usuário** → **Mitigação**: Capturar falhas de rasterização no serviço, exibir mensagem clara em português ao usuário (`SnackBar`) e não adicionar referência inválida à sessão.
