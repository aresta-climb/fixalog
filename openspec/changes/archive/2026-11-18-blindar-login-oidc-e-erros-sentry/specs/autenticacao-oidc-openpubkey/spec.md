# Spec Delta

## MODIFIED Requirements

### Requirement: Onboarding Obrigatório com Login Social Google e Apple
O sistema DEVE (MUST) exigir que o usuário se autentique durante o onboarding inicial do aplicativo antes de permitir o acesso às funcionalidades de criação ou visualização de laudos e materiais. O sistema DEVE (MUST) suportar exclusivamente login nativo via **Sign in with Google** (em Android e iOS) e **Sign in with Apple** (exclusivamente em iOS) autenticados contra o projeto Supabase compartilhado com o Aresta Climb (`signInWithIdToken`), sem oferecer login por código/link de e-mail (*Magic Link*), fluxo OAuth Web em navegador para a Apple ou modo anônimo sem conta. A tela de configuração de identidade DEVE (MUST) exibir o cabeçalho da marca `FIXA` / `LOG` e operar em duas etapas distintas: na Etapa 1 (sem sessão OIDC ativa), exibir os botões clássicos em largura total disponíveis para a plataforma atual (**Continuar com o Google** no Android; **Continuar com o Google** e **Continuar com a Apple** no iOS); na Etapa 2 (após autenticar via OIDC), exibir o selo da conta conectada com opção de trocar conta, os campos de Nome Completo e Clube/Associação, um card dedicado de **Segurança de Hardware** explicando a geração da chave privada ECDSA P-256 vinculada ao login (sem texto de aceite de termos e sem permissões misturadas), e uma seção separada de **Permissões do Dispositivo** (Câmera e Localização GPS) solicitando essas permissões nativas ao confirmar o cadastro.

#### Scenario: Primeiro acesso ao aplicativo exige autenticação social
- **WHEN** o usuário abre o aplicativo pela primeira vez em um dispositivo iOS sem sessão autenticada ativa
- **THEN** o sistema exibe a tela de onboarding/identidade com o cabeçalho `FIXA` / `LOG` apresentando exclusivamente a Etapa 1 com os botões em largura total **Continuar com o Google** e **Continuar com a Apple**, ocultando os campos de formulário e bloqueando a navegação para a tela inicial até que a autenticação e o cadastro de Nome Completo sejam concluídos

#### Scenario: Primeiro acesso no Android exibe exclusivamente botão do Google
- **WHEN** o usuário abre o aplicativo pela primeira vez em um dispositivo Android sem sessão autenticada ativa
- **THEN** o sistema exibe na Etapa 1 exclusivamente o botão em largura total **Continuar com o Google**, ocultando o botão **Continuar com a Apple**

#### Scenario: Avanço para a Etapa 2 após autenticação social com explicação da chave e seção separada de permissões
- **WHEN** o usuário conclui o login com Google ou Apple (ou abre a tela já possuindo sessão OIDC ativa)
- **THEN** o sistema avança para a Etapa 2 exibindo o selo da conta autenticada com opção de trocar conta, os campos de Nome Completo e Clube/Associação, o card **Segurança de Hardware** explicando a geração da chave privada ECDSA P-256 (sem texto redundante de termos de uso), e um card separado **Permissões do Dispositivo** listando Acesso à Câmera e Localização (GPS)
- **THEN** ao clicar em "Gerar Chaves e Entrar", o sistema solicita as permissões nativas de Câmera e Localização, gera/vincula o certificado X.509 e navega para a tela inicial

#### Scenario: Retomada offline após onboarding concluído
- **WHEN** o usuário já concluiu o onboarding autenticado anteriormente e abre o aplicativo em ambiente de montanha sem conexão com a internet
- **THEN** o sistema valida a sessão e a identidade criptográfica persistidas localmente e libera o uso integral offline do aplicativo

## ADDED Requirements

### Requirement: Proibição de Credenciais Sintéticas de Fallback em Produção
O sistema JAMAIS DEVE (MUST NOT) gerar tokens OIDC sintéticos locais ou sessões de conta fictícias quando o canal nativo de autenticação retornar nulo, estiver indisponível ou devolver token vazio. Qualquer ausência de credencial real não decorrente de cancelamento explícito do usuário DEVE (MUST) resultar em falha explícita de autenticação.

#### Scenario: Resposta nula ou sem token do canal nativo falha explicitamente
- **WHEN** o seletor nativo de autenticação retorna resposta nula, `idToken` vazio ou falha de plataforma sem flag de cancelamento
- **THEN** o sistema interrompe a autenticação sem persistir sessão local nem invocar fallback sintético, registra o erro operacional na observabilidade e exibe mensagem amigável na interface

### Requirement: Tratamento Silencioso de Cancelamento Voluntário pelo Usuário
Quando o usuário fechar ou cancelar voluntariamente o modal nativo de autenticação (`cancelado == true`), o sistema DEVE (MUST) interromper o estado de carregamento sem enviar requisição ao servidor de autenticação, sem exibir alerta de erro na interface e sem registrar falha na observabilidade.

#### Scenario: Usuário cancela o modal do Face ID ou seletor de contas Google
- **WHEN** o usuário toca em cancelar ou fecha o modal nativo de login da Apple ou do Google
- **THEN** o sistema restaura a tela para o estado interativo inicial sem exibir `SnackBar` de erro e sem enviar exceção ao Sentry ou Crashlytics
