# Spec Delta

## MODIFIED Requirements

### Requirement: O sistema DEVE realizar Compressão de Vídeo/Áudio
O sistema DEVE (MUST) comprimir anexos de vídeo e áudio antes de embuti-los no documento, transcodificando vídeos para H.264 720p a 30fps com CRF 26, preset `veryfast`, intervalo de *keyframe* fixo `-g 300` (garantindo exato 1 *I-Frame* a cada 10 segundos), áudio AAC mono 64 kbps (`+faststart`), aplicando corte opcional de trecho (`-ss <inicio> -t <duracao>`) quando selecionado pelo usuário e extraindo o *poster frame* estático aos 0.5s do trecho final diretamente em formato JPEG (`<uuid>_poster.jpg`).

#### Scenario: Compressão de vídeo
- **WHEN** um vídeo é gravado ou anexado à vistoria
- **THEN** o sistema transcodifica o vídeo para 720p em H.264 utilizando `-preset veryfast -g 300` e extrai o frame de capa em `<uuid>_poster.jpg`

#### Scenario: Compressão de trecho selecionado de um vídeo longo
- **WHEN** o usuário seleciona o intervalo de 15s a 75s (`inicio = 15s`, `duracao = 60s`) de um vídeo original mais longo
- **THEN** o sistema transcodifica exclusivamente o trecho de 60 segundos via `-ss 15 -t 60` com `-g 300` e extrai o `<uuid>_poster.jpg` correspondente ao trecho cortado

## ADDED Requirements

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
