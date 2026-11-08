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
O sistema DEVE (MUST) comprimir anexos de vídeo e áudio antes de embuti-los no documento, transcodificando vídeos para H.264 720p a 30fps com CRF 26, preset `veryfast`, intervalo de *keyframe* fixo `-g 300` (garantindo exato 1 *I-Frame* a cada 10 segundos), áudio AAC mono 64 kbps (`+faststart`), aplicando corte opcional de trecho (`-ss <inicio> -t <duracao>`) quando selecionado pelo usuário e extraindo o *poster frame* estático aos 0.5s do trecho final diretamente em formato JPEG (`<uuid>_poster.jpg`).

#### Scenario: Compressão de vídeo
- **WHEN** um vídeo é gravado ou anexado à vistoria
- **THEN** o sistema transcodifica o vídeo para 720p em H.264 utilizando `-preset veryfast -g 300` e extrai o frame de capa em `<uuid>_poster.jpg`

#### Scenario: Compressão de trecho selecionado de um vídeo longo
- **WHEN** o usuário seleciona o intervalo de 15s a 75s (`inicio = 15s`, `duracao = 60s`) de um vídeo original mais longo
- **THEN** o sistema transcodifica exclusivamente o trecho de 60 segundos via `-ss 15 -t 60` com `-g 300` e extrai o `<uuid>_poster.jpg` correspondente ao trecho cortado

### Requirement: O sistema DEVE gerar Miniaturas Leves de Impressão
Durante o processamento das imagens e páginas de documentos PDF de uma sessão de vistoria, o sistema DEVE gerar, além da imagem principal em WebP de 4MP (`2048x2048`, qualidade 85) destinada ao EPUB 3, uma versão em JPEG de 2MP (`1440x1440`, qualidade 80) nomeada `<uuid>_thumb.jpg` (derivada a partir da imagem de 4MP já redimensionada), armazenada no bundle da sessão para embutimento direto e instantâneo no documento PDF Resumido.

#### Scenario: Geração da miniatura de impressão para foto
- **WHEN** uma foto ou página de PDF capturada na vistoria é processada pelo serviço de compressão da sessão
- **THEN** o sistema gera `<uuid>.webp` (até 2048x2048, q=85) a partir do arquivo original e, a partir de `<uuid>.webp`, gera `<uuid>_thumb.jpg` (até 1440x1440, q=80) sem criar arquivos `_thumb.webp` de 600px

### Requirement: Pré-processamento Assíncrono em Segundo Plano com Escrita Atômica
O sistema DEVE comprimir imagens, páginas de PDF e vídeos em segundo plano logo após o anexo no Wizard e também ao carregar qualquer sessão existente para edição ou retomada (`loadSession`), gravando em arquivos temporários (`.tmp`) renomeados atomicamente ao concluir. Se o app fechar antes do término ou a geração final iniciar com mídias pendentes, o sistema DEVE aguardar as tarefas ativas e processar em paralelo apenas as mídias sem artefatos finais prontos.

#### Scenario: Reutilização imediata de mídia já pré-processada durante o preenchimento
- **WHEN** o usuário anexa fotos e vídeos no Wizard e o pré-processamento em segundo plano conclui a gravação atômica de `<uuid>.webp`, `<uuid>_thumb.jpg`, `<uuid>.mp4` e `<uuid>_poster.jpg` antes da assinatura final
- **THEN** ao acionar a geração do relatório, o sistema detecta os arquivos finais prontos no disco e os reutiliza imediatamente sem recomprimir ou retrancodificar

#### Scenario: Disparo de pré-processamento ao abrir relatório existente para edição
- **WHEN** o usuário abre um rascunho ou relatório existente para edição e alguma foto, vídeo ou documento PDF da sessão ainda não possui seus artefatos finais pré-processados em disco
- **THEN** o sistema dispara automaticamente em segundo plano o pré-processamento apenas das mídias pendentes enquanto o usuário navega pelo Wizard

#### Scenario: Recuperação e conclusão paralela caso o app tenha sido fechado antes do término
- **WHEN** o usuário anexa mídias, o aplicativo é fechado antes do término do pré-processamento em segundo plano e o usuário reabre a sessão para gerar o relatório
- **THEN** o sistema ignora eventuais arquivos `.tmp` incompletos e processa em paralelo a partir dos arquivos `_original` apenas as mídias cujos artefatos finais ainda não existem

### Requirement: Limite de 60 Segundos por Vídeo com Seletor de Trecho Unificado (`SeletorTrechoVideoDialog`)
Cada vídeo anexado a um relatório DEVE (MUST) possuir duração final máxima de **60 segundos (1 minuto)**. Tanto na captura direta pela câmera (`ImageSource.camera`) quanto na seleção da galeria (`pickMultipleMedia`), o aplicativo NÃO DEVE (MUST NOT) interromper abruptamente a gravação da câmera aos 60 segundos e DEVE (MUST) continuar salvando o vídeo bruto completo na galeria do dispositivo (`salvarVideoNoRoloDaCamera`). Após a captura ou seleção, o sistema DEVE (MUST) inspecionar a duração do vídeo:
- Se a duração for menor ou igual a 60 segundos (`<= 60s`), o vídeo DEVE (MUST) ser anexado diretamente sem exigir ação adicional;
- Se a duração for superior a 60 segundos (`> 60s`), o sistema DEVE (MUST) abrir o modal `SeletorTrechoVideoDialog` permitindo ao usuário pré-visualizar o vídeo e posicionar uma janela deslizante de até 60 segundos antes de confirmar o anexo.

#### Scenario: Vídeo gravado na câmera ou escolhido da galeria com até 60 segundos
- **WHEN** o usuário grava um vídeo de 42 segundos pela câmera (ou seleciona um vídeo de 42 segundos da galeria)
- **THEN** o sistema salva o vídeo na galeria do aparelho (quando vindo da câmera) e anexa o vídeo diretamente ao passo do protocolo sem exibir o modal de corte

#### Scenario: Vídeo gravado na câmera com mais de 60 segundos preserva original no rolo e abre seletor de trecho
- **WHEN** o usuário grava um vídeo contínuo de 95 segundos pela câmera do aplicativo
- **THEN** a gravação não é interrompida aos 60 segundos, o vídeo completo de 95 segundos é salvo no rolo da câmera do dispositivo e o sistema exibe o `SeletorTrechoVideoDialog` para que o usuário escolha qual trecho de até 60 segundos será incluído no laudo
