# Proposta: Infraestrutura de Observabilidade Dual (Firebase + Sentry), App Check e Gestão de Memória

## Why

Atualmente, o Fixalog opera sem qualquer mecanismo centralizado de telemetria, captura de erros ou observabilidade de falhas em campo. Quando um auditor ou escalador enfrenta um crash inesperado durante uma perícia em ambiente remoto de montanha, ou quando ocorre uma falha inesperada na sincronização de pacotes EPUB 3 (`SincronizadorNuvemService`) ou na autenticação OIDC OpenPubkey (`AutenticacaoNuvemService`), o erro é silencioso (`catch (_)`) e inviabiliza diagnósticos rápidos. Além disso:
- O `AutenticacaoNuvemService` utiliza atualmente um stub estático (`'app_check_token_fixalog_padrao'`) para o cabeçalho `X-Firebase-AppCheck` exigido pelo worker de nuvem (`https://fixalog.app`).
- A manipulação de múltiplas fotografias de alta resolução de proteções fixas e paradas sem gestão de memória adaptativa impõe alto risco de falha nativa por esgotamento de memória (*OutOfMemory* / SIGSEGV).

Adotar o **Sentry** (integrado ao ecossistema Aresta Climb e seus roteadores de alertas no WhatsApp e GitHub Issues) em conjunto com o **Firebase** (Crashlytics, App Check, Remote Config e Analytics) resolve essas lacunas com custo operacional zero. Um serviço unificado (`RegistroLogger`) com filtro inteligente de instabilidades transitórias de montanha garante que perda de sinal 4G não polua o rastreador de incidentes, enquanto o armazenamento local (*outbox*), a atestação criptográfica de integridade do app (`ServicoAppCheck`) e a gestão adaptativa de cache de imagens garantem resiliência total em conformidade com o princípio de 100% Offline-First.

## What Changes

- **Integração Dual Firebase + Sentry**:
  - Configuração do projeto Firebase dedicado `com-arestaclimb-fixlog` (`firebase_core`, `firebase_crashlytics`, `firebase_app_check`, `firebase_analytics`, `firebase_remote_config`) para o pacote `com.arestaclimb.fixalog`.
  - Adição do SDK `sentry_flutter: ^10.2.0` no aplicativo e do plugin `sentry_dart_plugin: ^3.4.0` para desofuscação de símbolos.
- **Serviço Centralizado `RegistroLogger` (`app/lib/core/services/registro_logger.dart`)**:
  - Abstração centralizada para log de informações (`logInfo`), avisos (`logAviso`), erros operacionais (`logError`), falhas de sincronização (`logFalhaSyncOuDownload`) e falhas críticas (`logCrash`).
  - Reconhecimento automático de instabilidade de conectividade e quedas de rede via `isFalhaConexaoOuTimeout`, rebaixando erros transitórios de rede para breadcrumbs e evitando alertas espúrios na montanha.
  - Instrumentação de `SincronizadorNuvemService` e `AutenticacaoNuvemService` para substituir blocos `catch (_)` silenciosos por registros estruturados via `RegistroLogger`.
  - Implementação *test-only* de `RegistroLoggerFake` em `app/test/fakes/registro_logger_fake.dart` (com `registro_logger_fake_test.dart`) para assegurar fidelidade de produção sem uso de mocks (Princípio V).
- **Atestação de Integridade via Firebase App Check (`app/lib/core/services/servico_app_check.dart`)**:
  - Implementação do `ServicoAppCheck` utilizando Play Integrity no Android, App Attest no iOS e Debug Provider em modo de desenvolvimento, com degradação graciosa offline.
  - Conexão do `ServicoAppCheck` como provedor real de tokens em `AutenticacaoNuvemService.obterTokenAppCheck()`, alimentando o cabeçalho `X-Firebase-AppCheck` enviado pelo `SincronizadorNuvemService`.
- **Gestão Adaptativa de Memória (`app/lib/core/services/classificador_dispositivo.dart`)**:
  - Leitura da capacidade de RAM do hardware e dimensionamento do teto de `imageCache` do Flutter (50 MB a 150 MB) para prevenir falhas nativas de OOM durante catalogação de fotos e geração de PDF/EPUB.
- **Esteira de CI/CD com Ofuscação e Upload de Símbolos (Android e iOS)**:
  - Atualização dos workflows `.github/workflows/build_android.yml` e `.github/workflows/build_ios.yml` para compilar com `--obfuscate --split-debug-info=build/symbols` e realizar upload automático dos símbolos no Sentry e Crashlytics.

## Capabilities

### New Capabilities
- `observabilidade-dual-logger`: Serviço de logging e captura de exceções dual (Sentry + Crashlytics), atestação Firebase App Check e filtro de desconexão de montanha com fila offline.
- `gestao-memoria-dispositivo`: Classificação dinâmica de RAM e dimensionamento de cache de imagens para prevenção de OOM.

### Modified Capabilities
*(Nenhuma especificação canônica existente em `openspec/specs/` teve seus requisitos alterados)*

## Impact

- **Código e Dependências**:
  - `app/pubspec.yaml`: inclusão de `firebase_core`, `firebase_crashlytics`, `firebase_app_check`, `firebase_analytics`, `firebase_remote_config`, `sentry_flutter` e `sentry_dart_plugin`.
  - `app/lib/main.dart`: inicialização coordenada e resiliente do Firebase, `ServicoAppCheck`, `ClassificadorDispositivo` e `SentryFlutter.init`.
  - `app/lib/core/services/`: criação de `registro_logger.dart`, `servico_app_check.dart`, `classificador_dispositivo.dart`, `servico_configuracao_remota.dart`, `servico_telemetria.dart` e instrumentação de `sincronizador_nuvem_service.dart` e `autenticacao_nuvem_service.dart`.
  - `app/test/`: testes unitários espelhados 1:1 para todos os arquivos criados e `app/test/fakes/registro_logger_fake.dart` (+ `_test.dart`).
- **Infraestrutura e CI/CD**:
  - `.github/workflows/build_android.yml` e `.github/workflows/build_ios.yml`: flags `--obfuscate --split-debug-info=build/symbols` e upload via `sentry_dart_plugin` (`SENTRY_AUTH_TOKEN`).
