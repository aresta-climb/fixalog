## ADDED Requirements

### Requirement: Licença Mozilla Public License 2.0 (MPL-2.0)
O repositório Fixalog DEVE adotar a Mozilla Public License Version 2.0 (MPL-2.0) como sua licença de código aberto principal, substituindo a GPLv3 no arquivo raiz `LICENSE`.

#### Scenario: Leitura do arquivo de licença
- **WHEN** um desenvolvedor ou auditor inspeciona o arquivo `LICENSE` na raiz do repositório
- **THEN** o texto integral corresponde à licença oficial Mozilla Public License Version 2.0

### Requirement: Cabeçalhos SPDX Padronizados em Arquivos Fonte
Todos os arquivos de código-fonte autorais nas linguagens Dart, Rust e Kotlin DEVEM conter o cabeçalho padrão de licença e direitos autorais nas suas linhas iniciais.

O cabeçalho DEVE conter exatamente:
```
// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors
```

#### Scenario: Arquivo Dart autoral contém cabeçalho
- **WHEN** um arquivo `.dart` não-gerado em `app/lib/` ou `app/test/` é analisado
- **THEN** as primeiras linhas do arquivo contêm a identificação de licença SPDX-License-Identifier: MPL-2.0 e o aviso de Copyright

#### Scenario: Arquivo Rust autoral contém cabeçalho
- **WHEN** um arquivo `.rs` autoral em `app/rust/src/` é analisado
- **THEN** as primeiras linhas do arquivo contêm a identificação SPDX e Copyright da MPL-2.0

#### Scenario: Arquivo Kotlin autoral contém cabeçalho
- **WHEN** um arquivo `.kt` autoral em `app/android/app/src/main/kotlin/` é analisado
- **THEN** as primeiras linhas do arquivo contêm a identificação SPDX e Copyright da MPL-2.0

### Requirement: Exclusão de Arquivos Gerados e Dependências Vendoreadas
Arquivos gerados automaticamente por ferramentas de compilação (*codegen*) e bibliotecas de terceiros vendoreadas DEVEM ser expressamente ignorados da exigência do cabeçalho manual.

#### Scenario: Ignorar arquivos de codegen e terceiros
- **WHEN** a suíte de validação processa arquivos como `*.g.dart`, `*.pb*.dart`, `src/rust/frb_generated*` ou dependências em `app/rust/formats/`
- **THEN** tais arquivos são ignorados e não causam falhas de conformidade

### Requirement: Teste Automatizado de Integridade de Cabeçalhos
A suíte de testes de arquitetura DEVE possuir um teste automatizado (`license_headers_test.dart`) que varre todos os arquivos de código autorais e valida a presença obrigatória do cabeçalho de licença.

#### Scenario: Falha ao encontrar arquivo sem cabeçalho
- **WHEN** um novo arquivo de código autoral é adicionado sem o cabeçalho padronizado
- **THEN** o teste automatizado falha indicando o caminho do arquivo e a mensagem de correção em português

#### Scenario: Sucesso quando todos os arquivos atendem ao padrão
- **WHEN** todos os arquivos de código autorais possuem o cabeçalho correto
- **THEN** o teste automatizado é concluído com sucesso (pass)
