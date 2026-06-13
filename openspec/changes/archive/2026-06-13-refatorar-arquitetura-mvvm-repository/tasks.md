## 1. Configuração da Camada Repository (Identity)

- [x] 1.1 Criar a estrutura de diretórios `app/lib/features/identity/repositories`.
- [x] 1.2 Implementar a classe `IdentityRepository` abstraindo as chamadas de banco de dados (`Isar.writeTxn` e `isar.identityRecords`).
- [x] 1.3 Escrever testes unitários (`identity_repository_test.dart`) provando o funcionamento isolado do Repository.
- [x] 1.4 Criar e expor o provider `identityRepositoryProvider` injetando o Isar na raiz.

## 2. Refatoração para ViewModels

- [x] 2.1 Renomear a pasta `app/lib/features/identity/controllers` para `app/lib/features/identity/viewmodels`.
- [x] 2.2 Renomear `IdentityFormController` para `IdentityFormViewModel` e seu respectivo arquivo.
- [x] 2.3 Refatorar `IdentityFormViewModel` para receber o `IdentityRepository` via construtor (Dependency Injection), eliminando qualquer import direto do `Isar`.
- [x] 2.4 Criar a suíte de testes unitários `identity_form_view_model_test.dart` utilizando um *Mock* do `IdentityRepository` para validar os estados de erro, loading e sucesso.

## 3. Atualização das Views e Providers

- [x] 3.1 Atualizar `app/lib/features/identity/views/identity_setup_screen.dart` para consumir o novo `identityFormViewModelProvider` e renomear as referências pertinentes.
- [x] 3.2 Atualizar dependências em `main.dart` e `home_screen.dart` caso utilizem os providers antigos de Identity.
- [x] 3.3 Rodar a aplicação completa e garantir a ausência de regressões na tela de setup.

## 4. Revisão Geral da Arquitetura

- [x] 4.1 Auditar pastas `features/home/` e `features/wizard/` buscando eventuais `controllers` para aplicar o mesmo tratamento MVVM/Repository, se existirem lógicas persistentes.
- [x] 4.2 Executar a suíte de testes completa do Flutter para certificar que todos os testes (novos e antigos) passam (Verde no Red-Green-Refactor).
