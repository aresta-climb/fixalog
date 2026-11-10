# EPUB 3 Report

## Purpose

Gera o documento canônico de relatório técnico de manutenção no formato aberto EPUB 3, contendo layout responsivo em HTML5/CSS, múltiplos vídeos de inspeção em alta definição, metadados estruturados em Protobuf e assinatura digital criptográfica W3C XML-DSig.

## Requirements

### Requirement: O sistema DEVE gerar um container EPUB 3 padronizado
O sistema DEVE (MUST) compilar o relatório técnico de vistoria em um arquivo de extensão `.epub` aderente à especificação EPUB 3 (OCF/W3C), empacotando o arquivo `mimetype` sem compressão no início do arquivo, aplicando compressão `DEFLATE` aos metadados, documentos XHTML, folhas de estilo CSS, assinaturas XML, manifesto YAML (`OEBPS/dados/registro.yaml`) e schemas `.proto` (`OEBPS/dados/registro.proto` e `OEBPS/dados/wizard.proto`), e armazenando os ativos de mídia já comprimidos (`.mp4`, `.webp`, `.jpg`, `.jpeg`, `.png`, `.pdf`) no modo `STORE` (`CompressionType.none`) para evitar recompressão redundante de CPU.

#### Scenario: Geração do container EPUB 3 com dados da vistoria
- **WHEN** o usuário conclui o preenchimento da vistoria no aplicativo e solicita a geração do relatório
- **THEN** o sistema compila um arquivo `.epub` válido onde os arquivos `.xhtml`, `.css`, `.opf`, `.xml`, `.yaml` e `.proto` são comprimidos com `DEFLATE` e os arquivos de mídia em `OEBPS/midias/` e `OEBPS/materiais/` são armazenados com `CompressionType.none` (`STORE`)

### Requirement: O sistema DEVE embutir e reproduzir múltiplos vídeos e fotos no EPUB 3
O sistema DEVE (MUST) incorporar arquivos de vídeo MP4 (codec H.264 720p CRF 26 `-preset veryfast` / áudio mono AAC 64k / faststart) e fotos em formato WebP (resolução de até 4MP e qualidade 85) no manifesto do EPUB 3, sem impor limites arbitrários à quantidade total de mídias. Os vídeos DEVEM (MUST) ser referenciados semanticamente via tags HTML5 `<video controls>` com imagem de capa (*poster frame*) estática em formato JPEG (`<uuid>_poster.jpg`) e DEVEM (MUST) ser acompanhados em `OEBPS/midias/` por miniaturas JPEG altamente comprimidas (`360p`, qualidade leve) extraídas a cada 10 segundos de vídeo (`<uuid>_kf_10s.jpg`, `<uuid>_kf_20s.jpg`, ...), todas declaradas no `content.opf` e assinadas no `META-INF/signatures.xml` para auditoria pericial e moderação de segurança no servidor.

#### Scenario: Vistoria com múltiplos vídeos e fotos de proteções
- **WHEN** a sessão de manutenção inclui vídeos e fotos documentando o estado das proteções
- **THEN** todas as mídias pré-processadas ou transcodificadas são empacotadas em `OEBPS/midias/` (incluindo `<uuid>.mp4`, `<uuid>_poster.jpg` e as miniaturas de keyframes `<uuid>_kf_<N>s.jpg` a cada 10 segundos de vídeo), assinadas em `META-INF/signatures.xml` e renderizadas com controles nativos de reprodução

### Requirement: O sistema DEVE preservar mídias originais para re-geração
O sistema DEVE manter os arquivos brutos originais de fotos e vídeos gravados no dispositivo com o sufixo _original dentro do armazenamento local da sessão (sessoes/<sessionId>/), garantindo que futuras compilações do EPUB sejam realizadas a partir da mídia matriz sem perda cumulativa de qualidade.

#### Scenario: Re-geração do relatório a partir do Histórico
- **WHEN** o usuário solicita a re-emissão de um relatório existente
- **THEN** a esteira de compressão consome os arquivos originais preservados no disco local para montar o novo artefato EPUB 3

