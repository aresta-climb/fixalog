# Spec Delta

## ADDED Requirements

### Requirement: Captura Unificada de Mídias em Campos do Wizard
Qualquer campo de mídia do Wizard DEVE (MUST) apresentar um botão de ação unificado (`ADICIONAR MÍDIA` com subtítulo `Fotos, vídeos ou PDFs`) e abrir o seletor unificado permitindo capturar foto pela câmera, gravar vídeo pela câmera, selecionar fotos/vídeos da galeria ou anexar documento PDF no mesmo campo.

#### Scenario: Exibição e acionamento de campo de mídia vazio ou preenchido
- **WHEN** um passo ou item de lista exibe um campo de captura de mídia no Wizard
- **THEN** o botão de captura apresenta o rótulo unificado de adição de mídia e permite anexar tanto fotos quanto vídeos e arquivos PDF no mesmo campo

## MODIFIED Requirements

### Requirement: Seleção de Materiais do Catálogo Local e Criação Sob Demanda
O componente `StepRefMateriais` DEVE (MUST) permitir selecionar materiais previamente cadastrados e gerados no catálogo local do dispositivo diretamente no passo ou dentro do item de ação onde o material é utilizado (`origem_catalogo: true`), exibindo-os ordenados pela data da última seleção (mais recentemente selecionados primeiro), além de disponibilizar um botão para cadastrar um novo material na hora e atualizar o timestamp de última seleção dos materiais escolhidos, sem exigir pré-seleção em bloco anterior.

#### Scenario: Seleção de materiais pré-cadastrados ordenados por uso recente
- **WHEN** o usuário expande uma ação que utiliza materiais (como substituição de ancoragem, novo ponto de ancoragem, proteção instalada ou parada)
- **THEN** o sistema lista os materiais cadastrados no catálogo local ordenados pelos selecionados mais recentemente no topo
- **THEN** ao selecionar um material, o registro de última seleção daquele material é atualizado

#### Scenario: Cadastrar novo material a partir da seleção na manutenção
- **WHEN** o usuário clica no botão de cadastrar novo material dentro do campo `StepRefMateriais` de uma ação da manutenção ou abertura
- **THEN** o sistema abre o Wizard de cadastro de materiais em sessão isolada e, após sua conclusão e geração, inclui e seleciona automaticamente o novo material na ação atual

### Requirement: Compatibilidade Retroativa com Sessões Legadas que Continham Assinatura em Tela
Ao carregar, editar ou duplicar uma sessão existente, o sistema DEVE (MUST) delegar a normalização e atualização do `Registro` ao motor de migração de protocolos (`MigradorProtocoloRegistro`), que remove silenciosamente campos e passos legados de assinatura manuscrita (`SIGNATURE`, `assinatura_c`, `mat_assinatura_c`) e migra o registro para a versão inteira atual do protocolo antes de construir o estado do Wizard.

#### Scenario: Abertura ou edição de relatório antigo contendo passo de assinatura no YAML salvo
- **WHEN** o usuário abre para continuar preenchimento, editar ou duplicar um registro antigo cujo `yamlConteudo` ou mapa de respostas pertença a uma versão anterior ou contenha o tipo `SIGNATURE` (`assinatura_c` ou `mat_assinatura_c`)
- **THEN** o motor de migração transforma o `Registro` para a versão atual do protocolo descartando os campos de assinatura manuscrita e preservando todos os demais dados sem apresentar erro
