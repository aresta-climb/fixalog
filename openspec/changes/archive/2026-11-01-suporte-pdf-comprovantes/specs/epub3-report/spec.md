## ADDED Requirements

### Requirement: Empacotamento de Documentos PDF Originais e Páginas Rasterizadas no EPUB 3
Quando o registro contiver um documento PDF anexado (`ArquivoDocumento`), o gerador de EPUB 3 DEVE empacotar o binário original intacto em `OEBPS/midias/<uuid>.pdf` (declarado no `content.opf` com `media-type="application/pdf"` e assinado no `META-INF/signatures.xml`) e empacotar cada página rasterizada em `OEBPS/midias/<uuid>_p<N>.webp`, exibindo todas as páginas sequencialmente no `relatorio.xhtml` junto a um link direto para abrir ou baixar o documento PDF original.

#### Scenario: Geração de EPUB 3 com nota fiscal em PDF assinado de múltiplas páginas
- **WHEN** um relatório EPUB 3 é gerado contendo uma nota fiscal anexada em formato PDF com 2 páginas
- **THEN** o pacote EPUB 3 inclui `OEBPS/midias/<uuid>.pdf` preservado bit-a-bit (mantendo eventual assinatura gov.br/ICP-Brasil) e as imagens `OEBPS/midias/<uuid>_p1.webp` e `OEBPS/midias/<uuid>_p2.webp`
- **THEN** o `META-INF/signatures.xml` inclui os resumos SHA-256 tanto do `.pdf` original quanto de cada `.webp` de página
- **THEN** o `relatorio.xhtml` renderiza as imagens das 2 páginas na ordem correta e exibe um link apontando para `midias/<uuid>.pdf`
