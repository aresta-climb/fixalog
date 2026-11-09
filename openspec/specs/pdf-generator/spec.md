# PDF Generator

## Purpose

Exportação de resumo impresso A4 do relatório de manutenção (@media print) contendo informações técnicas, dados da vistoria e QR Codes direcionando para mídias e versão canônica interativa.

## Requirements

### Requirement: O sistema DEVE gerar um Rascunho Visual
O sistema DEVE (MUST) delegar a exportação e impressão da versão resumida A4 em PDF integralmente para a folha de estilos `@media print` do documento XHTML contido no pacote `.epub` e servida na página web pública (`https://fixalog.app/v/:id`), sem manter geradores locais duplicados de arquivos PDF no aplicativo móvel.

#### Scenario: Geração do PDF Resumido para protocolo
- **WHEN** o usuário aciona a opção discreta de exportar/imprimir PDF na visualização web do relatório (`https://fixalog.app/v/:id` ou `/v/:id/pdf`)
- **THEN** o navegador formata o documento em layout A4 de impressão (`@media print`) exibindo o cabeçalho institucional com QR Code canônico, substituindo vídeos por seus *poster frames* com QR Codes individuais e ocultando a barra de navegação web

### Requirement: O PDF DEVE exibir cabeçalho de versão resumida e QR Code de rastreabilidade
O documento PDF gerado DEVE conter no topo da primeira página uma faixa/cabeçalho informando explicitamente que se trata de uma versão impressa/resumida, acompanhada de link textual clicável e QR Code apontando para a página canônica da vistoria na Web.

#### Scenario: Visualização do cabeçalho no PDF de protocolo
- **WHEN** o PDF é exportado ou impresso a partir da vistoria
- **THEN** a primeira página exibe o aviso institucional com o link e o QR Code direcionando para a versão canônica interativa

### Requirement: O PDF DEVE substituir vídeos por poster frame e QR Code individual
Nas seções onde houver vídeos de inspeção associados a proteções, o PDF DEVE ocultar o player de vídeo interativo e exibir em seu lugar o *poster frame* (imagem estática em alta resolução) acompanhado de um mini QR Code específico para visualização daquele vídeo na Web.

#### Scenario: Inspeção com vídeo no documento impresso
- **WHEN** uma proteção catalogada contém um vídeo de inspeção
- **THEN** o PDF renderiza a foto de capa e um mini QR Code com a legenda para assistir à gravação online

### Requirement: O sistema DEVE manter cache do PDF Resumido gerado sob demanda
O aplicativo móvel NÃO DEVE (MUST NOT) gerar ou armazenar arquivos `.pdf` derivados de relatórios localmente no dispositivo, mantendo exclusivamente o pacote `.epub` assinado (`SubmissionRecord.epubPath`) e o manifesto estruturado (`SubmissionRecord.protobufPath`) no armazenamento local.

#### Scenario: Compartilhamento subsequente do PDF já gerado
- **WHEN** um relatório é gerado e assinado no aplicativo móvel
- **THEN** o sistema persiste apenas o pacote `.epub` assinado e disponibiliza a exportação para PDF através do link web público no navegador

#### Scenario: Invalidação do cache de PDF ao re-gerar o relatório EPUB
- **WHEN** um relatório existente é re-editado e re-gerado no aplicativo
- **THEN** o sistema atualiza o pacote `.epub` assinado e garante que `pdfPath` permaneça vazio no registro local

### Requirement: Concatenação dos Relatórios de Materiais no PDF Resumido da Manutenção
Ao renderizar na web (`https://fixalog.app/v/:id`) uma manutenção que utiliza materiais cadastrados em `OEBPS/materiais/<uuid>/OEBPS/relatorio.xhtml`, o sistema DEVE (MUST) incluir ao final do documento as seções completas correspondentes aos relatórios de cada material utilizado para que a exportação/impressão em PDF pelo navegador (`@media print`) produza um documento único contendo a manutenção seguida das fichas completas dos materiais vinculados.

#### Scenario: Exportação de PDF único contendo manutenção e materiais anexos
- **WHEN** o usuário aciona a impressão/exportação para PDF no navegador em um relatório de manutenção com materiais vinculados
- **THEN** a versão impressa inclui nas primeiras páginas o relatório da manutenção e nas páginas seguintes as fichas completas de todos os materiais utilizados extraídas do próprio `.epub`

