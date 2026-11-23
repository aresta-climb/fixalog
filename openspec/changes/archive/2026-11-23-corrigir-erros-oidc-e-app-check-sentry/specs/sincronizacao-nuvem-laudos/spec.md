# Spec Delta

## MODIFIED Requirements

### Requirement: Fila de Sincronização Automática em Segundo Plano com Ordem de Dependência de Materiais
O sistema DEVE (MUST) manter uma fila automática de sincronização em segundo plano que envia para a nuvem todos os registros locais com status `GERADO` e `enviadoNuvem == false` logo após a selagem do laudo e assim que houver conectividade com a internet, utilizando protocolo retomável em blocos fixos de `512 KB` identificados pelo par `{id_sessao, sha256}`. Antes de enviar os blocos de um relatório de manutenção, abertura de via ou registro expresso, o sistema DEVE (MUST) verificar todos os materiais referenciados (`ref_mat_*`) e garantir que o pacote `.epub` de cada material referenciado seja enviado (ou atualizado) na nuvem primeiro, consultando previamente o servidor com o `sha256` local para pular blocos ou arquivos já recebidos. Em modo de desenvolvimento (`kModoDesenvolvimento`), caso o dispositivo não possua um token real do Firebase App Check registrado (`null` ou vazio), o sistema DEVE (MUST) realizar um mock gracioso local (`[DEBUG MOCK]`), registrando a conclusão no `RegistroLogger.logInfo` e marcando o registro como `enviadoNuvem = true` no SQLite sem realizar requisições HTTP. Em modo de produção oficial (`!kModoDesenvolvimento`), caso o token do App Check esteja indisponível (`null` ou vazio), o sistema DEVE (MUST) abortar a tentativa de envio sem disparar requisições HTTP, registrando apenas aviso (`logAviso`) e mantendo `enviadoNuvem = false`.

#### Scenario: Upload automático de manutenção precedido pelo upload de seus materiais
- **WHEN** o dispositivo possui conexão com a internet e existe um relatório de manutenção `GERADO` (`enviadoNuvem == false`) que referencia um material também ainda não sincronizado (`enviadoNuvem == false`)
- **THEN** o sistema envia primeiro os blocos do arquivo `.epub` do material para a nuvem, marca o material como `enviadoNuvem = true`, envia em seguida os blocos do arquivo `.epub` da manutenção e, após confirmação do servidor, atualiza o registro da manutenção para `enviadoNuvem = true` no banco SQLite local

#### Scenario: Falha de rede durante tentativa de upload em segundo plano
- **WHEN** o dispositivo está offline ou a requisição de upload cai após transmitir parte dos blocos de `512 KB`
- **THEN** o sistema preserva `enviadoNuvem = false` no banco SQLite local e, na próxima tentativa com conectividade, consulta `GET /api/v1/laudos/:id/status?sha256=<hash>` para enviar apenas os blocos restantes que ainda não chegaram ao servidor

#### Scenario: Mock gracioso de upload em desenvolvimento sem token do App Check registrado
- **WHEN** o envio de uma submissão é acionado em modo de desenvolvimento (`kModoDesenvolvimento`) e o token do App Check retornado está ausente (`null` ou em branco)
- **THEN** o `SincronizadorNuvemService` não realiza chamadas HTTP, registra `📝 [DEBUG MOCK]` via `logInfo`, atualiza `enviadoNuvem = true` no banco SQLite local e emite `EtapaPublicacaoLaudo.concluidoAtivo`

#### Scenario: Suspensão silenciosa do upload em produção sem token válido do App Check
- **WHEN** o envio ou publicação de uma submissão é acionado em produção oficial (`!kModoDesenvolvimento`) e o token do App Check retorna `null` ou vazio
- **THEN** o sistema não realiza chamadas HTTP sem cabeçalho válido, registra apenas um aviso (`logAviso`) sem emitir erro no Sentry, e preserva `enviadoNuvem = false` no SQLite local

