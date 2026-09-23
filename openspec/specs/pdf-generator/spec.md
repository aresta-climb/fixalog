# PDF Generator

## Purpose

Exportação de resumo impresso A4 do relatório de manutenção (@media print) contendo informações técnicas, dados da vistoria e QR Codes direcionando para mídias e versão canônica interativa.

## Requirements

### Requirement: O sistema DEVE gerar um Rascunho Visual
O módulo gerador de PDF deve gerar um documento PDF Resumido para protocolo a partir da renderização HTML5/CSS e folhas de estilo de impressão (@media print), posicionando o cabeçalho informativo, os dados da vistoria e os elementos estáticos adequadamente formatados para páginas A4.

#### Scenario: Geração do PDF Resumido para protocolo
- **WHEN** o usuário opta por exportar o resumo em PDF da vistoria
- **THEN** o sistema converte o documento visual em um arquivo PDF A4 legível e formatado via motor de impressão nativo

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
