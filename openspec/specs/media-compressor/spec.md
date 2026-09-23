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
