# Catálogo de Materiais

## Purpose

Permite o cadastro, catalogação, assinatura digital e reutilização de materiais individuais ou conjuntos de materiais de manutenção (comprados prontos ou de fabricação própria), documentando notas fiscais, testes de qualidade e detalhes ou processos de fabricação para inclusão pericial em manutenções.

## Requirements

### Requirement: Entrada de Cadastro de Material na Tela Inicial
O sistema DEVE disponibilizar na tela inicial de novos protocolos um card dedicado para iniciar o protocolo de cadastro de materiais utilizando o motor do Wizard.

#### Scenario: Iniciar cadastro de material pela tela inicial
- **WHEN** o usuário toca no botão de iniciar no card de Cadastro de Materiais na tela inicial
- **THEN** o sistema carrega o protocolo YAML de cadastro de materiais em uma nova sessão do Wizard

### Requirement: Identificação Geral do Registro de Material
O protocolo de cadastro de materiais DEVE coletar na etapa de identificação geral o nome ou descrição identificadora do material/conjunto, o código interno de rastreamento da associação (opcional) e a data do registro preenchida automaticamente com a data atual e editável pelo usuário.

#### Scenario: Preenchimento da identificação geral com data automática
- **WHEN** o usuário inicia o protocolo de cadastro de materiais
- **THEN** o campo de data já se apresenta preenchido com a data atual do dispositivo, permitindo alteração manual
- **THEN** o usuário informa o nome identificador e opcionalmente o código interno da associação

### Requirement: Suporte a Material Único ou Conjunto de Materiais
O protocolo de cadastro de materiais DEVE permitir adicionar um ou múltiplos materiais dentro do mesmo registro antes da assinatura final, possibilitando cadastrar tanto um item isolado quanto um conjunto pronto (como chumbador somado a chapeleta e argola).

#### Scenario: Cadastro de conjunto com múltiplos componentes
- **WHEN** o usuário adiciona um item do tipo "Chumbador Mecânico / Parabolt" e em seguida adiciona um item do tipo "Chapeleta" na lista de materiais do cadastro
- **THEN** ambos os itens são validados e empacotados dentro do mesmo registro de material assinado ao final

### Requirement: Categorias Pré-definidas e Categoria Livre de Material
Ao adicionar um material na lista do cadastro, o sistema DEVE oferecer as opções "Chumbador Mecânico / Parabolt", "Chapeleta", "Chapeleta com Argola", "Ancoragem Química", "Costura permanente" e "Outro". As cinco primeiras opções DEVEM apresentar campos pré-selecionados de produto pronto (como marca, liga metálica, lote, validade para químicos e foto), enquanto a opção "Outro" DEVE omitir campos engessados de produto pronto e focar diretamente na identificação livre e na seção padronizada de detalhes.

#### Scenario: Preenchimento de material pré-definido
- **WHEN** o usuário seleciona "Chumbador Mecânico / Parabolt" ou "Ancoragem Química"
- **THEN** o Wizard exibe os campos técnicos específicos daquele produto pronto seguidos pela seção universal de nota fiscal, testes de qualidade e detalhes

#### Scenario: Preenchimento de material do tipo Outro para fabricação própria
- **WHEN** o usuário seleciona a opção "Outro" para registrar barras roscadas de fabricação própria
- **THEN** o Wizard exibe apenas a identificação básica e a seção universal de nota fiscal, testes de qualidade e lista repetível de detalhes para documentar cada etapa do processo de fabricação

### Requirement: Seção Universal de Nota Fiscal, Testes de Qualidade e Detalhes por Material
Independentemente da categoria escolhida dentre as seis opções, cada material adicionado DEVE conter de forma padronizada campos para anexar Nota Fiscal/Comprovante (aceitando tanto foto quanto arquivo PDF de uma ou múltiplas páginas), uma lista repetível de Testes de Qualidade (aceitando fotos, vídeos curtos ou laudos em PDF) e uma lista repetível de Detalhes Adicionais (permitindo texto descritivo, fotos e vídeos curtos para documentar etapas de fabricação ou especificidades).

#### Scenario: Inclusão de nota fiscal, teste e etapas de fabricação em um material
- **WHEN** o usuário está preenchendo qualquer item de material na lista
- **THEN** ele pode anexar a nota fiscal correspondente via foto ou arquivo PDF, adicionar múltiplos testes de qualidade com fotos, vídeos ou PDFs e adicionar múltiplos blocos de detalhes com o passo a passo de fabricação

#### Scenario: Anexo de Nota Fiscal ou Certificado em PDF com múltiplas páginas
- **WHEN** o usuário seleciona um arquivo PDF de múltiplas páginas como comprovante de nota fiscal ou laudo de teste de qualidade de um material
- **THEN** o sistema preserva o documento PDF original intacto na sessão e gera uma imagem WebP para cada página do documento para exibição e inclusão no relatório

### Requirement: Emissão e Edição de Relatório Assinado de Material
Ao concluir o cadastro de um material, o sistema DEVE exigir a assinatura do mantenedor e gerar um pacote EPUB 3 assinado digitalmente para aquele material, permitindo sua visualização, exportação isolada em EPUB/PDF ou posterior edição e re-assinatura a partir do Histórico.

#### Scenario: Conclusão e assinatura de material
- **WHEN** o usuário assina e conclui o cadastro de um material
- **THEN** o sistema gera o arquivo EPUB 3 assinado do material e o disponibiliza na seção de Materiais do Histórico e na lista de seleção das manutenções
