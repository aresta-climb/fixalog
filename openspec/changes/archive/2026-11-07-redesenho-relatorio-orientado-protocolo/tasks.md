# Tasks

## 1. Motor Semântico da Árvore de Relatório (`ConstrutorArvoreRelatorio`)

- [x] 1.1 Criar os testes orientados a comportamento em `app/test/core/services/construtor_arvore_relatorio_test.dart` validando (a) erro explícito quando `yamlConteudo` está vazio, (b) tradução de `Bloco`, `StepCampoSimples`, `DROPDOWN` e `StepRefMateriais` para rótulos humanos, (c) omissão total de `StepInstrucao` e de campos/sub-listas/blocos vazios, (d) expansão recursiva de `StepSelecaoRamo` e aninhamento recursivo de sub-listas (`__<idItemPai>`), e (e) agrupamento de campos simples curtos em grade e mídias em galeria; verificar que os testes falham inicialmente (Red).
- [x] 1.2 Implementar `ConstrutorArvoreRelatorio` e os modelos imutáveis da árvore semântica em `app/lib/core/services/construtor_arvore_relatorio.dart` com docstrings em português brasileiro, extração de UUIDs de materiais orientada a `StepRefMateriais` (sem *hardcodes* de chaves) e fazer passar 100% dos testes em `app/test/core/services/construtor_arvore_relatorio_test.dart` com 100% de cobertura de linhas (Green/Refactor).

## 2. Redesenho Semântico e Visual do Relatório EPUB 3 (`EpubDocumentBuilder` e `EpubPackagerService`)

- [x] 2.1 Atualizar os testes em `app/test/core/services/epub_document_builder_test.dart` e `app/test/core/services/epub_packager_service_test.dart` para fornecerem `yamlConteudo` válido e verificarem a renderização por blocos do protocolo, rótulos humanos de perguntas/opções, omissão de `StepInstrucao` e campos vazios, cards numerados com sub-listas aninhadas, grades de propriedades, galerias de fotos lado a lado com rótulos, seções de materiais anexos e títulos reais dos materiais no `OEBPS/nav.xhtml` (Red).
- [x] 2.2 Refatorar `app/lib/core/services/epub_document_builder.dart` e `app/lib/core/services/epub_packager_service.dart` para consumirem `ConstrutorArvoreRelatorio`, aplicarem o novo CSS responsivo (grades de 2 colunas para propriedades e fotos, cards aninhados, badges de escolha e regras `@media print`) e receberem `titulosMateriais` na montagem do `nav.xhtml`, verificando que ambos os arquivos de teste passam com 100% de cobertura (Green/Refactor).

## 3. Redesenho Editorial do PDF Resumido A4 (`PdfPrintSummaryService`) e Integração de Geração

- [x] 3.1 Atualizar os testes em `app/test/core/services/pdf_print_summary_service_test.dart`, `app/test/features/pdf_generation/providers/generation_provider_test.dart` e `app/test/features/pdf_generation/views/visualizador_relatorio_screen_test.dart` com `yamlConteudo` válido, validando a estruturação por blocos, rótulos humanos, omissão de `StepInstrucao` e vazios, aninhamento de sub-listas, layout em duas colunas para propriedades e fotos no PDF A4 e resolução genérica de títulos de exibição (Red).
- [x] 3.2 Refatorar `app/lib/core/services/pdf_print_summary_service.dart`, `app/lib/features/pdf_generation/providers/generation_provider.dart` e `app/lib/features/pdf_generation/views/visualizador_relatorio_screen.dart` para utilizarem `ConstrutorArvoreRelatorio` tanto no relatório principal quanto nas fichas técnicas de materiais anexas, verificando que todos os testes unitários e de widget dos módulos afetados passam com 100% de cobertura (Green/Refactor).

## 4. Verificação de Espelhamento 1:1, Cobertura Integral e Análise Estática

- [x] 4.1 Executar `flutter analyze`, `flutter test test/architecture/test_structure_mirror_test.dart` e a verificação de 100% de cobertura comportamental sobre todos os arquivos modificados e criados, garantindo zero avisos do analisador e conformidade integral com o `AGENTS.md`.
