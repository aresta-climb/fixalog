# Spec Delta

## MODIFIED Requirements

### Requirement: Incorporação de Materiais Extraídos sem Duplicação no EPUB 3 da Manutenção
Ao gerar o container EPUB 3 de qualquer relatório de vistoria (Manutenção, Abertura de Via ou Registro Expresso) que referencie materiais cadastrados em campos de nível raiz ou dentro de itens de lista (`ref_mat_*`), o sistema DEVE (MUST) compilar o conjunto único de todos os materiais referenciados no relatório e incorporar o conteúdo extraído do pacote `.epub` de cada material utilizado dentro do diretório `OEBPS/materiais/<uuid_material>/` do EPUB gerado, mantendo o arquivo `OEBPS/dados/registro.binarypb` e a assinatura `META-INF/signatures.xml` originais do material intactos dentro dessa subpasta para permitir validação criptográfica independente sem duplicar mídias.

#### Scenario: Empacotamento e verificação de material aninhado no EPUB da manutenção
- **WHEN** o relatório EPUB 3 de uma manutenção, abertura de via ou registro expresso contendo materiais selecionados dentro das ações (`ref_mat_*`) é gerado e assinado
- **THEN** o sistema coleta automaticamente todos os UUIDs únicos de materiais referenciados nas ações e grava a árvore extraída do EPUB de cada material em `OEBPS/materiais/<uuid_material>/` contendo seu `META-INF/signatures.xml` e `OEBPS/dados/registro.binarypb` originais
- **THEN** a assinatura `META-INF/signatures.xml` na raiz assina todos os arquivos do pacote principal e das subpastas de materiais
- **THEN** a assinatura original do material continua válida se verificada isoladamente a partir da subpasta `OEBPS/materiais/<uuid_material>/`