### Requirement: O sistema DEVE assinar digitalmente o EPUB 3 com XML-DSig
O sistema DEVE (MUST) proteger a integridade do relatório gerando o arquivo `META-INF/signatures.xml` conforme a recomendação W3C XML Signature (XML-DSig). O arquivo DEVE (MUST) conter os resumos criptográficos SHA-256 de todos os arquivos do manifesto (incluindo páginas XHTML, mídias e Protobuf), a assinatura calculada com a chave privada ECDSA (`secp256r1`) do mantenedor, o certificado X.509 correspondente e o atestado OIDC assinado pelo provedor social (`atestado_oidc_jwt`) que vincula criptograficamente a chave pública ECDSA à conta Google/Apple do autor via `nonce`.

#### Scenario: Verificação de integridade do container assinado
- **WHEN** o relatório EPUB 3 é finalizado pelo mantenedor
- **THEN** o arquivo `META-INF/signatures.xml` é gerado contendo os digests de cada componente, a assinatura criptográfica vinculada ao certificado do mantenedor e o `atestado_oidc_jwt` comprovando a posse da conta Google/Apple no momento da geração da chave

### Requirement: O sistema DEVE embutir os dados brutos Protobuf no container
O sistema DEVE (MUST) serializar o modelo `Registro` em texto legível no arquivo `OEBPS/dados/registro.yaml` (contendo todas as respostas, listas e o `yamlConteudo` do protocolo em bloco multiline) e incluir os schemas formais `OEBPS/dados/registro.proto` e `OEBPS/dados/wizard.proto` dentro da estrutura do EPUB 3, todos devidamente declarados no manifesto `content.opf` e protegidos pelo cálculo de hash SHA-256 na assinatura digital `META-INF/signatures.xml`. Na leitura de containers EPUB 3, o sistema DEVE (MUST) reconstruir e validar estaticamente a instância `Registro` a partir de `OEBPS/dados/registro.yaml`, mantendo compatibilidade retroativa de leitura com containers antigos que possuam `OEBPS/dados/registro.binarypb`.

#### Scenario: Auditoria técnica automatizada
- **WHEN** um sistema terceiro ou auditor humano abre o arquivo `.epub` da vistoria
- **THEN** ele encontra em `OEBPS/dados/` o arquivo `registro.yaml` legível em texto puro junto com os schemas `registro.proto` e `wizard.proto`, e o aplicativo reconstrói a estrutura tipada `Registro` validando os campos contra o schema Protobuf

### Requirement: Incorporação de Materiais Extraídos sem Duplicação no EPUB 3 da Manutenção
Ao gerar o container EPUB 3 de qualquer relatório de vistoria (Manutenção, Abertura de Via ou Registro Expresso) que referencie materiais cadastrados em campos de nível raiz ou dentro de itens de lista (`ref_mat_*`), o sistema DEVE (MUST) compilar o conjunto único de todos os materiais referenciados no relatório e incorporar o conteúdo extraído do pacote `.epub` de cada material utilizado dentro do diretório `OEBPS/materiais/<uuid_material>/` do EPUB gerado, mantendo os dados estruturados (`OEBPS/dados/registro.yaml`, `OEBPS/dados/registro.proto` e `OEBPS/dados/wizard.proto`, ou `OEBPS/dados/registro.binarypb` em materiais legados) e a assinatura `META-INF/signatures.xml` originais do material intactos dentro dessa subpasta para permitir validação criptográfica independente sem duplicar mídias.

#### Scenario: Empacotamento e verificação de material aninhado no EPUB da manutenção
- **WHEN** o relatório EPUB 3 de uma manutenção, abertura de via ou registro expresso contendo materiais selecionados dentro das ações (`ref_mat_*`) é gerado e assinado
- **THEN** o sistema coleta automaticamente todos os UUIDs únicos de materiais referenciados nas ações e grava a árvore extraída do EPUB de cada material em `OEBPS/materiais/<uuid_material>/` contendo seu `META-INF/signatures.xml` e `OEBPS/dados/registro.yaml` (ou `registro.binarypb` legado) originais
- **THEN** a assinatura `META-INF/signatures.xml` na raiz assina todos os arquivos do pacote principal e das subpastas de materiais
- **THEN** a assinatura original do material continua válida se verificada isoladamente a partir da subpasta `OEBPS/materiais/<uuid_material>/`

