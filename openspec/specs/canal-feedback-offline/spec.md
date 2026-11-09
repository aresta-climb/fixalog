# Canal de Feedback In-App Offline

## Purpose

Permite que os auditores e escaladores capturem telas com anotações gráficas e enviem relatos mesmo sem conexão à internet através de fila persistente local no `BancoDadosLocal` (SQLite).

## Requirements

### Requirement: Captura e Anotação Visual de Feedback
O sistema DEVE (MUST) permitir ao usuário acionar a ferramenta de feedback sobre a tela do aplicativo, desenhando anotações vetoriais sobre a captura de tela e anexando descrição textual no idioma ativo da interface.

#### Scenario: Acionamento e anotação sobre a tela
- **WHEN** o usuário seleciona a opção de enviar relato ou feedback (`BotaoFeedback`)
- **THEN** o sistema congela a tela atual e exibe ferramentas de desenho e formulário textual para o relato

### Requirement: Compressão e Enfileiramento Offline no SQLite
O sistema DEVE (MUST) comprimir a captura de tela resultante e armazenar o feedback na tabela `fila_feedback` do `BancoDadosLocal` (`FeedbackRecord`) com status pendente antes de tentar o despacho pela rede, garantindo persistência mesmo se o dispositivo estiver sem conexão à internet.

#### Scenario: Envio de relato em ambiente offline
- **WHEN** o usuário confirma o envio do feedback sem sinal de rede na montanha
- **THEN** o sistema salva o `FeedbackRecord` localmente na tabela `fila_feedback` do SQLite com status pendente, registra a tentativa como aviso transitório no `RegistroLogger` e exibe confirmação de que o relato será transmitido quando houver conexão

### Requirement: Despacho em Segundo Plano Pós-Reconexão com App Check
O sistema DEVE (MUST) verificar a existência de feedbacks pendentes na tabela `fila_feedback` do `BancoDadosLocal` e transmiti-los ao endpoint de nuvem com o cabeçalho `X-Firebase-AppCheck`, marcando o registro como enviado e removendo o arquivo temporário de imagem após confirmação HTTP 2xx. Em modo de desenvolvimento (`kModoDesenvolvimento`), caso o dispositivo não possua um token real do Firebase App Check registrado, o sistema DEVE (MUST) realizar um mock gracioso local (`[DEBUG MOCK]`), registrando os dados no console via `logInfo`, marcando o feedback como enviado no SQLite e removendo o arquivo de imagem temporário sem realizar chamada HTTP.

#### Scenario: Recuperação de sinal de rede e despacho
- **WHEN** o despacho da fila de feedback é acionado com conectividade ativa e token válido do App Check
- **THEN** o `ServicoFilaFeedback` transmite os relatos pendentes via multipart HTTP POST autenticado, atualiza o status no SQLite para enviado e limpa o arquivo de captura de tela local

#### Scenario: Mock gracioso de feedback em desenvolvimento sem token do App Check registrado
- **WHEN** o despacho da fila de feedback é acionado em modo de desenvolvimento (`kModoDesenvolvimento`) e o token do App Check está ausente ou é o fallback local (`app_check_token_fixalog_padrao`)
- **THEN** o `ServicoFilaFeedback` registra `📝 [DEBUG MOCK]` via `logInfo` sem realizar chamada HTTP, marca o item como enviado no SQLite e remove o arquivo de imagem temporário

### Requirement: Anexo Automático de Breadcrumbs nos Metadados do Feedback
O `ServicoFilaFeedback` DEVE (MUST) incluir automaticamente a lista cronológica de eventos recentes obtida de `GravadorBreadcrumbs.instancia.obterBreadcrumbs()` no campo `breadcrumbs` do `metadadosJson` de cada `FeedbackRecord` enfileirado.

#### Scenario: Enfileiramento de feedback após navegação pelo aplicativo
- **WHEN** o auditor realiza ações no aplicativo e envia um relato através do `ServicoFilaFeedback.enfileirarEDespacharFeedback`
- **THEN** o `metadadosJson` salvo no `FeedbackRecord` contém a chave `breadcrumbs` com a lista das últimas ações registradas no `GravadorBreadcrumbs`
