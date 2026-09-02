## 1. Atualização da Licença do Repositório

- [x] 1.1 Atualizar o arquivo raiz `LICENSE` para o texto oficial da Mozilla Public License Version 2.0 (MPL-2.0)
- [x] 1.2 Atualizar referências de licença em `README.md` e arquivos de documentação se houver menção

## 2. Teste de Integridade Arquitetural (Test-First)

- [x] 2.1 Implementar `app/test/architecture/license_headers_test.dart` com as regras de validação de cabeçalho e matriz de exclusão de codegen
- [x] 2.2 Executar o teste e validar que ele falha (fase Red do TDD) listando os arquivos que ainda não possuem o cabeçalho

## 3. Inserção dos Cabeçalhos SPDX nos Arquivos Fonte

- [x] 3.1 Adicionar o cabeçalho SPDX/MPL-2.0 em todos os arquivos `.dart` autorais de `app/lib/`
- [x] 3.2 Adicionar o cabeçalho SPDX/MPL-2.0 em todos os arquivos `.dart` autorais de `app/test/`
- [x] 3.3 Adicionar o cabeçalho SPDX/MPL-2.0 em todos os arquivos `.rs` autorais de `app/rust/src/` (ignorando `frb_generated.rs` e subdiretório `formats/`)
- [x] 3.4 Adicionar o cabeçalho SPDX/MPL-2.0 no arquivo Kotlin de `app/android/app/src/main/kotlin/`

## 4. Validação e Homologação Final

- [x] 4.1 Executar o teste `app/test/architecture/license_headers_test.dart` e garantir aprovação (fase Green do TDD)
- [x] 4.2 Executar toda a suíte de testes do aplicativo (`flutter test`) garantindo 100% de sucesso e sem regressões
