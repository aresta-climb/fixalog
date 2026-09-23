## 1. Configuração Nativa Android e iOS

- [ ] 1.1 Atualizar `app/android/app/build.gradle.kts` definindo `namespace = "com.arestaclimb.fixalog"` e `applicationId = "com.arestaclimb.fixalog"` e verificar com inspeção no arquivo
- [ ] 1.2 Mover a pasta Kotlin de `com/arestaclimb/fixlog` para `com/arestaclimb/fixalog`, atualizar `MainActivity.kt` com `package com.arestaclimb.fixalog` e verificar a existência do novo caminho
- [ ] 1.3 Atualizar `app/android/app/src/main/AndroidManifest.xml` com `android:label="Fixalog"` e verificar a chave no manifesto
- [ ] 1.4 Atualizar `app/ios/Runner.xcodeproj/project.pbxproj` alterando todas as instâncias de `PRODUCT_BUNDLE_IDENTIFIER` para `com.arestaclimb.fixalog` e verificar com busca no arquivo
- [ ] 1.5 Atualizar `app/ios/Runner/Info.plist` definindo `CFBundleDisplayName` como `Fixalog` e `CFBundleName` como `fixalog` e verificar o XML gerado

## 2. Pacote Flutter e Refatoração de Imports Dart

- [ ] 2.1 Atualizar `app/pubspec.yaml` definindo `name: fixalog` e executar `flutter pub get` no diretório `app`
- [ ] 2.2 Substituir sistematicamente todas as ocorrências de `package:fixlog/` por `package:fixalog/` nos arquivos do diretório `app/lib/` e validar com busca de texto
- [ ] 2.3 Substituir sistematicamente todas as ocorrências de `package:fixlog/` por `package:fixalog/` nos arquivos dos diretórios `app/test/` e `app/integration_test/` e validar com busca de texto
- [ ] 2.4 Renomear a classe principal de `FixLogApp` para `FixalogApp` e a propriedade `title` para `'Fixalog'` em `app/lib/main.dart` e sincronizar as instanciações nos testes unitários e de integração

## 3. Identidade de Telas, Laudos e Documentações

- [ ] 3.1 Atualizar menções textuais de `FixLog` para `Fixalog` em títulos de diálogos, assuntos de e-mail/compartilhamento de relatórios e mensagens de interface em `app/lib/features/`
- [ ] 3.2 Atualizar o pacote autônomo `ferramentas/atualizador_legal/` (descrição no `pubspec.yaml`, logs e testes de integridade) para referenciar `Fixalog`
- [ ] 3.3 Sincronizar as referências na documentação do projeto e preparar a especificação de branding

## 4. Garantia de Qualidade e Cobertura (@qa)

- [ ] 4.1 Executar análise estática de código com `flutter analyze` e garantir zero erros e zero advertências
- [ ] 4.2 Executar a suíte de testes unitários com cobertura (`flutter test --coverage`) e comprovar 100% de cobertura de código conforme o `PRINCIPIOS.md`
- [ ] 4.3 Executar os testes de integração para validar a inicialização de `FixalogApp` e o fluxo dos termos de uso
- [ ] 4.4 Pausar para revisão e aprovação explícita do usuário (@pm constraint)
