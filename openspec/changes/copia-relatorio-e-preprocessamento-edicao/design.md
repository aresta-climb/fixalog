# Design

## Context

Conforme descrito em `proposal.md`, precisamos:
1. Garantir que o carregamento de qualquer sessão no Wizard (`WizardStateController.loadSession`) verifique todas as mídias referenciadas (fotos, vídeos e documentos PDF) e acione o pré-processamento em segundo plano para qualquer mídia cujos artefatos finais ainda não estejam prontos em disco.
2. Permitir que o usuário crie uma cópia completa de qualquer registro (Manutenção ou Material, `GERADO` ou `EM PROGRESSO`) a partir do menu de 3 pontinhos na `HistoryScreen`, exibindo um diálogo de carregamento enquanto clona o bundle em background e abrindo imediatamente o `WizardScreen` na nova sessão.

## Goals / Non-Goals

**Goals:**
- Disparar automaticamente o pré-processamento assíncrono (`unawaited`) de imagens (`comprimirImagemSessao`), vídeos (`transcodificarVideoSessao`) e documentos PDF (`rasterizarDocumentoPdfSessao`) ao final de `WizardStateController.loadSession`.
- Implementar a clonagem de sessão isolada (`copiarArquivosMidiaSessao` em `SessionBundleManager` e `duplicarSessao` em `WizardStateController`) preservando mídias originais e pré-processadas (sem copiar `.epub`/`.pdf` de relatório final ou `.tmp`).
- Calcular sufixos incrementais `(Cópia)`, `(Cópia 2)`, `(Cópia 3)`... sobre o nome base do registro sem duplicar sufixos aninhados como `(Cópia) (Cópia)`.
- Atualizar campos com `preencher_data_atual: true` (ex.: `mat_data`) para a data atual na sessão duplicada.
- Exibir modal de carregamento na `HistoryScreen` durante a cópia e abrir imediatamente o `WizardScreen` (`isEditing: true`) na sessão recém-criada.

**Non-Goals:**
- Copiar assinaturas criptográficas (`META-INF/signatures.xml`, `hashAssinatura`) ou pacotes `.epub`/`.pdf` compilados da sessão original, pois a cópia nasce como um novo rascunho (`EM_PROGRESSO`).

## Decisions

### 1. Verificação e Disparo de Pré-processamento em `loadSession`
- **Decisão**: Ao concluir a reconstrução de `allAnswers` em `WizardStateController.loadSession(sessionId)`, percorrer todas as entradas de `allAnswers` extraindo `ReferenciaMidia` via `extrairMidiasDeResposta(resposta)` e para cada mídia:
  - Se `hasImagem()`, chamar `unawaited(mediaService.comprimirImagemSessao(...))`.
  - Se `hasVideo()`, chamar `unawaited(mediaService.transcodificarVideoSessao(...))`.
  - Se `hasDocumento()`, chamar `unawaited(mediaService.rasterizarDocumentoPdfSessao(...))`.
- **Racional**: Como `MediaCompressorService` já possui verificação rápida de existência dos arquivos finais em disco, escrita atômica (`.tmp` -> `rename`), deduplicação de `Future`s em andamento e pools limitados por semáforo, essa chamada tem custo praticamente zero quando os arquivos já existem e inicia imediatamente a preparação em background quando algum arquivo está ausente.

### 2. Clonagem de Arquivos de Mídia no `SessionBundleManager`
- **Decisão**: Adicionar o método `copiarArquivosMidiaSessao({required String idSessaoOrigem, required String idSessaoDestino})` em `SessionBundleManager`, que copia todos os arquivos de mídia do diretório `/sessoes/<idSessaoOrigem>/` para `/sessoes/<idSessaoDestino>/`, ignorando:
  - `registro.binarypb` e `registro.json` (pois serão gravados com os dados da nova sessão);
  - Arquivos temporários `*.tmp`;
  - Arquivos de relatório final da sessão antiga (`fixalog_*.pdf` e `fixalog_*.epub`).
- **Racional**: Copiar tanto os arquivos `*_original.*` quanto os derivados já processados (`*.webp`, `*_thumb.jpg`, `*.mp4`, `*_poster.jpg`) garante isolamento completo entre a sessão original e a cópia (excluir uma não afeta a outra) e evita reprocessar mídias que já estavam prontas na sessão de origem.

### 3. Sufixo Incremental `(Cópia)`, `(Cópia 2)`, `(Cópia 3)` e Data Atual em `duplicarSessao`
- **Decisão**: Adicionar `Future<String> duplicarSessao(String idSessaoOrigem)` em `WizardStateController`:
  1. Gera um novo `novoSessionId = const Uuid().v4()`.
  2. Copia os arquivos de mídia do bundle via `sessionManager.copiarArquivosMidiaSessao(...)`.
  3. Carrega a sessão original e, sobre o estado carregado:
     - Identifica a chave de título do protocolo (`via_nome`, `nome_via` ou `mat_nome`) ou o `tituloExibicao` existente.
     - Extrai o nome base removendo eventual sufixo final `\s*\(Cópia(?:\s+\d+)?\)$`.
     - Consulta os registros existentes no Isar (`submissionRecords`) para verificar quais títulos começando com `<Base> (Cópia` já existem:
       - Se `<Base> (Cópia)` ainda não existir, usa `<Base> (Cópia)`.
       - Caso contrário, busca o menor `N >= 2` tal que `<Base> (Cópia N)` não exista.
     - Atualiza a resposta da chave de título (`via_nome` / `mat_nome`) com o novo título calculado.
     - Percorre os passos do protocolo (e dos itens de lista em `state.lists`) para atualizar qualquer `campoSimples` com `preencherDataAtual == true` (como `mat_data`) para a data atual formatada (`DD/MM/YYYY`).
     - Atualiza `state` com `sessionId: novoSessionId`, `currentIndex: 0` e `possuiAlteracoesPendentes: true`, persiste imediatamente via `saveSession(status: SubmissionStatus.emProgresso)` e dispara a verificação de pré-processamento em background.

### 4. Experiência de UI na `HistoryScreen`
- **Decisão**:
  - No `_buildHistoryItem` da `HistoryScreen`, adicionar `PopupMenuItem(value: 'duplicate', child: Text('Criar cópia'))` tanto para itens `isEmProgresso` quanto para itens `GERADO`.
  - Ao selecionar `'duplicate'`, exibir um diálogo modal não-dispensável (`barrierDismissible: false`) com `CircularProgressIndicator` e texto `"Criando cópia do relatório..."`, aguardar `controller.duplicarSessao(record.idSessao)`, fechar o modal de carregamento e navegar imediatamente para `WizardScreen(initialYaml: state.protocolRawYaml, isEditing: true)`.

## Risks / Trade-offs

- **[Risk] Cópia de arquivos de vídeo grandes bloquear o frame da UI** → **Mitigação**: Utilizar cópia assíncrona (`await file.copy(destino)`) em `copiarArquivosMidiaSessao` enquanto o modal com `CircularProgressIndicator` permanece visível e fluido.
