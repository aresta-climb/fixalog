## Context

Atualmente o aplicativo conta com a funcionalidade de "Registro Expresso" fortemente acoplada ao código Dart na camada de UI (`ExpressFormScreen`). Em paralelo, foi construída uma engine dinâmica (`WizardScreen`) capaz de gerar formulários inteiros baseados em arquivos YAML, mas que carece de integração com recursos nativos (Câmera, GPS) e de um fluxo de persistência de dados real. Isso resulta em duas fontes da verdade para UI e Lógica. O objetivo desse design é propor uma transição para consolidar o motor de formulários em um único fluxo dinâmico governado puramente por especificações YAML.

## Goals / Non-Goals

**Goals:**
- Prover a arquitetura e o modelo de dados para o novo "Protobuf Híbrido".
- Especificar as integrações nativas necessárias no `WizardScreen` (Câmera, GPS, Assinatura) para extinguir a necessidade da implementação customizada atual.
- Descrever a integração final do Wizard com o `SessionBundleManager` e a chamada de geração de PDF.

**Non-Goals:**
- Mudar ou reescrever a renderização de componentes de UI do Wizard que já existem (campos simples, menus, branches). Apenas faremos o bind das ações finais.
- Modificar o sistema de criptografia ou os wrappers de assinaturas em si (apenas seu acionamento).

## Decisions

### 1. Protobuf Híbrido: `Registro` ao invés de `RegistroManutencao`
Em vez de mapear explicitamente os campos de cada resposta de UI do Wizard em um esquema Protobuf rígido, vamos introduzir um modelo *híbrido*:
- **Envelope Estrito:** Mantém IDs (sessão, protocolo, mantenedor), metadados de segurança e assinatura digital como campos estritamente tipados.
- **Payload Dinâmico Tipado:** As respostas do formulário (que o `WizardState` mantém num `Map`) serão serializadas diretamente para um `map<string, Resposta>` no Protobuf. O tipo `Resposta` será uma mensagem `oneof` tipada capaz de acomodar `string`, `double`, `int64` (inteiros), `bool`, estruturas de mídia (`ReferenciaMidia`) e **uma estrutura de encapsulamento para listas** (`ListaRespostas`, contendo `repeated Resposta`, já que o Protobuf não permite `repeated` diretamente dentro de um `oneof`).

*Justificativa:* Minimiza dramaticamente o acoplamento. Adicionar um novo campo no YAML não exigirá recompilação de código Dart nem de Rust (PDF).

### 2. Estado Nativo com Protobuf (Zero-Conversion)
O `WizardState` será refatorado para utilizar nativamente as estruturas geradas pelo Protobuf em seu estado. O mapa de respostas passará de `Map<String, String>` para `Map<String, Resposta>`.
Ao finalizar o formulário, a etapa de conversão será eliminada. O controlador simplesmente instanciará o `Registro` e injetará os mapas de estado com um `addAll`, chamando em seguida o `SessionBundleManager` para o cálculo dos hashes de mídia.

### 3. Integração Nativa no `WizardScreen`
As funções mockadas (`save('photo.jpg')` e similares) no widget `CampoSimplesWidget` serão conectadas a:
- `ImagePicker` para captura real.
- Pacote de Localização / GPS para preenchimento de coordenadas reais.
- `signature` (ou lib equivalente utilizada no projeto) para coleta da assinatura digital do mantenedor.

### 4. Especificação de "Registro Expresso" em YAML
Remoção imediata da funcionalidade legada de Registro Expresso (as telas antigas). Em seu lugar, será introduzido o `registro_expresso.yaml` que utilizará a estrutura infinita (`maximo: 0`) de repetições (Ação de Foto + Descrição de Texto).

## Risks / Trade-offs

- **[Trade-off] Perda de tipagem forte nos campos de negócio:** O Rust/Typst perderá acesso a getters tipados para regras de negócio exclusivas, exigindo fetch via `map[key]`. *Mitigação*: Como a estrutura é espelho do YAML, a validação de existência já é feita pelo Wizard. O script gerador do PDF apenas reflete o que o YAML pediu.
- **[Risco] Compatibilidade Retroativa:** Ao trocar o Protobuf de um modelo para outro, registros antigos previamente gerados pelo app perderão a compatibilidade estrutural. *Mitigação*: **Nenhuma.** Como o aplicativo ainda não foi lançado, trata-se de uma quebra intencional e os dados antigos de desenvolvimento podem ser descartados (Wipe database).
