import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fixalog/main.dart';
import 'package:fixalog/core/models/local/identity_record.dart';
import 'package:fixalog/core/models/local/app_config_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Fluxo de Integração: Auto-save contínuo de rascunho e retomada pelo histórico', (tester) async {
    final tempDir = await getTemporaryDirectory();
    final testDir = Directory('${tempDir.path}/test_draft_flow');
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
    await testDir.create();

    final banco = await BancoDadosLocal.abrirEmArquivo(testDir.path);

    await banco.salvarConfiguracao(
      AppConfigRecord(id: 1, acceptedTermsVersion: 1),
    );
    await banco.salvarIdentidade(
      IdentityRecord()
        ..nome = 'Escalador Teste'
        ..clubeAssociacao = 'Clube ACEC'
        ..dataRegistro = DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bancoDadosLocalProvider.overrideWithValue(banco),
        ],
        child: const FixalogApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Inicia um protocolo a partir da tela inicial
    final btnIniciar = find.text('INICIAR').first;
    expect(btnIniciar, findsOneWidget);
    await tester.tap(btnIniciar);
    await tester.pumpAndSettle();

    // 2. Digita em um campo de texto no Wizard (se houver TextField disponível)
    final textFields = find.byType(TextField);
    if (textFields.evaluate().isNotEmpty) {
      await tester.enterText(textFields.first, 'Via Teste AutoSave');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    // 3. Simula saída da tela (botão voltar)
    final backButton = find.byTooltip('Back');
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton.first);
      await tester.pumpAndSettle();
    } else {
      final navigator = Navigator.of(tester.element(find.byType(Scaffold).last));
      navigator.pop();
      await tester.pumpAndSettle();
    }

    // 4. Vai para a aba Histórico
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();

    // 5. Verifica se o registro salvo como rascunho aparece com tag EM PROGRESSO
    expect(find.text('EM PROGRESSO'), findsWidgets);

    // 6. Clica no item para retomar o preenchimento
    await tester.tap(find.text('EM PROGRESSO').first);
    await tester.pumpAndSettle();

    // Valida que estamos de volta no Wizard
    expect(find.text('AVANÇAR'), findsWidgets);

    await banco.fechar();
  });
}
