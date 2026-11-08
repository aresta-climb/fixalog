# Autenticação OIDC e OpenPubkey

## Purpose

Provê autenticação obrigatória no onboarding via login social (Google e Apple) integrado ao Supabase Auth do ecossistema Aresta Climb, vinculando matematicamente o par de chaves ECDSA (`secp256r1`) local do dispositivo ao `idToken` OIDC (`nonce` estilo OpenPubkey) e ao Firebase App Check, com backup criptografado nativo do sistema operacional e sincronização de Nome/Clube da conta.

## Requirements

### Requirement: Onboarding Obrigatório com Login Social Google e Apple
O sistema DEVE (MUST) exigir que o usuário se autentique durante o onboarding inicial do aplicativo antes de permitir o acesso às funcionalidades de criação ou visualização de laudos e materiais. O sistema DEVE (MUST) suportar exclusivamente login via **Sign in with Google** e **Sign in with Apple** autenticados contra o projeto Supabase compartilhado com o Aresta Climb (`signInWithIdToken`), sem oferecer login por código/link de e-mail (*Magic Link*) ou modo anônimo sem conta.

#### Scenario: Primeiro acesso ao aplicativo exige autenticação social
- **WHEN** o usuário abre o aplicativo pela primeira vez sem sessão autenticada ativa
- **THEN** o sistema exibe a tela de onboarding/identidade exigindo login com Google ou Apple e bloqueia a navegação para a tela inicial até que a autenticação e o cadastro de Nome Completo sejam concluídos

#### Scenario: Retomada offline após onboarding concluído
- **WHEN** o usuário já concluiu o onboarding autenticado anteriormente e abre o aplicativo em ambiente de montanha sem conexão com a internet
- **THEN** o sistema valida a sessão e a identidade criptográfica persistidas localmente e libera o uso integral offline do aplicativo

### Requirement: Geração Local e Backup Nativo Criptografado da Chave Privada ECDSA
O sistema DEVE (MUST) gerar o par de chaves criptográficas ECDSA (`secp256r1` / P-256) exclusivamente no dispositivo do usuário e armazená-lo no cofre seguro do sistema operacional com a sincronização criptografada ponta-a-ponta nativa habilitada (`iCloud Keychain` com `synchronizable: true` no iOS e `Encrypted AutoBackup` no Android). A chave privada JAMAIS deve ser transmitida para servidores externos.

#### Scenario: Preservação automática da chave privada ao trocar de aparelho no mesmo ecossistema
- **WHEN** o usuário restaura seu backup do sistema operacional (iOS para iOS via iCloud Keychain ou Android para Android via Google Encrypted Backup) em um novo aparelho e faz login na mesma conta
- **THEN** o sistema recupera o par de chaves ECDSA existente no armazenamento seguro local sem gerar uma nova chave desnecessariamente

#### Scenario: Geração de nova chave local ao trocar de ecossistema ou sem backup prévio
- **WHEN** o usuário faz login em um dispositivo onde o cofre seguro local não possui par de chaves prévio (ex.: migração de Android para iOS)
- **THEN** o sistema gera um novo par de chaves ECDSA `secp256r1` localmente antes de concluir a vinculação OIDC do dispositivo

### Requirement: Vinculação Criptográfica da Chave Pública no Token OIDC (Estilo OpenPubkey)
Antes de iniciar o fluxo de autenticação OAuth com Google ou Apple, o sistema DEVE (MUST) garantir a existência da chave pública ECDSA local, calcular `rawNonce = sha256(chave_publica_pem)` e fornecer esse `rawNonce` ao provedor OIDC para que o `idToken` JWT emitido e assinado pelas chaves raiz da Google/Apple contenha a reivindicação `nonce = sha256(rawNonce)`. O sistema DEVE (MUST) armazenar o `idToken` bruto (`atestado_oidc_jwt`) para incluí-lo nos laudos assinados e no registro da chave pública na nuvem.

#### Scenario: Emissão de atestado OIDC vinculado à chave pública do dispositivo
- **WHEN** o usuário realiza login com Google ou Apple no aplicativo
- **THEN** o sistema passa o hash derivado da chave pública ECDSA local como `rawNonce` para o provedor social, autentica no Supabase via `signInWithIdToken` e persiste o `idToken` assinado (`atestado_oidc_jwt`) contendo o `nonce` correspondente à chave pública e o identificador/e-mail da conta (`sub`/`email`)

### Requirement: Proteção de Requisições com Firebase App Check
Todas as requisições de registro de chave pública e upload de relatórios para a nuvem DEVEM (MUST) incluir um token válido do Firebase App Check emitido pelo atestador nativo do dispositivo (`Play Integrity` no Android e `App Attest` / `DeviceCheck` no iOS), além do JWT de sessão do Supabase.

#### Scenario: Envio de requisição autenticada com atestado de integridade do dispositivo
- **WHEN** o aplicativo envia o registro de uma chave pública ou o upload de um arquivo `.epub` para a API do Fixalog
- **THEN** a requisição inclui o cabeçalho `Authorization: Bearer <supabase_jwt>` e o cabeçalho `X-Firebase-AppCheck: <app_check_token>`

### Requirement: Sincronização de Nome e Clube/Associação sem Invalidação da Chave Criptográfica
O sistema DEVE (MUST) sincronizar o Nome Completo (`nome`) e o Clube/Associação (`clube_associacao`) do mantenedor com os metadados da conta autenticada no Supabase/Aresta. Caso o usuário altere seu nome ou clube/associação posteriormente, o sistema DEVE (MUST) atualizar os metadados da conta e o `Subject` do certificado X.509 para assinaturas futuras, mantendo inalterado o par de chaves ECDSA (`secp256r1`) e a validade matemática de todos os laudos já assinados.

#### Scenario: Preenchimento automático de Nome e Clube a partir da conta existente
- **WHEN** o usuário faz login com uma conta que já possui Nome e Clube/Associação cadastrados no ecossistema Aresta/Fixalog
- **THEN** o sistema pré-preenche automaticamente os campos de Nome Completo e Clube/Associação com os valores sincronizados da conta

#### Scenario: Alteração de Clube/Associação preserva o par de chaves ECDSA
- **WHEN** o usuário edita seu Nome ou Clube/Associação nas configurações de identidade
- **THEN** o sistema sincroniza os novos valores na conta e atualiza o certificado X.509 com a mesma chave pública e privada ECDSA existente, sem gerar um novo par de chaves
