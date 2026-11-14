// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/crypto_service.dart';
import 'package:fixalog/core/services/providers.dart';
import 'package:fixalog/features/home/views/home_screen.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:fixalog/features/identity/views/identity_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../core/services/autenticacao_nuvem_service_fake.dart';
import '../../../fakes/crypto_service_fake.dart';

void main() {
  const canalPermissoes = MethodChannel(
    'flutter.baseflow.com/permissions/methods',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalPermissoes, (call) async {
          if (call.method == 'requestPermissions') {
            final permissoes = (call.arguments as List).cast<int>();
            return <int, int>{for (final p in permissoes) p: 1};
          }
          return 1;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalPermissoes, null);
  });

  Widget createWidgetUnderTest({
    BancoDadosLocal? banco,
    Locale? locale,
    CryptoService? cryptoService,
    AutenticacaoNuvemService? autenticacaoService,
    Future<void> Function()? solicitadorPermissoes,
  }) {
    return ProviderScope(
      overrides: [
        if (banco != null) bancoDadosLocalProvider.overrideWithValue(banco),
        if (locale != null) localeSistemaProvider.overrideWithValue(locale),
        if (cryptoService != null)
          cryptoServiceProvider.overrideWithValue(cryptoService),
        if (autenticacaoService != null)
          autenticacaoNuvemServiceProvider.overrideWithValue(
            autenticacaoService,
          ),
      ],
      child: MaterialApp(
        localizationsDelegates: locale != null
            ? AppLocalizations.localizationsDelegates
            : null,
        supportedLocales: ResolvedorIdioma.localesSuportados,
        home: IdentitySetupScreen(
          solicitadorPermissoes: solicitadorPermissoes,
        ),
      ),
    );
  }

  group('IdentitySetupScreen Widget Tests', () {
    testWidgets('Etapa 1 renderiza cabeçalho FIXA LOG e apenas botões clássicos Google e Apple', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('FIXA'), findsOneWidget);
      expect(find.text('LOG'), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF2D3328));
      expect(find.byKey(const Key('botao_voltar_identidade')), findsNothing);
      expect(find.byKey(const Key('botao_login_google')), findsOneWidget);
      expect(find.byKey(const Key('botao_login_apple')), findsOneWidget);
      expect(find.text('Continuar com o Google'), findsOneWidget);
      expect(find.text('Continuar com a Apple'), findsOneWidget);
      expect(find.text('NOME COMPLETO'), findsNothing);
      expect(find.text('GERAR CHAVES E ENTRAR'), findsNothing);
    });

    testWidgets('Etapa 2 exibe erro se nome for limpo, permite trocar de conta e alternar checkbox do Aresta Climb', (
      tester,
    ) async {
      final crypto = CryptoServiceFake();
      final auth = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        nomeRetornadoOidc: 'Renato Aresta',
        clubeRetornadoOidc: 'FEMERJ',
      );
      await tester.pumpWidget(
        createWidgetUnderTest(
          cryptoService: crypto,
          autenticacaoService: auth,
        ),
      );
      await tester.pump();

      // Autentica com Apple na Etapa 1 para avançar à Etapa 2
      await tester.tap(find.byKey(const Key('botao_login_apple')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('badge_sessao_oidc')), findsOneWidget);
      expect(find.byKey(const Key('card_seguranca_hardware')), findsOneWidget);
      expect(find.byKey(const Key('card_permissoes_dispositivo')), findsOneWidget);
      expect(find.text('ACESSO À CÂMERA'), findsOneWidget);
      expect(find.text('LOCALIZAÇÃO (GPS)'), findsOneWidget);
      expect(
        find.textContaining('Ao clicar em gerar chaves, você concorda'),
        findsNothing,
      );

      // Limpa o nome e tenta confirmar
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));
      await tester.enterText(textFields.first, '');
      await tester.pump();

      final botao = find.byKey(const Key('botao_gerar_chaves_entrar'));
      await tester.ensureVisible(botao);
      await tester.tap(botao);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Atenção. O nome não pode estar vazio.'),
        findsOneWidget,
      );

      // Alterna a checkbox do Aresta Climb
      final checkbox = find.byKey(const Key('checkbox_atualizar_nome_aresta'));
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();

      // Troca de conta e retorna para a Etapa 1
      final botaoTrocar = find.byKey(const Key('botao_trocar_conta_oidc'));
      await tester.ensureVisible(botaoTrocar);
      await tester.tap(botaoTrocar);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('botao_login_google')), findsOneWidget);
      expect(find.byKey(const Key('badge_sessao_oidc')), findsNothing);
    });

    testWidgets('autentica com Google, pré-preenche Nome/Clube, solicita permissões e navega para HomeScreen ao concluir', (
      tester,
    ) async {
      late BancoDadosLocal banco;
      await tester.runAsync(() async {
        banco = await BancoDadosLocal.abrirEmMemoria();
      });
      addTearDown(() async {
        await tester.runAsync(() async {
          await banco.fechar();
        });
      });

      var permissoesSolicitadas = false;
      final crypto = CryptoServiceFake();
      final auth = AutenticacaoNuvemServiceFake(
        crypto: crypto,
        nomeRetornadoOidc: 'Renato Ferreira',
        clubeRetornadoOidc: 'FEMERJ',
        emailRetornadoOidc: 'renato@arestaclimb.com',
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          banco: banco,
          cryptoService: crypto,
          autenticacaoService: auth,
          solicitadorPermissoes: () async {
            permissoesSolicitadas = true;
          },
        ),
      );
      await tester.pump();

      final botaoGoogle = find.byKey(const Key('botao_login_google'));
      await tester.ensureVisible(botaoGoogle);
      await tester.tap(botaoGoogle);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('badge_sessao_oidc')), findsOneWidget);
      expect(find.text('Renato Ferreira'), findsOneWidget);
      expect(find.text('FEMERJ'), findsOneWidget);

      final botaoConfirmar = find.byKey(const Key('botao_gerar_chaves_entrar'));
      await tester.ensureVisible(botaoConfirmar);
      await tester.runAsync(() async {
        await tester.tap(botaoConfirmar);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(permissoesSolicitadas, isTrue);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets(
      'renderiza textos localizados em Inglês, Árabe e Japonês sem overflow visual nas Etapas 1 e 2',
      (tester) async {
        final crypto = CryptoServiceFake();
        final auth = AutenticacaoNuvemServiceFake(crypto: crypto);
        await auth.entrarComProvedorOidc(ProvedorOidc.google);

        late WidgetRef refCapturado;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localeSistemaProvider.overrideWithValue(const Locale('en')),
              cryptoServiceProvider.overrideWithValue(crypto),
              autenticacaoNuvemServiceProvider.overrideWithValue(auth),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: ResolvedorIdioma.localesSuportados,
              home: Consumer(
                builder: (context, ref, _) {
                  refCapturado = ref;
                  return const IdentitySetupScreen();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Full Name *'), findsOneWidget);
        expect(find.text('GENERATE KEYS AND CONTINUE'), findsOneWidget);

        await refCapturado
            .read(idiomaAtivoProvider.notifier)
            .selecionarIdioma('ar');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('الاسم الكامل *'), findsOneWidget);

        await refCapturado
            .read(idiomaAtivoProvider.notifier)
            .selecionarIdioma('ja');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('氏名 *'), findsOneWidget);
        expect(find.text('鍵を生成して続行'), findsOneWidget);
      },
    );

    testWidgets(
      'mantém tela aberta ao abrir via Navigator.push após isSuccess=true prévio e executa Navigator.pop atualizando currentIdentityProvider ao salvar edição',
      (tester) async {
        late BancoDadosLocal banco;
        await tester.runAsync(() async {
          banco = await BancoDadosLocal.abrirEmMemoria();
        });
        addTearDown(() async {
          await tester.runAsync(() async {
            await banco.fechar();
          });
        });

        final crypto = CryptoServiceFake();
        final auth = AutenticacaoNuvemServiceFake(
          crypto: crypto,
          nomeRetornadoOidc: 'Renato Inicial',
          clubeRetornadoOidc: 'FEMERJ',
        );
        await auth.entrarComProvedorOidc(ProvedorOidc.google);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bancoDadosLocalProvider.overrideWithValue(banco),
              cryptoServiceProvider.overrideWithValue(crypto),
              autenticacaoNuvemServiceProvider.overrideWithValue(auth),
            ],
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  final identidadeAsync = ref.watch(currentIdentityProvider);
                  return Scaffold(
                    key: const Key('tela_origem_config'),
                    body: Column(
                      children: [
                        Text(
                          'Identidade atual: ${identidadeAsync.valueOrNull?.nome ?? "nenhuma"}',
                        ),
                        ElevatedButton(
                          key: const Key('botao_abrir_edicao_identidade'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => IdentitySetupScreen(
                                  solicitadorPermissoes: () async {},
                                ),
                              ),
                            );
                          },
                          child: const Text('Editar Identidade'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Simula conclusão prévia do onboarding deixando isSuccess=true no provider compartilhado
        final container = ProviderScope.containerOf(
          tester.element(find.byKey(const Key('tela_origem_config'))),
        );
        await tester.runAsync(() async {
          await container
              .read(identityFormViewModelProvider.notifier)
              .submitIdentity(
                'Renato Inicial',
                'FEMERJ',
                exigirAutenticacaoOidc: true,
              );
        });
        container.invalidate(currentIdentityProvider);
        await tester.pumpAndSettle();
        expect(
          container.read(identityFormViewModelProvider).isSuccess,
          isTrue,
        );
        expect(find.text('Identidade atual: Renato Inicial'), findsOneWidget);

        // Abre a IdentitySetupScreen empilhada (como na TelaConfiguracoes)
        await tester.tap(find.byKey(const Key('botao_abrir_edicao_identidade')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Já durante a transição (antes de concluir postFrameCallback assíncrono),
        // os campos devem estar pré-preenchidos sincronamente e o botão voltar visível
        expect(find.byType(IdentitySetupScreen), findsOneWidget);
        expect(find.text('Renato Inicial'), findsOneWidget);
        expect(find.text('FEMERJ'), findsOneWidget);
        expect(find.byKey(const Key('botao_voltar_identidade')), findsOneWidget);

        await tester.pumpAndSettle();

        // Testa cancelar a edição pelo botão voltar no topo da tela
        await tester.tap(find.byKey(const Key('botao_voltar_identidade')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tela_origem_config')), findsOneWidget);
        expect(find.byType(IdentitySetupScreen), findsNothing);

        // Abre novamente a IdentitySetupScreen empilhada para editar e salvar
        await tester.tap(find.byKey(const Key('botao_abrir_edicao_identidade')));
        await tester.pumpAndSettle();

        // A tela DEVE permanecer aberta para edição (sem auto-navegar imediatamente)
        expect(find.byType(IdentitySetupScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
        expect(find.text('Renato Inicial'), findsOneWidget);

        // Edita o nome e confirma
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, 'Renato Editado');
        await tester.pump();

        final botaoConfirmar = find.byKey(const Key('botao_gerar_chaves_entrar'));
        await tester.ensureVisible(botaoConfirmar);
        await tester.runAsync(() async {
          await tester.tap(botaoConfirmar);
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        // Deve ter executado Navigator.pop de volta para a tela_origem_config sem empilhar HomeScreen
        expect(find.byKey(const Key('tela_origem_config')), findsOneWidget);
        expect(find.byType(IdentitySetupScreen), findsNothing);
        expect(find.byType(HomeScreen), findsNothing);
        expect(find.text('Identidade atual: Renato Editado'), findsOneWidget);
      },
    );
  });
}
