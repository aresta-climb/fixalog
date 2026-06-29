## ADDED Requirements

### Requirement: Conversão para PDF/A-3 e Anexação
O sistema (módulo Rust) DEVE receber um PDF de rascunho e listas de caminhos de arquivos, e adicionar esses arquivos nativamente como `EmbeddedFiles` na árvore do PDF, convertendo-o estruturalmente para um contêiner PDF/A-3 válido em disco.

#### Scenario: Anexação em arquivo pesado
- **WHEN** uma lista de 5 vídeos de 20MB é recebida
- **THEN** o sistema anexa via streaming sem carregar os 100MB na memória RAM simultaneamente

### Requirement: Cálculo de ByteRange e Placeholder (Selo)
O sistema DEVE reservar um espaço (`ByteRange`) no dicionário de assinaturas (`Sig`) do arquivo final em disco para injetar a assinatura criptográfica CMS sem corromper as referências cruzadas (`XRef`).

#### Scenario: Cálculo de Hash Streaming
- **WHEN** o arquivo está pronto no disco com o placeholder de assinatura
- **THEN** o motor calcula o SHA-256 processando o arquivo em blocos, pulando os bytes do placeholder

### Requirement: Emissão de Eventos de Progresso (FFI)
O módulo Rust DEVE suportar comunicação assíncrona por canais (Streams) enviando seu estado percentual e descritivo atualizado (`status: "Assinando...", percent: 0.85`) de volta para o Flutter.

#### Scenario: Atualização de interface
- **WHEN** o módulo conclui uma etapa crítica (ex: Hash finalizado)
- **THEN** ele emite o progresso via `StreamSink` garantindo resposta em tempo real
