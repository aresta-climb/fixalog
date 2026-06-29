## ADDED Requirements

### Requirement: O sistema DEVE bloquear coordenadas Mocked
Se a API de localização do dispositivo indicar que as coordenadas recebidas foram originadas por um aplicativo simulador de GPS (Mock Location), a operação DEVE ser bloqueada.

#### Scenario: Bloqueio de submissão por Fake GPS
- **WHEN** a propriedade isMocked da Location retornada for verdadeira
- **THEN** o sistema exibe um erro de segurança e não gera o arquivo PDF, protegendo a integridade do processo
