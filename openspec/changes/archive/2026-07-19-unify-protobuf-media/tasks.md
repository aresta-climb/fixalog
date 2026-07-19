## 1. Atualização do Schema Protobuf (Library-First)

- [ ] 1.1 Criar testes unitários (vermelhos) para garantir que o novo modelo Protobuf consiga estruturar UUIDs, hashes originais/comprimidos e data_version, com 100% de coverage.
- [ ] 1.2 Atualizar `registro.proto`: Substituir os campos `bytes foto` e afins por `ReferenciaMidia` (Imagem, Vídeo, Áudio).
- [ ] 1.3 Gerar o código Dart (`protoc`) e implementar a lógica necessária até que os testes unitários passem (verde).

## 2. Gerenciamento do Session Bundle (Core)

- [ ] 2.1 Escrever teste de integração (vermelho) simulando o fluxo de ponta a ponta de salvar arquivos no Session Bundle e confirmar isolamento.
- [ ] 2.2 Criar testes unitários (vermelhos) para a nova library `SessionBundleManager` cobrindo criação de diretórios, nomenclaturas de arquivos originais/comprimidos e exclusão (Garbage Collection), com 100% de coverage.
- [ ] 2.3 Implementar o `SessionBundleManager` para fazer os testes unitários passarem.
- [ ] 2.4 Criar testes unitários (vermelhos) para o `SubmissionRecord` no Isar validando a gravação de `protobufPath` (removendo `yamlPath`).
- [ ] 2.5 Refatorar o modelo do Isar e lógica até os testes unitários passarem.

## 3. Adaptação do Express Form

- [ ] 3.1 Escrever testes de integração (vermelhos) garantindo que a tela carrega os dados de um manifesto e salva no novo formato.
- [ ] 3.2 Criar testes unitários (vermelhos) para o `ExpressFormViewModel` simulando o carregamento via UUID e caminhos locais com 100% de coverage.
- [ ] 3.3 Implementar a lógica de restauração no `ExpressFormViewModel` até os testes passarem.
- [ ] 3.4 Escrever testes unitários (vermelhos) validando a montagem do manifesto `.binarypb` (com hashes SHA-256) antes da geração do PDF.
- [ ] 3.5 Implementar a geração correta do manifesto no ViewModel para fazer os testes passarem.

## 4. Integração de Auditoria (PDF e Rust)

- [x] 4.1 Escrever testes de integração (vermelhos) validando que o PDF final possui anexos e tamanho correspondente.
- [x] 4.2 Criar testes unitários (vermelhos) cobrindo a adaptação no `PdfDraftService` para tratar listas de arquivos originais/comprimidos com 100% de coverage.
- [x] 4.3 Implementar a passagem correta dos dados no `PdfDraftService` (verde).
- [x] 4.4 Atualizar os mocks e a FFI em Rust para simular o PDF/A-3 injetando o `registro.binarypb` e as mídias compactadas.

## 5. Rastreamento e Histórico

- [x] 5.1 Escrever testes de integração End-to-End (vermelhos) verificando a exclusão de relatórios antigos e o fluxo de re-edição a partir do clique no card de Histórico.
- [x] 5.2 Criar testes unitários (vermelhos) para a lógica de UI de exclusão, garantindo deleção recursiva da pasta do Session Bundle.
- [x] 5.3 Implementar a deleção física integrada com a exclusão do Isar até os testes passarem.
- [x] 5.4 Criar testes unitários (vermelhos) garantindo a passagem do `id_sessao` via roteamento ao abrir o `ExpressFormScreen`.
- [x] 5.5 Implementar as correções de roteamento (verde).
