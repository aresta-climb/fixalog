## Why

A aplicação já utiliza padrões reativos com Riverpod e Isar que se assemelham fortemente ao padrão MVVM (Model-View-ViewModel). No entanto, o código atual nomeia essas lógicas de apresentação como "Controllers" e mistura o acesso direto ao banco de dados (Isar) com a lógica de apresentação. Para obedecer ao **Princípio III (Imperativo do Teste em Primeiro Lugar)** estipulado no `PRINCIPIOS.md`, precisamos desacoplar o acesso a dados introduzindo uma camada de `Repository`. Isso permitirá criar testes unitários isolados ("mockando" o repositório) para a nossa regra de negócios e formalizará a arquitetura MVVM.

## What Changes

- Renomear todos os diretórios `controllers` em `app/lib/features/*/` para `viewmodels`.
- Renomear classes com sufixo `*Controller` para `*ViewModel`.
- Introduzir uma nova camada de diretórios `repositories` nas features.
- Mover as invocações diretas de `_isar!.writeTxn` (ou similares) dos atuais controllers para classes no padrão Repository (ex: `IdentityRepository`).
- O `ViewModel` receberá o `Repository` injetado pelo Riverpod em vez do acesso direto ao `Isar`.
- Criação de suítes de testes iniciais provando que os ViewModels são testáveis independentemente do banco de dados (mockando o Repository).

## Capabilities

### New Capabilities
- Nenhuma. Trata-se de uma refatoração arquitetural puramente interna sem alterações em requisitos funcionais de usuário.

### Modified Capabilities
- Nenhuma mudança funcional de requisitos.

## Impact

- Modificações em arquivos na `app/lib/features/identity/` (como `identity_form_controller.dart` e `identity_setup_screen.dart`).
- Quaisquer outras features que já possuam pastas `controllers/` ou chamadas diretas ao Isar.
- A árvore de dependência do Riverpod precisará adicionar os Providers para os Repositories.
