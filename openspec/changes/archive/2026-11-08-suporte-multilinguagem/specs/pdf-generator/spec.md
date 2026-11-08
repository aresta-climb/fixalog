# PDF Generator

## ADDED Requirements

### Requirement: Emissão do PDF Resumido no Idioma Ativo com Fontes Noto Sans Offline e Suporte RTL
O gerador de PDF Resumido DEVE (MUST) construir o documento A4 no idioma em que o relatório foi emitido, traduzindo cabeçalhos, avisos institucionais, rótulos de campos e valores de opções do protocolo, carregando sob demanda a partir dos assets locais as fontes TTF da família Google Noto Sans (`NotoSans` base, adicionando `NotoSansArabic` para `ar` com direção `RTL` ou `NotoSansJP` para `ja`) para garantir renderização 100% offline sem falha de glifos.

#### Scenario: Exportação de PDF Resumido em Japonês offline
- **WHEN** o usuário exporta o PDF Resumido de um relatório em Japonês (`ja`) sem conexão com a internet
- **THEN** o gerador incorpora a fonte local `NotoSansJP` e `NotoSans` e renderiza todos os ideogramas CJK, cabeçalhos e rótulos de campos traduzidos sem caracteres ausentes

#### Scenario: Exportação de PDF Resumido em Árabe com layout RTL
- **WHEN** o usuário exporta o PDF Resumido de um relatório em Árabe (`ar`)
- **THEN** o gerador incorpora a fonte local `NotoSansArabic`, aplica direcionalidade da direita para a esquerda (`RTL`) na página e renderiza os textos e rótulos em Árabe
