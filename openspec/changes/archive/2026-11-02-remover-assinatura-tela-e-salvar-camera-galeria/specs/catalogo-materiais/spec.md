## MODIFIED Requirements

### Requirement: Suporte a Material Único ou Conjunto de Materiais
O protocolo de cadastro de materiais DEVE permitir adicionar um ou múltiplos materiais dentro do mesmo registro antes da geração final, possibilitando cadastrar tanto um item isolado quanto um conjunto pronto (como chumbador somado a chapeleta e argola).

#### Scenario: Cadastro de conjunto com múltiplos componentes
- **WHEN** o usuário adiciona um item do tipo "Chumbador Mecânico / Parabolt" e em seguida adiciona um item do tipo "Chapeleta" na lista de materiais do cadastro
- **THEN** ambos os itens são validados e empacotados dentro do mesmo registro de material assinado digitalmente ao final

### Requirement: Emissão e Edição de Relatório Assinado de Material
Ao concluir o cadastro de um material, o sistema DEVE gerar diretamente um pacote EPUB 3 assinado digitalmente via XML-DSig para aquele material, sem exigir assinatura manuscrita em tela, permitindo sua visualização, exportação isolada em EPUB/PDF ou posterior edição e re-geração a partir do Histórico.

#### Scenario: Conclusão e assinatura de material
- **WHEN** o usuário conclui o preenchimento dos dados do cadastro de um material e solicita a geração do relatório
- **THEN** o sistema gera o arquivo EPUB 3 assinado digitalmente do material e o disponibiliza na seção de Materiais do Histórico e na lista de seleção das manutenções
