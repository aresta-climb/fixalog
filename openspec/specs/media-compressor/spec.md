# Media Compressor

## Purpose

Serviço de processamento e compressão de mídias (fotos, vídeos e áudio) para otimização de armazenamento e transmissão nos relatórios do FixLog.

## Requirements

### Requirement: O sistema DEVE realizar Compressão de Imagens
O sistema DEVE comprimir imagens adicionadas ao documento para otimizar o tamanho final do arquivo gerado, mantendo a legibilidade.

#### Scenario: Compressão de foto
- **WHEN** uma foto é adicionada ao laudo
- **THEN** o sistema comprime a imagem para WebP mantendo resolução legível

### Requirement: O sistema DEVE realizar Compressão de Vídeo/Áudio
O sistema DEVE comprimir anexos de vídeo e áudio antes de embuti-los no documento, adequando-se aos limites de tamanho especificados para os relatórios.

#### Scenario: Compressão de vídeo
- **WHEN** um vídeo é gravado ou anexado à vistoria
- **THEN** o sistema transcodifica o vídeo para 720p em H.264

### Requirement: O sistema DEVE gerar Miniaturas Leves de Impressão
Durante o processamento das imagens de uma sessão de vistoria, o sistema MUST gerar, além da imagem principal de alta resolução, uma miniatura de impressão compacta (máximo 600x600 px em formato WebP) armazenada no bundle da sessão, destinada à renderização e conversão rápida de documentos impressos.

#### Scenario: Geração da miniatura de impressão para foto
- **WHEN** uma foto capturada na vistoria é processada pelo serviço de compressão da sessão
- **THEN** o sistema gera e salva a miniatura `<uuid>_thumb.webp` no diretório da sessão com tamanho reduzido (< 50 KB)
