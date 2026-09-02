## Why

O projeto Fixalog atualmente utiliza a licença GPLv3. Para permitir maior flexibilidade de distribuição, modularidade e integração com o ecossistema móvel e bibliotecas públicas, a licença do projeto será alterada para a **Mozilla Public License 2.0 (MPL-2.0)**. 

Além disso, para garantir a conformidade legal e a integridade de direitos autorais em todos os arquivos de código-fonte autorais (Dart, Rust e Kotlin), é necessário padronizar o cabeçalho SPDX de licença e implementar um teste unitário automatizado de integridade arquitetural para assegurar que nenhum arquivo de código seja adicionado ou mantido sem o cabeçalho exigido.

## What Changes

- **Alteração da Licença do Repositório**: Substituição do arquivo `LICENSE` da GPLv3 para a **Mozilla Public License Version 2.0 (MPL-2.0)** e atualização das referências nos documentos de documentação (`README.md`, etc.).
- **Inclusão de Cabeçalhos SPDX/MPL 2.0**: Adição do cabeçalho padronizado de licença e copyright no topo de todos os arquivos de código-fonte autorais em Dart (`app/lib/`, `app/test/`), Rust (`app/rust/src/`) e Kotlin (`app/android/app/src/main/kotlin/`).
- **Teste de Unidade de Conformidade Arquitetural**: Criação do teste `app/test/architecture/license_headers_test.dart` para validar de forma automatizada e contínua que todos os arquivos de código-fonte respeitam o formato de cabeçalho definido, ignorando adequadamente arquivos gerados automaticamente (*codegen* como `*.g.dart`, `*.pb*.dart`, etc.) e dependências vendoreadas de terceiros.

## Capabilities

### New Capabilities
- `conformidade-licenca-headers`: Regras de padronização dos cabeçalhos SPDX/MPL-2.0, escopo de arquivos autorais e teste automatizado de integridade de licença.

### Modified Capabilities

## Impact

- **Repositório & Governança**: Substituição do arquivo `LICENSE` na raiz e documentações.
- **Código-Fonte**: Inclusão de comentários de cabeçalho no início de dezenas de arquivos existentes em Dart, Rust e Kotlin.
- **Suíte de Testes**: Novo teste em `app/test/architecture/` executado durante `flutter test`.
