# Proposal

## Why

Atualmente, a tela de configuração de identidade (`IdentitySetupScreen`) apresenta todos os elementos misturados em uma única etapa (com erro tipográfico `FIX` / `LOG` no cabeçalho, botões de login social fora do padrão clássico, permissões embutidas dentro do card de segurança criptográfica indicando "Armazenamento" em vez de "Localização (GPS)" e um aviso redundante de aceite de termos que já possui tela dedicada), enquanto a `TelaTermosDeUso` solicita permissões nativas prematuramente antes de explicá-las ao usuário e ainda não há sincronização bidirecional explícita do Nome/Clube com a conta compartilhada do Aresta Climb no Supabase. Refatorar esse fluxo em duas etapas claras melhora a usabilidade do login social (*easy login*), dá controle explícito sobre a atualização do nome público no Aresta Climb e unifica a explicação e solicitação de permissões (Câmera e Localização) junto à geração da chave criptográfica.

## What Changes

- **Correção da marca no cabeçalho da `IdentitySetupScreen`**: alterar o título de `FIX` / `LOG` para `FIXA` / `LOG`.
- **Fluxo de Login e Identidade em 2 Etapas na `IdentitySetupScreen`**:
  - **Etapa 1 (Login Fácil — antes de autenticar via OIDC)**: exibir apenas o cabeçalho `FIXA` / `LOG`, a chamada de autenticação e os botões clássicos em largura total **Continuar com o Google** (fundo branco) e **Continuar com a Apple** (fundo preto), no mesmo padrão visual do Aresta Climb.
  - **Etapa 2 (Identificação Técnica, Chave Criptográfica e Permissões — após autenticar via OIDC)**:
    - Exibir o selo da conta conectada (`GOOGLE • email` / `APPLE • email`) com ação para trocar de conta.
    - Pré-preencher **Nome Completo** (buscando de `user_metadata.nome_completo_fixalog`, `public.perfis.autor_nome_publico`, `user_metadata.autor_nome_publico` ou `full_name`) e **Clube / Associação** (`user_metadata.clube_associacao_fixalog`).
    - Adicionar uma **checkbox explícita** abaixo do campo Nome Completo (marcada por padrão): *"Atualizar também meu nome de exibição no Aresta Climb"*. Ao salvar, persistir sempre `nome_completo_fixalog` e `clube_associacao_fixalog` no Supabase e, somente se a checkbox estiver marcada, atualizar também `autor_nome_publico` em `public.perfis` e `user_metadata`.
    - Manter o card **Segurança de Hardware** dedicado exclusivamente à explicação da geração da chave privada ECDSA P-256 no cofre seguro do dispositivo vinculada ao login Google/Apple (OpenPubkey), removendo de dentro dele os itens de permissão e a frase redundante *"Ao clicar em gerar chaves, você concorda com os termos..."*.
    - Criar uma nova seção/card separada **Permissões do Dispositivo** listando **Acesso à Câmera** e **Localização (GPS)** (substituindo o antigo item "Armazenamento"), solicitando as permissões nativas (`Permission.camera` e `Permission.locationWhenInUse`) ao tocar em **Gerar Chaves e Entrar**.
- **Desacoplamento da solicitação de permissões na `TelaTermosDeUso`**: remover o disparo automático de permissões nativas ao aceitar os Termos de Uso, mantendo a `TelaTermosDeUso` focada exclusivamente no consentimento jurídico auditável, pois as permissões passam a ser explicadas e solicitadas na Etapa 2 da `IdentitySetupScreen`.

## Capabilities

### New Capabilities

### Modified Capabilities
- `autenticacao-oidc-openpubkey`: Estrutura a `IdentitySetupScreen` em duas etapas (login social clássico Google/Apple na Etapa 1; identificação técnica pré-preenchida da conta Aresta Climb com checkbox explícita de sincronização de nome público, card dedicado de Segurança de Hardware ECDSA P-256 e seção separada de Permissões de Câmera e Localização na Etapa 2).
- `onboarding-terms`: Remove a solicitação de permissões nativas de Câmera e GPS do clique de aceite em `TelaTermosDeUso`, transferindo-a para a conclusão da Etapa 2 na `IdentitySetupScreen`.

## Impact

- `app/lib/core/services/autenticacao_nuvem_service.dart` e `app/test/core/services/autenticacao_nuvem_service_test.dart`: leitura do perfil/metadados existentes do usuário no Supabase (`public.perfis` e `auth.users.user_metadata`) após login OIDC e sincronização de `nome_completo_fixalog`, `clube_associacao_fixalog` e opcionalmente `autor_nome_publico`.
- `app/lib/features/identity/viewmodels/identity_form_view_model.dart` e `app/test/features/identity/viewmodels/identity_form_view_model_test.dart`: gerenciamento do estado das 2 etapas, opção `atualizarNomeNoAresta` (padrão `true`), ação de trocar conta e disparo de sincronização na nuvem.
- `app/lib/features/identity/views/identity_setup_screen.dart` e `app/test/features/identity/views/identity_setup_screen_test.dart`: cabeçalho `FIXA` / `LOG`, Etapa 1 com botões clássicos Google/Apple, Etapa 2 com campos pré-preenchidos, checkbox de sincronização com Aresta Climb, card `Segurança de Hardware` limpo e novo card `Permissões do Dispositivo` (Câmera e Localização) com solicitação de permissões ao confirmar.
- `app/lib/features/onboarding/views/tela_termos_de_uso.dart` e `app/test/features/onboarding/views/tela_termos_de_uso_test.dart`: remoção da solicitação de permissões nativas durante o aceite dos termos.
