# Spec Delta: Canal de Feedback In-App Offline

## MODIFIED Requirements

### Requirement: Despacho em Segundo Plano Pós-Reconexão com App Check
O sistema DEVE (MUST) verificar a existência de feedbacks pendentes na tabela `fila_feedback` do `BancoDadosLocal` e transmiti-los ao endpoint de nuvem com o cabeçalho `X-Firebase-AppCheck`, marcando o registro como enviado e removendo o arquivo temporário de imagem após confirmação HTTP 2xx. Em modo de desenvolvimento (`kModoDesenvolvimento`), caso o dispositivo não possua um token real do Firebase App Check registrado, o sistema DEVE (MUST) realizar um mock gracioso local (`[DEBUG MOCK]`), registrando os dados no console via `logInfo`, marcando o feedback como enviado no SQLite e removendo o arquivo de imagem temporário sem realizar chamada HTTP.

#### Scenario: Recuperação de sinal de rede e despacho
- **WHEN** o despacho da fila de feedback é acionado com conectividade ativa e token válido do App Check
- **THEN** o `ServicoFilaFeedback` transmite os relatos pendentes via multipart HTTP POST autenticado, atualiza o status no SQLite para enviado e limpa o arquivo de captura de tela local

#### Scenario: Mock gracioso de feedback em desenvolvimento sem token do App Check registrado
- **WHEN** o despacho da fila de feedback é acionado em modo de desenvolvimento (`kModoDesenvolvimento`) e o token do App Check está ausente ou é o fallback local (`app_check_token_fixalog_padrao`)
- **THEN** o `ServicoFilaFeedback` registra `📝 [DEBUG MOCK]` via `logInfo` sem realizar chamada HTTP, marca o item como enviado no SQLite e remove o arquivo de imagem temporário
