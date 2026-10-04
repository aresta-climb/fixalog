# Fixalog

> **Aplicativo de inventário, auditoria técnica e laudos periciais de proteções fixas em vias de escalada.**

O **Fixalog** é uma ferramenta de campo desenvolvida para conquistadores, mantenedores e entidades de montanhismo catalogarem, auditarem e emitirem relatórios técnicos verificáveis sobre o estado de conservação de proteções fixas (grampos, chapeletas, paradas, rapéis e ancoragens).

Faz parte do ecossistema de código aberto da **Aresta Climb**.

---

## ⚡ Principais Funcionalidades

- **📱 Funcionamento 100% Offline-First**: Projetado para operar em ambientes remotos de montanha sem conexão à internet, com persistência local reativa via Isar Database.
- **🔐 Laudos Periciais em EPUB 3 com XML-DSig**: Geração de containers padronizados em EPUB 3 contendo fotos e vídeos comprimidos, dados brutos em Protobuf e assinatura digital criptográfica (X.509) do responsável técnico.
- **📄 Sumários Executivos em PDF**: Emissão de relatórios resumidos em PDF com QR Code canônico para validação de autenticidade no domínio `https://fixalog.app/v/<id>`.
- **📍 Auditoria de Localização e Antifraude**: Coleta e validação de coordenadas geográficas (GPS) com marca d'água forense e registro de cadeia de custódia.
- **🎬 Compressão Otimizada de Mídias**: Transcodificação local de fotos e vídeos para manter pacotes leves e portáveis.

---

## 🛠️ Stack Tecnológica

O Fixalog é construído inteiramente em **Flutter/Dart** puro, sem necessidade de toolchains externas ou compiladores de outras linguagens:

- **Framework**: [Flutter](https://flutter.dev) (Dart 3.x)
- **Gerenciamento de Estado**: [Riverpod](https://riverpod.dev)
- **Banco de Dados Local**: [Isar Database](https://isar.dev)
- **Criptografia e Assinatura Digital**: [PointyCastle](https://pub.dev/packages/pointycastle) & X.509
- **Geração de Documentos**: `pdf`, `printing` e `archive` (EPUB 3)
- **Serialização de Protocolos**: [Protocol Buffers (Protobuf)](https://protobuf.dev)
- **Processamento Multimídia**: `flutter_image_compress` e `ffmpeg_kit_flutter_new`

---

## 🚀 Como Começar

### Pré-requisitos

- **Flutter SDK** instalado (Canal `stable`, versão `>=3.11.3`).  
  Siga as instruções oficiais: [Instalação do Flutter](https://docs.flutter.dev/get-started/install).
- **Android Studio** (com Android SDK configurado) ou **Xcode** (no macOS para compilação iOS).

Verifique o seu ambiente executando:
```bash
flutter doctor
```

### Executando o Aplicativo

1. Clone o repositório com os submódulos:
   ```bash
   git clone --recursive https://github.com/aresta-climb/fixalog.git
   cd fixalog/app
   ```

2. Instale as dependências do Flutter:
   ```bash
   flutter pub get
   ```

3. Inicie o aplicativo em seu emulador ou dispositivo físico:
   ```bash
   flutter run
   ```

---

## 🧪 Qualidade de Código e Testes

Conforme estabelecido em nossos [Princípios de Engenharia](PRINCIPIOS.md), mantemos **100% de cobertura de testes unitários** e ciclo rigoroso de TDD (Test-Driven Development).

### Rodando a Suíte de Testes
```bash
cd app
flutter test
```

### Verificando a Cobertura de Código
```bash
cd app
flutter test --coverage
```

### Análise Estática
```bash
cd app
flutter analyze
```

---

## 📂 Estrutura do Repositório

```text
fixalog/
├── app/                  # Código-fonte do aplicativo Flutter (lib/, test/, android/, ios/)
├── docs/                 # Documentações arquiteturais e roteiros de integração
├── ferramentas/          # Utilitários de apoio (ex: atualizador_legal de termos)
├── openspec/             # Especificações de arquitetura e mudanças orientadas a especificação
└── PRINCIPIOS.md         # Princípios fundamentais e inegociáveis de engenharia
```

---

## 📜 Princípios de Engenharia

O desenvolvimento do Fixalog é pautado por cinco regras fundamentais definidas em [PRINCIPIOS.md](PRINCIPIOS.md):
1. **Tudo em Português**: Código, documentação, entidades e testes em português brasileiro.
2. **Library-First**: Módulos autossuficientes e desacoplados.
3. **100% de Cobertura de Testes Unitários**: Inegociável para qualquer entrega.
4. **TDD Obrigatório**: Red-Green-Refactor desde o primeiro teste.
5. **Simplicidade e Anti-Abstração**: Código claro, direto e sem complexidade desnecessária.

---

## 📄 Licença

Distribuído sob os termos da **Mozilla Public License Version 2.0 (MPL-2.0)**. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.
