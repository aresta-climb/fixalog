# Spec Delta

## MODIFIED Requirements

### Requirement: Exibição de Dados Reais do Histórico
O sistema DEVE (MUST) apresentar a lista de registros persistidos na aba 'Histórico' do aplicativo, ordenados do mais recente para o mais antigo. A interface DEVE distinguir visualmente os registros em progresso (`EM_PROGRESSO`) dos relatórios gerados (`GERADO`), abrindo sempre o visualizador do relatório EPUB (`VisualizadorRelatorioScreen`) ao tocar em um registro `GERADO` cujo pacote EPUB exista em disco, ou rebaixando o registro para `EM_PROGRESSO` e abrindo o `WizardScreen` para edição caso o pacote EPUB não exista em disco (sem jamais acionar visualizador ou compartilhamento direto de PDF a partir do Histórico).

#### Scenario: Usuário navega para a tela de histórico
- **WHEN** o usuário abre a aba Histórico
- **THEN** o sistema busca os registros do banco local SQLite e os exibe dinamicamente com as respectivas tags de status (`EM PROGRESSO` ou `GERADO`)

#### Scenario: Usuário toca em um item em progresso
- **WHEN** o usuário clica em um card de registro com status `EM_PROGRESSO`
- **THEN** o sistema lê o manifesto da sessão e abre o `WizardScreen` para retomar o preenchimento exatamente de onde parou

#### Scenario: Usuário toca em um item gerado
- **WHEN** o usuário clica em um card de registro com status `GERADO` cujo arquivo EPUB existe em disco (em `epubPath`, em `sessoes/<id_sessao>/relatorio.epub` ou como irmão `.epub`)
- **THEN** o sistema abre o `VisualizadorRelatorioScreen` renderizando o EPUB 3 com a barra inferior de compartilhamento, mesmo que já exista um PDF resumido em cache

#### Scenario: Usuário toca em um item gerado cujo arquivo EPUB não existe em disco
- **WHEN** o usuário clica em um card de registro marcado como `GERADO`, mas nenhum arquivo `.epub` correspondente existe no disco
- **THEN** o sistema atualiza o registro no banco local SQLite para `status = EM_PROGRESSO` (limpando `epubPath` e `pdfPath`), remove eventual PDF resumido órfão do disco e abre a sessão no `WizardScreen` para revisão e nova geração do relatório

#### Scenario: Usuário modifica um relatório previamente gerado
- **WHEN** o usuário abre um relatório gerado para edição e realiza qualquer alteração
- **THEN** o status do registro é atualizado para `EM_PROGRESSO` no banco SQLite e na lista do histórico até que um novo relatório seja gerado

### Requirement: Reconstrução Automática do Histórico a partir dos Session Bundles em Disco
Ao inicializar o banco de dados local SQLite, o sistema DEVE (MUST) inspecionar o diretório de sessões (`sessoes/<id_sessao>/`), reconstruir automaticamente na tabela de submissões quaisquer rascunhos (`registro.yaml` ou `registro.binarypb`) ou relatórios gerados (`relatorio.epub`) que ainda não estejam indexados no banco SQLite, reconciliar o `epub_path` e o `status` dos registros já existentes no SQLite conforme a presença real do arquivo `.epub` em disco e remover arquivos residuais legados do Isar (`default.isar` e `default.isar.lock`).

#### Scenario: Migração e recuperação de sessões existentes no disco
- **WHEN** o aplicativo inicializa o banco SQLite e existem diretórios em `sessoes/<id_sessao>/` contendo `registro.yaml`, `registro.binarypb` ou `relatorio.epub` sem registro correspondente na tabela `submissoes`
- **THEN** o sistema lê os metadados do manifesto de cada sessão e insere o respectivo `SubmissionRecord` no SQLite com o status (`GERADO` ou `EM_PROGRESSO`), categoria (`MATERIAL` ou `MANUTENCAO`) e título corretos
- **THEN** caso existam arquivos `default.isar` ou `default.isar.lock` no diretório de documentos, o sistema os remove sem erro

#### Scenario: Reconciliação de registros já indexados no SQLite durante a inicialização
- **WHEN** o aplicativo inicializa o banco SQLite contendo registros já existentes na tabela `submissoes`
- **THEN** para registros cujo arquivo `sessoes/<id_sessao>/relatorio.epub` existe em disco mas `epub_path` está vazio, o sistema preenche `epub_path` com o caminho do `relatorio.epub`
- **THEN** para registros com `status = GERADO` cujo arquivo `.epub` não existe em disco em nenhum dos caminhos candidatos, o sistema rebaixa `status` para `EM_PROGRESSO`, limpa `epub_path` e `pdf_path` e remove eventual PDF resumido órfão do disco
