# Tasks

## 1. Contratos da API e Esquema D1 Compartilhado (`../aresta_backend/aresta_api`)

- [x] 1.1 Criar especificação OpenAPI em `../aresta_backend/aresta_api/openapi/fixalog.yaml` cobrindo registro de chave (`POST /api/v1/chaves`), upload de versão de laudo (`PUT /api/v1/laudos/:id`), listagem de laudos da conta (`GET /api/v1/laudos`), denúncia (`POST /api/v1/laudos/:id/denunciar`) e rotas públicas de visualização e *Byte-Range* (`GET /v/:id`, `GET /v/:id/midias/*`, `GET /v/:id/epub`, `GET /v/:id/pdf`), verificando a validade sintática do contrato.
- [x] 1.2 Adicionar migração/esquema SQL para o banco D1 compartilhado `aresta-catalogo` definindo as tabelas `chaves_usuario_fixalog`, `laudos_fixalog` (com `escalada_uid` anulável) e `versoes_laudo_fixalog`, atualizando a documentação do `aresta_api/README.md` e verificando a execução limpa do schema em SQLite em memória.

## 2. Limite de 60s de Vídeo, `SeletorTrechoVideoDialog` e Keyframes (`fixalog/app`)

- [x] 2.1 Atualizar `VideoTranscoderService` (`app/lib/features/media/services/video_transcoder_service.dart`) e seu Fake determinístico (`video_transcoder_service_fake.dart`) para suportar parâmetros opcionais de corte (`inicioSegundos`, `duracaoSegundos` -> `-ss` e `-t`) e intervalo fixo de *keyframe* `-g 300`, garantindo 100% de cobertura em `video_transcoder_service_test.dart` e `video_transcoder_service_fake_test.dart`.
- [x] 2.2 Implementar o componente `SeletorTrechoVideoDialog` (`app/lib/features/media/widgets/seletor_trecho_video_dialog.dart`) com teste espelhado `seletor_trecho_video_dialog_test.dart` permitindo selecionar uma janela de até 60 segundos em vídeos com duração superior a 60s, validando a interação via `flutter test`.
- [x] 2.3 Integrar a verificação de duração de vídeo no fluxo de captura por câmera (`ImageSource.camera`, sem interromper a gravação aos 60s e mantendo o salvamento do vídeo completo no rolo da câmera) e seleção da galeria no `WizardScreen` e `MediaCompressorService`, verificando que vídeos `<= 60s` são anexados diretamente e vídeos `> 60s` abrem o `SeletorTrechoVideoDialog` em `wizard_screen_test.dart` e `media_compressor_service_test.dart`.

## 3. Âncora de Vídeo e Atestado OIDC no EPUB 3 (`fixalog/app`)

- [x] 3.1 Atualizar `EpubDocumentBuilder` (`app/lib/core/services/epub_document_builder.dart`) para incluir `id="video-<uuid>"` em cada container `<div class="container-video">` do `relatorio.xhtml`, verificando em `epub_document_builder_test.dart` que o ID corresponde ao fragmento `#video-<uuid>` dos QR Codes.
- [x] 3.2 Atualizar `XmlDsigSigner` (`app/lib/core/services/xml_dsig_signer.dart`) e `CryptoService` (`app/lib/core/services/crypto_service.dart`) para embutir e extrair o `atestado_oidc_jwt` dentro de `META-INF/signatures.xml`, validando a assinatura e extração em `xml_dsig_signer_test.dart` e `crypto_service_test.dart`.

## 4. Onboarding Obrigatório OIDC (Google/Apple), OpenPubkey `nonce` e App Check (`fixalog/app`)

- [x] 4.1 Configurar backup nativo criptografado no `CryptoService` (`IOSOptions(synchronizable: true)` e `AndroidOptions(encryptedSharedPreferences: true)`), cálculo de `rawNonce = sha256(chave_publica_pem)` e atualização de Nome/Clube no certificado X.509 sem regerar o par de chaves ECDSA, validando em `crypto_service_test.dart`.
- [x] 4.2 Criar o módulo `AutenticacaoNuvemService` (`app/lib/core/services/autenticacao_nuvem_service.dart`) e sua biblioteca Fake determinística (`app/test/core/services/autenticacao_nuvem_service_fake.dart`) integrando Sign in with Google, Sign in with Apple (`signInWithIdToken` no Supabase com `rawNonce`) e token do Firebase App Check, verificando 100% de cobertura em `autenticacao_nuvem_service_test.dart` e `autenticacao_nuvem_service_fake_test.dart`.
- [x] 4.3 Atualizar `IdentitySetupScreen` (`app/lib/features/identity/views/identity_setup_screen.dart`) e `IdentityFormViewModel` (`app/lib/features/identity/viewmodels/identity_form_view_model.dart`) para exigir autenticação Google ou Apple no onboarding, sincronizar Nome Completo e Clube/Associação da conta e vincular chaves locais pré-existentes ao `nonce` OIDC, verificando os fluxos em `identity_setup_screen_test.dart` e `identity_form_view_model_test.dart`.

