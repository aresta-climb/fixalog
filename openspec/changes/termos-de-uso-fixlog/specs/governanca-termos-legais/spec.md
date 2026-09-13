## ADDED Requirements

### Requirement: Atualização Automática de Versão Legal via CLI
O sistema DEVE (MUST) prover uma biblioteca independente de linha de comando (`ferramentas/atualizador_legal`) para analisar os hashes criptográficos SHA-256 dos documentos de termos do FixLog e gerar o arquivo de constantes de versão `app/lib/core/constantes/versao_legal.g.dart`.

#### Scenario: Detecção de alterações nos documentos Markdown
- **WHEN** o utilitário CLI é executado e o hash SHA-256 de `termos-de-uso-fixlog.md` ou de `politica-de-privacidade-fixlog.md` difere dos hashes gravados no arquivo gerado
- **THEN** o utilitário incrementa a constante inteira `kVersaoLegal`
- **THEN** o utilitário atualiza a data `kDataUltimaAtualizacaoLegal` para a data corrente
- **THEN** o utilitário grava o novo mapa `kHashesLegais` com os respectivos hashes SHA-256 no arquivo de saída

#### Scenario: Execução sem alterações nos documentos
- **WHEN** o utilitário CLI é executado e os hashes calculados são idênticos aos gravados no arquivo gerado
- **THEN** o utilitário mantém o arquivo inalterado e encerra com código de sucesso

### Requirement: Workflow de Sincronização Contínua em CI/CD
O repositório DEVE (MUST) conter uma automação no GitHub Actions (`.github/workflows/atualizar_termos_legais.yml`) para atualizar o submódulo de termos e disparar a atualização de versão legal.

#### Scenario: Disparo do workflow de atualização
- **WHEN** o evento de `repository_dispatch` (tipo `update-legal-terms`) ou disparo manual (`workflow_dispatch`) é recebido
- **THEN** o workflow atualiza o submódulo git `legal/repo`
- **THEN** o workflow executa a biblioteca CLI `ferramentas/atualizador_legal`
- **THEN** o workflow comita e envia as alterações geradas caso haja modificações
