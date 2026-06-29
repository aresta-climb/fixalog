## Why

Atualmente, o aplicativo exporta relatórios em PDF com um texto indicando um "Hash SHA-256" e uma "Assinatura" gerados customizadamente sobre o Protobuf. Apesar de garantir integridade, isso não é reconhecido nativamente por leitores de PDF padrão (como o Adobe Acrobat). Implementar a assinatura PKCS#7 nativa diretamente no arquivo PDF utilizando metadados XMP reais trará validação de integridade transparente e nível corporativo ao aplicativo. Além disso, adicionar a defesa contra "Fake GPS" e seguir estritamente o PRINCIPIOS.md (TDD e 100% Test Coverage) garantirá a resiliência corporativa deste módulo crítico.

## What Changes

- **TDD & 100% Coverage**: O desenvolvimento seguirá estritamente a prática de TDD, assegurando cobertura total (100%) por testes unitários das novas regras.
- Implementar PKI do zero com geração de par de chaves ECDSA (secp256r1).
- Gerar Certificado X.509 Autoassinado (CN=[Nome], O=FixaLog) sob demanda.
- Exigir biometria (Face ID / Touch ID) para desbloquear a chave privada.
- **Assinatura e Integridade via XMP**: Embutir o binário do Protobuf e a Chave Pública no formato PEM dentro dos metadados XMP invisíveis do PDF.
- Assinar os metadados usando ECDSA puro, gerando uma assinatura que pode ser auditada por scripts de verificação (ex: Python). 
- Rejeitar ativamente coordenadas marcadas com a flag isMocked.
- Adicionar o campo attestation_token ao Protobuf.

## Capabilities

### New Capabilities
- pdf-xmp-signature: Assinatura de relatórios utilizando curva elíptica (ECDSA) e injeção do Certificado e Assinatura em metadados XMP, garantindo integridade sem custo de bibliotecas comerciais PDF.
- biometric-vault: Desbloqueio seguro de chaves criptográficas sob exigência de biometria local.
- anti-fraud-location: Deteccção e bloqueio da emissão de relatórios quando o sistema operacional reporta fraude nas coordenadas via Mock Location.

### Modified Capabilities

## Impact

- **Testes**: Introdução de extensos mocks (mocktail ou equivalentes) para local_auth e operações do sistema de arquivos para atingir os 100% de coverage previstos no PRINCIPIOS.md.
- **Packages**: Inclusão de pointycastle, asic_utils e local_auth. 
- **Sistema Operacional**: Mudança em AndroidManifest.xml (USE_BIOMETRIC) e Info.plist (NSFaceIDUsageDescription).
