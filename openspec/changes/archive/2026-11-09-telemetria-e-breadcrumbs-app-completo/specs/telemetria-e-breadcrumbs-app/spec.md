# Spec Delta: Telemetria e Breadcrumbs Transversais no Aplicativo Completo

## Purpose

Garante o registro padronizado de eventos analíticos e breadcrumbs de diagnóstico em todas as telas e jornadas do aplicativo (`FixalogApp`), mantendo um buffer circular em memória (`GravadorBreadcrumbs`) das últimas ações do auditor e emitindo trilhas em tempo real para o terminal, Sentry e Firebase.

## ADDED Requirements

### Requirement: Buffer Circular de Breadcrumbs em Memória
O sistema DEVE (MUST) manter um buffer circular FIFO em memória (`GravadorBreadcrumbs`) com capacidade padrão para os últimos 50 eventos disparados pelo `ServicoTelemetria`, armazenando timestamp ISO-8601 UTC, nome do evento e mapa de parâmetros.

#### Scenario: Descarte FIFO ao exceder capacidade máxima
- **WHEN** mais de 50 eventos são registrados no `GravadorBreadcrumbs`
- **THEN** o evento mais antigo é descartado automaticamente e `obterBreadcrumbs()` retorna exatamente os 50 eventos mais recentes em ordem cronológica

### Requirement: Despacho Unificado de Telemetria, Breadcrumb e Log de Terminal
Toda chamada ao `ServicoTelemetria.registrarEvento` DEVE (MUST) registrar o evento no `GravadorBreadcrumbs`, emitir um log informativo via `RegistroLogger.logInfo` (que imprime no console em modo de desenvolvimento/teste e adiciona um breadcrumb no Sentry e no Crashlytics) e despachar ao Firebase Analytics quando inicializado.

#### Scenario: Visibilidade imediata de breadcrumbs durante o Robô Caótico
- **WHEN** o usuário ou o `MotorRoboCaotico` interage com qualquer funcionalidade instrumentada pelo `ServicoTelemetria`
- **THEN** o evento é impresso no terminal via `RegistroLogger.logInfo`, adicionado aos breadcrumbs do Sentry e retido no `GravadorBreadcrumbs`

### Requirement: Instrumentação de Navegação Principal e Fluxo Completo do Wizard
O aplicativo DEVE (MUST) emitir eventos de telemetria e breadcrumbs ao alternar abas na `HomeScreen` (`navegar_aba`), iniciar um protocolo na `NewProtocolScreen` ou `WizardScreen` (`iniciar_protocolo`), avançar ou retroceder etapas (`etapa_wizard`), escolher ramificações (`escolher_ramo_wizard`), manipular itens de `StepListaAcoes` (`acao_lista_wizard`) e anexar mídias ou coordenadas GPS (`acao_midia_wizard`).

#### Scenario: Rastreamento de jornada no Wizard
- **WHEN** o auditor seleciona um protocolo, avança entre etapas, adiciona um item de lista e captura uma mídia
- **THEN** o `ServicoTelemetria` registra cada uma dessas ações em sequência cronológica com o `id_protocolo` e identificadores correspondentes

### Requirement: Instrumentação de Geração de Laudo EPUB 3, Histórico e Visualizador
O aplicativo DEVE (MUST) emitir eventos de telemetria e breadcrumbs ao concluir a geração e assinatura de um laudo no `GenerationNotifier` (`gerar_laudo_epub` com `duracao_ms` e `assinado`), ao interagir com registros na `HistoryScreen` (`acao_historico`) e ao compartilhar, exportar ou publicar relatórios na `VisualizadorRelatorioScreen` (`acao_visualizador_relatorio`).

#### Scenario: Emissão de laudo assinado e visualização
- **WHEN** o auditor finaliza a geração de um relatório EPUB 3 e o abre ou compartilha pelo histórico
- **THEN** o `ServicoTelemetria` registra `gerar_laudo_epub` enriquecido com `duracao_ms`, `tier_dispositivo` e `ram_gb`, seguido de `acao_historico` e `acao_visualizador_relatorio`

### Requirement: Instrumentação de Onboarding, Identidade, Configurações e Sincronização
O aplicativo DEVE (MUST) emitir eventos de telemetria e breadcrumbs no aceite dos Termos de Uso (`aceitar_termos_uso`), no salvamento da identidade técnica (`salvar_identidade`), nas ações da `TelaConfiguracoes` (`acao_configuracoes` incluindo troca de idioma e autenticação OIDC), na abertura de links externos (`link_externo`), nos ciclos do `SincronizadorNuvemService` (`sincronizar_nuvem`) e no fluxo de feedback (`acao_feedback`).

#### Scenario: Troca de idioma nas configurações
- **WHEN** o auditor altera o idioma da interface na `TelaConfiguracoes`
- **THEN** o `ServicoTelemetria` registra `acao_configuracoes` com a ação `alterar_idioma` e o código do novo idioma selecionado
