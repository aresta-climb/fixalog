# Spec Delta

## MODIFIED Requirements

### Requirement: Motor Universal de Interface (YAML)
O `WizardScreen` DEVE (MUST) ser capaz de renderizar e coordenar totalmente as etapas de captura, incluindo componentes nativos de mídia e localização ditados apenas pelo arquivo YAML fornecido, servindo como única tela para qualquer formulário no app, encerrando o último passo diretamente na confirmação de geração sem exigir coleta de assinatura manuscrita em tela e exibindo no botão `"GERAR RELATÓRIO"` um ícone semântico de documento/relatório (`Icons.description_outlined`) em vez de um ícone restrito a PDF (`Icons.picture_as_pdf`).

#### Scenario: Integração de Recursos Nativos
- **WHEN** um `StepCampoSimples` for do tipo `IMAGE`, `VIDEO` ou `GPS`
- **THEN** a interface deve invocar respectivamente a Câmera/Galeria nativa e o serviço de Localização, salvando a saída física no `SessionBundleManager`

#### Scenario: Coleta de Assinatura Digital sem Crash
- **WHEN** o usuário preenche os campos obrigatórios do último passo do protocolo e aciona o botão de conclusão do passo
- **THEN** o Wizard avança diretamente para o card de conclusão do protocolo para geração e assinatura digital criptográfica do relatório, sem exibir modal de assinatura manuscrita em tela

#### Scenario: Ícone de relatório no botão de conclusão
- **WHEN** o card de conclusão (`PROTOCOLO CONCLUÍDO`) é exibido ao final do Wizard
- **THEN** o botão `"GERAR RELATÓRIO"` exibe o ícone de documento/relatório (`Icons.description_outlined`) e não exibe o ícone legado `Icons.picture_as_pdf`

### Requirement: Isolamento de Estado para Wizards Encadeados
O motor do Wizard DEVE (MUST) isolar o estado de cada sessão em execução como uma instância independente, tanto quando uma tela `WizardScreen` é aberta de forma empilhada sobre outra tela `WizardScreen` em andamento quanto quando o usuário abre ou edita um relatório antigo no Histórico, sai e em seguida inicia um novo relatório, garantindo que os campos de entrada do novo relatório nunca venham pré-preenchidos com dados da sessão anterior.

#### Scenario: Abrir cadastro de material durante uma manutenção
- **WHEN** o usuário está preenchendo um protocolo de manutenção e aciona a opção de cadastrar um novo material na hora
- **THEN** uma nova instância isolada do `WizardScreen` é aberta para o cadastro do material mantendo o estado da manutenção intacto em segundo plano
- **THEN** ao concluir e gerar o relatório assinado digitalmente do novo material, a tela retorna à manutenção com os dados anteriores preservados e o novo material disponível e selecionado

#### Scenario: Iniciar novo relatório após abrir ou editar relatório antigo no Histórico
- **WHEN** o usuário abre ou edita um relatório antigo pelo Histórico, sai do `WizardScreen` e em seguida inicia um novo relatório
- **THEN** o novo relatório é inicializado com uma nova sessão limpa e todos os campos de texto, número e seleção aparecem vazios (exceto campos configurados com preenchimento automático da data atual), sem reter textos ou respostas do relatório antigo
