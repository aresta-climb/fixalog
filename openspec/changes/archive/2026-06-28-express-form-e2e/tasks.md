## 1. Setup & Dependências

- [x] 1.1 Adicionar os packages `image_picker`, `geolocator` e `permission_handler` no `pubspec.yaml`
- [x] 1.2 Configurar permissões de Câmera e Localização nos arquivos nativos (`AndroidManifest.xml` e/ou `Info.plist`)
- [x] 1.3 Rodar `flutter pub get`

## 2. Banco de Dados Local (Isar)

- [x] 2.1 Criar o schema `app/lib/core/models/local/app_config_record.dart` para persistir a `acceptedTermsVersion`
- [x] 2.2 Registrar `AppConfigRecordSchema` no `main.dart` e rodar o `build_runner` para gerar o código `.g.dart`

## 3. Onboarding & Termos de Uso

- [x] 3.1 Criar a view `terms_of_use_screen.dart` com o texto, solicitação de permissões e salvamento no Isar
- [x] 3.2 Atualizar o `_StartupRouter` no `main.dart` para verificar o `AppConfigRecord` antes de ir para HomeScreen ou IdentitySetupScreen

## 4. UI da Home e Formulário Expresso

- [x] 4.1 Adicionar botão "Novo Registro Expresso" na `home_screen.dart`
- [x] 4.2 Criar `express_form_view_model.dart` para gerenciar o estado da lista de (Foto + Descrição) usando Riverpod
- [x] 4.3 Implementar `express_form_screen.dart` com a ListView, FAB de câmera (`image_picker`) e botão "Gerar Relatório"

## 5. Integração Protobuf e PDF Generator

- [x] 5.1 Implementar `express_pdf_generator.dart` capturando GPS via `geolocator` ao gerar o relatório
- [x] 5.2 Mapear os dados da tela (GPS + Fotos/Textos) para o modelo oficial do `RegistroManutencao` (usando `RegistroVia` e `DetalheAcaoCustomizada`)
- [x] 5.3 Implementar a renderização do layout via pacote `pdf` lendo os dados do Protobuf instanciado
- [x] 5.4 Chamar a tela de preview do pacote `printing`
- [x] 5.5 Integrar este gerador ao botão da `ExpressFormScreen`
