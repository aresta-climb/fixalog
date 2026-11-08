# Spec Delta

## ADDED Requirements

### Requirement: Estruturação Editorial do PDF Resumido Guiada pelo Protocolo YAML
O gerador do PDF Resumido A4 DEVE construir tanto o relatório principal quanto as seções anexas de materiais interpretando obrigatoriamente `registro.yamlConteudo`. O documento DEVE organizar as seções pelos `Bloco`s do protocolo, traduzir todos os identificadores de campos, opções de `DROPDOWN`, escolhas de `selecao_ramo`, listas (`lista_acoes`) e referências de materiais (`ref_materiais`) para seus rótulos humanos (`label` e `sublabel`), omitir integralmente elementos `StepInstrucao` e ocultar campos, sub-listas e blocos vazios.

#### Scenario: Exportação de PDF Resumido com rótulos do protocolo e sem campos vazios
- **WHEN** o usuário exporta o PDF Resumido de uma manutenção ou ficha de material
- **THEN** o documento A4 exibe o nome do protocolo, divide as seções pelos `Bloco`s preenchidos, apresenta os rótulos humanos das perguntas e respostas de `DROPDOWN`/`selecao_ramo` e omite todas as instruções do Wizard e campos não respondidos

### Requirement: Aninhamento Visual de Sub-listas e Layout em Duas Colunas no PDF Resumido
No documento PDF Resumido A4, o sistema DEVE renderizar os itens de listas repetíveis (`StepListaAcoes`) em cartões numerados que aninhem internamente suas sub-listas filhas e ramos escolhidos, dispor campos simples curtos em grade de duas colunas e organizar fotos em layout lado a lado (duas colunas) identificadas pelo `label` do respectivo campo no protocolo.

#### Scenario: Ficha de material com sub-listas aninhadas e fotos lado a lado no PDF
- **WHEN** o PDF Resumido é gerado contendo itens de lista com múltiplos campos curtos, sub-listas (como testes de qualidade e etapas de fabricação) e múltiplas fotos
- **THEN** o PDF renderiza cada item principal em um cartão numerado contendo os campos curtos distribuídos em duas colunas, as fotos dispostas lado a lado com seus rótulos e os cartões das sub-listas aninhados visualmente dentro do cartão pai