### Requirement: Navegação por Hiperlinks de Ida e Volta entre Manutenção e Materiais no EPUB 3
O documento `relatorio.xhtml` da manutenção DEVE renderizar as referências aos materiais utilizados como hiperlinks apontando para o documento `materiais/<uuid_material>/OEBPS/relatorio.xhtml` correspondente, e o documento XHTML do material DEVE disponibilizar um botão ou controle de retorno que permita ao leitor voltar exatamente ao ponto de leitura anterior no relatório da manutenção.

#### Scenario: Navegar para os detalhes do material e retornar à manutenção
- **WHEN** o usuário visualiza o relatório da manutenção e clica na referência de um material utilizado
- **THEN** o visualizador navega para a página de detalhes daquele material exibindo seus componentes, notas fiscais, testes e etapas de fabricação
- **THEN** ao acionar o botão de voltar na página do material, o visualizador retorna ao relatório da manutenção na posição onde o usuário estava

### Requirement: Atualização de Materiais ao Re-gerar Relatório de Manutenção
Quando um relatório de manutenção previamente gerado for editado ou re-gerado, o sistema DEVE buscar a versão assinada mais recente de cada material referenciado no catálogo local para atualizar a subpasta `OEBPS/materiais/<uuid_material>/`, mantendo como fallback a cópia já embutida no EPUB anterior caso o material tenha sido excluído do catálogo local.

#### Scenario: Re-gerar manutenção após atualização de um material no catálogo
- **WHEN** um material é editado e re-assinado no catálogo e posteriormente o usuário re-gera o relatório de uma manutenção que utiliza esse material
- **THEN** o novo EPUB 3 da manutenção incorpora a versão atualizada do material

### Requirement: Empacotamento de Documentos PDF Originais e Páginas Rasterizadas no EPUB 3
Quando o registro contiver um documento PDF anexado (`ArquivoDocumento`), o gerador de EPUB 3 DEVE empacotar o binário original intacto em `OEBPS/midias/<uuid>.pdf` (declarado no `content.opf` com `media-type="application/pdf"` e assinado no `META-INF/signatures.xml`) e empacotar cada página rasterizada em `OEBPS/midias/<uuid>_p<N>.webp`, exibindo todas as páginas sequencialmente no `relatorio.xhtml` junto a um link direto para abrir ou baixar o documento PDF original.

#### Scenario: Geração de EPUB 3 com nota fiscal em PDF assinado de múltiplas páginas
- **WHEN** um relatório EPUB 3 é gerado contendo uma nota fiscal anexada em formato PDF com 2 páginas
- **THEN** o pacote EPUB 3 inclui `OEBPS/midias/<uuid>.pdf` preservado bit-a-bit (mantendo eventual assinatura gov.br/ICP-Brasil) e as imagens `OEBPS/midias/<uuid>_p1.webp` e `OEBPS/midias/<uuid>_p2.webp`
- **THEN** o `META-INF/signatures.xml` inclui os resumos SHA-256 tanto do `.pdf` original quanto de cada `.webp` de página
- **THEN** o `relatorio.xhtml` renderiza as imagens das 2 páginas na ordem correta e exibe um link apontando para `midias/<uuid>.pdf`

### Requirement: Estruturação Semântica do Relatório Guiada pelo Protocolo YAML
O sistema DEVE construir o documento `relatorio.xhtml` do EPUB 3 interpretando obrigatoriamente a definição do protocolo contida em `registro.yamlConteudo`. O relatório DEVE organizar as seções pelos `Bloco`s do protocolo e traduzir todos os identificadores de campos, opções de `DROPDOWN`, escolhas de `selecao_ramo`, listas (`lista_acoes`) e referências de materiais (`ref_materiais`) para seus rótulos humanos (`label` e `sublabel`) definidos no YAML, sem exibir chaves internas brutas.

#### Scenario: Renderização de protocolo com blocos, dropdowns e ramos traduzidos
- **WHEN** o sistema gera o relatório EPUB 3 de um registro contendo `yamlConteudo` preenchido com blocos, campos `DROPDOWN` e escolhas de `selecao_ramo`
- **THEN** o `relatorio.xhtml` exibe o nome e versão do protocolo no cabeçalho, divide as seções pelos títulos e subtítulos dos `Bloco`s e apresenta os `label` e `sublabel` humanos de cada pergunta e opção escolhida em vez dos IDs técnicos

