## Why

Atualmente, o Fixalog gera pacotes periciais `.epub` (EPUB 3 assinado digitalmente com ECDSA `secp256r1` via XML-DSig X.509) e sumários executivos `.pdf` com QR Codes apontando para `https://fixalog.app/v/<id>`, além de exibir um ícone estático de nuvem (`Icons.cloud_done_outlined`) na tela de histórico (`HistoryScreen`). Contudo, não existe sincronização real com a nuvem nem infraestrutura no domínio `fixalog.app`: os QR Codes impressos nos laudos levam a URLs inexistentes, o campo `enviadoNuvem` (`enviado_nuvem` no SQLite) permanece sempre `false` e o usuário perde o histórico de laudos e materiais caso troque ou perca o aparelho.

Precisamos implementar o ecossistema completo de autenticação criptográfica, backup/sincronização em segundo plano e visualização/compartilhamento web de laudos periciais em `https://fixalog.app`, integrando o aplicativo Flutter (`fixalog`) à infraestrutura de borda na Cloudflare (`../aresta_backend/cloudflare/fixalog`) e aos contratos compartilhados (`../aresta_backend/aresta_api`), garantindo custódia criptográfica *zero-knowledge* (estilo OpenPubkey), versionamento imutável de relatórios, armazenamento sem duplicação no R2 com leitura parcial por *Byte-Range* e moderação rigorosa de mídia (CSAM e NSFW) em múltiplas camadas.

## What Changes

- **Onboarding Obrigatório com Login Social (Google e Apple) e Identidade Criptográfica estilo OpenPubkey**:
  - Exigir login no onboarding inicial do aplicativo utilizando o mesmo projeto Supabase do Aresta Climb (`../aresta_app`), exclusivamente via **Sign in with Google** e **Sign in with Apple** (`signInWithIdToken`, sem suporte a Magic Link/código por e-mail).
  - Gerar o par de chaves ECDSA (`secp256r1`) localmente no dispositivo e persisti-lo no `FlutterSecureStorage` com backup criptografado ponta-a-ponta nativo do sistema operacional habilitado (`iCloud Keychain` no iOS com `synchronizable: true` e `Encrypted AutoBackup` no Android), garantindo que a chave privada **jamais** saia do dispositivo para nossos servidores.
  - Vincular matematicamente a chave pública ECDSA do dispositivo à identidade OIDC durante o login social passando `rawNonce = sha256(chave_publica_pem)` para o provedor (Google/Apple), que assina `nonce = sha256(rawNonce)` dentro do `idToken` JWT (`atestado_oidc_jwt`). Esse atestado assinado pelo Google/Apple, somado à validação do **Firebase App Check**, comprova matematicamente que o par de chaves pertence ao titular da conta em um dispositivo autêntico.
  - Sincronizar Nome e Clube/Associação (`nome`, `clube_associacao`) com a conta do usuário sem invalidar o par de chaves criptográficas caso o usuário atualize seu nome ou clube.

- **Versionamento Imutável de Relatórios (`v1`, `v2`, ...) sem Trava de Chave Perdida**:
  - Substituir qualquer sobrescrita destrutiva por **versionamento imutável**: cada envio de um laudo novo ou re-editado gera uma nova versão sequencial imutável (`v1`, `v2`, `v3`... armazenada como `laudos/<id_sessao>/v<N>.epub`).
  - Permitir que a mesma conta autenticada (`user_id`) publique novas versões de um laudo mesmo que tenha trocado de ecossistema (ex.: Android para iOS) e gerado uma nova chave ECDSA local, preservando todas as versões anteriores assinadas e auditáveis.

- **Limite de 60 Segundos para Vídeos, Seletor de Trecho (`SeletorTrechoVideoDialog`) e Keyframes Garantidos**:
  - Definir duração máxima de **60 segundos (1 minuto)** por vídeo anexado ao laudo (~4,8 MB por vídeo em H.264 720p 30fps CRF 26).
  - Unificar o fluxo de captura pela câmera (`ImageSource.camera`, sem interromper abruptamente a gravação aos 60s e mantendo o salvamento do vídeo bruto integral na galeria do aparelho) e seleção da galeria (`pickMultipleMedia`): se o vídeo tiver `<= 60s`, segue direto para transcodificação; se tiver `> 60s`, abre o modal `SeletorTrechoVideoDialog` para o usuário escolher a janela de até 60s desejada.
  - Atualizar `VideoTranscoderService` para receber o intervalo opcional (`-ss <inicio> -t <duracao>`) e forçar `-g 300` (garantindo exato 1 *I-Frame / keyframe* a cada 10 segundos a 30fps).

