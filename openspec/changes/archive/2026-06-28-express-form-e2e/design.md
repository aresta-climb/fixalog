## Context

O FixaLog precisa de um fluxo e2e (end-to-end) operante para mitigar riscos de integração entre a coleta de dados na interface, a persistência estruturada e a geração do relatório PDF assinado. Atualmente, temos o domínio de dados formalizado via Protobuf, mas não há um ciclo fechado operando sobre ele. O "Formulário Expresso" servirá como um "Tracer Bullet" ou "Walking Skeleton", provando que o core do sistema funciona na prática ao preencher as estruturas `AcaoManutencao` e `RegistroVia` dinamicamente com informações super simplificadas do usuário.

## Goals / Non-Goals

**Goals:**
- Implementar as interfaces `TermsOfUseScreen` (Onboarding) e `ExpressFormScreen` (Formulário).
- Criar o `AppConfigRecord` no Isar para persistir os Termos de Uso (versão).
- Integrar `geolocator` e `image_picker` e mapear os dados coletados na estrutura existente do Protobuf (`registro.proto`) sem precisar alterá-lo.

**Non-Goals:**
- Desenvolver os outros blocos avançados (lotes de material, avaliação final customizada) que faziam parte das propostas de formulário antigas.
- Sincronizar o relatório com algum backend remoto neste momento.

## Decisions

1. **Reaproveitamento da Estrutura Protobuf Atual:**
   Em vez de criar um modelo de dados provisório para este MVP, o formulário criará um `RegistroManutencao` oficial. Cada item (foto + descrição) será mapeado para um objeto `AcaoManutencao` cujo tipo seja `DetalheAcaoCustomizada`. As coordenadas automáticas de GPS serão injetadas em `RegistroVia`. Isso garante a compatibilidade e a prova de integração real.
   
2. **Gerenciamento de Estado da Permissão:**
   Checar permissões nativas ou exibir prompts a cada inicialização gera uma UI instável. Decidimos salvar um inteiro `acceptedTermsVersion` num novo schema do Isar (`AppConfigRecord`). Assim, caso os Termos mudem no futuro, basta incrementar a constante no app e a tela reaparecerá.

3. **Arquitetura da PDF Generation:**
   A criação do PDF vai ocorrer "sob demanda" (in-memory) lendo o `RegistroManutencao` e exibindo via pacote `printing` antes de salvar localmente.

## Risks / Trade-offs

- **Trade-off de Dados Restritos:** O uso exclusivo do `DetalheAcaoCustomizada` não cobre metadados técnicos dos protetores (liga, validade, etc.). *Mitigação*: Este é o comportamento intencional de um "Tracer Bullet". A estrutura de código estará validada para receber as telas complexas no futuro.
- **Risco com Permissões no Boot:** A recusa das permissões na tela de Termos impede o uso. *Mitigação*: Exigir que a `TermsOfUseScreen` eduque bem o usuário sobre o porquê de Câmera e GPS serem o coração funcional da auditoria antes de disparar o diálogo do Sistema Operacional.
