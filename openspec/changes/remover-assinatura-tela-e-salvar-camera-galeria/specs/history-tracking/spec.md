## MODIFIED Requirements

### Requirement: Separação de Manutenções e Materiais no Histórico
A tela de Histórico e o banco de dados local DEVEM distinguir os registros de protocolos de manutenção dos registros de materiais cadastrados, permitindo ao usuário alternar a visualização na tela de Histórico entre a lista de Manutenções realizadas e a lista de Materiais cadastrados, reutilizando as ações de visualizar relatório, continuar rascunho, editar e excluir.

#### Scenario: Alternar entre Manutenções e Materiais no Histórico
- **WHEN** o usuário acessa a aba Histórico e seleciona o filtro/aba de Materiais
- **THEN** o sistema exibe exclusivamente os registros de materiais cadastrados com seu nome identificador, data e status (`EM PROGRESSO` ou `GERADO`)
- **THEN** ao selecionar o filtro/aba de Manutenções, o sistema exibe exclusivamente os registros de manutenções e vistorias de vias

#### Scenario: Editar e re-assinar um material existente pelo Histórico
- **WHEN** o usuário escolhe a opção de editar um material já gerado na seção de Materiais do Histórico
- **THEN** o sistema carrega os dados daquele material no `WizardScreen` mantendo seu identificador único (`idSessao`) e permitindo modificar informações e re-gerar para atualizar o pacote assinado digitalmente do material no catálogo

## ADDED Requirements

### Requirement: Exclusão Resiliente de Relatórios e Artefatos Legados
Ao excluir qualquer registro pelo Histórico (seja um rascunho ou um relatório antigo ou recente), o sistema DEVE remover o registro do banco de dados local e limpar de forma resiliente todos os arquivos associados (`.pdf`, `.epub` principal ou irmão e diretório de sessão), sem falhar caso algum arquivo já tenha sido removido ou pertença ao formato legado com assinatura em tela.

#### Scenario: Exclusão de relatório antigo com arquivos parciais ou legados
- **WHEN** o usuário confirma a exclusão de um relatório antigo no Histórico
- **THEN** o sistema remove os arquivos `.pdf`, `.epub` e o diretório da sessão correspondentes (ignorando com segurança arquivos inexistentes ou falhas isoladas de I/O) e exclui o registro do banco local sem exibir erro
