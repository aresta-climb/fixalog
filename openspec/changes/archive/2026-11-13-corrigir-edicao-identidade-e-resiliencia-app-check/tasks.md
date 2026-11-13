# Tasks

## 1. Edição de Identidade e Navegação Contextual (Issue #6 / FIXALOG-2)

- [x] 1.1 Escrever testes unitários em `app/test/features/identity/viewmodels/identity_form_view_model_test.dart` validando que `carregarSessaoExistente()` reinicia `isSuccess: false` e `errorMessage: null` após um `submitIdentity` concluído anteriormente, e verificar que falham antes da implementação (Red)
- [x] 1.2 Implementar o reset de `isSuccess: false` e `errorMessage: null` em `IdentityFormViewModel.carregarSessaoExistente()` em `app/lib/features/identity/viewmodels/identity_form_view_model.dart` e verificar que os testes de `identity_form_view_model_test.dart` passam (Green)
- [x] 1.3 Escrever testes de widget em `app/test/features/identity/views/identity_setup_screen_test.dart` validando que abrir `IdentitySetupScreen` via `Navigator.push` quando `isSuccess` já era `true` mantém a tela aberta para edição e que concluir o salvamento executa `Navigator.pop` retornando à tela anterior sem duplicar a `HomeScreen`
- [x] 1.4 Atualizar `IdentitySetupScreen` em `app/lib/features/identity/views/identity_setup_screen.dart` para observar apenas a transição `!(previous?.isSuccess ?? false) && next.isSuccess`, desempilhando (`Navigator.pop`) quando `Navigator.canPop(context)` for `true` e invalidando `currentIdentityProvider`, e verificar que `flutter test test/features/identity/` passa com 100% de cobertura

## 2. Cooldown e Resiliência de Rate-Limit no ServicoAppCheck (Issues #7 e #8 / FIXALOG-3 e FIXALOG-4)

- [x] 2.1 Escrever testes unitários em `app/test/core/services/servico_app_check_test.dart` validando que exceções contendo `Too many attempts` são registradas como `logAviso` (sem `logError`) e que falhas de obtenção de token ativam um *cooldown* em memória de 5 minutos para chamadas `obterToken(false)` (ignorável via `obterToken(true)`), verificando a falha inicial (Red)
- [x] 2.2 Implementar o *cooldown* determinístico com relógio injetável e a classificação de `Too many attempts` como `logAviso` em `app/lib/core/services/servico_app_check.dart`, verificando que `flutter test test/core/services/servico_app_check_test.dart --coverage` passa com 100% de cobertura (Green)

## 3. Verificação Integrada

- [x] 3.1 Executar `flutter analyze --fatal-infos --fatal-warnings` e a suíte de testes afetada em `app/` garantindo zero avisos e 100% de aprovação
