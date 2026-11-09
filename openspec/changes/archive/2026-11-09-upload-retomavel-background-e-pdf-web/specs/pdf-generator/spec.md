# Spec Delta

## MODIFIED Requirements

### Requirement: O sistema DEVE gerar um Rascunho Visual
O sistema DEVE (MUST) delegar a exportação e impressão da versão resumida A4 em PDF integralmente para a folha de estilos `@media print` do documento XHTML contido no pacote `.epub` e servida na página web pública (`https://fixalog.app/v/:id`), sem manter geradores locais duplicados de arquivos PDF no aplicativo móvel.

#### Scenario: Geração do PDF Resumido para protocolo
- **WHEN** o usuário aciona a opção discreta de exportar/imprimir PDF na visualização web do relatório (`https://fixalog.app/v/:id` ou `/v/:id/pdf`)
- **THEN** o navegador formata o documento em layout A4 de impressão (`@media print`) exibindo o cabeçalho institucional com QR Code canônico, substituindo vídeos por seus *poster frames* com QR Codes individuais e ocultando a barra de navegação web

### Requirement: O sistema DEVE manter cache do PDF Resumido gerado sob demanda
O aplicativo móvel NÃO DEVE (MUST NOT) gerar ou armazenar arquivos `.pdf` derivados de relatórios localmente no dispositivo, mantendo exclusivamente o pacote `.epub` assinado (`SubmissionRecord.epubPath`) e o manifesto estruturado (`SubmissionRecord.protobufPath`) no armazenamento local.

#### Scenario: Compartilhamento subsequente do PDF já gerado
- **WHEN** um relatório é gerado e assinado no aplicativo móvel
- **THEN** o sistema persiste apenas o pacote `.epub` assinado e disponibiliza a exportação para PDF através do link web público no navegador

#### Scenario: Invalidação do cache de PDF ao re-gerar o relatório EPUB
- **WHEN** um relatório existente é re-editado e re-gerado no aplicativo
- **THEN** o sistema atualiza o pacote `.epub` assinado e garante que `pdfPath` permaneça vazio no registro local

### Requirement: Concatenação dos Relatórios de Materiais no PDF Resumido da Manutenção
Ao renderizar na web (`https://fixalog.app/v/:id`) uma manutenção que utiliza materiais cadastrados em `OEBPS/materiais/<uuid>/OEBPS/relatorio.xhtml`, o sistema DEVE (MUST) incluir ao final do documento as seções completas correspondentes aos relatórios de cada material utilizado para que a exportação/impressão em PDF pelo navegador (`@media print`) produza um documento único contendo a manutenção seguida das fichas completas dos materiais vinculados.

#### Scenario: Exportação de PDF único contendo manutenção e materiais anexos
- **WHEN** o usuário aciona a impressão/exportação para PDF no navegador em um relatório de manutenção com materiais vinculados
- **THEN** a versão impressa inclui nas primeiras páginas o relatório da manutenção e nas páginas seguintes as fichas completas de todos os materiais utilizados extraídas do próprio `.epub`
