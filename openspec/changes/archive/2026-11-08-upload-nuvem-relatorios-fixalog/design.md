# Design

## Context

O Fixalog já compila localmente pacotes periciais `.epub` (EPUB 3 com `OEBPS/relatorio.xhtml`, `OEBPS/dados/registro.binarypb`, mídias em modo `STORE` e assinatura digital ECDSA `secp256r1` em `META-INF/signatures.xml`) e sumários executivos `.pdf` cujos QR Codes apontam para `https://fixalog.app/v/<idSessao>` e `https://fixalog.app/v/<idSessao>#video-<uuid>`. No entanto, o aplicativo ainda utiliza uma identidade meramente local (`IdentitySetupScreen` sem login em nuvem), o campo `SubmissionRecord.enviadoNuvem` nunca é atualizado e o domínio `fixalog.app` não possui um Cloudflare Worker nem armazenamento no R2/D1.

O ecossistema Aresta Climb já opera sobre dois repositórios irmãos:
- `../aresta_app`: Aplicativo Flutter que já integra `supabase_flutter`, `google_sign_in` e `sign_in_with_apple` via `signInWithIdToken`.
- `../aresta_backend`: Monorepo com contratos formais em `aresta_api/` (OpenAPI + SQLite/D1) e Cloudflare Workers em `cloudflare/` (`catalogo`, `previa`, `feedback`, `app-links`), utilizando o banco D1 `aresta-catalogo` e alertas operacionais via `alertas.arestaclimb.com`.

Consulte `proposal.md` para a motivação completa da mudança.

## Goals / Non-Goals

**Goals:**
- Garantir custódia criptográfica *zero-knowledge* real: a chave privada ECDSA (`secp256r1`) nunca sai do dispositivo, sobrevive a trocas de celular do mesmo sistema operacional via backup nativo criptografado (`iCloud Keychain` / `Google AutoBackup`) e é vinculada matematicamente à conta Google/Apple do usuário via `nonce` OIDC (estilo OpenPubkey) + Firebase App Check.
- Eliminar perda de acesso por perda de chave: adotar **versionamento imutável** (`v1`, `v2`, ...) por relatório, permitindo que a mesma conta (`user_id`) publique novas versões mesmo que troque de ecossistema e gere um novo par de chaves.
- Servir relatórios web (`https://fixalog.app/v/:id`), fotos e *streaming* de vídeos (`.mp4` com `HTTP Range`) com **zero duplicação no R2**, lendo fatias de bytes (*Byte-Range*) diretamente de dentro do arquivo `.epub` único armazenado em `fixalog-laudos`.
- Impedir que qualquer mídia ilegal (CSAM) ou imprópria (NSFW) seja servida publicamente por meio de um *gatekeeper* assíncrono (`em_analise` -> `ativo` / `bloqueado`) que extrai fotos e *I-Frames* dos vídeos diretamente no servidor e os submete ao Cloudflare CSAM Scanning Tool e ao Cloudflare Workers AI Vision.
- Manter 100% de fidelidade aos princípios do `AGENTS.md`: código e documentação em PT-BR, *Library-First*, espelhamento 1:1 de testes, 100% de cobertura comportamental via TDD e zero mocks internos (usando SQLite `:memory:` e Fakes determinísticos testados `*_fake.dart` / `*_fake.ts`).

**Non-Goals:**
- Abertura automática de Pull Requests no repositório `aresta_db` quando um laudo com `escalada_uid` for enviado (a coluna `escalada_uid` já ficará pronta no D1, mas o fluxo de PR automático para aprovação de mantenedores do croqui será tratado em um pacote futuro de integração com o Aresta).
- Login via código/link de e-mail (*Magic Link*): foi descartado para que 100% das contas possuam `idToken` OIDC assinado diretamente pelas chaves raiz da Google ou Apple com suporte a `nonce`.
- Edição colaborativa multi-usuário de um mesmo laudo: cada `idSessao` pertence ao `user_id` criador.

## Decisions

### 1. Identidade Criptográfica estilo OpenPubkey (`nonce` OIDC Google/Apple + App Check + Backup Nativo OS)

- **Decisão**:
  1. No `FlutterSecureStorage`, habilitar `IOSOptions(synchronizable: true, accessibility: KeychainAccessibility.first_unlock)` e `AndroidOptions(encryptedSharedPreferences: true)` com suporte ao AutoBackup criptografado do Android.
  2. Antes de chamar `GoogleSignIn` ou `SignInWithApple`, o `CryptoService` garante que o par de chaves ECDSA `secp256r1` local existe e calcula `rawNonce = sha256Hex(chavePublicaPem)`.
  3. O provedor nativo (Google/Apple) recebe `nonce = sha256Hex(rawNonce)` e devolve um `idToken` JWT assinado pelas chaves públicas oficiais (`https://www.googleapis.com/oauth2/v3/certs` ou `https://appleid.apple.com/auth/keys`).
  4. O app autentica no Supabase com `supabase.auth.signInWithIdToken(provider, idToken, rawNonce)` e armazena o `idToken` (`atestado_oidc_jwt`).
  5. Esse `atestado_oidc_jwt` é embutido em `META-INF/signatures.xml` (dentro de `<ds:Object Id="oidc-attestation">`) e enviado ao Worker junto com o token do **Firebase App Check**.
