## Context

O FixaLog gera relatórios de manutenção criptograficamente selados e independentes. Atualmente, os relatórios expressos e até certos fluxos antigos misturavam mídias cruas diretamente nos campos de `bytes` do Protobuf. Isso estava criando gargalos de memória (inflação no Dart ao serializar vídeos ou múltiplas fotos de alta resolução) e poluindo o Isar com blobs gigantescos de mídias que deveriam estar no File System. Além disso, a falta de uma estrutura clara dificultava a re-edição dos rascunhos.

Para resolver, propomos uma arquitetura baseada em "Manifesto" (onde o `.binarypb` pesa apenas KBs, apenas referenciando IDs) acoplada a um "Session Bundle" local, permitindo que vídeos sejam suportados de forma natural e que as mídias fiquem encapsuladas.

## Goals / Non-Goals

**Goals:**
- Desacoplar mídias brutas e comprimidas do corpo serializado do Protobuf.
- Criar a camada `ReferenciaMidia` (Imagem, Áudio, Vídeo) no `.proto` com hashes independentes para garantir a integridade matemática da mídia na visão da auditoria.
- Garantir que cada relatório gere um "Session Bundle" (pasta local baseada no `id_sessao` com as mídias originais e comprimidas e o arquivo `.binarypb`).
- Injetar o manifesto `.binarypb` e os arquivos compactados como **anexos visíveis** em nível de máquina usando PDF/A-3.
- Habilitar edição a partir do Histórico usando o `ExpressFormViewModel` lendo os manifestos armazenados no Bundle.

**Non-Goals:**
- Implementação de um player completo de edição/corte de vídeos no app.
- Sincronização em nuvem desta estrutura (neste momento focaremos apenas no estado local no app e arquivos injetados no PDF).

## Decisions

1. **Protobuf Manifest vs Blobs**:
   - **Decisão**: Mudar `bytes foto` e afins para `ReferenciaMidia`.
   - **Justificativa**: Serializar 30MB de vídeos ou imagens de 12MP em memória num `build()` do Protobuf no Dart causava lentidão, quebra no formato Isar, e limitava a reutilização do arquivo `.pb`. Agora, o `.pb` carregará apenas a metadata criptograficamente validada e UUIDs.
2. **Double-Hashing na Mídia**:
   - **Decisão**: Cada arquivo de mídia terá 2 hashes guardados no `.pb`: `hash_original` (da versão HD tirada da câmera) e `hash_comprimido` (da versão de exportação final), junto com o `versao_compressao`.
   - **Justificativa**: Isso permite re-comprimir a imagem local posteriormente se atualizarmos o algoritmo (checa-se a validade matemática pelo hash_original para autorizar) e permite a futura exportação do PDF com mídias em High-Res se necessário.
3. **Storage: O "Session Bundle"**:
   - **Decisão**: Os arquivos não ficarão mais "soltos". Cada relatório criará um diretório `app_docs/sessoes/<id_sessao>/` onde todas as mídias (originais e comprimidas) e o manifesto ficarão agrupados.
   - **Justificativa**: Limpeza com 1 comando (delete do folder), portabilidade e isolamento.
4. **Armazenamento de Longo Prazo**:
   - **Decisão**: Arquivos `_original` serão mantidos permanentemente até exclusão manual do relatório.
   - **Justificativa**: Regra acordada com o usuário para garantir cópias primárias de alta qualidade.
5. **Assinatura Dinâmica na Edição**:
   - **Decisão**: Editar um arquivo não quebra a criptografia; ao clicar em "Gerar" numa edição, o arquivo antigo não é "assinado por cima". Cria-se um novo PDF (e portanto, nova assinatura) baseado nos blocos da edição.

## Risks / Trade-offs

- **[Risk] Aumento do consumo do espaço do usuário devido aos originais mantidos permanentemente.** 
  - **Mitigation**: Ser transparente sobre o armazenamento; arquivos agrupados em pastas isoladas por sessão permitem limpezas simples em futuras versões.
- **[Risk] PDF Duplicando dados (Visual vs Anexos PDF/A-3).**
  - **Mitigation**: É um trade-off arquitetural aceito pelo projeto. Mídias visuais no PDF podem ser corrompidas por renderizadores; os arquivos embutidos como anexos protegem o Hash.
