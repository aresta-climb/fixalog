# Documento de Design de Produto: FixaLog

## 1. Visão Geral
**Nome do Produto:** FixaLog  
**Status:** Especificação de Produto (PRD)  
**Plataforma:** Mobile (Flutter)  

O **FixaLog** é uma ferramenta especializada para a recordação técnica e auditoria de manutenções em vias de escalada (ex: rebolting, inspeções visuais, troca de ancoragens, abertura de vias, etc). O aplicativo, através de um sistema guiado de formulários dinâmicos, guia o mantenedor através de protocolos rigorosos de segurança, coleta dados estruturados, informações de geolocalização, evidências fotográficas offline e videos e gera relatórios PDF autoassinados (self-signed) com integridade criptográfica.

## 2. Problema e solução
* **O Problema:** Atualmente, a manutenção de vias sofre com a falta de padronização no registro. Informações cruciais sobre as proteções utilizadas (ex: liga metálica, fornecedor, se atendem normas como EN959 ou UIAA 123), datas de instalação e estado da rocha muitas vezes se perdem ou são registradas de forma caótica.
* **A Solução:** Um aplicativo que força a coleta padronizada através de "Protocolos de Manutenção". O mantenedor escolhe o protocolo (ex: "Protocolo de Rebolting Completo" ou "Inspeção de Rotina"), e o app guia o preenchimento passo a passo no próprio setor de escalada, gerando um PDF oficial e imutável ao final.

## 3. Público-Alvo
* Conquistadores e mantenedores locais de vias de escalada.
* Diretorias técnicas de associações de escalada que necessitam de relatórios formais para arquivamento e prestação de contas.

## 4. Casos de Uso Principais
1.  **Configuração inicial do Perfil**: O usuário precisa, ao abrir o app pela primeira vez, informar seu nome, clube/associação, e autorizar a geração de chaves assimétricas no dispositivo.
2.  **Seleção de Protocolo:** O usuário chega à base da via, abre o app (mesmo sem internet) e seleciona o protocolo de manutenção desejado a partir de uma lista local.
3.  **Execução Guiada:** O app apresenta uma sequência de telas (steps) baseadas no protocolo. O usuário insere textos, seleciona opções em menus suspensos (ex: "Tipo de Chapeleta: Inox 304, 316L, Titânio") e tira fotos das proteções recém-batidas ou do estado da cola/epóxi.
4.  **Validação de Preenchimento:** O app impede o avanço ou a geração do relatório se campos obrigatórios definidos no protocolo não forem preenchidos.
5.  **Geração e Exportação de PDF:** Ao finalizar, o app compila os dados, injeta as fotos redimensionadas e gera um PDF formatado. Quando o usuário tiver conexão, ele compartilha o arquivo via WhatsApp, e-mail ou salva no Google Drive.
6.  **Histórico de Preenchimento**: O usuário pode acessar o histórico de preenchimentos, podendo alterar o formulário preenchido, e, se desejar, gerar um novo PDF com as alterações embutidas. O PDF terá, porém, nova data e assinatura digital, não modificando o PDF anterior. Todo o histórico de PDFs gerados deve também estar disponível.

## 5. Objetivos e Proposta de Valor
* **Padronização Técnica:** Eliminar registros informais, forçando a coleta de dados conforme normas internacionais (UIAA 123, EN959) e protocolos de associações (ex: ACEC-MG).
* **Segurança Jurídica:** Prover um rastro de auditoria imutável sobre quem realizou a manutenção, quais materiais foram usados e qual o estado da rocha.
* **Memória Institucional:** Criar um histórico técnico confiável para clubes e associações de escalada.
* **Operação em Campo:** Funcionalidade 100% offline para uso em setores remotos de escalada.

## 6. Personas
1.  **O Mantenedor/Conquistador:** Técnico que executa o trabalho na rocha e precisa de uma forma ágil, porém rigorosa, de documentar o serviço sem depender de papel ou sinal de internet.
2.  **O Diretor Técnico da Associação:** Responsável por auditar as manutenções, validar a qualidade dos materiais (ligas metálicas, químicos) e arquivar os relatórios para gestão de risco.

