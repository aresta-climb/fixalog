// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:fixalog/core/services/gerenciador_notificacao_upload_laudo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/plugin_notificacoes_locais_fake.dart';

void main() {
  group('GerenciadorNotificacaoUploadLaudo', () {
    test('instancia singleton padrao e permite reinicializacao para testes', () {
      expect(GerenciadorNotificacaoUploadLaudo.instancia, isNotNull);
      final plugin = PluginNotificacoesLocaisFake();
      final gerenciador = GerenciadorNotificacaoUploadLaudo.paraTestes(
        plugin: plugin,
      );
      gerenciador.reiniciarParaTestes(novoPlugin: plugin);
      expect(gerenciador.consumirIdSessaoTocadoPendente(), isNull);
    });

    test('exibe notificacao sticky em primeiro plano durante progresso e transiciona para notificacao de conclusao clicavel', () async {
      final plugin = PluginNotificacoesLocaisFake();
      final gerenciador = GerenciadorNotificacaoUploadLaudo.paraTestes(
        plugin: plugin,
      );

      String? idSelecionadoPorCallback;
      String? idCanceladoPorCallback;
      final idsStream = <String>[];
      final idsCanceladosStream = <String>[];
      final sub = gerenciador.streamLaudosSelecionados.listen(idsStream.add);
      final subCancel = gerenciador.streamCancelamentosSolicitados.listen(
        idsCanceladosStream.add,
      );
      gerenciador.aoSelecionarLaudoConcluido = (id) {
        idSelecionadoPorCallback = id;
      };
      gerenciador.aoSolicitarCancelamento = (id) {
        idCanceladoPorCallback = id;
      };

      await gerenciador.exibirProgresso(
        idSessao: 'sessao_barras_1',
        tituloLaudo: 'Barras Roscadas Inox',
        etapaDescricao: 'Enviando blocos do laudo (6/12)',
        progresso: 0.25,
      );

      expect(plugin.androidFake!.canaisCriados.length, 2);
      expect(plugin.androidFake!.chamadasSolicitarPermissao, 1);
      expect(plugin.iosFake!.chamadasSolicitarPermissao, 1);
      expect(plugin.androidFake!.servicosIniciados.length, 1);

      final notifProgresso = plugin.androidFake!.servicosIniciados.first;
      expect(notifProgresso.titulo, 'Barras Roscadas Inox');
      expect(notifProgresso.corpo, 'Enviando blocos do laudo (6/12) (25%)');
      expect(notifProgresso.detalhesAndroid?.ongoing, isTrue);
      expect(notifProgresso.detalhesAndroid?.autoCancel, isFalse);
      expect(notifProgresso.detalhesAndroid?.progress, 25);
      expect(
        notifProgresso.detalhesAndroid?.actions?.single.id,
        GerenciadorNotificacaoUploadLaudo.idAcaoCancelarUpload,
      );
      expect(
        notifProgresso.detalhesAndroid?.actions?.single.title,
        'Cancelar envio',
      );

      // Simula toque na ação "Cancelar envio" da notificação sticky
      plugin.simularToqueNotificacao(
        payload: 'sessao_barras_1',
        actionId: GerenciadorNotificacaoUploadLaudo.idAcaoCancelarUpload,
      );
      await Future<void>.delayed(Duration.zero);
      expect(idCanceladoPorCallback, 'sessao_barras_1');
      expect(idsCanceladosStream, ['sessao_barras_1']);
      expect(idSelecionadoPorCallback, isNull);

      // Transiciona para concluído -> para ForegroundService e exibe notificação autoCancel: true
      await gerenciador.exibirConcluido(
        idSessao: 'sessao_barras_1',
        tituloLaudo: 'Barras Roscadas Inox',
      );

      expect(plugin.androidFake!.chamadasPararServicoPrimeiroPlano, 1);
      expect(plugin.notificacoesExibidas.length, 1);
      final notifConcluida = plugin.notificacoesExibidas.first;
      expect(notifConcluida.titulo, 'Barras Roscadas Inox');
      expect(
        notifConcluida.corpo,
        contains('Toque para abrir o laudo e compartilhar'),
      );
      expect(notifConcluida.payload, 'sessao_barras_1');
      expect(notifConcluida.detalhes?.android?.ongoing, isFalse);
      expect(notifConcluida.detalhes?.android?.autoCancel, isTrue);

      // Simula toque na notificação de conclusão
      plugin.simularToqueNotificacao(payload: 'sessao_barras_1');
      await Future<void>.delayed(Duration.zero);

      expect(idSelecionadoPorCallback, 'sessao_barras_1');
      expect(idsStream, ['sessao_barras_1']);
      expect(
        gerenciador.consumirIdSessaoTocadoPendente(),
        'sessao_barras_1',
      );
      expect(gerenciador.consumirIdSessaoTocadoPendente(), isNull);

      // Toque com payload vazio/nulo é ignorado
      plugin.simularToqueNotificacao(payload: '   ');
      expect(gerenciador.consumirIdSessaoTocadoPendente(), isNull);

      await sub.cancel();
      await subCancel.cancel();
    });

    test('usa fallback show quando startForegroundService falha ou Android nao esta disponivel, e suporta exibirFalha e cancelar', () async {
      final plugin = PluginNotificacoesLocaisFake();
      plugin.androidFake!.erroAoIniciarServicoPrimeiroPlano =
          StateError('ForegroundService indisponível');

      final gerenciador = GerenciadorNotificacaoUploadLaudo.paraTestes(
        plugin: plugin,
      );

      await gerenciador.exibirProgresso(
        idSessao: 'sessao_2',
        tituloLaudo: 'Via Dedo de Deus',
        etapaDescricao: 'Verificando integridade no servidor (2/4)',
        progresso: 0.75,
      );

      expect(plugin.notificacoesExibidas.length, 1);
      expect(
        plugin.notificacoesExibidas.first.corpo,
        'Verificando integridade no servidor (2/4) (75%)',
      );

      await gerenciador.exibirFalha(
        idSessao: 'sessao_2',
        tituloLaudo: 'Via Dedo de Deus',
        motivo: 'Assinatura XML-DSig inválida.',
      );

      expect(plugin.notificacoesExibidas.last.corpo, 'Assinatura XML-DSig inválida.');
      expect(plugin.notificacoesExibidas.last.detalhes?.android?.ongoing, isFalse);

      await gerenciador.cancelar('sessao_2');
      expect(plugin.idsCancelados, isNotEmpty);
    });

    test('tolera falhas de plataforma durante inicializacao, exibicao e cancelamento sem propagar excecoes', () async {
      final plugin = PluginNotificacoesLocaisFake();
      plugin.erroAoInicializar = StateError('falha init');
      plugin.erroAoExibir = StateError('falha show');
      plugin.erroAoCancelar = StateError('falha cancel');

      final gerenciador = GerenciadorNotificacaoUploadLaudo.paraTestes(
        plugin: plugin,
      );

      await gerenciador.inicializar();
      await gerenciador.exibirProgresso(
        idSessao: 'sessao_erro',
        tituloLaudo: 'Laudo',
        etapaDescricao: 'Enviando',
        progresso: 0.5,
      );
      await gerenciador.exibirConcluido(
        idSessao: 'sessao_erro',
        tituloLaudo: 'Laudo',
      );
      await gerenciador.exibirFalha(
        idSessao: 'sessao_erro',
        tituloLaudo: 'Laudo',
        motivo: 'Erro',
      );
      await gerenciador.cancelar('sessao_erro');

      // Também testa quando startForegroundService funciona mas stopForegroundService lança erro
      final plugin2 = PluginNotificacoesLocaisFake();
      plugin2.androidFake!.erroAoPararServicoPrimeiroPlano =
          StateError('falha stop fg');
      final gerenciador2 = GerenciadorNotificacaoUploadLaudo.paraTestes(
        plugin: plugin2,
      );
      await gerenciador2.exibirProgresso(
        idSessao: 'sessao_fg',
        tituloLaudo: 'Laudo FG',
        etapaDescricao: 'Enviando',
        progresso: 0.1,
      );
      await gerenciador2.cancelar('sessao_fg');
    });
  });
}
