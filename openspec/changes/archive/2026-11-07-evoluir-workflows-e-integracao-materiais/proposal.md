# Proposal

## Why

Com o catálogo de materiais (`cadastro_material.yaml`) estruturado e completo, os demais workflows de vistoria e campo (`manutencao_ferragens.yaml`, `abertura_vias.yaml`, `inspecao_visual.yaml` e `registro_expresso.yaml`) ficaram defasados: a manutenção exige selecionar materiais duas vezes (em um Bloco 1 obrigatório e novamente em cada ação), a abertura de vias e a inspeção visual ainda são mocks mínimos da versão inicial sem estrutura real de campo, o registro expresso carece de identificação/data e divide fotos e vídeos artificialmente, e a evolução dos protocolos YAML começava a acumular condicionais (`if`s) de legado espalhadas pelo código. Precisamos evoluir e padronizar os 4 workflows de vistoria, permitir a seleção de materiais diretamente dentro das ações pertinentes (compilando-os automaticamente no EPUB 3 e no PDF Resumido), unificar a captura de mídia em todo o aplicativo e instituir um mecanismo determinístico de versionamento inteiro e migração sequencial de protocolos.

## What Changes

- **Reordenação dos Workflows na Tela Inicial (`NewProtocolScreen`)**: Organizar os cards de protocolo na ordem lógica de uso em campo:
  1. **Inspeção Visual de Proteções Fixas** (`assets/protocols/inspecao_visual.yaml`)
  2. **Manutenção de Vias** (`assets/protocols/manutencao.yaml`)
  3. **Abertura de Via** (`assets/protocols/abertura_vias.yaml`)
  4. **Registro Expresso** (`assets/protocols/registro_expresso.yaml`)
  5. **Cadastro de Materiais** (`assets/protocols/cadastro_material.yaml`)
- **BREAKING (com migração automática) — Renomeação e Simplificação da Manutenção (`manutencao.yaml`)**:
  - Renomear `assets/protocols/manutencao_ferragens.yaml` (`id: manutencao_ferragens`) para `assets/protocols/manutencao.yaml` (`id: manutencao`, `versao: 2`).
  - Remover o antigo Bloco 1 obrigatório de pré-seleção de materiais (`lista_materiais_c`), permitindo realizar manutenções sem troca de ferragem (como limpeza de vegetação, remoção de bloco solto ou reaperto/inspeção) sem bloqueio.
  - Adicionar campo de data preenchida automaticamente (`via_data`) na Identificação da Via.
  - Configurar os campos `ref_materiais` dentro das ações de manutenção (substituição com reuso de furo, substituição em novo local, novo ponto de ancoragem e opcionalmente em outra ação) com `origem_catalogo: true` e chaves padronizadas `ref_mat_*`, dando acesso direto ao catálogo local e ao botão `+ CADASTRAR NOVO MATERIAL` no ponto exato da intervenção.
- **Transformação da Inspeção Visual em Workflow Completo (`inspecao_visual.yaml`, `versao: 2`)**:
  - Estruturar em 3 blocos completos sem intervenção mecânica e sem recomendação de materiais:
    - Bloco 1 — Identificação da Via: Data (`via_data` automática), GPS obrigatório (`via_gps`), Nome da Via obrigatório (`via_nome`), Setor (`via_setor`) e Pico (`via_pico`).
    - Bloco 2 — Inspeção Ponto a Ponto (`lista_acoes`, mínimo 1): Avaliação individualizada de *Proteção / Ancoragem*, *Parada / Rapel* e *Rocha / Ambiente*, coletando posição/identificação, estado visual, presença de corrosão, observações e mídias de evidência.
    - Bloco 3 — Situação Final da Via: Condição final para escalada (*Liberada*, *Liberada com restrição*, *Interditada*) e resumo geral da inspeção.
- **Transformação da Abertura de Vias em Workflow Completo com Materiais (`abertura_vias.yaml`, `versao: 2`)**:
  - Estruturar em 3 blocos completos:
    - Bloco 1 — Identificação da Nova Via: Data (`via_data` automática), GPS da base obrigatório (`via_gps`), Nome da Via obrigatório (`via_nome`), Conquistador(es) (`via_conquistadores`), Graduação proposta (`via_graduacao`), Extensão/Enfiadas (`via_extensao`), Setor (`via_setor`), Pico (`via_pico`) e Mídia da Linha/Croqui obrigatória (`via_foto_linha`).
    - Bloco 2 — Proteções Instaladas e Ações na Conquista (`lista_acoes`, mínimo 1): *Proteção Fixa Instalada* e *Parada / Rapel Instalado* (ambos vinculando materiais diretamente do catálogo via `ref_mat_*` com `origem_catalogo: true` e botão de cadastro sob demanda, além de mídia após instalação e observações), *Remoção de Bloco Solto*, *Limpeza de Vegetação* e *Outra Ação* (com `ref_mat_*` opcional).
    - Bloco 3 — Avaliação e Encerramento: Condição da via (*Liberada para escalada*, *Em conquista / Projeto em aberto*, *Liberada com restrição*) e equipamento sugerido para repetição / comentários.
