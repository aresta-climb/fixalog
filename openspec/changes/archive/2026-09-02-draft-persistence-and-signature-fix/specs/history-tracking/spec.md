## MODIFIED Requirements

### Requirement: Salvar Registros e Rascunhos no Histórico
O sistema DEVE persistir e gerenciar registros locais (`SubmissionRecord`) no banco Isar ao longo de todo o ciclo de vida do protocolo, representando tanto rascunhos em preenchimento (`EM_PROGRESSO`) quanto relatórios finalizados e gerados (`GERADO`).

#### Scenario: Persistência contínua de rascunhos
- **QUANDO** um protocolo estiver sendo preenchido ou editado
- **ENTÃO** um registro no Isar com status `EM_PROGRESSO` é salvo ou atualizado no banco local

#### Scenario: Geração bem-sucedida atualiza status para gerado
- **QUANDO** o processo de geração do PDF finalizar com sucesso e o arquivo for gravado em disco
- **ENTÃO** o registro correspondente no banco Isar é atualizado para status `GERADO`, contendo o ID do protocolo, nome, data, caminho do PDF e caminho do arquivo Protobuf

### Requirement: Exibição de Dados Reais do Histórico
O sistema DEVE apresentar a lista de registros persistidos na aba 'Histórico' do aplicativo, ordenados do mais recente para o mais antigo. A interface DEVE distinguir visualmente os registros em progresso (`EM_PROGRESSO`) dos relatórios gerados (`GERADO`), adaptando o toque no card de acordo com o contexto.

#### Scenario: Usuário navega para a tela de histórico
- **QUANDO** o usuário abre a aba Histórico
- **ENTÃO** o sistema busca os registros do banco local Isar e os exibe dinamicamente com as respectivas tags de status (`EM PROGRESSO` ou `GERADO`)

#### Scenario: Usuário toca em um item em progresso
- **QUANDO** o usuário clica em um card de registro com status `EM_PROGRESSO`
- **ENTÃO** o sistema lê o manifesto Protobuf do Session Bundle e abre o `WizardScreen` para retomar o preenchimento exatamente de onde parou

#### Scenario: Usuário toca em um item gerado
- **QUANDO** o usuário clica em um card de registro com status `GERADO`
- **ENTÃO** o sistema abre diretamente o PDF gerado utilizando o serviço `PdfViewerService`

#### Scenario: Usuário modifica um relatório previamente gerado
- **QUANDO** o usuário abre um relatório gerado para edição e realiza qualquer alteração
- **ENTÃO** o status do registro é atualizado para `EM_PROGRESSO` no banco e na lista do histórico até que um novo relatório PDF seja gerado
