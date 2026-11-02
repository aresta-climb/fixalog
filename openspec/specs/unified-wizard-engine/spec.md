# Motor Unificado de Wizard

## Purpose

Fornece o motor declarativo universal orientado a protocolos YAML e Protobuf para coleta guiada de dados, mídias (fotos, vídeos com salvamento no rolo da câmera e PDFs), coordenadas GPS, listas aninhadas e persistência contínua offline em sessões isoladas.

## Requirements

### Requirement: Arquitetura Protobuf Híbrida
O sistema DEVE utilizar um schema Protobuf genérico (`Registro`) capaz de armazenar meta-dados estritos de sessão e um payload dicionário de tipagem dinâmica.

#### Scenario: Serialização de Respostas
- **WHEN** o motor finalizar a sessão com um dicionário de respostas
- **THEN** o sistema empacota o dicionário no campo genérico `map<string, Resposta>` do Protobuf
- **THEN** o sistema assina o arquivo binário garantindo integridade

### Requirement: Motor Universal de Interface (YAML)
O `WizardScreen` DEVE ser capaz de renderizar e coordenar totalmente as etapas de captura, incluindo componentes nativos de mídia e localização ditados apenas pelo arquivo YAML fornecido, servindo como única tela para qualquer formulário no app, encerrando o último passo diretamente na confirmação de geração sem exigir coleta de assinatura manuscrita em tela.

#### Scenario: Integração de Recursos Nativos
- **WHEN** um `StepCampoSimples` for do tipo `IMAGE`, `VIDEO` ou `GPS`
- **THEN** a interface deve invocar respectivamente a Câmera/Galeria nativa e o serviço de Localização, salvando a saída física no `SessionBundleManager`

#### Scenario: Coleta de Assinatura Digital sem Crash
- **WHEN** o usuário preenche os campos obrigatórios do último passo do protocolo e aciona o botão de conclusão do passo
- **THEN** o Wizard avança diretamente para o card de conclusão do protocolo para geração e assinatura digital criptográfica do relatório, sem exibir modal de assinatura manuscrita em tela

### Requirement: Pipeline de Persistência Unificado
O motor do Wizard DEVE (MUST) persistir continuamente as alterações no manifesto Protobuf (`registro.binarypb`) e no banco local SQLite (`SubmissionRecord`) durante todo o ciclo de preenchimento, garantindo que nenhum progresso seja perdido caso o usuário saia da tela ou feche o app. Ao finalizar a última tela do Wizard, o motor consolida o registro para a geração do relatório final.

#### Scenario: Auto-Save Reativo durante o Preenchimento
- **WHEN** o usuário altera uma resposta de texto, captura uma mídia, seleciona um ramo ou adiciona um item de lista no Wizard
- **THEN** o `WizardStateController` serializa o estado para `registro.binarypb` no Session Bundle
- **THEN** o registro correspondente no banco local SQLite é criado ou atualizado com status `EM_PROGRESSO`

#### Scenario: Flush ao Fechar a Tela
- **WHEN** o usuário sai do `WizardScreen` antes de concluir a geração
- **THEN** qualquer estado pendente é persistido em disco e no banco local SQLite
- **THEN** a sessão fica disponível no Histórico com status `EM_PROGRESSO`

#### Scenario: Geração Final
- **WHEN** o usuário clica em "GERAR RELATÓRIO" no final do Wizard
- **THEN** as mídias são hasheadas (SHA-256) e movidas para o SessionBundle
- **THEN** o manifesto `.binarypb` é gerado
- **THEN** o registro no banco local SQLite é atualizado para o status `GERADO` após a conclusão do relatório
- **THEN** a task de geração do relatório é disparada com o diálogo de progresso

### Requirement: Isolamento de Estado para Wizards Encadeados
O motor do Wizard DEVE isolar o estado de cada sessão em execução como uma instância independente, permitindo que uma tela `WizardScreen` (como o cadastro de um novo material) seja aberta de forma empilhada sobre outra tela `WizardScreen` em andamento (como uma manutenção) sem sobrescrever ou corromper os dados da sessão pai.

