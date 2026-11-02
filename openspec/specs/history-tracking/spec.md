# Histórico de Registros

## Purpose

Gerencia a persistência local, listagem, filtragem por categoria (Manutenções e Materiais), retomada de rascunhos, edição e exclusão resiliente dos registros e relatórios periciais no banco de dados local do aplicativo.

## Requirements

### Requirement: Salvar Registros e Rascunhos no Histórico
O sistema DEVE (MUST) persistir e gerenciar registros locais (`SubmissionRecord`) no banco de dados local SQLite (`sqflite`) ao longo de todo o ciclo de vida do protocolo, representando tanto rascunhos em preenchimento (`EM_PROGRESSO`) quanto relatórios finalizados e gerados (`GERADO`).

#### Scenario: Persistência contínua de rascunhos
- **WHEN** um protocolo estiver sendo preenchido ou editado
- **THEN** um registro no banco local SQLite com status `EM_PROGRESSO` é salvo ou atualizado

#### Scenario: Geração bem-sucedida atualiza status para gerado
- **WHEN** o processo de geração do relatório finalizar com sucesso e o arquivo for gravado em disco
- **THEN** o registro correspondente no banco local SQLite é atualizado para status `GERADO`, contendo o ID do protocolo, nome, data, caminho do PDF e caminho do arquivo de relatório/Protobuf

### Requirement: Exibição de Dados Reais do Histórico
O sistema DEVE (MUST) apresentar a lista de registros persistidos na aba 'Histórico' do aplicativo, ordenados do mais recente para o mais antigo. A interface DEVE distinguir visualmente os registros em progresso (`EM_PROGRESSO`) dos relatórios gerados (`GERADO`), adaptando o toque no card de acordo com o contexto.

#### Scenario: Usuário navega para a tela de histórico
- **WHEN** o usuário abre a aba Histórico
- **THEN** o sistema busca os registros do banco local SQLite e os exibe dinamicamente com as respectivas tags de status (`EM PROGRESSO` ou `GERADO`)

#### Scenario: Usuário toca em um item em progresso
- **WHEN** o usuário clica em um card de registro com status `EM_PROGRESSO`
- **THEN** o sistema lê o manifesto Protobuf do Session Bundle e abre o `WizardScreen` para retomar o preenchimento exatamente de onde parou

#### Scenario: Usuário toca em um item gerado
- **WHEN** o usuário clica em um card de registro com status `GERADO`
- **THEN** o sistema abre diretamente o relatório gerado utilizando o serviço de visualização

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
