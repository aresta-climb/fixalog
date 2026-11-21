# Spec Delta

## MODIFIED Requirements

### Requirement: Automação de CI/CD para Google Play e TestFlight
O repositório DEVE (MUST) possuir fluxos automatizados do GitHub Actions em paridade com o ecossistema Aresta (`release_new_app_version.yml`, `build_android.yml`, `build_ios.yml`, `submit_ios_review.yml` e `atualizar_termos_legais.yml`) apoiados por ferramentas determinísticas de versionamento SemVer em Dart (`app/tool/release_tools/`) com espelhamento 1:1 de testes unitários e topologia transacional de quatro estágios:
1. O workflow orquestrador `release_new_app_version.yml` DEVE receber `bump_type` (`patch`, `minor`, `major`, `custom`), `custom_version`, `deploy_android`, `deploy_ios`, `enviar_para_producao`, `publicar_nas_lojas` (padrão `true`), `executar_robo_caotico` e `release_notes`, validar no primeiro passo que `release_notes` possui entre 1 e 500 caracteres, executar `flutter analyze`, `flutter test` e (quando habilitado) a campanha do Robô Caótico de 5 minutos, calcular a versão de release via `calcular_versao_release.dart`, sincronizar o submódulo `app/legal/repo` e a constante `versaoTermosLegaisAtuais` e empacotar o estado candidato para os jobs de compilação **sem realizar push de commits ou tags antes da aprovação dos smoke tests**;
2. Os estágios de compilação e validação pós-build (`build_android.yml` e `build_ios.yml` em modo de compilação e smoke) DEVEM compilar os pacotes oficiais (`.aab` e `.ipa`) com `--obfuscate --split-debug-info=build/symbols`, auditar a pureza binária dos pacotes oficiais, executar o smoke test funcional ponta a ponta (emulador Android KVM e iOS Simulator) e publicar os artefatos aprovados em staging do GitHub Actions antes de qualquer envio às lojas;
3. Somente após o sucesso integral da compilação e do smoke test em todas as plataformas selecionadas (e quando `publicar_nas_lojas == true`), um job dedicado de corte de versão DEVE criar o commit de lançamento, a tag `v<semver>+<build>` e o commit de avanço para `<proximo_patch>-dev+<build+1>` via `calcular_proximo_dev.dart`, publicando-os de forma atômica via `git push --atomic`;
4. Após o corte atômico da versão (quando `publicar_nas_lojas == true`), os estágios de publicação de `build_android.yml` e `build_ios.yml` DEVEM reutilizar os artefatos aprovados de staging (sem recompilar), enviar símbolos de debug ao Sentry (`sentry_dart_plugin`) e ao Firebase Crashlytics (`firebase-tools crashlytics:symbols:upload` e `upload-symbols` de `dSYMs`), publicar nas faixas `internal,production` (ou `internal`) do Google Play com `whatsnew-pt-BR` e no App Store Connect via `xcrun altool --upload-app` (`--apple-id "6818883254"`), acionando `submit_ios_review.yml` via Fastlane (`submeter_revisao`) quando `enviar_para_producao == true`.

#### Scenario: Disparo de Release Unificado
- **WHEN** o workflow `release_new_app_version.yml` é acionado com `bump_type = 'patch'`, `enviar_para_producao = true`, `publicar_nas_lojas = true` e `release_notes` com até 500 caracteres, e ambos os smoke tests (Android e iOS) são aprovados
- **THEN** a esteira valida o tamanho das notas no primeiro passo, calcula a versão de release removendo o sufixo `-dev` e incrementando o build, sincroniza os termos legais, aprova as compilações e smoke tests em Android e iOS, cria e envia atomicamente (`git push --atomic`) a tag Git `v<versao>+<build>` e o próximo ciclo `-dev` e aciona a publicação unificada nas lojas e `submit_ios_review`

#### Scenario: Bloqueio de Corte de Versão e Lojas quando Smoke Test Falha
- **WHEN** a compilação ou o smoke test pós-build falha em Android ou em iOS
- **THEN** o job de corte de versão e os jobs de publicação nas lojas NÃO são executados, mantendo a branch `main`, as tags Git e os `versionCode` nas lojas inalterados

#### Scenario: Disparo de Validação Interna sem Publicar nas Lojas
- **WHEN** o workflow `release_new_app_version.yml` é acionado com `publicar_nas_lojas = false`
- **THEN** a esteira executa integralmente a validação, a compilação dos pacotes `.aab` e `.ipa` oficiais, a auditoria binária e os smoke tests em Android Emulator KVM e iOS Simulator publicando os relatórios de evidência nos artefatos do GitHub Actions, mas omite o corte de versão no Git e o upload para Google Play, App Store Connect, Sentry e Crashlytics

#### Scenario: Falha Imediata quando Notas de Lançamento Excedem 500 Caracteres
- **WHEN** o workflow `release_new_app_version.yml` é acionado com `release_notes` contendo mais de 500 caracteres
- **THEN** o job inicial falha em menos de 10 segundos antes de criar commits, tags ou iniciar compilações móveis

#### Scenario: Compilação e Deploy do Android
- **WHEN** o workflow `build_android.yml` é executado com `enviar_para_producao = true`, `publicar_nas_lojas = true` e `release_notes` preenchido
- **THEN** o estágio de compilação gera o `.aab` ofuscado e aprova a auditoria binária e o smoke test no emulador KVM, e o estágio de publicação após o corte da versão envia símbolos ao Sentry e Crashlytics, preenche `whatsnew-pt-BR` e publica nas faixas `internal,production` da Google Play Store

#### Scenario: Compilação e Deploy do iOS
- **WHEN** o workflow `build_ios.yml` aprova a compilação do `.ipa`, a auditoria binária e o smoke test no iOS Simulator e conclui o envio para o TestFlight (`apple-id 6818883254`) com `enviar_para_producao = true` e `publicar_nas_lojas = true`
- **THEN** o runner macOS envia os `dSYMs` ao Crashlytics e símbolos ao Sentry, publica o `.ipa` via `xcrun altool` e o workflow `submit_ios_review.yml` aguarda o processamento da build na Apple via `FastlaneCore::BuildWatcher` e executa `deliver` para submeter a versão à revisão da App Store com as notas em `pt-BR` e `default`
