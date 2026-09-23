## Purpose

Gera o documento canônico de relatório técnico de manutenção no formato aberto EPUB 3, contendo layout responsivo em HTML5/CSS, múltiplos vídeos de inspeção em alta definição, metadados estruturados em Protobuf e assinatura digital criptográfica W3C XML-DSig.

## ADDED Requirements

### Requirement: O sistema DEVE gerar um container EPUB 3 padronizado
O sistema DEVE compilar o relatório técnico de vistoria em um arquivo de extensão `.epub` aderente à especificação EPUB 3 (OCF/W3C), empacotando o arquivo `mimetype` sem compressão no início do arquivo, os metadados do container em `META-INF/container.xml` e a pasta de conteúdo `OEBPS/` com manifesto OPF, folhas de estilo CSS, páginas XHTML e ativos de mídia.

#### Scenario: Geração do container EPUB 3 com dados da vistoria
- **WHEN** o usuário conclui o preenchimento da vistoria no aplicativo e solicita a geração do relatório
- **THEN** o sistema compila um arquivo `.epub` válido contendo as páginas XHTML formatadas, o manifesto `content.opf` e todos os arquivos de imagem e vídeo registrados

### Requirement: O sistema DEVE embutir e reproduzir múltiplos vídeos e fotos no EPUB 3
O sistema DEVE incorporar arquivos de vídeo MP4 (codec H.264 720p CRF 26 / áudio mono AAC 64k / faststart) e fotos em formato WebP (resolução de até 4MP e qualidade 85) no manifesto do EPUB 3, sem impor limites arbitrários à quantidade total de mídias. Os vídeos DEVEM ser referenciados semanticamente via tags HTML5 `<video controls>` com imagem de capa (*poster frame*) estática representativa.

#### Scenario: Vistoria com múltiplos vídeos e fotos de proteções
- **WHEN** a sessão de manutenção inclui múltiplos vídeos e fotos documentando o estado das proteções, sem limitação fixa de quantidade
- **THEN** todas as mídias transcodificadas são empacotadas na pasta de mídias do EPUB e renderizadas com controles nativos de reprodução nas respectivas seções de cada proteção

### Requirement: O sistema DEVE preservar mídias originais para re-geração
O sistema DEVE manter os arquivos brutos originais de fotos e vídeos gravados no dispositivo com o sufixo `_original` dentro do armazenamento local da sessão (`sessoes/<sessionId>/`), garantindo que futuras compilações do EPUB sejam realizadas a partir da mídia matriz sem perda cumulativa de qualidade.

#### Scenario: Re-geração do relatório a partir do Histórico
- **WHEN** o usuário solicita a re-emissão de um relatório existente
- **THEN** a esteira de compressão consome os arquivos originais preservados no disco local para montar o novo artefato EPUB 3

### Requirement: O sistema DEVE assinar digitalmente o EPUB 3 com XML-DSig
O sistema DEVE proteger a integridade do relatório gerando o arquivo `META-INF/signatures.xml` conforme a recomendação W3C XML Signature (XML-DSig). O arquivo DEVE conter os resumos criptográficos SHA-256 de todos os arquivos do manifesto (incluindo páginas XHTML, mídias e Protobuf) e a assinatura calculada com a chave privada ECDSA (secp256r1) do mantenedor.

#### Scenario: Verificação de integridade do container assinado
- **WHEN** o relatório EPUB 3 é finalizado pelo mantenedor
- **THEN** o arquivo `META-INF/signatures.xml` é gerado contendo os digests de cada componente e a assinatura criptográfica vinculada ao certificado do mantenedor

### Requirement: O sistema DEVE embutir os dados brutos Protobuf no container
O sistema DEVE incluir o arquivo binário original `registro.binarypb` dentro da estrutura do EPUB 3 (em `OEBPS/dados/registro.binarypb`), devidamente declarado no manifesto `content.opf` e protegido pelo cálculo de hash na assinatura digital.

#### Scenario: Auditoria técnica automatizada
- **WHEN** um sistema terceiro lê o arquivo `.epub` da vistoria
- **THEN** ele consegue extrair o binário `registro.binarypb` para consumir as respostas estruturadas e coordenadas GPS sem depender do parsing do layout visual
