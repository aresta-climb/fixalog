## Why

Precisamos de uma versão funcional end-to-end (e2e) do aplicativo antes de continuar aprimorando interfaces complexas. O desenvolvimento "Tracer Bullet" (ou Walking Skeleton) mitiga os riscos de integração, permitindo que a fundação do aplicativo (coleta na UI -> conversão Protobuf -> exportação PDF) seja validada imediatamente. Além disso, ter um MVP rodando agiliza ciclos de feedback.

## What Changes

- Criação de uma tela simples de Formulário Expresso (adicionar fotos e descrições).
- Inclusão de um fluxo de solicitação de permissões (Câmera e GPS) antecedido pela apresentação dos Termos de Uso.
- Persistência da versão dos Termos de Uso aceitos utilizando a base Isar (`AppConfigRecord`).
- Integração das capacidades do dispositivo: geolocalização automática e captura de câmera.
- Criação de um gerador de relatório que mapeia a UI para a estrutura padrão em Protobuf (`RegistroManutencao`, `RegistroVia` e lista de `DetalheAcaoCustomizada`) e exporta o resultado em PDF.
- Acesso à nova funcionalidade através de um botão destacado na `HomeScreen`.

## Capabilities

### New Capabilities
- `express-form`: Permite criar registros em campo contendo múltiplas fotos e descrições, associando as coordenadas GPS automaticamente na exportação para PDF.
- `onboarding-terms`: Fluxo para apresentação, aceite e persistência da versão dos Termos de Uso no banco Isar, garantindo respaldo para as requisições de permissões nativas.

### Modified Capabilities

## Impact

- **Roteamento Inicial**: Atualização da lógica no `_StartupRouter` (`main.dart`) para checar os Termos de Uso.
- **Dependências**: Adição dos packages `image_picker`, `geolocator` e `permission_handler` no `pubspec.yaml`.
- **Navegação**: O `home_screen.dart` ganhará uma nova rota.
- **Armazenamento**: Inclusão de uma nova coleção Isar (`AppConfigRecord`) implicando uma pequena alteração no banco local e possível migração futura.
