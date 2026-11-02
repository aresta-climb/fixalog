## MODIFIED Requirements

### Requirement: Motor Universal de Interface (YAML)
O `WizardScreen` DEVE ser capaz de renderizar e coordenar totalmente as etapas de captura, incluindo componentes nativos de mídia e localização ditados apenas pelo arquivo YAML fornecido, servindo como única tela para qualquer formulário no app, encerrando o último passo diretamente na confirmação de geração sem exigir coleta de assinatura manuscrita em tela.

#### Scenario: Integração de Recursos Nativos
- **WHEN** um `StepCampoSimples` for do tipo `IMAGE`, `VIDEO` ou `GPS`
- **THEN** a interface deve invocar respectivamente a Câmera/Galeria nativa e o serviço de Localização, salvando a saída física no `SessionBundleManager`

#### Scenario: Coleta de Assinatura Digital sem Crash
- **WHEN** o usuário preenche os campos obrigatórios do último passo do protocolo e aciona o botão de conclusão do passo
- **THEN** o Wizard avança diretamente para o card de conclusão do protocolo para geração e assinatura digital criptográfica do relatório, sem exibir modal de assinatura manuscrita em tela

### Requirement: Isolamento de Estado para Wizards Encadeados
O motor do Wizard DEVE isolar o estado de cada sessão em execução como uma instância independente, permitindo que uma tela `WizardScreen` (como o cadastro de um novo material) seja aberta de forma empilhada sobre outra tela `WizardScreen` em andamento (como uma manutenção) sem sobrescrever ou corromper os dados da sessão pai.

#### Scenario: Abrir cadastro de material durante uma manutenção
- **WHEN** o usuário está preenchendo um protocolo de manutenção e aciona a opção de cadastrar um novo material na hora
- **THEN** uma nova instância isolada do `WizardScreen` é aberta para o cadastro do material mantendo o estado da manutenção intacto em segundo plano
- **THEN** ao concluir e gerar o relatório assinado digitalmente do novo material, a tela retorna à manutenção com os dados anteriores preservados e o novo material disponível e selecionado

### Requirement: Seleção de Materiais do Catálogo Local e Criação Sob Demanda
O componente `StepRefMateriais` DEVE permitir selecionar materiais previamente cadastrados e gerados no catálogo local do dispositivo, exibindo-os ordenados pela data da última seleção (mais recentemente selecionados primeiro), além de disponibilizar um botão para cadastrar um novo material na hora e atualizar o timestamp de última seleção dos materiais escolhidos.

#### Scenario: Seleção de materiais pré-cadastrados ordenados por uso recente
- **WHEN** o usuário acessa a etapa de seleção de materiais no início de uma manutenção
- **THEN** o sistema lista os materiais cadastrados no aplicativo ordenados pelos selecionados mais recentemente no topo
- **THEN** ao selecionar um material, o registro de última seleção daquele material é atualizado

#### Scenario: Cadastrar novo material a partir da seleção na manutenção
- **WHEN** o usuário clica no botão de cadastrar novo material dentro da etapa de seleção de materiais da manutenção
- **THEN** o sistema abre o Wizard de cadastro de materiais em tela dedicada e, após sua conclusão e geração, inclui e seleciona automaticamente o novo material na manutenção atual

## ADDED Requirements

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
