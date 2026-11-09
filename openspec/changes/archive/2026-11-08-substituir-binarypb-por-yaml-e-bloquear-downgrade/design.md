# Design

## Context

Conforme detalhado em `proposal.md`, o Fixalog hoje armazena o manifesto `Registro` em binário Protobuf (`registro.binarypb`) tanto na pasta local da sessão (`sessoes/<id>/registro.binarypb`) quanto dentro do pacote pericial assinado (`OEBPS/dados/registro.binarypb`). Embora o Protobuf seja excelente para tipagem estática em memória no Dart (`Registro`, `GrupoRepetido`, `Resposta`, `ReferenciaMidia`), seu formato binário (`wire format`) omite todos os nomes de campos, dependendo exclusivamente dos números de tags. Para garantir legibilidade humana direta por 20+ anos sem abrir mão da validação estática do Protobuf no aplicativo, a persistência em disco e no `.epub` deve ser feita em `registro.yaml`, acompanhada dos schemas `registro.proto` e `wizard.proto` dentro de `OEBPS/dados/`, além de bloquear qualquer tentativa de downgrade ao editar relatórios de versões futuras (`versaoOrigem > versaoAlvo`).

## Goals / Non-Goals

**Goals:**
- Criar uma biblioteca coesa e determinística (`SerializadorYamlRegistro`) para converter `Registro` (Protobuf) ↔ `registro.yaml` (texto YAML legível com `yamlConteudo` em bloco literal `|`), validando estaticamente a estrutura via `toProto3Json()` e `mergeFromProto3Json()`.
- Empacotar e assinar `OEBPS/dados/registro.yaml`, `OEBPS/dados/registro.proto` e `OEBPS/dados/wizard.proto` dentro de todo `.epub` gerado, lendo os arquivos `.proto` diretamente de `app/protos/` (declarados nos assets do `pubspec.yaml` sem duplicar arquivos).
- Garantir por teste automatizado de contrato que os arquivos `app/protos/registro.proto` e `app/protos/wizard.proto` estejam sempre 100% sincronizados com os descritores `BuilderInfo` (`info_`) das classes Dart geradas (`registro.pb.dart` e `wizard.pb.dart`).
- Manter fallback transparente de leitura para `registro.binarypb` em sessões locais e pacotes `.epub` legados.
- Lançar `ExcecaoVersaoProtocoloNaoSuportada` em `MigradorProtocoloRegistro.migrarRegistro` sempre que `versaoOrigem > versaoAlvo`.

**Non-Goals:**
- Alterar o schema lógico de `registro.proto` ou `wizard.proto` (os campos existentes permanecem exatamente os mesmos).
- Bloquear a visualização somente-leitura (`VisualizadorRelatorioScreen`) de arquivos `.epub` gerados por versões futuras do aplicativo (pois o `.epub` já contém o `OEBPS/relatorio.xhtml` pronto).

## Decisions

### 1. Conversão `Registro` (Protobuf) ↔ `registro.yaml` via `SerializadorYamlRegistro`
- **Decisão**: Criar `SerializadorYamlRegistro` em `app/lib/core/services/serializador_yaml_registro.dart` com dois métodos estáticos principais:
  - `String paraYaml(Registro registro)`:
    1. Converte `registro.toProto3Json()` (que produz um `Map<String, dynamic>` com chaves camelCase padronizadas pelo Proto3 JSON e validação de tipos nativos do `protobuf`).
    2. Serializa a árvore para YAML determinístico com indentação de 2 espaços, ordenação estável de chaves de mapa e formatação de strings multilinhas (como `yamlConteudo` e textos de observações em Markdown) usando o indicador de bloco literal YAML (`|`), tornando o `yamlConteudo` do protocolo diretamente legível dentro de `registro.yaml`.
  - `Registro deYaml(String conteudoYaml)`:
    1. Executa `loadYaml(conteudoYaml)` do pacote `yaml` e converte recursivamente `YamlMap`/`YamlList` para `Map<String, dynamic>` e `List<dynamic>` puros em Dart.
    2. Instancia `Registro()..mergeFromProto3Json(mapa)`. Caso haja qualquer campo desconhecido ou tipo incompatível com o schema `registro.proto`, `mergeFromProto3Json` lança `FormatException` imediatamente, garantindo a mesma segurança de tipos estáticos em memória.
- **Alternativas consideradas**:
  - *Construir um parser/serializador manual campo a campo para `Registro`*: Descartado porque exigiria manutenção manual a cada novo campo no `.proto`, enquanto `toProto3Json()` / `mergeFromProto3Json()` já são gerados pelo `protoc` para todas as mensagens.

