# Tasks

## 1. Sincronização de Perfil Supabase e Aresta Climb (`ServicoAutenticacaoNuvem`)

- [x] 1.1 Escrever testes de comportamento em `app/test/core/services/autenticacao_nuvem_service_test.dart` e `app/test/core/services/autenticacao_nuvem_service_fake_test.dart` validando a recuperação do `autor_nome_publico` de `public.perfis` / `user_metadata` (`nome_completo_fixalog`, `clube_associacao_fixalog`) e o envio de `sincronizarPerfilConta` com `atualizarNomeNoAresta: true` e `false`, verificando a falha inicial (Red).
- [x] 1.2 Implementar em `app/lib/core/services/autenticacao_nuvem_service.dart` e `app/test/core/services/autenticacao_nuvem_service_fake.dart` a leitura de perfil/metadados no Supabase e o método `sincronizarPerfilConta({required String nomeCompleto, required String clubeAssociacao, required bool atualizarNomeNoAresta})`, garantindo 100% de cobertura com `flutter test --coverage test/core/services/autenticacao_nuvem_service_test.dart test/core/services/autenticacao_nuvem_service_fake_test.dart`.

## 2. ViewModel de Identidade (`IdentityFormViewModel`)

- [x] 2.1 Escrever testes em `app/test/features/identity/viewmodels/identity_form_view_model_test.dart` cobrindo o estado `atualizarNomeNoAresta` (padrão `true`), a alternância `definirAtualizarNomeNoAresta(bool)`, a ação `trocarConta()` (limpando a sessão OIDC para retornar à Etapa 1) e a chamada a `sincronizarPerfilConta` durante `submitIdentity`, verificando a falha inicial (Red).
- [x] 2.2 Implementar em `app/lib/features/identity/viewmodels/identity_form_view_model.dart` os novos campos/métodos (`atualizarNomeNoAresta`, `definirAtualizarNomeNoAresta`, `trocarConta` e integração com `sincronizarPerfilConta`), garantindo 100% de cobertura com `flutter test --coverage test/features/identity/viewmodels/identity_form_view_model_test.dart`.

## 3. UI de Login em 2 Etapas, Permissões e Termos de Uso (`IdentitySetupScreen` e `TelaTermosDeUso`)

- [x] 3.1 Escrever testes de widget em `app/test/features/identity/views/identity_setup_screen_test.dart` e `app/test/features/onboarding/views/tela_termos_de_uso_test.dart` validando: cabeçalho `FIXA` / `LOG`, Etapa 1 exibindo apenas os botões clássicos "Continuar com o Google" e "Continuar com a Apple", avanço para a Etapa 2 após autenticar com campos pré-preenchidos, checkbox "Atualizar também meu nome de exibição no Aresta Climb", card `SEGURANÇA DE HARDWARE` (explicando a chave ECDSA P-256 sem o texto redundante dos termos), card separado `PERMISSÕES DO DISPOSITIVO` (Câmera e Localização GPS) e ausência de disparo de permissão na `TelaTermosDeUso`, verificando a falha inicial (Red).
- [x] 3.2 Implementar a refatoração de UI em `app/lib/features/identity/views/identity_setup_screen.dart` e `app/lib/features/onboarding/views/tela_termos_de_uso.dart`, garantindo 100% de cobertura de linhas nos arquivos alterados com `flutter test --coverage test/features/identity/views/identity_setup_screen_test.dart test/features/onboarding/views/tela_termos_de_uso_test.dart`.
