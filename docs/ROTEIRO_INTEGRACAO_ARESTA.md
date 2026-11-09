# Roteiro de Integração de Infraestrutura: aresta_app ➔ fixalog

Este documento define o planejamento estratégico e arquitetural para o reaproveitamento e integração de infraestrutura comprovada do ecossistema **Aresta Climb** (`aresta_app/frontend`) para o **Fixalog** (`fixalog/app`).

A estratégia segue estritamente os 8 princípios de engenharia definidos no [AGENTS.md](../AGENTS.md):
- **I. Tudo em Português com Internacionalização Padronizada (7 idiomas)**
- **II. Modularidade e Desacoplamento (Library-First)**
- **III. Testes Orientados a Comportamento e Espelhamento 1:1 (`test_structure_mirror_test.dart`)**
- **IV. 100% de Cobertura Comportamental e TDD (Red-Green-Refactor)**
- **V. Fidelidade de Produção, Anti-Mocking (`BancoDadosLocal.abrirEmMemoria()` e Fakes Determinísticos Testados)**
- **VI. Simplicidade, Anti-Abstração e Documentação Contínua**
- **VII. Inegociabilidade Perante Código Legado (Regra do Escoteiro)**
- **VIII. Operação Offline-First e Integridade Pericial Criptográfica**

---

## 🗺️ Mapa de Execução das Propostas OpenSpec

```
┌─────────────────────────────────────────────────────────────────────────┐
│ ✅ CONCLUÍDO: Governança Jurídica, SQLite, EPUB 3, OIDC e 7 Idiomas     │
├─────────────────────────────────────────────────────────────────────────┤
│ • Submódulo Git legal/repo em 7 idiomas + TelaTermosDeUso               │
│ • Migração integral do Isar para SQLite (BancoDadosLocal / sqflite)     │
│ • Geração nativa Dart de EPUB 3 + XML-DSig X.509 + OpenPubkey OIDC      │
│ • SincronizadorNuvemService + AutenticacaoNuvemService                  │
│ • Internacionalização 100% offline em 7 idiomas (pt,en,es,fr,de,ar,ja)  │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ PROPOSTA 1: observabilidade-firebase-sentry                             │
├─────────────────────────────────────────────────────────────────────────┤
│ • Projeto Firebase (com-arestaclimb-fixlog) + Sentry (fixalog)          │
│ • RegistroLogger dual com filtro de desconexão de montanha              │
│ • ServicoAppCheck (Play Integrity / App Attest) conectado ao            │
│   AutenticacaoNuvemService e SincronizadorNuvemService                  │
│ • ClassificadorDispositivo com teto dinâmico de imageCache (50–150 MB)  │
│ • ServicoConfiguracaoRemota e ServicoTelemetria com fallbacks offline   │
│ • CI/CD (Android e iOS) com --obfuscate e upload de símbolos no Sentry  │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ PROPOSTA 2: feedback-offline-configuracoes                              │
├─────────────────────────────────────────────────────────────────────────┤
│ • Migração do BancoDadosLocal para schema v3 com tabela fila_feedback   │
│ • In-App Feedback com anotações visuais, compressão e fila SQLite       │
│ • Despacho autenticado com X-Firebase-AppCheck e RegistroLogger         │
│ • TelaConfiguracoes evoluindo a aba atual (mantendo seletor de 7        │
│   idiomas e gestão OIDC) + resumo da chave ECDSA + auditoria de termos  │
│ • Links oficiais: Comunidade WhatsApp e Portal arestaclimb.com          │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ PROPOSTA 3: robo-caotico-wizard                                         │
├─────────────────────────────────────────────────────────────────────────┤
│ • MotorRoboCaotico sobre WidgetTester nos 5 protocolos YAML e 7 idiomas │
│ • Execução com BancoDadosLocal.abrirEmMemoria() e Fakes determinísticos │
│ • EncolhedorCaminhoCrash com Delta Debugging (ddmin)                    │
│ • Suíte regressao_caminhos_test.dart (< 1s por receita no CI)           │
│ • Integração com RegistroLogger anexando receita_robo_caotico           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📌 Status Atual das Propostas OpenSpec

- [x] **Base Arquitetural (`termos-de-uso-fixlog`, `BancoDadosLocal` SQLite, OIDC OpenPubkey, Sincronização EPUB 3, 7 Idiomas)** — *Concluída*
- [ ] **Proposta 1: `observabilidade-firebase-sentry`** — *Pronta e validada para `/openspec-apply-change`*
- [ ] **Proposta 2: `feedback-offline-configuracoes`** — *Pronta e validada para `/openspec-apply-change`*
- [ ] **Proposta 3: `robo-caotico-wizard`** — *Pronta e validada para `/openspec-apply-change`*
