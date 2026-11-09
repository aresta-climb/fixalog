// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'dart:math' as math;

import 'package:fixalog/core/services/registro_logger.dart';
import 'package:fixalog/main.dart' show kSentryDsn;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'encolhedor_caminho_crash.dart';
import 'receita_crash_robo.dart';

/// Resultado de uma única sessão exploratória executada pelo [MotorRoboCaotico].
class ResultadoSessaoRobo {
  /// Semente pseudo-aleatória utilizada na sessão.
  final int seed;

  /// Perfil de dataset utilizado na sessão.
  final TipoDatasetCaos dataset;

  /// Sequência completa de passos executados até o fim da sessão ou até a falha.
  final List<PassoRobo> passosExecutados;

  /// Indica se algum erro não tratado, `FlutterError` ou `RegistroLogger.logError` ocorreu durante a sessão.
  final bool teveFalha;

  /// Oráculo que detectou a falha (`excecao_nao_tratada`, `flutter_error` ou `erro_registrado_log`).
  final String? oraculo;

  /// Exceção capturada caso [teveFalha] seja `true`.
  final Object? excecao;

  /// Pilha de execução associada à [excecao].
  final StackTrace? stackTrace;

  /// Receita mínima gerada após o shrinking caso uma falha tenha ocorrido.
  final ReceitaCrashRobo? receitaGerada;

  /// Constrói o resultado imutável de uma sessão do robô caótico.
  const ResultadoSessaoRobo({
    required this.seed,
    required this.dataset,
    required this.passosExecutados,
    required this.teveFalha,
    this.oraculo,
    this.excecao,
    this.stackTrace,
    this.receitaGerada,
  });
}

/// Relatório consolidado ao término de uma campanha de testes caóticos por tempo.
class RelatorioCampanhaRobo {
  /// Número total de sessões exploratórias completas ou interrompidas por falha.
  final int totalSessoesExecutadas;

  /// Tempo total decorrido na campanha.
  final Duration duracaoTotal;

  /// Lista de receitas encolhidas para cada assinatura única de falha encontrada.
  final List<ReceitaCrashRobo> falhasUnicas;

  /// Contagem de ocorrências de cada assinatura de falha durante a campanha.
  final Map<String, int> contagemPorAssinatura;

  /// Constrói o relatório consolidado da campanha.
  const RelatorioCampanhaRobo({
    required this.totalSessoesExecutadas,
    required this.duracaoTotal,
    required this.falhasUnicas,
    required this.contagemPorAssinatura,
  });

  /// Formata um resumo legível de todas as falhas únicas encontradas na campanha.
  String formatarResumoConsolidado() {
    final buffer = StringBuffer()
      ..writeln(
        '=== RELATÓRIO DO ROBÔ CAÓTICO FIXALOG ($totalSessoesExecutadas sessões em ${duracaoTotal.inSeconds}s) ===',
      )
      ..writeln('Falhas únicas encontradas: ${falhasUnicas.length}');
    for (final receita in falhasUnicas) {
      final ocorrencias =
          contagemPorAssinatura[receita.assinaturaFalha] ?? 1;
      buffer
        ..writeln(
          '- [${receita.oraculo}] ${receita.assinaturaFalha} ($ocorrencias ocorrências) | seed=${receita.seed} | dataset=${receita.dataset.name}',
        )
        ..writeln(
          '  Passos reduzidos: ${receita.passosOriginais.length} -> ${receita.passosMinimos.length}',
        )
        ..writeln('  Erro: ${receita.resumoErro}');
    }
    return buffer.toString();
  }
}

/// Motor de testes exploratórios caóticos (*Monkey / Fuzzing Testing*) para o aplicativo completo (`FixalogApp`).
///
/// Opera sobre o [WidgetTester], descobrindo dinamicamente widgets interativos visíveis
/// em todas as telas (`HomeScreen`, `NewProtocolScreen`, `WizardScreen` nos 5 protocolos YAML,
/// `HistoryScreen`, `TelaConfiguracoes` nos 7 idiomas, `IdentitySetupScreen`, `TelaTermosDeUso`
/// e `BetterFeedback`), interceptando tanto crashes e `FlutterError` quanto erros tratados
/// registrados em [RegistroLogger.logError] / [RegistroLogger.logCrash].
class MotorRoboCaotico {
  /// Instância do [WidgetTester] onde a árvore de widgets é montada e exercitada.
  final WidgetTester tester;

