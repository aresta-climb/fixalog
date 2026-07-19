# PDF Generator
## Requirements
### Requirement: O sistema DEVE gerar um Rascunho Visual
O módulo gerador de PDF deve criar um rascunho visual (Draft) do documento, posicionando todos os elementos e espaços de assinatura corretamente, para posterior conversão e assinatura.

### Requirement: O sistema DEVE criar Anotações GoToE
O sistema deve suportar a criação de anotações GoToE (Go To Embedded) no PDF. Isso permitirá a navegação e a vinculação direta entre elementos do layout do documento e seus respectivos arquivos embutidos. 

#### Scenario: Vinculação de Arquivos Embutidos (PDF/A-3)
- **WHEN** o Rust processa as referências de mídia e o manifesto `.json`
- **THEN** ele anexa fisicamente esses arquivos ao container do PDF como EmbeddedFiles
- **THEN** ele cria os links GoToE permitindo acesso aos arquivos brutos a partir das miniaturas visuais impressas no PDF

