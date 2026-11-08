# Protocolos de Vistoria e Migração

## Purpose

Padroniza a ordem, estrutura de blocos e campos dos workflows de vistoria de vias de escalada (`inspecao_visual`, `manutencao`, `abertura_vias` e `registro_expresso`), além de estabelecer o versionamento numérico sequencial dos protocolos YAML e a migração determinística em cadeia (`v -> v + 1`) de registros entre versões.

## ADDED Requirements

### Requirement: Ordem e Disponibilização dos Workflows na Tela Inicial
A tela inicial de novos protocolos DEVE (MUST) apresentar os cards de workflows na seguinte ordem:
1. Inspeção Visual de Proteções Fixas (`assets/protocols/inspecao_visual.yaml`)
2. Manutenção de Proteções Fixas (`assets/protocols/manutencao.yaml`)
3. Abertura de Via (`assets/protocols/abertura_vias.yaml`)
4. Registro Expresso (`assets/protocols/registro_expresso.yaml`)
5. Cadastro de Materiais (`assets/protocols/cadastro_material.yaml`)

#### Scenario: Exibição ordenada dos protocolos na tela inicial
- **WHEN** o usuário acessa a tela de criação de novo registro
- **THEN** o sistema exibe os cards exatamente na sequência: Inspeção Visual, Manutenção, Abertura de Via, Registro Expresso e Cadastro de Materiais

### Requirement: Protocolo Completo de Inspeção Visual Ponto a Ponto
O protocolo `inspecao_visual` DEVE (MUST) ser estruturado em três blocos sem intervenção mecânica e sem recomendação ou seleção de materiais:
1. Identificação da Via: Data da inspeção preenchida automaticamente (`via_data`), localização GPS obrigatória (`via_gps`), nome da via obrigatório (`via_nome`), setor (`via_setor`) e pico/área (`via_pico`).
2. Inspeção Ponto a Ponto (`lista_acoes` obrigatória com mínimo de 1 item): Permite registrar avaliações individuais de *Proteção / Ancoragem*, *Parada / Rapel* e *Rocha / Ambiente*, coletando posição/identificação, estado visual, presença de corrosão (para proteções e paradas), observações e mídias de evidência.
3. Situação Final da Via: Avaliação da condição final para escalada (*Liberada para escalada*, *Liberada com restrição* ou *Interditada*) e resumo geral da inspeção.

#### Scenario: Preenchimento de inspeção visual com múltiplos pontos
- **WHEN** o usuário inicia uma Inspeção Visual, informa os dados e GPS da via, adiciona avaliações ponto a ponto de proteções e paradas e define a condição final da via
- **THEN** o sistema valida todos os campos obrigatórios sem exigir ou exibir seleção de materiais de manutenção e gera o laudo pericial da inspeção

### Requirement: Protocolo de Manutenção com Seleção de Materiais Direto nas Ações
O protocolo `manutencao` (`assets/protocols/manutencao.yaml`) NÃO DEVE (MUST NOT) exigir um bloco inicial separado de pré-seleção de materiais, iniciando diretamente na Identificação da Via (com data automática `via_data`, GPS `via_gps`, nome `via_nome`, setor, pico e permissão do conquistador), seguido pelo bloco de Ações de Manutenção e pelo bloco de Avaliação e Encerramento. A seleção obrigatória de materiais do catálogo (`origem_catalogo: true` com botão de criação sob demanda) DEVE (MUST) ocorrer diretamente dentro das ações que instalam ferragens (substituição de ancoragem com reuso de furo, substituição em novo local e novo ponto de ancoragem) e de forma opcional na ação *Outra Ação*.

#### Scenario: Manutenção sem instalação de ferragens
- **WHEN** o usuário realiza uma manutenção contendo apenas ações de *Limpeza de Vegetação*, *Remoção de Bloco Solto* ou *Inspeção de Ancoragem* com resultado *Aprovado* ou *Reaperto*
- **THEN** o sistema permite concluir e gerar o relatório de manutenção sem exigir nenhum material cadastrado ou selecionado

