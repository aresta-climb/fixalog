# Spec Delta

## MODIFIED Requirements

### Requirement: O sistema DEVE gerar um Rascunho Visual
O módulo gerador de PDF DEVE gerar o documento PDF Resumido A4 sob demanda no momento em que o usuário solicita o compartilhamento da versão impressa ou a abertura via histórico, construindo o arquivo PDF nativamente em Dart sem depender de WebView ou conversão HTML/Base64 e reutilizando diretamente as imagens JPEG de 2MP (`<uuid>_thumb.jpg` e `<uuid>_poster.jpg`) pré-processadas da sessão.

#### Scenario: Geração do PDF Resumido para protocolo
- **WHEN** o usuário solicita o compartilhamento da versão resumida em PDF de uma vistoria
- **THEN** o sistema constrói o arquivo PDF A4 sob demanda lendo diretamente os arquivos JPEG de 2MP pré-processados (sem re-processar as imagens originais nem codificá-las em Base64) e abre a folha de compartilhamento

### Requirement: Renderização Integral das Páginas de Documentos PDF Anexados no PDF Resumido
Ao gerar o PDF Resumido de um registro que contenha documentos PDF anexados (`ArquivoDocumento`), o gerador de PDF DEVE incorporar sequencialmente todas as páginas pré-processadas (`<uuid>_p1_thumb.jpg` até `<uuid>_pN_thumb.jpg`, com fallback para as imagens de página disponíveis) do documento anexado na seção correspondente do relatório impresso.

#### Scenario: Exportação de PDF Resumido contendo comprovante PDF de múltiplas páginas
- **WHEN** o usuário exporta o PDF Resumido de um material ou manutenção que possui um comprovante PDF de 3 páginas anexado
- **THEN** o documento PDF gerado renderiza as 3 páginas pré-processadas do comprovante em sequência, identificadas com o nome original do documento e a numeração de página
