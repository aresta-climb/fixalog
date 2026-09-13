## Why

Atualmente, a tela de termos de uso do FixLog exibe apenas um texto básico sobre permissões de Câmera e GPS, sem disponibilizar os textos jurídicos completos de Termos de Uso e Política de Privacidade da plataforma. Como o FixLog lida com auditoria técnica, responsabilidade civil de manutenção de vias de escalada, laudos periciais, fotos e coordenadas geográficas, é fundamental estabelecer conformidade jurídica rigorosa, transparência sobre a coleta de dados e uma esteira automatizada para versionamento e atualização desses documentos com base no repositório central do ecossistema Aresta Climb.

Esta proposta formaliza a especificação técnica elaborada pelo Gerente de Produto (@pm) em conjunto com o Designer UX/UI (@ux), o Engenheiro Full-Stack (@engineer) e o Engenheiro de QA (@qa), seguindo estritamente os princípios inegociáveis de engenharia estabelecidos no `PRINCIPIOS.md`.

## What Changes

- **Integração de Submódulo Git**: Conecta o submódulo Git `legal/repo` apontando para o repositório central de documentos legais (`arestaclimb.com`).
- **Documentos Jurídicos Dedicados ao FixLog**: Criação de `termos-de-uso-fixlog.md` e `politica-de-privacidade-fixlog.md` no diretório `public/docs/` do repositório legal.
- **Biblioteca Isolada de Versionamento (Library-First)**: Implementação do pacote autônomo em `ferramentas/atualizador_legal/` com utilitário CLI em Dart puro para calcular hashes SHA-256 e gerar `app/lib/core/constantes/versao_legal.g.dart` com identificadores estritamente em português (`kVersaoLegal`, `kDataUltimaAtualizacaoLegal`, `kHashesLegais`).
- **Automação de CI/CD**: Adição do workflow `.github/workflows/atualizar_termos_legais.yml` para sincronização, verificação e atualização automática dos termos via GitHub Actions.
- **Testes de Integração em Primeiro Lugar**: Criação de teste de integração end-to-end simulando o ciclo de vida completo: abertura do banco Isar, detecção de termos pendentes, renderização da tela, aceite e persistência.
- **Interface e Acessibilidade (@ux)**: Refatoração da tela `TelaTermosDeUso` com renderização rica em Markdown via `flutter_markdown_plus`, paleta de alto contraste para ambiente externo (Laranja Resgate `#FFFF6B00` e Fundo Basalto `#121416`), botões com área de toque de 56px (compatível com mãos enluvadas), modal deslizante para Política de Privacidade e checkbox explícito de concordância.
- **Auditoria Transacional no Isar**: Atualização da entidade `RegistroConfiguracaoApp` (`AppConfigRecord`) para registrar a versão aceita (`versaoTermosAceita`) e o timestamp exato do aceite (`dataHoraAceiteTermos`).
- **Garantia de Qualidade e TDD (@qa)**: Ciclo estrito Vermelho-Verde-Refatorar com 100% de cobertura de testes unitários e de integração antes de qualquer liberação de código em produção.

## Capabilities

### New Capabilities
- `governanca-termos-legais`: Pipeline automatizado de sincronização, cálculo criptográfico de SHA-256 e versionamento estático de documentos legais via submódulo Git, CLI em Dart e CI/CD.

### Modified Capabilities
- `onboarding-terms`: Expande os requisitos da tela de consentimento para exigir renderização em Markdown dos documentos dedicados (`termos-de-uso-fixlog.md`), modal deslizante para Política de Privacidade, checkbox explícito de aceite e persistência da versão e do timestamp no Isar.

## Impact

- **Código do Aplicativo**:
  - Refatoração de `app/lib/features/onboarding/views/terms_of_use_screen.dart` para `TelaTermosDeUso`.
  - Criação da biblioteca `app/lib/core/servicos/servico_termos_legais.dart`.
  - Geração de `app/lib/core/constantes/versao_legal.g.dart`.
  - Atualização do modelo `app/lib/core/models/local/app_config_record.dart` e regeneração com `build_runner`.
- **Dependências**: Adição de `flutter_markdown_plus` em `app/pubspec.yaml`.
- **Ferramental**: Novo pacote independente `ferramentas/atualizador_legal/`.
- **CI/CD**: Novo workflow `.github/workflows/atualizar_termos_legais.yml`.
- **Testes**: Novos testes de integração em `app/integration_test/` e testes unitários em `app/test/` e `ferramentas/atualizador_legal/test/` garantindo 100% de cobertura.
