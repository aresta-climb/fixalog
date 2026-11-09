# Histórico de Registros

## Purpose

Gerencia a persistência local, listagem, filtragem por categoria (Manutenções e Materiais), retomada de rascunhos, edição e exclusão resiliente dos registros e relatórios periciais no banco de dados local do aplicativo.

## Requirements

### Requirement: Salvar Registros e Rascunhos no Histórico
O sistema DEVE (MUST) persistir e gerenciar registros locais (`SubmissionRecord`) no banco de dados local SQLite (`sqflite`) ao longo de todo o ciclo de vida do protocolo, representando tanto rascunhos em preenchimento (`EM_PROGRESSO`) quanto relatórios finalizados e gerados (`GERADO`), mantendo colunas independentes para o manifesto Protobuf (`protobuf_path` em `sessoes/<id_sessao>/registro.binarypb`), o pacote EPUB 3 assinado (`epub_path` em `sessoes/<id_sessao>/relatorio.epub`) e o resumo impresso (`pdf_path` em `sessoes/<id_sessao>/fixalog_<id_sessao>.pdf`).

#### Scenario: Persistência contínua de rascunhos
- **WHEN** um protocolo estiver sendo preenchido ou editado com alterações pendentes
- **THEN** um registro no banco local SQLite com status `EM_PROGRESSO` é salvo ou atualizado apontando `protobuf_path` para `sessoes/<id_sessao>/registro.binarypb` e invalidando eventual `pdf_path` antigo

#### Scenario: Geração bem-sucedida atualiza status para gerado com caminho padronizado do EPUB
- **WHEN** o processo de geração do relatório finalizar com sucesso e o arquivo EPUB for gravado em disco
- **THEN** o pacote EPUB é gravado no caminho padronizado `sessoes/<id_sessao>/relatorio.epub` e o registro correspondente no banco local SQLite é atualizado para status `GERADO` com `epub_path` apontando para o EPUB, `protobuf_path` preservado para o `registro.binarypb` e `pdf_path` limpo

#### Scenario: Saída da tela do Wizard após geração preserva o caminho do EPUB
- **WHEN** o usuário gera um relatório no Wizard e navega de volta para a tela anterior sem realizar novas edições
- **THEN** o registro no banco SQLite mantém `status = GERADO` e preserva intacto o `epub_path` apontando para `sessoes/<id_sessao>/relatorio.epub`

### Requirement: Exibição de Dados Reais do Histórico
O sistema DEVE (MUST) apresentar a lista de registros persistidos na aba 'Histórico' do aplicativo, ordenados do mais recente para o mais antigo. A interface DEVE distinguir visualmente os registros em progresso (`EM_PROGRESSO`) dos relatórios gerados (`GERADO`), abrindo sempre o visualizador do relatório EPUB (`VisualizadorRelatorioScreen`) ao tocar em um registro `GERADO` que possua pacote EPUB disponível.

#### Scenario: Usuário navega para a tela de histórico
- **WHEN** o usuário abre a aba Histórico
- **THEN** o sistema busca os registros do banco local SQLite e os exibe dinamicamente com as respectivas tags de status (`EM PROGRESSO` ou `GERADO`)

#### Scenario: Usuário toca em um item em progresso
- **WHEN** o usuário clica em um card de registro com status `EM_PROGRESSO`
- **THEN** o sistema lê o manifesto Protobuf do Session Bundle e abre o `WizardScreen` para retomar o preenchimento exatamente de onde parou

#### Scenario: Usuário toca em um item gerado
- **WHEN** o usuário clica em um card de registro com status `GERADO`
- **THEN** o sistema localiza o arquivo EPUB através de `epubPath` (ou do caminho padronizado `sessoes/<id_sessao>/relatorio.epub`) e abre o `VisualizadorRelatorioScreen` renderizando o EPUB 3, mesmo que já exista um PDF resumido em cache

#### Scenario: Usuário modifica um relatório previamente gerado
- **WHEN** o usuário abre um relatório gerado para edição e realiza qualquer alteração
- **THEN** o status do registro é atualizado para `EM_PROGRESSO` no banco SQLite e na lista do histórico até que um novo relatório seja gerado

### Requirement: Separação de Manutenções e Materiais no Histórico
A tela de Histórico e o banco de dados local DEVEM distinguir os registros de protocolos de manutenção dos registros de materiais cadastrados, permitindo ao usuário alternar a visualização na tela de Histórico entre a lista de Manutenções realizadas e a lista de Materiais cadastrados, reutilizando as ações de visualizar relatório, continuar rascunho, editar e excluir.

#### Scenario: Alternar entre Manutenções e Materiais no Histórico
- **WHEN** o usuário acessa a aba Histórico e seleciona o filtro/aba de Materiais
- **THEN** o sistema exibe exclusivamente os registros de materiais cadastrados com seu nome identificador, data e status (`EM PROGRESSO` ou `GERADO`)
- **THEN** ao selecionar o filtro/aba de Manutenções, o sistema exibe exclusivamente os registros de manutenções e vistorias de vias

#### Scenario: Editar e re-assinar um material existente pelo Histórico
- **WHEN** o usuário escolhe a opção de editar um material já gerado na seção de Materiais do Histórico
- **THEN** o sistema carrega os dados daquele material no `WizardScreen` mantendo seu identificador único (`idSessao`) e permitindo modificar informações e re-gerar para atualizar o pacote assinado digitalmente do material no catálogo

