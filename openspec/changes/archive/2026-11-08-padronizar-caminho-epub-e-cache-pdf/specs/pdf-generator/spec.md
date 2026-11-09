# Spec Delta

## MODIFIED Requirements

### Requirement: O sistema DEVE manter cache do PDF Resumido gerado sob demanda
Após a primeira geração sob demanda do PDF resumido, o sistema DEVE salvar o arquivo no disco local e associar seu caminho ao registro da sessão (`SubmissionRecord.pdfPath`) para que compartilhamentos ou aberturas subsequentes ocorram instantaneamente sem re-renderização. Sempre que o relatório EPUB da sessão for gerado ou re-gerado (ou quando a sessão for editada), o sistema DEVE invalidar `SubmissionRecord.pdfPath` e excluir do disco eventual arquivo PDF antigo para garantir que a próxima exportação reflita o relatório atualizado.

#### Scenario: Compartilhamento subsequente do PDF já gerado
- **WHEN** o usuário solicita compartilhar o PDF Resumido de um laudo cujo PDF já foi gerado previamente para a versão atual do EPUB
- **THEN** o sistema reutiliza o arquivo em disco diretamente sem disparar nova conversão pelo motor de impressão

#### Scenario: Invalidação do cache de PDF ao re-gerar o relatório EPUB
- **WHEN** um relatório que já possuía um PDF resumido em cache é re-gerado na esteira de geração
- **THEN** o sistema remove o arquivo PDF antigo do disco, limpa `SubmissionRecord.pdfPath` no banco SQLite e gera um novo PDF atualizado na próxima solicitação de compartilhamento de PDF

### Requirement: Estruturação Editorial do PDF Resumido Guiada pelo Protocolo YAML
O gerador do PDF Resumido A4 DEVE construir tanto o relatório principal quanto as seções anexas de materiais interpretando obrigatoriamente `registro.yamlConteudo` e aplicando o dicionário de tradução do protocolo correspondente ao idioma efetivo do aplicativo (`assets/protocols/i18n/<locale>/<id_protocolo>.yaml`). O documento DEVE organizar as seções pelos `Bloco`s do protocolo, traduzir todos os identificadores de campos, opções de `DROPDOWN`, escolhas de `selecao_ramo`, listas (`lista_acoes`) e referências de materiais (`ref_materiais`) para seus rótulos humanos (`label` e `sublabel`), omitir integralmente elementos `StepInstrucao` e ocultar campos, sub-listas e blocos vazios.

#### Scenario: Exportação de PDF Resumido com rótulos traduzidos do protocolo e sem campos vazios
- **WHEN** o usuário exporta o PDF Resumido de uma manutenção ou ficha de material a partir do visualizador de relatórios
- **THEN** o documento A4 carrega as traduções do protocolo e fontes para o idioma ativo, exibe o nome traduzido do protocolo, divide as seções pelos `Bloco`s preenchidos, apresenta os rótulos humanos das perguntas e respostas de `DROPDOWN`/`selecao_ramo` e omite todas as instruções do Wizard e campos não respondidos
