# Princípios de Engenharia Fixalog (`fixalog`)

Para garantir que o nosso código, seja ele escrito por humanos ou por agentes autônomos de IA (como Google Antigravity e OPSX), se mantenha coeso, testável, sustentável e simples, adotamos oito princípios basilares e inegociáveis.

Estes princípios devem guiar toda e qualquer nova implementação, revisão ou refatoração no repositório.

## I. Tudo em Português
Todo o repositório deve **OBRIGATORIAMENTE** ser em português brasileiro. Isso inclui, mas não se limita a: documentação, especificações (OpenSpec), comentários de código, docstrings (`///`), mensagens de erro, nomes de bibliotecas, classes, widgets, funções, métodos e variáveis.
*Exceções:* Nomes de pacotes de terceiros, APIs nativas do Flutter/Dart, termos técnicos consolidados do ecossistema e títulos de seção exigidos em inglês pelo schema do OpenSpec.

## II. Modularidade e Desacoplamento (Library-First)
Toda funcionalidade DEVE começar e ser estruturada como uma biblioteca ou módulo independente.
- As bibliotecas e módulos em `app/lib/core/` e `app/lib/features/` devem ser autossuficientes, testáveis de forma isolada e claramente documentados.
- Evite criar arquivos, classes ou widgets que sirvam apenas para fins puramente organizacionais; cada módulo separado deve ter um propósito funcional claro e uma interface pública coesa.
- Não misture regras de negócios (como geração de EPUB 3, assinatura XML-DSig ou auditoria GPS) em grandes monólitos de UI.

## III. Testes Orientados a Comportamento e Espelhamento 1:1
Os testes devem validar **o que** o código ou widget faz (comportamento), e nunca **como** ele foi implementado internamente.
- **Espelhamento 1:1 Obrigatório**: QUALQUER arquivo `.dart` de produção em `app/lib/` DEVE possuir um arquivo `_test.dart` correspondente em `app/test/` (validado automaticamente por `test_structure_mirror_test.dart`). Se decidimos separar código em um arquivo próprio, ele possui por definição uma interface pública que deve ser testada.
- **Um Teste por Comportamento (Behavior-Driven Testing)**: Cada bloco `test()` ou `testWidgets()` deve verificar um único comportamento ou fluxo observável através da API pública ou interação de UI (seguindo a estrutura *Dado/Quando/Então* ou *Preparar/Agir/Verificar*).
- **Proibição de Change-Detector Tests**: É estritamente proibido escrever testes acoplados à implementação interna (inspecionar estado privado, verificar chamadas de métodos auxiliares internos ou replicar a lógica de produção dentro do asserto). Uma refatoração interna que preserve o comportamento observável nunca deve quebrar os testes.

## IV. 100% de Cobertura Comportamental e TDD (Red-Green-Refactor)
O Desenvolvimento Orientado a Testes (Test-Driven Development) e a cobertura integral são **obrigatórios** e inegociáveis.
- **Ciclo Red-Green-Refactor**: Os testes DEVEM ser escritos e vistos falhar (*Red*) antes do início de qualquer implementação de código de produção (*Green*), seguidos de refatoração (*Refactor*).
- **100% de Unit & Widget Test Coverage via Comportamento**: Qualquer commit submetido no Fixalog deve manter 100% de cobertura de testes atingida exclusivamente exercitando comportamentos reais pela interface pública.
- **Resolução de Cobertura pelo Design**: Se uma linha ou ramificação (`if/else`, `try/catch`) não puder ser alcançada por um teste de comportamento público, **o defeito está no código de produção** (código morto, validação defensiva redundante ou acoplamento direto de I/O). A solução obrigatória é simplificar o código de produção ou remover a ramificação inalcançável — sendo proibido usar mocks internos ou expor métodos privados para forçar cobertura artificial.

## V. Fidelidade de Produção, Anti-Mocking e Testes de Integração em Primeiro Lugar
A suíte de testes deve ser representativa do comportamento real do aplicativo em produção.
- **Testes de Integração e Fronteira em Primeiro Lugar**: Priorize testar as fronteiras e os contratos entre os componentes do sistema (e fluxos de Widget) antes de descer para detalhes isolados.
- **Proibição de Mocks para Código Interno**: É proibido usar `mocktail`, `mockito` ou classes `extends Mock` para isolar classes, provedores Riverpod, modelos Protobuf, geradores de PDF/EPUB ou serviços internos do próprio projeto. Use sempre instâncias reais, containers Riverpod reais e diretórios temporários reais (`Directory.systemTemp`).
- **Bibliotecas `test-only` de Fakes Determinísticos**: Para fronteiras externas (câmera/hardware, GPS, armazenamento seguro, FFmpeg, Isar ou rede), devem ser utilizadas **bibliotecas `test-only` de Fakes determinísticos** em memória (configuráveis inclusive para simular falhas determinísticas de I/O), evitando reimplementar stubs ad-hoc em cada arquivo de teste.
- **Fakes Também São Bibliotecas Testadas**: Toda biblioteca de Fake (`*_fake.dart`) é uma biblioteca de primeira classe e DEVE obrigatoriamente possuir seu próprio arquivo de teste espelhado (`*_fake_test.dart`) garantindo que o Fake cumpre fielmente o contrato real.

## VI. Simplicidade, Anti-Abstração e Documentação Contínua
O código DEVE ser simples, declarativo, bem documentado e fácil de compreender.
- Evite abstrações prematuras e códigos "espertos" (complexidade desnecessária). Siga a regra de ouro: *"Melhor um pouco de duplicação do que a abstração errada."*
- Pratique o DRY (Don't Repeat Yourself) de forma prudente: extraia apenas o que for óbvio e simples para reutilização clara.
- Toda implementação DEVE ser documentada através de **docstrings** (`///` no Dart) explicando *o porquê* (intenção) e atualizando os arquivos `README.md` pertinentes sempre que introduzir novos módulos.

## VII. Inegociabilidade Perante Código Legado (Regra do Escoteiro)
A existência de código ou testes legados no repositório que ainda não sigam integralmente estes padrões **NÃO é desculpa nem precedente** para violá-los.
- Agentes autônomos e desenvolvedores estão proibidos de imitar antipadrões presentes em arquivos vizinhos (como uso de `mocktail`/`mockito`, *change-detector tests* ou identificadores em inglês).
- Sempre que tocar em um arquivo ou módulo existente que viole este `AGENTS.md`, você DEVE refatorar o trecho e os testes afetados para que passem a seguir integralmente estes princípios.

## VIII. Operação Offline-First e Integridade Pericial Criptográfica
O Fixalog é uma ferramenta de auditoria técnica e emissão de laudos periciais em ambientes remotos de montanha:
- **100% Offline-First**: Todas as funcionalidades de coleta, catalogação, compressão de mídia e geração de relatórios devem operar integralmente sem conexão à internet, com persistência local confiável.
- **Verificabilidade e Cadeia de Custódia**: A geração de pacotes periciais (EPUB 3 com assinatura digital XML-DSig X.509, sumários executivos em PDF e metadados Protobuf/GPS) deve preservar estritamente a integridade criptográfica e o determinismo dos artefatos gerados.

---
> **Nota para Agentes Autônomos**: Vocês estão estritamente obrigados a considerar este documento como diretriz de mais alta prioridade ao planejar arquitetura, sugerir refatorações, ou implementar novas rotinas (incluindo o uso do OpenSpec).
