## ADDED Requirements

### Requirement: Referenciamento de Mídias via UUID no Protobuf
O sistema DEVE utilizar o esquema `ReferenciaMidia` (contendo UUID, tipo original, hash original, tipo comprimido, hash comprimido e versão da compressão) ao invés de armazenar o binário diretamente nos campos do Protobuf.

#### Scenario: Construção do Protobuf
- **WHEN** o sistema for gerar o arquivo de manifesto (registro.json)
- **THEN** o sistema preenche as propriedades de `ReferenciaMidia` com os dados criptográficos da mídia (hash SHA-256) em vez do seu conteúdo binário

### Requirement: Validação Matemática (Dual-Hash)
O sistema DEVE assegurar que o hash do arquivo compactado de trabalho corresponda exatamente ao `hash_comprimido` armazenado e validado pela assinatura.

#### Scenario: Verificação Criptográfica de Re-compressão
- **WHEN** o sistema avaliar a necessidade de re-comprimir uma mídia de `_original` (devido a mudança de data_version) em modo de edição
- **THEN** ele recalcula o SHA-256 do `_original` atual no disco
- **THEN** só prossegue com a re-compressão se o hash calculado bater perfeitamente com o `hash_original` do manifesto
