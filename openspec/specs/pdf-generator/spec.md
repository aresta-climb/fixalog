# PDF Generator

## Purpose

Exportação de resumo impresso A4 do relatório de manutenção (@media print) contendo informações técnicas, dados da vistoria e QR Codes direcionando para mídias e versão canônica interativa.

## Requirements

### Requirement: O sistema DEVE gerar um Rascunho Visual
O módulo gerador de PDF MUST gerar o documento PDF Resumido sob demanda no momento em que o usuário solicita o compartilhamento da versão impressa ou a abertura via histórico, utilizando miniaturas de impressão otimizadas e folhas de estilo (@media print) sem bloquear a finalização do fluxo do Wizard.

#### Scenario: Geração do PDF Resumido para protocolo
- **WHEN** o usuário solicita o compartilhamento da versão resumida em PDF de uma vistoria
- **THEN** o sistema gera o arquivo PDF A4 sob demanda utilizando miniaturas de impressão leves e abre a folha de compartilhamento

### Requirement: O PDF DEVE exibir cabeçalho de versão resumida e QR Code de rastreabilidade
O documento PDF gerado DEVE conter no topo da primeira página uma faixa/cabeçalho informando explicitamente que se trata de uma versão impressa/resumida, acompanhada de link textual clicável e QR Code apontando para a página canônica da vistoria na Web.

#### Scenario: Visualização do cabeçalho no PDF de protocolo
- **WHEN** o PDF é exportado ou impresso a partir da vistoria
- **THEN** a primeira página exibe o aviso institucional com o link e o QR Code direcionando para a versão canônica interativa

### Requirement: O PDF DEVE substituir vídeos por poster frame e QR Code individual
Nas seções onde houver vídeos de inspeção associados a proteções, o PDF DEVE ocultar o player de vídeo interativo e exibir em seu lugar o *poster frame* (imagem estática em alta resolução) acompanhado de um mini QR Code específico para visualização daquele vídeo na Web.

#### Scenario: Inspeção com vídeo no documento impresso
- **WHEN** uma proteção catalogada contém um vídeo de inspeção
- **THEN** o PDF renderiza a foto de capa e um mini QR Code com a legenda para assistir à gravação online

### Requirement: O sistema DEVE manter cache do PDF Resumido gerado sob demanda
Após a primeira geração sob demanda do PDF resumido, o sistema MUST salvar o arquivo no disco local e associar seu caminho ao registro da sessão (`SubmissionRecord.pdfPath`) para que compartilhamentos ou aberturas subsequentes ocorram instantaneamente sem re-renderização.

#### Scenario: Compartilhamento subsequente do PDF já gerado
- **WHEN** o usuário solicita compartilhar o PDF Resumido de um laudo cujo PDF já foi gerado previamente
- **THEN** o sistema reutiliza o arquivo em disco diretamente sem disparar nova conversão pelo motor de impressão

### Requirement: Concatenação dos Relatórios de Materiais no PDF Resumido da Manutenção
Ao gerar o documento PDF Resumido de uma manutenção que utiliza materiais cadastrados, o sistema DEVE anexar ao final do mesmo arquivo PDF, logo após o relatório da manutenção, as seções completas correspondentes aos relatórios de cada material utilizado (incluindo seus dados técnicos, notas fiscais, testes de qualidade, detalhes de fabricação e QR Codes de vídeos).

#### Scenario: Exportação de PDF único contendo manutenção e materiais anexos
- **WHEN** o usuário solicita a geração ou compartilhamento do PDF Resumido de uma manutenção com materiais vinculados
- **THEN** o sistema produz um único arquivo PDF contendo nas primeiras páginas o relatório da manutenção e nas páginas seguintes as fichas completas de todos os materiais utilizados

### Requirement: Renderização Integral das Páginas de Documentos PDF Anexados no PDF Resumido
Ao gerar o PDF Resumido de um registro que contenha documentos PDF anexados (`ArquivoDocumento`), o gerador de PDF DEVE incorporar sequencialmente todas as páginas rasterizadas (`<uuid>_p1.webp` até `<uuid>_pN.webp`) do documento anexado na seção correspondente do relatório impresso.

#### Scenario: Exportação de PDF Resumido contendo comprovante PDF de múltiplas páginas
- **WHEN** o usuário exporta o PDF Resumido de um material ou manutenção que possui um comprovante PDF de 3 páginas anexado
- **THEN** o documento PDF gerado renderiza as 3 páginas rasterizadas do comprovante em sequência, identificadas com o nome original do documento e a numeração de página
