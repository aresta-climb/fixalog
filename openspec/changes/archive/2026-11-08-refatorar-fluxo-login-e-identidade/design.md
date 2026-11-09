# Design

## Context

Veja `proposal.md` para a motivação. Atualmente:
- `IdentitySetupScreen` (`app/lib/features/identity/views/identity_setup_screen.dart`) renderiza o título `FIX` / `LOG`, dois botões pequenos `GOOGLE` / `APPLE` lado a lado e, na mesma tela, os campos de Nome/Clube e um único card "Segurança de Hardware" que mistura a explicação da chave ECDSA P-256 com ícones de "Acesso Câmera", "Armazenamento" e uma nota de rodapé redundante sobre concordância com os termos de uso.
- `TelaTermosDeUso` (`app/lib/features/onboarding/views/tela_termos_de_uso.dart`) chama `[Permission.camera, Permission.locationWhenInUse].request()` logo no clique de aceite dos termos jurídicos, antes que o usuário veja a explicação contextual dessas permissões.
- `ServicoAutenticacaoNuvemPadrao` (`app/lib/core/services/autenticacao_nuvem_service.dart`) autentica no GoTrue (`/auth/v1/token?grant_type=id_token`) e extrai o nome apenas do payload do `idToken` ou `user.user_metadata`, sem consultar `public.perfis` do Aresta Climb nem sincronizar as alterações de Nome/Clube de volta ao Supabase.

## Goals / Non-Goals

**Goals:**
- Dividir a experiência da `IdentitySetupScreen` em 2 etapas reativas baseadas na presença de `state.sessaoNuvem` (com opção de trocar de conta na Etapa 2).
- Padronizar os botões de login Google (branco `#FFFFFF`, texto `#1F1F1F`) e Apple (preto `#000000`, texto branco) em largura total na Etapa 1, espelhando a identidade visual clássica usada no Aresta Climb.
- Pré-preencher Nome Completo e Clube/Associação na Etapa 2 consultando os metadados da conta Supabase e a tabela `public.perfis` (`autor_nome_publico`) do Aresta Climb.
- Sincronizar de volta ao Supabase os metadados do Fixalog (`nome_completo_fixalog`, `clube_associacao_fixalog`) e, mediante checkbox explícita (`atualizarNomeNoAresta`, marcada por padrão), também atualizar `autor_nome_publico` em `auth.users` e `public.perfis`.
- Manter o card **Segurança de Hardware** focado na explicação da chave ECDSA P-256 + OpenPubkey, e criar um card separado **Permissões do Dispositivo** (Câmera e Localização GPS), solicitando essas permissões ao concluir a Etapa 2.

**Non-Goals:**
- Alterar o algoritmo criptográfico ECDSA P-256 ou o formato de assinatura XML-DSig dos pacotes `.epub`.
- Bloquear a conclusão local do cadastro de identidade caso a sincronização de perfil na nuvem falhe por oscilação de rede após o login OIDC (a atualização de perfil remoto deve ser *best-effort* para preservar a resiliência *offline-first*).

## Decisions

### 1. Máquina de estados de 2 etapas na `IdentitySetupScreen`
- **Decisão**: A transição entre a Etapa 1 e a Etapa 2 será guiada diretamente por `state.sessaoNuvem != null` no `IdentityFormState`, complementada por uma ação `trocarConta()` no `IdentityFormViewModel` (que executa `encerrarSessao()` no `ServicoAutenticacaoNuvem` e limpa `sessaoNuvem` do estado para permitir escolher outra conta Google/Apple).
- **Racional**: Se o usuário abrir o app sem sessão OIDC, vê imediatamente a Etapa 1 (apenas os botões clássicos Google e Apple). Assim que autentica — ou quando abre "Gerenciar Identidade" a partir da aba Configurações já estando autenticado — vê diretamente a Etapa 2 com sua conta conectada, campos pré-preenchidos e botão `[Trocar]` no badge da conta.

