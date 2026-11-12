// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixalog/core/l10n/generated/app_localizations.dart';
import 'package:fixalog/core/l10n/resolvedor_idioma.dart';
import 'package:fixalog/features/home/views/new_protocol_screen.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:fixalog/core/models/local/identity_record.dart';
import 'package:fixalog/features/wizard/views/wizard_screen.dart';

// Helper: monta a tela com um provider de identidade configurado.
Widget _buildScreen({IdentityRecord? identity}) {
  return ProviderScope(
    overrides: [
      currentIdentityProvider.overrideWith(
        (ref) async => identity ?? IdentityRecord(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: NewProtocolScreen())),
  );
}

void main() {
  group('NewProtocolScreen Widget Tests', () {
    testWidgets('Exibe o header FIXALOG', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('FIXALOG'), findsOneWidget);
    });

    testWidgets('Exibe saudação genérica quando identidade está vazia', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Boa jornada.'), findsOneWidget);
    });

    testWidgets('Exibe saudação com primeiro nome quando identidade tem nome', (
      tester,
    ) async {
      final identity = IdentityRecord()..nome = 'Renato Silva';
      await tester.pumpWidget(_buildScreen(identity: identity));
      await tester.pump();

      expect(find.text('Boa jornada, Renato.'), findsOneWidget);
    });

    testWidgets('Exibe nome do clube quando preenchido e diferente de N/A', (
      tester,
    ) async {
      final identity = IdentityRecord()
        ..nome = 'Ana'
        ..clubeAssociacao = 'Clube Alpino Paulista';
      await tester.pumpWidget(_buildScreen(identity: identity));
      await tester.pump();

      expect(find.text('CLUBE ALPINO PAULISTA'), findsOneWidget);
    });

    testWidgets('Exibe fallback MANTENEDOR INDEPENDENTE quando clube é N/A', (
      tester,
    ) async {
      final identity = IdentityRecord()
        ..nome = 'Ana'
        ..clubeAssociacao = 'N/A';
      await tester.pumpWidget(_buildScreen(identity: identity));
      await tester.pump();

      expect(find.text('MANTENEDOR INDEPENDENTE'), findsOneWidget);
    });

    testWidgets('Exibe título da seção de protocolos', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('NOVO REGISTRO DE MANUTENÇÃO'), findsOneWidget);
    });

    testWidgets('Exibe os 5 cards de protocolo na ordem: Inspeção Visual, Manutenção, Abertura de Via, Registro Expresso e Cadastro de Materiais', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      final yInspecao = tester.getTopLeft(find.text('Inspeção Visual de\nProteções Fixas')).dy;
      final yManutencao = tester.getTopLeft(find.text('Manutenção de\nProteções Fixas')).dy;
      final yAbertura = tester.getTopLeft(find.text('Abertura de Via')).dy;
      final yExpresso = tester.getTopLeft(find.text('Registro Expresso\n(Fotos + Local)')).dy;
      final yMateriais = tester.getTopLeft(find.text('Cadastro de\nMateriais')).dy;

      expect(yInspecao, lessThan(yManutencao));
      expect(yManutencao, lessThan(yAbertura));
      expect(yAbertura, lessThan(yExpresso));
      expect(yExpresso, lessThan(yMateriais));
    });

    testWidgets('Exibe tags de protocolo corretas', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('PROTOCOLO TÉCNICO'), findsNWidgets(2));
      expect(find.text('PROTOCOLO PREVENTIVO'), findsOneWidget);
      expect(find.text('CATÁLOGO DE INSUMOS'), findsOneWidget);
    });

    testWidgets('Exibe cinco botões INICIAR', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('INICIAR'), findsNWidgets(5));
    });

    testWidgets('Navega para Inspeção Visual ao tocar no 1º card', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('INICIAR').at(0));
      await tester.pumpAndSettle();

      expect(find.byType(WizardScreen), findsOneWidget);
      expect(find.text('Data da Inspeção'), findsOneWidget);
    });

    testWidgets('Navega para Manutenção de Proteções Fixas (manutencao.yaml) ao tocar no 2º card', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final finder = find.text('INICIAR').at(1);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.byType(WizardScreen), findsOneWidget);
      expect(find.text('Data da Manutenção'), findsOneWidget);
    });

    testWidgets('Navega para Abertura de Via ao tocar no 3º card', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final finder = find.text('INICIAR').at(2);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.byType(WizardScreen), findsOneWidget);
      expect(find.text('Data da Abertura / Conquista'), findsOneWidget);
    });

    testWidgets('Navega para Registro Expresso ao tocar no 4º card', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final finder = find.text('INICIAR').at(3);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.byType(WizardScreen), findsOneWidget);
      expect(find.text('Título / Identificação do Registro'), findsOneWidget);
    });

    testWidgets('Navega para Cadastro de Materiais ao tocar no 5º card', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final finder = find.text('INICIAR').at(4);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.byType(WizardScreen), findsOneWidget);
      expect(find.text('Nome do Material ou Conjunto'), findsOneWidget);
    });

    testWidgets(
      'Exibe os 5 cards traduzidos em Inglês, Árabe e Japonês sem overflow visual',
      (tester) async {
        late WidgetRef refCapturado;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localeSistemaProvider.overrideWithValue(const Locale('en')),
              currentIdentityProvider.overrideWith(
                (ref) async => IdentityRecord()..nome = 'Alex',
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: ResolvedorIdioma.localesSuportados,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    refCapturado = ref;
                    return const NewProtocolScreen();
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('SELECT PROTOCOL'), findsOneWidget);
        expect(find.text('Visual Inspection'), findsOneWidget);

        await refCapturado
            .read(idiomaAtivoProvider.notifier)
            .selecionarIdioma('ar');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('اختر البروتوكول'), findsOneWidget);

        await refCapturado
            .read(idiomaAtivoProvider.notifier)
            .selecionarIdioma('ja');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('プロトコルを選択'), findsOneWidget);
        expect(find.text('目視点検'), findsOneWidget);
      },
    );
  });
}
