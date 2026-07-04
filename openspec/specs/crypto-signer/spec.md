## ADDED Requirements

### Requirement: O sistema DEVE suportar conversão para PDF/A-3
O módulo crypto-signer deve garantir que o documento seja convertido para o padrão PDF/A-3 antes ou durante o processo de assinatura, permitindo anexar arquivos embutidos de forma padronizada.

### Requirement: O sistema DEVE implementar suporte a ByteRange
A assinatura digital deve calcular o hash do documento utilizando o mecanismo de ByteRange para garantir a integridade de todo o PDF, pulando a área reservada para a própria assinatura.

### Requirement: O sistema DEVE reportar Eventos de Progresso FFI
O processo de assinatura deve emitir eventos de progresso através da ponte FFI para notificar a aplicação (UI) sobre o andamento da operação (ex: início do hash, signing, finalização).
