## MODIFIED Requirements

### Requirement: Exibição dos Termos de Uso
O sistema DEVE (MUST) verificar no banco de dados local (Isar) se a versão legal ativa (`kVersaoLegal`) já foi aceita pelo usuário e carregar dinamicamente o conteúdo formatado em Markdown de `termos-de-uso-fixlog.md`.

#### Scenario: Termos desatualizados ou não aceitos
- **WHEN** o aplicativo inicializa e o campo `versaoTermosAceita` (ou `acceptedTermsVersion`) na tabela `AppConfigRecord` for menor que `kVersaoLegal`
- **THEN** o sistema redireciona o usuário para a tela `TelaTermosDeUso`
- **THEN** o sistema exibe o documento Markdown de termos de uso com estilos visuais adaptados ao tema escuro

#### Scenario: Termos atualizados já aceitos
- **WHEN** o aplicativo inicializa e a versão aceita confere com a constante `kVersaoLegal`
- **THEN** o sistema prossegue diretamente para o fluxo principal (Identidade ou HomeScreen) sem exibir a tela de termos

### Requirement: Aceite e Solicitação de Permissões
O sistema DEVE (MUST) exigir que o usuário marque explicitamente a caixa de confirmação ("Li e concordo com os Termos de Uso e a Política de Privacidade") antes de liberar a ação de aceite, solicitar as permissões de Câmera e GPS e persistir a auditoria completa no Isar.

#### Scenario: Tentativa de aceite sem marcar confirmação
- **WHEN** o usuário acessa a tela e a caixa de confirmação de leitura não está marcada
- **THEN** o botão de aceitar e continuar permanece desabilitado

#### Scenario: Aceite confirmado pelo usuário
- **WHEN** o usuário marca a caixa de confirmação e clica no botão "Aceitar Termos e Continuar"
- **THEN** o sistema aciona os diálogos nativos do sistema operacional solicitando permissão para Câmera e GPS
- **THEN** o sistema grava no `AppConfigRecord` a versão aceita (`kVersaoLegal`) e a data/hora exata do aceite (`dataHoraAceiteTermos`)
- **THEN** o sistema avança para a tela subsequente de configuração de identidade ou home

## ADDED Requirements

### Requirement: Visualização da Política de Privacidade em Modal
O sistema DEVE (MUST) permitir a leitura sob demanda da Política de Privacidade (`politica-de-privacidade-fixlog.md`) a partir de links clicáveis ou botão de apoio sem fechar o fluxo de onboarding.

#### Scenario: Abertura do modal de privacidade
- **WHEN** o usuário toca no link da Política de Privacidade dentro da tela de termos
- **THEN** o sistema abre um modal inferior deslizante (BottomSheet) renderizando o documento completo em Markdown
- **THEN** o usuário pode fechar o modal e retornar exatamente ao ponto em que estava na tela de aceite
