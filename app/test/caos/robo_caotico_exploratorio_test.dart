// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fabrica_dataset_caos.dart';
import 'motor_robo_caotico.dart';

/// Duração da campanha exploratória em segundos.
///
/// Por padrão é `0` para que o `flutter test` do dia a dia faça skip automático
/// (executando apenas os caminhos já salvos em `regressao_caminhos_test.dart`).
/// Para rodar sob demanda ou no workflow de pré-release (`release_new_app_version.yml`),
/// passe `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=15` (ou `300` para 5 minutos).
const int kDuracaoCampanhaCaosSegundos = int.fromEnvironment(
  'DURACAO_CAMPANHA_CAOS_SEGUNDOS',
  defaultValue: 0,
);

/// Define se o Sentry deve permanecer liberado e receber as falhas e receitas geradas.
///
/// Habilitado por padrão (`true`) nas campanhas exploratórias usando o `kSentryDsn` já configurado no app.
const bool kReportarSentryCaos = bool.fromEnvironment(
  'REPORTAR_SENTRY_CAOS',
  defaultValue: true,
);

/// Semente inicial opcional (`--dart-define=SEED_INICIAL_CAOS=...`).
///
/// Quando não informada (`0`), gera uma semente aleatória via `Random.secure()` (`/dev/urandom` / CSPRNG do SO)
/// para explorar novos caminhos a cada execução mantendo reprodutibilidade total via receita `.json`.
const int kSeedInicialCaosConfigurada = int.fromEnvironment(
  'SEED_INICIAL_CAOS',
  defaultValue: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Robô Caótico Fixalog - Campanha Exploratória Determinística', () {
    late AmbienteAppCaos ambiente;

    setUp(() async {
      ambiente = await AmbienteAppCaos.inicializar();
    });

    tearDown(() async {
      await ambiente.limpar();
    });

    testWidgets(
      'Explora o FixalogApp completo com datasets normal e tóxico sem crashes ou erros (${kDuracaoCampanhaCaosSegundos}s)',
      (tester) async {
        final diretorioSaida = Directory('test/caos/caminhos_regressao');
        final motor = ambiente.criarMotor(
          tester: tester,
          diretorioSaidaReceitas: diretorioSaida,
          reportarAoSentry: kReportarSentryCaos,
        );

        final seedInicialEfetiva = resolverSeedInicialCampanha(
          kSeedInicialCaosConfigurada,
        );
        debugPrint(
          '🎲 [Robô Caótico Fixalog] Iniciando campanha exploratória com seedInicial=$seedInicialEfetiva...',
        );

        final relatorio = await motor.executarCampanhaPorTempo(
          duracaoMaxima: const Duration(seconds: kDuracaoCampanhaCaosSegundos),
          maxPassosPorSessao: 20,
          seedInicial: seedInicialEfetiva,
        );

        expect(relatorio.totalSessoesExecutadas, greaterThanOrEqualTo(2));

        if (relatorio.falhasUnicas.isNotEmpty) {
          fail(relatorio.formatarResumoConsolidado());
        }
      },
      skip: kDuracaoCampanhaCaosSegundos <= 0,
    );
  });
}
