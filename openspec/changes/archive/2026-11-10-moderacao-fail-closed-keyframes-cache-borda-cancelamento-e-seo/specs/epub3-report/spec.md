# Spec Delta

## MODIFIED Requirements

### Requirement: O sistema DEVE embutir e reproduzir múltiplos vídeos e fotos no EPUB 3
O sistema DEVE (MUST) incorporar arquivos de vídeo MP4 (codec H.264 720p CRF 26 `-preset veryfast` / áudio mono AAC 64k / faststart) e fotos em formato WebP (resolução de até 4MP e qualidade 85) no manifesto do EPUB 3, sem impor limites arbitrários à quantidade total de mídias. Os vídeos DEVEM (MUST) ser referenciados semanticamente via tags HTML5 `<video controls>` com imagem de capa (*poster frame*) estática em formato JPEG (`<uuid>_poster.jpg`) e DEVEM (MUST) ser acompanhados em `OEBPS/midias/` por miniaturas JPEG altamente comprimidas (`360p`, qualidade leve) extraídas a cada 10 segundos de vídeo (`<uuid>_kf_10s.jpg`, `<uuid>_kf_20s.jpg`, ...), todas declaradas no `content.opf` e assinadas no `META-INF/signatures.xml` para auditoria pericial e moderação de segurança no servidor.

#### Scenario: Vistoria com múltiplos vídeos e fotos de proteções
- **WHEN** a sessão de manutenção inclui vídeos e fotos documentando o estado das proteções
- **THEN** todas as mídias pré-processadas ou transcodificadas são empacotadas em `OEBPS/midias/` (incluindo `<uuid>.mp4`, `<uuid>_poster.jpg` e as miniaturas de keyframes `<uuid>_kf_<N>s.jpg` a cada 10 segundos de vídeo), assinadas em `META-INF/signatures.xml` e renderizadas com controles nativos de reprodução
