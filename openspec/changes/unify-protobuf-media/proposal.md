## Why

Atualmente, o aplicativo mistura dados brutos (arquivos de imagem pesados) dentro da estrutura do Protobuf, além de não padronizar a forma como as mídias são persistidas e versionadas (especialmente em formulários expressos, que não geram um registro formal no histórico validado). Precisamos garantir que todos os formulários funcionem como manifestos leves, suportem edição rápida e armazenem os dados e anexos em um formato 100% auditável pelo padrão PDF/A-3, permitindo versionamento de compressão de forma segura.

## What Changes

- **BREAKING**: Refatoração do `registro.proto` para não armazenar mais `bytes` diretos para fotos e vídeos. A estrutura passará a adotar `ReferenciaMidia` (Imagem, Vídeo, Áudio) mantendo referências (UUIDs), e hashes da versão original e da versão comprimida, além da versão do algoritmo (`data_version`).
- Organização do armazenamento local no conceito de "Session Bundle": cada relatório (Sessão) terá uma pasta dedicada (`/sessoes/<id_sessao>/`) que encapsulará o arquivo de manifesto (`.binarypb`), PDF final gerado e todas as mídias originais e de trabalho (comprimidas).
- Atualização da geração de PDF (via Rust) para usar o modelo PDF/A-3 de verdade: embutir visualmente os dados necessários (comprimidos), mas anexar de forma oculta os arquivos binários (`.binarypb`) e todas as mídias compactadas (e possivelmente os originais sob demanda) para validação criptográfica.
- O botão do Histórico passará a invocar a tela de edição recarregando os dados diretamente do arquivo `.binarypb` presente no bundle da sessão em vez de re-abrir apenas o PDF final.
- Suporte nativo para vídeos de forma unificada com imagens, não correndo risco de inchar a memória.

## Capabilities

### New Capabilities
- `session-bundle-storage`: Gerenciamento do ciclo de vida dos arquivos locais através de um "Session Bundle", onde originais e modificados residem por sessão.
- `media-manifest-auditing`: Regras de auditoria baseada no hash (SHA-256) original vs comprimido contido no `.binarypb`.

### Modified Capabilities
- `express-form`: Agora carregará dados do `.binarypb` permitindo a re-edição correta sem recompressão acidental e salvará os dados obedecendo à unificação do protobuf.
- `pdf-generator`: Deverá injetar ativamente as mídias e o manifesto como anexos de EmbeddedFiles (PDF/A-3).
- `history-tracking`: Ao invés de apenas abrir o PDF final, invoca o "ExpressFormScreen" em estado populado e envia o "id_sessao" ao visualizador.

## Impact

- **Storage (Isar)**: O Isar deixará de inflar. A tabela `SubmissionRecord` guardará apenas o `protobufPath`.
- **API (Rust)**: O core em Rust para a manipulação do PDF deve suportar anexação explícita.
- **Modelos**: Os modelos do Flutter e Protos precisarão ser fortemente alterados (quebra de compatibilidade em relatórios antigos não migrados).
