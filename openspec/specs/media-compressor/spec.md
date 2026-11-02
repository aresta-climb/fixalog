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
O sistema DEVE comprimir anexos de vídeo e áudio antes de embuti-los no documento, transcodificando vídeos para H.264 720p a 30fps com CRF 26, preset `veryfast`, áudio AAC mono 64 kbps (`+faststart`) e extraindo o *poster frame* estático aos 0.5s diretamente em formato JPEG (`<uuid>_poster.jpg`).

#### Scenario: Compressão de vídeo
- **WHEN** um vídeo é gravado ou anexado à vistoria
- **THEN** o sistema transcodifica o vídeo para 720p em H.264 utilizando `-preset veryfast` e extrai o frame de capa em `<uuid>_poster.jpg`

### Requirement: O sistema DEVE gerar Miniaturas Leves de Impressão
Durante o processamento das imagens e páginas de documentos PDF de uma sessão de vistoria, o sistema DEVE gerar, além da imagem principal em WebP de 4MP (`2048x2048`, qualidade 85) destinada ao EPUB 3, uma versão em JPEG de 2MP (`1440x1440`, qualidade 80) nomeada `<uuid>_thumb.jpg` (derivada a partir da imagem de 4MP já redimensionada), armazenada no bundle da sessão para embutimento direto e instantâneo no documento PDF Resumido.

#### Scenario: Geração da miniatura de impressão para foto
- **WHEN** uma foto ou página de PDF capturada na vistoria é processada pelo serviço de compressão da sessão
- **THEN** o sistema gera `<uuid>.webp` (até 2048x2048, q=85) a partir do arquivo original e, a partir de `<uuid>.webp`, gera `<uuid>_thumb.jpg` (até 1440x1440, q=80) sem criar arquivos `_thumb.webp` de 600px

### Requirement: Pré-processamento Assíncrono em Segundo Plano com Escrita Atômica
O sistema DEVE comprimir imagens, páginas de PDF e vídeos em segundo plano logo após o anexo no Wizard, gravando em arquivos temporários (`.tmp`) renomeados atomicamente ao concluir. Se o app fechar antes do término ou a geração final iniciar com mídias pendentes, o sistema DEVE aguardar as tarefas ativas e processar em paralelo apenas as mídias sem artefatos finais prontos.

#### Scenario: Reutilização imediata de mídia já pré-processada durante o preenchimento
- **WHEN** o usuário anexa fotos e vídeos no Wizard e o pré-processamento em segundo plano conclui a gravação atômica de `<uuid>.webp`, `<uuid>_thumb.jpg`, `<uuid>.mp4` e `<uuid>_poster.jpg` antes da assinatura final
- **THEN** ao acionar a geração do relatório, o sistema detecta os arquivos finais prontos no disco e os reutiliza imediatamente sem recomprimir ou retrancodificar

#### Scenario: Recuperação e conclusão paralela caso o app tenha sido fechado antes do término
- **WHEN** o usuário anexa mídias, o aplicativo é fechado antes do término do pré-processamento em segundo plano e o usuário reabre a sessão para gerar o relatório
- **THEN** o sistema ignora eventuais arquivos `.tmp` incompletos e processa em paralelo a partir dos arquivos `_original` apenas as mídias cujos artefatos finais ainda não existem
