# onboarding-terms Specification

## MODIFIED Requirements

### Requirement: Exibição dos Termos de Uso
O sistema DEVE (MUST) verificar no banco de dados local SQLite (`sqflite`) se a versão legal ativa (`kVersaoLegal`) já foi aceita pelo usuário e carregar dinamicamente o conteúdo formatado em Markdown de `termos-de-uso-fixalog.md` correspondente ao idioma ativo (`pt`, `en`, `es`, `fr`, `de`, `ar`, `ja`), com fallback para Inglês (`en`).

#### Scenario: Termos desatualizados ou não aceitos
- **WHEN** o aplicativo inicializa e o campo `versaoTermosAceita` na tabela de configuração (`AppConfigRecord`) for menor que `kVersaoLegal`
- **THEN** o sistema redireciona o usuário para a tela `TelaTermosDeUso`
- **THEN** o sistema exibe o documento Markdown de termos de uso no idioma ativo com estilos visuais adaptados ao tema escuro

#### Scenario: Termos atualizados já aceitos
- **WHEN** o aplicativo inicializa e a versão aceita confere com a constante `kVersaoLegal`
- **THEN** o sistema prossegue diretamente para o fluxo principal (Identidade ou HomeScreen) sem exibir a tela de termos

### Requirement: Visualização da Política de Privacidade em Modal
O sistema DEVE (MUST) permitir a leitura sob demanda da Política de Privacidade no idioma ativo a partir de links clicáveis com alvo canônico (`#privacy-policy` ou referência ao arquivo `politica-de-privacidade-fixalog.md`) ou botão de apoio em qualquer um dos 7 idiomas suportados, sem fechar o fluxo de onboarding.

#### Scenario: Abertura do modal de privacidade
- **WHEN** o usuário toca no link da Política de Privacidade (`#privacy-policy`) ou no botão de leitura da política dentro da tela de termos em qualquer idioma suportado
- **THEN** o sistema abre um modal inferior deslizante (BottomSheet) renderizando o documento completo da Política de Privacidade no idioma ativo em Markdown
- **THEN** o usuário pode fechar o modal e retornar exatamente ao ponto em que estava na tela de aceite

## ADDED Requirements

### Requirement: Seletor de Idioma na Tela Inicial de Termos de Uso
A tela `TelaTermosDeUso` DEVE (MUST) disponibilizar no cabeçalho (`AppBar`) um seletor de idioma visível que permita ao usuário alternar imediatamente entre os 7 idiomas suportados antes de ler e aceitar os termos.

#### Scenario: Troca de idioma antes do aceite dos termos
- **WHEN** o usuário está na `TelaTermosDeUso` e altera o idioma no seletor do topo para Francês (`fr`)
- **THEN** o sistema persiste a preferência de idioma no banco local SQLite e recarrega imediatamente os textos da tela, os Termos de Uso e a Política de Privacidade em Francês
