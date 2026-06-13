## Context

Atualmente o aplicativo `FixaLog` foi construído sobre uma arquitetura orientada a features (`features/identity`, `features/home`, etc.), utilizando o `Riverpod` para gerenciar estado e injeção de dependências, e `Isar` como banco de dados local. Os provedores de estado (ex: `IdentityFormController`) manipulam diretamente o banco de dados `Isar`. Essa abordagem viola o Princípio III (TDD e independência de testes), pois acopla rigidamente a lógica de tela à infraestrutura de banco de dados, inviabilizando testes unitários sem levantar a engine do banco local real. 

## Goals / Non-Goals

**Goals:**
- Separar o acesso aos dados da regra de apresentação (ViewModels).
- Introduzir a camada de `Repository` para comunicação com `Isar`.
- Alinhar a nomenclatura à arquitetura MVVM, padronizando sufixos para `ViewModel` e pastas para `viewmodels`.
- Tornar os `ViewModels` 100% testáveis isoladamente.

**Non-Goals:**
- Nenhuma funcionalidade nova visível para o usuário será introduzida.
- Não alteraremos o banco de dados (o Schema do Isar permanece o mesmo).
- Não faremos refatorações pesadas nas `Views` em si, exceto pelas nomenclaturas das chamadas de `ref.read` ou reações de providers que foram renomeados.

## Decisions

1. **Camada Repository:**
   - **Decisão**: Criar classes específicas como `IdentityRepository` para envelopar `_isar!.identityRecords`.
   - **Alternativa Considerada**: Criar uma interface abstrata (ex: `IdentityRepository`) e a implementação (ex: `IsarIdentityRepository`). 
   - **Justificativa**: Conforme o "Princípio V: Simplicidade e Anti-Abstração", não criaremos interfaces abstratas neste primeiro momento se só tivermos o Isar. A testabilidade do ViewModel pode ser alcançada fazendo um *Mock* da classe base `IdentityRepository` usando pacotes como `mockito` ou `mocktail`. Se no futuro houver necessidade de salvar em nuvem (ex: Supabase), a abstração pode ser justificada.

2. **Nomenclatura ViewModels:**
   - **Decisão**: Renomear todos `*Controller` para `*ViewModel` e armazená-los em diretórios `/viewmodels/`.
   - **Justificativa**: Evita a confusão do termo "Controller", que muitas vezes é atrelado ao MVC ou a bibliotecas externas do Flutter (como `TextEditingController`). `ViewModel` denota inequivocamente que a classe modela o estado para uma View específica e que não contém elementos do Flutter (como contexto).

3. **Injeção de Dependências:**
   - **Decisão**: O `Riverpod` continuará sendo usado como mecanismo de injeção. Criaremos `identityRepositoryProvider` e injetaremos ele no `identityFormViewModelProvider`.
   - **Justificativa**: Mantém a infraestrutura que já funciona brilhantemente no aplicativo.

## Risks / Trade-offs

- **[Risk] Aumento do Número de Arquivos:** → Teremos diretórios e arquivos extras para os `Repositories`. A mitigação é que o ganho em testabilidade compensa a leve verbosidade de criar esses arquivos. O padrão Library-First continuará garantindo organização.
- **[Risk] Atualizações de Injeção Pendentes:** → Refatorar nomes pode causar quebra de builds se o import de algum provedor for esquecido. A mitigação é contar com a análise forte de tipos do Dart e garantir que o ciclo "Vermelho-Verde-Refatorar" ocorra.
