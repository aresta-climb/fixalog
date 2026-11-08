# Design

## Context

Consulte `proposal.md` para a motivação completa. Atualmente:
- O protocolo de manutenção (`manutencao_ferragens.yaml`) exige um Bloco 1 obrigatório (`lista_materiais_c`) e depois filtra essa lista dentro das ações (`ia_sub_rf_materiais`, `ia_sub_nl_materiais`, `np_materiais`) com `origem_catalogo: false`.
- `EpubDocumentBuilder.extrairUuidsMateriaisReferenciados` e `PdfPrintSummaryService._formatarTextoReferenciaMaterial` verificam apenas `chave == 'lista_materiais_c' || chave.startsWith('ref_mat')`, dependendo da existência do Bloco 1 para descobrir os materiais usados nas ações.
- `abertura_vias.yaml` (`id: abertura_via_v1`) e `inspecao_visual.yaml` (`id: inspecao_visual_v1`) são protótipos iniciais de 3 a 4 campos soltos.
- `registro_expresso.yaml` não coleta título nem data e separa itens de foto e vídeo (`acao_foto` e `acao_video`).
- `WizardStateController.loadSession` contém condicionais ad-hoc (`if (yamlStr.contains('SIGNATURE') || ...)`) para atualizar sessões antigas.

## Goals / Non-Goals

**Goals:**
- Eliminar condicionais de versões legadas espalhadas em `WizardStateController`, `EpubDocumentBuilder` e `PdfPrintSummaryService` centralizando toda evolução de protocolo em `MigradorProtocoloRegistro`.
- Garantir por contrato automatizado em testes que qualquer alteração estrutural em `app/assets/protocols/*.yaml` exija incremento da versão inteira (`versao: N`) e registro do passo de migração `(N-1) -> N`.
- Padronizar as chaves de referência a materiais (`ref_mat_*`) e de metadados básicos (`via_nome`, `via_data`, `via_gps`) em todos os workflows de vistoria.
- Preservar intactos os pacotes `.epub` já assinados digitalmente (`status == GERADO`) quando apenas visualizados ou exportados, aplicando a migração apenas ao carregar uma sessão no Wizard (rascunho, edição ou duplicação).

**Non-Goals:**
- Alterar o schema binário Protobuf (`wizard.proto` ou `registro.proto`): o campo `versao` e `versao_protocolo` permanece `string` no wire format Protobuf para compatibilidade binária, armazenando a representação textual do inteiro (`"1"`, `"2"`, `"3"`).
- Modificar os campos ou a estrutura do `cadastro_material.yaml` (apenas normalizar sua declaração `versao: 1`).

## Decisions

### 1. Versionamento Inteiro Sequencial nos Protocolos YAML
- **Decisão**: O campo `versao` nos arquivos YAML passa a ser um número inteiro sequencial (`1`, `2`, `3`...). `ProtocolParser` converte `m['versao']?.toString()` e expõe um utilitário `ProtocolParser.extrairVersaoInteira(String versaoBruta)` que retorna `int.tryParse(versaoBruta.trim()) ?? 1` (convertendo qualquer string semver legada como `"1.0.0"` ou `"2.1.0"` na versão base `1`).
- **Alternativa considerada**: Manter semver (`"2.1.0"`). Rejeitada porque protocolos de formulário evoluem linearmente e números inteiros sequenciais permitem iterar deterministicamente `for (var v = versaoOrigem; v < versaoAlvo; v++)` para executar os migradores intermediários sem ambiguidade.

