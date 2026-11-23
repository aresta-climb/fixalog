# Spec Delta

## MODIFIED Requirements

### Requirement: Despacho em Segundo Plano Pós-Reconexão com App Check
O sistema DEVE (MUST) verificar a existência de feedbacks pendentes na tabela `fila_feedback` do `BancoDadosLocal` e transmiti-los ao endpoint de nuvem com o cabeçalho `X-Firebase-AppCheck`, marcando o registro como enviado e removendo o arquivo temporário de imagem após confirmação HTTP 2xx. Em modo de desenvolvimento (`kModoDesenvolvimento`), caso o dispositivo não possua um token real do Firebase App Check registrado (`null` ou vazio), o sistema DEVE (MUST) realizar um mock gracioso local (`[DEBUG MOCK]`), registrando os dados no console via `logInfo`, marcando o feedback como enviado no SQLite e removendo o arquivo de imagem temporário sem realizar chamada HTTP. Em modo de produção oficial (`!kModoDesenvolvimento`), caso o token do Firebase App Check esteja indisponível (`null` ou vazio), o sistema JAMAIS DEVE (MUST NOT) disparar requisição HTTP sem token válido, devendo registrar apenas um aviso operacional (`logAviso`) e preservar o relato pendente no SQLite sem reportar erro ao Sentry ou Crashlytics.

#### Scenario: Recuperação de sinal de rede e despacho
- **WHEN** o despacho da fila de feedback é acionado com conectividade ativa e token válido do App Check
- **THEN** o `ServicoFilaFeedback` transmite os relatos pendentes via multipart HTTP POST autenticado, atualiza o status no SQLite para enviado e limpa o arquivo de captura de tela local

#### Scenario: Mock gracioso de feedback em desenvolvimento sem token do App Check registrado
- **WHEN** o despacho da fila de feedback é acionado em modo de desenvolvimento (`kModoDesenvolvimento`) e o token do App Check está ausente (`null` ou em branco)
- **THEN** o `ServicoFilaFeedback` registra `📝 [DEBUG MOCK]` via `logInfo` sem realizar chamada HTTP, marca o item como enviado no SQLite e remove o arquivo de imagem temporário

#### Scenario: Suspensão silenciosa do envio em produção quando o token do App Check está indisponível
- **WHEN** o despacho da fila de feedback é acionado em produção oficial (`!kModoDesenvolvimento`) e o token do App Check retorna `null` ou vazio (ex.: emulador sem Play Integrity, *cooldown* ativo ou falha de rede no atestador)
- **THEN** o `ServicoFilaFeedback` não realiza chamada HTTP para a Edge Function, registra apenas um aviso (`logAviso`) sem disparar erro no Sentry, e mantém o registro pendente na tabela `fila_feedback` do SQLite