  /// Função responsável por limpar o estado anterior e montar a árvore do aplicativo para o [TipoDatasetCaos] solicitado.
  final Future<void> Function(TipoDatasetCaos dataset) montarCenario;

  /// Callback opcional para simular o disparo de um evento assíncrono de sincronização em segundo plano.
  final Future<void> Function()? aoDispararEventoSync;

  /// Callback opcional para simular a alternância de conectividade (online <-> offline).
  final Future<void> Function()? aoAlternarConectividade;

  /// Diretório onde as receitas `.json` encolhidas serão salvas automaticamente quando uma falha inédita for encontrada.
  final Directory? diretorioSaidaReceitas;

  /// Define se o Sentry deve permanecer liberado e receber as falhas e receitas geradas.
  final bool reportarAoSentry;

  /// Limite máximo de execuções de replay durante o shrinking (`ddmin`) de cada falha única.
  final int maxTentativasShrinking;

  static final List<String> _entradasTextoFuzz = <String>[
    '',
    ' ',
    'Via Paredão Sul P2',
    'Chapeleta Bonier Inox 316L',
    '12',
    '-999999',
    '0',
    '🧗‍♂️🪨⚡🔥❄️💧',
    'Texto com **negrito**, *itálico* e [link](https://fixalog.app)',
    'التقرير الفني للصيانة — فحص المرساة ١٢',
    'アンカー保守点検レポート — ボルト交換 #42',
    'SELECT * FROM submissoes; DROP TABLE identidade; --',
    'A' * 256,
  ];

  static const List<Type> _tiposInterativosTap = <Type>[
    FilledButton,
    ElevatedButton,
    OutlinedButton,
    TextButton,
    IconButton,
    FloatingActionButton,
    ListTile,
    RadioListTile,
    CheckboxListTile,
    SwitchListTile,
    PopupMenuButton,
    DropdownButton,
    DropdownMenuItem,
    FilterChip,
    ChoiceChip,
    ActionChip,
    Switch,
    Checkbox,
    InkWell,
  ];

  /// Cria uma instância do [MotorRoboCaotico].
  const MotorRoboCaotico({
    required this.tester,
    required this.montarCenario,
    this.aoDispararEventoSync,
    this.aoAlternarConectividade,
    this.diretorioSaidaReceitas,
    this.reportarAoSentry = false,
    this.maxTentativasShrinking = 25,
  });

  /// Executa uma única sessão exploratória determinística com a [seed] e [dataset] informados.
  Future<ResultadoSessaoRobo> executarSessao({
    required int seed,
    required TipoDatasetCaos dataset,
    int maxPassos = 25,
    bool encolherAoFalhar = true,
  }) async {
    final random = math.Random(seed);
    final historicoPassos = <PassoRobo>[];

    final falhaMontagem = await _executarCapturandoErro(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await montarCenario(dataset);
    });
    if (falhaMontagem != null) {
      ReceitaCrashRobo? receita;
      if (encolherAoFalhar) {
        receita = await processarFalhaComShrinking(
          seed: seed,
          dataset: dataset,
          oraculo: falhaMontagem.oraculo,
          passosAteFalha: historicoPassos,
          excecao: falhaMontagem.excecao,
          stackTrace: falhaMontagem.stackTrace,
        );
      }
      return ResultadoSessaoRobo(
        seed: seed,
        dataset: dataset,
        passosExecutados: List<PassoRobo>.unmodifiable(historicoPassos),
        teveFalha: true,
        oraculo: falhaMontagem.oraculo,
        excecao: falhaMontagem.excecao,
        stackTrace: falhaMontagem.stackTrace,
        receitaGerada: receita,
      );
    }

    for (var indicePasso = 0; indicePasso < maxPassos; indicePasso++) {
      final passo = _sortearProximoPasso(random);
      historicoPassos.add(passo);

      final falhaPasso = await _executarPasso(passo);
      if (falhaPasso != null) {
        ReceitaCrashRobo? receita;
        if (encolherAoFalhar) {
          receita = await processarFalhaComShrinking(
            seed: seed,
            dataset: dataset,
            oraculo: falhaPasso.oraculo,
            passosAteFalha: historicoPassos,
            excecao: falhaPasso.excecao,
            stackTrace: falhaPasso.stackTrace,
          );
        }
        return ResultadoSessaoRobo(
          seed: seed,
          dataset: dataset,
          passosExecutados: List<PassoRobo>.unmodifiable(historicoPassos),
          teveFalha: true,
          oraculo: falhaPasso.oraculo,
          excecao: falhaPasso.excecao,
          stackTrace: falhaPasso.stackTrace,
          receitaGerada: receita,
        );
      }
    }

