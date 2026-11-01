## ADDED Requirements

### Requirement: Renderização Integral das Páginas de Documentos PDF Anexados no PDF Resumido
Ao gerar o PDF Resumido de um registro que contenha documentos PDF anexados (`ArquivoDocumento`), o gerador de PDF DEVE incorporar sequencialmente todas as páginas rasterizadas (`<uuid>_p1.webp` até `<uuid>_pN.webp`) do documento anexado na seção correspondente do relatório impresso.

#### Scenario: Exportação de PDF Resumido contendo comprovante PDF de múltiplas páginas
- **WHEN** o usuário exporta o PDF Resumido de um material ou manutenção que possui um comprovante PDF de 3 páginas anexado
- **THEN** o documento PDF gerado renderiza as 3 páginas rasterizadas do comprovante em sequência, identificadas com o nome original do documento e a numeração de página
