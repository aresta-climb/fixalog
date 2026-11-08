# Spec Delta

## Purpose

Gerencia a fila offline-first de upload automático e manual de pacotes periciais `.epub` (materiais e manutenções) para a nuvem com versionamento imutável (`v1`, `v2`...), a restauração de laudos/materiais da conta em novos dispositivos e o compartilhamento do link público `https://fixalog.app/v/<id>`.

## ADDED Requirements

### Requirement: Fila de Sincronização Automática em Segundo Plano com Ordem de Dependência de Materiais
O sistema DEVE (MUST) manter uma fila automática de sincronização em segundo plano que envia para a nuvem todos os registros locais com status `GERADO` e `enviadoNuvem == false` assim que houver conectividade com a internet. Antes de enviar o `.epub` de um relatório de manutenção, abertura de via ou registro expresso, o sistema DEVE (MUST) verificar todos os materiais referenciados (`ref_mat_*`) e garantir que o pacote `.epub` de cada material referenciado seja enviado (ou atualizado) na nuvem primeiro.

#### Scenario: Upload automático de manutenção precedido pelo upload de seus materiais
- **WHEN** o dispositivo recupera conexão com a internet e existe um relatório de manutenção `GERADO` (`enviadoNuvem == false`) que referencia um material também ainda não sincronizado (`enviadoNuvem == false`)
- **THEN** o sistema envia primeiro o arquivo `.epub` do material para a nuvem, marca o material como `enviadoNuvem = true`, envia em seguida o arquivo `.epub` da manutenção e, após confirmação HTTP `200/201` do servidor, atualiza o registro da manutenção para `enviadoNuvem = true` no banco SQLite local

#### Scenario: Falha de rede durante tentativa de upload em segundo plano
- **WHEN** o dispositivo está offline ou a requisição de upload falha por instabilidade de rede
- **THEN** o sistema preserva `enviadoNuvem = false` no banco SQLite local sem corromper os arquivos locais e agenda nova tentativa automática quando a conectividade for restabelecida

### Requirement: Versionamento Imutável ao Re-editar e Re-gerar um Laudo
Sempre que o usuário editar um relatório ou material previamente gerado e sincronizado (`enviadoNuvem == true`) e gerar uma nova assinatura `.epub`, o sistema DEVE (MUST) redefinir `enviadoNuvem = false` localmente e enviar o novo pacote `.epub` para a nuvem mantendo o mesmo `idSessao`, criando uma nova versão sequencial imutável (`v2`, `v3`, ...) no servidor sem apagar as versões anteriores.

#### Scenario: Re-geração de relatório já sincronizado cria nova versão na nuvem
- **WHEN** o usuário edita um relatório que já estava sincronizado na nuvem (`v1`), conclui a re-geração do `.epub` (assinado com a chave atual da conta) e o dispositivo sincroniza com a nuvem
- **THEN** o servidor armazena o novo pacote como versão `v2` vinculada ao mesmo `idSessao` e atualiza o registro local para `enviadoNuvem = true`

### Requirement: Restauração de Laudos e Materiais da Conta em Novo Dispositivo
Ao autenticar-se em um dispositivo, o sistema DEVE (MUST) consultar a lista de laudos e materiais pertencentes ao `user_id` na nuvem e sincronizar para o banco SQLite local e armazenamento de sessões quaisquer registros existentes na nuvem que ainda não estejam presentes localmente, permitindo que o usuário visualize seu histórico completo, reutilize materiais cadastrados e crie novas versões de seus relatórios.

#### Scenario: Login em novo celular restaura histórico de manutenções e catálogo de materiais
- **WHEN** o usuário faz login com sua conta Google ou Apple em um aparelho recém-instalado
- **THEN** o sistema baixa os metadados e pacotes `.epub` da versão mais recente de cada material e manutenção da conta, reconstrói os diretórios de sessão locais e insere os registros correspondentes no banco SQLite com `status = GERADO` e `enviadoNuvem = true`

### Requirement: Compartilhamento de Link Público e Sincronização Manual no Visualizador de Relatório
Na tela de visualização de relatório finalizado (`VisualizadorRelatorioScreen`), o sistema DEVE (MUST) exibir o estado atual de sincronização na nuvem do relatório, disponibilizar uma ação para copiar/compartilhar o link público web (`https://fixalog.app/v/<idSessao>`) e permitir acionar manualmente a sincronização imediata caso `enviadoNuvem` seja `false`.

#### Scenario: Compartilhamento do link web de um relatório
- **WHEN** o usuário toca no botão de compartilhar link web na `VisualizadorRelatorioScreen`
- **THEN** o sistema aciona o menu de compartilhamento nativo (ou cópia para a área de transferência) com a URL canônica `https://fixalog.app/v/<idSessao>` e, caso o relatório ainda não tenha sido enviado (`enviadoNuvem == false`), dispara imediatamente seu upload em paralelo
