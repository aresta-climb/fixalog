## ADDED Requirements

### Requirement: Registro Expresso
O sistema DEVE permitir a criação de um registro simplificado a partir da tela inicial.

#### Scenario: Acesso ao formulário
- **WHEN** usuário clica no botão "Novo Registro Expresso" na HomeScreen
- **THEN** sistema navega para a ExpressFormScreen vazia

### Requirement: Captura de Foto e Descrição
O sistema DEVE permitir adicionar múltiplas fotos, cada uma acompanhada de um campo de texto descritivo.

#### Scenario: Adição de item
- **WHEN** usuário clica no FAB de câmera
- **THEN** sistema abre a câmera nativa e, após captura, adiciona um card na lista com a miniatura da imagem e um campo de texto para descrição

### Requirement: Geração do PDF
O sistema DEVE gerar um arquivo PDF sumarizando os dados capturados utilizando a estrutura do Protobuf.

#### Scenario: Geração bem-sucedida
- **WHEN** usuário clica em "Gerar Relatório"
- **THEN** sistema obtém a localização GPS
- **THEN** sistema mapeia as fotos e descrições para instâncias de `DetalheAcaoCustomizada` do Protobuf
- **THEN** sistema exibe a pré-visualização do PDF na tela usando o pacote `printing` contendo os textos, imagens e coordenadas
