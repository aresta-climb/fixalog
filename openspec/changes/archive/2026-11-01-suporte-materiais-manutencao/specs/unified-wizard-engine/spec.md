## ADDED Requirements

### Requirement: Isolamento de Estado para Wizards Encadeados
O motor do Wizard DEVE isolar o estado de cada sessão em execução como uma instância independente, permitindo que uma tela `WizardScreen` (como o cadastro de um novo material) seja aberta de forma empilhada sobre outra tela `WizardScreen` em andamento (como uma manutenção) sem sobrescrever ou corromper os dados da sessão pai.

#### Scenario: Abrir cadastro de material durante uma manutenção
- **WHEN** o usuário está preenchendo um protocolo de manutenção e aciona a opção de cadastrar um novo material na hora
- **THEN** uma nova instância isolada do `WizardScreen` é aberta para o cadastro do material mantendo o estado da manutenção intacto em segundo plano
- **THEN** ao concluir e assinar o novo material, a tela retorna à manutenção com os dados anteriores preservados e o novo material disponível e selecionado

### Requirement: Preenchimento Automático Editável de Data Atual
O motor do Wizard DEVE suportar uma configuração em campos do tipo `DATE` (`preencher_data_atual`) que inicialize automaticamente a resposta do campo com a data corrente do dispositivo no momento do carregamento do passo ou criação do item, permitindo que o usuário altere a data manualmente caso deseje.

#### Scenario: Inicialização de campo de data com a data de hoje
- **WHEN** um passo contendo um `StepCampoSimples` do tipo `DATE` com preenchimento automático habilitado é carregado sem resposta prévia
- **THEN** o campo exibe e registra automaticamente a data atual formatada
- **THEN** o usuário pode tocar no campo para selecionar outra data no calendário se necessário

### Requirement: Listas de Ações Repetíveis Aninhadas
O motor do Wizard DEVE suportar a definição, renderização inline, validação e persistência de elementos `StepListaAcoes` aninhados dentro dos passos de um item de outro `StepListaAcoes`, vinculando os sub-itens ao identificador do item pai.

#### Scenario: Adição e validação de sub-itens em lista aninhada
- **WHEN** o usuário expande um item de uma lista principal (como um material) que contém uma `StepListaAcoes` interna (como detalhes ou testes de qualidade)
- **THEN** a interface renderiza a sub-lista permitindo adicionar, expandir, editar, confirmar e remover sub-itens vinculados exclusivamente àquele item pai
- **THEN** ao salvar a sessão, os sub-itens são persistidos no manifesto `Registro` preservando o vínculo hierárquico com o item pai

### Requirement: Seleção de Materiais do Catálogo Local e Criação Sob Demanda
O componente `StepRefMateriais` DEVE permitir selecionar materiais previamente cadastrados e gerados no catálogo local do dispositivo, exibindo-os ordenados pela data da última seleção (mais recentemente selecionados primeiro), além de disponibilizar um botão para cadastrar um novo material na hora e atualizar o timestamp de última seleção dos materiais escolhidos.

#### Scenario: Seleção de materiais pré-cadastrados ordenados por uso recente
- **WHEN** o usuário acessa a etapa de seleção de materiais no início de uma manutenção
- **THEN** o sistema lista os materiais cadastrados no aplicativo ordenados pelos selecionados mais recentemente no topo
- **THEN** ao selecionar um material, o registro de última seleção daquele material é atualizado

#### Scenario: Cadastrar novo material a partir da seleção na manutenção
- **WHEN** o usuário clica no botão de cadastrar novo material dentro da etapa de seleção de materiais da manutenção
- **THEN** o sistema abre o Wizard de cadastro de materiais em tela dedicada e, após sua conclusão e assinatura, inclui e seleciona automaticamente o novo material na manutenção atual
