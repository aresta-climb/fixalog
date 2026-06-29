## ADDED Requirements

### Requirement: Compressão de Imagens
O sistema DEVE reduzir o tamanho, dimensão e qualidade de imagens capturadas (fotos) antes da persistência final, a fim de minimizar o armazenamento e o tamanho do PDF final.

#### Scenario: Compressão padrão de imagem
- **WHEN** uma imagem em alta resolução é recebida da câmera
- **THEN** o sistema a comprime e retorna o caminho temporário do arquivo leve

### Requirement: Compressão e Transcodificação de Vídeo/Áudio
O sistema DEVE transcodificar vídeos gravados (H.264, bitrate controlado) e áudios (AAC/m4a) localmente usando bibliotecas aceleradas por hardware (ex: `ffmpeg_kit_flutter`) para garantir empacotamento rápido e tamanho de PDF aceitável.

#### Scenario: Compressão de vídeo longo
- **WHEN** um vídeo de 100MB é capturado
- **THEN** o FFmpeg transcodifica em background retornando um arquivo de ~10MB sem travar a thread da UI