- **Âncoras de Vídeo e Metadados de Atestado OIDC no EPUB 3**:
  - Adicionar `id="video-<uuid>"` nos containers `<div class="container-video">` gerados pelo `EpubDocumentBuilder` (`relatorio.xhtml`), permitindo que os QR Codes do sumário em PDF (`https://fixalog.app/v/<id>#video-<uuid>`) rolem diretamente até o vídeo correspondente.
  - Incluir o `atestado_oidc_jwt` nos metadados empacotados e assinados do `.epub`.

- **Fila de Sincronização em Segundo Plano, Restauração de Conta e Compartilhamento Web**:
  - Implementar serviço de sincronização automática em segundo plano que envia primeiro os pacotes `.epub` de materiais pendentes referenciados pelo laudo e, em seguida, o `.epub` da manutenção/abertura, atualizando `enviadoNuvem = true` no SQLite local.
  - Restaurar automaticamente os laudos e materiais do usuário a partir da nuvem ao fazer login em um novo dispositivo.
  - Corrigir a `HistoryScreen` para refletir fielmente o estado real de `record.enviadoNuvem` (diferenciando laudos apenas locais dos já sincronizados na nuvem) e adicionar ações de sincronização manual e compartilhamento do link web (`https://fixalog.app/v/<id>`) na `VisualizadorRelatorioScreen` e `HistoryScreen`.

- **Infraestrutura Cloudflare (`fixalog.app`) com Leitura Parcial por Byte-Range no R2 e D1 Compartilhado**:
  - Especificar o contrato OpenAPI (`../aresta_backend/aresta_api/openapi/fixalog.yaml`) e migrações SQL no banco Cloudflare D1 compartilhado com o Aresta (`aresta-catalogo`), criando as tabelas `laudos_fixalog` (com coluna opcional `escalada_uid` para futuros *joins* com o catálogo de vias), `versoes_laudo_fixalog` e `chaves_usuario_fixalog`.
  - Implementar o Worker `../aresta_backend/cloudflare/fixalog` conectado ao bucket R2 dedicado (`fixalog-laudos`), armazenando **apenas o arquivo `.epub` único por versão** (`laudos/<id>/v<N>.epub`) sem duplicar fotos ou vídeos.
  - Extrair no upload o diretório central ZIP do `.epub` (`indices_zip_json`, aproveitando que mídias são empacotadas com `CompressionType.none` / `STORE`) e servir fotos e *streaming* de vídeos (`.mp4` com suporte a HTTP `Range`) diretamente de dentro do `.epub` via leituras parciais no R2 (`BUCKET.get(key, { range: { offset, length } })`), com cache imutável na CDN da Cloudflare.
  - Renderizar em `https://fixalog.app/v/:id` o visualizador web do laudo com barra superior de verificação criptográfica (status da assinatura ECDSA, nome/clube, *fingerprint* da chave pública, total de laudos assinados por aquela chave consultado em tempo real no D1, seletor de versões `v1..vN`, botões de download do `.epub`/`.pdf` e botão "Denunciar relatório").

- **Gatekeeper de Moderação CSAM e NSFW em 3 Camadas na Borda**:
  - Todo upload entra inicialmente com `status_moderacao = 'em_analise'`, bloqueando a exibição pública do laudo e de suas mídias enquanto a varredura assíncrona (`ctx.waitUntil`) não for concluída com sucesso.
  - Extrair diretamente no Worker todas as fotos `.webp` e **todos os I-Frames dos vídeos `.mp4`** (1 a cada 10s + primeiro e último quadro, via parsing da tabela `moov/stss` e decodificação H.264 WASM no servidor, impedindo falsificação de mosaicos pelo cliente).
  - Submeter cada imagem e quadro extraído a: (1) sub-requisições pela zona `fixalog.app` para varredura pelo **Cloudflare CSAM Scanning Tool** (hashes perceptuais PhotoDNA NCMEC/Interpol) e (2) classificação visual semântica no **Cloudflare Workers AI** (`@cf/meta/llama-3.2-11b-vision-instruct` / `@cf/llava-hf/llava-1.5-7b-hf` com taxonomia Llama Guard `S4: Child Sexual Exploitation` e `S12: Sexual Content`).
  - Aprovar (`status_moderacao = 'ativo'`) apenas se 100% limpo; caso contrário, bloquear imediatamente (`status_moderacao = 'bloqueado'`), colocar o objeto em quarentena/remoção no R2 e disparar alerta imediato para `alertas.arestaclimb.com`.

