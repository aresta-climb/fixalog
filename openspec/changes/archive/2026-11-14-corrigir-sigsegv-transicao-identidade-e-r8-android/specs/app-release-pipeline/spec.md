## MODIFIED Requirements

### Requirement: Suporte Híbrido de Assinatura Android e Conformidade iOS
O projeto Android DEVE suportar assinatura de release via variáveis de ambiente e arquivo local, configurar explicitamente a minificação R8 Full Mode (`android.enableR8.fullMode=true`), a redução otimizada de recursos (`isShrinkResources = true` com `android.r8.optimizedResourceShrinking=true`), regras ProGuard (`proguard-rules.pro`) e geração de tabela de símbolos nativos (`ndk.debugSymbolLevel = "SYMBOL_TABLE"`), e o projeto iOS DEVE declarar conformidade de criptografia adequada para distribuição automatizada no TestFlight.

#### Scenario: Assinatura de Release e Otimização R8 no Gradle
- **WHEN** o build de release Android for executado em ambiente com variáveis de ambiente ou com arquivo `key.properties`
- **THEN** o `build.gradle.kts` DEVE utilizar essas credenciais e aplicar `isMinifyEnabled = true`, `isShrinkResources = true`, `proguard-rules.pro` e `debugSymbolLevel = "SYMBOL_TABLE"`, com `android.enableR8.fullMode=true` e `android.r8.optimizedResourceShrinking=true` ativos no `gradle.properties`, gerando um artefato `.aab` assinado e símbolos nativos simbolicáveis

#### Scenario: Conformidade de Criptografia no iOS
- **WHEN** o pacote iOS for inspecionado para upload no TestFlight
- **THEN** a chave `ITSAppUsesNonExemptEncryption` com valor booleano `false` DEVE estar presente no `Info.plist`
