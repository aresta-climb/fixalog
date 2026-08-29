## ADDED Requirements

### Requirement: Arquitetura Protobuf Híbrida
O sistema DEVE utilizar um schema Protobuf genérico (`Registro`) capaz de armazenar meta-dados estritos de sessão e um payload dicionário de tipagem dinâmica.

#### Scenario: Serialização de Respostas
- **WHEN** o motor finalizar a sessão com um dicionário de respostas
- **THEN** o sistema empacota o dicionário no campo genérico `map<string, Resposta>` do Protobuf
- **THEN** o sistema assina o arquivo binário garantindo integridade

### Requirement: Motor Universal de Interface (YAML)
O `WizardScreen` DEVE ser capaz de renderizar e coordenar totalmente as etapas de captura, incluindo componentes nativos de mídia, ditados apenas pelo arquivo YAML fornecido, servindo como única tela para qualquer formulário no app.

#### Scenario: Integração de Recursos Nativos
- **WHEN** um `StepCampoSimples` for do tipo `IMAGE`, `GPS` ou `SIGNATURE`
- **THEN** a UI deve invocar respectivamente a Câmera nativa, o serviço de Localização, e o Canvas de Assinatura, ao invés de usar mocks, salvando a saída física no `SessionBundleManager`.

### Requirement: Pipeline de Persistência Unificado
Ao finalizar a última tela do Wizard, o motor DEVE converter o estado transiente num `Registro` final e integrá-lo a toda a cadeia de persistência local.

#### Scenario: Geração Final
- **WHEN** o usuário clica em "GERAR RELATÓRIO" no final do Wizard
- **THEN** as mídias são hasheadas (SHA-256) e movidas para o SessionBundle
- **THEN** o manifesto `.binarypb` é gerado
- **THEN** um registro é adicionado no banco Isar para o Histórico
- **THEN** a task de geração do PDF Rust/Typst é disparada com o diálogo de progresso
