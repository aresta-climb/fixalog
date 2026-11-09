// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:fixalog/core/services/classificador_dispositivo.dart';
import 'package:fixalog/core/services/gravador_breadcrumbs.dart';
import 'package:fixalog/core/services/servico_telemetria.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/registro_logger_fake.dart';

void main() {
  late RegistroLoggerFake loggerFake;
  late GravadorBreadcrumbs gravador;

  setUp(() {
    ServicoTelemetria.resetarParaTestes();
    ClassificadorDispositivo.resetarParaTestes();
    GravadorBreadcrumbs.resetarParaTestes();
    loggerFake = RegistroLoggerFake();
    gravador = GravadorBreadcrumbs.instancia;
  });

  tearDown(() {
    ServicoTelemetria.resetarParaTestes();
    ClassificadorDispositivo.resetarParaTestes();
    GravadorBreadcrumbs.resetarParaTestes();
  });

  group('ServicoTelemetria — Eventos Analíticos, Breadcrumbs e Hardware', () {
    test(
      'inicializar desativa coleta em modo desenvolvimento, ativa em produção e trata falhas sem quebrar',
      () async {
        final estadosColeta = <bool>[];
        final servico = ServicoTelemetria(
          logger: loggerFake,
          gravadorBreadcrumbs: gravador,
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
      'dispara todos os eventos tipados do Fixalog, grava no GravadorBreadcrumbs e enriquece duracao_ms',
      () async {
        ClassificadorDispositivo.instancia.classificar(ramTotalMb: 4096);
        final eventosDisparados = <Map<String, Object?>>[];

        final servico = ServicoTelemetria(
          logger: loggerFake,
          gravadorBreadcrumbs: gravador,
          enviarEventoAnalytics: (nome, parametros) async {
            eventosDisparados.add({'nome': nome, 'parametros': parametros});
          },
        );

        await servico.registrarNavegacaoAba('historico');
        await servico.registrarInicioProtocolo(
          'bolt_maintenance',
          idioma: 'pt',
          modo: 'novo',
        );
        await servico.registrarEtapaWizard(
          acao: 'avancar_etapa',
          idProtocolo: 'bolt_maintenance',
          stepId: 'step_1',
          indice: 1,
        );
        await servico.registrarEscolhaRamoWizard(
          idProtocolo: 'bolt_maintenance',
          conteudoId: 'ramo_1',
          opcao: 'sim',
        );
        await servico.registrarAcaoListaWizard(
          acao: 'adicionar_item',
          conteudoId: 'lista_protecoes',
          tipoId: 'chapeleta',
        );
        await servico.registrarAcaoMidiaWizard(
          acao: 'anexar_midia',
          tipoMidia: 'foto',
          campoId: 'foto_protecao',
        );
        await servico.registrarGeracaoLaudoEpub(
          idProtocolo: 'bolt_maintenance',
          duracaoMs: 840,
          assinado: true,
        );
        await servico.registrarGeracaoLaudoEpub(
          idProtocolo: 'bolt_maintenance',
          duracaoMs: 420,
          assinado: false,
        );
        await servico.registrarAcaoHistorico(
          acao: 'abrir_relatorio',
          idProtocolo: 'bolt_maintenance',
          status: 'gerado',
        );
        await servico.registrarAcaoVisualizadorRelatorio(
          acao: 'compartilhar_link_web',
          idSessao: 'sessao_1',
        );
        await servico.registrarAceiteTermosUso('2026-11-01');
        await servico.registrarSalvarIdentidade(possuiClube: true);
        await servico.registrarSalvarIdentidade(possuiClube: false);
        await servico.registrarAcaoConfiguracoes(
          'alterar_idioma',
          detalhe: 'en',
        );
        await servico.registrarAberturaLinkExterno(
          'https://arestaclimb.com',
          origem: 'configuracoes',
        );
        await servico.registrarSincronizacaoNuvem(enviados: 2, falhas: 0);
        await servico.registrarAcaoFeedback(
          'enfileirar_feedback',
          categoria: 'aplicativo',
          idFeedback: 'fb_1',
        );

        expect(eventosDisparados, hasLength(17));
        expect(gravador.total, equals(17));
        expect(loggerFake.infosRegistrados, hasLength(17));

        expect(eventosDisparados[0]['nome'], equals('navegar_aba'));
        expect(eventosDisparados[1]['nome'], equals('iniciar_protocolo'));
        expect(
          eventosDisparados[1]['parametros'],
          equals({
            'id_protocolo': 'bolt_maintenance',
            'idioma': 'pt',
            'modo': 'novo',
          }),
        );

        expect(eventosDisparados[6]['nome'], equals('gerar_laudo_epub'));
        expect(
          eventosDisparados[6]['parametros'],
          equals({
            'tier_dispositivo': 'medio',
            'ram_gb': '4',
            'id_protocolo': 'bolt_maintenance',
            'duracao_ms': 840,
            'assinado': 'true',
          }),
        );
        expect(
          (eventosDisparados[7]['parametros'] as Map)['assinado'],
          equals('false'),
        );
      },
    );

    test(
      'registrarEvento captura exceções de envio sem derrubar o app e ignora silenciosamente [core/no-app] nos delegates padrão',
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

        // Exercita instância padrão sem Firebase inicializado (que lança [core/no-app] internamente sem acionar logError)
        await expectLater(ServicoTelemetria.instancia.inicializar(), completes);
        await expectLater(
          ServicoTelemetria.instancia.registrarEvento('evento_padrao'),
          completes,
        );
        expect(gravador.obterBreadcrumbs().last['evento'], equals('evento_padrao'));
      },
    );
  });
}
