# Roteiro de Integração de Infraestrutura: aresta_app ➔ fixalog

Este documento define o planejamento estratégico e arquitetural para o reaproveitamento e integração de infraestrutura comprovada do ecossistema **Aresta Climb** (`aresta_app/frontend`) para o **Fixalog** (`fixalog/app`).

A estratégia segue estritamente os princípios de engenharia definidos no [PRINCIPIOS.md](../PRINCIPIOS.md):
- **I. Tudo em Português**: Documentação, código, testes e entidades em português brasileiro.
- **II. Library-First**: Funcionalidades isoladas, autossuficientes e modulares.
- **III. 100% Unit Test Coverage**: Cobertura integral de testes unitários em cada etapa.
- **IV. TDD (Test-Driven Development)**: Testes escritos e estruturados no ciclo Red-Green-Refactor.
- **V. Simplicidade e Anti-Abstração**: Práticas diretas, sem complexidade desnecessária.

---

## 🗺️ Mapa de Execução em 3 Etapas

```
┌─────────────────────────────────────────────────────────────────────────┐
│ ETAPA 1: Termos de Uso e Governança Jurídica (termos-de-uso-fixlog)     │
├─────────────────────────────────────────────────────────────────────────┤
│ • Submódulo Git legal/repo apontando para o repositório central         │
│ • Documentos dedicados: termos-de-uso-fixlog.md e                      │
│   politica-de-privacidade-fixlog.md                                     │
│ • Utilitário CLI tool/legal_updater para hash SHA-256 e versionamento   │
│ • Workflow CI/CD .github/workflows/update_legal_terms.yml               │
│ • Tela de consentimento inicial em Markdown + Auditoria no Isar         │
│ • 100% de cobertura de testes unitários                                 │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ ETAPA 2: Monitoramento e Telemetria Firebase (setup-firebase-fixlog)    │
├─────────────────────────────────────────────────────────────────────────┤
│ • Projeto dedicado no Firebase: com-arestaclimb-fixlog                  │
│ • RegistroLogger (AppLogger) com filtro de exceções de rede na montanha │
│ • Crashlytics focado em falhas críticas de Rust/FFI, FFmpeg e PDFs      │
│ • ServicoTelemetria (TelemetryService) anônimo e ético                  │
│ • ServicoConfiguracaoRemota + VerificadorVersaoApp (AppVersionChecker)  │
│ • Teste arquitetural de isolamento estrito de pacotes Firebase          │
│ • 100% de cobertura de testes unitários com mocks dedicados             │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ ETAPA 3: Aba de Configurações & In-App Feedback Offline                 │
│         (configuracoes-e-feedback-fixlog)                               │
├─────────────────────────────────────────────────────────────────────────┤
│ • Tela definitiva de Configurações (substituindo _SettingsPlaceholder) │
│ • Gestão de Identidade e Chaves Criptográficas do Mantenedor            │
│ • Seção Jurídica: visualização dos termos e data/hora do aceite         │
│ • Seção Comunidade: Links para WhatsApp oficial e Portal Aresta Climb   │
│ • Ferramenta de In-App Feedback com desenho na tela e fila offline      │
│ • 100% de cobertura de testes unitários em widgets e serviços           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Detalhamento das Etapas

### 📄 Etapa 1: Termos de Uso e Governança Jurídica (`termos-de-uso-fixlog`)

O Fixalog lida com auditoria de proteções, responsabilidade técnica, localização precisa (GPS) e fotos/vídeos. Esta etapa estabelece a esteira automatizada de conformidade jurídica.

#### Entregáveis:
1. **Submódulo Git `legal/repo`**:
   - Conecta ao repositório de documentos legais do portal `arestaclimb.com`.
   - Utilização de arquivos dedicados:
     - `public/docs/termos-de-uso-fixlog.md`
     - `public/docs/politica-de-privacidade-fixlog.md`
2. **CLI de Versionamento e Hashes (`tool/legal_updater`)**:
   - Script em Dart que analisa o SHA-256 dos arquivos Markdown do Fixalog.
   - Gera e incrementa `lib/core/constants/versao_legal.g.dart` quando houver alterações de texto.
3. **Automação GitHub Actions (`.github/workflows/update_legal_terms.yml`)**:
   - Sincronização disparada via `repository_dispatch` ou manual.
   - Atualiza o submódulo, roda o `legal_updater` e efetua commit automático.
4. **Interface e Persistência no App**:
   - Substituição do placeholder atual por uma tela de onboarding em Markdown (`flutter_markdown_plus`).
   - Modal inferior para leitura integral da Política de Privacidade.
   - Persistência no Isar (`AppConfigRecord`) da versão aceita e do timestamp com precisão de minutos.
5. **Testes Unitários**:
   - Teste do CLI `legal_updater`.
   - Teste de renderização do Markdown e do fluxo de aceite com o Isar.

---

### 🔥 Etapa 2: Monitoramento e Telemetria Firebase (`setup-firebase-fixlog`)

Estabelece observabilidade em campo para um aplicativo que roda código nativo de baixo nível (Rust FFI, compressão de vídeo/imagem, criptografia e montagem de relatórios em PDF).

#### Entregáveis:
1. **Projeto Firebase Dedicado**:
   - Identificador de projeto: `com-arestaclimb-fixalog`.
   - Isolamento total de métricas, cotas do Plano Spark e regras de Remote Config em relação ao app de croquis.
2. **Camada de Log Resiliente (`RegistroLogger`)**:
   - Captura silenciosa de falhas não-fatais e crashes fatais via Firebase Crashlytics.
   - Filtro inteligente para montanha: erros transitórios de rede (`SocketException`, timeouts, `ClientException`) não geram alarmes de crash fatal.
3. **Serviço de Telemetria (`ServicoTelemetria`)**:
   - Métricas estruturadas de engajamento e performance: tempo de compilação de PDFs no Rust, taxa de sucesso de assinaturas criptográficas, protocolos mais utilizados.
4. **Governança de Versões (`ServicoConfiguracaoRemota` + `VerificadorVersaoApp`)**:
   - Parâmetros: `hard_min_version` (bloqueio de emergência para versões quebradas), `soft_min_version` (aviso de atualização obrigatória) e `recommended_version` (banner informativo).
5. **Isolamento Arquitetural**:
   - Teste unitário obrigatório (`teste_isolamento_firebase.dart`) garantindo que apenas arquivos de serviço acessem os pacotes `firebase_*`.
   - Mocks completos para viabilizar testes sem necessidade de emuladores ou internet ativa.

---

### 💬 Etapa 3: Aba de Configurações & In-App Feedback Offline (`configuracoes-e-feedback-fixlog`)

Transforma a terceira aba da `HomeScreen` (atualmente vazia com `_SettingsPlaceholder`) em uma central completa de governança, suporte e integração com a comunidade.

#### Entregáveis:
1. **Tela de Configurações (`TelaConfiguracoes`)**:
   - **Identidade do Mantenedor**: Nome, chave pública e certificado ativo para assinatura digital de laudos.
   - **Jurídico**: Leitura sob demanda dos Termos de Uso e Política de Privacidade com indicação de data/hora do aceite.
   - **Comunidade Aresta Climb**:
     - Link direto para o Grupo Oficial no WhatsApp: `https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv`
     - Link para o portal: `https://arestaclimb.com`
     - Informações da licença open-source (MPL-2.0).
   - **Sistema e Status**: Versão do app, build number, status do motor nativo em Rust e checagem de atualizações via Remote Config.
2. **Sistema de In-App Feedback Offline**:
   - Integração com a biblioteca `feedback` com suporte a captura de tela e ferramentas de desenho (pincel, marcações).
   - `ColetorMetadadosFeedback`: Coleta modelo do dispositivo, SO, nível de bateria, conectividade e pilha de telas ativas.
   - `FilaFeedbackServico`: Persistência local no Isar para que conquistadores em áreas remotas salvem feedbacks que serão transmitidos assim que o dispositivo recuperar conexão.
3. **Testes Unitários**:
   - Testes de widgets para todos os blocos de configurações.
   - Teste do enfileiramento e despacho do feedback offline.

---

## 📌 Status Atual de Progresso

- [ ] **Etapa 1: `termos-de-uso-fixlog`** ➔ *Próxima etapa a ser iniciada via `/opsx-propose`.*
- [ ] **Etapa 2: `setup-firebase-fixlog`**
- [ ] **Etapa 3: `configuracoes-e-feedback-fixlog`**
