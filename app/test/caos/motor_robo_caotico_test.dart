// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';

import 'package:fixalog/core/services/registro_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/registro_logger_fake.dart';
import 'fabrica_dataset_caos.dart';
import 'motor_robo_caotico.dart';
import 'receita_crash_robo.dart';

/// Aplicativo de bancada controlado para validar determinismo, ações, oráculos e shrinking do [MotorRoboCaotico].
class _AppBancadaTesteCaos extends StatefulWidget {
  final bool habilitarArmadilhaCrash;

  const _AppBancadaTesteCaos({this.habilitarArmadilhaCrash = false});

  @override
  State<_AppBancadaTesteCaos> createState() => _AppBancadaTesteCaosState();
}

class _AppBancadaTesteCaosState extends State<_AppBancadaTesteCaos> {
  int _contadorPassosArmadilha = 0;
  String _ultimoTexto = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bancada Caos Fixalog'),
          leading: BackButton(
            onPressed: () {},
          ),
        ),
        body: ListView(
          children: [
            TextField(
              key: const ValueKey<String>('campo_busca_caos'),
              onChanged: (v) => setState(() => _ultimoTexto = v),
            ),
            Text('Texto atual: $_ultimoTexto'),
            FilledButton(
              key: const ValueKey<String>('botao_armar'),
              onPressed: () {
                setState(() {
                  _contadorPassosArmadilha = 1;
                });
              },
              child: const Text('Armar Armadilha'),
            ),
            TextButton(
              onPressed: () {
                if (widget.habilitarArmadilhaCrash &&
                    _contadorPassosArmadilha == 1) {
                  throw StateError('Crash determinístico na armadilha!');
                }
              },
              child: const Text('Disparar Armadilha'),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    RegistroLogger.resetarParaTestes();
    tempDir = await Directory.systemTemp.createTemp('motor_robo_test_');
  });

  tearDown(() async {
    RegistroLogger.resetarParaTestes();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MotorRoboCaotico', () {
    testWidgets(
      'Produz caminhada 100% determinística para a mesma seed e executa replay fiel de passos',
      (tester) async {
        final motor = MotorRoboCaotico(
          tester: tester,
          montarCenario: (_) async {
            await tester.pumpWidget(const _AppBancadaTesteCaos());
            await tester.pump();
          },
        );

        final resultado1 = await motor.executarSessao(
          seed: 42,
          dataset: TipoDatasetCaos.normal,
          maxPassos: 12,
        );
        final resultado2 = await motor.executarSessao(
          seed: 42,
          dataset: TipoDatasetCaos.normal,
          maxPassos: 12,
        );

        expect(resultado1.teveFalha, isFalse);
        expect(resultado1.passosExecutados.length, 12);
        expect(
          resultado1.passosExecutados,
          equals(resultado2.passosExecutados),
        );

        final falhaReplay = await motor.reproduzirCaminho(
          dataset: TipoDatasetCaos.normal,
          passos: resultado1.passosExecutados,
        );
        expect(falhaReplay, isNull);
      },
    );

    testWidgets(
      'Captura crash, encolhe caminho por busca binária (shrinking), salva receita JSON e reporta ao RegistroLogger.logCrash',
      (tester) async {
        final loggerFake = RegistroLoggerFake();
        RegistroLogger.instancia = loggerFake;

        final motor = MotorRoboCaotico(
          tester: tester,
          diretorioSaidaReceitas: tempDir,
          reportarAoSentry: true,
          montarCenario: (_) async {
            await tester.pumpWidget(
              const _AppBancadaTesteCaos(habilitarArmadilhaCrash: true),
            );
            await tester.pump();
          },
        );

        const caminhoComRuido = <PassoRobo>[
          PassoRobo(acao: TipoAcaoRobo.alternarConectividade),
          PassoRobo(acao: TipoAcaoRobo.dispararEventoSync),
          PassoRobo(
            acao: TipoAcaoRobo.digitarTexto,
            alvo: SeletorAlvoRobo.porKey('campo_busca_caos'),
            textoDigitado: 'ruído inicial',
          ),
          PassoRobo(
            acao: TipoAcaoRobo.tap,
            alvo: SeletorAlvoRobo.porKey('botao_armar'),
          ),
          PassoRobo(
            acao: TipoAcaoRobo.tap,
            alvo: SeletorAlvoRobo.porTipoEIcone(
              tipoWidget: 'IconButton',
              iconeCodePoint: 0xe872,
            ),
          ),
          PassoRobo(
            acao: TipoAcaoRobo.tap,
            alvo: SeletorAlvoRobo.porTipoETexto(
              tipoWidget: 'TextButton',
              texto: 'Disparar Armadilha',
            ),
          ),
        ];

        final receita = await motor.processarFalhaComShrinking(
          seed: 777,
          dataset: TipoDatasetCaos.toxico,
          passosAteFalha: caminhoComRuido,
          excecao: StateError('Crash determinístico na armadilha!'),
          stackTrace: StackTrace.current,
        );

        expect(receita.passosOriginais.length, 6);
        expect(receita.passosMinimos.length, 2);
        expect(
          receita.passosMinimos.first.alvo,
          const SeletorAlvoRobo.porKey('botao_armar'),
        );

        final arquivos = tempDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList();
        expect(arquivos, isNotEmpty);

        expect(loggerFake.crashesRegistrados, isNotEmpty);
        expect(
          loggerFake.crashesRegistrados.last.contextosExtras,
          contains('receita_robo_caotico'),
        );
      },
    );

    testWidgets(
      'Detecta erros tratados registrados via RegistroLogger.logError (mesmo dentro de try/catch), encolhe receita e envia ao Sentry/Logger',
      (tester) async {
        final loggerFake = RegistroLoggerFake();
        RegistroLogger.instancia = loggerFake;

        final motor = MotorRoboCaotico(
          tester: tester,
          diretorioSaidaReceitas: tempDir,
          reportarAoSentry: true,
          montarCenario: (_) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: FilledButton(
                    key: const ValueKey<String>('botao_erro_tratado'),
                    onPressed: () {
                      try {
                        throw const FormatException(
                          'Erro silencioso tratado em try/catch',
                        );
                      } catch (e, st) {
                        RegistroLogger.instancia.logError(
                          'Falha tratada no botão',
                          error: e,
                          stackTrace: st,
                        );
                      }
                    },
                    child: const Text('Disparar Erro Tratado'),
                  ),
                ),
              ),
            );
            await tester.pump();
          },
        );

        final resultado = await motor.executarSessao(
          seed: 7,
          dataset: TipoDatasetCaos.normal,
          maxPassos: 15,
        );

        expect(resultado.teveFalha, isTrue);
        expect(resultado.oraculo, equals('erro_registrado_log'));
        expect(resultado.excecao, isA<FormatException>());
        expect(resultado.receitaGerada, isNotNull);
        expect(
          resultado.receitaGerada!.oraculo,
          equals('erro_registrado_log'),
        );
        expect(
          loggerFake.crashesRegistrados.last.contextosExtras,
          contains('receita_robo_caotico'),
        );
      },
    );

    testWidgets(
      'executarCampanhaPorTempo roda até esgotar o orçamento de tempo, deduplica falhas repetidas e consolida relatório final',
      (tester) async {
        final loggerFake = RegistroLoggerFake();
        RegistroLogger.instancia = loggerFake;

        var sessoesIniciadas = 0;
        final motor = MotorRoboCaotico(
          tester: tester,
          diretorioSaidaReceitas: tempDir,
          reportarAoSentry: true,
          montarCenario: (_) async {
            sessoesIniciadas++;
            await tester.pumpWidget(
              const _AppBancadaTesteCaos(habilitarArmadilhaCrash: true),
            );
            await tester.pump();
          },
        );

        final relatorio = await motor.executarCampanhaPorTempo(
          duracaoMaxima: const Duration(milliseconds: 150),
          maxPassosPorSessao: 15,
          seedInicial: 100,
        );

        expect(sessoesIniciadas, greaterThanOrEqualTo(2));
        expect(relatorio.totalSessoesExecutadas, greaterThanOrEqualTo(2));
        if (relatorio.falhasUnicas.isNotEmpty) {
          expect(relatorio.falhasUnicas.length, 1);
          expect(
            relatorio.formatarResumoConsolidado(),
            contains('StateError'),
          );
        }
      },
    );

    testWidgets(
      'Explora o FixalogApp completo montado pelo AmbienteAppCaos sem falhas',
      (tester) async {
        late AmbienteAppCaos ambiente;
        await tester.runAsync(() async {
          ambiente = await AmbienteAppCaos.inicializar();
        });
        addTearDown(() async {
          await tester.runAsync(() async => await ambiente.limpar());
        });

        final motor = ambiente.criarMotor(tester: tester);
        final resultado = await motor.executarSessao(
          seed: 101,
          dataset: TipoDatasetCaos.normal,
          maxPassos: 8,
        );

        expect(resultado.teveFalha, isFalse);
        expect(resultado.passosExecutados.length, equals(8));
      },
    );
  });
}
