# Spec Delta: onboarding-terms

## MODIFIED Requirements

### Requirement: Exibição dos Termos de Uso
O sistema DEVE (MUST) verificar no banco de dados local SQLite (`sqflite`) se a versão legal ativa (`kVersaoLegal`) já foi aceita pelo usuário e carregar dinamicamente o conteúdo formatado em Markdown de `termos-de-uso-fixalog.md`.

#### Scenario: Termos desatualizados ou não aceitos
- **WHEN** o aplicativo inicializa e o campo `versaoTermosAceita` na tabela de configuração (`AppConfigRecord`) for menor que `kVersaoLegal`
- **THEN** o sistema redireciona o usuário para a tela `TelaTermosDeUso`
- **THEN** o sistema exibe o documento Markdown de termos de uso com estilos visuais adaptados ao tema escuro

#### Scenario: Termos atualizados já aceitos
- **WHEN** o aplicativo inicializa e a versão aceita confere com a constante `kVersaoLegal`
- **THEN** o sistema prossegue diretamente para o fluxo principal (Identidade ou HomeScreen) sem exibir a tela de termos

### Requirement: Aceite e Solicitação de Permissões
O sistema DEVE (MUST) exigir que o usuário marque explicitamente a caixa de confirmação ("Li e concordo com os Termos de Uso e a Política de Privacidade") antes de liberar a ação de aceite, solicitar as permissões de Câmera e GPS e persistir a auditoria completa no banco de dados local SQLite.

#### Scenario: Tentativa de aceite sem marcar confirmação
- **WHEN** o usuário acessa a tela e a caixa de confirmação de leitura não está marcada
- **THEN** o botão de aceitar e continuar permanece desabilitado

#### Scenario: Aceite confirmado pelo usuário
- **WHEN** o usuário marca a caixa de confirmação e clica no botão "Aceitar Termos e Continuar"
- **THEN** o sistema aciona os diálogos nativos do sistema operacional solicitando permissão para Câmera e GPS
- **THEN** o sistema grava no `AppConfigRecord` do banco SQLite a versão aceita (`kVersaoLegal`) e a data/hora exata do aceite (`dataHoraAceiteTermos`)
- **THEN** o sistema avança para a tela subsequente de configuração de identidade ou home