## 7. Requisitos Funcionais

### 7.1 Engine de Protocolos Dinâmicos (Core)
O núcleo do aplicativo. A interface de formulário não deve ser "hardcoded". Ao invés disso, o app deve renderizar formulários dinamicamente a partir de uma estrutura intermediária (Protobuf ou YAML).  
* O app deve ler arquivos de configuração (estruturados via Protobuf para eficiência e tipagem, e salvos em YAML para fácil leitura/escrita humana pré-compilação) e renderizar a UI dinamicamente.
* **Tipos de Campos suportados pelo engine:**
    * `Texto curto / longo`
    * `Numérico`(ex. quantidade de proteções, bitola da broca, torque)
    * `Múltipla escolha / dropdown` (ex tipo de liga: 304, 316L, Titânio)
    * `Booleano` (Sim/Não)
    * `Captura de mídia` (foto obrigatória do grampo/chapeleta instalada, vídeo do resultado)
    * `Data/Hora`
    * `Localização/GPS` (coordenadas da base da via, se disponível)
* Cada campo pode ser obrigatório ou opcional, a depender da configuração.
* **Lógica de Sequência:** O usuário seleciona o protocolo (ex: Rebolting Químico, Inspeção Visual Anual) e o app define os campos obrigatórios e a ordem de preenchimento.

### 7.2 Sistema Offline-First
* Como as manutenções ocorrem em setores de rocha frequentemente sem sinal, **toda** a navegação, interpretação de protocolos, captura de fotos e geração do PDF deve ocorrer 100% offline.

### 7.3 Fluxo de Trabalho Guiado
* **Checklist de Início:** Verificação de EPIs e materiais antes de iniciar o registro.
* **Registro Passo a Passo:** Captura de dados por proteção (grampo/chapeleta), permitindo associar fotos específicas a cada ponto de ancoragem.
* **Validação:** Bloqueio da geração do relatório caso itens críticos de segurança não sejam preenchidos.

### 7.4 Gestão de Mídia
* O aplicativo deve capturar fotos diretamente pela câmera ou galeria.
* **Processamento de Imagem:** Redimensionamento e compressão automática offline para manter o PDF leve.

### 7.5 Geração de Relatórios (PDF Engine)
Criação de um documento PDF formatado com cabeçalho institucional, metadados da via, tabela de componentes instalados e anexo fotográfico.
* Template visual embutido no app (cabeçalho, metadados da via, corpo do formulário preenchido, grid de fotos).
* Injeção automática da data de geração e assinatura digital/nome do mantenedor.

### 7.6 Geração de metadados (YAML)
Além do PDF, o app deve exportar os dados brutos estruturados (em formato YAML) contendo uma assinatura digital embutida (ex: JWS) para permitir a ingestão e auditoria automatizada desses dados por sistemas de terceiros. Esse arquivo YAML vai ser basicamente uma versão serializada do protobuf que representa o formulário do usuário, mas em formato YAML, contendo inclusive mídia em base64. 

### 7.7 Assinatura e Segurança
* **Assinatura Visual:** Captura do "de acordo" manuscrito na tela do dispositivo.
* **Assinatura Criptográfica (Self-Signed):** * Geração de par de chaves (RSA/ECDSA) único por dispositivo/usuário.
    * Armazenamento seguro da chave privada (Keystore/Keychain).
    * Assinatura do hash do PDF gerado para garantir que o documento não seja alterado após a saída da base da via.
* **Timestamp Autêntico (GPS Time):** Para mitigação de fraudes de data em ambiente offline, a aplicação deverá obter o timestamp diretamente do hardware de GPS (imune à alteração local de relógio do usuário) e embuti-lo no pacote assinado criptograficamente.

