# Prompt Consolidado para o Google Stitch

## Objetivo
Este documento contém o prompt longo e detalhado para ser repassado ao Google Stitch (StitchMCP) ou outra ferramenta de geração de UI por IA, para a criação do mock completo do aplicativo FixaLog de uma só vez, baseando-se no `design_inicial.md`, `especificacao_tecnica.md` e na direção de arte estabelecida em `design_ui.md`.

---

## O Prompt

Copie e cole o texto abaixo em inglês (já otimizado para o modelo de geração) no Google Stitch para iniciar a geração do aplicativo:

```text
Design a complete mobile application called "FixaLog" with 4 primary screens, presented as a cohesive flow.

**App Context & Purpose:**
FixaLog is a specialized, rugged utility app for rock climbing route maintenance and technical auditing (e.g., rebolting, visual inspections, anchor replacements). It operates in absolute offline environments at the base of climbing routes. It features a dynamic guided form engine to standardize data collection (media, text, GPS) and generates cryptographically self-signed PDF technical reports. It is used outdoors in harsh sunlight, often by users wearing gloves or with climbing chalk/magnesium on their hands.

**Design System & Aesthetics (Technical Brutalism):**
- **Mode:** Strict Dark Mode always active to avoid blinding the user in sunlight.
- **Typography:** Use "Space Grotesk" for large, industrial, metric-looking headings. Use "Inter" for body text to ensure extreme legibility.
- **Colors:** Surface backgrounds must be Graphite Black (e.g., #121416). Use highly-visible "Rescue Orange" (e.g., #FF6B00) for primary actions, CTA buttons, and key accents. Use dark bluish-grey for secondary contrast.
- **Shapes & Layout:** Utilitarian, flat design with slightly rounded corners. AVOID traditional Material Design drop shadows, thin lines, and exaggerated border radii. Rely on contrasting background colors of containers rather than dividing lines.
- **Usability:** Massive touch targets (hit areas) and very generous paddings everywhere to accommodate clumsy hands and bad conditions.

**Please generate the following 4 screens side-by-side or as a flow:**

1. **Onboarding / Setup (Identidade Técnica):**
   A dark mode setup screen representing the user's first access to generate their local cryptographic identity. 
   - Top: Large industrial heading: "Identidade Técnica".
   - Middle: Huge, easily tappable text input fields for "Nome Completo" and an optional field "Clube / Associação de Escalada". Below them, a muted text section explaining the terms of agreement for cryptographic signature creation on the device.
   - Bottom anchored: A full-width, massive, bright Rescue Orange primary action button saying "Gerar Chaves e Entrar".

2. **Dashboard (Offline Home & History):**
   The main brutalist hub screen when opening the app offline.
   - Top header: Shows an "Offline Sync" badge icon and a greeting with the user's name.
   - Top Section: A highlighted area with massive, tapable cards to start a new workflow. Title: "Nova Manutenção". Include two prominent sub-option cards: "Rebolting Completo" and "Inspeção Rápida".
   - Bottom Section: A vertical list titled "Histórico Seguro" displaying past generated technical reports. Each list item should show a timestamp, the route name, and a PDF icon. Use Rescue Orange for subtle accents against the graphite background.

3. **Guided Form Step Wizard (The "Thermomix" UI):**
   The core workspace where data is collected. It focuses strictly on ONE question per screen to reduce mental fatigue.
   - Top: A progress indicator labeled "Passo 3 de 15".
   - Middle: A very large, highly readable question heading: "Qual tipo de Chapeleta instalada?". Below it, a vertical layout of massive, easily-tappable radio-button-style container cards for the options (e.g., "Aço Inox 304", "Titânio", "Aço Carbono"). Below the options, a big rectangular placeholder box/button with a camera icon labeled "Capturar Foto do Grampo".
   - Bottom anchored navigation: A "Voltar" (Back) text link on the left, and a gigantic Rescue Orange "Confirmar e Avançar" (Confirm & Next) button on the right.

4. **Final Audit & Visual Signature:**
   The final review screen before generating the immutable PDF report.
   - Top to Middle: A dense but legible technical data table layout summarizing the user's form answers (read-only view).
   - Lower Middle: A dedicated, large rectangular area with a striking pure white background acting as a finger signature canvas pad. Title it "Sua Assinatura e Concordância" in dark text. The stark white box must stand out heavily against the dark mode app.
   - Bottom anchored: A full-width, massive primary action button in Rescue Orange saying "Assinar e Forjar Segurança".
```
