# Especificação Técnica: FixaLog

## 1. Resumo Executivo
O FixaLog é um aplicativo mobile "offline-first" destinado à comunidade de escalada (conquistadores, mantenedores e associações). A sua principal finalidade é padronizar e auditar tecnicamente a manutenção de vias de escalada. Através de um "engine" de UI dinâmico alimentado por esquemas Protobuf/YAML, o app guia o mantenedor em formulários "passo a passo" diretamente na base da via. Ao concluir a coleta – que engloba dados em texto, geolocalização e mídias (fotos e vídeos curtos) – o app gera PDFs de relatórios offline e arquivos YAML encapsulando integridade criptográfica (assinatura digital e marcação de tempo por hardware de GPS). Essa integridade garante que o serviço auditado se torne não repudiável assim que a auditoria finaliza.

## 2. Requisitos

### 2.1 Casos de Uso Principais
1. **Configuração inicial do Perfil**: O usuário precisa, ao abrir o app pela primeira vez, informar seu nome, clube/associação, e autorizar a geração de chaves assimétricas no dispositivo.
2. **Seleção e Execução Guiada**: O usuário seleciona o protocolo de manutenção desejado a partir de uma lista local e o app apresenta uma sequência baseada no protocolo.
3. **Validação de Preenchimento**: Impede o avanço ou a geração do relatório se campos obrigatórios não forem preenchidos.
4. **Geração e Histórico**: Ao finalizar, compila os dados, gera PDF e YAML e salva no histórico, permitindo reabrir como nova versão.

### 2.2 Requisitos Funcionais
* **Engine de Formulários Dinâmico:** Leitura e interpretação robusta de modelos Protobuf baseados em configuração, permitindo a construção "on-the-fly" da tela nativamente baseada nas diretrizes ditadas. Tipagem de campos dinamicamente:
  * Texto curto / longo
  * Numérico (ex. quantidade de proteções, torque)
  * Múltipla escolha / dropdown
  * Booleano (Sim/Não)
  * Captura de mídia (foto/vídeo complementar obrigatória)
  * Data/Hora
  * Localização/GPS
* **Offline-First Absoluto:** Todo o processo deve acontecer sem conexão com a internet. O histórico de PDF/YAML, assinatura em device e navegação não podem incorrer bloqueios de dependência de APIs em nuvem.
* **Geração de PDF e Metadados (YAML):** O relatório deverá ter template estático pré-embarcado sendo gerado pelo framework PDF nativo e exportando YAML assinado com dados essenciais codificados (ex. imagens do grampo em base64).
* **Assinatura e Integridade (Criptografia & GPS Time):** O GPS ditará o "Timestamp" para prevenir alteração do relógio do celular e assegurar prova temporal inquestionável. Ademais, inclui-se a **Assinatura Visual** (captura do "de acordo" manuscrito na tela do dispositivo) e de forma sistêmica cada dispositivo e perfil de mantenedor terá par de chaves auto-geradas (Self-Signed) gerenciadas de forma a colocar o hash de transação dentro da assinatura criptográfica JWS no PDF/YAML.
* **Gestor de Histórico:** Interface de registro do histórico contendo auditorias geradas, com possibilidade de duplicá-las e editar sobre cópias.
* **Integração Google Drive e Exportação Nativamente:** Backups massivos para pastas da nuvem pré-selecionadas de forma manual (quando houver link web).

### 2.2 Requisitos Não Funcionais
* **Plataforma Core:** iOS e Android **(via Flutter)** garantindo interoperabilidade total com hardware embarcado.
* **Linguagem e Localização:** Todo UI, documentação de código e arquitetura desenhadas prioritariamente em português do Brasil.
* **Armazenamento e Prevenção à Perda de Dados:** Evitar persistências em pastas "cache". Deve-se buscar diretório seguro (Application Support ou Externo onde suportado) visando prevenir perdas se houver problemas sistêmicos.
* **Performance UX:** Interface responsiva contínua (UI não pode colapsar sob compressões de foto ou processamentos de criptografia, devendo rodar processos no Isolates).

## 3. Arquitetura e Stack Tecnológica
A stack tecnológica escolhida para solucionar a requisição com excelência e solidez técnica no Flutter moderno:

* **Framework:** **Flutter (Linguagem Dart)**.
* **Banco de Dados Local:** **Isar Database**. Optamos pelo Isar por se destacar com suporte a isolados e velocidade síncrona excelente para serialização offline. Ele suporta schemas fortemente tipados perfeitamente interligáveis aos nossos modelos Protobuf. 
* **Gerenciamento de Estado:** **Riverpod** em conjunto ao suporte a **Riverpod Hooks**. Essencial para separar o ciclo de vida UI e a transmutação gradual do formulário sem corromper dependências da árvore widget. Extremamente útil do começo ao fim dos passos.
* **Serialização e Modelos:** Inicialização pura gerada com o compilador **Protobuf**, lendo/salvando templates da base em formato **YAML**.
* **Engine de PDF:** Pacote **pdf** oficial Dart (criação programática do documento) e **printing** (se exigido layout de impressão no celular).
* **Segurança e Criptografia:** **flutter_secure_storage** guardará a private key contida na chave RSA/ECDSA e geração da assinatura (JWS) usando abstrações estritas da **pointycastle** com auxílio nativo nas hash functions.

### Design de Componentes Arquiteturais (Draft)
- `ProtocolRepository`: Gerencia o consumo e conversão de schemas (de `Asset/Remote` -> `Protobuf obj`).
- `WizardStateController`: Mantém controle do formulário transiente rodando in-memory e provê revalidação ao pressionar o botão 'Next'.
- `ReportGeneratorService`: Serviço que processa background isolates para (1) Buscar Localização, (2) Redimensionar imagens pesadas, (3) Assinar a payload e compilar o .pdf. 
- `LocalStorageManager (Isar)`: Camadada persistente onde será salvo o metadado `Report` contendo apontamentos de data/path do final formatado.

## 4. UX e Requisitos Visuais
* **Sistema "Thermomix" de Navegação:** Operado quase 100% de base por "Cards modais expandidos/Steps em tela cheia". Esta quebra tira o cansaço do usuário na base da via e força-o mentalmente numa pergunta de cada vez de forma estrita. 
* **Modo Acessibilidade (Outdoor/Sol):** Textos legíveis e cores primárias com contraste gritante visando combate aos reflexos intensos do monitor e da rocha. Fundamental não esconder coisas sob menus não contrastantes e finos. Estilo visual limpo, espaçoso e flat.
* **Animações e Háptica (Haptic Feedback):** Essencial o uso de vibrações curtas para confimação de foto e transição de botões devido as interferências ou luvas utilizadas para manutenção de EPIs na parede.

## 5. Gerenciamento de Estado e Ciclo de Vida de Preenchimento
1. Estado "Idle" mantido no banco Isar em modo lista contendo Formulários Concluídos e Protocolos Prontos.
2. Início do registro instaura um escopo temporário no **Riverpod** `Formulário Em Andamento`. À medida que responde cada pergunta ou submeta as mídias, atualiza a cache. 
3. Ao finalizar, botão submeter comanda ação para Service responsável rodar `compute` limitando uso de memória. Os artefatos PDF/YAML retornam salvos para diretório do app. Provider do andamento será destruído limpando lixo na memória. Base notifica que lista de "Hitóricos" tem integrante novo.

## 6. Estrutura de Dados (Exemplo Conceitual em YAML)
Abaixo está o modelo abstrato base sobre como o Protobuf interpretará um modelo do formato YAML para criação de formulários (protocolos):
```yaml
protocolo:
  id: "acec_mg_rebolting_v1"
  nome: "Manutenção de Ferragens - ACEC-MG"
  campos:
    - id: "tipo_ancoragem"
      label: "Tipo de Ancoragem"
      tipo: "DROPDOWN"
      opcoes: ["Mecânica (Parabolt)", "Química (Resina)"]
    - id: "foto_instalacao"
      label: "Foto do Grampo Instalado"
      tipo: "IMAGE"
      obrigatorio: true
```

## 7. Critérios de Aceite
* O mantenedor consegue gerar um PDF completo offline em menos de 2 minutos após o trabalho na base da via.
* O PDF gerado aberto no rastreio da aplicação ou num Acrobat local acusará a validação da assinatura se intacto. 
* A documentação de exportação (PDF e YAML) tem pronto-suporte via intenções nativas de OS (Share Menu iOS/Android).