### Requirement: Omissão de Instruções do Wizard e de Campos Opcionais Vazios no Relatório
Ao gerar o relatório EPUB 3, o sistema DEVE omitir integralmente todos os elementos de orientação (`StepInstrucao`) e DEVE ocultar quaisquer campos opcionais, listas repetíveis, passos ou blocos que não possuam respostas preenchidas no registro.

#### Scenario: Protocolo contendo instruções de preenchimento e campos opcionais em branco
- **WHEN** um registro é compilado para EPUB 3 a partir de um protocolo que possui cards `instrucao` e campos ou sub-listas opcionais não preenchidos pelo usuário
- **THEN** nenhum título ou corpo de `StepInstrucao` é incluído no `relatorio.xhtml` e os campos, sub-listas e blocos sem respostas são omitidos do documento final

### Requirement: Aninhamento Recursivo de Ramos Condicionais e Sub-listas no EPUB 3
O gerador do relatório EPUB 3 DEVE expandir os passos internos de cada ramo condicional escolhido (`StepSelecaoRamo`) na sequência imediata da decisão e DEVE aninhar visualmente todas as sub-listas repetíveis (`StepListaAcoes` vinculadas a um item pai via sufixo `__<idItemPai>`) dentro do cartão do item pai correspondente, em qualquer nível de profundidade.

#### Scenario: Material com sub-listas de testes de qualidade e etapas de fabricação
- **WHEN** o relatório EPUB 3 de um material contendo componentes com sub-listas de "Testes de Qualidade" e "Detalhes e Processo de Fabricação" é gerado
- **THEN** cada teste de qualidade e etapa de fabricação é renderizado aninhado dentro do cartão do respectivo componente pai, exibindo o rótulo da sub-lista e do tipo de item sem expor o sufixo `__<idItemPai>`

#### Scenario: Ação de manutenção com seleção de ramo recursiva
- **WHEN** uma ação de manutenção possui uma escolha condicional (`selecao_ramo`) que abre sub-passos e outra escolha condicional aninhada
- **THEN** o cartão da ação renderiza na ordem exata a primeira decisão, os sub-passos intermediários, a segunda decisão e os campos finais preenchidos

### Requirement: Layout Visual de Grades de Propriedades, Galerias de Mídia e Sumário no EPUB 3
O documento `relatorio.xhtml` e sua folha `estilo.css` DEVEM agrupar campos simples curtos em grade de propriedades, destacar escolhas de `LARGE_TILES` e `selecao_ramo`, exibir fotos em layout de galeria lado a lado (grid responsivo) acompanhadas do `label` do campo correspondente, e o documento `nav.xhtml` DEVE listar os nomes reais dos materiais anexados em vez de seus UUIDs.

#### Scenario: Comparação visual de fotos Antes e Depois em uma ação
- **WHEN** um passo ou item de ação contém campos de imagem preenchidos (como "Foto antes da intervenção" e "Foto após instalação")
- **THEN** o `relatorio.xhtml` renderiza as imagens em uma galeria em grid identificada pelo `label` de cada campo

#### Scenario: Sumário de navegação com nomes dos materiais anexados
- **WHEN** o pacote EPUB 3 de uma manutenção é empacotado com materiais aninhados
- **THEN** o arquivo `OEBPS/nav.xhtml` exibe os títulos de exibição dos materiais nos links de navegação

### Requirement: Emissão do Relatório EPUB 3 no Idioma Ativo do Usuário com Rótulos Traduzidos
O gerador de EPUB 3 DEVE (MUST) compilar os documentos `relatorio.xhtml`, `nav.xhtml` e o metadado `<dc:language>` do `content.opf` estaticamente no idioma ativo do aplicativo no momento da geração (aplicando `dir="rtl"` quando o idioma for Árabe `ar`), exibindo cabeçalhos, textos fixos, rótulos de campos e valores de opções traduzidos a partir do dicionário do protocolo, enquanto mantém os identificadores canônicos em inglês no arquivo `OEBPS/dados/registro.binarypb`.

