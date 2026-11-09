# Spec Delta

## MODIFIED Requirements

### Requirement: Aceite e Solicitação de Permissões
O sistema DEVE (MUST) exigir que o usuário marque explicitamente a caixa de confirmação ("Li e concordo com os Termos de Uso e a Política de Privacidade") antes de liberar a ação de aceite e persistir a auditoria completa no banco de dados local SQLite, sem disparar diálogos nativos de permissão de Câmera e GPS na tela de termos (pois as permissões são apresentadas e solicitadas na Etapa 2 da configuração de identidade).

#### Scenario: Tentativa de aceite sem marcar confirmação
- **WHEN** o usuário acessa a tela e a caixa de confirmação de leitura não está marcada
- **THEN** o botão de aceitar e continuar permanece desabilitado

#### Scenario: Aceite confirmado pelo usuário
- **WHEN** o usuário marca a caixa de confirmação e clica no botão "Aceitar Termos e Continuar"
- **THEN** o sistema grava no `AppConfigRecord` do banco SQLite a versão aceita (`kVersaoLegal`) e a data/hora exata do aceite (`dataHoraAceiteTermos`) sem disparar diálogos de permissão na tela de termos
- **THEN** o sistema avança para a tela subsequente de configuração de identidade ou home
