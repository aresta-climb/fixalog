# Spec Delta: Canal de Feedback In-App Offline

## Purpose

Permite que os auditores e escaladores capturem telas com anotações gráficas e enviem relatos mesmo sem conexão à internet através de fila persistente local.

## ADDED Requirements

### Requirement: Captura e Anotação Visual de Feedback
O sistema DEVE (MUST) permitir ao usuário acionar a ferramenta de feedback sobre qualquer tela do aplicativo, desenhando anotações vetoriais sobre a captura de tela e anexando descrição textual.

#### Scenario: Acionamento e anotação sobre a tela
- **WHEN** o usuário seleciona a opção de enviar relato ou feedback
- **THEN** o sistema congela a tela atual e exibe ferramentas de desenho e caixa de texto para o relato

### Requirement: Compressão e Enfileiramento Offline
O sistema DEVE (MUST) comprimir a captura de tela resultante e armazenar o feedback em banco local SQLite (`FeedbackRecord`) com status pendente caso o dispositivo não possua conexão à internet ativa.

#### Scenario: Envio de relato em ambiente offline
- **WHEN** o usuário confirma o envio do feedback sem sinal de rede
- **THEN** o sistema salva o registro localmente no SQLite com status pendente e exibe confirmação de que o relato será transmitido assim que a conexão for restabelecida

### Requirement: Despacho em Segundo Plano Pós-Reconexão
O sistema DEVE (MUST) verificar periodicamente ou ao detectar retorno de conectividade a existência de feedbacks pendentes na fila local, transmitindo-os ao endpoint do ecossistema e atualizando o status para enviado.

#### Scenario: Recuperação de sinal de rede
- **WHEN** a conectividade à internet é restabelecida
- **THEN** o serviço de fila transmite os relatos pendentes em segundo plano sem travar a interface do usuário
