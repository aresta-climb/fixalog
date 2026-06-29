## Context

O aplicativo móvel precisa empacotar grandes quantidades de mídias (vídeos, fotos de alta resolução, áudios) em um único arquivo de laudo e assiná-lo criptograficamente para garantir integridade. Bibliotecas de PDF tradicionais no Flutter tentam carregar o arquivo inteiro na memória RAM (como `Uint8List`), o que causa falhas fatais de *Out of Memory* (OOM) em arquivos superiores a 50-100MB. Além disso, o processamento exige feedback visual constante para o usuário.

## Goals / Non-Goals

**Goals:**
- Garantir processamento *Zero OOM* via acesso a disco (streams).
- Centralizar o processamento e criptografia pesada em um núcleo nativo seguro (Rust).
- Emitir atualizações de progresso granulares para a UI via Riverpod.
- Gerar um PDF/A-3 válido com mídias como *EmbeddedFiles* (anexos).

**Non-Goals:**
- Implementar compressão de vídeo/áudio do zero em Rust ou C/C++ (usaremos wrappers do FFmpeg).
- Utilizar a API do Gov.br para assinatura em nuvem (restrita a órgãos públicos).
- Desenhar as páginas visuais do PDF via código Rust.

## Decisions

### 1. Separação de Responsabilidades (Dart vs Rust)
- **Dart (Flutter):** Responsável por orquestrar as tarefas, comprimir as mídias delegando para plugins do ecossistema (`flutter_image_compress` e `ffmpeg_kit_flutter`) e desenhar o layout visual (rascunho) do PDF (textos e ícones GoToE).
- **Rust (Core):** Responsável apenas pela injeção binária de anexos (atualizando para PDF/A-3), leitura em fluxo (hash SHA-256 pulando o ByteRange) e geração da assinatura CMS.
- *Rationale:* Pragmatismo. Desenhar UI e interagir com encoders de hardware é muito mais fácil usando os ecossistemas nativos via Flutter do que recriar rodas em Rust.

### 2. Comunicação Inter-Processo (FFI)
- Utilização da biblioteca `flutter_rust_bridge`.
- *Rationale:* Automatiza a geração de código C e JNI/Objective-C para comunicação entre o código Rust assíncrono e os *Isolates* do Dart, permitindo o retorno de `Streams` para atualizar a barra de progresso.

### 3. Gerência de Estado via Riverpod
- O pacote Riverpod será utilizado para escutar a *Stream* do Rust e atualizar a tela (`GenerationProgressDialog`) de forma reativa e segura contra vazamento de memória.
- *Rationale:* Tipo-seguro (type-safe) e elimina problemas de contexto herdados do antigo `Provider`.

### 4. Certificado Autoassinado (MVP)
- A chave e certificado X.509 autoassinados serão gerados localmente e utilizados para criar a estrutura PAdES.
- *Rationale:* Isola o risco jurídico para o criador da plataforma nesta fase inicial, enquanto tecnicamente a estrutura criptográfica permanece idêntica à que será usada no futuro com um e-CNPJ.

### 5. Arquitetura Library-First e TDD Obrigatório
- O código será escrito estritamente usando *Test-Driven Development* (TDD), com o ciclo Red-Green-Refactor. Todos os serviços Flutter e módulos Rust serão desenhados como bibliotecas independentes (`Library-First`).
- Os testes de integração (fronteira entre Dart e Rust) serão escritos e mockados *antes* dos testes unitários, assegurando os contratos FFI. 
- *Rationale:* Conformidade inegociável com o `PRINCIPIOS.md` para garantir 100% de cobertura de teste, código simples, declarativo e coeso.

## Risks / Trade-offs

- **Risco:** Complexidade de infraestrutura de Build (CI/CD) aumentada por exigir a compilação cruzada (cross-compilation) de bibliotecas dinâmicas do Rust para Android (JNI) e iOS (CocoaPods).
  - *Mitigation:* Utilizar os scripts de inicialização do `flutter_rust_bridge_codegen` que abstraem a maior parte da dor da compilação cruzada.
- **Risco:** Ocupação extrema de armazenamento interno do celular caso o usuário gere múltiplos PDFs pesados, além de "lixo" temporário.
  - *Mitigation:* Implementar o serviço de *Garbage Collection* no boot do app, que varre arquivos temporários (`.tmp`) de sessões que falharam (status `processing`). A mídia original do usuário não será apagada na versão 1.0.
