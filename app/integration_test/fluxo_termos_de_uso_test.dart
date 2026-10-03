// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fixalog/main.dart';
import 'package:fixalog/core/models/local/identity_record.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/models/local/app_config_record.dart';
import 'package:fixalog/core/constantes/versao_legal.g.dart';
import 'package:fixalog/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:fixalog/features/onboarding/views/tela_termos_de_uso.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Fluxo de Integração: Bloqueio inicial, leitura, checkbox e aceite dos termos de uso', (tester) async {

    final tempDir = await getTemporaryDirectory();
    final testDir = Directory('${tempDir.path}/teste_fluxo_termos');
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
    await testDir.create();

    final isar = await Isar.open(
      [IdentityRecordSchema, SubmissionRecordSchema, AppConfigRecordSchema],
      directory: testDir.path,
    );

    // Banco inicial sem termos aceitos
    await isar.writeTxn(() async {
      await isar.appConfigRecords.put(
        AppConfigRecord()
          ..id = 1
          ..acceptedTermsVersion = 0,
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
        ],
        child: const FixalogApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifica que a TelaTermosDeUso é exibida
    expect(find.byType(TelaTermosDeUso), findsOneWidget);
    expect(find.text('Termos de Uso e Auditoria Técnica'), findsOneWidget);

    // 2. Localiza o botão de aceite e verifica que está inicialmente desabilitado
    final botaoAceitar = find.widgetWithText(FilledButton, 'Aceitar Termos e Continuar');
    expect(botaoAceitar, findsOneWidget);
    final filledBtn = tester.widget<FilledButton>(botaoAceitar);
    expect(filledBtn.onPressed, isNull);

    // 3. Localiza e marca o Checkbox de confirmação
    final checkbox = find.byType(Checkbox);
    expect(checkbox, findsOneWidget);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    // 4. Verifica que o botão agora está habilitado
    final filledBtnHabilitado = tester.widget<FilledButton>(botaoAceitar);
    expect(filledBtnHabilitado.onPressed, isNotNull);

    // 5. Clica para aceitar
    await tester.tap(botaoAceitar);
    await tester.pumpAndSettle();

    // 6. Confere a persistência no Isar
    final configSalva = await isar.appConfigRecords.get(1);
    expect(configSalva, isNotNull);
    expect(configSalva!.acceptedTermsVersion, equals(kVersaoLegal));
    expect(configSalva.dataHoraAceiteTermos, isNotNull);

    await isar.close();
  });
}
