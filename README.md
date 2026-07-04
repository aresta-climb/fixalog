# FixaLog

Catalogue suas proteções fixas durantes abertura ou manutenções de vias de
escalada!

## 🛠️ Configuração do Ambiente de Desenvolvimento (Toolchains)

Este projeto utiliza **Flutter** para a interface móvel e um núcleo em **Rust**
para processamento criptográfico de PDFs pesados. Para compilar o aplicativo
localmente, você precisará configurar ambas as toolchains.

### 1. Flutter SDK

Siga as instruções oficiais para instalar o Flutter no seu sistema operacional:
[Instalação do Flutter](https://docs.flutter.dev/get-started/install)

- Certifique-se de rodar `flutter doctor` no terminal e resolver as pendências
  (Android Studio / Xcode).

### 2. Rust (rustup)

Instale o compilador da linguagem Rust via `rustup` (gerenciador oficial):

- **Linux/macOS:** Rode
  `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh` no terminal.
- **Windows:** Baixe e instale o arquivo `rustup-init.exe` em
  [rustup.rs](https://rustup.rs/).

### 3. Alvos de Compilação (Cross-Compilation)

Para que o código Rust compile corretamente para as arquiteturas dos celulares
(ARM/x86), você precisa adicionar os _targets_ através do `rustup`:

```bash
# Adiciona alvos para Android
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android

# Adiciona alvos para iOS (Necessário utilizar macOS)
rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim
```

### 4. Integração Flutter <-> Rust (flutter_rust_bridge)

Nós usamos o `flutter_rust_bridge` para conectar o Dart ao Rust (FFI). Instale o
gerador de código globalmente e a ferramenta para NDK:

```bash
cargo install flutter_rust_bridge_codegen cargo-ndk
```

### 5. Executando o Projeto

Com tudo instalado, sempre que modificar algo na pasta `rust/`, você deve gerar
as pontes de comunicação novamente antes de compilar o app Flutter:

```bash
flutter_rust_bridge_codegen generate
flutter run
```
