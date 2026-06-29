## ADDED Requirements

### Requirement: O sistema DEVE exigir biometria para uso da chave privada
O acesso ao material criptográfico do usuário (Chave Privada) DEVE ser condicionado à apresentação de uma credencial biométrica válida (Face ID/Touch ID) ou PIN de fallback, mediada pelo sistema operacional.

#### Scenario: Solicitação de biometria ao assinar
- **WHEN** o usuário inicia o fluxo final de assinatura do PDF
- **THEN** o prompt biométrico nativo do OS é exibido, e a operação só avança caso a autenticação seja aprovada