## 5. Cloudflare Worker `fixalog` (`../aresta_backend/cloudflare/fixalog`)

- [x] 5.1 Inicializar o pacote `../aresta_backend/cloudflare/fixalog` (`package.json`, `tsconfig.json`, `wrangler.toml` com bindings para D1 `aresta-catalogo`, R2 `fixalog-laudos`, Workers AI `AI` e `ALERTA_URL`), criando Fakes determinísticos de R2, D1, AI e verificadores externos com seus respectivos testes (`*_fake.test.ts`).
- [x] 5.2 Implementar `extrator_indice_epub.ts` e `extrator_indice_epub.test.ts` para ler o Diretório Central ZIP do `.epub`, gerar o `indices_zip_json` e resolver leituras parciais de intervalo de bytes (`Range` / `206 Partial Content`) para mídias em modo `STORE` (`.mp4`, `.webp`, `.jpg`, `.png`, `.pdf`).
- [x] 5.3 Implementar `verificador_assinatura_laudo.ts` e `verificador_assinatura_laudo.test.ts` validando na borda o token Firebase App Check, o JWT do Supabase (`user_id`), a assinatura e o `nonce` do `atestado_oidc_jwt` (Google/Apple) e a assinatura ECDSA `META-INF/signatures.xml` do `.epub`.
- [x] 5.4 Implementar `extrator_iframes_mp4.ts` e `moderador_midia_ia.ts` (com seus testes `*.test.ts`) para extrair fotos e todos os *I-Frames* dos vídeos `.mp4` no servidor (via tabela `moov/stss` + decodificação H.264 WASM), disparar sub-requisições para o Cloudflare CSAM Scanning Tool, classificar CSAM (`S4`) e NSFW (`S12`) no Cloudflare Workers AI e transicionar `status_moderacao` de `'em_analise'` para `'ativo'` ou `'bloqueado'` (com alerta imediato para `alertas.arestaclimb.com`).
- [x] 5.5 Implementar `renderizador_pagina_laudo.ts`, o roteador principal `index.ts` e os testes de integração do Worker (`index.test.ts`) cobrindo upload versionado (`v1`, `v2`...), listagem por `user_id`, página pública `GET /v/:id` com barra de verificação criptográfica (incluindo contagem dinâmica de laudos da chave no D1 e seletor de versões), *streaming* `GET /v/:id/midias/*` com cache imutável e endpoint `POST /api/v1/laudos/:id/denunciar`.

## 6. Fila de Sincronização em Segundo Plano, Restauração e Compartilhamento (`fixalog/app`)

- [x] 6.1 Implementar `SincronizadorNuvemService` (`app/lib/core/services/sincronizador_nuvem_service.dart`) e seu Fake determinístico (`app/test/core/services/sincronizador_nuvem_service_fake.dart`) gerenciando a fila de upload automático em segundo plano (enviando pacotes `.epub` de materiais referenciados antes do laudo de manutenção, criando novas versões quando re-editado e atualizando `enviadoNuvem = true` no SQLite) e a restauração de laudos/materiais ao logar em novo dispositivo, validando 100% de cobertura em `sincronizador_nuvem_service_test.dart` e `sincronizador_nuvem_service_fake_test.dart`.
- [x] 6.2 Atualizar `HistoryScreen` (`app/lib/features/home/views/history_screen.dart`) e `VisualizadorRelatorioScreen` (`app/lib/features/pdf_generation/views/visualizador_relatorio_screen.dart`) para exibir fielmente o estado real de `record.enviadoNuvem`, permitir sincronização manual imediata e compartilhar o link web `https://fixalog.app/v/<idSessao>`, validando os comportamentos em `history_screen_test.dart` e `visualizador_relatorio_screen_test.dart`.

## 7. Verificação Integrada e Conformidade Arquitetural

- [x] 7.1 Executar `openspec validate "upload-nuvem-relatorios-fixalog"`, a suíte de testes do Worker (`npm test` em `../aresta_backend/cloudflare/fixalog`) e a suíte completa do aplicativo Flutter (`flutter test --coverage` e `test_structure_mirror_test.dart` em `fixalog/app`), verificando espelhamento 1:1 integral e 100% de cobertura nas bibliotecas criadas e modificadas.
