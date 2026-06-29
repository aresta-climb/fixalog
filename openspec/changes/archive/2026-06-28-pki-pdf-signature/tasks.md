## 1. Setup & Dependências (Testes e Produção)

- [x] 1.1 Modificar `pubspec.yaml` adicionando dependências: `pointycastle`, `basic_utils`, `local_auth`. Se não existirem, adicionar também `mocktail` e `flutter_test` (dev_dependencies).
- [x] 1.2 Atualizar dependências com `flutter pub get`.
- [x] 1.3 Adicionar permissões biométricas no `AndroidManifest.xml` e no `Info.plist` (iOS).

## 2. Estrutura de Dados Protobuf

- [x] 2.1 Adicionar campo `string attestation_token = 99;` ao arquivo `app/lib/core/models/proto/registro.proto`.
- [x] 2.2 Recompilar as definições rodando o compilador `protoc`.

## 3. Core PKI (CryptoService) em TDD

- [x] 3.1 **[TEST]** Escrever testes de unidade falhos para a geração de Chaves ECDSA e armazenamento no SecureStorage (Mock).
- [x] 3.2 **[IMPLEMENT]** Implementar a geração de Chaves ECDSA no `CryptoService` fazendo os testes de geração passarem.
- [x] 3.3 **[TEST]** Escrever testes de unidade falhos garantindo que um Certificado X.509 autoassinado (`CN=Nome, O=FixaLog`) é gerado corretamente.
- [x] 3.4 **[IMPLEMENT]** Implementar a geração de Certificado X.509 via `basic_utils` fazendo os testes passarem.
- [x] 3.5 **[TEST]** Escrever testes falhos para `getPdfSigner()` que exijam validação da biometria via mock de `LocalAuthentication`.
- [x] 3.6 **[IMPLEMENT]** Implementar `getPdfSigner()` com `local_auth` fazendo os testes passarem.

## 4. Integração do PDF e Prevenção de Fraudes em TDD

- [x] 4.1 **[TEST]** Escrever testes falhos para o ExpressPdfGenerator garantindo que lance exceção quando a Position tiver isMocked == true.
- [x] 4.2 **[IMPLEMENT]** Adicionar a validação if (position.isMocked) na extração do GPS.
- [x] 4.3 **[TEST]** Escrever testes que validem a injeção do Protobuf Base64 no XmlBuilder e o acionamento do `getPdfSigner()` (mocado).
- [x] 4.4 **[IMPLEMENT]** Injetar a assinatura PKCS#7 e o XMP no `pw.Document` e remover os rodapés visuais antigos.
- [x] 4.5 Executar cobertura total de testes (`flutter test --coverage`) e confirmar 100% de coverage nas classes alteradas.

## 5. Testes Manuais Finais

- [x] 5.1 Rodar a aplicação no emulador/dispositivo real e garantir que o *prompt* biométrico é acionado com sucesso.
- [x] 5.2 Avaliar arquivo PDF final exportado num leitor compatível verificando a tag de assinatura e o XMP com o script de validação Python.
