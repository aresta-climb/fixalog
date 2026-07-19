# session-bundle-storage Specification

## Purpose
TBD - created by archiving change unify-protobuf-media. Update Purpose after archive.
## Requirements
### Requirement: Encapsulamento em Bundles de Sessão
O sistema DEVE criar um diretório dedicado para cada relatório baseado no seu UUID (id_sessao). Todos os arquivos associados a esta sessão (PDF final, arquivo de manifesto protobuf, mídias originais e mídias comprimidas) DEVEM ser armazenados exclusivamente neste diretório.

#### Scenario: Criação de um Bundle
- **WHEN** uma nova sessão de preenchimento é iniciada e a primeira mídia é capturada ou ao gerar o relatório final
- **THEN** o sistema cria o diretório `/documentos/sessoes/<id_sessao>/` se não existir

### Requirement: Nomenclatura das Mídias Locais
O sistema DEVE renomear as mídias capturadas utilizando um UUID único por mídia, salvando o arquivo original com o sufixo `_original` e a versão de trabalho comprimida sem sufixo, mantendo a extensão correta.

#### Scenario: Salvamento e Compressão de Mídia
- **WHEN** o usuário captura uma foto ou vídeo
- **THEN** o sistema salva o arquivo original como `<media_uuid>_original.<ext>`
- **THEN** o sistema aplica a compressão e salva o resultado como `<media_uuid>.<ext>` no mesmo diretório

### Requirement: Exclusão de Sessão (Garbage Collection)
O sistema DEVE excluir integralmente o diretório do Session Bundle quando o registro for removido do Histórico pelo usuário.

#### Scenario: Exclusão Limpa
- **WHEN** o usuário exclui um relatório a partir do Histórico
- **THEN** o sistema deleta o registro do Isar
- **THEN** o sistema exclui a pasta `/documentos/sessoes/<id_sessao>/` recursivamente do disco local

