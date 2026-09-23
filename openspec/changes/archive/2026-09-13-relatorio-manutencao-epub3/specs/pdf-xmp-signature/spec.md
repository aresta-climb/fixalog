## REMOVED Requirements

### Requirement: O sistema DEVE assinar PDFs digitalmente usando PKCS#7
**Reason**: Assinaturas PKCS#7/PAdES na camada binária de baixo nível do PDF foram descontinuadas porque exigiam manipulação binária de /ByteRange via Rust e entravam em conflito com a assinatura de protocolo externa realizada por gestores ou mantenedores no portal Gov.br.
**Migration**: A assinatura digital canônica passa a ser realizada no container EPUB 3 via especificação W3C XML-DSig com o mesmo par de chaves ECDSA secp256r1. O PDF gerado pelo FixLog atua como representação impressa sem travas criptográficas binárias prévias, podendo ser assinado no Gov.br livremente.

### Requirement: O Protobuf limpo DEVE estar embutido no XMP
**Reason**: A injeção de dicionários XML/XMP binários no PDF via FFI Rust foi substituída pelo empacotamento aberto do EPUB 3.
**Migration**: O binário Protobuf `registro.binarypb` agora é armazenado diretamente como anexo estruturado dentro do container EPUB 3 na pasta `OEBPS/dados/`, declarado no manifesto e assinado no `META-INF/signatures.xml`.
