# Spec Delta

## MODIFIED Requirements

### Requirement: Compartilhamento de Link Público e Sincronização Manual no Visualizador de Relatório
Na tela de visualização de relatório finalizado (`VisualizadorRelatorioScreen`), o botão principal de compartilhamento DEVE (MUST) focar no compartilhamento do link público web (`https://fixalog.app/v/<idSessao>`) acompanhado de um resumo descritivo rico do laudo (protocolo, nome da via/setor/material e autor). O sistema JAMAIS DEVE (MUST NOT) liberar ou compartilhar o link enquanto o upload estiver pendente ou enquanto o status no servidor for `em_analise`. Ao tocar em compartilhar, caso o laudo ainda não esteja confirmado como `ativo` na nuvem, o sistema DEVE (MUST) exibir um modal de progresso em duas etapas dotado de barras de progresso contínuas tanto para a Etapa 1 (`1. Enviando blocos do laudo (X/Y)`) quanto para a Etapa 2 (`2. Verificando integridade e mídias no servidor (M/N)`, alimentada por `verificacao_concluida` e `verificacao_total` do D1), além de um botão para fechar o modal mantendo o envio em segundo plano (`Continuar em 2º plano` / `✕`) e um botão explícito para **cancelar a sincronização** (`Cancelar envio`). Ao tocar em `Cancelar envio`, o sistema DEVE (MUST) abortar imediatamente o upload/polling daquele laudo, remover a notificação *sticky* e pausar o reenvio automático em segundo plano daquele laudo até que o usuário solicite compartilhar novamente. O sistema DEVE (MUST) abrir o menu nativo de compartilhamento somente quando o servidor confirmar `status_moderacao == 'ativo'` (e caso o usuário não tenha fechado ou cancelado o modal) ou imediatamente via mock gracioso quando em `kModoDesenvolvimento` sem token real do App Check registrado. Caso ocorra erro HTTP (`>= 400`) ou rejeição/falha de verificação no servidor, o modal DEVE (MUST) exibir a mensagem de erro retornada com botão para fechar. Caso o dispositivo esteja sem conexão com a internet, o sistema DEVE (MUST) informar que é necessário estar conectado à internet para publicar o laudo e gerar o link.

#### Scenario: Compartilhamento do link web de um relatório
- **WHEN** o usuário toca no botão de compartilhar na `VisualizadorRelatorioScreen` com conexão ativa à internet
- **THEN** o modal exibe a barra de progresso da Etapa 1 (envio de blocos) e, após enviar todos os blocos, exibe a barra de progresso contínua da Etapa 2 (`verificacao_concluida / verificacao_total`) até `status_moderacao == 'ativo'`, acionando então o menu de compartilhamento nativo com o resumo descritivo do laudo e a URL canônica `https://fixalog.app/v/<idSessao>`

#### Scenario: Fechamento do modal para continuar publicação em segundo plano
- **WHEN** o usuário toca no botão de fechar / `Continuar em 2º plano` no modal enquanto o envio ou a verificação está em andamento
- **THEN** o modal é fechado imediatamente liberando a leitura do relatório, enquanto o upload e a notificação *sticky* continuam em segundo plano até a conclusão

#### Scenario: Cancelamento do upload pelo botão do modal
- **WHEN** o usuário toca em `Cancelar envio` no modal de publicação enquanto os blocos estão sendo enviados ou verificados
- **THEN** o sistema aborta imediatamente o envio em andamento, fecha o modal e a notificação *sticky*, e não reenvia aquele laudo automaticamente em segundo plano até nova ação explícita do usuário

#### Scenario: Exibição clara de erro quando o servidor retorna falha HTTP ou rejeição
- **WHEN** o envio de bloco ou consulta de status retorna erro HTTP (`>= 400`) ou `status_moderacao == 'bloqueado'`
- **THEN** o modal exibe imediatamente a mensagem de erro correspondente com botão `FECHAR`, sem continuar em loop

#### Scenario: Tentativa de compartilhamento sem conexão com a internet
- **WHEN** o usuário toca no botão de compartilhar na `VisualizadorRelatorioScreen` estando offline
- **THEN** o sistema exibe um aviso claro informando que é necessária conexão com a internet para publicar o laudo na nuvem e gerar o link de compartilhamento, sem liberar um link quebrado

#### Scenario: Mock gracioso de publicação e compartilhamento em desenvolvimento sem App Check
- **WHEN** `publicarEAguardarLiberacao` é acionado em modo de desenvolvimento (`kModoDesenvolvimento`) sem token real do App Check registrado
- **THEN** o sistema conclui o mock local do envio e retorna `EtapaPublicacaoLaudo.concluidoAtivo` sem realizar polling HTTP remoto

### Requirement: Notificação Nativa Sticky de Progresso de Upload e Reabertura do Relatório ao Concluir
Durante o envio de blocos e a verificação no servidor de um laudo, o sistema DEVE (MUST) exibir uma notificação nativa contínua (*sticky*, `ongoing: true`) no sistema operacional com barra de progresso combinada das duas etapas e uma ação interativa **"Cancelar envio"** (`cancelar_upload`). Se o usuário acionar **"Cancelar envio"** na notificação, o sistema DEVE (MUST) cancelar imediatamente a sincronização em segundo plano daquele laudo e remover a notificação. Assim que o servidor confirmar `status_moderacao == 'ativo'`, o sistema DEVE (MUST) substituir a notificação *sticky* por uma notificação dispensável (`ongoing: false`, `autoCancel: true`) informando que o laudo está pronto para compartilhamento; ao tocar nessa notificação de conclusão, o aplicativo DEVE (MUST) abrir a `VisualizadorRelatorioScreen` do respectivo laudo para que o usuário possa tocar no botão de compartilhar.

#### Scenario: Exibição de notificação sticky durante upload e transição ao concluir
- **WHEN** um laudo inicia o envio de blocos e a verificação de mídias no servidor
- **THEN** o sistema exibe uma notificação *sticky* com barra de progresso atualizada em tempo real e ação `Cancelar envio` e, quando `status_moderacao` atinge `'ativo'`, substitui-a por uma notificação de conclusão

#### Scenario: Cancelamento da sincronização em segundo plano direto pela notificação sticky
- **WHEN** o usuário toca na ação `Cancelar envio` da notificação *sticky* enquanto o upload ocorre em segundo plano
- **THEN** o `SincronizadorNuvemService` aborta imediatamente o envio daquele laudo, dispensa a notificação *sticky* e pausa o reenvio automático daquela sessão

#### Scenario: Toque na notificação de conclusão abre o relatório pronto para compartilhar
- **WHEN** o usuário toca na notificação de conclusão de publicação de um laudo
- **THEN** o aplicativo navega diretamente para a `VisualizadorRelatorioScreen` daquele laudo com o botão `COMPARTILHAR` disponível
