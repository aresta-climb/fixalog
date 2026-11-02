# Spec Delta

## MODIFIED Requirements

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
