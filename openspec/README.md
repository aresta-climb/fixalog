# Visão Geral do Sistema: Fixalog

O **Fixalog** é um aplicativo voltado para a catalogação de proteções fixas durante a abertura ou manutenção de vias de escalada.

## Stack Tecnológico Atual
- **Framework**: Flutter (versão >3.11.3)
- **Gerenciamento de Estado**: Riverpod (ProviderScope na raiz da aplicação)
- **Banco de Dados Local**: Isar Database (Armazenamento offline-first)
- **Modelagem de Dados**: Protobuf (provavelmente usado para padronização ou envio futuro de relatórios)
- **Outras Bibliotecas**: `pdf` e `printing` para geração de relatórios, `flutter_secure_storage`.

## Arquitetura e Organização de Diretórios
A arquitetura do projeto segue uma abordagem orientada a *features*, sendo o código da aplicação centralizado em `app/lib/`:

- `core/`: Contém os modelos e utilitários globais, bem como as definições de schemas do Isar.
  - Modelos já identificados: `IdentityRecord` (para guardar informações do usuário logado) e `SubmissionRecord` (para guardar o log/catalogo das proteções).
- `features/`:
  - **`identity`**: Responsável pelo fluxo de identificação do usuário. Se o banco não possui uma identidade configurada (`hasIdentityProvider`), o app inicia na `IdentitySetupScreen`.
  - **`home`**: Tela principal (`HomeScreen`), exibida quando o usuário já possui uma identidade.
  - **`wizard`**: Provavelmente o fluxo principal onde o usuário submete um novo log/catálogo (gera um `SubmissionRecord`).

## Fluxo de Inicialização
No arquivo `main.dart`, a inicialização do app:
1. Garante que os bindings do Flutter estão iniciados.
2. Abre o Isar Database injetando as coleções `IdentityRecordSchema` e `SubmissionRecordSchema`.
3. Injeta a instância do Isar globalmente via Riverpod (`isarProvider`).
4. Configura o Tema (Dark Theme por padrão com cores customizadas como "Rescue Orange" e "Moss Green") e fontes de sistema (SpaceGrotesk e Inter).
5. Usa um roteador inicial (`_StartupRouter`) que verifica de forma reativa (`ref.watch(hasIdentityProvider)`) se o usuário já preencheu sua identidade. Redireciona de acordo (Home ou Setup).

## Princípios de Engenharia
Todos os desenvolvimentos neste repositório devem seguir rigidamente os princípios estabelecidos em `PRINCIPIOS.md`.

Este arquivo serve como o contexto base para o OpenSpec e para os agentes autônomos que operarem nesta base de código.
