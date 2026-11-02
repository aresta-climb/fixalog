# Spec Delta

## MODIFIED Requirements

### Requirement: O sistema DEVE gerar um container EPUB 3 padronizado
O sistema DEVE compilar o relatório técnico de vistoria em um arquivo de extensão `.epub` aderente à especificação EPUB 3 (OCF/W3C), empacotando o arquivo `mimetype` sem compressão no início do arquivo, aplicando compressão `DEFLATE` aos metadados, documentos XHTML, folhas de estilo CSS, assinaturas XML e binários Protobuf, e armazenando os ativos de mídia já comprimidos (`.mp4`, `.webp`, `.jpg`, `.jpeg`, `.png`, `.pdf`) no modo `STORE` (`CompressionType.none`) para evitar recompressão redundante de CPU.

#### Scenario: Geração do container EPUB 3 com dados da vistoria
- **WHEN** o usuário conclui o preenchimento da vistoria no aplicativo e solicita a geração do relatório
- **THEN** o sistema compila um arquivo `.epub` válido onde os arquivos `.xhtml`, `.css`, `.opf`, `.xml` e `.binarypb` são comprimidos com `DEFLATE` e os arquivos de mídia em `OEBPS/midias/` e `OEBPS/materiais/` são armazenados com `CompressionType.none` (`STORE`)

### Requirement: O sistema DEVE embutir e reproduzir múltiplos vídeos e fotos no EPUB 3
O sistema DEVE incorporar arquivos de vídeo MP4 (codec H.264 720p CRF 26 `-preset veryfast` / áudio mono AAC 64k / faststart) e fotos em formato WebP (resolução de até 4MP e qualidade 85) no manifesto do EPUB 3, sem impor limites arbitrários à quantidade total de mídias. Os vídeos DEVEM ser referenciados semanticamente via tags HTML5 `<video controls>` com imagem de capa (*poster frame*) estática em formato JPEG (`<uuid>_poster.jpg`).

#### Scenario: Vistoria com múltiplos vídeos e fotos de proteções
- **WHEN** a sessão de manutenção inclui múltiplos vídeos e fotos documentando o estado das proteções, sem limitação fixa de quantidade
- **THEN** todas as mídias pré-processadas ou transcodificadas são empacotadas na pasta de mídias do EPUB e renderizadas com controles nativos de reprodução e atributo `poster` apontando para `<uuid>_poster.jpg`