- **Racional**: Mesmo alguém com acesso administrativo ao banco do Supabase não consegue forjar um `idToken` assinado pela chave privada da Google ou da Apple contendo o `nonce` da chave pública ECDSA do dispositivo. Isso prova matematicamente (`A + B`) que a chave pública pertence ao dono daquela conta Google/Apple em um binário oficial do Fixalog, sem precisarmos custodiar a chave privada na nuvem nem exigir senhas/PINs extras no onboarding.
- **Alternativas consideradas**:
  - *Cofre de chave privada na nuvem cifrado com PIN/senha*: Descartado por adicionar atrito no onboarding e risco de esquecimento de senha.
  - *Cifrar chave privada no servidor usando segredo derivado do JWT do Supabase*: Descartado porque o administrador do projeto Supabase detém o `JWT_SECRET` e tecnicamente poderia personificar um login por e-mail; o vínculo via `idToken` Google/Apple elimina essa brecha.

### 2. Versionamento Imutável (`v1`, `v2`, ...) em vez de Trava por Chave Pública Única

- **Decisão**: Cada upload de um `idSessao` gera uma nova versão sequencial imutável no R2 (`laudos/<idSessao>/v1.epub`, `laudos/<idSessao>/v2.epub`...) e uma nova linha na tabela `versoes_laudo_fixalog` no D1. A autorização para publicar `v<N+1>` verifica se o `user_id` autenticado é o proprietário do laudo em `laudos_fixalog` e se a chave pública que assinou `v<N+1>` possui vínculo OIDC válido para esse mesmo `user_id`.
- **Racional**: Se o usuário migrar de Android para iPhone (onde o Keychain não é compartilhado entre fabricantes) e re-editar um relatório antigo, ele não fica bloqueado por ter perdido a chave privada anterior. Ao mesmo tempo, como não existe sobrescrita ("nunca tem edição, apenas novas versões"), `v1` permanece intacta e auditável para sempre, e a barra superior de `fixalog.app/v/:id` permite alternar entre `v1` e `v2` mostrando exatamente qual chave assinou cada versão.
- **Alternativas consideradas**:
  - *Travar cada conta ou relatório a uma única chave pública imutável*: Descartado porque impediria o próprio autor de atualizar um relatório caso perdesse o aparelho sem backup compatível.

### 3. Armazenamento Único no R2 (`fixalog-laudos`) e Streaming por Byte-Range do Diretório Central ZIP

- **Decisão**: Armazenar apenas `laudos/<id>/v<N>.epub` no bucket R2 `fixalog-laudos`. Como o `EpubPackagerService` grava `.mp4`, `.webp`, `.jpg`, `.png` e `.pdf` com `CompressionType.none` (`STORE`), os bytes de cada mídia estão contíguos e sem compressão adicional dentro do arquivo `.epub`. No upload, o Worker lê o *End of Central Directory (EOCD)* e o *Central Directory* nos últimos 64 KB do `.epub`, calcula o `offset` exato dos dados de cada entrada (`localHeaderOffset + 30 + fileNameLength + extraFieldLength`) e salva o mapa JSON compacto `indices_zip_json` na tabela `versoes_laudo_fixalog`:
  ```json
  {
    "OEBPS/relatorio.xhtml": { "o": 142, "s": 4820, "c": 8 },
    "OEBPS/midias/foto1.webp": { "o": 12400, "s": 184320, "c": 0 },
    "OEBPS/midias/video1.mp4": { "o": 196800, "s": 4120000, "c": 0 }
  }
  ```
  Quando o navegador requisita `GET /v/:id/midias/video1.mp4` (inclusive com `Range: bytes=start-end`), o Worker traduz para `BUCKET.get("laudos/<id>/v<N>.epub", { range: { offset: entry.o + start, length: requestedLength } })` e devolve `206 Partial Content` com `Cache-Control: public, max-age=31536000, immutable`.
- **Racional**: Reduz em 50% o armazenamento no R2 (zero duplicação de fotos e vídeos fora do `.epub`), mantém um único artefato canônico assinado por versão e entrega *seek* instantâneo de vídeo na CDN da Cloudflare.
- **Alternativas consideradas**:
  - *Descompactar todas as mídias do `.epub` em arquivos soltos no R2*: Descartado por dobrar o consumo de armazenamento e o número de operações de escrita (`Class A operations`) no R2.