### 7.8 Histórico de preenchimento
Todo preenchimento deve ser salvo em uma seção de histórico no app, permitindo que o usuário altere o formulário preenchido, duplicando o registro para uma nova edição, e, se desejar, gerar um novo PDF com as alterações embutidas. O PDF terá, porém, nova data e assinatura digital, não modificando o PDF ou registro anterior. Todo o histórico de PDFs e registros gerados deve também estar disponível.

### 7.9 Integração com o Google Drive
Será possível especificar uma pasta no Google Drive para backup automático de todos os relatórios gerados, tanto em PDF quanto em YAML. O usuário poderá, a qualquer momento, clicar em um botão para fazer a sincronização com o Google Drive automaticamente. Isso não impede o usuário de compartilhar os documentos com as ferramentas tradicionais de compartilhamento do dispositivo em que está usando.

### 7.10 Estilo da UI
O app deve seguir o estilo visual de instruções e passos do aplicativo da Thermomix, através do uso de 'cards' para cada passo, com navegação entre passos por botões de 'próximo' e 'anterior', além de scroll para trás e para frente, e um botão de 'concluir' para finalizar o preenchimento.

## 8. Requisitos Não Funcionais
* **Arquitetura:** Flutter para garantir portabilidade e consistência de UI.
* **Offline-First:** O app não deve exigir conexão para nenhuma etapa do processo de registro ou geração de PDF.
* **Sincronização:** Quando online, permitir o upload do PDF para nuvens como o Google Drive.
* **Serialização:** Uso de Protocol Buffers (Protobuf) para comunicação eficiente de schemas de protocolos.
* **Performance:** A renderização dos formulários dinâmicos não pode ter atrasos (UI thread livre), mesmo com protocolos que exijam mais de 20 campos e múltiplas fotos.
* **Armazenamento**: O app deve armazenar localmente todos os registros de preenchimento e PDFs gerados, permitindo o acesso offline a todo o histórico. Esse armazenamento deve ser seguro e persistente, salvo em uma pasta do disco do usuário, e não sendo apagado em caso de desinstalação do app.
* **Linguagem**: todo o aplicativo deve estar em português, incluindo o código-fonte (comentários e documentação).

## 9. Estrutura de Dados (Exemplo Conceitual)
```yaml
protocolo:
  id: "acec_mg_rebolting_v1"
  nome: "Manutenção de Ferragens - ACEC-MG"
  campos:
    - id: "tipo_ancoragem"
      label: "Tipo de Ancoragem"
      tipo: "DROPDOWN"
      opcoes: ["Mecânica (Parabolt)", "Química (Resina)"]
    - id: "material_liga"
      label: "Liga Metálica"
      tipo: "DROPDOWN"
      opcoes: ["Aço Inox 304", "Aço Inox 316L", "Aço Carbono Zincado", "Titânio"]
    - id: "foto_instalacao"
      label: "Foto do Grampo Instalado"
      tipo: "IMAGE"
      obrigatorio: true
```

## 10. Critérios de Aceite
* O usuário consegue gerar um PDF completo em menos de 2 minutos após terminar o trabalho físico.
* O PDF aberto no Adobe Acrobat (ou similar) deve indicar se a assinatura é válida ou se o documento foi adulterado.
* O app deve permitir a exportação imediata do PDF via protocolos de compartilhamento do sistema (WhatsApp, E-mail, Drive).

## 11. Detalhes ainda a definir 
A partir deste documento, a technical spec deverá focar em:
1.  Definir os arquivos `.proto` exatos que modelarão os `Protocolos` e as `Respostas` (parte da especificação).
2.  Definir qual banco de dados local será utilizado para o cache offline e armazenamento do histórico (ex: SQLite, Isar, Hive, Moor).
3.  Escolher a biblioteca de geração de PDF e assinatura digital no ecossistema Dart/Flutter (ex: pacote `pdf`).
4.  Desenhar a arquitetura de estado (ex: Bloc, Riverpod ou Provider) para gerenciar o estado efêmero do formulário dinâmico enquanto o usuário avança pelos "steps".