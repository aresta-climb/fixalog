## Context

O FixLog é um aplicativo de vistoria e auditoria técnica de proteções fixas em vias de escalada. Para respaldar legalmente os mantenedores, conquistadores e a comunidade de escalada, o aplicativo necessita de termos de uso claros que abordem:
1. Isenção de responsabilidade civil e assunção de risco inerente à escalada.
2. Uso legítimo e finalidade da coleta de evidências fotográficas e coordenadas GPS.
3. Propriedade intelectual e distribuição dos laudos gerados sob licença aberta.

Atualmente, a tela de onboarding possui apenas um texto breve sobre permissões. No ecossistema Aresta Climb (`aresta_app`), existe uma esteira madura que mantém os termos como documentos Markdown centralizados em um repositório git (`arestaclimb.com`), com automação de versionamento baseada em hashes SHA-256 e sincronização contínua via CI/CD.

Este documento de design consolida as diretrizes da **Equipe Autônoma de Desenvolvimento (AGENT.md)** e os mandamentos inegociáveis do **PRINCIPIOS.md**:
- **@pm**: Especificação funcional robusta, desacoplada e com rastreabilidade jurídica.
- **@ux**: Interface acessível para uso em campo (rocha/falésia), alto contraste, tipografia Space Grotesk / Inter e botões grandes (56px) para operação com luvas.
- **@engineer**: Código limpo, DRY, library-first, estritamente em português brasileiro e localizado em `app/` e `ferramentas/`.
- **@qa**: Imperativo de testes de integração prévios, TDD estrito e 100% de cobertura de código sem promessas não tratadas.

## Goals / Non-Goals

**Goals:**
- Conectar o repositório central de documentação jurídica via submódulo Git em `legal/repo`.
- Criar e versionar os arquivos dedicados do FixLog: `termos-de-uso-fixlog.md` e `politica-de-privacidade-fixlog.md`.
- Construir a biblioteca independente `ferramentas/atualizador_legal` (Library-First) em Dart puro com testes unitários autônomos para checagem de SHA-256 e geração de `app/lib/core/constantes/versao_legal.g.dart`.
- Adicionar o workflow do GitHub Actions (`.github/workflows/atualizar_termos_legais.yml`) para auto-update dos termos.
- Implementar primeiro o teste de integração (`app/integration_test/fluxo_termos_de_uso_test.dart`) cobrindo o fluxo ponta a ponta.
- Refatorar a interface (`TelaTermosDeUso`) com renderização rica em Markdown, modal deslizante de privacidade, checkbox de concordância e botão de 56px de altura.
- Persistir no Isar (`AppConfigRecord`) a versão aceita e o timestamp exato do aceite para fins de auditoria.
- Garantir 100% de cobertura de testes unitários (`flutter test --coverage`).

**Non-Goals:**
- Não inclui o setup de telemetria ou Firebase nesta etapa (pertence à Etapa 2).
- Não inclui a aba completa de Configurações nesta etapa (pertence à Etapa 3).
- Não altera o core criptográfico em Rust nem o schema de geração de relatórios PDF.

## Decisions

### Decisão 1: Princípio do Português Obrigatório em Toda a Camada
- **Diretriz**: Conforme Princípio I do `PRINCIPIOS.md`, todos os nomes de classes, métodos, constantes e variáveis serão em português brasileiro.
- **Definições**:
  - `kVersaoLegal`: inteiro com a versão corrente dos termos.
  - `kDataUltimaAtualizacaoLegal`: string ISO da data do último hash alterado.
  - `kHashesLegais`: mapa com o SHA-256 de cada documento.
  - `AtualizadorVersaoLegal`: classe responsável por ler e atualizar os hashes.
  - `ServicoTermosLegais`: classe de serviço no app para carregar e validar termos.
  - `TelaTermosDeUso`: widget principal de apresentação.
  - Campos do Isar: `versaoTermosAceita` e `dataHoraAceiteTermos`.

### Decisão 2: Arquitetura Library-First para o Atualizador Legal
- **Abordagem**: O atualizador de termos não será um script solto, mas sim um pacote Dart independente localizado em `ferramentas/atualizador_legal/`, com seu próprio `pubspec.yaml`, dependência isolada de `crypto` e suíte de testes unitários próprios em `ferramentas/atualizador_legal/test/`.
- **Justificativa**: Respeita o Princípio II (`Library-First`). Pode ser executado via `dart run` tanto localmente quanto no CI, e testado de forma completamente autônoma sem carregar o framework do Flutter.

### Decisão 3: Testes de Integração em Primeiro Lugar (@qa & Princípio V)
- **Abordagem**: Antes de aprofundar os testes unitários da UI, será estabelecido o teste de integração de fronteira (`app/integration_test/fluxo_termos_de_uso_test.dart`).
- **Escopo**:
  1. Inicializa o Isar limpo em memória temporária.
  2. Verifica que o app detecta a pendência de termos e renderiza a tela.
  3. Verifica que o botão de avançar fica desabilitado até a marcação do checkbox.
  4. Simula o clique no botão de aceite.
  5. Valida que o Isar persistiu `versaoTermosAceita == kVersaoLegal` e `dataHoraAceiteTermos != null`.
  6. Valida que uma reinicialização subsequente pula a tela de termos diretamente para o fluxo principal.

### Decisão 4: UX Otimizada para Campo e Escalada (@ux)
- **Paleta e Contraste**: Fundo Basalto (`#121416`), Superfície Elevada (`#1A1C1E`) e Destaque Laranja Resgate (`#FFFF6B00`), garantindo legibilidade sob sol forte em setores de rocha.
- **Ergonomia Física**: Botão principal com altura mínima de 56px e cantos arredondados (12px), projetado para toques precisos mesmo com dedos calejados ou mãos enluvadas.
- **Hierarquia Visual**:
  - Títulos em `SpaceGrotesk` em negrito.
  - Corpo de texto legível em `Inter` (16px, espaçamento entre linhas 1.6).
  - Modal inferior (BottomSheet) seguro e rolável para leitura integral da Política de Privacidade sem perder o estado da tela pai.

### Decisão 5: Resiliência Offline e Fallback (@qa)
- **Abordagem**: Os arquivos Markdown são declarados em `assets` no `app/pubspec.yaml` e empacotados diretamente no binário do aplicativo.
- **Garantia**: O aplicativo nunca depende de conexão com a internet para exibir os termos de uso. Caso ocorra erro inesperado de leitura de asset, o `ServicoTermosLegais` trata a exceção graciosamente, apresentando mensagem amigável e registrando o log de diagnóstico sem travar o aplicativo.

## Risks / Trade-offs

- **[Risco] Submódulo não inicializado em ambiente de build/CI** → *Mitigação*: Configuração de `submodules: 'recursive'` nos fluxos do GitHub Actions e teste unitário que valida a existência dos assets de fallback.
- **[Risco] Regressão na cobertura de 100% exigida** → *Mitigação*: Configuração do script de verificação de cobertura no pipeline de commit, impedindo aprovação caso haja qualquer linha ou branch não coberta.
- **[Risco] Migração de dados no Isar em dispositivos com versões antigas instaladas** → *Mitigação*: A adição dos campos `versaoTermosAceita` e `dataHoraAceiteTermos` no Isar é cumulativa e aceita valores nulos, migrando os registros de forma não-destrutiva.
