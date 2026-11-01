# Design: Canal de Feedback In-App Offline e Aba de Configurações

## Context

O FixLog é utilizado em montanha onde o contato com desenvolvedores é impossibilitado pela ausência de sinal. O pacote `feedback` do Flutter fornece tela de anotação gráfica, mas exige customização para suportar enfileiramento em banco local e despacho resiliente. Veja a motivação completa em `proposal.md`.

## Goals / Non-Goals

**Goals:**
- Fornecer tela interativa para anotações e comentários sobre capturas de tela.
- Garantir persistência 100% offline no banco SQLite local (`sqflite`) para que nenhum relato se perca sem rede.
- Disponibilizar na Aba de Configurações a auditoria dos termos aceitos (data/hora e versão) e links diretos da comunidade.

**Non-Goals:**
- Criar infraestrutura de backend própria (o envio aponta para a Edge Function existente do ecossistema Aresta ou GitHub webhook).
- Permitir edição de chaves criptográficas na tela de configurações (a identidade é imutável após setup).

## Decisions

### 1. Entidade e Tabela SQLite `FeedbackRecord`
- **Decisão**: Criar o modelo Dart puro `class FeedbackRecord` (com `toMap()` e `fromMap()`) e a tabela correspondente `fila_feedback` no banco local SQLite (`sqflite`) contendo id, texto do relato, caminho da imagem local comprimida, timestamp e flag booleana `enviado` (0/1). Nos testes unitários e de widget, utilizar sempre instâncias SQLite reais em memória (`inMemoryDatabasePath` via `sqflite_common_ffi` com `databaseFactoryFfiNoIsolate`), evitando mocks ou fakes de banco.
- **Por que**: Alinha-se perfeitamente com o Princípio V (Fidelidade de Produção e Anti-Mocking), Princípio VI (Simplicidade, zero `build_runner`) e Princípio VIII (100% Offline-First), permitindo re-tentativas ilimitadas até confirmação de entrega e integração idêntica ao `aresta_app`.

### 2. Wrapper do Pacote de Feedback
- **Decisão**: Envolver o `MaterialApp` principal com o widget `BetterFeedback` configurado com tema escuro e textos estritamente em português brasileiro.
- **Por que**: Permite invocar `BetterFeedback.of(context).show(...)` de qualquer ponto da aplicação (Aba de Configurações, Wizard ou Menu).

### 3. Compressão Local Pré-Armazenamento
- **Decisão**: Redimensionar e comprimir a imagem anotada para resolução máxima de 1280px e qualidade JPEG/WebP 80% antes de gravar no disco.
- **Por que**: Economiza espaço de armazenamento no aparelho do auditor e agiliza a transmissão quando a conexão for lenta ou 3G.

## Risks / Trade-offs

- [Acúmulo de imagens no disco] → O serviço de fila deleta os arquivos de imagem temporários locais após a confirmação bem-sucedida de envio.
- [Conflito de renderização com canvas de assinatura] → O feedback congela a tela renderizada antes de abrir as ferramentas de desenho, sem interagir com estados de formulário ativos.
