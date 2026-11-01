## ADDED Requirements

### Requirement: Seleção e Rasterização de Documentos PDF em Campos de Mídia
Quando um campo do Wizard permitir captura de documento ou imagem, a interface DEVE oferecer, além da captura por câmera e galeria de fotos, a opção de selecionar um arquivo PDF do dispositivo, armazenando o binário `.pdf` original intacto e as imagens `.webp` rasterizadas de cada página no `SessionBundleManager`.

#### Scenario: Seleção de arquivo PDF no modal de captura do campo
- **WHEN** o usuário toca para anexar um comprovante em um campo que aceita documento ou imagem e escolhe a opção de selecionar arquivo PDF
- **THEN** o sistema abre o seletor de arquivos filtrando por extensão `.pdf`
- **THEN** após a escolha do PDF, o arquivo original é copiado para a sessão, cada página é rasterizada em um arquivo `.webp` numerado e o campo exibe a confirmação visual do documento anexado com sua contagem de páginas
