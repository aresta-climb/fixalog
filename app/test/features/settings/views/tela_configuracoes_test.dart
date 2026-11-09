// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:typed_data';

import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/core/models/local/app_config_record.dart';
import 'package:fixalog/core/models/local/identity_record.dart';
import 'package:fixalog/core/services/autenticacao_nuvem_service.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/crypto_service.dart';
import 'package:fixalog/features/feedback/services/servico_fila_feedback.dart';
import 'package:fixalog/features/feedback/views/construtor_feedback_usuario.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:fixalog/features/settings/views/tela_configuracoes.dart';

import '../../../core/services/autenticacao_nuvem_service_fake.dart';
import '../../../fakes/servico_fila_feedback_fake.dart';

void main() {
  group('TelaConfiguracoes — Idioma, Identidade, Governança Legal, Feedback e Comunidade', () {
    late BancoDadosLocal banco;
    late AutenticacaoNuvemServiceFake authFake;
    late ServicoFilaFeedbackFake filaFake;

    setUp(() async {
      banco = await BancoDadosLocal.abrirEmMemoria();
      filaFake = ServicoFilaFeedbackFake();
      authFake = AutenticacaoNuvemServiceFake(
        crypto: CryptoService(),
        sessaoArmazenada: const SessaoUsuarioNuvem(
          userId: 'usr_oidc_99',
          email: 'auditor@arestaclimb.com',
          provedor: ProvedorOidc.google,
          nomeCompleto: 'Renato Auditor',
          clubeAssociacao: 'FEMERJ',
          jwtSupabase: 'jwt_99',
          atestadoOidcJwt: 'oidc_99',
          fingerprintChavePublica:
              'a1b2c3d4e5f60718293a4b5c6d7e8f90112233445566778899aabbccddeeff00',
        ),
      );
    });

    tearDown(() async {
      await banco.fechar();
    });

    testWidgets(
      'exibe identidade local, sessão OIDC, fingerprint ECDSA truncado, versão/data dos termos aceitos e abre links externos e feedback',
      (tester) async {
        await tester.runAsync(() async {
          await banco.salvarConfiguracao(
            AppConfigRecord(
              id: 1,
              acceptedTermsVersion: 3,
              dataHoraAceiteTermos: DateTime(2026, 11, 8, 14, 35),
              idiomaPreferido: 'pt',
            ),
          );
        });

        final identidade = IdentityRecord()
          ..id = 1
          ..nome = 'Renato Auditor'
          ..clubeAssociacao = 'FEMERJ'
          ..dataRegistro = DateTime(2026, 11, 8);

        final urlsAbertas = <Uri>[];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bancoDadosLocalProvider.overrideWithValue(banco),
              autenticacaoNuvemServiceProvider.overrideWithValue(authFake),
              servicoFilaFeedbackProvider.overrideWithValue(filaFake),
              currentIdentityProvider.overrideWith((ref) async => identidade),
            ],
            child: BetterFeedback(
              feedbackBuilder: construtorFeedbackUsuario,
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: ResolvedorIdioma.localesSuportados,
                home: Scaffold(
                  body: TelaConfiguracoes(
                    abridorUrlExterna: (uri) async {
                      urlsAbertas.add(uri);
                      return true;
                    },
                    exibidorFeedback: (context, aoSubmeter) {
                      aoSubmeter(
                        UserFeedback(
                          text: 'Feedback enviado pela TelaConfiguracoes',
                          screenshot: Uint8List.fromList([1, 2, 3]),
                          extra: const {'categoria': 'aplicativo'},
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Seletor de idioma
        expect(find.byKey(const Key('seletor_idioma_config')), findsOneWidget);

        // 2. Identidade local + OIDC + fingerprint ECDSA
        expect(find.byKey(const Key('card_identidade_config')), findsOneWidget);
        expect(find.text('Renato Auditor'), findsOneWidget);
        expect(find.text('FEMERJ'), findsOneWidget);
        expect(
          find.textContaining('GOOGLE (auditor@arestaclimb.com)'),
          findsOneWidget,
        );
        expect(find.textContaining('a1b2c3d4...eeff00'), findsOneWidget);

        // 3. Governança e Termos Legais (versão e timestamp)
        expect(
          find.byKey(const Key('card_governanca_termos_config')),
          findsOneWidget,
        );
        expect(find.text('Versão aceita: v3'), findsOneWidget);
        expect(
          find.text('Consentimento em: 2026-11-08 14:35'),
          findsOneWidget,
        );

        // 4. Acionamento do BotaoFeedback
        await tester.ensureVisible(find.byKey(const Key('botao_acionar_feedback')));
        await tester.tap(find.byKey(const Key('botao_acionar_feedback')));
        await tester.pumpAndSettle();
        expect(filaFake.feedbacksEnfileirados, hasLength(1));
        expect(
          filaFake.feedbacksEnfileirados.single.mensagem,
          equals('Feedback enviado pela TelaConfiguracoes'),
        );

        // 5. Links externos da comunidade (WhatsApp e Portal Web)
        await tester.ensureVisible(
          find.byKey(const Key('botao_whatsapp_comunidade_config')),
        );
        await tester.tap(
          find.byKey(const Key('botao_whatsapp_comunidade_config')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('botao_portal_web_config')),
        );
        await tester.tap(find.byKey(const Key('botao_portal_web_config')));
        await tester.pumpAndSettle();

        expect(
          urlsAbertas.map((u) => u.toString()).toList(),
          equals([
            'https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv',
            'https://arestaclimb.com',
          ]),
        );
      },
    );

    testWidgets(
      'exibe estado não vinculado e aceite pendente quando sem sessão OIDC/termos e navega para consulta dos termos',
      (tester) async {
        final authSemSessao = AutenticacaoNuvemServiceFake(
          crypto: CryptoService(),
          sessaoArmazenada: null,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bancoDadosLocalProvider.overrideWithValue(banco),
              localeSistemaProvider.overrideWithValue(const Locale('pt')),
              autenticacaoNuvemServiceProvider.overrideWithValue(authSemSessao),
              servicoFilaFeedbackProvider.overrideWithValue(filaFake),
              currentIdentityProvider.overrideWith((ref) async => null),
            ],
            child: BetterFeedback(
              feedbackBuilder: construtorFeedbackUsuario,
              child: MaterialApp(
                locale: const Locale('pt'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: ResolvedorIdioma.localesSuportados,
                home: const Scaffold(
                  body: TelaConfiguracoes(),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Não vinculada (modo local)'), findsOneWidget);
        expect(find.text('Aceite pendente'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const Key('botao_consultar_termos_config')),
        );
        await tester.tap(find.byKey(const Key('botao_consultar_termos_config')));
        await tester.pumpAndSettle();

        expect(
          find.text('Termos de Uso e Auditoria Técnica'),
          findsOneWidget,
        );
      },
    );
  });
}
