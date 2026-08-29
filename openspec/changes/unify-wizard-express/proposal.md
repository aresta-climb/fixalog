## Why

Atualmente temos duas fontes de verdade e dois motores de UI para formulários: o Registro Expresso (implementação fixa em código) e o Relatório de Manutenção de Via (motor dinâmico Wizard baseado em YAML). Essa divisão gera duplicação de esforço, onde apenas o Expresso possui a infraestrutura completa conectada (captura real, salvamento e PDF), enquanto o Wizard apenas salva dados em memória. A unificação resolve isso, transformando o Wizard no motor único capaz de interpretar qualquer YAML, reduzindo a complexidade de manutenção e permitindo a criação de novos protocolos de forma 100% declarativa, escalando infinitamente sem necessidade de mudar o modelo de dados ou a UI.

## What Changes

- **Unificação da UI**: O `WizardScreen` passa a ser a única engine de formulários do aplicativo.
- **Deleção de Código**: Remoção completa do `ExpressFormScreen` e `ExpressFormViewModel`.
- **Registro Expresso como Configuração**: O "Registro Expresso" será recriado inteiramente como um arquivo declarativo `registro_expresso.yaml`.
- **Protobuf Híbrido (BREAKING)**: Refatoração do `registro.proto` (`RegistroManutencao` vira `Registro`) para adotar um modelo híbrido: mantém-se o envelope estrito de segurança (metadados, assinaturas, hashes de mídia) e adota-se um payload genérico e tipado (`map<string, Resposta>`) para guardar os dados coletados de forma flexível a partir de qualquer YAML.
- **Integração Real (Fim dos Mocks)**: O `WizardScreen` será conectado aos pacotes nativos para Câmera, GPS e Assinatura.
- **Persistência Unificada**: O `WizardState` ao finalizar, gravará a sessão no `SessionBundleManager` e no Isar, acionando a geração do PDF, assim como o Registro Expresso fazia.

## Capabilities

### New Capabilities
- `unified-wizard-engine`: O motor central unificado de formulários capaz de mapear diretamente as respostas do YAML num modelo genérico Híbrido de Protobuf e persistir a sessão completa (com mídias criptograficamente seguras) usando a infraestrutura do app.

### Modified Capabilities
- `express-form`: O formulário passará de implementado rigidamente no código para uma especificação YAML alimentada pelo motor unificado, unindo-se à mesma base de código dos outros protocolos.

## Impact

- **Código Afetado**: `WizardScreen`, `WizardStateController`, arquivos `.proto` (principalmente `registro.proto`), exclusão da feature `express_form`.
- **Sistemas**: O gerador de PDF (em Rust/Typst) precisará ser levemente adaptado para ler dados de um JSON derivado de um Payload Genérico (`map<string, Resposta>`), ao invés de buscar campos estritamente nomeados, usando os IDs definidos nos YAMLs como chaves.