### 2. Sincronização de Nome/Clube com Supabase e Checkbox explícita do Aresta Climb
- **Decisão**:
  - Adicionar em `ServicoAutenticacaoNuvem`:
    - Durante/após a autenticação no Supabase (`autenticarComProvedor` e `_carregarIdentidadeExistente`), buscar os dados mais recentes de `/auth/v1/user` e `/rest/v1/perfis?user_id=eq.<userId>&select=autor_nome_publico` para popular `nomeSugerido` (prioridade: `user_metadata.nome_completo_fixalog` -> `perfis.autor_nome_publico` -> `user_metadata.autor_nome_publico` -> `user_metadata.full_name` -> `user_metadata.name`) e `clubeSugerido` (`user_metadata.clube_associacao_fixalog`).
    - Método ` Future<void> sincronizarPerfilConta({required String nomeCompleto, required String clubeAssociacao, required bool atualizarNomeNoAresta})`:
      1. Envia `PUT /auth/v1/user` com `data: {'nome_completo_fixalog': nomeCompleto, 'clube_associacao_fixalog': clubeAssociacao, if (atualizarNomeNoAresta) 'autor_nome_publico': nomeCompleto}`.
      2. Se `atualizarNomeNoAresta == true`, envia também `PATCH /rest/v1/perfis?user_id=eq.<userId>` com `{'autor_nome_publico': nomeCompleto}`.
- **Alternativas consideradas**:
  - Sobrescrever sempre `autor_nome_publico` sem perguntar: descartado porque muitos escaladores usam apelido no Aresta Climb e nome civil completo nos laudos técnicos do Fixalog.

### 3. Separação entre Card de Segurança de Hardware e Card de Permissões do Dispositivo
- **Decisão**:
  - Na Etapa 2 da `IdentitySetupScreen`, exibir dois cards distintos:
    1. **Card `SEGURANÇA DE HARDWARE`** (`Key('card_seguranca_hardware')`): mantém o ícone `Icons.verified_user_outlined`, título e explicação da geração da chave privada ECDSA P-256 no cofre criptografado vinculada ao login Google/Apple (OpenPubkey), sem itens de permissão e sem o rodapé de termos de uso.
    2. **Card `PERMISSÕES DO DISPOSITIVO`** (`Key('card_permissoes_dispositivo')`): lista **ACESSO À CÂMERA** (`Icons.camera_alt_outlined`) e **LOCALIZAÇÃO (GPS)** (`Icons.location_on_outlined`) com descrições curtas do motivo técnico de cada permissão.
  - Ao tocar em **GERAR CHAVES E ENTRAR**, a `IdentitySetupScreen` solicita `[Permission.camera, Permission.locationWhenInUse].request()` (controlado por flag `solicitarPermissoesNativas`, padrão `false` apenas quando desabilitado explicitamente ou tratado com segurança em ambientes de teste sem plugin nativo) antes de chamar `submitIdentity`.
  - Na `TelaTermosDeUso`, o valor padrão de `solicitarPermissoesNativas` passa a ser `false` (ou a chamada de `Permission` é removida do aceite de termos), evitando pedir permissões duas vezes.

## Risks / Trade-offs

- **[Risk] Falha de rede ao sincronizar `perfis` no Supabase após login** → **Mitigation**: `sincronizarPerfilConta` trata erros de rede de forma silenciosa (*best-effort*) após persistir a identidade e o certificado X.509 localmente no cofre seguro, garantindo que o usuário nunca fique bloqueado em campo.
- **[Risk] Chamada de `Permission.request()` em testes de widget sem canal nativo registrado** → **Mitigation**: Encapsular a solicitação de `[Permission.camera, Permission.locationWhenInUse].request()` em bloco `try / catch (_)` (ou callback injetável na `IdentitySetupScreen`) para que testes de widget e plataformas desktop não falhem por `MissingPluginException`.
