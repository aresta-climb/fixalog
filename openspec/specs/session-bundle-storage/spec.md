# Armazenamento de Bundles de Sessão (session-bundle-storage)

## Purpose

Organiza o armazenamento físico em disco de cada sessão de preenchimento e relatório em diretórios isolados (`sessoes/<id_sessao>/`), encapsulando manifesto Protobuf, mídias originais, mídias comprimidas e limpeza recursiva na exclusão.

## Requirements

### Requirement: Encapsulamento em Bundles de Sessão
O sistema DEVE (MUST) criar um diretório dedicado para cada relatório baseado no seu UUID (`id_sessao`). Todos os arquivos associados a esta sessão (relatório final `.epub`/`.pdf`, arquivo de manifesto estruturado `registro.yaml`, mídias originais e mídias comprimidas) DEVEM (MUST) ser armazenados exclusivamente neste diretório. Ao ler o manifesto da sessão do disco local, o sistema DEVE (MUST) ler `registro.yaml` e convertê-lo para a instância estaticamente tipada `Registro` (Protobuf), mantendo fallback transparente de leitura para `registro.binarypb` caso a sessão tenha sido salva por uma versão anterior do aplicativo.

#### Scenario: Criação de um Bundle
- **WHEN** uma nova sessão de preenchimento é iniciada e persistida ou ao gerar o relatório final
- **THEN** o sistema cria o diretório `/documentos/sessoes/<id_sessao>/` se não existir e grava o manifesto estruturado em `registro.yaml`
- **THEN** ao recarregar a sessão, o sistema converte `registro.yaml` de volta para o objeto Protobuf `Registro` validando a tipagem dos campos

#### Scenario: Leitura retrocompatível de sessão legada em binarypb
- **WHEN** o sistema lê uma sessão antiga cujo diretório contém apenas `registro.binarypb` e ainda não possui `registro.yaml`
- **THEN** o sistema carrega os dados a partir de `registro.binarypb` sem erro e, ao salvar novamente a sessão, persiste o manifesto em `registro.yaml`

### Requirement: Nomenclatura das Mídias Locais
O sistema DEVE renomear as mídias capturadas utilizando um UUID único por mídia, salvando o arquivo original com o sufixo `_original` e a versão de trabalho comprimida sem sufixo, mantendo a extensão correta.

#### Scenario: Salvamento e Compressão de Mídia
- **WHEN** o usuário captura uma foto ou vídeo
- **THEN** o sistema salva o arquivo original como `<media_uuid>_original.<ext>`
- **THEN** o sistema aplica a compressão e salva o resultado como `<media_uuid>.<ext>` no mesmo diretório

### Requirement: Exclusão de Sessão (Garbage Collection)
O sistema DEVE (MUST) excluir integralmente o diretório do Session Bundle quando o registro for removido do Histórico pelo usuário.

#### Scenario: Exclusão Limpa
- **WHEN** o usuário exclui um relatório a partir do Histórico
- **THEN** o sistema deleta o registro do banco de dados local SQLite
- **THEN** o sistema exclui a pasta `/documentos/sessoes/<id_sessao>/` recursivamente do disco local