### 4. Esquema no Banco Cloudflare D1 Compartilhado (`aresta-catalogo`)

- **Decisão**: Criar as tabelas do Fixalog no mesmo banco D1 `aresta-catalogo` utilizado pelo Worker `catalogo` do Aresta:
  ```sql
  CREATE TABLE IF NOT EXISTS chaves_usuario_fixalog (
    fingerprint_sha256 TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    chave_publica_pem TEXT NOT NULL,
    certificado_x509_pem TEXT NOT NULL,
    atestado_oidc_jwt TEXT NOT NULL,
    provedor_oidc TEXT NOT NULL,
    nome_declarado TEXT NOT NULL,
    clube_declarado TEXT,
    criado_em TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS laudos_fixalog (
    id_sessao TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    categoria TEXT NOT NULL, -- 'MANUTENCAO' | 'MATERIAL'
    id_protocolo TEXT NOT NULL,
    titulo TEXT NOT NULL,
    escalada_uid TEXT,       -- UUID opcional da via no catálogo Aresta
    latitude REAL,
    longitude REAL,
    versao_atual INTEGER NOT NULL DEFAULT 1,
    criado_em TEXT NOT NULL,
    atualizado_em TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS versoes_laudo_fixalog (
    id_sessao TEXT NOT NULL,
    versao INTEGER NOT NULL,
    r2_key TEXT NOT NULL,
    tamanho_bytes INTEGER NOT NULL,
    hash_epub_sha256 TEXT NOT NULL,
    fingerprint_chave TEXT NOT NULL,
    nome_mantenedor TEXT NOT NULL,
    clube_mantenedor TEXT,
    indices_zip_json TEXT NOT NULL,
    materiais_referenciados_json TEXT NOT NULL DEFAULT '[]',
    status_moderacao TEXT NOT NULL DEFAULT 'em_analise', -- 'em_analise' | 'ativo' | 'bloqueado' | 'suspenso'
    motivo_moderacao TEXT,
    criado_em TEXT NOT NULL,
    PRIMARY KEY (id_sessao, versao),
    FOREIGN KEY (id_sessao) REFERENCES laudos_fixalog(id_sessao)
  );
  ```
- **Racional**: Compartilhar o banco `aresta-catalogo` permite consultas diretas (`JOIN`) futuras entre `laudos_fixalog.escalada_uid` e as vias do catálogo Aresta em sub-milissegundos, além de calcular em tempo real o contador de relatórios assinados por uma chave (`SELECT COUNT(DISTINCT id_sessao) FROM versoes_laudo_fixalog WHERE fingerprint_chave = ? AND status_moderacao = 'ativo'`) para exibir na barra de verificação sem dados defasados.

### 5. Limite de 60s de Vídeo, `SeletorTrechoVideoDialog` e Keyframes (`-g 300`)

- **Decisão**:
  1. Não limitar `maxDuration` na gravação nativa da câmera (`ImageSource.camera`) para não cortar a filmagem do escalador abruptamente na parede e garantir que o vídeo completo seja salvo no rolo da câmera (`salvarVideoNoRoloDaCamera`).
  2. Tanto após gravar na câmera quanto após selecionar da galeria, inspecionar a duração do vídeo. Se `> 60s`, abrir `SeletorTrechoVideoDialog` com linha do tempo deslizante de até 60s (`inicio`, `duracao <= 60s`).
  3. No `VideoTranscoderService`, aplicar `-ss <inicio> -t <duracao>` antes da transcodificação e adicionar `-g 300` (a 30fps = 1 *I-Frame* exato a cada 10s).
- **Racional**: Um vídeo de 60s em H.264 720p CRF 26 ocupa no máximo ~4,8 MB, protegendo a franquia gratuita de 10 GB do R2, enquanto `-g 300` garante que o servidor consiga extrair rapidamente *I-Frames* espaçados de 10 em 10 segundos sem precisar decodificar *P/B-Frames* intermediários.

### 6. Gatekeeper de Moderação CSAM e NSFW em 3 Camadas com Extração de I-Frames no Servidor