### Requirement: Exclusão Resiliente de Relatórios e Artefatos Legados
Ao excluir qualquer registro pelo Histórico (seja um rascunho ou um relatório antigo ou recente), o sistema DEVE remover o registro do banco de dados local e limpar de forma resiliente todos os arquivos associados (`.pdf`, `.epub` principal ou irmão e diretório de sessão), sem falhar caso algum arquivo já tenha sido removido ou pertença ao formato legado com assinatura em tela.

#### Scenario: Exclusão de relatório antigo com arquivos parciais ou legados
- **WHEN** o usuário confirma a exclusão de um relatório antigo no Histórico
- **THEN** o sistema remove os arquivos `.pdf`, `.epub` e o diretório da sessão correspondentes (ignorando com segurança arquivos inexistentes ou falhas isoladas de I/O) e exclui o registro do banco local sem exibir erro

### Requirement: Reconstrução Automática do Histórico a partir dos Session Bundles em Disco
Ao inicializar o banco de dados local SQLite, o sistema DEVE (MUST) inspecionar o diretório de sessões (`sessoes/<id_sessao>/`), reconstruir automaticamente na tabela de submissões quaisquer rascunhos (`registro.binarypb`) ou relatórios gerados (`relatorio.epub`) que ainda não estejam indexados no banco SQLite e remover arquivos residuais legados do Isar (`default.isar` e `default.isar.lock`).

#### Scenario: Migração e recuperação de sessões existentes no disco
- **WHEN** o aplicativo inicializa o banco SQLite e existem diretórios em `sessoes/<id_sessao>/` contendo `registro.binarypb` ou `relatorio.epub` sem registro correspondente na tabela `submissoes`
- **THEN** o sistema lê os metadados do manifesto Protobuf de cada sessão e insere o respectivo `SubmissionRecord` no SQLite com o status (`GERADO` ou `EM_PROGRESSO`), categoria (`MATERIAL` ou `MANUTENCAO`) e título corretos
- **THEN** caso existam arquivos `default.isar` ou `default.isar.lock` no diretório de documentos, o sistema os remove sem erro

### Requirement: Criação de Cópia de Relatório Existente pelo Histórico
A tela de Histórico DEVE disponibilizar a opção "Criar cópia" no menu de opções (3 pontinhos) de todos os registros (`GERADO` e `EM PROGRESSO`, tanto de Manutenções quanto de Materiais). Ao acioná-la, o sistema DEVE exibir um indicador de progresso enquanto clona os dados e arquivos de mídia para uma nova sessão independente (`EM_PROGRESSO`), aplicando sufixo incremental `(Cópia)` / `(Cópia N)` ao título, atualizando campos de data atual para a data de hoje e abrindo imediatamente o `WizardScreen` na nova sessão.

#### Scenario: Criar primeira cópia de um relatório ou material existente
- **WHEN** o usuário abre o menu de 3 pontinhos de um registro intitulado `"Via do Diedro"` e seleciona `"Criar cópia"`
- **THEN** o sistema exibe um modal de carregamento com indicador giratório, copia todas as respostas, listas e arquivos de mídia (originais e pré-processados) para um novo `sessionId`, define o nome/título da cópia como `"Via do Diedro (Cópia)"`, atualiza campos configurados com `preencher_data_atual` para a data de hoje, salva o novo registro como `EM_PROGRESSO` e abre imediatamente o `WizardScreen` carregado na nova sessão

#### Scenario: Incremento automático do sufixo ao criar múltiplas cópias
- **WHEN** já existe um registro intitulado `"Kit Parabolt Inox (Cópia)"` e o usuário seleciona `"Criar cópia"` a partir de `"Kit Parabolt Inox"` ou de `"Kit Parabolt Inox (Cópia)"`
- **THEN** o sistema nomeia a nova cópia como `"Kit Parabolt Inox (Cópia 2)"` (e `"Kit Parabolt Inox (Cópia 3)"` na próxima, sucessivamente)

### Requirement: Exibição Fiel do Status de Sincronização em Nuvem e Ações de Nuvem no Histórico
A tela de Histórico (`HistoryScreen`) DEVE (MUST) exibir o indicador visual de nuvem em cada card de registro `GERADO` refletindo estritamente o valor real do campo `enviadoNuvem` (`enviado_nuvem` no SQLite):
- Quando `enviadoNuvem == true`, DEVE (MUST) exibir o ícone de sincronização concluída (`Icons.cloud_done_outlined`);
- Quando `enviadoNuvem == false`, DEVE (MUST) exibir o ícone de sincronização pendente (`Icons.cloud_upload_outlined`) e permitir acionar a sincronização manual ou compartilhar o link web (`https://fixalog.app/v/<idSessao>`) através do card ou menu de opções do registro.

#### Scenario: Diferenciação visual entre relatório sincronizado e relatório pendente de envio
- **WHEN** o usuário abre a tela de Histórico contendo um relatório `GERADO` já sincronizado (`enviadoNuvem == true`) e outro relatório `GERADO` gerado offline (`enviadoNuvem == false`)
- **THEN** o card do relatório sincronizado exibe o ícone de nuvem concluída e o card do relatório offline exibe o ícone de upload pendente

#### Scenario: Acionamento manual de sincronização a partir do Histórico
- **WHEN** o usuário aciona a opção de sincronizar na nuvem em um relatório com `enviadoNuvem == false` na tela de Histórico (ou toca no ícone de upload pendente) com conexão ativa à internet
- **THEN** o sistema envia o pacote `.epub` (e eventuais materiais dependentes) para a nuvem e atualiza o ícone do card para sincronizado (`enviadoNuvem = true`)
