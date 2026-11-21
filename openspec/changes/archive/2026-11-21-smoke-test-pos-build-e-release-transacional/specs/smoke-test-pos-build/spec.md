# Spec Delta

## Purpose

Garante que os artefatos móveis compilados em modo de lançamento do Fixalog (Android e iOS) sejam validados de ponta a ponta em ambiente virtualizado nativo (emulador Android KVM e iOS Simulator) — cobrindo inicialização nativa, autenticação OIDC, cofre criptográfico ECDSA, compressão de mídia e geração de laudo EPUB 3 assinado — assegurando simultaneamente ausência absoluta de código de teste nos binários distribuídos às lojas.

## ADDED Requirements

### Requirement: Pureza Binária dos Artefatos Oficiais de Loja
Os pacotes oficiais gerados para distribuição nas lojas (`.aab` Android e `.ipa` iOS) DEVEM (MUST) ser compilados com o modo de smoke desativado em tempo de compilação e auditados automaticamente antes de qualquer publicação para impedir que rotinas, canais ou endpoints de teste alcancem dispositivos reais de usuários.

#### Scenario: Auditoria aprova pacote oficial isento de símbolos de smoke
- **WHEN** o pacote oficial `.aab` ou `.ipa` é inspecionado pelo auditor pós-build
- **THEN** o auditor verifica a presença das bibliotecas nativas essenciais e confirma que nenhum marcador de smoke test consta nos binários compilados

#### Scenario: Auditoria bloqueia pacote oficial contaminado por artefatos de smoke
- **WHEN** qualquer arquivo executável ou biblioteca compartilhada dentro do `.aab` ou `.ipa` oficial contiver marcadores de rota ou canal de smoke test
- **THEN** a auditoria falha imediatamente com código diferente de zero, abortando o pipeline antes do corte de versão

#### Scenario: Validação de Cold Start puro do pacote Android oficial
- **WHEN** o APK universal extraído do `.aab` oficial da loja é instalado e iniciado no emulador Android
- **THEN** o processo do aplicativo permanece vivo até a renderização inicial sem registrar exceções fatais de tempo de execução nativo ou Dart

### Requirement: Restrição Dupla de Hardware Virtual e Loopback no Binário de Smoke
O binário descartável de smoke test DEVE (MUST) restringir sua ativação simultaneamente à flag explícita de compilação de CI, à detecção de execução em emulador Android ou iOS Simulator e a endereços estritamente locais de loopback (`127.0.0.1`, `localhost` ou `10.0.2.2`), silenciando o envio de eventos externos ao Sentry e telemetria de produção durante a sessão.

#### Scenario: Rejeição de endereço externo fora de loopback
- **WHEN** o binário de smoke recebe um endereço de servidor cujo host não pertence ao conjunto de loopback local permitido
- **THEN** a inicialização de smoke recusa o servidor e falha explicitamente sem executar desvios de autenticação

#### Scenario: Bloqueio físico fora de emulador ou simulador
- **WHEN** o canal nativo de smoke é consultado fora de um emulador Android QEMU ou fora do ambiente iOS Simulator
- **THEN** a camada nativa não expõe nem executa o desvio de emissão local de token OIDC

### Requirement: Jornada Ponta a Ponta Pós-Build com Login OIDC e Emissão de Laudo Assinado
Antes da aprovação de um lançamento, o pacote descartável compilado com minificação/ofuscação de lançamento no Android e para o iOS Simulator DEVE (MUST) concluir com sucesso a jornada pericial completa sem mockar banco de dados, cofre de chaves, compressão de mídia ou assinatura digital.

#### Scenario: Execução completa da jornada de smoke em Android e iOS
- **WHEN** o orquestrador inicia o servidor local de smoke e lança o aplicativo no emulador Android ou no iOS Simulator
- **THEN** o aplicativo aceita os Termos de Uso no SQLite nativo, gera o par de chaves ECDSA no cofre seguro do sistema operacional, autentica via OIDC pelo canal nativo validando o vínculo criptográfico `SHA-256(rawNonce)`, emite o certificado X.509 da identidade técnica, processa uma sessão com foto WebP, vídeo transcodificado H.264 com poster frame e documento PDF rasterizado, gera e assina o pacote `.epub` com XML-DSig, carrega o relatório extraído e reporta sucesso sem erros não tratados ao orquestrador

#### Scenario: Falha imediata ao capturar erro de framework ou plataforma durante o smoke
- **WHEN** ocorre qualquer exceção não tratada no framework ou na plataforma nativa, ou alguma etapa do relatório pericial falha durante a jornada de smoke
- **THEN** o aplicativo reporta a falha detalhada ao orquestrador local e o pipeline encerra com erro antes do corte de versão