### 2. Empacotamento de `registro.proto` e `wizard.proto` sem Duplicação e com Trava de Contrato
- **Decisão**:
  - Adicionar `- protos/` na seção `flutter: assets:` do `app/pubspec.yaml`. Como `app/protos/registro.proto` e `app/protos/wizard.proto` já residem dentro da árvore `app/`, o Flutter empacota os próprios arquivos originais como assets sem precisar copiá-los para outra pasta.
  - Em `EpubPackagerService.empacotarEpub` e `GenerationNotifier.startGeneration`, empacotar e assinar no `META-INF/signatures.xml`:
    - `OEBPS/dados/registro.yaml` (`media-type="application/yaml"`)
    - `OEBPS/dados/registro.proto` (`media-type="text/plain"`)
    - `OEBPS/dados/wizard.proto` (`media-type="text/plain"`)
  - Em `SerializadorYamlRegistro.validarSincroniaSchemasProto`, inspecionar o texto de `app/protos/registro.proto` e `app/protos/wizard.proto` (extraindo os blocos `message Nome { ... }` e os nomes/números de tags dos campos) e compará-los contra os `BuilderInfo` (`info_.byTagAsString`) de todas as classes geradas em `registro.pb.dart` (`Registro`, `GrupoRepetido`, `Resposta`, `ListaRespostas`, `ReferenciaMidia`, `ArquivoImagem`, `ArquivoVideo`, `ArquivoAudio`, `ArquivoDocumento`) e `wizard.pb.dart` (`DefinicaoProtocolo`, `Bloco`, `Step`, `ConteudoStep`, `StepInstrucao`, `StepCampoSimples`, `OpcaoCampo`, `StepSelecaoRamo`, `Ramo`, `StepListaAcoes`, `TipoAcao`, `StepRefMateriais`).
- **Racional**: Assim é impossível esquecer de atualizar o `.proto` ao selar o laudo (pois o `.epub` puxa direto de `app/protos/`) e impossível alterar o `.proto` ou o `.pb.dart` de forma dessincronizada sem quebrar a suíte de testes.

### 3. Compatibilidade Retroativa Transparente na Leitura (`registro.yaml` com Fallback para `registro.binarypb`)
- **Decisão**:
  - Em `SessionBundleManager`:
    - Adicionar `saveManifestYaml({required String sessionId, required String yamlConteudo})` (ou atualizar `saveManifest` / `readManifestRegistro`) gravando `registro.yaml`.
    - Na leitura do manifesto da sessão (`lerRegistroSessao` / `readManifest`), verificar primeiro se `registro.yaml` existe e decodificá-lo via `SerializadorYamlRegistro.deYaml`; caso contrário, se `registro.binarypb` existir (sessão legada), ler via `Registro.fromBuffer`.
    - Em `copiarArquivosMidiaSessao`, ignorar também `registro.yaml` ao copiar mídias entre sessões.
  - Em `BancoDadosLocal`, `GenerationNotifier` e `VisualizadorRelatorioScreen`:
    - Ao ler um registro de uma pasta de sessão ou de um `.epub` (incluindo materiais aninhados em `OEBPS/materiais/<uuid>/`), procurar primeiro `OEBPS/dados/registro.yaml` (ou `sessoes/<id>/registro.yaml`) e usar `OEBPS/dados/registro.binarypb` (ou `sessoes/<id>/registro.binarypb`) como fallback para relatórios gerados antes desta mudança.

### 4. Recusa Explícita de Downgrade (`versaoOrigem > versaoAlvo`)
- **Decisão**:
  - Criar a exceção tipada `ExcecaoVersaoProtocoloNaoSuportada` em `app/lib/core/services/migrador_protocolo_registro.dart` contendo `idProtocolo`, `versaoRegistro` e `versaoSuportada`.
  - No início de `MigradorProtocoloRegistro.migrarRegistro`:
    - Se `versaoOrigem > versaoAlvo`, lançar `ExcecaoVersaoProtocoloNaoSuportada` com mensagem clara em português: *"O relatório utiliza a versão $versaoOrigem do protocolo '$idCanonico', que é mais recente que a versão suportada por este aplicativo (versão $versaoAlvo). Atualize o aplicativo para editar ou duplicar este relatório."*
    - Nenhuma alteração é feita no `registro` quando `versaoOrigem > versaoAlvo`.

## Risks / Trade-offs

- **[Risco] Relatórios e sessões já existentes no dispositivo do usuário estão salvos em `registro.binarypb`** → **Mitigação**: Todos os pontos de leitura (`SessionBundleManager`, `BancoDadosLocal`, `GenerationNotifier`, `VisualizadorRelatorioScreen`) verificam `registro.yaml` primeiro e fazem fallback automático para `registro.binarypb`. Assim que uma sessão antiga for editada ou re-gerada, ela passa a ser gravada em `registro.yaml`.
- **[Risco] Caracteres especiais, quebras de linha ou números/booleanos em strings no YAML causarem ambiguidade ao fazer parsing de volta para Protobuf** → **Mitigação**: `SerializadorYamlRegistro.paraYaml` colocará strings entre aspas JSON/YAML seguras sempre que necessário (ex.: strings numéricas como `"2"` em `versaoProtocolo` ou `"1762550000"` em `Int64` serializado pelo Proto3 JSON) para que `loadYaml` preserve o tipo exato (`String` vs `int`/`bool`) exigido por `mergeFromProto3Json`.
