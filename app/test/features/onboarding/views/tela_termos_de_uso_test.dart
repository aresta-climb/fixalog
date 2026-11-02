// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixalog/features/onboarding/views/tela_termos_de_uso.dart';
import 'package:fixalog/core/constantes/versao_legal.g.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:fixalog/features/home/views/home_screen.dart';
import 'package:fixalog/features/identity/views/identity_setup_screen.dart';

class PacoteAssetsTeste extends Fake implements AssetBundle {
  final Map<String, String> arquivos;
  PacoteAssetsTeste(this.arquivos);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (arquivos.containsKey(key)) {
      return arquivos[key]!;
    }
    throw FlutterError('Asset nao encontrado: $key');
  }

  @override
  Future<ByteData> load(String key) async {
    final str = await loadString(key);
    return ByteData.sublistView(Uint8List.fromList(str.codeUnits));
  }
}

void main() {
  late PacoteAssetsTeste assetsTeste;
  late BancoDadosLocal banco;

  setUp(() async {
    banco = await BancoDadosLocal.abrirEmMemoria();
    assetsTeste = PacoteAssetsTeste({
      'legal/repo/public/docs/termos-de-uso-fixalog.md':
          '# Termos Fixalog\n\nTexto dos termos.\n\n[Privacidade Inline](https://arestaclimb.com/privacidade)',
      'legal/repo/public/docs/politica-de-privacidade-fixalog.md': '# Politica Fixalog\n\nConteudo de privacidade.',
    });
  });

  tearDown(() async {
    await banco.fechar();
  });

  Widget criarWidgetDeTeste({
    AssetBundle? bundle,
    VoidCallback? aoAceitar,
    List<Override> overrides = const [],
    bool solicitarPermissoes = false,
  }) {
    return ProviderScope(
      overrides: [
        bancoDadosLocalProvider.overrideWithValue(banco),
        ...overrides,
      ],
      child: MaterialApp(
        home: TelaTermosDeUso(
          assetBundle: bundle ?? assetsTeste,
          aoAceitar: aoAceitar,
          solicitarPermissoesNativas: solicitarPermissoes,
        ),
      ),
    );
  }

  testWidgets('Renderiza markdown dos termos e mantem botao desabilitado sem checkbox', (tester) async {
    await tester.pumpWidget(criarWidgetDeTeste());
    await tester.pumpAndSettle();

    expect(find.text('Termos de Uso e Auditoria Técnica'), findsOneWidget);
    expect(find.textContaining('Termos Fixalog'), findsOneWidget);
    expect(find.textContaining('Li e concordo com os Termos de Uso e a Política de Privacidade.'), findsOneWidget);

    final botao = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Aceitar Termos e Continuar'));
    expect(botao.onPressed, isNull);
  });

  testWidgets('Marcar o checkbox habilita o botao de aceite', (tester) async {
    await tester.pumpWidget(criarWidgetDeTeste());
    await tester.pumpAndSettle();

    final checkbox = find.byType(Checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    final botao = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Aceitar Termos e Continuar'));
    expect(botao.onPressed, isNotNull);
  });

  testWidgets('Abre e fecha modal inferior de politica de privacidade via botao de apoio', (tester) async {
    await tester.pumpWidget(criarWidgetDeTeste());
    await tester.pumpAndSettle();

    final btnPolitica = find.text('Ler Política de Privacidade');
    expect(btnPolitica, findsOneWidget);
    await tester.tap(btnPolitica);
    await tester.pumpAndSettle();

    expect(find.text('Política de Privacidade - Fixalog'), findsOneWidget);
    expect(find.textContaining('Politica Fixalog'), findsOneWidget);

    // Fecha o modal
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsNothing);

    // Também abre o modal clicando em link de privacidade dentro do Markdown
    await tester.tap(find.text('Privacidade Inline', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('Política de Privacidade - Fixalog'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  });

  testWidgets('Exibe mensagem amigavel e botao de tentar novamente em caso de erro no asset', (tester) async {
    final assetsComErro = PacoteAssetsTeste({});
    await tester.pumpWidget(criarWidgetDeTeste(bundle: assetsComErro));
    await tester.pumpAndSettle();

    expect(find.textContaining('Não foi possível carregar os termos de uso locais'), findsOneWidget);
    final btnTentarNovamente = find.text('Tentar Novamente');
    expect(btnTentarNovamente, findsOneWidget);
    await tester.tap(btnTentarNovamente);
    await tester.pumpAndSettle();
  });

  testWidgets('Clicar no botao habilitado grava dados no banco SQLite em memoria e chama aoAceitar', (tester) async {
    var foiAceito = false;

    await tester.pumpWidget(criarWidgetDeTeste(
      aoAceitar: () {
        foiAceito = true;
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Aceitar Termos e Continuar'));
    await tester.pumpAndSettle();

    expect(foiAceito, isTrue);
    final configSalva = await banco.obterConfiguracao(1);
    expect(configSalva, isNotNull);
    expect(configSalva!.versaoTermosAceita, equals(kVersaoLegal));
    expect(configSalva.dataHoraAceiteTermos, isNotNull);
  });

  testWidgets('Navega para HomeScreen quando aoAceitar for nulo e o usuario tiver identidade', (tester) async {
    await tester.pumpWidget(criarWidgetDeTeste(
      overrides: [
        hasIdentityProvider.overrideWith((ref) => Future.value(true)),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Aceitar Termos e Continuar'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Navega para IdentitySetupScreen quando aoAceitar for nulo e o usuario nao tiver identidade', (tester) async {
    await tester.pumpWidget(criarWidgetDeTeste(
      overrides: [
        hasIdentityProvider.overrideWith((ref) => Future.value(false)),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Aceitar Termos e Continuar'));
    await tester.pumpAndSettle();

    expect(find.byType(IdentitySetupScreen), findsOneWidget);
  });
}
