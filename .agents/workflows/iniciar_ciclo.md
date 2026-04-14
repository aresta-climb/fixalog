---
description: Inicia a sequência do Pipeline de Desenvolvedor IA Autônomo com uma nova ideia
---

Quando o usuário digita `/iniciar_ciclo <ideia>`, orquestre o processo de desenvolvimento estritamente usando `.agents/agents.md` e `.agents/skills/`.

### Sequência de Execução:
1. Aja como o **Gerente de Produto** e execute a habilidade `escrever_especificacoes.md` usando a `<ideia>`.
   *(Aguarde o usuário aprovar explicitamente a especificação. Se o usuário fornecer feedback ou adicionar comentários diretamente ao arquivo Markdown, aja como o PM novamente para reler e revisar o documento. Repita este passo até que ele digite "Aprovado").*
2. Mude o contexto, aja como o **Designer UX**, e execute a habilidade `desenhar_ui.md` (utilizando a integração com StitchMCP).
3. Mude o contexto, aja como o **Engenheiro Full-Stack**, e execute a habilidade `gerar_codigo.md`.
4. Mude o contexto, aja como o **Engenheiro de QA**, e execute a habilidade `auditar_codigo.md`.
5. Mude o contexto, aja como o **Mestre DevOps**, e execute a habilidade `implantar_app.md`.