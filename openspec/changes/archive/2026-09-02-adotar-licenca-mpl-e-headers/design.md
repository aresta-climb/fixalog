## Context

O projeto Fixalog utilizava anteriormente a licença GNU GPLv3. Com a evolução da arquitetura do aplicativo para módulos autônomos, integrações nativas em Rust (`flutter_rust_bridge`) e potencial distribuição de módulos ou bibliotecas reutilizáveis, a licença Mozilla Public License 2.0 (MPL-2.0) fornece o equilíbrio ideal entre proteção copyleft a nível de arquivo e flexibilidade de combinação em trabalhos maiores.

Além disso, em conformidade com as diretrizes de governança e com o `PRINCIPIOS.md`, é crucial assegurar que todo código produzido no repositório possua identificação formal de licença SPDX e direitos autorais, validado de forma inquebrável por testes unitários contínuos.

## Goals / Non-Goals

**Goals:**
- Atualizar o arquivo `LICENSE` na raiz para o texto integral da Mozilla Public License Version 2.0.
- Padronizar o cabeçalho SPDX de 2 linhas em todos os arquivos de código-fonte autorais:
  ```
  // SPDX-License-Identifier: MPL-2.0
  // Copyright (c) 2026 FixLog Contributors
  ```
- Aplicar o cabeçalho em arquivos Dart (`app/lib/`, `app/test/`), Rust (`app/rust/src/`) e Kotlin (`app/android/app/src/main/kotlin/`).
- Implementar o teste unitário de conformidade em `app/test/architecture/license_headers_test.dart`.

**Non-Goals:**
- Não aplicar cabeçalhos manuais em arquivos gerados automaticamente (`*.g.dart`, `*.pb*.dart`, `src/rust/frb_generated.*`).
- Não alterar cabeçalhos de crates de terceiros vendoreadas dentro de `app/rust/formats/`.
- Não reescrever arquivos estáticos de scaffolding nativo não mantidos diretamente pelo projeto (como templates padrão de build de iOS/macOS/Windows/Linux).

## Decisions

### 1. Formato SPDX Compacto
- **Decisão**: Utilizar o identificador SPDX canônico `SPDX-License-Identifier: MPL-2.0` acompanhado da linha `Copyright (c) 2026 FixLog Contributors`.
- **Alternativas consideradas**:
  - *Aviso longo da MPL 2.0 (Exhibit A)*: Ocupa 5+ linhas por arquivo, gerando ruído visual excessivo sem ganho legal substancial sobre o padrão SPDX.
  - *Header sem SPDX*: Dificulta a varredura automática por ferramentas de auditoria e compliance de código aberto.
- **Justificativa**: O padrão SPDX é universalmente reconhecido por scanners de conformidade de código aberto (FOSSID, ScanCode, GitHub License Scanner) e mantém o topo do arquivo limpo.

### 2. Localização e Escopo do Teste de Integridade
- **Decisão**: Criar o teste dentro de `app/test/architecture/license_headers_test.dart` utilizando `package:flutter_test`.
- **Alternativas consideradas**:
  - *Script de pré-commit / bash*: Depende do ambiente de cada desenvolvedor e pode ser burlado.
  - *Linter customizado*: Mais complexo de configurar e manter.
- **Justificativa**: O projeto já utiliza `app/test/architecture/test_structure_mirror_test.dart` para validar regras de repositório via `flutter test`. O teste roda no CI padrão e bloqueia qualquer commit incompleto.

### 3. Matriz de Exclusão de Arquivos no Teste
- **Decisão**: O teste deve excluir explicitamente:
  - `.g.dart` (gerado por Isar / build_runner)
  - `.pb.dart`, `.pbenum.dart`, `.pbjson.dart` (gerado por protoc)
  - `frb_generated.*` (gerado por flutter_rust_bridge)
  - Subdiretório `app/rust/formats` (bibliotecas externas)
  - Arquivos de template nativo como `GeneratedPluginRegistrant.*`

## Risks / Trade-offs

- **[Risco] Falsos positivos com novos geradores de código**: Se uma nova ferramenta de codegen for adicionada e gerar arquivos sem o cabeçalho, o teste falhará.
  → *Mitigação*: A lista de exceções no teste de arquitetura é centralizada e documentada com clareza em português, facilitando a inclusão de novos padrões de codegen se necessário.
- **[Risco] Quebra de testes de espelhamento (Princípio IV)**: Novos arquivos em `lib/` requerem espelhamento em `test/`.
  → *Mitigação*: `license_headers_test.dart` reside em `test/architecture/`, que é um teste de governança arquitetural (mesmo padrão de `test_structure_mirror_test.dart`).
