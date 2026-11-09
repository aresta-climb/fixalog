# Design: Motor de Testes do Robô Caótico e Regressão de UI

## Context

O assistente de catalogação pericial do Fixalog (`WizardScreen`) gerencia estados complexos com validação contínua de formulários em 5 protocolos YAML e 7 idiomas, persistência reativa no `BancoDadosLocal` (SQLite), seleção de catálogo de materiais (`StepRefMateriais`), anexos multimídia e geração de pacotes EPUB 3 assinados. O ecossistema Aresta possui um motor comprovado de testes caóticos com *shrinking* determinístico (`ddmin`). Veja a motivação completa em `proposal.md`.

## Goals / Non-Goals

**Goals:**
- Implementar um motor de macaco caótico (*Monkey Testing*) em Dart puro sobre a API do `WidgetTester`, exercitando os 5 protocolos YAML e os 7 idiomas suportados.
- Utilizar exclusivamente instâncias reais do `BancoDadosLocal.abrirEmMemoria()` (SQLite `:memory:`) e os Fakes determinísticos de `app/test/fakes/` e `app/test/core/services/*_fake.dart` (Princípio V do `AGENTS.md`).
- Garantir capacidade de encolhimento automático de passos via busca binária (*Delta Debugging* / `ddmin`).
- Integrar com o pipeline de CI rodando todas as receitas de regressão existentes em tempo recorde (< 1s por receita).
- Anexar a receita encolhida do robô caótico ao `RegistroLogger` (`receita_robo_caotico`) em caso de falhas durante campanhas exploratórias.

**Non-Goals:**
- Substituir testes unitários e de widget orientados a comportamento (o robô caótico complementa a suíte espelhada 1:1, descobrindo estados de borda imprevisíveis).
- Executar campanhas aleatórias longas de minutos em todo commit local (o `flutter test` padrão roda instantaneamente as receitas de regressão consolidadas e os testes unitários do motor; campanhas longas são ativadas por `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS`).

## Decisions

### 1. Ambiente Determinístico com `BancoDadosLocal.abrirEmMemoria()` e Fakes Reais
- **Decisão**: Configurar o `MotorRoboCaotico` para inicializar a árvore de widgets com `ProviderScope` injetando `BancoDadosLocal.abrirEmMemoria()`, `ServicoGaleriaDispositivoFake`, `VideoTranscoderServiceFake`, `CryptoServiceFake`, `SincronizadorNuvemServiceFake`, `AutenticacaoNuvemServiceFake` e `RegistroLoggerFake`.
- **Por que**: Permite que o robô clique livremente em botões de câmera, galeria, corte de vídeo, seleção de materiais (`StepRefMateriais`) e finalização de protocolo sem travar em diálogos nativos do sistema operacional e sem usar `mocktail`/`mockito`.

### 2. Cobertura Multi-Protocolo e Multilíngue (7 Idiomas + Detox de Textos)
- **Decisão**: A `FabricaDatasetCaos` sorteia (a partir da `seed`) tanto o protocolo YAML (`bolt_maintenance`, `route_opening`, `visual_inspection`, `material_registration`, `incident_report`) quanto o `Locale` (`pt`, `en`, `es`, `fr`, `de`, `ar`, `ja`) e popula campos de texto com entradas extremas (strings vazias, textos gigantes, emojis, caracteres RTL/CJK e caracteres especiais YAML/XML).
- **Por que**: Garante que a combinação de layouts (como RTL em árabe ou textos longos em alemão) com árvores dinâmicas do `WizardScreen` nunca provoque `RenderFlex overflow` ou corrupção na serialização `registro.yaml` / EPUB 3.

### 3. Algoritmo Delta Debugging (`ddmin`) em `EncolhedorCaminhoCrash`
- **Decisão**: Implementar a classe `EncolhedorCaminhoCrash` que particiona a lista de passos (`List<PassoRobo>`) em blocos e testa subconjuntos através de um callback assíncrono de reprodução até encontrar o ponto fixo 1-minimal onde a remoção de qualquer passo individual faz a falha desaparecer.
- **Por que**: Sequências caóticas de 80 ou 100 passos são difíceis de diagnosticar manualmente; a receita reduzida para 3 a 5 passos isola a causa raiz imediatamente e executa em milissegundos no CI.

### 4. Execução Rápida por Padrão no `flutter test` e Campanhas Sob Demanda
- **Decisão**: O arquivo `robo_caotico_exploratorio_test.dart` lê `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS` (padrão `0`, executando apenas 1 rodada curta de fumaça determinística para manter cobertura e velocidade, ou `N` segundos em campanhas de fuzzing). Já o `regressao_caminhos_test.dart` reexecuta todas as receitas `.json` de `app/test/caos/caminhos_regressao/` em toda execução da suíte.
- **Por que**: Preserva a rapidez da suíte de testes no desenvolvimento diário enquanto garante proteção contínua contra regressões.

## Risks / Trade-offs

- [Testes de renderização lentos em animações] → O robô utiliza passos curtos com `tester.pump(Duration(milliseconds: 50))` em vez de `pumpAndSettle` infinito quando há indicadores de progresso indeterminados.
- [Fragilidade de seletores em mudanças de tradução] → O modelo `SeletorAlvoRobo` prioriza chaves semânticas (`Key`) e tipo/índice do widget antes de recorrer ao rótulo textual.