## Capabilities

### New Capabilities
- `autenticacao-oidc-openpubkey`: Onboarding obrigatório com login Google/Apple via Supabase Auth, geração e backup nativo da chave ECDSA `secp256r1` no `FlutterSecureStorage`, vinculação criptográfica da chave pública no `nonce` do `idToken` OIDC (`atestado_oidc_jwt`), validação Firebase App Check e sincronização de Nome/Clube da conta.
- `sincronizacao-nuvem-laudos`: Fila de upload automático em segundo plano (garantindo envio de `.epub` de materiais antes do laudo de manutenção), versionamento imutável (`v1`, `v2`...), restauração de laudos/materiais ao logar em novo aparelho e compartilhamento do link público `https://fixalog.app/v/<id>`.
- `worker-fixalog-nuvem`: Contrato OpenAPI (`fixalog.yaml`), tabelas no D1 compartilhado (`aresta-catalogo`), Cloudflare Worker (`cloudflare/fixalog`) com armazenamento sem duplicação no R2 (`fixalog-laudos`), streaming de mídias via *Byte-Range* interno do `.epub`, página web `fixalog.app/v/:id` com barra de verificação criptográfica e histórico de versões, e *gatekeeper* de moderação CSAM/NSFW em 3 camadas com extração de *I-Frames* no servidor e canal de denúncias.

### Modified Capabilities
- `media-compressor`: Limite máximo de 60 segundos por vídeo, seletor visual de trecho (`SeletorTrechoVideoDialog`) para vídeos de câmera ou galeria acima de 60s (preservando o vídeo original completo no rolo da câmera), corte via FFmpeg (`-ss` / `-t`) e inserção obrigatória de `-g 300` (1 *I-Frame* a cada 10 segundos).
- `epub3-report`: Inclusão do atributo `id="video-<uuid>"` nos containers de vídeo do `relatorio.xhtml` para navegação direta via QR Code (`#video-<uuid>`) e inclusão do `atestado_oidc_jwt` nos metadados assinados do pacote `.epub`.
- `history-tracking`: Exibição fiel do status real de sincronização em nuvem (`enviadoNuvem`) nos cards da `HistoryScreen`, botão de sincronização manual e ação rápida de compartilhamento do link `https://fixalog.app/v/<id>`.

## Impact

- **Aplicativo Flutter (`fixalog/app`)**:
  - `app/lib/features/identity/` e `app/lib/core/services/crypto_service.dart`: Integração com `supabase_flutter`, `google_sign_in`, `sign_in_with_apple` e `firebase_app_check`; cálculo do `rawNonce = sha256(public_key_pem)` no login OIDC; persistência de `atestado_oidc_jwt` e configuração `synchronizable: true` no `FlutterSecureStorage`.
  - `app/lib/features/media/` e `app/lib/features/wizard/`: Novo widget `SeletorTrechoVideoDialog`, inspeção de duração de vídeo pós-captura/seleção e parâmetros `-ss`, `-t` e `-g 300` no `VideoTranscoderService`.
  - `app/lib/core/services/epub_document_builder.dart` e `xml_dsig_signer.dart`: Âncora `id="video-<uuid>"` no XHTML e inclusão do `atestado_oidc_jwt`.
  - `app/lib/core/services/sincronizador_nuvem_service.dart` (novo), `app/lib/features/home/views/history_screen.dart` e `app/lib/features/pdf_generation/views/visualizador_relatorio_screen.dart`: Fila offline-first de upload/download, indicadores reais de sincronização e compartilhamento de link.
- **Contratos e Backend (`../aresta_backend`)**:
  - `../aresta_backend/aresta_api/openapi/fixalog.yaml` e schemas SQL D1 (`laudos_fixalog`, `versoes_laudo_fixalog`, `chaves_usuario_fixalog` no banco `aresta-catalogo`).
  - `../aresta_backend/cloudflare/fixalog`: Novo Cloudflare Worker com bindings para R2 (`fixalog-laudos`), D1 (`aresta-catalogo`), Workers AI (`AI`) e serviço de alertas (`alertas.arestaclimb.com`).
