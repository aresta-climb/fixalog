## 1. Persistência de Dados (TDD)

- [x] 1.1 Criar testes unitários para a lógica de salvamento do `SubmissionRecord`, assegurando TDD (Test-First) conforme `PRINCIPIOS.md`.
- [x] 1.2 Implementar a persistência em `generation_provider.dart`, instanciando e gravando o `SubmissionRecord` no Isar, garantindo 100% de cobertura (coverage) do fluxo.

## 2. Consumo de Dados (Provider TDD)

- [x] 2.1 Criar o arquivo de testes `history_provider_test.dart` especificando o comportamento de recuperação dos registros do Isar.
- [x] 2.2 Implementar o arquivo `history_provider.dart` com o provider do Riverpod, buscando registros de forma decrescente e satisfazendo os testes com 100% de cobertura.

## 3. Interface de Usuário (Histórico)

- [x] 3.1 Em `history_screen.dart`, utilizar o `ConsumerWidget` (ou `ref.watch`) para escutar o provider criado no passo anterior.
- [x] 3.2 Substituir a lista estática (Via do Sol, Fenda do Pânico, etc) por um mapeamento iterativo dinâmico a partir dos dados recebidos.
- [x] 3.3 Utilizar os dados reais do modelo (nomeProtocolo, dataInclusao, etc) para popular o layout dos cards do histórico.
- [x] 3.4 Avaliar se a UI atual com `SingleChildScrollView` + `Column` suporta adequadamente dezenas de registros, ou se é conveniente trocar para `ListView.builder`.