### Requirement: Restauração de Laudos e Materiais da Conta em Novo Dispositivo
Ao autenticar-se em um dispositivo, o sistema DEVE (MUST) consultar a lista de laudos e materiais pertencentes ao `user_id` na nuvem e sincronizar para o banco SQLite local e armazenamento de sessões quaisquer registros existentes na nuvem que ainda não estejam presentes localmente, permitindo que o usuário visualize seu histórico completo, reutilize materiais cadastrados e crie novas versões de seus relatórios. Em modo de desenvolvimento sem token real do App Check registrado, o sistema DEVE (MUST) registrar um mock gracioso local e retornar `0` sem realizar requisições HTTP. Em modo de produção oficial sem token válido do App Check (`null` ou vazio), o sistema DEVE (MUST) registrar apenas um aviso (`logAviso`) e retornar `0` sem disparar chamadas HTTP.

#### Scenario: Login em novo celular restaura histórico de manutenções e catálogo de materiais
- **WHEN** o usuário faz login com sua conta Google ou Apple em um aparelho recém-instalado
- **THEN** o sistema baixa os metadados e pacotes `.epub` da versão mais recente de cada material e manutenção da conta, reconstrói os diretórios de sessão locais e insere os registros correspondentes no banco SQLite com `status = GERADO` e `enviadoNuvem = true`

#### Scenario: Mock gracioso de restauração em desenvolvimento sem token do App Check registrado
- **WHEN** `restaurarRelatoriosDaConta` é acionado em modo de desenvolvimento (`kModoDesenvolvimento`) sem token real do App Check registrado
- **THEN** o sistema registra `📝 [DEBUG MOCK]` via `logInfo` e retorna `0` sem disparar chamadas de rede

#### Scenario: Suspensão silenciosa da restauração em produção sem token válido do App Check
- **WHEN** `restaurarRelatoriosDaConta` é acionado em produção oficial (`!kModoDesenvolvimento`) e o token do App Check está ausente (`null` ou vazio)
- **THEN** o sistema registra apenas aviso (`logAviso`) e retorna `0` sem disparar chamadas HTTP nem reportar erro ao Sentry

### Requirement: Agendador Econômico em Segundo Plano com Detecção de Modo Avião
O sistema DEVE (MUST) executar um agendador periódico e reativo ao ciclo de vida do aplicativo que processa automaticamente as filas locais pendentes de sincronização de laudos (`SincronizadorNuvemService`) e de feedbacks (`ServicoFilaFeedback`). Antes de realizar qualquer tentativa de rede, o agendador DEVE (MUST) verificar a existência de interfaces de rede ativas não-loopback no sistema operacional e abortar instantaneamente caso o dispositivo esteja em Modo Avião ou sem rede ativa, desligando o temporizador periódico sempre que não existirem itens pendentes no banco SQLite. Quando itens permanecerem pendentes após tentativas consecutivas, o agendador DEVE (MUST) limitar as retentativas automáticas seguidas à lista configurada de intervalos de *backoff* (`30s`, `60s`, `120s` por padrão), pausando novos agendamentos automáticos ao esgotar todos os intervalos da sequência e reiniciando o contador de *backoff* quando o aplicativo retornar ao primeiro plano (`aoRetomarAplicativo`) ou quando o monitoramento for explicitamente reiniciado (`iniciarMonitoramento`).

#### Scenario: Dispositivo em Modo Avião aborta ciclo de sincronização sem consumo de rádio
- **WHEN** o agendador de segundo plano é acionado e o dispositivo está em Modo Avião (nenhuma interface de rede não-loopback ativa)
- **THEN** o sistema aborta imediatamente a tentativa sem realizar chamadas HTTP ou solicitar tokens de autenticação, preservando a bateria

#### Scenario: Sincronização automática ao selar laudo ou retomar o aplicativo com conectividade
- **WHEN** o usuário finaliza a selagem de um laudo ou traz o aplicativo para o primeiro plano com conectividade ativa e itens pendentes no SQLite
- **THEN** o agendador dispara automaticamente o envio em segundo plano dos laudos e feedbacks pendentes e encerra o temporizador assim que a fila zera

#### Scenario: Pausa do temporizador automático após esgotar os intervalos de backoff
- **WHEN** existem itens pendentes no SQLite que não puderam ser concluídos após a tentativa inicial e todas as retentativas configuradas na sequência de *backoff* (`30s`, `60s`, `120s`)
- **THEN** o agendador desliga o temporizador periódico para economizar bateria sem entrar em loop contínuo, retomando uma nova sequência de *backoff* apenas quando `aoRetomarAplicativo` ou `iniciarMonitoramento` for acionado
