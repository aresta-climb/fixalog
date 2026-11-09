# Spec Delta

## MODIFIED Requirements

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
