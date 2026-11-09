# Spec Delta

## ADDED Requirements

### Requirement: Verificação Automática de Sincronia entre Schemas .proto e Classes Geradas
O sistema DEVE (MUST) validar automaticamente que todas as mensagens (`message`) e campos declarados nos arquivos de definição `protos/registro.proto` e `protos/wizard.proto` correspondam exatamente aos descritores compilados nas classes geradas em tempo de execução, garantindo que os schemas `.proto` empacotados em `OEBPS/dados/` dentro do `.epub` reflitam fielmente a estrutura de `OEBPS/dados/registro.yaml`.

#### Scenario: Detecção de divergência entre arquivo .proto e classes geradas
- **WHEN** um campo é adicionado, removido ou renomeado em `registro.proto` ou `wizard.proto` sem estar sincronizado com os descritores das classes em execução
- **THEN** a verificação de contrato de schemas reporta falha apontando a mensagem e o campo divergentes

## MODIFIED Requirements

### Requirement: O sistema DEVE gerar um container EPUB 3 padronizado
O sistema DEVE (MUST) compilar o relatório técnico de vistoria em um arquivo de extensão `.epub` aderente à especificação EPUB 3 (OCF/W3C), empacotando o arquivo `mimetype` sem compressão no início do arquivo, aplicando compressão `DEFLATE` aos metadados, documentos XHTML, folhas de estilo CSS, assinaturas XML, manifesto YAML (`OEBPS/dados/registro.yaml`) e schemas `.proto` (`OEBPS/dados/registro.proto` e `OEBPS/dados/wizard.proto`), e armazenando os ativos de mídia já comprimidos (`.mp4`, `.webp`, `.jpg`, `.jpeg`, `.png`, `.pdf`) no modo `STORE` (`CompressionType.none`) para evitar recompressão redundante de CPU.

#### Scenario: Geração do container EPUB 3 com dados da vistoria
- **WHEN** o usuário conclui o preenchimento da vistoria no aplicativo e solicita a geração do relatório
- **THEN** o sistema compila um arquivo `.epub` válido onde os arquivos `.xhtml`, `.css`, `.opf`, `.xml`, `.yaml` e `.proto` são comprimidos com `DEFLATE` e os arquivos de mídia em `OEBPS/midias/` e `OEBPS/materiais/` são armazenados com `CompressionType.none` (`STORE`)

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
