# Projeto da Interface de Usuário: FixaLog

Este documento detalha as especificações do layout, métricas CSS (tokens), sistema de componentes e ponteiros do Google Stitch (StitchMCP) desenvolvidos pelo Designer UX/UI para orientar a implementação pixel-perfect pela Engenharia.

## 1. Visão Geral do Projeto (StitchMCP)
* **ID do Projeto no Google Stitch:** `projects/4266835099781872140`
* **Nome do Projeto:** "FixaLog UI Design"
* **Creative North Star:** *"The Digital Topo"* (Technical Brutalism).

Diferente de aplicativos de consumo voltados ao "softness", a UI do FixaLog imita o acabamento premium de hardwares de escalada (como mosquetões anodizados) e a precisão técnica de um mapa topográfico. É um sistema utilitário, "indestrutível" e focado em alta legibilidade outdoor.

---

## 2. Telas Definidas no Google Stitch
As telas do aplicativo já estão projetadas e disponíveis no Stitch. O Engenheiro(a) pode invocá-las através do MCP para obter detalhes do layout de renderização.

1. **FixaLog - Home (V2)** `[ID: 18b316ac6a2c4ba1a1bb45e5aeeb72ff]`
   - Lista inicial contendo os Protocolos de Manutenção prontos e a listagem de Histórico (arquivos salvos).
2. **FixaLog - Home** `[ID: d518517b735043338a262ad89d85aa3a]`
   - Variação do layout da Home.
3. **Protocolo Guiado** `[ID: 8498584b393a47df9721a33c56f5108f]`
   - Estrutura base dos "Cards" modais de tela cheia (Thermomix Style). Inclui input fields, uploads e navegação passo a passo (Wizard).
4. **Resumo e Conclusão** `[ID: 9054069d5a79418d951ae29107226bf2]`
   - Visualização sumarizada (Auditoria) com o canvas liberado ao final para coleta de Assinatura Visual (Manuscrita) antes de dar o gatilho na gravação segura.

---

## 3. Design System & Tokens Visuais

### Cores (Tonal Architecture)
O aplicativo força um design em "DARK MODE" estrito como premissa nativa (combate ao *glare* e brilho solar nas rochas).
* **Modo de Cor:** `DARK`
* **Background Base:** `#121416` (`surface`) com textura abstrata de 3% ("Noise") para assemelhar-se a pó/granito.
* **Cor Primária ("Rescue Orange"):** `#FF6B00` (Usar sobre fundos neutros. O texto atrelado deve ser `on_primary_container`).
* **Cor Secundária ("Moss Green"):** `#4F6D44` ou derivado `#aed09f` para feedback de sucesso e metadados lógicos focados à natureza.
* **Elevação de Superfícies:**
   - Base Level (Floor): `surface` (`#121416`)
   - Content Sections: `surface-container-low` (`#1a1c1e`)
   - Interactive Cards/Inputs: `surface-container-highest` (`#333537`)

### Tipografia Dual
* **Display / Headlines / Labels:** `Space Grotesk`. Oferece rigor paramétrico (técnico, tipo espaçamento metalúrgico) e alta classe. Títulos devem usar tracking apertado (-2%) `headline-lg`. Labels fixas de metadata em all-caps `label-md`.
* **Corpo / Formulários (Body):** `Inter`. Utilizado para garantir excepcional caligrafia técnica em listas longas, anotações de manutenção e descrições de grampos/chapeletas.

---

## 4. Elementos Estruturais e Componentes (Regras Estritas)

As seguintes regras devem ser forçadas pela engenharia nas diretrizes do Flutter:

#### O Fim das Linhas Divisórias Padrões ("No-Line Rule")
* Nunca usar bordas de subdivisão de "1px solid" nas listas e espaçadores. 
* A segmentação é conseguida mudando uma "bandeja" com `surface-container-low` ao redor de elementos do passo ou injetando 16px puros de whitespace.

#### Ghost Borders e Sombras de Oclusão Ambientais
* Sombras projetadas ("Drop Shadows" clássicas) não são aconselhadas.
* Para flutuação ativa de Cards sobre o background (`surface`): aplicar 24px de blur radius a 6% de opacidade utilizando a propriedade cor `on-surface`.
* Para contornos leves contra telas da mesma cor, usar "Ghost Border": uma borda interna de 1px `outline_variant` (`#5a4136`) em apenas 15% de opacidade.

#### Botões e Inputs
* **Action CTAs:** Usar shape `xl` (12px ou arredondamento equivalente). Devem preencher áreas visuais grandes (hit target extenso de 56px+ altura) para possibilitar toque com as mãos impregnadas de magnésio/luvas.
* **Inputs/Forms:** Background obrigatoriamente preenchido (`surface_container_highest`). Na ação *Focus*, não circular o input inteiro com borda larga; destacar *somente* o bottom-bar em `#FF6B00` com 2px.

---

## 5. Próximos Passos (Para Engenharia)
Na hora da estilização em Flutter, os *ThemeData* globais deverão abrigar estas especificações de cor. Os estilos abstratos dos Botões e Inputs podem e devem virar Widgets reaproveitáveis (`FixaLogTextField`, `FixaLogPrimaryButton`) configurados antecipadamente antes das rotas entrarem na etapa real de codificação. Os IDs do projeto expostos podem ser conferidos para consultar medidas de espaçamentos.