#### Scenario: Abrir cadastro de material durante uma manutenção
- **WHEN** o usuário está preenchendo um protocolo de manutenção e aciona a opção de cadastrar um novo material na hora
- **THEN** uma nova instância isolada do `WizardScreen` é aberta para o cadastro do material mantendo o estado da manutenção intacto em segundo plano
- **THEN** ao concluir e gerar o relatório assinado digitalmente do novo material, a tela retorna à manutenção com os dados anteriores preservados e o novo material disponível e selecionado

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
- **THEN** o sistema abre o Wizard de cadastro de materiais em tela dedicada e, após sua conclusão e geração, inclui e seleciona automaticamente o novo material na manutenção atual

### Requirement: Seleção e Rasterização de Documentos PDF em Campos de Mídia
Quando um campo do Wizard permitir captura de documento ou imagem, a interface DEVE oferecer, além da captura por câmera e galeria de fotos, a opção de selecionar um arquivo PDF do dispositivo, armazenando o binário `.pdf` original intacto e as imagens `.webp` rasterizadas de cada página no `SessionBundleManager`.

#### Scenario: Seleção de arquivo PDF no modal de captura do campo
- **WHEN** o usuário toca para anexar um comprovante em um campo que aceita documento ou imagem e escolhe a opção de selecionar arquivo PDF
- **THEN** o sistema abre o seletor de arquivos filtrando por extensão `.pdf`
- **THEN** após a escolha do PDF, o arquivo original é copiado para a sessão, cada página é rasterizada em um arquivo `.webp` numerado e o campo exibe a confirmação visual do documento anexado com sua contagem de páginas

### Requirement: Salvamento no Rolo da Câmera para Mídias Capturadas pela Câmera
Quando o usuário capturar uma foto ou gravar um vídeo diretamente pela câmera do dispositivo dentro do Wizard, o sistema DEVE salvar a mídia original tanto no armazenamento da sessão (`SessionBundleManager`) quanto diretamente no rolo da câmera da galeria do dispositivo, sem criar álbum separado e sem interromper o fluxo do laudo caso o sistema operacional recuse o salvamento na galeria.

#### Scenario: Captura de foto ou vídeo pela câmera nativa
- **WHEN** o usuário escolhe "Tirar Foto com a Câmera" ou "Gravar com a Câmera" em um campo de mídia do Wizard e confirma a captura
- **THEN** o arquivo capturado é salvo no `SessionBundleManager` da sessão atual com cálculo de hash SHA-256
- **THEN** uma cópia do arquivo é salva diretamente no rolo da câmera do dispositivo

#### Scenario: Seleção de mídia já existente na galeria
- **WHEN** o usuário escolhe "Escolher da Galeria" em um campo de mídia do Wizard
- **THEN** os arquivos selecionados são salvos apenas no `SessionBundleManager` da sessão atual, sem duplicá-los no rolo da câmera do dispositivo

#### Scenario: Falha ou permissão negada ao salvar no rolo da câmera
- **WHEN** o usuário captura uma foto ou vídeo pela câmera mas o sistema operacional nega permissão de escrita na galeria ou ocorre falha na API da galeria
- **THEN** a mídia continua salva e anexada normalmente na sessão do relatório sem lançar erro bloqueante para o usuário

### Requirement: Compatibilidade Retroativa com Sessões Legadas que Continham Assinatura em Tela
Ao carregar, editar ou analisar o YAML de uma sessão ou relatório antigo que contenha definições ou respostas do tipo legado `SIGNATURE`, o sistema DEVE ignorar e remover silenciosamente os campos, passos e blocos exclusivos de assinatura manuscrita, permitindo abrir, editar e re-gerar o relatório sem erros.

#### Scenario: Abertura ou edição de relatório antigo contendo passo de assinatura no YAML salvo
- **WHEN** o usuário abre para continuar preenchimento ou editar um registro antigo cujo `yamlConteudo` ou mapa de respostas contenha o tipo `SIGNATURE` (`assinatura_c` ou `mat_assinatura_c`)
- **THEN** o parser e o controlador descartam os conteúdos e passos de assinatura manuscrita e carregam todos os demais dados do relatório normalmente sem apresentar erro
