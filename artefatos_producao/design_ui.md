# Documento de Design de Interface (UI/UX) - FixaLog

**Autor:** @ux (Designer UX/UI)
**Status:** Mocks atualizados no Google Stitch
**Plataforma:** Mobile (Flutter)

---

## 1. Visão Geral do Design System: Technical Brutalism

Como @ux, nosso foco é garantir que o FixaLog seja uma ferramenta essencial, priorizando extrema usabilidade em ambientes hostis, como a base de uma via de escalada sob sol pleno ou com as mãos sujas de magnésio. A estética escolhida é o **Technical Brutalism**. Este sistema imita a robustez de equipamentos de escalada de ponta e a precisão de um mapa topográfico: utilitário, indestrutível e perfeitamente legível.

### 1.1 Arquitetura de Cores e Profundidade (Tonal Layering)
Abandonamos as bordas desenhadas e os temas planos convencionais. A interface usa "Tonal Layering", com peças empilhadas representadas por diferentes elevações (tons escuros progressivos):
- **Superfície Base (Background):** `#121416`
- **Conteúdo e Cards:** `#1a1c1e` (low), `#333537` (highest)
- **Primary (Rescue Orange):** `#ff6b00` (container), `#ffb693` (primary). Usado como sinal principal de alerta, ação primária e segurança. Remete a equipamentos de resgate.
- **Secondary (Moss Green):** `#314e28` (container), `#aed09f` (secondary). O acento verde musgo é focado em feedbacks ecológicos/positivos da manutenção.
- **Noise Texture:** Toda a superfície leva um leve "ruído visual" (3%) para simular a sensação de metal escovado ou granito texturizado, removendo a frieza digital do app.

### 1.2 Tipografia e Legibilidade 
A precisão se mistura com a leitura de alta clareza:
- **Headlines / Display:** `Space Grotesk` (Technical monospace feel). Utilizado para títulos de protocolo, métricas heróicas e nomes de via.
- **Corpo do texto / Data Entry:** `Inter`. Legibilidade absoluta para campos de texto dinâmicos (descrições técnicas de cola, chumbador, etc).
- As fontes são configuradas para serem lidas mesmo com reflexo do sol na tela (alto contraste de `on_surface` em relação ao fundo escuro).

### 1.3 Interatividade tátil e Componentes
- **Ghost Borders & Ambient Occulsion:** Não há uso de 'drop shadows' material. Elementos flutuantes têm desfoque pesado (blur de 20px) com baixíssima opacidade (6%), ou são definidos por uma borda "fantasma" (`outline-variant` 15%).
- **Inputs Gigantes:** Acessibilidade extrema. Campos de texto ou dropdowns possuem um touch target maior (mín 56px) para garantir usabilidade para mãos de escaladores (sujas ou com esparadrapo). 
- **CTAs:** O estado 'pressed' (pressionado) não apenas muda de cor, mas simula afundamento na topologia (muda a superfície de cor), entregando a resposta táctil.

---

## 2. Mapa de Telas (Conforme Google Stitch)

A arquitetura visual foi projetada considerando a navegação estritamente offline orientada a passos (estilo "Thermomix"), distribuída nas seguintes telas fundamentais:

### 2.1 Configuração de Identidade (V4 / V6)
**O que é:** O setup inicial onde o mantenedor assina digitalmente seu device.
- **Visão UX:** A identidade visual desta página prioriza confiança. É um contrato digital. Fundo escuro com destaques para elementos onde o usuário vai "gravar" sua assinatura criptográfica.
- **Micro-interações:** Botões de criação de chave robustos, dando feedback imediato de segurança local (sem loadings infinitos focados em internet).

### 2.2 FixaLog - Home (V2)
**O que é:** O painel principal "Dashboard do Mantenedor", acessado toda vez que o app abre.
- **Visão UX:** Apresentação clara do "Iniciar Nova Atividade" (Rescue Orange) com altíssima proeminência. A estrutura de listas agrupa os guias/protocolos baixados (ex: Rebolting Químico, Inspeção Anual) e os Relatórios Anteriores localmente em cards sem divisão de linhas horizontais, apenas por espaçamento generoso e blocos de cor (elevação tonal).

### 2.3 Protocolo Guiado (V7)
**O que é:** O formulário dinâmico. O coração do FixaLog em campo.
- **Visão UX:** Interface imersiva. Cada "Step" do protocolo toma conta da tela. A navegação usa controles de "Próximo" / "Anterior" enormes e facilmente alcançáveis pela área inferior da tela (Thumb Zone). Se a tarefa pede "Tirar foto", o bloco de input de mídia deve cobrir uma área central substancial da tela.
- **Micro-interações:** Ao concluir os inputs obrigatórios de um trecho da via, as opções de avanço se desabilitam suavemente. Feedback proeminente se faltar algo crítico (bordas/fontes mudando para o Warning State leve associado a segurança).

### 2.4 Resumo e Conclusão
**O que é:** A compilação pré-assinatura e visualização do relatório final.
- **Visão UX:** Apresenta um overview hierárquico, como uma fatura contábil ou uma ficha médica, separando os itens preenchidos.
- **Action:** Apenas nesta etapa exibimos um elemento gigante de CTA para "Assinar e Gerar PDF", invocando visualmente a irreversibilidade tátil do registro.

---

## 3. Diretrizes Futuras para o Engenheiro & QA
- **Engenheiro (@engineer):** Respeite o `Space Grotesk` e o tema escuro como modo *único* ou *padrão inegociável* (o app é focado em alta legibilidade sob o sol refletindo em pedra calcária/pão-de-açúcar, dark mode diminui stress ocular gravemente nesses ambientes). Para a geração dos formulários a partir do Protobuf, componha a UI de blocos modulares sólidos sem divs/linhas arbitrárias.
- **QA (@qa):** Testar em cenários de acessibilidade onde o target é tocado na beirada (dedos grossos). Nenhuma função principal deve residir nos cantos extremos (notch ou dead zones).  

> *Fim do Documento.*
> *Revisado por @ux para refletir o status perfeito dos mocks em "Technical Brutalism".*