- **Evolução do Registro Expresso como Catch-All Completo (`registro_expresso.yaml`, `versao: 2`)**:
  - Adicionar Identificação Geral com Título/Identificação obrigatório (`via_nome`, para exibição clara no Histórico), Data automática (`via_data`), GPS opcional (`via_gps`) e Observações gerais (`observacoes_gerais`).
  - Unificar a lista de evidências em um único tipo de item que recebe mídias unificadas (fotos, vídeos e PDFs) e descrição em Markdown, além de incluir seleção opcional de materiais do catálogo (`ref_mat_expresso`, `origem_catalogo: true`, `obrigatorio: false`).
- **Unificação da Experiência de Mídia e Compilação de Materiais no App**:
  - Padronizar todos os campos de mídia no `WizardScreen` para apresentar ação e rótulo unificados (`ADICIONAR MÍDIA` — `Fotos, vídeos ou PDFs`).
  - Atualizar `EpubDocumentBuilder` e `PdfPrintSummaryService` para extrair e linkar automaticamente todos os materiais referenciados em qualquer campo `ref_mat_*` (raiz ou dentro de itens de lista) ao compilar o pacote `.epub` e o PDF Resumido.
- **Versionamento Inteiro Sequencial e Motor de Migração em Cadeia (`MigradorProtocoloRegistro`)**:
  - Adotar números inteiros sequenciais (`1`, `2`, `3`...) no campo `versao` dos arquivos YAML de protocolo (normalizando strings semver legadas como `"1.0.0"` e `"2.1.0"` para a versão `1`).
  - Criar a biblioteca `MigradorProtocoloRegistro` em `app/lib/core/services/migrador_protocolo_registro.dart` para executar migrações passo a passo (`v -> v + 1`) ao carregar sessões no `WizardStateController` ou sincronizar rascunhos, removendo `if`s de legado espalhados pelo restante do sistema.
  - Implementar travas automáticas na suíte de testes que verificam a assinatura estrutural de cada YAML na versão atual (impedindo alterar campos de um YAML sem incrementar sua versão inteira) e exigem a presença e execução de todos os migradores `1 .. (N-1)` para qualquer protocolo na versão `N`.

## Capabilities

### New Capabilities
- `protocolos-vistoria-e-migracao`: Define a estrutura e ordem dos protocolos de vistoria em campo (`inspecao_visual`, `manutencao`, `abertura_vias`, `registro_expresso`), o versionamento inteiro sequencial dos protocolos YAML e a migração determinística em cadeia (`v -> v + 1`) com verificação automática de integridade de versão e migradores.

### Modified Capabilities
- `unified-wizard-engine`: Atualiza a seleção de materiais (`StepRefMateriais`) para operar diretamente dentro das ações com acesso ao catálogo e criação sob demanda sem depender de bloco prévio, unifica a interface de captura de mídia (fotos, vídeos e PDFs) e delega a compatibilidade retroativa de sessões ao `MigradorProtocoloRegistro`.
- `express-form`: Atualiza o protocolo de Registro Expresso para incluir identificação (`via_nome`), data automática (`via_data`), captura unificada de evidências (fotos, vídeos e PDFs) e referência opcional a materiais do catálogo (`ref_mat_expresso`).
- `epub3-report`: Amplia a extração e incorporação de materiais aninhados (`OEBPS/materiais/<uuid_material>/`) para coletar automaticamente todos os materiais selecionados diretamente dentro das ações (`ref_mat_*`) em qualquer workflow que utilize materiais.

## Impact

- **Protocolos YAML (`app/assets/protocols/`)**:
  - Remoção de `manutencao_ferragens.yaml` e criação de `manutencao.yaml` (`versao: 2`).
  - Reescrita de `inspecao_visual.yaml` (`versao: 2`), `abertura_vias.yaml` (`versao: 2`) e `registro_expresso.yaml` (`versao: 2`).
  - Atualização de `cadastro_material.yaml` para `versao: 1` (inteiro).
- **Serviços Core (`app/lib/core/services/`)**:
  - Novo módulo `migrador_protocolo_registro.dart` (e seu teste espelhado 1:1 `migrador_protocolo_registro_test.dart`).
  - Ajustes em `protocol_parser.dart` (suporte a `versao` inteira no YAML), `epub_document_builder.dart` e `pdf_print_summary_service.dart` (reconhecimento padronizado de `ref_mat_*` em respostas e listas).
- **Wizard e Home (`app/lib/features/`)**:
  - Reordenação e atualização dos cards em `new_protocol_screen.dart`.
  - Integração do `MigradorProtocoloRegistro` em `wizard_state_controller.dart` (removendo os `if`s legados em `loadSession`).
  - Padronização do rótulo de captura de mídia em `wizard_screen.dart`.
