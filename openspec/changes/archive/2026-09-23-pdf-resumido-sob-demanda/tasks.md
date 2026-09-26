## 1. Miniaturas de Impressão no Serviço de Compressão

- [x] 1.1 Adicionar método `compressThumbnail` em `MediaCompressorService` gerando imagem 600x600 WebP (qualidade 70) e verificar com testes unitários em `media_compressor_service_test.dart`
- [x] 1.2 Atualizar `comprimirFotoSessao` em `MediaCompressorService` para salvar `<uuid>_thumb.webp` no bundle da sessão via `SessionBundleManager` e validar com testes de persistência

## 2. Desacoplamento da Geração no Wizard

- [x] 2.1 Remover a chamada síncrona do `exportarPdfResumido` de dentro do `startGeneration` em `generation_provider.dart`, focando a finalização exclusivamente no container EPUB 3 e assinatura XML-DSig
- [x] 2.2 Atualizar `generation_provider_test.dart` para verificar que `startGeneration` conclui com sucesso mantendo `epubPath` e `status` sem depender do PDF síncrono

## 3. Geração Sob Demanda e Cache do PDF no Visualizador

- [x] 3.1 Implementar serviço/método de exportação sob demanda em `VisualizadorRelatorioScreen` que gera o PDF resumido a partir das miniaturas e do XHTML extraído da sessão caso `caminhoPdf` ainda não exista
- [x] 3.2 Atualizar o registro da sessão no Isar (`SubmissionRecord.pdfPath`) com o caminho do PDF gerado sob demanda para que novas aberturas e compartilhamentos sejam imediatos
- [x] 3.3 Adicionar indicador visual de carregamento ("Gerando PDF resumido...") durante a exportação sob demanda e tratar erros com SnackBar amigável
- [x] 3.4 Atualizar testes em `visualizador_relatorio_screen_test.dart` cobrindo o fluxo de geração sob demanda ao selecionar a opção "Versão Resumida (PDF)"

## 4. Verificação Integrada

- [x] 4.1 Executar a suíte completa de testes (`flutter test`) e verificar 100% de aprovação sem regressões
