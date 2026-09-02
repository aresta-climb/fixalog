## 1. Protobuf e Conversão de Dados

- [x] 1.1 Atualizar `registro.proto` para o formato Híbrido, introduzindo `Resposta` (com `oneof` de string, double, int, bool, midia, e `ListaRespostas`), o `map<string, Resposta>` e os grupos repetidos dinâmicos, mantendo o envelope de segurança (`id_sessao`, `assinatura_digital`, etc).
- [x] 1.2 Atualizar o arquivo de geração do protoc (`build.rs` ou script similar) e gerar as novas classes Dart e bindings Rust.
- [x] 1.3 Refatorar o `WizardState` e o `WizardStateController` para armazenarem `Map<String, Resposta>` nativamente ao invés de dicionários de strings planas.
- [x] 1.4 Implementar testes unitários para assegurar que os inputs da interface geram as instâncias corretas de `Resposta` no estado (Test-First).

## 2. Implementação Nativa no Wizard

- [x] 2.1 Refatorar `_CampoSimplesContent` no `wizard_screen.dart` para chamar `ImagePicker` quando o tipo for `IMAGE` e salvar o caminho absoluto.
- [x] 2.2 Refatorar `_CampoSimplesContent` para invocar o serviço/pacote de GPS (ex: `geolocator`) quando o tipo for `GPS` e salvar as coordenadas formatadas.
- [x] 2.3 Refatorar `_CampoSimplesContent` para exibir um Canvas Modal de assinatura digital quando o tipo for `SIGNATURE` e capturar a imagem gerada.

## 3. Integração de Persistência e PDF

- [x] 3.1 Adicionar método `saveSession()` no `WizardStateController`. Deve instanciar o `Registro` final e popular as coleções injetando diretamente o estado atual (`addAll`), sem necessidade de conversão.
- [x] 3.2 O `saveSession()` deve extrair todas as mídias coletadas, calcular os hashes SHA-256 e movê-las usando `SessionBundleManager.saveOriginalMedia`.
- [x] 3.3 O `saveSession()` deve salvar o `.binarypb` final usando `SessionBundleManager.saveManifest` e criar um registro na tabela `SubmissionRecord` do banco Isar.
- [x] 3.4 No widget `SummaryConclusionCard` do Wizard, conectar o botão "GERAR RELATÓRIO" ao `saveSession()` e subsequentemente acionar `generationProvider.notifier.startGeneration()`, exibindo o `GenerationProgressDialog`.

## 4. Adaptação do Registro Expresso (YAML) e Remoção de Código

- [x] 4.1 Criar o arquivo de especificação `assets/protocols/registro_expresso.yaml` com o formato dinâmico (lista infinita de ações de captura de fotos com descrições).
- [x] 4.2 Alterar a `HomeScreen` para que o botão "Novo Registro Expresso" abra a `WizardScreen` injetando o YAML do expresso.
- [x] 4.3 Testar o fluxo ponta-a-ponta do expresso usando a nova infraestrutura unificada.
- [x] 4.4 Excluir completamente os arquivos legados: `express_form_screen.dart`, `express_form_view_model.dart` e remover a dependência de sua feature antiga.
- [x] 4.5 Adaptar o script do gerador PDF em Rust para ler os campos mapeados do JSON Híbrido, utilizando as chaves extraídas do YAML (ao invés de properties estritas).
