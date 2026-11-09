# Spec Delta

## MODIFIED Requirements

### Requirement: Versionamento Inteiro Sequencial e Migração em Cadeia de Protocolos
Todo protocolo YAML DEVE (MUST) declarar sua versão como um número inteiro sequencial positivo (`1`, `2`, `3`...), e o sistema DEVE (MUST) normalizar versões semver legadas (`"1.0.0"`, `"2.1.0"`) como versão `1`. Ao carregar um registro para edição ou duplicação cuja versão seja inferior à versão atual do protocolo correspondente (`versaoOrigem < versaoAlvo`), o sistema DEVE (MUST) executar em sequência todos os migradores intermediários (`v -> v + 1`) até atingir a versão mais nova do protocolo no aplicativo, atualizando o `idProtocolo`, `versaoProtocolo`, `yamlConteudo` e migrando as chaves de respostas e listas sem perda de dados. Caso a versão do registro seja superior à versão do protocolo suportada pelo aplicativo (`versaoOrigem > versaoAlvo`), o sistema DEVE (MUST) recusar a edição ou migração lançando um erro explícito que oriente o usuário a atualizar o aplicativo, mantendo liberada apenas a visualização do relatório `.epub` já gerado.

#### Scenario: Migração automática de relatório legado de manutenção ou versão anterior
- **WHEN** o usuário abre para continuar, editar ou duplicar um registro salvo em uma versão anterior (como `manutencao_ferragens` v1, `abertura_via_v1` v1, `inspecao_visual_v1` v1 ou `registro_expresso` v1)
- **THEN** o sistema executa a cadeia de migrações desde a versão original do registro até a versão inteira atual do protocolo, preservando todas as respostas, mídias e seleções de materiais já preenchidas no novo formato

#### Scenario: Recusa de edição quando o relatório pertence a uma versão mais nova que a do aplicativo
- **WHEN** o usuário tenta abrir para editar ou duplicar um registro cuja `versaoProtocolo` (`versaoOrigem`) é maior que a versão atual do protocolo empacotada no aplicativo (`versaoAlvo`)
- **THEN** o motor de migração recusa a operação lançando uma exceção clara informando que o relatório foi criado em uma versão mais recente e que é necessário atualizar o aplicativo
