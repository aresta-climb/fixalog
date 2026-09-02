## Requirements

### Requirement: Registro Expresso
O sistema DEVE permitir a criação de um registro simplificado a partir da tela inicial.

#### Scenario: Acesso ao formulário
- **WHEN** usuário clica no botão "Novo Registro Expresso" na HomeScreen
- **THEN** sistema navega para o WizardScreen, instanciando-o com o protocolo `registro_expresso.yaml`

### Requirement: Captura de Foto e Descrição
O sistema DEVE permitir adicionar múltiplas fotos, cada uma acompanhada de um campo de texto descritivo, guiado estritamente pelas diretrizes do motor dinâmico YAML.

#### Scenario: Adição de item
- **WHEN** usuário clica no botão de adicionar item de lista (conforme definido no yaml)
- **THEN** o motor insere os campos na fila: um componente que abre a câmera nativa (IMAGE) e um de área de texto (TEXT).
- **THEN** a mídia física é roteada para salvamento na sessão correspondente pelo motor central.

### Requirement: Geração do PDF
O sistema DEVE gerar um arquivo PDF sumarizando os dados capturados utilizando a estrutura do Protobuf. A estrutura do Protobuf passará a ser um manifesto unificado Híbrido baseado nas chaves YAML do Express form.

#### Scenario: Geração bem-sucedida
- **WHEN** usuário avança até a conclusão do Wizard Express e clica em "GERAR RELATÓRIO"
- **THEN** o motor extrai todas as respostas de mídia preenchidas, executa os hashes necessários, grava na sessão
- **THEN** o sistema empacota as chaves e valores no payload dinâmico `Registro`
- **THEN** o sistema grava o arquivo `.binarypb` e um `registro.json` derivado (com o payload formatado) na pasta da sessão
- **THEN** sistema gera o PDF chamando o core Rust com os caminhos dos arquivos UUID locais para serem renderizados visualmente e anexados

### Requirement: Edição e Restauração
O sistema DEVE permitir carregar os dados de uma sessão existente no Express Form para fins de edição.

#### Scenario: Restauração de Manifesto
- **WHEN** o WizardScreen recebe um `id_sessao` existente e um `protocol_id="expresso"` no momento da inicialização
- **THEN** o StateController lê o manifesto unificado da pasta correspondente e recarrega os campos de interface preenchendo as respostas baseado nos IDs do payload, restaurando a interface do Wizard.

