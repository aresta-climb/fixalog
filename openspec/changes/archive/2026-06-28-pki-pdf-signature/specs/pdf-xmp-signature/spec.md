## ADDED Requirements

### Requirement: O sistema DEVE assinar PDFs digitalmente usando PKCS#7
O sistema DEVE utilizar um certificado X.509 autoassinado gerado na máquina (ECDSA secp256r1) para envelopar criptograficamente todo o documento PDF gerado, protegendo os dados visuais e os metadados XMP contra adulterações.

#### Scenario: Assinatura bem-sucedida do PDF Expresso
- **WHEN** o usuário finaliza o Registro Expresso e aprova a exportação
- **THEN** o arquivo .pdf gerado possui uma assinatura PKCS#7 válida na camada nativa do formato PDF

### Requirement: O Protobuf limpo DEVE estar embutido no XMP
O sistema DEVE codificar o objeto Protobuf final em Base64 e injetá-lo na tag <fixalog:protobuf> do dicionário XMP do arquivo PDF, eliminando a necessidade de impressão de Hashes no rodapé visível.

#### Scenario: Injeção de XMP
- **WHEN** o PDF é construído e o Protobuf é serializado
- **THEN** o documento recebe um PdfMetadata XML formatado que transita os dados crus de forma invisível
