## ADDED Requirements

### Requirement: Incorporação de Materiais Extraídos sem Duplicação no EPUB 3 da Manutenção
Ao gerar o container EPUB 3 de uma manutenção que referencia materiais cadastrados, o sistema DEVE incorporar o conteúdo extraído do pacote `.epub` de cada material utilizado dentro do diretório `OEBPS/materiais/<uuid_material>/` do EPUB da manutenção, mantendo o arquivo `OEBPS/dados/registro.binarypb` e a assinatura `META-INF/signatures.xml` originais do material intactos dentro dessa subpasta para permitir validação criptográfica independente sem duplicar mídias.

#### Scenario: Empacotamento e verificação de material aninhado no EPUB da manutenção
- **WHEN** o relatório EPUB 3 de uma manutenção contendo materiais selecionados é gerado e assinado
- **THEN** a árvore extraída do EPUB de cada material utilizado é gravada em `OEBPS/materiais/<uuid_material>/` contendo seu `META-INF/signatures.xml` e `OEBPS/dados/registro.binarypb` originais
- **THEN** a assinatura `META-INF/signatures.xml` da manutenção na raiz assina todos os arquivos do pacote principal e das subpastas de materiais
- **THEN** a assinatura original do material continua válida se verificada isoladamente a partir da subpasta `OEBPS/materiais/<uuid_material>/`

### Requirement: Navegação por Hiperlinks de Ida e Volta entre Manutenção e Materiais no EPUB 3
O documento `relatorio.xhtml` da manutenção DEVE renderizar as referências aos materiais utilizados como hiperlinks apontando para o documento `materiais/<uuid_material>/OEBPS/relatorio.xhtml` correspondente, e o documento XHTML do material DEVE disponibilizar um botão ou controle de retorno que permita ao leitor voltar exatamente ao ponto de leitura anterior no relatório da manutenção.

#### Scenario: Navegar para os detalhes do material e retornar à manutenção
- **WHEN** o usuário visualiza o relatório da manutenção e clica na referência de um material utilizado
- **THEN** o visualizador navega para a página de detalhes daquele material exibindo seus componentes, notas fiscais, testes e etapas de fabricação
- **THEN** ao acionar o botão de voltar na página do material, o visualizador retorna ao relatório da manutenção na posição onde o usuário estava

### Requirement: Atualização de Materiais ao Re-gerar Relatório de Manutenção
Quando um relatório de manutenção previamente gerado for editado ou re-gerado, o sistema DEVE buscar a versão assinada mais recente de cada material referenciado no catálogo local para atualizar a subpasta `OEBPS/materiais/<uuid_material>/`, mantendo como fallback a cópia já embutida no EPUB anterior caso o material tenha sido excluído do catálogo local.

#### Scenario: Re-gerar manutenção após atualização de um material no catálogo
- **WHEN** um material é editado e re-assinado no catálogo e posteriormente o usuário re-gera o relatório de uma manutenção que utiliza esse material
- **THEN** o novo EPUB 3 da manutenção incorpora a versão atualizada do material
