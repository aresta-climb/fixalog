# Spec Delta

## ADDED Requirements

### Requirement: Identificação Geral e Seleção Opcional de Materiais no Registro Expresso
O protocolo de Registro Expresso DEVE (MUST) coletar o título/identificação obrigatório do registro (`via_nome`), a data preenchida automaticamente com a data atual (`via_data`), coordenadas GPS opcionais (`via_gps`) e observações gerais opcionais (`observacoes_gerais`), além de oferecer seleção opcional de materiais do catálogo local (`ref_mat_expresso` com `origem_catalogo: true` e `obrigatorio: false`).

#### Scenario: Preenchimento de Registro Expresso com título, data automática e material opcional
- **WHEN** o usuário inicia um Registro Expresso
- **THEN** o campo `via_data` já vem preenchido com a data atual e o usuário informa o título em `via_nome`
- **THEN** o usuário pode opcionalmente selecionar materiais do catálogo local ou concluir o registro sem selecionar materiais

## MODIFIED Requirements

### Requirement: Registro Expresso
O sistema DEVE (MUST) permitir a criação de um registro flexível (*catch-all*) a partir da tela inicial, posicionado como última opção dentre os workflows de vistoria de campo.

#### Scenario: Acesso ao formulário
- **WHEN** usuário clica no botão de iniciar no card "Registro Expresso" na tela inicial
- **THEN** sistema navega para o WizardScreen, instanciando-o com o protocolo `registro_expresso.yaml`

### Requirement: Captura de Foto e Descrição
O protocolo de Registro Expresso DEVE (MUST) permitir adicionar múltiplos itens de evidência em uma lista unificada (`lista_evidencias`), onde cada item possui um campo de mídia unificado (aceitando fotos, vídeos e PDFs) acompanhado de um campo de texto descritivo em Markdown.

#### Scenario: Adição de item
- **WHEN** usuário clica no botão de adicionar evidência na lista do Registro Expresso
- **THEN** o motor insere um item contendo o campo de mídia unificado (para fotos, vídeos ou PDFs) e o campo de descrição textual
- **THEN** a mídia física é roteada para salvamento na sessão correspondente pelo motor central