#### Scenario: Manutenção com substituição ou novo ponto de ancoragem
- **WHEN** o usuário adiciona uma ação de *Novo Ponto de Ancoragem* ou *Substituição necessária* durante a manutenção
- **THEN** a própria ação exibe a seleção de materiais diretamente do catálogo local (`ref_mat_*`) e o botão para cadastrar um novo material na hora

### Requirement: Protocolo Completo de Abertura de Via com Materiais do Catálogo
O protocolo `abertura_vias` DEVE (MUST) ser estruturado em três blocos completos:
1. Identificação da Nova Via: Data automática (`via_data`), localização GPS da base obrigatória (`via_gps`), nome da via obrigatório (`via_nome`), conquistador(es) (`via_conquistadores`), graduação estimada (`via_graduacao`), extensão/enfiadas (`via_extensao`), setor (`via_setor`), pico (`via_pico`) e mídia obrigatória da linha/setor (`via_foto_linha`).
2. Proteções e Ações da Conquista (`lista_acoes` com mínimo de 1 item): Suporta *Proteção Fixa Instalada* e *Parada / Rapel Instalado* (ambos exigindo seleção de materiais diretamente do catálogo local via `ref_mat_*` com botão de criar material e mídia após instalação), além de *Remoção de Bloco Solto*, *Limpeza de Vegetação* e *Outra Ação* (com seleção opcional de materiais).
3. Avaliação e Encerramento: Condição da via (*Liberada para escalada*, *Em conquista / Projeto em aberto* ou *Liberada com restrição*) e recomendações/equipamento para repetição.

#### Scenario: Registro de conquista com instalação de proteções e paradas
- **WHEN** o usuário preenche uma Abertura de Via e adiciona pontos de *Proteção Fixa Instalada* e *Parada / Rapel Instalado* selecionando materiais do catálogo local
- **THEN** o relatório EPUB 3 e o PDF Resumido da abertura compilam e incorporam automaticamente as fichas assinadas de todos os materiais utilizados na conquista

### Requirement: Versionamento Inteiro Sequencial e Migração em Cadeia de Protocolos
Todo protocolo YAML DEVE (MUST) declarar sua versão como um número inteiro sequencial positivo (`1`, `2`, `3`...), e o sistema DEVE (MUST) normalizar versões semver legadas (`"1.0.0"`, `"2.1.0"`) como versão `1`. Ao carregar um registro cuja versão seja inferior à versão atual do protocolo correspondente, o sistema DEVE (MUST) executar em sequência todos os migradores intermediários (`v -> v + 1`) até atingir a versão atual, atualizando o `idProtocolo`, `versaoProtocolo`, `yamlConteudo` e migrando as chaves de respostas e listas sem perda de dados.

#### Scenario: Migração automática de relatório legado de manutenção ou versão anterior
- **WHEN** o usuário abre para continuar, editar ou duplicar um registro salvo em uma versão anterior (como `manutencao_ferragens` v1, `abertura_via_v1` v1, `inspecao_visual_v1` v1 ou `registro_expresso` v1)
- **THEN** o sistema executa a cadeia de migrações desde a versão original do registro até a versão inteira atual do protocolo, preservando todas as respostas, mídias e seleções de materiais já preenchidas no novo formato

### Requirement: Verificação Automática de Integridade de Versão e Cadeia de Migradores
O sistema DEVE (MUST) validar automaticamente a integridade dos protocolos YAML em relação às assinaturas estruturais de suas versões e à existência de todos os passos de migração (`1 -> 2`, ..., `(N-1) -> N`) para qualquer protocolo cuja versão atual seja `N > 1`.

#### Scenario: Detecção de alteração estrutural de protocolo ou ausência de migrador
- **WHEN** os campos ou estrutura de um protocolo YAML são modificados sem incremento da versão inteira ou sem o registro do migrador correspondente `(N-1) -> N`
- **THEN** a verificação de integridade reporta falha apontando o protocolo divergente e o passo de migração ausente
