## Requirements
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
O sistema DEVE gerar um arquivo PDF sumarizando os dados capturados utilizando a estrutura do Protobuf. A estrutura do Protobuf passará a ser um manifesto de referências e não mais de blobs.

#### Scenario: Geração bem-sucedida
- **WHEN** usuário clica em "Gerar Relatório"
- **THEN** sistema obtém a localização GPS
- **THEN** sistema mapeia as fotos e descrições para instâncias de `ReferenciaMidia` injetadas em `DetalheAcaoCustomizada` do Protobuf unificado
- **THEN** o sistema grava o arquivo `registro.json` na pasta da sessão
- **THEN** sistema gera o PDF chamando o core Rust com os caminhos dos arquivos UUID locais para serem renderizados visualmente e anexados

### Requirement: Edição e Restauração
O sistema DEVE permitir carregar os dados de uma sessão existente no Express Form para fins de edição.

#### Scenario: Restauração de Manifesto
- **WHEN** a tela recebe um `id_sessao` no momento da inicialização
- **THEN** o ViewModel lê o arquivo `registro.json` da pasta correspondente e recarrega os caminhos locais (através dos UUIDs) e as descrições no estado da interface

