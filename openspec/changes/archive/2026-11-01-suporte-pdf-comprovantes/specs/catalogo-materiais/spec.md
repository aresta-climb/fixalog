## MODIFIED Requirements

### Requirement: Seção Universal de Nota Fiscal, Testes de Qualidade e Detalhes por Material
Independentemente da categoria escolhida dentre as seis opções, cada material adicionado DEVE conter de forma padronizada campos para anexar Nota Fiscal/Comprovante (aceitando tanto foto quanto arquivo PDF de uma ou múltiplas páginas), uma lista repetível de Testes de Qualidade (aceitando fotos, vídeos curtos ou laudos em PDF) e uma lista repetível de Detalhes Adicionais (permitindo texto descritivo, fotos e vídeos curtos para documentar etapas de fabricação ou especificidades).

#### Scenario: Inclusão de nota fiscal, teste e etapas de fabricação em um material
- **WHEN** o usuário está preenchendo qualquer item de material na lista
- **THEN** ele pode anexar a nota fiscal correspondente via foto ou arquivo PDF, adicionar múltiplos testes de qualidade com fotos, vídeos ou PDFs e adicionar múltiplos blocos de detalhes com o passo a passo de fabricação

#### Scenario: Anexo de Nota Fiscal ou Certificado em PDF com múltiplas páginas
- **WHEN** o usuário seleciona um arquivo PDF de múltiplas páginas como comprovante de nota fiscal ou laudo de teste de qualidade de um material
- **THEN** o sistema preserva o documento PDF original intacto na sessão e gera uma imagem WebP para cada página do documento para exibição e inclusão no relatório
