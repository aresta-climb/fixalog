## 1. Submódulo e Documentos Jurídicos

- [x] 1.1 Configurar o submódulo Git `legal/repo` apontando para o repositório central de documentos legais e criar os arquivos `public/docs/termos-de-uso-fixlog.md` e `public/docs/politica-de-privacidade-fixlog.md`
- [x] 1.2 Declarar os novos documentos Markdown na seção `assets` do `app/pubspec.yaml`
- [x] 1.3 Adicionar a dependência `flutter_markdown_plus` no `app/pubspec.yaml`

## 2. Biblioteca de Versionamento Legal (ferramentas/atualizador_legal - Library-First)

- [x] 2.1 Criar a estrutura do pacote autônomo `ferramentas/atualizador_legal/` com `pubspec.yaml` e dependência isolada de `crypto`
- [x] 2.2 [TDD - Red] Escrever a suíte de testes unitários em `ferramentas/atualizador_legal/test/atualizador_versao_legal_test.dart` cobrindo cálculo de SHA-256, incremento de versão e geração de constantes
- [x] 2.3 [TDD - Green] Implementar a classe `AtualizadorVersaoLegal` em `ferramentas/atualizador_legal/lib/atualizador_versao_legal.dart` e o executável em `bin/atualizar_versao_legal.dart`
- [x] 2.4 Executar o utilitário CLI e gerar o arquivo de constantes estritamente em português em `app/lib/core/constantes/versao_legal.g.dart` com `kVersaoLegal`, `kDataUltimaAtualizacaoLegal` e `kHashesLegais`
- [x] 2.5 Verificar 100% de cobertura de testes na biblioteca `ferramentas/atualizador_legal/`

## 3. Automação CI/CD no GitHub Actions

- [x] 3.1 Criar o workflow `.github/workflows/atualizar_termos_legais.yml` para sincronização do submódulo e execução automatizada do atualizador legal no GitHub Actions

## 4. Testes de Integração em Primeiro Lugar (@qa & Princípio V)

- [x] 4.1 Escrever o teste de integração de fronteira em `app/integration_test/fluxo_termos_de_uso_test.dart` cobrindo o ciclo completo: checagem no Isar, renderização inicial, bloqueio sem checkbox, aceite e redirecionamento

## 5. Persistência de Auditoria no Isar (AppConfigRecord)

- [x] 5.1 Adicionar os campos `versaoTermosAceita` e `dataHoraAceiteTermos` na entidade `AppConfigRecord` em `app/lib/core/models/local/app_config_record.dart`
- [x] 5.2 Executar o `build_runner` no `app` para atualizar o schema gerado `app_config_record.g.dart`
- [x] 5.3 [TDD] Escrever testes unitários em `app/test/core/models/local/app_config_record_test.dart` validando a gravação e conferência de versão e timestamp no Isar

## 6. Interface de Consentimento dos Termos de Uso (@ux & @engineer)

- [x] 6.1 [TDD - Red] Escrever testes de widget em `app/test/features/onboarding/views/tela_termos_de_uso_test.dart` cobrindo botão desabilitado sem checkbox, toque no link de privacidade e clique de aceite
- [x] 6.2 [TDD - Green] Refatorar a tela para `TelaTermosDeUso` em `app/lib/features/onboarding/views/tela_termos_de_uso.dart` com renderização rica em Markdown, botão ergonômico de 56px de altura, paleta de alto contraste (#121416 e #FFFF6B00) e modal deslizante (BottomSheet) de privacidade
- [x] 6.3 Atualizar o roteador inicial em `app/lib/main.dart` para comparar a versão persistida contra `kVersaoLegal`
- [x] 6.4 Garantir 100% de cobertura de testes unitários nos widgets e modelos de onboarding

## 7. Auditoria de Qualidade Final (@qa)

- [x] 7.1 Executar a suíte de testes de integração (`flutter test integration_test/fluxo_termos_de_uso_test.dart`)
- [x] 7.2 Executar a suíte completa de testes unitários (`flutter test --coverage`) e verificar conformidade estrita com 100% de cobertura
- [x] 7.3 Executar análise estática de código (`flutter analyze`) para garantir zero warnings
- [ ] 7.4 Pausar para revisão e aprovação explícita do usuário (@pm constraint)
