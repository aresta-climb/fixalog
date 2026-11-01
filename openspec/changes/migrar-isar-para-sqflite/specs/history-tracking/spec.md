# Spec Delta: history-tracking

## MODIFIED Requirements

### Requirement: Salvar Registros e Rascunhos no Histórico
O sistema DEVE (MUST) persistir e gerenciar registros locais (`SubmissionRecord`) no banco de dados local SQLite (`sqflite`) ao longo de todo o ciclo de vida do protocolo, representando tanto rascunhos em preenchimento (`EM_PROGRESSO`) quanto relatórios finalizados e gerados (`GERADO`).

#### Scenario: Persistência contínua de rascunhos
- **WHEN** um protocolo estiver sendo preenchido ou editado
- **THEN** um registro no banco local SQLite com status `EM_PROGRESSO` é salvo ou atualizado

#### Scenario: Geração bem-sucedida atualiza status para gerado
- **WHEN** o processo de geração do PDF/EPUB finalizar com sucesso e o arquivo for gravado em disco
- **THEN** o registro correspondente no banco local SQLite é atualizado para status `GERADO`, contendo o ID do protocolo, nome, data, caminho do relatório e caminho do arquivo Protobuf

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
- **THEN** o sistema abre diretamente o relatório gerado utilizando a tela de visualização de relatório

#### Scenario: Usuário modifica um relatório previamente gerado
- **WHEN** o usuário abre um relatório gerado para edição e realiza qualquer alteração
- **THEN** o status do registro é atualizado para `EM_PROGRESSO` no banco SQLite e na lista do histórico até que um novo relatório seja gerado
