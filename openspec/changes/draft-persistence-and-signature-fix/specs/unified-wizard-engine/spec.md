## MODIFIED Requirements

### Requirement: Motor Universal de Interface (YAML)
O `WizardScreen` DEVE ser capaz de renderizar e coordenar totalmente as etapas de captura, incluindo componentes nativos de mídia, ditados apenas pelo arquivo YAML fornecido, servindo como única tela para qualquer formulário no app. O modal de captura de assinatura (`SIGNATURE`) DEVE utilizar restrições explícitas de layout para evitar render boxes sem dimensões calculadas.

#### Scenario: Integração de Recursos Nativos
- **QUANDO** um `StepCampoSimples` for do tipo `IMAGE`, `GPS` ou `SIGNATURE`
- **ENTÃO** a interface deve invocar respectivamente a Câmera nativa, o serviço de Localização, e o Canvas de Assinatura, ao invés de usar mocks, salvando a saída física no `SessionBundleManager`

#### Scenario: Coleta de Assinatura Digital sem Crash
- **QUANDO** o usuário toca no campo de assinatura digital do mantenedor
- **ENTÃO** o `SignatureModal` é exibido com dimensões finitas delimitadas via `LayoutBuilder`
- **ENTÃO** o usuário consegue assinar livremente no canvas sem disparar exceção de hit test

### Requirement: Pipeline de Persistência Unificado
O motor do Wizard DEVE persistir continuamente as alterações no manifesto Protobuf (`registro.binarypb`) e no banco local `Isar` (`SubmissionRecord`) durante todo o ciclo de preenchimento, garantindo que nenhum progresso seja perdido caso o usuário saia da tela ou feche o app. Ao finalizar a última tela do Wizard, o motor consolida o registro para a geração do PDF.

#### Scenario: Auto-Save Reativo durante o Preenchimento
- **QUANDO** o usuário altera uma resposta de texto, captura uma mídia, seleciona um ramo ou adiciona um item de lista no Wizard
- **ENTÃO** o `WizardStateController` serializa o estado para `registro.binarypb` no Session Bundle
- **ENTÃO** o registro correspondente no banco Isar é criado ou atualizado com status `EM_PROGRESSO`

#### Scenario: Flush ao Fechar a Tela
- **QUANDO** o usuário sai do `WizardScreen` antes de concluir a geração
- **ENTÃO** qualquer estado pendente é persistido em disco e no Isar
- **ENTÃO** a sessão fica disponível no Histórico com status `EM_PROGRESSO`

#### Scenario: Geração Final
- **QUANDO** o usuário clica em "GERAR RELATÓRIO" no final do Wizard
- **ENTÃO** as mídias são hasheadas (SHA-256) e movidas para o SessionBundle
- **ENTÃO** o manifesto `.binarypb` é gerado
- **ENTÃO** o registro no banco Isar é atualizado para o status `GERADO` após a conclusão do PDF
- **ENTÃO** a task de geração do PDF Rust/Typst é disparada com o diálogo de progresso
