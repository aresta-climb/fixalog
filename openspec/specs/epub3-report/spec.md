# EPUB 3 Report

## Purpose

Gera o documento canônico de relatório técnico de manutenção no formato aberto EPUB 3, contendo layout responsivo em HTML5/CSS, múltiplos vídeos de inspeção em alta definição, metadados estruturados em Protobuf e assinatura digital criptográfica W3C XML-DSig.

## Requirements

### Requirement: O sistema DEVE gerar um container EPUB 3 padronizado
O sistema DEVE compilar o relatório técnico de vistoria em um arquivo de extensão .epub aderente à especificação EPUB 3 (OCF/W3C), empacotando o arquivo mimetype sem compressão no início do arquivo, os metadados do container em META-INF/container.xml e a pasta de conteúdo OEBPS/ com manifesto OPF, folhas de estilo CSS, páginas XHTML e ativos de mídia.

#### Scenario: Geração do container EPUB 3 com dados da vistoria
- **WHEN** o usuário conclui o preenchimento da vistoria no aplicativo e solicita a geração do relatório
- **THEN** o sistema compila um arquivo .epub válido contendo as páginas XHTML formatadas, o manifesto content.opf e todos os arquivos de imagem e vídeo registrados

### Requirement: O sistema DEVE embutir e reproduzir múltiplos vídeos e fotos no EPUB 3
O sistema DEVE incorporar arquivos de vídeo MP4 (codec H.264 720p CRF 26 / áudio mono AAC 64k / faststart) e fotos em formato WebP (resolução de até 4MP e qualidade 85) no manifesto do EPUB 3, sem impor limites arbitrários à quantidade total de mídias. Os vídeos DEVEM ser referenciados semanticamente via tags HTML5 <video controls> com imagem de capa (*poster frame*) estática representativa.

#### Scenario: Vistoria com múltiplos vídeos e fotos de proteções
- **WHEN** a sessão de manutenção inclui múltiplos vídeos e fotos documentando o estado das proteções, sem limitação fixa de quantidade
- **THEN** todas as mídias transcodificadas são empacotadas na pasta de mídias do EPUB e renderizadas com controles nativos de reprodução nas respectivas seções de cada proteção

### Requirement: O sistema DEVE preservar mídias originais para re-geração
O sistema DEVE manter os arquivos brutos originais de fotos e vídeos gravados no dispositivo com o sufixo _original dentro do armazenamento local da sessão (sessoes/<sessionId>/), garantindo que futuras compilações do EPUB sejam realizadas a partir da mídia matriz sem perda cumulativa de qualidade.

#### Scenario: Re-geração do relatório a partir do Histórico
- **WHEN** o usuário solicita a re-emissão de um relatório existente
- **THEN** a esteira de compressão consome os arquivos originais preservados no disco local para montar o novo artefato EPUB 3

### Requirement: O sistema DEVE assinar digitalmente o EPUB 3 com XML-DSig
O sistema DEVE proteger a integridade do relatório gerando o arquivo META-INF/signatures.xml conforme a recomendação W3C XML Signature (XML-DSig). O arquivo DEVE conter os resumos criptográficos SHA-256 de todos os arquivos do manifesto (incluindo páginas XHTML, mídias e Protobuf) e a assinatura calculada com a chave privada ECDSA (secp256r1) do mantenedor.

#### Scenario: Verificação de integridade do container assinado
- **WHEN** o relatório EPUB 3 é finalizado pelo mantenedor
- **THEN** o arquivo META-INF/signatures.xml é gerado contendo os digests de cada componente e a assinatura criptográfica vinculada ao certificado do mantenedor

### Requirement: O sistema DEVE embutir os dados brutos Protobuf no container
O sistema DEVE incluir o arquivo binário original `registro.binarypb` dentro da estrutura do EPUB 3 (em OEBPS/dados/registro.binarypb), devidamente declarado no manifesto content.opf e protegido pelo cálculo de hash na assinatura digital.

#### Scenario: Auditoria técnica automatizada
- **WHEN** um sistema terceiro lê o arquivo .epub da vistoria
- **THEN** ele consegue extrair o binário `registro.binarypb` para consumir as respostas estruturadas e coordenadas GPS sem depender do parsing do layout visual

### Requirement: Incorporação de Materiais Extraídos sem Duplicação no EPUB 3 da Manutenção
Ao gerar o container EPUB 3 de uma manutenção que referencia materiais cadastrados, o sistema DEVE incorporar o conteúdo extraído do pacote `.epub` de cada material utilizado dentro do diretório `OEBPS/materiais/<uuid_material>/` do EPUB da manutenção, mantendo o arquivo `OEBPS/dados/registro.binarypb` e a assinatura `META-INF/signatures.xml` originais do material intactos dentro dessa subpasta para permitir validação criptográfica independente sem duplicar mídias.

#### Scenario: Empacotamento e verificação de material aninhado no EPUB da manutenção
- **WHEN** o relatório EPUB 3 de uma manutenção contendo materiais selecionados é gerado e assinado
- **THEN** a árvore extraída do EPUB de cada material utilizado é gravada em `OEBPS/materiais/<uuid_material>/` contendo seu `META-INF/signatures.xml` e `OEBPS/dados/registro.binarypb` originais
- **THEN** a assinatura `META-INF/signatures.xml` da manutenção na raiz assina todos os arquivos do pacote principal e das subpastas de materiais
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
