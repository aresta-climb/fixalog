# EPUB 3 Report

## ADDED Requirements

### Requirement: Emissão do Relatório EPUB 3 no Idioma Ativo do Usuário com Rótulos Traduzidos
O gerador de EPUB 3 DEVE (MUST) compilar os documentos `relatorio.xhtml`, `nav.xhtml` e o metadado `<dc:language>` do `content.opf` estaticamente no idioma ativo do aplicativo no momento da geração (aplicando `dir="rtl"` quando o idioma for Árabe `ar`), exibindo cabeçalhos, textos fixos, rótulos de campos e valores de opções traduzidos a partir do dicionário do protocolo, enquanto mantém os identificadores canônicos em inglês no arquivo `OEBPS/dados/registro.binarypb`.

#### Scenario: Geração de laudo EPUB 3 em Inglês ou Japonês
- **WHEN** o usuário gera um relatório EPUB 3 com o aplicativo configurado em Japonês (`ja`)
- **THEN** o `content.opf` registra `<dc:language>ja</dc:language>` e o `relatorio.xhtml` é gerado com `lang="ja"`, cabeçalhos em Japonês e rótulos/opções de campos resolvidos pelo dicionário `ja` do protocolo
- **THEN** o binário `OEBPS/dados/registro.binarypb` preserva os identificadores técnicos canônicos em inglês

#### Scenario: Geração de laudo EPUB 3 em Árabe com direção RTL
- **WHEN** o usuário gera um relatório EPUB 3 com o aplicativo configurado em Árabe (`ar`)
- **THEN** os documentos `relatorio.xhtml` e `nav.xhtml` incluem os atributos `lang="ar"` e `dir="rtl"`

### Requirement: Empacotamento Seletivo da Fonte Noto Sans do Idioma do Relatório no EPUB 3
O empacotador EPUB 3 DEVE (MUST) incluir em `OEBPS/fonts/` apenas os arquivos de fonte `Noto Sans` necessários para o idioma em que o relatório foi gerado (`NotoSans` para idiomas latinos, adicionando `NotoSansArabic` para `ar` ou `NotoSansJP` para `ja`), declarando-os via `@font-face` no `OEBPS/estilo.css`, registrando-os no `<manifest>` do `OEBPS/content.opf` com `media-type="font/ttf"` e incluindo seus hashes SHA-256 na assinatura `META-INF/signatures.xml`.

#### Scenario: Empacotamento e assinatura de fonte para relatório em idioma latino
- **WHEN** um relatório EPUB 3 é gerado em Português (`pt`) ou Inglês (`en`)
- **THEN** o pacote `.epub` inclui `OEBPS/fonts/NotoSans-Regular.ttf` e `OEBPS/fonts/NotoSans-Bold.ttf` comprimidos com `DEFLATE`, declarados no `estilo.css` e no `content.opf` e assinados no `META-INF/signatures.xml`, sem incluir os arquivos de fonte de Árabe ou Japonês

#### Scenario: Empacotamento e assinatura de fonte para relatório em Japonês ou Árabe
- **WHEN** um relatório EPUB 3 é gerado em Japonês (`ja`) ou Árabe (`ar`)
- **THEN** o pacote `.epub` inclui em `OEBPS/fonts/` a fonte específica do script (`NotoSansJP` ou `NotoSansArabic`) além da `NotoSans` base, garantindo renderização determinística e autocontida em qualquer leitor de EPUB
