## Why

Atualmente, o processo de geração de relatórios expressos cria os arquivos PDF e salva em disco, mas não os registra no banco de dados local (Isar). Consequentemente, a aba de "Histórico" do aplicativo exibe apenas dados estáticos (mock) em vez de refletir as submissões reais. Resolver este problema fecha o ciclo de fluxo primário do app, permitindo ao usuário auditar e acessar seu histórico real.

## What Changes

- Registrar um `SubmissionRecord` real no Isar logo após a geração de um relatório expresso.
- Modificar o componente visual da tela de histórico (`history_screen.dart`) para consumir uma stream ou future do Isar, substituindo os dados estáticos da interface.
- Tornar a lista de histórico na view completamente populada pela base de dados real do usuário, suportando rolagem para todos os itens históricos.

## Capabilities

### New Capabilities
- `history-tracking`: Capacidade de persistir relatórios gerados no banco de dados local e listar esses registros ao usuário através do histórico do app.

### Modified Capabilities
Nenhum

## Impact

- `lib/features/pdf_generation/providers/generation_provider.dart`: Adição da lógica de salvamento local.
- `lib/features/home/views/history_screen.dart`: Ligação da interface com a camada de estado fornecida pelo Riverpod conectada ao Isar.
- Pode impactar ligeiramente a performance na tela de geração ao adicionar a rotina de escrita local (embora insignificante).
