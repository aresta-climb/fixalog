# Spec Delta

## MODIFIED Requirements

### Requirement: Encapsulamento em Bundles de Sessão
O sistema DEVE (MUST) criar um diretório dedicado para cada relatório baseado no seu UUID (`id_sessao`). Todos os arquivos associados a esta sessão (relatório final `.epub`/`.pdf`, arquivo de manifesto estruturado `registro.yaml`, mídias originais e mídias comprimidas) DEVEM (MUST) ser armazenados exclusivamente neste diretório. Ao ler o manifesto da sessão do disco local, o sistema DEVE (MUST) ler `registro.yaml` e convertê-lo para a instância estaticamente tipada `Registro` (Protobuf), mantendo fallback transparente de leitura para `registro.binarypb` caso a sessão tenha sido salva por uma versão anterior do aplicativo.

#### Scenario: Criação de um Bundle
- **WHEN** uma nova sessão de preenchimento é iniciada e persistida ou ao gerar o relatório final
- **THEN** o sistema cria o diretório `/documentos/sessoes/<id_sessao>/` se não existir e grava o manifesto estruturado em `registro.yaml`
- **THEN** ao recarregar a sessão, o sistema converte `registro.yaml` de volta para o objeto Protobuf `Registro` validando a tipagem dos campos

#### Scenario: Leitura retrocompatível de sessão legada em binarypb
- **WHEN** o sistema lê uma sessão antiga cujo diretório contém apenas `registro.binarypb` e ainda não possui `registro.yaml`
- **THEN** o sistema carrega os dados a partir de `registro.binarypb` sem erro e, ao salvar novamente a sessão, persiste o manifesto em `registro.yaml`
