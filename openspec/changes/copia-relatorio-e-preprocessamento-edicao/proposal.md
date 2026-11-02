# Proposal

## Why

Ao reabrir um relatório em progresso ou editar um relatório antigo no Wizard, mídias cujo pré-processamento em segundo plano tenha sido interrompido (ou que pertençam a versões anteriores sem miniaturas `_thumb.jpg` / `_poster.jpg`) só passam a ser processadas na geração final, desperdiçando o tempo em que o usuário está revisando o formulário. Além disso, mantenedores e fabricantes frequentemente precisam cadastrar materiais similares (mesma nota fiscal, lote ou etapas de fabricação) ou manutenções em vias do mesmo setor, mas hoje precisam preencher e anexar tudo do zero por não existir uma opção de duplicar relatórios existentes no Histórico.

## What Changes

- **Pré-processamento em Segundo Plano ao Carregar Sessão (`loadSession`)**:
  - Atualizar `WizardStateController.loadSession` para inspecionar todas as mídias referenciadas nas respostas da sessão carregada (fotos, vídeos e documentos PDF) e disparar em segundo plano (`unawaited`) a verificação/processamento via `MediaCompressorService`, garantindo que qualquer artefato ausente (`.webp`, `_thumb.jpg`, `.mp4`, `_poster.jpg`) já seja preparado enquanto o usuário edita o relatório.
- **Cópia de Relatório Existente no Histórico ("Criar cópia")**:
  - Adicionar a opção **"Criar cópia"** no menu de 3 pontinhos (`PopupMenuButton`) de cada item na `HistoryScreen`, disponível tanto para registros `GERADO` quanto `EM PROGRESSO`, nas abas `MANUTENÇÕES` e `MATERIAIS`.
  - Implementar a clonagem de sessão (`duplicarSessao` / `clonarSessao`), criando um novo `sessionId` e copiando todos os arquivos de mídia do bundle original (originais `_original.*` e pré-processados `.webp`, `_thumb.jpg`, `.mp4`, `_poster.jpg`, ignorando `.epub`/`.pdf` finais da sessão antiga e `.tmp`) para o novo diretório `/sessoes/<novoSessionId>/`.
  - Ajustar automaticamente o nome/título do registro copiado (`via_nome`, `nome_via`, `mat_nome` e `tituloExibicao`) com sufixo incremental inteligente: `<Base> (Cópia)`, `<Base> (Cópia 2)`, `<Base> (Cópia 3)`, etc., verificando os títulos já existentes no banco local para evitar colisões.
  - Atualizar automaticamente para a data de hoje (`DD/MM/YYYY`) os campos configurados com `preencher_data_atual: true` (como `mat_data`).
  - Exibir um modal intermediário de carregamento com `CircularProgressIndicator` enquanto a cópia é concluída em segundo plano e, ao finalizar, abrir imediatamente o `WizardScreen` carregado na nova sessão (`EM_PROGRESSO`).

## Capabilities

### New Capabilities

### Modified Capabilities
- `media-compressor`: Disparo automático do pré-processamento em segundo plano também ao abrir uma sessão existente para edição ou retomada (`loadSession`), processando apenas mídias cujos artefatos finais ainda não existam em disco.
- `history-tracking`: Ação "Criar cópia" no menu de opções do Histórico (para manutenções e materiais, gerados ou em progresso), com clonagem isolada de manifesto e mídias, sufixo incremental `(Cópia)` / `(Cópia N)`, atualização da data atual e abertura imediata no Wizard.

## Impact

- `app/lib/features/wizard/controllers/wizard_state_controller.dart` (disparo de pré-processamento em `loadSession` e rotina de clonagem/duplicação de sessão com sufixo incremental e data atual).
- `app/lib/core/services/session_bundle_manager.dart` (cópia de arquivos de mídia entre diretórios de sessão).
- `app/lib/features/home/views/history_screen.dart` (opção "Criar cópia" no `PopupMenuButton`, diálogo de progresso e navegação imediata para o `WizardScreen`).
- Testes espelhados 1:1 em `app/test/`.