    return ResultadoSessaoRobo(
      seed: seed,
      dataset: dataset,
      passosExecutados: List<PassoRobo>.unmodifiable(historicoPassos),
      teveFalha: false,
    );
  }

  /// Executa uma campanha exploratória contínua até atingir [duracaoMaxima].
  ///
  /// Percorre todo o orçamento de tempo alternando seeds e datasets (`normal` e `toxico`),
  /// deduplica falhas repetidas pela assinatura para evitar shrinking redundante e retorna
  /// um [RelatorioCampanhaRobo] consolidado ao final.
  Future<RelatorioCampanhaRobo> executarCampanhaPorTempo({
    required Duration duracaoMaxima,
    int maxPassosPorSessao = 25,
    int seedInicial = 1,
  }) async {
    final cronometro = Stopwatch()..start();
    final falhasUnicas = <ReceitaCrashRobo>[];
    final contagemPorAssinatura = <String, int>{};
    var sessoesExecutadas = 0;

    while (cronometro.elapsed < duracaoMaxima || sessoesExecutadas < 2) {
      if (reportarAoSentry) {
        await _garantirSentryInicializadoParaCampanha();
      }
      final seedAtual = seedInicial + sessoesExecutadas;
      final datasetAtual = sessoesExecutadas.isEven
          ? TipoDatasetCaos.normal
          : TipoDatasetCaos.toxico;

      final resultado = await executarSessao(
        seed: seedAtual,
        dataset: datasetAtual,
        maxPassos: maxPassosPorSessao,
        encolherAoFalhar: false,
      );
      sessoesExecutadas++;

      if (resultado.teveFalha && resultado.excecao != null) {
        final assinatura = ReceitaCrashRobo.extrairAssinaturaFalha(
          resultado.excecao!,
          resultado.stackTrace,
        );
        final contagemAnterior = contagemPorAssinatura[assinatura] ?? 0;
        contagemPorAssinatura[assinatura] = contagemAnterior + 1;

        if (contagemAnterior == 0) {
          // Pausa o cronômetro durante o shrinking para não descontar do orçamento exploratório
          cronometro.stop();
          final receita = await processarFalhaComShrinking(
            seed: seedAtual,
            dataset: datasetAtual,
            oraculo: resultado.oraculo ?? 'excecao_nao_tratada',
            passosAteFalha: resultado.passosExecutados,
            excecao: resultado.excecao!,
            stackTrace: resultado.stackTrace,
          );
          falhasUnicas.add(receita);
          cronometro.start();
        }
      }

      if (duracaoMaxima == Duration.zero && sessoesExecutadas >= 1) {
        break;
      }
    }

    cronometro.stop();
    return RelatorioCampanhaRobo(
      totalSessoesExecutadas: sessoesExecutadas,
      duracaoTotal: cronometro.elapsed,
      falhasUnicas: List<ReceitaCrashRobo>.unmodifiable(falhasUnicas),
      contagemPorAssinatura:
          Map<String, int>.unmodifiable(contagemPorAssinatura),
    );
  }

  /// Reproduz deterministicamente uma sequência de [passos] sobre o [dataset] informado.
  ///
  /// Retorna a assinatura da falha (`TipoExcecao|FramePrincipal`) caso ocorra um crash ou erro,
  /// ou `null` caso todos os passos completem sem erros.
  Future<String?> reproduzirCaminho({
    required TipoDatasetCaos dataset,
    required List<PassoRobo> passos,
  }) async {
    final falhaMontagem = await _executarCapturandoErro(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await montarCenario(dataset);
    });
    if (falhaMontagem != null) {
      return ReceitaCrashRobo.extrairAssinaturaFalha(
        falhaMontagem.excecao,
        falhaMontagem.stackTrace,
      );
    }

    for (final passo in passos) {
      final falhaPasso = await _executarPasso(passo);
      if (falhaPasso != null) {
        return ReceitaCrashRobo.extrairAssinaturaFalha(
          falhaPasso.excecao,
          falhaPasso.stackTrace,
        );
      }
    }
    return null;
  }

  /// Encolhe [passosAteFalha] via busca binária, persiste a receita `.json` em disco
  /// (se [diretorioSaidaReceitas] estiver configurado) e reporta ao Sentry via [RegistroLogger.logCrash].
  Future<ReceitaCrashRobo> processarFalhaComShrinking({
    required int seed,
    required TipoDatasetCaos dataset,
    String oraculo = 'excecao_nao_tratada',
    required List<PassoRobo> passosAteFalha,
    required Object excecao,
    StackTrace? stackTrace,
  }) async {
    final assinaturaAlvo = ReceitaCrashRobo.extrairAssinaturaFalha(
      excecao,
      stackTrace,
    );
    final prefixoTipoExcecao = '${excecao.runtimeType}|';

    final passosMinimos = await EncolhedorCaminhoCrash.encolher(
      passosOriginais: passosAteFalha,
      assinaturaAlvo: assinaturaAlvo,
      maxTentativas: maxTentativasShrinking,
      testarSequencia: (candidato) async {
        final assinaturaObtida = await reproduzirCaminho(
          dataset: dataset,
          passos: candidato,
        );
        if (assinaturaObtida == null) return null;
        if (assinaturaObtida == assinaturaAlvo ||
            assinaturaObtida.startsWith(prefixoTipoExcecao)) {
          return assinaturaAlvo;
        }
        return assinaturaObtida;
      },
    );

    final receita = ReceitaCrashRobo.criar(
      seed: seed,
      dataset: dataset,
      oraculo: oraculo,
      excecao: excecao,
      stackTrace: stackTrace,
      passosMinimos: passosMinimos,
      passosOriginais: passosAteFalha,
    );

    if (diretorioSaidaReceitas != null) {
      final nomeArquivo = 'crash_${dataset.name}_seed_$seed.json';
      final arquivo = File(
        '${diretorioSaidaReceitas!.path}${Platform.pathSeparator}$nomeArquivo',
      );
      receita.salvarEmArquivo(arquivo);
    }

    if (reportarAoSentry) {
      await _enviarCrashParaSentry(
        receita: receita,
        excecao: excecao,
        stackTrace: stackTrace ?? StackTrace.current,
      );
    }

    return receita;
  }

  /// Garante que o Sentry permaneça inicializado e liberado em tempo real durante toda a campanha.
  Future<void> _garantirSentryInicializadoParaCampanha() async {
    final logger = RegistroLogger.instancia;
    if (logger.runtimeType != RegistroLogger) {
      return;
    }
    await tester.runAsync(() async {
      await HttpOverrides.runWithHttpOverrides(() async {
        if (!Sentry.isEnabled) {
          await Sentry.init((options) {
            options.dsn = kSentryDsn;
            options.environment = 'robo_caotico';
          });
        }
      }, _HttpOverridesRedeRealCaos());
    });
  }

  /// Envia a falha capturada e a receita mínima ao `RegistroLogger.instancia.logCrash`.
  Future<void> _enviarCrashParaSentry({
    required ReceitaCrashRobo receita,
    required Object excecao,
    required StackTrace stackTrace,
  }) async {
    final logger = RegistroLogger.instancia;
    final contextos = <String, Map<String, Object?>>{
      'receita_robo_caotico': receita.toJson(),
    };
    final mensagem =
        'Robô Caótico detectou falha reproduzível (${receita.assinaturaFalha})';

    if (logger.runtimeType != RegistroLogger) {
      logger.logCrash(
        mensagem,
        error: excecao,
        stackTrace: stackTrace,
        contextosExtras: contextos,
      );
      return;
    }

    await tester.runAsync(() async {
      await HttpOverrides.runWithHttpOverrides(() async {
        if (!Sentry.isEnabled) {
          await Sentry.init((options) {
            options.dsn = kSentryDsn;
            options.environment = 'robo_caotico';
          });
        }
        logger.logCrash(
          mensagem,
          error: excecao,
          stackTrace: stackTrace,
          contextosExtras: contextos,
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }, _HttpOverridesRedeRealCaos());
    });
  }

  /// Inspeciona os widgets visíveis e sorteia o próximo [PassoRobo] de forma determinística.
  PassoRobo _sortearProximoPasso(math.Random random) {
    final candidatos = <PassoRobo>[];
    final usarPumpAndSettle = random.nextDouble() >= 0.45;
    final pumpMs = usarPumpAndSettle ? null : (50 + random.nextInt(301));

    // 1. Descobre widgets clicáveis visíveis
    final seletoresTap = _descobrirSeletoresInterativosTap();
    for (final seletor in seletoresTap) {
      candidatos.add(
        PassoRobo(
          acao: TipoAcaoRobo.tap,
          alvo: seletor,
          pumpAndSettle: usarPumpAndSettle,
          pumpMs: pumpMs,
        ),
      );
    }

    // 2. Descobre campos de texto visíveis
    final seletoresTexto = _descobrirSeletoresPorTipo(TextField);
    for (final seletor in seletoresTexto) {
      final textoSorteado =
          _entradasTextoFuzz[random.nextInt(_entradasTextoFuzz.length)];
      candidatos.add(
        PassoRobo(
          acao: TipoAcaoRobo.digitarTexto,
          alvo: seletor,
          textoDigitado: textoSorteado,
          pumpAndSettle: usarPumpAndSettle,
          pumpMs: pumpMs,
        ),
      );
    }

    // 3. Descobre listas/scrollables visíveis
    final seletoresScroll = _descobrirSeletoresPorTipo(Scrollable);
    for (final seletor in seletoresScroll) {
      final dy =
          (random.nextBool() ? -1.0 : 1.0) * (120 + random.nextInt(300));
      candidatos.add(
        PassoRobo(
          acao: TipoAcaoRobo.scroll,
          alvo: seletor,
          deslocamentoDx: 0.0,
          deslocamentoDy: dy,
          pumpAndSettle: usarPumpAndSettle,
          pumpMs: pumpMs,
        ),
      );
    }

    // 4. Ações globais de navegação e eventos assíncronos
    candidatos.add(
      PassoRobo(
        acao: TipoAcaoRobo.voltarSistema,
        pumpAndSettle: usarPumpAndSettle,
        pumpMs: pumpMs,
      ),
    );
    candidatos.add(
      PassoRobo(
        acao: TipoAcaoRobo.voltarAppNav,
        pumpAndSettle: usarPumpAndSettle,
        pumpMs: pumpMs,
      ),
    );

    if (aoDispararEventoSync != null) {
      candidatos.add(
        PassoRobo(
          acao: TipoAcaoRobo.dispararEventoSync,
          pumpAndSettle: usarPumpAndSettle,
          pumpMs: pumpMs,
        ),
      );
    }

    if (aoAlternarConectividade != null) {
      candidatos.add(
        PassoRobo(
          acao: TipoAcaoRobo.alternarConectividade,
          pumpAndSettle: usarPumpAndSettle,
          pumpMs: pumpMs,
        ),
      );
    }

    return candidatos[random.nextInt(candidatos.length)];
  }

  /// Descobre seletores semânticos para widgets clicáveis atualmente visíveis.
  List<SeletorAlvoRobo> _descobrirSeletoresInterativosTap() {
    final resultado = <SeletorAlvoRobo>[];
    for (final tipo in _tiposInterativosTap) {
      resultado.addAll(_descobrirSeletoresPorTipo(tipo));
    }
    return resultado;
  }

  /// Descobre seletores semânticos resilientes para todos os elementos visíveis de [tipo].
  List<SeletorAlvoRobo> _descobrirSeletoresPorTipo(Type tipo) {
    final finder = find.byType(tipo, skipOffstage: true);
    final elementos = finder.evaluate().toList();
    final seletores = <SeletorAlvoRobo>[];

    final contagemPorKey = <String, int>{};
    final contagemPorTexto = <String, int>{};
    final contagemPorIcone = <int, int>{};

    for (var i = 0; i < elementos.length; i++) {
      final el = elementos[i];
      final nomeTipo = el.widget.runtimeType.toString();
      final key = el.widget.key;

      if (key is ValueKey<String>) {
        final ocorrencia = contagemPorKey[key.value] ?? 0;
        contagemPorKey[key.value] = ocorrencia + 1;
        seletores.add(
          SeletorAlvoRobo.porKey(key.value, ocorrencia: ocorrencia),
        );
        continue;
      }

      final texto = _extrairPrimeiroTextoDescendente(el);
      if (texto != null) {
        final ocorrencia = contagemPorTexto[texto] ?? 0;
        contagemPorTexto[texto] = ocorrencia + 1;
        seletores.add(
          SeletorAlvoRobo.porTipoETexto(
            tipoWidget: nomeTipo,
            texto: texto,
            ocorrencia: ocorrencia,
          ),
        );
        continue;
      }

      final iconeCodePoint = _extrairPrimeiroIconeDescendente(el);
      if (iconeCodePoint != null) {
        final ocorrencia = contagemPorIcone[iconeCodePoint] ?? 0;
        contagemPorIcone[iconeCodePoint] = ocorrencia + 1;
        seletores.add(
          SeletorAlvoRobo.porTipoEIcone(
            tipoWidget: nomeTipo,
            iconeCodePoint: iconeCodePoint,
            ocorrencia: ocorrencia,
          ),
        );
        continue;
      }

      seletores.add(
        SeletorAlvoRobo.porTipoEIndice(
          tipoWidget: nomeTipo,
          ocorrencia: i,
        ),
      );
    }

    return seletores;
  }

  /// Executa um [PassoRobo] e seu avanço temporal correspondente, capturando qualquer falha.
  Future<_FalhaCapturada?> _executarPasso(PassoRobo passo) async {
    return _executarCapturandoErro(() async {
      switch (passo.acao) {
        case TipoAcaoRobo.tap:
          final finder = _resolverFinder(passo.alvo);
          if (finder != null) {
            await tester.tap(finder, warnIfMissed: false);
          }
        case TipoAcaoRobo.digitarTexto:
          final finder = _resolverFinder(passo.alvo);
          if (finder != null) {
            await tester.enterText(finder, passo.textoDigitado ?? '');
          }
        case TipoAcaoRobo.scroll:
          final finder = _resolverFinder(passo.alvo);
          if (finder != null) {
            await tester.drag(
              finder,
              Offset(
                passo.deslocamentoDx ?? 0.0,
                passo.deslocamentoDy ?? -200.0,
              ),
              warnIfMissed: false,
            );
          }
        case TipoAcaoRobo.voltarSistema:
          await tester.binding.handlePopRoute();
        case TipoAcaoRobo.voltarAppNav:
          final elementos =
              find.byType(Scaffold, skipOffstage: true).evaluate();
          if (elementos.isNotEmpty) {
            Navigator.maybePop(elementos.first);
          }
        case TipoAcaoRobo.dispararEventoSync:
          if (aoDispararEventoSync != null) {
            await aoDispararEventoSync!();
          }
        case TipoAcaoRobo.alternarConectividade:
          if (aoAlternarConectividade != null) {
            await aoAlternarConectividade!();
          }
      }

      await _avancarTempo(passo);
    });
  }

  /// Avança os quadros da interface conforme especificado no [passo] (`pump` parcial ou `pumpAndSettle`).
  Future<void> _avancarTempo(PassoRobo passo) async {
    if (passo.pumpAndSettle) {
      try {
        await tester.pumpAndSettle(
          const Duration(milliseconds: 16),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 2),
        );
      } on FlutterError catch (erro) {
        // Animações contínuas (ex: CircularProgressIndicator) dão timeout no pumpAndSettle;
        // nesses casos avançamos um frame simples sem considerar o timeout como crash.
        if (!erro.message.contains('pumpAndSettle timed out')) {
          rethrow;
        }
        await tester.pump(const Duration(milliseconds: 100));
      }
    } else {
      await tester.pump(Duration(milliseconds: passo.pumpMs ?? 100));
    }
  }

  /// Resolve um [SeletorAlvoRobo] para um [Finder] apontando para uma única ocorrência visível.
  Finder? _resolverFinder(SeletorAlvoRobo? seletor) {
    if (seletor == null) return null;

    Finder finderBase;
    switch (seletor.tipo) {
      case TipoSeletorRobo.porKey:
        finderBase = find.byKey(
          ValueKey<String>(seletor.valorKey!),
          skipOffstage: true,
        );
      case TipoSeletorRobo.porTipoETexto:
        finderBase = find.byElementPredicate(
          (el) =>
              el.widget.runtimeType.toString() == seletor.tipoWidget &&
              _extrairPrimeiroTextoDescendente(el) == seletor.texto,
          skipOffstage: true,
        );
      case TipoSeletorRobo.porTipoEIcone:
        finderBase = find.byElementPredicate(
          (el) =>
              el.widget.runtimeType.toString() == seletor.tipoWidget &&
              _extrairPrimeiroIconeDescendente(el) == seletor.iconeCodePoint,
          skipOffstage: true,
        );
      case TipoSeletorRobo.porTipoEIndice:
        finderBase = find.byElementPredicate(
          (el) => el.widget.runtimeType.toString() == seletor.tipoWidget,
          skipOffstage: true,
        );
    }

    final avaliados = finderBase.evaluate().toList();
    if (avaliados.isEmpty || seletor.ocorrencia >= avaliados.length) {
      return null;
    }
    return finderBase.at(seletor.ocorrencia);
  }

  /// Executa [bloco] interceptando erros do framework Flutter (`FlutterError.onError` / `takeException`),
  /// erros tratados registrados em [RegistroLogger.logError] / [RegistroLogger.logCrash] e exceções diretas.
  Future<_FalhaCapturada?> _executarCapturandoErro(
    Future<void> Function() bloco,
  ) async {
    FlutterErrorDetails? detalhesFlutter;
    _FalhaCapturada? falhaLogger;
    final handlerAnterior = FlutterError.onError;
    final hookLoggerAnterior = RegistroLogger.instancia.aoRegistrarErroOuCrash;

    FlutterError.onError = (FlutterErrorDetails details) {
      detalhesFlutter ??= details;
      handlerAnterior?.call(details);
    };
    RegistroLogger.instancia.aoRegistrarErroOuCrash = (
      erro,
      stackTrace,
      mensagem, {
      required fatal,
    }) {
      falhaLogger ??= _FalhaCapturada(
        oraculo: 'erro_registrado_log',
        excecao: erro,
        stackTrace: stackTrace,
      );
      hookLoggerAnterior?.call(erro, stackTrace, mensagem, fatal: fatal);
    };

    try {
      await bloco();
    } catch (erro, stack) {
      tester.takeException();
      return _FalhaCapturada(
        oraculo: 'excecao_nao_tratada',
        excecao: erro,
        stackTrace: stack,
      );
    } finally {
      FlutterError.onError = handlerAnterior;
      RegistroLogger.instancia.aoRegistrarErroOuCrash = hookLoggerAnterior;
    }

    final excecaoBinding = tester.takeException();
    if (excecaoBinding != null) {
      return _FalhaCapturada(
        oraculo: 'flutter_error',
        excecao: excecaoBinding,
        stackTrace: detalhesFlutter?.stack ?? StackTrace.current,
      );
    }
    if (detalhesFlutter != null) {
      return _FalhaCapturada(
        oraculo: 'flutter_error',
        excecao: detalhesFlutter!.exception,
        stackTrace: detalhesFlutter!.stack ?? StackTrace.current,
      );
    }
    if (falhaLogger != null) {
      return falhaLogger;
    }
    return null;
  }

  static String? _extrairPrimeiroTextoDescendente(Element raiz) {
    String? encontrado;
    void visitar(Element el) {
      if (encontrado != null) return;
      final w = el.widget;
      if (w is Text && w.data != null && w.data!.trim().isNotEmpty) {
        encontrado = w.data!.trim();
        return;
      }
      el.visitChildren(visitar);
    }

    raiz.visitChildren(visitar);
    return encontrado;
  }

  static int? _extrairPrimeiroIconeDescendente(Element raiz) {
    int? encontrado;
    void visitar(Element el) {
      if (encontrado != null) return;
      final w = el.widget;
      if (w is Icon && w.icon != null) {
        encontrado = w.icon!.codePoint;
        return;
      }
      el.visitChildren(visitar);
    }

    raiz.visitChildren(visitar);
    return encontrado;
  }
}

class _FalhaCapturada {
  final String oraculo;
  final Object excecao;
  final StackTrace? stackTrace;

  const _FalhaCapturada({
    required this.oraculo,
    required this.excecao,
    this.stackTrace,
  });
}

class _HttpOverridesRedeRealCaos extends HttpOverrides {}
