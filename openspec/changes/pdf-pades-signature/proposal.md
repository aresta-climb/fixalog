## Why

Necessidade de garantir a integridade absoluta dos laudos gerados no dispositivo móvel (vídeos, áudios, imagens e formulários) sem consumir excesso de memória RAM (evitando *Out of Memory*), garantindo validade de Assinatura Eletrônica (Selo FixaLog) sem a necessidade de chaves privadas do usuário final.

## What Changes

- Geração assíncrona de arquivos PDF/A-3 com vídeos e áudios embutidos invisivelmente.
- Implementação de um pipeline de compressão pragmático usando pacotes nativos do Flutter para reduzir o tamanho de mídias antes da anexação.
- Criação de um núcleo em Rust (via `flutter_rust_bridge`) para realizar *streaming hash* (leitura e hash do disco sem onerar RAM) e assinar arquivos gigantes.
- Uso de Certificado Autoassinado internamente (com futura substituição por e-CNPJ) para atestar a integridade do pacote gerado.
- Exibição de progresso granular na UI consumindo Streams via Riverpod.
- **Estruturação rigorosa "Library-First"**: O núcleo Rust e os serviços Dart serão isolados em bibliotecas autossuficientes e altamente testáveis.
- **Adoção imperativa de TDD**: 100% de cobertura de testes unitários e testes de integração escritos antes do código de produção (Red-Green-Refactor).

## Capabilities

### New Capabilities
- `pdf-generator`: Rascunho visual do laudo, organizando *thumbnails* (vídeo) e ícones (áudio) com links navegáveis (GoToE) apontando para os anexos.
- `media-compressor`: Funil de transcodificação utilizando o FFmpeg e aceleradores nativos para achatar mídias antes da assinatura.
- `crypto-signer`: Orquestrador de baixo nível em Rust que manipula dicionários de PDF (`lopdf`), calcula o SHA-256 respeitando o `ByteRange`, empacota um envelope CMS/PKCS#7 (PAdES) e o injeta diretamente no disco.

### Modified Capabilities

- 

## Impact

- **Build/DevOps:** Adição de toolchain do Rust e configuração do `flutter_rust_bridge` no pipeline de CI/CD para compilar bibliotecas C++ para Android e iOS.
- **Qualidade de Software:** Rigor absoluto nos testes (`_test.dart` e `_test.rs`) para atingir 100% de *unit test coverage*, começando pelos testes de integração.
- **Armazenamento:** Modifica a forma como os dados temporários (`.tmp`) são salvos e requer uma rotina de *Garbage Collection* no boot do app.
- **Arquitetura State:** Introdução robusta do Riverpod para ouvir eventos inter-processo vindos do Rust.
