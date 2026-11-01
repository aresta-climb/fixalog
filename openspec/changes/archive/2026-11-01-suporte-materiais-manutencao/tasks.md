# Tasks

## 1. Evolução de Schemas Protobuf, Parser YAML e Modelo Local (Isar)

- [x] 1.1 Atualizar `app/protos/wizard.proto` adicionando `bool preencher_data_atual` em `StepCampoSimples` e `bool origem_catalogo` em `StepRefMateriais`, regerar os bindings Dart Protobuf e verificar que `flutter analyze` executa sem erros.
- [x] 1.2 Escrever testes de comportamento em `app/test/core/services/protocol_parser_test.dart` validando o parsing de `preencher_data_atual`, `origem_catalogo` e `StepListaAcoes` aninhadas dentro de `TipoAcao`, atualizar `app/lib/core/services/protocol_parser.dart` com docstrings em português e verificar que todos os testes do parser passam.
- [x] 1.3 Escrever testes em `app/test/core/models/local/submission_record_test.dart` para os novos campos `tipoRegistro`, `tituloExibicao` e `dataUltimaSelecao`, atualizar `app/lib/core/models/local/submission_record.dart`, regerar `submission_record.g.dart` e verificar que os testes do modelo passam.

## 2. Motor do Wizard: Isolamento de Escopo, Data Atual e Listas Aninhadas

- [x] 2.1 Escrever testes orientados a comportamento em `app/test/features/wizard/controllers/wizard_state_controller_test.dart` cobrindo inicialização automática de data atual (`preencher_data_atual`), manipulação/persistência/reconstrução de `StepListaAcoes` aninhadas (`"${subListaId}__${itemPaiId}"`) e extração de `tituloExibicao` e `tipoRegistro` no `SubmissionRecord`, implementar no `WizardStateController` e verificar que os testes passam.
- [x] 2.2 Escrever testes de widget em `app/test/features/wizard/views/wizard_screen_test.dart` validando a renderização inline de `StepListaAcoes` aninhadas, a edição de campo `DATE` pré-preenchido com a data atual e a abertura empilhada de um segundo `WizardScreen` com `ProviderScope` isolado sem corromper a sessão pai, implementar em `app/lib/features/wizard/views/wizard_screen.dart` e verificar que os testes passam.

## 3. Protocolo de Cadastro de Materiais e Seleção no Catálogo Local

- [x] 3.1 Criar o protocolo `app/assets/protocols/cadastro_material.yaml` contendo identificação geral (nome, código da associação, data automática), lista de materiais com as 6 categorias (`parabolt`, `chapeleta`, `chapeleta_argola`, `ancoragem_quimica`, `costura_permanente`, `outro`), seção universal padronizada por material (Nota Fiscal/Comprovante, sub-lista de Testes de Qualidade e sub-lista de Detalhes/Fabricação) e assinatura, registrando o asset no `pubspec.yaml` e verificando sua carga via teste em `protocol_parser_test.dart`.
- [x] 3.2 Atualizar `app/assets/protocols/manutencao_ferragens.yaml` para utilizar seleção de materiais do catálogo no Bloco 1 (`origem_catalogo: true`) e manter a referência nos passos de ações na via, verificando a validade do YAML nos testes do parser.
- [x] 3.3 Escrever testes de comportamento para a seleção de materiais do catálogo local (ordenados por `dataUltimaSelecao` decrescente) e para o botão de cadastrar novo material sob demanda (abrindo `WizardScreen` com `cadastro_material.yaml`, atualizando `dataUltimaSelecao` e auto-selecionando o material criado ao retornar), implementar no `RefMateriaisWidget` / `WizardStateController` e verificar que os testes passam.

## 4. Entrada na Tela Inicial e Separação no Histórico

- [x] 4.1 Escrever teste de widget em `app/test/features/home/views/new_protocol_screen_test.dart` verificando a exibição e abertura do novo card de Cadastro de Materiais, atualizar `app/lib/features/home/views/new_protocol_screen.dart` e confirmar que os testes passam.
- [x] 4.2 Escrever testes em `app/test/features/home/providers/history_provider_test.dart` e `app/test/features/home/views/history_screen_test.dart` validando a separação e alternância entre Manutenções e Materiais cadastrados, exibição do `tituloExibicao` e ações de visualizar, editar/re-assinar e excluir materiais, atualizar `history_provider.dart` e `history_screen.dart` e verificar que os testes passam.

## 5. Relatórios Assinados: Aninhamento Bit-a-Bit no EPUB 3 e Fusão no PDF

- [x] 5.1 Escrever testes em `app/test/core/services/epub_document_builder_test.dart` e `app/test/core/services/epub_packager_service_test.dart` validando a geração de links para `materiais/<uuid>/OEBPS/relatorio.xhtml`, botão de retorno à página anterior no XHTML e empacotamento da árvore extraída de cada material em `OEBPS/materiais/<uuid>/` (preservando `META-INF/signatures.xml` e `OEBPS/dados/registro.binarypb` originais do material), implementar em `epub_document_builder.dart` e `epub_packager_service.dart` e verificar que os testes passam.
- [x] 5.2 Escrever testes em `app/test/features/pdf_generation/providers/generation_provider_test.dart` verificando que a geração e re-geração do relatório de manutenção incorpora a versão mais recente assinada de cada material do catálogo em `OEBPS/materiais/<uuid>/` (com fallback para a cópia já embutida no EPUB anterior caso o material tenha sido removido do catálogo) e que tanto a assinatura XML-DSig da manutenção quanto a assinatura original do material na subpasta permanecem válidas, implementar em `generation_provider.dart` e verificar que os testes passam.
- [x] 5.3 Escrever testes em `app/test/core/services/pdf_print_summary_service_test.dart` e `app/test/features/pdf_generation/views/visualizador_relatorio_screen_test.dart` validando a concatenação dos relatórios dos materiais utilizados ao final do PDF Resumido da manutenção, implementar em `pdf_print_summary_service.dart` e `visualizador_relatorio_screen.dart` e verificar que os testes passam.
- [x] 5.4 Executar a suíte completa de testes (`flutter test`) e o validador de espelhamento 1:1 (`test_structure_mirror_test.dart`), garantindo 100% de aprovação e conformidade com o `AGENTS.md`.
