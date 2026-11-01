## Why

Atualmente, os campos de "Foto ou PDF da Nota Fiscal / Comprovante" e de anexos de "Testes de Qualidade" no cadastro de lotes de materiais (`CatalogoMateriais`) aceitam apenas captura de imagem via câmera ou seleção de foto na galeria (`FieldType.IMAGE`). Na prática, notas fiscais eletrônicas (DANFE/NF-e), certificados de conformidade metalúrgica (inox 316L/titânio) e laudos laboratoriais de tração/cisalhamento frequentemente são emitidos como documentos PDF — muitas vezes contendo múltiplas páginas e assinaturas digitais oficiais (como gov.br ou ICP-Brasil). Converter manualmente esses PDFs em fotos fora do aplicativo degrada a legibilidade, perde páginas e destrói a assinatura digital original do documento.

## What Changes

- **Suporte a Documentos PDF no Protobuf (`ArquivoDocumento`)**: Extensão de `ReferenciaMidia` em `registro.proto` com a variante `ArquivoDocumento documento = 4`, armazenando UUID, tipo original (`application/pdf`), hash SHA-256 do PDF original intacto, nome original do arquivo, quantidade de páginas e a lista ordenada de hashes SHA-256 das páginas rasterizadas em WebP (`<uuid>_p1.webp`, `<uuid>_p2.webp`, ...).
- **Novo Tipo de Campo ou Suporte a PDF no Wizard (`FieldType.DOCUMENT_OR_IMAGE`)**: Permite que campos de comprovante fiscal e anexos de laudos de qualidade ofereçam três opções no modal de captura: Tirar Foto (Câmera), Escolher da Galeria (Imagem) ou Selecionar Arquivo PDF.
- **Rasterização Multi-página e Compressão Determinística**: Ao anexar um arquivo PDF, o serviço de mídia preserva o binário `.pdf` original bit-a-bit na sessão e rasteriza cada página do PDF (via `Printing.raster`) em imagens `.webp` individuais (`<uuid>_p1.webp`, `<uuid>_p2.webp`, ...) para exibição visual imediata no relatórios.
- **Empacotamento Híbrido no EPUB 3 (`OEBPS/midias/<uuid>.pdf` + `<uuid>_p<N>.webp`)**: O pacote EPUB 3 passa a incluir tanto o arquivo `.pdf` original intacto (declarado no `content.opf` com `media-type="application/pdf"` e assinado no `META-INF/signatures.xml`) quanto todas as páginas `.webp` renderizadas diretamente no corpo do `relatorio.xhtml`, acompanhadas de um link explícito para abrir/baixar o documento PDF original assinado.
- **Inclusão Integral no PDF Resumido**: O gerador de PDF (`PdfGeneratorService`) renderiza sequencialmente todas as páginas `.webp` derivadas dos documentos PDF anexados em Notas Fiscais e Testes de Qualidade.

## Capabilities

### New Capabilities
*(Nenhuma capacidade totalmente nova; as capacidades existentes serão expandidas).*

### Modified Capabilities
- `catalogo-materiais`: Atualização dos campos de anexo de Nota Fiscal / Comprovante e de Testes de Qualidade para aceitar documentos PDF (além de fotos) e persistir `ArquivoDocumento` no `RegistroMaterial`.
- `unified-wizard-engine`: Suporte à seleção de arquivos `.pdf` no fluxo de captura de mídia/documento do Wizard, com pré-visualização e armazenamento no `SessionBundleManager`.
- `epub3-report`: Empacotamento do binário `.pdf` original intacto em `OEBPS/midias/<uuid>.pdf`, declaração no manifesto OPF, assinatura no `META-INF/signatures.xml`, exibição das páginas `<uuid>_p<N>.webp` no XHTML e link para o PDF original.
- `pdf-generator`: Renderização de todas as páginas rasterizadas (`<uuid>_p1.webp` .. `<uuid>_pN.webp`) dos comprovantes e laudos em PDF dentro do relatório PDF resumido.

## Impact

- **Protobuf (`app/protos/registro.proto`)**: Adição da mensagem `ArquivoDocumento` e do campo `documento = 4` no `oneof midia` de `ReferenciaMidia`.
- **Serviços de Mídia e Wizard (`app/lib/features/media/`, `app/lib/features/wizard/`)**: Novo seletor injetável de documentos PDF, rasterização de páginas PDF para WebP e suporte no `SessionBundleManager` e `WizardScreen`.
- **Geradores de Relatório (`app/lib/features/export/`)**: Atualização de `EpubGeneratorService` e `PdfGeneratorService` para incluir os arquivos `.pdf` originais e suas páginas `.webp` nos relatórios de materiais e de manutenção.
- **Dependências**: Uso do pacote `printing` (já presente em `pubspec.yaml`) para rasterização das páginas do PDF e `file_picker` (ou abstração nativa compatível) para seleção de arquivos `.pdf`.
