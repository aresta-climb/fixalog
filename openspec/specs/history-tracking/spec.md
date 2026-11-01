## Requirements

### Requirement: Salvar Registros e Rascunhos no Histórico
O sistema DEVE persistir e gerenciar registros locais (`SubmissionRecord`) no banco Isar ao longo de todo o ciclo de vida do protocolo, representando tanto rascunhos em preenchimento (`EM_PROGRESSO`) quanto relatórios finalizados e gerados (`GERADO`).

#### Scenario: Persistência contínua de rascunhos
- **WHEN** um protocolo estiver sendo preenchido ou editado
- **THEN** um registro no Isar com status `EM_PROGRESSO` é salvo ou atualizado no banco local

#### Scenario: Geração bem-sucedida atualiza status para gerado
- **WHEN** o processo de geração do PDF finalizar com sucesso e o arquivo for gravado em disco
- **THEN** o registro correspondente no banco Isar é atualizado para status `GERADO`, contendo o ID do protocolo, nome, data, caminho do PDF e caminho do arquivo Protobuf

### Requirement: Exibição de Dados Reais do Histórico
O sistema DEVE apresentar a lista de registros persistidos na aba 'Histórico' do aplicativo, ordenados do mais recente para o mais antigo. A interface DEVE distinguir visualmente os registros em progresso (`EM_PROGRESSO`) dos relatórios gerados (`GERADO`), adaptando o toque no card de acordo com o contexto.

#### Scenario: Usuário navega para a tela de histórico
- **WHEN** o usuário abre a aba Histórico
- **THEN** o sistema busca os registros do banco local Isar e os exibe dinamicamente com as respectivas tags de status (`EM PROGRESSO` ou `GERADO`)

#### Scenario: Usuário toca em um item em progresso
- **WHEN** o usuário clica em um card de registro com status `EM_PROGRESSO`
- **THEN** o sistema lê o manifesto Protobuf do Session Bundle e abre o `WizardScreen` para retomar o preenchimento exatamente de onde parou

#### Scenario: Usuário toca em um item gerado
- **WHEN** o usuário clica em um card de registro com status `GERADO`
- **THEN** o sistema abre diretamente o PDF gerado utilizando o serviço `PdfViewerService`

#### Scenario: Usuário modifica um relatório previamente gerado
- **WHEN** o usuário abre um relatório gerado para edição e realiza qualquer alteração
- **THEN** o status do registro é atualizado para `EM_PROGRESSO` no banco e na lista do histórico até que um novo relatório PDF seja gerado

### Requirement: Separação de Manutenções e Materiais no Histórico
A tela de Histórico e o banco de dados local DEVEM distinguir os registros de protocolos de manutenção dos registros de materiais cadastrados, permitindo ao usuário alternar a visualização na tela de Histórico entre a lista de Manutenções realizadas e a lista de Materiais cadastrados, reutilizando as ações de visualizar relatório, continuar rascunho, editar e excluir.

#### Scenario: Alternar entre Manutenções e Materiais no Histórico
- **WHEN** o usuário acessa a aba Histórico e seleciona o filtro/aba de Materiais
- **THEN** o sistema exibe exclusivamente os registros de materiais cadastrados com seu nome identificador, data e status (`EM PROGRESSO` ou `GERADO`)
- **THEN** ao selecionar o filtro/aba de Manutenções, o sistema exibe exclusivamente os registros de manutenções e vistorias de vias

#### Scenario: Editar e re-assinar um material existente pelo Histórico
- **WHEN** o usuário escolhe a opção de editar um material já gerado na seção de Materiais do Histórico
- **THEN** o sistema carrega os dados daquele material no `WizardScreen` mantendo seu identificador único (`idSessao`) e permitindo modificar informações e re-assinar para atualizar o pacote do material no catálogo
