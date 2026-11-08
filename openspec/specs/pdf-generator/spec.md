# PDF Generator

## Purpose

Exportação de resumo impresso A4 do relatório de manutenção (@media print) contendo informações técnicas, dados da vistoria e QR Codes direcionando para mídias e versão canônica interativa.

## Requirements

### Requirement: O sistema DEVE gerar um Rascunho Visual
O módulo gerador de PDF DEVE gerar o documento PDF Resumido A4 sob demanda no momento em que o usuário solicita o compartilhamento da versão impressa ou a abertura via histórico, construindo o arquivo PDF nativamente em Dart sem depender de WebView ou conversão HTML/Base64 e reutilizando diretamente as imagens JPEG de 2MP (`<uuid>_thumb.jpg` e `<uuid>_poster.jpg`) pré-processadas da sessão.

#### Scenario: Geração do PDF Resumido para protocolo
- **WHEN** o usuário solicita o compartilhamento da versão resumida em PDF de uma vistoria
- **THEN** o sistema constrói o arquivo PDF A4 sob demanda lendo diretamente os arquivos JPEG de 2MP pré-processados (sem re-processar as imagens originais nem codificá-las em Base64) e abre a folha de compartilhamento

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
Ao gerar o PDF Resumido de um registro que contenha documentos PDF anexados (`ArquivoDocumento`), o gerador de PDF DEVE incorporar sequencialmente todas as páginas pré-processadas (`<uuid>_p1_thumb.jpg` até `<uuid>_pN_thumb.jpg`, com fallback para as imagens de página disponíveis) do documento anexado na seção correspondente do relatório impresso.

#### Scenario: Exportação de PDF Resumido contendo comprovante PDF de múltiplas páginas
- **WHEN** o usuário exporta o PDF Resumido de um material ou manutenção que possui um comprovante PDF de 3 páginas anexado
- **THEN** o documento PDF gerado renderiza as 3 páginas pré-processadas do comprovante em sequência, identificadas com o nome original do documento e a numeração de página

### Requirement: Estruturação Editorial do PDF Resumido Guiada pelo Protocolo YAML
O gerador do PDF Resumido A4 DEVE construir tanto o relatório principal quanto as seções anexas de materiais interpretando obrigatoriamente `registro.yamlConteudo`. O documento DEVE organizar as seções pelos `Bloco`s do protocolo, traduzir todos os identificadores de campos, opções de `DROPDOWN`, escolhas de `selecao_ramo`, listas (`lista_acoes`) e referências de materiais (`ref_materiais`) para seus rótulos humanos (`label` e `sublabel`), omitir integralmente elementos `StepInstrucao` e ocultar campos, sub-listas e blocos vazios.

#### Scenario: Exportação de PDF Resumido com rótulos do protocolo e sem campos vazios
- **WHEN** o usuário exporta o PDF Resumido de uma manutenção ou ficha de material
- **THEN** o documento A4 exibe o nome do protocolo, divide as seções pelos `Bloco`s preenchidos, apresenta os rótulos humanos das perguntas e respostas de `DROPDOWN`/`selecao_ramo` e omite todas as instruções do Wizard e campos não respondidos

### Requirement: Aninhamento Visual de Sub-listas e Layout em Duas Colunas no PDF Resumido
No documento PDF Resumido A4, o sistema DEVE renderizar os itens de listas repetíveis (`StepListaAcoes`) em cartões numerados que aninhem internamente suas sub-listas filhas e ramos escolhidos, dispor campos simples curtos em grade de duas colunas e organizar fotos em layout lado a lado (duas colunas) identificadas pelo `label` do respectivo campo no protocolo.

#### Scenario: Ficha de material com sub-listas aninhadas e fotos lado a lado no PDF
- **WHEN** o PDF Resumido é gerado contendo itens de lista com múltiplos campos curtos, sub-listas (como testes de qualidade e etapas de fabricação) e múltiplas fotos
- **THEN** o PDF renderiza cada item principal em um cartão numerado contendo os campos curtos distribuídos em duas colunas, as fotos dispostas lado a lado com seus rótulos e os cartões das sub-listas aninhados visualmente dentro do cartão pai