### Requirement: Renderização Integral das Páginas de Documentos PDF Anexados no PDF Resumido
Ao gerar o PDF Resumido de um registro que contenha documentos PDF anexados (`ArquivoDocumento`), o gerador de PDF DEVE incorporar sequencialmente todas as páginas pré-processadas (`<uuid>_p1_thumb.jpg` até `<uuid>_pN_thumb.jpg`, com fallback para as imagens de página disponíveis) do documento anexado na seção correspondente do relatório impresso.

#### Scenario: Exportação de PDF Resumido contendo comprovante PDF de múltiplas páginas
- **WHEN** o usuário exporta o PDF Resumido de um material ou manutenção que possui um comprovante PDF de 3 páginas anexado
- **THEN** o documento PDF gerado renderiza as 3 páginas pré-processadas do comprovante em sequência, identificadas com o nome original do documento e a numeração de página

### Requirement: Estruturação Editorial do PDF Resumido Guiada pelo Protocolo YAML
O gerador do PDF Resumido A4 DEVE construir tanto o relatório principal quanto as seções anexas de materiais interpretando obrigatoriamente `registro.yamlConteudo` e aplicando o dicionário de tradução do protocolo correspondente ao idioma efetivo do aplicativo (`assets/protocols/i18n/<locale>/<id_protocolo>.yaml`). O documento DEVE organizar as seções pelos `Bloco`s do protocolo, traduzir todos os identificadores de campos, opções de `DROPDOWN`, escolhas de `selecao_ramo`, listas (`lista_acoes`) e referências de materiais (`ref_materiais`) para seus rótulos humanos (`label` e `sublabel`), omitir integralmente elementos `StepInstrucao` e ocultar campos, sub-listas e blocos vazios.

#### Scenario: Exportação de PDF Resumido com rótulos traduzidos do protocolo e sem campos vazios
- **WHEN** o usuário exporta o PDF Resumido de uma manutenção ou ficha de material a partir do visualizador de relatórios
- **THEN** o documento A4 carrega as traduções do protocolo e fontes para o idioma ativo, exibe o nome traduzido do protocolo, divide as seções pelos `Bloco`s preenchidos, apresenta os rótulos humanos das perguntas e respostas de `DROPDOWN`/`selecao_ramo` e omite todas as instruções do Wizard e campos não respondidos

### Requirement: Aninhamento Visual de Sub-listas e Layout em Duas Colunas no PDF Resumido
No documento PDF Resumido A4, o sistema DEVE renderizar os itens de listas repetíveis (`StepListaAcoes`) em cartões numerados que aninhem internamente suas sub-listas filhas e ramos escolhidos, dispor campos simples curtos em grade de duas colunas e organizar fotos em layout lado a lado (duas colunas) identificadas pelo `label` do respectivo campo no protocolo.

#### Scenario: Ficha de material com sub-listas aninhadas e fotos lado a lado no PDF
- **WHEN** o PDF Resumido é gerado contendo itens de lista com múltiplos campos curtos, sub-listas (como testes de qualidade e etapas de fabricação) e múltiplas fotos
- **THEN** o PDF renderiza cada item principal em um cartão numerado contendo os campos curtos distribuídos em duas colunas, as fotos dispostas lado a lado com seus rótulos e os cartões das sub-listas aninhados visualmente dentro do cartão pai

### Requirement: Emissão do PDF Resumido no Idioma Ativo com Fontes Noto Sans Offline e Suporte RTL
O gerador de PDF Resumido DEVE (MUST) construir o documento A4 no idioma em que o relatório foi emitido, traduzindo cabeçalhos, avisos institucionais, rótulos de campos e valores de opções do protocolo, carregando sob demanda a partir dos assets locais as fontes TTF da família Google Noto Sans (`NotoSans` base, adicionando `NotoSansArabic` para `ar` com direção `RTL` ou `NotoSansJP` para `ja`) para garantir renderização 100% offline sem falha de glifos.

#### Scenario: Exportação de PDF Resumido em Japonês offline
- **WHEN** o usuário exporta o PDF Resumido de um relatório em Japonês (`ja`) sem conexão com a internet
- **THEN** o gerador incorpora a fonte local `NotoSansJP` e `NotoSans` e renderiza todos os ideogramas CJK, cabeçalhos e rótulos de campos traduzidos sem caracteres ausentes

#### Scenario: Exportação de PDF Resumido em Árabe com layout RTL
- **WHEN** o usuário exporta o PDF Resumido de um relatório em Árabe (`ar`)
- **THEN** o gerador incorpora a fonte local `NotoSansArabic`, aplica direcionalidade da direita para a esquerda (`RTL`) na página e renderiza os textos e rótulos em Árabe
