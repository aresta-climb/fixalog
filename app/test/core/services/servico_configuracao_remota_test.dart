// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';

import 'package:fixalog/core/services/servico_configuracao_remota.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/registro_logger_fake.dart';

void main() {
  late RegistroLoggerFake loggerFake;

  setUp(() {
    ServicoConfiguracaoRemota.resetarParaTestes();
    loggerFake = RegistroLoggerFake();
  });

  tearDown(() {
    ServicoConfiguracaoRemota.resetarParaTestes();
  });

  group('ServicoConfiguracaoRemota — Fallbacks Offline e Sincronização', () {
    test(
      'retorna valores estáticos padrão imediatamente antes mesmo da sincronização de rede',
      () {
        final config = ServicoConfiguracaoRemota(logger: loggerFake);

        expect(config.versaoRecomendada, equals(0));
        expect(config.versaoMinimaAviso, equals(0));
        expect(config.versaoMinimaBloqueio, equals(0));
        expect(
          config.urlComunidadeWhatsapp,
          equals('https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv'),
        );
        expect(config.urlPortalAresta, equals('https://arestaclimb.com'));
        expect(config.urlWorkerFixalog, equals('https://fixalog.app'));
        expect(
          config.urlFeedbackEdgeFunction,
          equals('https://yzkhiaoqtxvvcyyuwmqg.supabase.co/functions/v1/app-feedback'),
        );
        expect(config.obterBool('flag_inexistente'), isFalse);
        expect(config.obterInt('int_inexistente'), equals(0));
        expect(config.obterString('str_inexistente'), isEmpty);
      },
    );

    test(
      'inicializar atualiza parâmetros remotos, notifica ouvintes e preserva defaults para chaves vazias',
      () async {
        var notificacoes = 0;
        final config = ServicoConfiguracaoRemota(
          logger: loggerFake,
          sincronizarRemoto: (padroes) {
            return ServicoConfiguracaoRemota.sincronizarPadrao(
              padroes,
              definirPadroes: (_) async {},
              buscarEAtivar: () async => true,
              obterTodos: () => {
                'versao_recomendada':
                    ServicoConfiguracaoRemota.criarValorRemotoTexto('12'),
                'versao_minima_aviso':
                    ServicoConfiguracaoRemota.criarValorRemotoTexto('10'),
                'versao_minima_bloqueio':
                    ServicoConfiguracaoRemota.criarValorRemotoTexto('8'),
                'modo_manutencao':
                    ServicoConfiguracaoRemota.criarValorRemotoTexto('true'),
                'url_comunidade_whatsapp':
                    ServicoConfiguracaoRemota.criarValorRemotoTexto(''),
              },
            );
          },
        );
        config.addListener(() => notificacoes++);

        await config.inicializar();

        expect(notificacoes, equals(1));
        expect(config.versaoRecomendada, equals(12));
        expect(config.versaoMinimaAviso, equals(10));
        expect(config.versaoMinimaBloqueio, equals(8));
        expect(config.obterBool('modo_manutencao'), isTrue);
        // String vazia preserva a URL padrão estática
        expect(
          config.urlComunidadeWhatsapp,
          equals('https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv'),
        );
        expect(
          loggerFake.infosRegistrados.single,
          contains('Configuração remota sincronizada com sucesso'),
        );
      },
    );

    test(
      'inicializar rebaixa falha de rede na montanha para logAviso, permite nova tentativa e trata erro inesperado',
      () async {
        var falharRede = true;
        final config = ServicoConfiguracaoRemota(
          logger: loggerFake,
          sincronizarRemoto: (padroes) async {
            if (falharRede) {
              throw const SocketException('Sem sinal 4G na falésia');
            }
            return {
              ...padroes,
              'versao_recomendada': 15,
            };
          },
        );

        await config.inicializar();
        expect(config.versaoRecomendada, equals(0));
        expect(loggerFake.errosRegistrados, isEmpty);
        expect(loggerFake.avisosRegistrados, hasLength(1));

        // Como falhou por rede, uma nova chamada a inicializar() deve tentar novamente
        falharRede = false;
        await config.inicializar();
        expect(config.versaoRecomendada, equals(15));

        // Erro inesperado (não-rede) registra logError
        final configComErro = ServicoConfiguracaoRemota(
          logger: loggerFake,
          sincronizarRemoto: (_) async => throw StateError('Corrupção interna'),
        );
        await configComErro.inicializar();
        expect(loggerFake.errosRegistrados, hasLength(1));

        // Exercita instância padrão sem Firebase inicializado
        await expectLater(
          ServicoConfiguracaoRemota.instancia.inicializar(),
          completes,
        );
      },
    );
  });
}
