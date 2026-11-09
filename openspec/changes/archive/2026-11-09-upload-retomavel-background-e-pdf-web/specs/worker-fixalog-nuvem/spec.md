# Spec Delta

## ADDED Requirements

### Requirement: Upload Retomável em Blocos e Mapeamento Idempotente por SHA-256
O Worker DEVE (MUST) disponibilizar o endpoint `GET /api/v1/laudos/:id/status?sha256=<hash>` e o endpoint de recepção de blocos `PUT /api/v1/laudos/:id/chunk?sha256=<hash>&index=<i>&total=<N>`. O servidor DEVE (MUST) mapear cada versão pelo par `{id_sessao, hash_epub_sha256}`:
- Se o `sha256` informado já existir em `versoes_laudo_fixalog` para aquele `id_sessao`, o endpoint de status DEVE retornar `{ ja_enviado: true, versao, status_moderacao }`, e qualquer tentativa de novo upload com o mesmo `sha256` DEVE ser rejeitada/respondida sem duplicar a versão e informando que aquela versão já está pronta;
- Se o `sha256` ainda não estiver finalizado, o endpoint de status DEVE retornar a lista `chunks_recebidos` já armazenados temporariamente no R2 (`staging/<id_sessao>/<sha256>/chunk_<i>`), permitindo que o cliente envie apenas os blocos faltantes;
- Ao receber o último bloco de um `sha256` inédito, o Worker DEVE concatenar os blocos, validar que o hash SHA-256 e a assinatura `META-INF/signatures.xml` conferem, criar a nova versão sequencial `v<N>`, remover os blocos temporários e iniciar a moderação assíncrona.

#### Scenario: Retomada de upload após queda de conexão no meio dos blocos
- **WHEN** um cliente envia os blocos `0` e `1` de um laudo de 4 blocos para `PUT /api/v1/laudos/:id/chunk` e a conexão cai antes do bloco `2`
- **THEN** ao consultar `GET /api/v1/laudos/:id/status?sha256=<hash>`, o Worker retorna `ja_enviado: false` e `chunks_recebidos: [0, 1]`, permitindo que o cliente envie apenas os blocos `2` e `3` para concluir a versão

#### Scenario: Rejeição de re-upload quando o mesmo SHA-256 já foi enviado
- **WHEN** o cliente tenta enviar um pacote ou consultar status para um `{id_sessao, sha256}` que já consta em `versoes_laudo_fixalog`
- **THEN** o Worker não cria uma nova versão duplicada e informa que o `sha256` já foi processado, retornando o número da versão correspondente e seu `status_moderacao` atual

### Requirement: Meta Tags OpenGraph e Resumo Descritivo para Preview no WhatsApp
Ao renderizar `GET https://fixalog.app/v/:id`, o Worker DEVE (MUST) incluir no `<head>` as meta tags OpenGraph (`og:title`, `og:description`, `og:url`, `og:type`, `og:site_name`, `og:image` e `twitter:card`) contendo um resumo estruturado do laudo (tipo de protocolo, nome da via/setor/material, nome do mantenedor/clube e resumo de itens/mídias) e apontando `og:image` para a primeira foto disponível no pacote `.epub` quando `status_moderacao == 'ativo'`.

#### Scenario: Geração de preview rico ao compartilhar link no WhatsApp
- **WHEN** o crawler do WhatsApp ou navegador requisita `GET https://fixalog.app/v/<id>` de um laudo ativo
- **THEN** o HTML retornado inclui `og:title` com o protocolo e título específico do laudo, `og:description` com o autor, clube e resumo do conteúdo inspecionado, e `og:image` apontando para a primeira imagem do relatório

## MODIFIED Requirements

### Requirement: Visualizador Web (`fixalog.app/v/:id`) com Barra de Verificação Criptográfica e Seletor de Versões
Ao acessar `GET https://fixalog.app/v/:id` (ou `?v=<N>`), para um laudo com `status_moderacao = 'ativo'`, o Worker DEVE (MUST) renderizar o relatório XHTML completo (incluindo ao final, para fins de impressão `@media print`, as seções dos materiais anexados em `OEBPS/materiais/<uuid>/OEBPS/relatorio.xhtml`) acompanhado de uma barra superior fixa de verificação pericial contendo:
- Selo de verificação criptográfica da assinatura ECDSA (`META-INF/signatures.xml`) e validação do vínculo OIDC Google/Apple + App Check;
- Nome do mantenedor, Clube/Associação e data/hora da assinatura;
- *Fingerprint* abreviado da chave pública (`SHA-256`) e **contador dinâmico em tempo real** (consultado no D1) do total de laudos ativos assinados por aquela chave pública;
- Seletor de histórico de versões (`v1`, `v2`, ...) permitindo inspecionar qualquer versão anterior e ver se houve mudança de chave entre versões;
- Botão principal para baixar o pacote `.epub` original assinado, opção secundária/discreta para exportar/imprimir em `.pdf` pelo navegador (`window.print()`) e botão **"Denunciar relatório"**.

#### Scenario: Abertura de relatório via QR Code de vídeo rola até o vídeo e exibe dados criptográficos
- **WHEN** um usuário escaneia um QR Code apontando para `https://fixalog.app/v/<id>#video-<uuid>` de um laudo ativo
- **THEN** a página web carrega a barra superior de verificação criptográfica (com autor, clube, *fingerprint*, contagem atualizada de laudos da chave e versão atual) e posiciona a rolagem diretamente no elemento `<div id="video-<uuid>">` pronto para reprodução

#### Scenario: Inspeção de versão anterior pelo seletor de versões
- **WHEN** um laudo possui versões `v1` e `v2` e o leitor seleciona `v1` no seletor da barra superior (`https://fixalog.app/v/<id>?v=1`)
- **THEN** o Worker renderiza o conteúdo, as mídias e os metadados de assinatura correspondentes exatamente ao arquivo `laudos/<id>/v1.epub`, exibindo um aviso de que existe uma versão mais recente (`v2`)
