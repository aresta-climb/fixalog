// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/gerenciador_notificacao_upload_laudo.dart';
import 'package:fixalog/core/services/gravador_breadcrumbs.dart';
import 'package:fixalog/features/home/views/home_screen.dart';
import 'package:fixalog/features/home/providers/history_provider.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:fixalog/core/models/local/identity_record.dart';
import '../../../fakes/plugin_notificacoes_locais_fake.dart';

// Helper que envolve o widget numa árvore mínima com providers configurados.
Widget _buildTestApp({IdentityRecord? identity}) {
  return ProviderScope(
    overrides: [
      currentIdentityProvider.overrideWith(
        (ref) async => identity ?? IdentityRecord(),
      ),
      historyProvider.overrideWith(
        (ref) => Stream.value([]),
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  group('HomeScreen Shell Tests', () {
    testWidgets('Exibe o bottom navigation bar com os três itens', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Novo Protocolo'), findsOneWidget);
      expect(find.text('Histórico'), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
    });

    testWidgets('Navegar para aba Configurações exibe o conteúdo correto', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsWidgets);
    });

    testWidgets('Inicia na aba "Novo Protocolo" por padrão', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // A seção de protocolos está visível na aba inicial
      expect(find.text('NOVO REGISTRO DE MANUTENÇÃO'), findsOneWidget);
      // A seção de histórico NÃO está na árvore enquanto a aba 0 está ativa
      expect(find.text('HISTÓRICO RECENTE'), findsNothing);
    });

    testWidgets('Trocar para aba Histórico exibe o conteúdo correto', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Toca no item "Histórico" no bottom bar
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();

      // Título específico da aba de histórico
      expect(find.text('Histórico'), findsWidgets);
      expect(find.text('LOGS TOTAIS'), findsOneWidget);
    });

    testWidgets('Voltar para aba Novo Protocolo após navegar', (tester) async {
      GravadorBreadcrumbs.resetarParaTestes();
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Vai para Histórico
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();

      // Volta para Novo Protocolo
      await tester.tap(find.text('Novo Protocolo'));
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.text('NOVO REGISTRO DE MANUTENÇÃO'), findsOneWidget);
      final breadcrumbs = GravadorBreadcrumbs.instancia.obterBreadcrumbs();
      expect(
        breadcrumbs.map((b) => b['parametros']),
        containsAll([
          {'aba': 'historico'},
          {'aba': 'novo_protocolo'},
        ]),
      );
    });

    testWidgets(
      'Aba Configurações exibe dropdown de seleção de idioma (sem botões soltos), persiste no SQLite e atualiza os rótulos da UI sem overflow',
      (tester) async {
        late BancoDadosLocal banco;
        await tester.runAsync(() async {
          banco = await BancoDadosLocal.abrirEmMemoria();
        });
        addTearDown(() async {
          await tester.runAsync(() async => await banco.fechar());
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bancoDadosLocalProvider.overrideWithValue(banco),
              currentIdentityProvider.overrideWith(
                (ref) async => IdentityRecord(),
              ),
              historyProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: ResolvedorIdioma.localesSuportados,
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Navega para a aba de Configurações (índice 2)
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('seletor_idioma_config')), findsOneWidget);
        expect(find.byType(ChoiceChip), findsNothing);

        final dropdown = find.byKey(const Key('dropdown_idioma_config'));
        expect(dropdown, findsOneWidget);

        // Abre o menu dropdown e seleciona Alemão ('de')
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('opcao_idioma_de')).last);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(banco.obterConfiguracaoSync(1)?.idiomaPreferido, equals('de'));
        expect(find.text('App-Sprache'), findsOneWidget);
        expect(find.text('NEU'), findsOneWidget);
        expect(find.text('VERLAUF'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('botao_gerenciar_identidade_config')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('botao_login_google')), findsOneWidget);
      },
    );

    testWidgets(
      'Ao tocar na notificacao de conclusao de upload, reabre automaticamente a VisualizadorRelatorioScreen do laudo',
      (tester) async {
        late BancoDadosLocal banco;
        await tester.runAsync(() async {
          banco = await BancoDadosLocal.abrirEmMemoria();
          await banco.salvarSubmissao(
            SubmissionRecord()
              ..idSessao = 'sessao_notif_1'
              ..idProtocolo = 'material_registration'
              ..nomeProtocolo = 'Cadastro de Material'
              ..tituloExibicao = 'Barras Roscadas Inox 304'
              ..tipoRegistro = SubmissionTipoRegistro.material
              ..status = SubmissionStatus.gerado
              ..epubPath = '/inexistente.epub',
          );
          await banco.salvarSubmissao(
            SubmissionRecord()
              ..idSessao = 'sessao_notif_2'
              ..idProtocolo = 'manutencao_ferragens'
              ..nomeProtocolo = 'Manutenção Sem Título Exibição'
              ..tituloExibicao = ''
              ..tipoRegistro = SubmissionTipoRegistro.manutencao
              ..status = SubmissionStatus.gerado
              ..epubPath = '',
          );
        });

        final pluginFake = PluginNotificacoesLocaisFake();
        GerenciadorNotificacaoUploadLaudo.instancia.reiniciarParaTestes(
          novoPlugin: pluginFake,
        );
        addTearDown(() async {
          GerenciadorNotificacaoUploadLaudo.instancia.reiniciarParaTestes(
            novoPlugin: PluginNotificacoesLocaisFake(),
          );
          await tester.runAsync(() async => await banco.fechar());
        });

        // 1. Toque pendente registrado ANTES da montagem da HomeScreen
        await GerenciadorNotificacaoUploadLaudo.instancia.inicializar();
        pluginFake.simularToqueNotificacao(payload: 'sessao_notif_1');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bancoDadosLocalProvider.overrideWithValue(banco),
              currentIdentityProvider.overrideWith(
                (ref) async => IdentityRecord(),
              ),
              historyProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verifica que abriu a VisualizadorRelatorioScreen com o título do laudo
        expect(find.text('Barras Roscadas Inox 304'), findsOneWidget);

        // Volta para a HomeScreen e simula um novo toque em tempo real via stream
        Navigator.of(
          tester.element(find.text('Barras Roscadas Inox 304')),
        ).pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        pluginFake.simularToqueNotificacao(payload: 'sessao_notif_2');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Manutenção Sem Título Exibição'), findsOneWidget);
      },
    );
  });
}
