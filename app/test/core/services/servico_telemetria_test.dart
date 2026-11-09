// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:fixalog/core/services/classificador_dispositivo.dart';
import 'package:fixalog/core/services/servico_telemetria.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/registro_logger_fake.dart';

void main() {
  late RegistroLoggerFake loggerFake;

  setUp(() {
    ServicoTelemetria.resetarParaTestes();
    ClassificadorDispositivo.resetarParaTestes();
    loggerFake = RegistroLoggerFake();
  });

  tearDown(() {
    ServicoTelemetria.resetarParaTestes();
    ClassificadorDispositivo.resetarParaTestes();
  });

  group('ServicoTelemetria — Eventos Analíticos e Enriquecimento de Hardware', () {
    test(
      'inicializar desativa coleta em modo desenvolvimento, ativa em produção e trata falhas sem quebrar',
      () async {
        final estadosColeta = <bool>[];
        final servico = ServicoTelemetria(
          logger: loggerFake,
          configurarColetaAnalytics: (habilitado) async {
            estadosColeta.add(habilitado);
          },
        );

        await servico.inicializar(emModoDesenvolvimento: true);
        await servico.inicializar(emModoDesenvolvimento: false);

        expect(estadosColeta, equals([false, true]));
        expect(loggerFake.infosRegistrados, hasLength(2));

        final servicoComFalha = ServicoTelemetria(
          logger: loggerFake,
          configurarColetaAnalytics: (_) async {
            throw StateError('Falha ao configurar Analytics');
          },
        );
        await expectLater(servicoComFalha.inicializar(), completes);
        expect(loggerFake.errosRegistrados, hasLength(1));
      },
    );

    test(
      'dispara eventos de domínio do Fixalog e enriquece métricas de duração com tier_dispositivo e ram_gb',
      () async {
        ClassificadorDispositivo.instancia.classificar(ramTotalMb: 4096);
        final eventosDisparados = <Map<String, Object?>>[];

        final servico = ServicoTelemetria(
          logger: loggerFake,
          enviarEventoAnalytics: (nome, parametros) async {
            eventosDisparados.add({'nome': nome, 'parametros': parametros});
          },
        );

        await servico.registrarInicioProtocolo(
          'bolt_maintenance',
          idioma: 'pt',
        );
        await servico.registrarGeracaoLaudoEpub(
          idProtocolo: 'bolt_maintenance',
          duracaoMs: 840,
          assinado: true,
        );
        await servico.registrarSincronizacaoNuvem(enviados: 2, falhas: 0);
        await servico.registrarAberturaLinkExterno(
          'https://arestaclimb.com',
          origem: 'configuracoes',
        );

        expect(eventosDisparados, hasLength(4));
        expect(eventosDisparados[0]['nome'], equals('iniciar_protocolo'));
        expect(
          eventosDisparados[0]['parametros'],
          equals({'id_protocolo': 'bolt_maintenance', 'idioma': 'pt'}),
        );

        expect(eventosDisparados[1]['nome'], equals('gerar_laudo_epub'));
        expect(
          eventosDisparados[1]['parametros'],
          equals({
            'tier_dispositivo': 'medio',
            'ram_gb': '4',
            'id_protocolo': 'bolt_maintenance',
            'duracao_ms': 840,
            'assinado': 'true',
          }),
        );

        expect(eventosDisparados[2]['nome'], equals('sincronizar_nuvem'));
        expect(eventosDisparados[3]['nome'], equals('link_externo'));
      },
    );

    test(
      'registrarEvento captura exceções de envio sem derrubar o app e exercita delegates padrão',
      () async {
        final servicoComErro = ServicoTelemetria(
          logger: loggerFake,
          enviarEventoAnalytics: (_, _) async {
            throw StateError('Analytics offline');
          },
        );

        await expectLater(
          servicoComErro.registrarEvento('teste_erro'),
          completes,
        );
        expect(loggerFake.errosRegistrados, hasLength(1));

        // Exercita instância padrão sem Firebase inicializado
        await expectLater(ServicoTelemetria.instancia.inicializar(), completes);
        await expectLater(
          ServicoTelemetria.instancia.registrarEvento('evento_padrao'),
          completes,
        );
      },
    );
  });
}
