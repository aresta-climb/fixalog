# Fixalog (Aplicativo Móvel)

Aplicativo móvel em **Flutter** para inventário, auditoria técnica e laudos periciais de proteções em vias de escalada.

Consulte a documentação completa no [README principal](../README.md).

## Execução Rápida

```bash
# Obter dependências
flutter pub get

# Executar em dispositivo ou emulador
flutter run

# Executar testes unitários e receitas permanentes de regressão
flutter test

# Executar campanha exploratória do Robô Caótico (ex: 60s, Sentry ativo por padrão)
flutter test test/caos/robo_caotico_exploratorio_test.dart --dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=60

# Assistir o Robô Caótico ao vivo em emulador/dispositivo conectado
flutter test integration_test/robo_caotico_dispositivo_test.dart --dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=60
```

Consulte [`test/caos/README.md`](test/caos/README.md) para detalhes completos sobre o Robô Caótico, shrinking `ddmin` e reprodução de receitas `.json`.
