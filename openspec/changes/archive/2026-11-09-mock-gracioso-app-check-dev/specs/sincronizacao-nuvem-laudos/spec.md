# Spec Delta: Sincronização em Nuvem de Laudos

## MODIFIED Requirements

### Requirement: Fila de Sincronização Automática em Segundo Plano com Ordem de Dependência de Materiais
O sistema DEVE (MUST) manter uma fila automática de sincronização em segundo plano que envia para a nuvem todos os registros locais com status `GERADO` e `enviadoNuvem == false` logo após a selagem do laudo e assim que houver conectividade com a internet, utilizando protocolo retomável em blocos fixos de `512 KB` identificados pelo par `{id_sessao, sha256}`. Antes de enviar os blocos de um relatório de manutenção, abertura de via ou registro expresso, o sistema DEVE (MUST) verificar todos os materiais referenciados (`ref_mat_*`) e garantir que o pacote `.epub` de cada material referenciado seja enviado (ou atualizado) na nuvem primeiro, consultando previamente o servidor com o `sha256` local para pular blocos ou arquivos já recebidos. Em modo de desenvolvimento (`kModoDesenvolvimento`), caso o dispositivo não possua um token real do Firebase App Check registrado, o sistema DEVE (MUST) realizar um mock gracioso local (`[DEBUG MOCK]`), registrando a conclusão no `RegistroLogger.logInfo` e marcando o registro como `enviadoNuvem = true` no SQLite sem realizar requisições HTTP.

#### Scenario: Upload automático de manutenção precedido pelo upload de seus materiais
- **WHEN** o dispositivo possui conexão com a internet e existe um relatório de manutenção `GERADO` (`enviadoNuvem == false`) que referencia um material também ainda não sincronizado (`enviadoNuvem == false`)
- **THEN** o sistema envia primeiro os blocos do arquivo `.epub` do material para a nuvem, marca o material como `enviadoNuvem = true`, envia em seguida os blocos do arquivo `.epub` da manutenção e, após confirmação do servidor, atualiza o registro da manutenção para `enviadoNuvem = true` no banco SQLite local

#### Scenario: Falha de rede durante tentativa de upload em segundo plano
- **WHEN** o dispositivo está offline ou a requisição de upload cai após transmitir parte dos blocos de `512 KB`
- **THEN** o sistema preserva `enviadoNuvem = false` no banco SQLite local e, na próxima tentativa com conectividade, consulta `GET /api/v1/laudos/:id/status?sha256=<hash>` para enviar apenas os blocos restantes que ainda não chegaram ao servidor

#### Scenario: Mock gracioso de upload em desenvolvimento sem token do App Check registrado
- **WHEN** o envio de uma submissão é acionado em modo de desenvolvimento (`kModoDesenvolvimento`) e o token do App Check retornado é ausente ou o fallback local (`app_check_token_fixalog_padrao`)
- **THEN** o `SincronizadorNuvemService` não realiza chamadas HTTP, registra `📝 [DEBUG MOCK]` via `logInfo`, atualiza `enviadoNuvem = true` no banco SQLite local e emite `EtapaPublicacaoLaudo.concluidoAtivo`

### Requirement: Restauração de Laudos e Materiais da Conta em Novo Dispositivo
Ao autenticar-se em um dispositivo, o sistema DEVE (MUST) consultar a lista de laudos e materiais pertencentes ao `user_id` na nuvem e sincronizar para o banco SQLite local e armazenamento de sessões quaisquer registros existentes na nuvem que ainda não estejam presentes localmente, permitindo que o usuário visualize seu histórico completo, reutilize materiais cadastrados e crie novas versões de seus relatórios. Em modo de desenvolvimento sem token real do App Check registrado, o sistema DEVE (MUST) registrar um mock gracioso local e retornar `0` sem realizar requisições HTTP.

#### Scenario: Login em novo celular restaura histórico de manutenções e catálogo de materiais
- **WHEN** o usuário faz login com sua conta Google ou Apple em um aparelho recém-instalado
- **THEN** o sistema baixa os metadados e pacotes `.epub` da versão mais recente de cada material e manutenção da conta, reconstrói os diretórios de sessão locais e insere os registros correspondentes no banco SQLite com `status = GERADO` e `enviadoNuvem = true`

#### Scenario: Mock gracioso de restauração em desenvolvimento sem token do App Check registrado
- **WHEN** `restaurarRelatoriosDaConta` é acionado em modo de desenvolvimento (`kModoDesenvolvimento`) sem token real do App Check registrado
- **THEN** o sistema registra `📝 [DEBUG MOCK]` via `logInfo` e retorna `0` sem disparar chamadas de rede

### Requirement: Compartilhamento de Link Público e Sincronização Manual no Visualizador de Relatório
Na tela de visualização de relatório finalizado (`VisualizadorRelatorioScreen`), o botão principal de compartilhamento DEVE (MUST) focar no compartilhamento do link público web (`https://fixalog.app/v/<idSessao>`) acompanhado de um resumo descritivo rico do laudo (protocolo, nome da via/setor/material e autor). O sistema JAMAIS DEVE (MUST NOT) liberar ou compartilhar o link enquanto o upload estiver pendente ou enquanto o status no servidor for `em_analise`. Ao tocar em compartilhar, caso o laudo ainda não esteja confirmado como `ativo` na nuvem, o sistema DEVE (MUST) exibir um modal de progresso em duas etapas (1. Envio retomável dos blocos do laudo; 2. Verificação de integridade e mídias no servidor) e abrir o menu nativo de compartilhamento somente quando o servidor confirmar `status_moderacao == 'ativo'` (ou imediatamente via mock gracioso quando em `kModoDesenvolvimento` sem token real do App Check registrado). Caso o dispositivo esteja sem conexão com a internet, o sistema DEVE (MUST) informar que é necessário estar conectado à internet para publicar o laudo e gerar o link.

#### Scenario: Compartilhamento do link web de um relatório
- **WHEN** o usuário toca no botão de compartilhar na `VisualizadorRelatorioScreen` com conexão ativa à internet
- **THEN** o sistema conecta-se ao upload em andamento (ou inicia o envio dos blocos pendentes), aguarda a confirmação remota de `status_moderacao == 'ativo'` no servidor e, somente após a aprovação, aciona o menu de compartilhamento nativo com o resumo descritivo do laudo e a URL canônica `https://fixalog.app/v/<idSessao>`

#### Scenario: Tentativa de compartilhamento sem conexão com a internet
- **WHEN** o usuário toca no botão de compartilhar na `VisualizadorRelatorioScreen` estando offline
- **THEN** o sistema exibe um aviso claro informando que é necessária conexão com a internet para publicar o laudo na nuvem e gerar o link de compartilhamento, sem liberar um link quebrado

#### Scenario: Mock gracioso de publicação e compartilhamento em desenvolvimento sem App Check
- **WHEN** `publicarEAguardarLiberacao` é acionado em modo de desenvolvimento (`kModoDesenvolvimento`) sem token real do App Check registrado
- **THEN** o sistema conclui o mock local do envio e retorna `EtapaPublicacaoLaudo.concluidoAtivo` sem realizar polling HTTP remoto
