## ADDED Requirements

### Requirement: Geração do Rascunho Visual (Draft PDF)
O sistema DEVE gerar um arquivo PDF parcial contendo o layout visual do laudo, tabelas de formulários e imagens de evidências usando a biblioteca `pdf` em Dart, salvando o documento no disco para posterior injeção das mídias.

#### Scenario: Geração bem-sucedida do rascunho
- **WHEN** o laudo contém apenas textos e fotos simples
- **THEN** o sistema salva o PDF corretamente em disco no formato padrão

### Requirement: Anotações de Clique em Mídias (GoToE)
O sistema DEVE inserir miniaturas (Thumbnails) para vídeos e ícones vetoriais de áudio, circundados por anotações de clique (GoToE - Go To Embedded) nas posições correspondentes da página, para permitir a abertura dos anexos embutidos.

#### Scenario: Clique no vídeo
- **WHEN** o leitor clica na miniatura do vídeo dentro do PDF visual
- **THEN** a anotação aciona a extração do anexo de vídeo correspondente
