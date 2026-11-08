# Spec Delta

## ADDED Requirements

### Requirement: Exibição Fiel do Status de Sincronização em Nuvem e Ações de Nuvem no Histórico
A tela de Histórico (`HistoryScreen`) DEVE (MUST) exibir o indicador visual de nuvem em cada card de registro `GERADO` refletindo estritamente o valor real do campo `enviadoNuvem` (`enviado_nuvem` no SQLite):
- Quando `enviadoNuvem == true`, DEVE (MUST) exibir o ícone de sincronização concluída (`Icons.cloud_done_outlined`);
- Quando `enviadoNuvem == false`, DEVE (MUST) exibir o ícone de sincronização pendente (`Icons.cloud_upload_outlined`) e permitir acionar a sincronização manual ou compartilhar o link web (`https://fixalog.app/v/<idSessao>`) através do card ou menu de opções do registro.

#### Scenario: Diferenciação visual entre relatório sincronizado e relatório pendente de envio
- **WHEN** o usuário abre a tela de Histórico contendo um relatório `GERADO` já sincronizado (`enviadoNuvem == true`) e outro relatório `GERADO` gerado offline (`enviadoNuvem == false`)
- **THEN** o card do relatório sincronizado exibe o ícone de nuvem concluída e o card do relatório offline exibe o ícone de upload pendente

#### Scenario: Acionamento manual de sincronização a partir do Histórico
- **WHEN** o usuário aciona a opção de sincronizar na nuvem em um relatório com `enviadoNuvem == false` na tela de Histórico (ou toca no ícone de upload pendente) com conexão ativa à internet
- **THEN** o sistema envia o pacote `.epub` (e eventuais materiais dependentes) para a nuvem e atualiza o ícone do card para sincronizado (`enviadoNuvem = true`)
