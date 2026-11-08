# Spec Delta

## MODIFIED Requirements

### Requirement: O sistema DEVE assinar digitalmente o EPUB 3 com XML-DSig
O sistema DEVE (MUST) proteger a integridade do relatório gerando o arquivo `META-INF/signatures.xml` conforme a recomendação W3C XML Signature (XML-DSig). O arquivo DEVE (MUST) conter os resumos criptográficos SHA-256 de todos os arquivos do manifesto (incluindo páginas XHTML, mídias e Protobuf), a assinatura calculada com a chave privada ECDSA (`secp256r1`) do mantenedor, o certificado X.509 correspondente e o atestado OIDC assinado pelo provedor social (`atestado_oidc_jwt`) que vincula criptograficamente a chave pública ECDSA à conta Google/Apple do autor via `nonce`.

#### Scenario: Verificação de integridade do container assinado
- **WHEN** o relatório EPUB 3 é finalizado pelo mantenedor
- **THEN** o arquivo `META-INF/signatures.xml` é gerado contendo os digests de cada componente, a assinatura criptográfica vinculada ao certificado do mantenedor e o `atestado_oidc_jwt` comprovando a posse da conta Google/Apple no momento da geração da chave

## ADDED Requirements

### Requirement: Âncora de Navegação Direta por Vídeo (`id="video-<uuid>"`) no Documento XHTML
O gerador do documento `OEBPS/relatorio.xhtml` DEVE (MUST) atribuir o identificador único `id="video-<uuid>"` ao elemento container de cada vídeo embutido (`<div id="video-<uuid>" class="container-video">`), correspondendo exatamente ao fragmento de URL `#video-<uuid>` codificado nos QR Codes do Sumário Executivo em PDF (`https://fixalog.app/v/<idSessao>#video-<uuid>`).

#### Scenario: Correspondência entre QR Code do PDF e âncora HTML do vídeo no EPUB
- **WHEN** um relatório contendo um vídeo de identificador `<uuid>` é compilado em EPUB 3 e PDF Resumido
- **THEN** o `OEBPS/relatorio.xhtml` renderiza o container do vídeo com `id="video-<uuid>"` permitindo que a abertura de `https://fixalog.app/v/<idSessao>#video-<uuid>` posicione o leitor diretamente sobre o vídeo