#### Scenario: Geração de laudo EPUB 3 em Inglês ou Japonês
- **WHEN** o usuário gera um relatório EPUB 3 com o aplicativo configurado em Japonês (`ja`)
- **THEN** o `content.opf` registra `<dc:language>ja</dc:language>` e o `relatorio.xhtml` é gerado com `lang="ja"`, cabeçalhos em Japonês e rótulos/opções de campos resolvidos pelo dicionário `ja` do protocolo
- **THEN** o binário `OEBPS/dados/registro.binarypb` preserva os identificadores técnicos canônicos em inglês

#### Scenario: Geração de laudo EPUB 3 em Árabe com direção RTL
- **WHEN** o usuário gera um relatório EPUB 3 com o aplicativo configurado em Árabe (`ar`)
- **THEN** os documentos `relatorio.xhtml` e `nav.xhtml` incluem os atributos `lang="ar"` e `dir="rtl"`

### Requirement: Empacotamento Seletivo da Fonte Noto Sans do Idioma do Relatório no EPUB 3
O empacotador EPUB 3 DEVE (MUST) incluir em `OEBPS/fonts/` apenas os arquivos de fonte `Noto Sans` necessários para o idioma em que o relatório foi gerado (`NotoSans` para idiomas latinos, adicionando `NotoSansArabic` para `ar` ou `NotoSansJP` para `ja`), declarando-os via `@font-face` no `OEBPS/estilo.css`, registrando-os no `<manifest>` do `OEBPS/content.opf` com `media-type="font/ttf"` e incluindo seus hashes SHA-256 na assinatura `META-INF/signatures.xml`.

#### Scenario: Empacotamento e assinatura de fonte para relatório em idioma latino
- **WHEN** um relatório EPUB 3 é gerado em Português (`pt`) ou Inglês (`en`)
- **THEN** o pacote `.epub` inclui `OEBPS/fonts/NotoSans-Regular.ttf` e `OEBPS/fonts/NotoSans-Bold.ttf` comprimidos com `DEFLATE`, declarados no `estilo.css` e no `content.opf` e assinados no `META-INF/signatures.xml`, sem incluir os arquivos de fonte de Árabe ou Japonês

#### Scenario: Empacotamento e assinatura de fonte para relatório em Japonês ou Árabe
- **WHEN** um relatório EPUB 3 é gerado em Japonês (`ja`) ou Árabe (`ar`)
- **THEN** o pacote `.epub` inclui em `OEBPS/fonts/` a fonte específica do script (`NotoSansJP` ou `NotoSansArabic`) além da `NotoSans` base, garantindo renderização determinística e autocontida em qualquer leitor de EPUB

### Requirement: Âncora de Navegação Direta por Vídeo (`id="video-<uuid>"`) no Documento XHTML
O gerador do documento `OEBPS/relatorio.xhtml` DEVE (MUST) atribuir o identificador único `id="video-<uuid>"` ao elemento container de cada vídeo embutido (`<div id="video-<uuid>" class="container-video">`), correspondendo exatamente ao fragmento de URL `#video-<uuid>` codificado nos QR Codes do Sumário Executivo em PDF (`https://fixalog.app/v/<idSessao>#video-<uuid>`).

#### Scenario: Correspondência entre QR Code do PDF e âncora HTML do vídeo no EPUB
- **WHEN** um relatório contendo um vídeo de identificador `<uuid>` é compilado em EPUB 3 e PDF Resumido
- **THEN** o `OEBPS/relatorio.xhtml` renderiza o container do vídeo com `id="video-<uuid>"` permitindo que a abertura de `https://fixalog.app/v/<idSessao>#video-<uuid>` posicione o leitor diretamente sobre o vídeo

### Requirement: Verificação Automática de Sincronia entre Schemas .proto e Classes Geradas
O sistema DEVE (MUST) validar automaticamente que todas as mensagens (`message`) e campos declarados nos arquivos de definição `protos/registro.proto` e `protos/wizard.proto` correspondam exatamente aos descritores compilados nas classes geradas em tempo de execução, garantindo que os schemas `.proto` empacotados em `OEBPS/dados/` dentro do `.epub` reflitam fielmente a estrutura de `OEBPS/dados/registro.yaml`.

#### Scenario: Detecção de divergência entre arquivo .proto e classes geradas
- **WHEN** um campo é adicionado, removido ou renomeado em `registro.proto` ou `wizard.proto` sem estar sincronizado com os descritores das classes em execução
- **THEN** a verificação de contrato de schemas reporta falha apontando a mensagem e o campo divergentes
