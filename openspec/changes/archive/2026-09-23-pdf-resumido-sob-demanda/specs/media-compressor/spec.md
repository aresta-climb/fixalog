## ADDED Requirements

### Requirement: O sistema DEVE gerar Miniaturas Leves de Impressão
Durante o processamento das imagens de uma sessão de vistoria, o sistema MUST gerar, além da imagem principal de alta resolução, uma miniatura de impressão compacta (máximo 600x600 px em formato WebP) armazenada no bundle da sessão, destinada à renderização e conversão rápida de documentos impressos.

#### Scenario: Geração da miniatura de impressão para foto
- **WHEN** uma foto capturada na vistoria é processada pelo serviço de compressão da sessão
- **THEN** o sistema gera e salva a miniatura `<uuid>_thumb.webp` no diretório da sessão com tamanho reduzido (< 50 KB)
