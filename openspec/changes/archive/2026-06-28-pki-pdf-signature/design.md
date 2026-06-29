## Context

O aplicativo FixaLog transicionará sua prova de integridade em texto para uma infraestrutura PKI verdadeira (PKCS#7). Devido ao ambiente ser totalmente *offline*, usaremos Certificados Autoassinados locais. Em total consonância com o PRINCIPIOS.md, este módulo lida com criptografia e validação de fraudes, o que exige absoluta previsibilidade e estabilidade, alcançada somente via TDD (Test-Driven Development) e 100% de cobertura de testes de unidade.

## Goals / Non-Goals

**Goals:**
- **TDD First**: Alcançar 100% de Unit Test Coverage, escrevendo os testes antes do código de produção.
- Prover integridade inquestionável do Protobuf embutido através de PKCS#7 e metadados XMP.
- Exigir biometria via local_auth no momento da assinatura.
- Prevenir submissões de coordenadas forjadas verificando isMocked nas requisições do geolocator.

**Non-Goals:**
- Implementar "App Attestation" (Play Integrity/DeviceCheck) neste momento. Adicionaremos apenas a propriedade ttestation_token no Protobuf.

## Decisions

1. **Test-Driven Development (TDD)**: Testes de falha e sucesso do CryptoService e da validação isMocked serão construídos usando mocks estritos antes da implementação.
2. **ECDSA (secp256r1) em vez de RSA**: Escolhido para evitar pausas na thread de UI durante a geração das chaves.
3. **Bibliotecas asic_utils & pointycastle**: Decidimos não implementar codificadores ASN.1 puramente artesanais do zero.
4. **Barreira Biométrica (local_auth)**: A assinatura exigirá autenticação biométrica do usuário.
5. **Metadados XMP Limpos**: O Protobuf será injetado no XMP de maneira nativa, sem hashes visíveis.

## Risks / Trade-offs

- **[Risco] Mocar bibliotecas nativas de criptografia e biometria para testes de 100% coverage é complexo** → *Mitigação*: Utilizaremos injeção de dependência (via Riverpod ou injeção por construtor) para fornecer instâncias mocadas do FlutterSecureStorage e do LocalAuthentication aos nossos serviços durante os testes de unidade.
