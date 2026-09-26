## 1. Configuração Nativa e Workflows de CI/CD

- [ ] 1.1 Atualizar `app/android/app/build.gradle.kts` definindo `namespace = "com.arestaclimb.fixalog"` e `applicationId = "com.arestaclimb.fixalog"` e verificar com inspeção no arquivo
- [ ] 1.2 Mover a pasta Kotlin de `com/arestaclimb/fixlog` para `com/arestaclimb/fixalog`, atualizar `MainActivity.kt` com `package com.arestaclimb.fixalog` e verificar a existência do novo caminho
- [ ] 1.3 Atualizar `app/android/app/src/main/AndroidManifest.xml` com `android:label="Fixalog"` e verificar a chave no manifesto
- [ ] 1.4 Atualizar `app/ios/Runner.xcodeproj/project.pbxproj` alterando todas as instâncias de `PRODUCT_BUNDLE_IDENTIFIER` para `com.arestaclimb.fixalog` e verificar com busca no arquivo
- [ ] 1.5 Atualizar `app/ios/Runner/Info.plist` definindo `CFBundleDisplayName` como `Fixalog` e `CFBundleName` como `fixalog` e verificar o XML gerado
- [ ] 1.6 Atualizar os fluxos de CI/CD em `.github/workflows/build_android.yml` (`packageName: com.arestaclimb.fixalog`) e `.github/workflows/build_ios.yml` (`--bundle-id "com.arestaclimb.fixalog"`) e validar integridade do YAML

## 2. Pacote Flutter e Refatoração de Imports Dart

- [ ] 2.1 Atualizar `app/pubspec.yaml` definindo `name: fixalog` e executar `flutter pub get` no diretório `app`
- [ ] 2.2 Substituir sistematicamente todas as ocorrências de `package:fixlog/` por `package:fixalog/` nos arquivos do diretório `app/lib/` e validar com busca de texto
- [ ] 2.3 Substituir sistematicamente todas as ocorrências de `package:fixlog/` por `package:fixalog/` nos arquivos dos diretórios `app/test/` e `app/integration_test/` e validar com busca de texto
- [ ] 2.4 Renomear a classe principal de `FixLogApp` para `FixalogApp` e a propriedade `title` para `'Fixalog'` em `app/lib/main.dart` e sincronizar as instanciações nos testes unitários e de integração

## 3. Governança Arquitetural, Licença SPDX e Certificados

- [ ] 3.1 Atualizar a constante `expectedLine2` em `app/test/architecture/license_headers_test.dart` para esperar `'// Copyright (c) 2026 Fixalog Contributors'`
- [ ] 3.2 Substituir em lote a linha de copyright autoral para `// Copyright (c) 2026 Fixalog Contributors` em todos os arquivos autorais Dart (`lib/`, `test/`) e Kotlin (`android/`), garantindo aprovação no teste de cabeçalhos
- [ ] 3.3 Atualizar o serviço de criptografia `CryptoService` para gerar certificados X.509 com Organization `O=Fixalog` e sincronizar asserções em `crypto_service_test.dart`

## 4. Identidade de Telas, Laudos e URL Canônica

- [ ] 4.1 Atualizar textos de interface, diálogos de conclusão (`GenerationProgressDialog`), assuntos de compartilhamento (`VisualizadorRelatorioScreen`) e fallbacks de laudo (`WizardScreen`, `GenerationProvider`) para `Fixalog`
- [ ] 4.2 Atualizar a URL canônica padrão para `https://fixalog.app/v/$sid` em `VisualizadorRelatorioScreen`, `GenerationProvider`, `PdfPrintSummaryService` e `EpubDocumentBuilder`, sincronizando testes de geração de QR Code e XML
- [ ] 4.3 Atualizar o pacote autônomo `ferramentas/atualizador_legal/` e documentações mantendo a compatibilidade de assets com o submódulo upstream `app/legal/repo`

## 5. Garantia de Qualidade e Cobertura (@qa)

- [ ] 5.1 Executar análise estática de código com `flutter analyze` e garantir zero erros e zero advertências
- [ ] 5.2 Executar a suíte de testes unitários e arquitetura (`flutter test`) comprovando 100% de aprovação e cobertura integral conforme o `PRINCIPIOS.md`
- [ ] 5.3 Executar os testes de integração para validar a inicialização de `FixalogApp` e o fluxo completo do app
- [ ] 5.4 Pausar para revisão e aprovação explícita do usuário (@pm constraint)
