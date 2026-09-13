// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:fixlog/features/onboarding/views/tela_termos_de_uso.dart';
import 'package:fixlog/core/models/local/app_config_record.dart';
import 'package:fixlog/core/constantes/versao_legal.g.dart';
import 'package:fixlog/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:fixlog/features/home/views/home_screen.dart';
import 'package:fixlog/features/identity/views/identity_setup_screen.dart';

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

class FakeIsarTxn extends Fake implements Isar {
  bool salvou = false;
  int versaoSalva = 0;
  DateTime? dataSalva;
  late final _collection = FakeAppConfigCollection(this);

  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) async {
    return await callback();
  }

  @override
  IsarCollection<R> collection<R>() {
    return _collection as IsarCollection<R>;
  }
}

class FakeAppConfigCollection extends Fake implements IsarCollection<AppConfigRecord> {
  final FakeIsarTxn fakeIsar;
  FakeAppConfigCollection(this.fakeIsar);

  @override
  Future<AppConfigRecord?> get(Id id) async => null; // Testando criacao do AppConfigRecord() quando nulo

  @override
  Future<Id> put(AppConfigRecord object) async {
    fakeIsar.salvou = true;
    fakeIsar.versaoSalva = object.acceptedTermsVersion;
    fakeIsar.dataSalva = object.dataHoraAceiteTermos;
    return 1;
  }
}

void main() {
  late PacoteAssetsTeste assetsTeste;

  setUp(() {
    assetsTeste = PacoteAssetsTeste({
      'legal/repo/public/docs/termos-de-uso-fixlog.md': '# Termos FixLog\n\nTexto dos termos.',
      'legal/repo/public/docs/politica-de-privacidade-fixlog.md': '# Politica FixLog\n\nConteudo de privacidade.',
    });
  });

  Widget criarWidgetDeTeste({
    AssetBundle? bundle,
    VoidCallback? aoAceitar,
    List<Override> overrides = const [],
    bool solicitarPermissoes = false,
  }) {
    return ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(null),
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
    expect(find.textContaining('Termos FixLog'), findsOneWidget);
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

    expect(find.text('Política de Privacidade - FixLog'), findsOneWidget);
    expect(find.textContaining('Politica FixLog'), findsOneWidget);

    // Fecha o modal
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('Exibe mensagem amigavel e botao de tentar novamente em caso de erro no asset', (tester) async {
    final assetsComErro = PacoteAssetsTeste({}); // Sem os arquivos necessarios
    await tester.pumpWidget(criarWidgetDeTeste(bundle: assetsComErro));
    await tester.pumpAndSettle();

    expect(find.textContaining('Não foi possível carregar os termos de uso locais'), findsOneWidget);
    final btnTentarNovamente = find.text('Tentar Novamente');
    expect(btnTentarNovamente, findsOneWidget);
    await tester.tap(btnTentarNovamente);
    await tester.pumpAndSettle();
  });

  testWidgets('Clicar no botao habilitado grava dados no Isar e chama aoAceitar', (tester) async {
    final fakeIsar = FakeIsarTxn();
    var foiAceito = false;

    await tester.pumpWidget(criarWidgetDeTeste(
      overrides: [
        isarProvider.overrideWithValue(fakeIsar),
      ],
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
    expect(fakeIsar.salvou, isTrue);
    expect(fakeIsar.versaoSalva, equals(kVersaoLegal));
    expect(fakeIsar.dataSalva, isNotNull);
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