- **Decisão**:
  ```
  [Upload PUT /api/v1/laudos/:id]
         │
         ▼
  Grava R2 (laudos/<id>/v<N>.epub) + D1 (status_moderacao = 'em_analise')
         │
         ├──► Responde 202 Accepted ao App (enviadoNuvem = true)
         │
         └──► ctx.waitUntil(auditarSegurancaLaudo(id, versao)):
                1. Lê todas as fotos (.webp/.jpg/.png) via Byte-Range do .epub
                2. Para cada .mp4: lê átomo moov/stss, localiza todos os I-Frames
                   (a cada 10s + primeiro e último quadro) e decodifica via WASM H.264
                3. Camada CSAM (PhotoDNA NCMEC/Interpol): dispara sub-requisição
                   cacheável na zona fixalog.app para o Cloudflare CSAM Scanning Tool
                4. Camada IA Visual (CSAM S4 + NSFW S12): envia cada foto e I-Frame
                   para Cloudflare Workers AI (@cf/meta/llama-3.2-11b-vision-instruct)
                5. Se 100% SEGURO -> D1: status_moderacao = 'ativo'
                   Se QUALQUER ALERTA -> D1: status_moderacao = 'bloqueado',
                   remove/isola objeto no R2 e dispara POST para alertas.arestaclimb.com
  ```
- **Racional**: Extrair os *I-Frames* diretamente no Worker impede que um cliente malicioso envie um vídeo ilícito acompanhado de um mosaico falso inocente. E manter `status_moderacao = 'em_analise'` como bloqueio preventivo (*gatekeeper*) garante que nenhuma mídia seja servida publicamente antes de passar pelas verificações de CSAM e NSFW.

### 7. Modularidade Library-First e Fakes Determinísticos Testados

- **Decisão**:
  - No Flutter (`app/lib/core/services/`): criar módulos desacoplados `autenticacao_nuvem_service.dart`, `sincronizador_nuvem_service.dart` e seus Fakes determinísticos `test-only` (`autenticacao_nuvem_service_fake.dart`, `sincronizador_nuvem_service_fake.dart`), cada qual com seu teste espelhado 1:1 (`*_test.dart` e `*_fake_test.dart`).
  - No Worker (`../aresta_backend/cloudflare/fixalog/src/`): estruturar módulos puros e independentes (`extrator_indice_epub.ts`, `verificador_assinatura_laudo.ts`, `extrator_iframes_mp4.ts`, `moderador_midia_ia.ts`, `renderizador_pagina_laudo.ts`) com testes 1:1 usando Vitest/Miniflare.

## Risks / Trade-offs

- **[Tempo de CPU no Worker ao decodificar I-Frames de múltiplos vídeos]** → **Mitigação**: Como o FFmpeg no app codifica com `-g 300` (máximo de 6 a 7 *I-Frames* por vídeo de 60s em 720p) e o parser lê apenas a fatia de bytes exata de cada *IDR NAL unit* via `stss`/`stsc`/`stco` sem ler o resto do vídeo, a decodificação de um *I-Frame* isolado leva poucos milissegundos em WASM dentro do orçamento de CPU do Cloudflare Workers.
- **[Usuário tenta abrir o QR Code segundos após o upload enquanto `status_moderacao == 'em_analise'`]** → **Mitigação**: A página `fixalog.app/v/:id` quando `em_analise` exibe um estado visual amigável ("Verificando assinatura criptográfica e segurança das mídias...") com *auto-refresh* a cada 3 segundos até que mude para `'ativo'` (tipicamente 3 a 8 segundos).
- **[Troca de Android para iOS gera um novo par de chaves ECDSA]** → **Mitigação**: O vínculo OIDC registra a nova chave na mesma conta (`user_id`), a barra de verificação em `fixalog.app/v/:id` exibe todas as versões do laudo (`v1`, `v2`) com seus respectivos *fingerprints* e ambos os certificados permanecem matematicamente verificáveis.

## Migration Plan

1. **Contratos e Banco D1 (`../aresta_backend/aresta_api`)**:
   - Adicionar `openapi/fixalog.yaml` e o schema SQL das tabelas `chaves_usuario_fixalog`, `laudos_fixalog` e `versoes_laudo_fixalog` no banco `aresta-catalogo`.
2. **Cloudflare Worker (`../aresta_backend/cloudflare/fixalog`)**:
   - Criar o bucket R2 `fixalog-laudos`, configurar os bindings (`DB` -> `aresta-catalogo`, `LAUDOS_BUCKET` -> `fixalog-laudos`, `AI` -> Workers AI) e publicar o Worker na rota `fixalog.app/*`, ativando o **CSAM Scanning Tool** no painel da zona `fixalog.app`.
3. **Aplicativo Flutter (`fixalog/app`)**:
   - Migrar usuários locais existentes: se o dispositivo já possuía um par de chaves ECDSA e laudos locais antes da atualização, ao concluir o login obrigatório com Google/Apple o aplicativo vincula a chave existente ao `nonce` OIDC (sem perder a chave já gerada) e enfileira automaticamente todos os laudos `GERADO` (`enviadoNuvem == false`) para upload em segundo plano.
