## MODIFIED Requirements

### Requirement: O sistema DEVE gerar um Rascunho Visual
O módulo gerador de PDF MUST gerar o documento PDF Resumido sob demanda no momento em que o usuário solicita o compartilhamento da versão impressa ou a abertura via histórico, utilizando miniaturas de impressão otimizadas e folhas de estilo (@media print) sem bloquear a finalização do fluxo do Wizard.

#### Scenario: Geração do PDF Resumido para protocolo
- **WHEN** o usuário solicita o compartilhamento da versão resumida em PDF de uma vistoria
- **THEN** o sistema gera o arquivo PDF A4 sob demanda utilizando miniaturas de impressão leves e abre a folha de compartilhamento

## ADDED Requirements

### Requirement: O sistema DEVE manter cache do PDF Resumido gerado sob demanda
Após a primeira geração sob demanda do PDF resumido, o sistema MUST salvar o arquivo no disco local e associar seu caminho ao registro da sessão (`SubmissionRecord.pdfPath`) para que compartilhamentos ou aberturas subsequentes ocorram instantaneamente sem re-renderização.

#### Scenario: Compartilhamento subsequente do PDF já gerado
- **WHEN** o usuário solicita compartilhar o PDF Resumido de um laudo cujo PDF já foi gerado previamente
- **THEN** o sistema reutiliza o arquivo em disco diretamente sem disparar nova conversão pelo motor de impressão
