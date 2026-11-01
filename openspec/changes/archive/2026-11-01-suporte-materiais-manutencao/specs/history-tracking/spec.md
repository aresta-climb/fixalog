## ADDED Requirements

### Requirement: Separação de Manutenções e Materiais no Histórico
A tela de Histórico e o banco de dados local DEVEM distinguir os registros de protocolos de manutenção dos registros de materiais cadastrados, permitindo ao usuário alternar a visualização na tela de Histórico entre a lista de Manutenções realizadas e a lista de Materiais cadastrados, reutilizando as ações de visualizar relatório, continuar rascunho, editar e excluir.

#### Scenario: Alternar entre Manutenções e Materiais no Histórico
- **WHEN** o usuário acessa a aba Histórico e seleciona o filtro/aba de Materiais
- **THEN** o sistema exibe exclusivamente os registros de materiais cadastrados com seu nome identificador, data e status (`EM PROGRESSO` ou `GERADO`)
- **THEN** ao selecionar o filtro/aba de Manutenções, o sistema exibe exclusivamente os registros de manutenções e vistorias de vias

#### Scenario: Editar e re-assinar um material existente pelo Histórico
- **WHEN** o usuário escolhe a opção de editar um material já gerado na seção de Materiais do Histórico
- **THEN** o sistema carrega os dados daquele material no `WizardScreen` mantendo seu identificador único (`idSessao`) e permitindo modificar informações e re-assinar para atualizar o pacote do material no catálogo
