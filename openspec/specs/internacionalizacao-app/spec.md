# Internacionalização e Suporte Multilinguagem do Aplicativo

## Purpose

Provê o suporte nativo e offline a múltiplos idiomas (`pt`, `en`, `es`, `fr`, `de`, `ar`, `ja`) em todas as camadas do Fixalog, incluindo detecção e persistência de idioma, adaptação de layout RTL, padronização tipográfica com Google Noto Sans e localização dinâmica dos protocolos YAML mantendo identificadores técnicos canônicos em inglês.

## Requirements

### Requirement: Suporte aos 7 Idiomas Oficiais com Detecção e Fallback para Inglês
O sistema DEVE (MUST) suportar nativamente 7 idiomas — Português (`pt`), Inglês (`en`), Espanhol (`es`), Francês (`fr`), Alemão (`de`), Árabe (`ar`) e Japonês (`ja`). Quando nenhum idioma preferido estiver salvo localmente, o sistema DEVE (MUST) selecionar automaticamente o idioma do sistema operacional caso pertença aos 7 suportados, ou aplicar Inglês (`en`) como fallback padrão.

#### Scenario: Primeiro acesso com sistema operacional em idioma suportado
- **WHEN** o usuário abre o aplicativo pela primeira vez em um dispositivo configurado em Francês (`fr`) ou Japonês (`ja`)
- **THEN** o aplicativo inicializa e renderiza toda a interface no idioma correspondente do dispositivo

#### Scenario: Primeiro acesso com sistema operacional em idioma não suportado
- **WHEN** o usuário abre o aplicativo pela primeira vez em um dispositivo configurado em Italiano (`it`) ou Coreano (`ko`)
- **THEN** o aplicativo aplica o fallback padrão e renderiza toda a interface em Inglês (`en`)

### Requirement: Persistência e Troca Reativa de Idioma em Tempo de Execução
O sistema DEVE (MUST) persistir o código de idioma escolhido pelo usuário no banco de dados local SQLite (`configuracao_app`) e atualizar imediatamente toda a interface, os protocolos carregados e os documentos legais sem exigir reinicialização do aplicativo.

#### Scenario: Alteração manual de idioma na aba de Configurações
- **WHEN** o usuário seleciona Espanhol (`es`) no seletor de idioma da tela de Configurações
- **THEN** o sistema grava `es` no registro local de configuração no SQLite e atualiza imediatamente os textos das telas e menus para Espanhol

#### Scenario: Restauração do idioma escolhido ao reabrir o aplicativo
- **WHEN** o usuário que havia selecionado Alemão (`de`) fecha e abre novamente o aplicativo
- **THEN** o sistema lê a preferência persistida no SQLite e inicializa em Alemão (`de`), ignorando o idioma padrão do sistema operacional

### Requirement: Suporte a Escrita da Direita para a Esquerda (RTL) para Árabe
Quando o idioma ativo for Árabe (`ar`), o sistema DEVE (MUST) configurar a direcionalidade global da interface como `RTL` (Right-to-Left), espelhando alinhamentos horizontais, barras de navegação e ícones direcionais.

#### Scenario: Ativação do idioma Árabe na interface
- **WHEN** o idioma ativo do aplicativo é definido como Árabe (`ar`)
- **THEN** a árvore de widgets assume direção `TextDirection.rtl` e os textos e componentes visuais são alinhados da direita para a esquerda

### Requirement: Padronização Tipográfica Universal Offline com Google Noto Sans
O sistema DEVE (MUST) embutir localmente nos assets do aplicativo as fontes da família Google Noto Sans (`NotoSans` para escrita latina, `NotoSansArabic` para árabe e `NotoSansJP` para japonês) e aplicá-las como padrão tipográfico unificado da interface no Android e no iOS.

#### Scenario: Renderização de caracteres CJK, Árabes e Latinos sem conexão à internet
- **WHEN** o aplicativo é executado em modo avião nos idiomas Japonês (`ja`), Árabe (`ar`) ou Alemão (`de`)
- **THEN** todos os textos da interface são renderizados utilizando as fontes `NotoSans` locais sem depender de download de fontes pela rede

### Requirement: Protocolos YAML com IDs Canônicos em Inglês e Dicionários por Idioma
O motor de protocolos DEVE (MUST) manter uma definição estrutural única por protocolo com identificadores técnicos canônicos em inglês (`id` de protocolo, blocos, passos, conteúdos e `valor` de opções) e injetar os textos humanos (`nome`, `descricao`, `titulo`, `subtitulo`, `corpo`, `label`, `sublabel`) a partir do dicionário do idioma ativo em `assets/protocols/i18n/<locale>/`.

#### Scenario: Carregamento de protocolo no idioma ativo preservando IDs canônicos
- **WHEN** um usuário com idioma ativo em Japonês (`ja`) inicia o protocolo de abertura de vias e preenche os campos
- **THEN** o Wizard exibe todos os títulos, rótulos e opções traduzidos em Japonês
- **THEN** o manifesto Protobuf `Registro` armazena exclusivamente os identificadores técnicos canônicos em inglês

#### Scenario: Fallback de tradução em protocolo YAML
- **WHEN** um campo de protocolo não possui tradução cadastrada no dicionário do idioma ativo
- **THEN** o parser utiliza o texto de fallback em Inglês (`en`) sem interromper o carregamento do protocolo
