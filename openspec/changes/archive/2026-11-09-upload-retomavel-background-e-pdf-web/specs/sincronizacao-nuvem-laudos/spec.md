# Spec Delta

## ADDED Requirements

### Requirement: Agendador Econômico em Segundo Plano com Detecção de Modo Avião
O sistema DEVE (MUST) executar um agendador periódico e reativo ao ciclo de vida do aplicativo que processa automaticamente as filas locais pendentes de sincronização de laudos (`SincronizadorNuvemService`) e de feedbacks (`ServicoFilaFeedback`). Antes de realizar qualquer tentativa de rede, o agendador DEVE (MUST) verificar a existência de interfaces de rede ativas não-loopback no sistema operacional e abortar instantaneamente caso o dispositivo esteja em Modo Avião ou sem rede ativa, desligando o temporizador periódico sempre que não existirem itens pendentes no banco SQLite.

#### Scenario: Dispositivo em Modo Avião aborta ciclo de sincronização sem consumo de rádio
- **WHEN** o agendador de segundo plano é acionado e o dispositivo está em Modo Avião (nenhuma interface de rede não-loopback ativa)
- **THEN** o sistema aborta imediatamente a tentativa sem realizar chamadas HTTP ou solicitar tokens de autenticação, preservando a bateria

#### Scenario: Sincronização automática ao selar laudo ou retomar o aplicativo com conectividade
- **WHEN** o usuário finaliza a selagem de um laudo ou traz o aplicativo para o primeiro plano com conectividade ativa e itens pendentes no SQLite
- **THEN** o agendador dispara automaticamente o envio em segundo plano dos laudos e feedbacks pendentes e encerra o temporizador assim que a fila zera

## MODIFIED Requirements

### Requirement: Fila de Sincronização Automática em Segundo Plano com Ordem de Dependência de Materiais
O sistema DEVE (MUST) manter uma fila automática de sincronização em segundo plano que envia para a nuvem todos os registros locais com status `GERADO` e `enviadoNuvem == false` logo após a selagem do laudo e assim que houver conectividade com a internet, utilizando protocolo retomável em blocos fixos de `512 KB` identificados pelo par `{id_sessao, sha256}`. Antes de enviar os blocos de um relatório de manutenção, abertura de via ou registro expresso, o sistema DEVE (MUST) verificar todos os materiais referenciados (`ref_mat_*`) e garantir que o pacote `.epub` de cada material referenciado seja enviado (ou atualizado) na nuvem primeiro, consultando previamente o servidor com o `sha256` local para pular blocos ou arquivos já recebidos.

#### Scenario: Upload automático de manutenção precedido pelo upload de seus materiais
- **WHEN** o dispositivo possui conexão com a internet e existe um relatório de manutenção `GERADO` (`enviadoNuvem == false`) que referencia um material também ainda não sincronizado (`enviadoNuvem == false`)
- **THEN** o sistema envia primeiro os blocos do arquivo `.epub` do material para a nuvem, marca o material como `enviadoNuvem = true`, envia em seguida os blocos do arquivo `.epub` da manutenção e, após confirmação do servidor, atualiza o registro da manutenção para `enviadoNuvem = true` no banco SQLite local

#### Scenario: Falha de rede durante tentativa de upload em segundo plano
- **WHEN** o dispositivo está offline ou a requisição de upload cai após transmitir parte dos blocos de `512 KB`
- **THEN** o sistema preserva `enviadoNuvem = false` no banco SQLite local e, na próxima tentativa com conectividade, consulta `GET /api/v1/laudos/:id/status?sha256=<hash>` para enviar apenas os blocos restantes que ainda não chegaram ao servidor

### Requirement: Versionamento Imutável ao Re-editar e Re-gerar um Laudo
Sempre que o usuário editar um relatório ou material previamente gerado e sincronizado (`enviadoNuvem == true`) e gerar uma nova assinatura `.epub` cujo hash `sha256` seja diferente do anterior, o sistema DEVE (MUST) redefinir `enviadoNuvem = false` localmente e enviar o novo pacote `.epub` com seu `sha256` para a nuvem mantendo o mesmo `idSessao`, criando uma nova versão sequencial imutável (`v2`, `v3`, ...) no servidor sem apagar as versões anteriores. Caso o `sha256` calculado localmente já esteja registrado no servidor para aquele `idSessao`, o sistema DEVE (MUST) reconhecer que aquela versão exata já foi enviada sem retransmitir o arquivo.

#### Scenario: Re-geração de relatório já sincronizado cria nova versão na nuvem
- **WHEN** o usuário edita um relatório que já estava sincronizado na nuvem (`v1`), conclui a re-geração do `.epub` (produzindo um novo `sha256`) e o dispositivo sincroniza com a nuvem
- **THEN** o servidor armazena o novo pacote como versão `v2` vinculada ao par `{idSessao, sha256}` e atualiza o registro local para `enviadoNuvem = true`

### Requirement: Compartilhamento de Link Público e Sincronização Manual no Visualizador de Relatório
Na tela de visualização de relatório finalizado (`VisualizadorRelatorioScreen`), o botão principal de compartilhamento DEVE (MUST) focar no compartilhamento do link público web (`https://fixalog.app/v/<idSessao>`) acompanhado de um resumo descritivo rico do laudo (protocolo, nome da via/setor/material e autor). O sistema JAMAIS DEVE (MUST NOT) liberar ou compartilhar o link enquanto o upload estiver pendente ou enquanto o status no servidor for `em_analise`. Ao tocar em compartilhar, caso o laudo ainda não esteja confirmado como `ativo` na nuvem, o sistema DEVE (MUST) exibir um modal de progresso em duas etapas (1. Envio retomável dos blocos do laudo; 2. Verificação de integridade e mídias no servidor) e abrir o menu nativo de compartilhamento somente quando o servidor confirmar `status_moderacao == 'ativo'`. Caso o dispositivo esteja sem conexão com a internet, o sistema DEVE (MUST) informar que é necessário estar conectado à internet para publicar o laudo e gerar o link.

#### Scenario: Compartilhamento do link web de um relatório
- **WHEN** o usuário toca no botão de compartilhar na `VisualizadorRelatorioScreen` com conexão ativa à internet
- **THEN** o sistema conecta-se ao upload em andamento (ou inicia o envio dos blocos pendentes), aguarda a confirmação remota de `status_moderacao == 'ativo'` no servidor e, somente após a aprovação, aciona o menu de compartilhamento nativo com o resumo descritivo do laudo e a URL canônica `https://fixalog.app/v/<idSessao>`

#### Scenario: Tentativa de compartilhamento sem conexão com a internet
- **WHEN** o usuário toca no botão de compartilhar na `VisualizadorRelatorioScreen` estando offline
- **THEN** o sistema exibe um aviso claro informando que é necessária conexão com a internet para publicar o laudo na nuvem e gerar o link de compartilhamento, sem liberar um link quebrado
