# Testes Caóticos Exploratórios e Regressão (`app/test/caos/`)

Esta pasta contém o **Robô Caótico** do Fixalog: um motor de testes exploratórios determinísticos (*Monkey / Fuzzing Testing*) que navega autonomamente pelo aplicativo completo (`FixalogApp`), exercitando interações de UI, transições assíncronas, todos os 5 protocolos YAML, troca de idiomas em tempo real (7 idiomas) e datasets de estresse sobre SQLite em memória (`:memory:`).

## Arquitetura dos Arquivos

- `receita_crash_robo.dart` e `receita_crash_robo_test.dart`: Modelos de ações (`PassoRobo`), seletores semânticos resilientes (`SeletorAlvoRobo`) e serialização JSON do pacote de reprodução (`ReceitaCrashRobo`).
- `encolhedor_caminho_crash.dart` e `encolhedor_caminho_crash_test.dart`: Algoritmo *Delta Debugging* (`ddmin`) por busca binária que reduz sequências longas de passos aleatórios até a sequência mínima (`passos_minimos`) capaz de reproduzir a mesma assinatura de falha.
- `fabrica_dataset_caos.dart` e `fabrica_dataset_caos_test.dart`: Geração determinística dos perfis `TipoDatasetCaos.normal` e `TipoDatasetCaos.toxico` (identidades e submissões com emojis multi-codepoint, textos RTL em árabe, caracteres japoneses, Markdown limite e strings longas) e montagem da árvore completa do aplicativo (`AmbienteAppCaos` com `FixalogApp`, `BetterFeedback` e `BancoDadosLocal.abrirEmMemoria()`).
- `motor_robo_caotico.dart` e `motor_robo_caotico_test.dart`: Orquestrador sobre `WidgetTester` que descobre widgets visíveis em todas as telas (`HomeScreen`, `NewProtocolScreen`, `WizardScreen`, `HistoryScreen`, `TelaConfiguracoes`, `IdentitySetupScreen`, `TelaTermosDeUso`), sorteia ações guiadas por `seed`, intercepta crashes não tratados, `FlutterError` (incluindo `RenderFlex overflow`) e erros tratados em `RegistroLogger.logError`/`logCrash`, realiza o shrinking automático (`ddmin`) e envia ao Sentry.
- `robo_caotico_exploratorio_test.dart`: Suíte exploratória parametrizada por `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS` (padrão `0`, fazendo skip automático no `flutter test` do dia a dia; quando executada, já vem com `REPORTAR_SENTRY_CAOS=true` e `kSentryDsn` ativos por padrão).
- `../integration_test/robo_caotico_dispositivo_test.dart`: Suíte para assistir o robô caótico agindo ao vivo em emulador, celular físico ou desktop (`defaultValue: 60` segundos e `REPORTAR_SENTRY_CAOS=true` por padrão).
- `regressao_caminhos_test.dart` e `caminhos_regressao/*.json`: Suíte permanente de regressão que carrega todas as receitas `.json` salvas e as reexecuta em `< 1s` para impedir que falhas corrigidas voltem a ocorrer.

## Observabilidade e Sentry em Tempo Real

- O `SENTRY_DSN` já está configurado nativamente no aplicativo (`kSentryDsn` em `lib/main.dart`) e `REPORTAR_SENTRY_CAOS` é **`true` por padrão** tanto em `robo_caotico_exploratorio_test.dart` quanto em `integration_test/robo_caotico_dispositivo_test.dart`.
- Durante a campanha, o Sentry permanece liberado em tempo real (agrupando ocorrências repetidas na mesma Issue pela deduplicação nativa do Sentry) e, ao término do shrinking (`ddmin`), recebe também o evento com o contexto `receita_robo_caotico` anexado.
- Caso deseje rodar localmente sem enviar eventos ao Sentry, passe `--dart-define=REPORTAR_SENTRY_CAOS=false`.

## Como Executar (a partir da pasta `app/`)

```powershell
# 1. Executar uma campanha exploratória no terminal (ex: 30 ou 60 segundos, já reportando ao Sentry por padrão)
flutter test test/caos/robo_caotico_exploratorio_test.dart --dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=60

# 2. Ver o Robô Caótico agindo ao vivo na tela (emulador ou celular conectado, padrão 60s)
flutter test integration_test/robo_caotico_dispositivo_test.dart --dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=60

# 3. Reproduzir todas as receitas permanentes de regressão (< 1s)
flutter test test/caos/regressao_caminhos_test.dart

# 4. Reproduzir uma única receita específica pelo nome do arquivo JSON
flutter test test/caos/regressao_caminhos_test.dart --plain-name "regressao_navegacao_abas_idioma_seed_1.json"

# 5. Executar os testes unitários do próprio motor do Robô Caótico + regressão
flutter test test/caos/
```
