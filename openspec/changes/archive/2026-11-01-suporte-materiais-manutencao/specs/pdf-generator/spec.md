## ADDED Requirements

### Requirement: Concatenação dos Relatórios de Materiais no PDF Resumido da Manutenção
Ao gerar o documento PDF Resumido de uma manutenção que utiliza materiais cadastrados, o sistema DEVE anexar ao final do mesmo arquivo PDF, logo após o relatório da manutenção, as seções completas correspondentes aos relatórios de cada material utilizado (incluindo seus dados técnicos, notas fiscais, testes de qualidade, detalhes de fabricação e QR Codes de vídeos).

#### Scenario: Exportação de PDF único contendo manutenção e materiais anexos
- **WHEN** o usuário solicita a geração ou compartilhamento do PDF Resumido de uma manutenção com materiais vinculados
- **THEN** o sistema produz um único arquivo PDF contendo nas primeiras páginas o relatório da manutenção e nas páginas seguintes as fichas completas de todos os materiais utilizados