### 2. Arquitetura do `MigradorProtocoloRegistro` em Cadeia (`v -> v + 1`)
- **Decisão**: Criar a biblioteca independente `app/lib/core/services/migrador_protocolo_registro.dart` (com teste espelhado `app/test/core/services/migrador_protocolo_registro_test.dart`).
- **Funcionamento**:
  1. **Normalização de ID de Protocolo**: Mapeia IDs legados para o ID canônico atual:
     - `'manutencao_ferragens'` -> `'manutencao'`
     - `'abertura_via_v1'` -> `'abertura_vias'`
     - `'inspecao_visual_v1'` -> `'inspecao_visual'`
     - `'registro_expresso'` -> `'registro_expresso'`
     - `'cadastro_material'` -> `'cadastro_material'`
  2. **Limpeza Universal**: Remove chaves obsoletas de assinatura manuscrita (`assinatura_c`, `mat_assinatura_c`) caso presentes.
  3. **Execução em Cadeia**: Compara `versaoRegistro = extrairVersaoInteira(registro.versaoProtocolo)` com a `versaoAtual` do protocolo YAML canônico. Enquanto `versaoRegistro < versaoAtual`, executa a função registrada `migradoresPorProtocolo[idCanonico][versaoRegistro]!(registro)` e incrementa `versaoRegistro`. Ao final, atualiza `registro.idProtocolo = idCanonico`, `registro.versaoProtocolo = '$versaoAtual'` e `registro.yamlConteudo = yamlAtual`.
  4. **Migradores `1 -> 2` dos 4 Workflows**:
     - `manutencao` (`1 -> 2`): Remove `lista_materiais_c` de `registro.respostas`; nos itens de `registro.listas`, renomeia `ia_sub_rf_materiais` -> `ref_mat_reusar_furo`, `ia_sub_nl_materiais` -> `ref_mat_novo_local` e `np_materiais` -> `ref_mat_novo_ponto`; preenche `via_data` a partir de `utcTimestampInicio` se ausente.
     - `abertura_vias` (`1 -> 2`): Em `registro.respostas`, renomeia `nome_via` -> `via_nome`, `graduacao` -> `via_graduacao`, `setor_gps` -> `via_gps`, `foto_linha` -> `via_foto_linha`; preenche `via_data` a partir de `utcTimestampInicio` se ausente.
     - `inspecao_visual` (`1 -> 2`): Preenche `via_data` a partir de `utcTimestampInicio`; se existirem respostas de nível raiz do formato v1 (`estado_geral`, `corrosao`, `foto_evidencia`), move-as para um item `GrupoRepetido` (`idLista: 'lista_inspecao_c'`, `idTipo: 'protecao_ancoragem'`) mapeando `iv_pa_posicao: 'Proteção 1'`, `iv_pa_estado`, `iv_pa_corrosao` e `iv_pa_midia`.
     - `registro_expresso` (`1 -> 2`): Preenche `via_data` a partir de `utcTimestampInicio`; converte itens de `lista_fotos` (`acao_foto` / `acao_video`) para `lista_evidencias` (`idTipo: 'item_evidencia'`), unificando as chaves `foto` e `video` em `ev_midia` e `descricao` em `ev_descricao`.

### 3. Trava Dupla Automática de Contrato nos Testes
- **Decisão**: No `MigradorProtocoloRegistro`, declarar o mapa constante `assinaturasEstruturaisVersaoAtual` (contendo para cada protocolo canônico sua versão inteira atual e a assinatura canônica SHA-256 calculada sobre a árvore de IDs e tipos dos blocos/steps/conteúdos/opções/ramos do YAML).
- **Validação nos testes (`migrador_protocolo_registro_test.dart`)**:
  - **Trava A (Schema vs. Versão)**: Lê todos os arquivos `.yaml` em `app/assets/protocols/`, calcula a assinatura estrutural de cada um e verifica se coincide com a assinatura registrada para aquela versão inteira. Se alguém alterar um campo no YAML sem atualizar a versão, o teste falha.
  - **Trava B (Completude da Cadeia)**: Para cada protocolo com `versaoAtual > 1`, verifica que existem migradores registrados para todas as versões `1` até `versaoAtual - 1` sem lacunas e exercita a migração completa de `v1` até `vAtual`.

### 4. Padronização de Chaves `ref_mat_*` e Compilação no EPUB 3 / PDF
- **Decisão**: Todos os campos `StepRefMateriais` nos protocolos YAML passam a usar IDs iniciados por `ref_mat_` (`ref_mat_reusar_furo`, `ref_mat_novo_local`, `ref_mat_novo_ponto`, `ref_mat_outro`, `ref_mat_protecao`, `ref_mat_parada`, `ref_mat_expresso`).
- `EpubDocumentBuilder` e `PdfPrintSummaryService` continuam reconhecendo `chave.startsWith('ref_mat')` (mantendo `chave == 'lista_materiais_c'` apenas para leitura direta de EPUBs antigos já gerados). Assim, `EpubDocumentBuilder.extrairUuidsMateriaisReferenciados(registro)` coleta automaticamente todos os materiais selecionados dentro de qualquer ação do relatório.

## Risks / Trade-offs

- **[Risco] Relatórios `GERADO` antigos abertos apenas para leitura no visualizador** -> **Mitigação**: A visualização de relatórios concluídos lê o arquivo `relatorio.epub` já assinado sem invocar o `WizardStateController`, preservando a assinatura XML-DSig original. A migração só ocorre quando o usuário edita, continua um rascunho ou duplica o relatório.
- **[Risco] Sincronização de diretórios de sessão legados com `idProtocolo == 'manutencao_ferragens'`** -> **Mitigação**: `BancoDadosLocal` e `WizardStateController` reconhecem o mapeamento canônico via `MigradorProtocoloRegistro`, exibindo o título e protocolo corretos no Histórico.

## Migration Plan

1. Implementar e testar `MigradorProtocoloRegistro` com suporte ao versionamento inteiro e às migrações `1 -> 2` de `manutencao`, `inspecao_visual`, `abertura_vias` e `registro_expresso`.
2. Atualizar `ProtocolParser` para suportar `versao` inteira ou string no YAML.
3. Criar `manutencao.yaml` (removendo `manutencao_ferragens.yaml`) e atualizar `inspecao_visual.yaml`, `abertura_vias.yaml`, `registro_expresso.yaml` e `cadastro_material.yaml`.
4. Integrar `MigradorProtocoloRegistro` em `WizardStateController.loadSession`, unificar o rótulo de mídia em `WizardScreen` e reordenar os cards em `NewProtocolScreen`.
