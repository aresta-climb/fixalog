import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fixlog/main.dart';
import 'package:fixlog/core/models/local/identity_record.dart';
import 'package:fixlog/core/models/local/submission_record.dart';
import 'package:fixlog/core/models/local/app_config_record.dart';
import 'package:fixlog/features/identity/viewmodels/identity_form_view_model.dart';
import 'package:fixlog/src/rust/frb_generated.dart';
import 'package:fixlog/core/services/pdf_viewer_service.dart';
import 'package:open_filex/open_filex.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gera relatório simulado e verifica se o histórico atualiza', (tester) async {
    // 1. Setup inicial
    await RustLib.init();
    
    // Configura o Isar em um diretório temporário para isolamento do teste
    final tempDir = await getTemporaryDirectory();
    final testDir = Directory('${tempDir.path}/test_history_update');
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
    await testDir.create();

    final isar = await Isar.open(
      [IdentityRecordSchema, SubmissionRecordSchema, AppConfigRecordSchema],
      directory: testDir.path,
    );

    // Preenche configurações iniciais (Termos de Uso e Identidade) para ir direto ao HomeScreen
    await isar.writeTxn(() async {
      await isar.appConfigRecords.put(
        AppConfigRecord()..id = 1..acceptedTermsVersion = 1,
      );
      await isar.identityRecords.put(
        IdentityRecord()
          ..nome = 'Test User'
          ..clubeAssociacao = 'Clube Teste'
          ..dataRegistro = DateTime.now(),
      );
    });

    // Variável para registrar se o PDF foi aberto
    bool pdfAberto = false;
    String? caminhoPdfAberto;

    final mockPdfViewerService = PdfViewerService(
      openProxy: (path) async {
        pdfAberto = true;
        caminhoPdfAberto = path;
        return OpenResult(type: ResultType.done, message: 'Mock aberto');
      },
    );

    // 2. Inicia o app
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
          pdfViewerServiceProvider.overrideWithValue(mockPdfViewerService),
        ],
        child: const FixLogApp(),
      ),
    );

    // Aguarda carregar tudo e renderizar a HomeScreen (Novo Protocolo)
    await tester.pumpAndSettle();

    // Navega até a aba Histórico
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();

    // Como o Isar está vazio (não há relatórios gerados ainda)
    expect(find.text('Nenhum relatório preenchido.'), findsOneWidget);

    // 3. Simula a geração de um relatório persistindo no Isar diretamente
    // (O Provider de histórico deve capturar o evento do Isar graças ao watchHistory!)
    // Cria um arquivo PDF fake para o openPdf não falhar na checagem de exists()
    final fakePdf = File('${testDir.path}/pdf.pdf');
    await fakePdf.writeAsString('fake pdf');

    final novoRegistro = SubmissionRecord()
      ..idSessao = 'sessao-123'
      ..idProtocolo = 'proto-1'
      ..nomeProtocolo = 'Fenda do Teste'
      ..dataInclusao = DateTime(2025, 1, 1)
      ..hashAssinatura = 'abc123hash'
      ..pdfPath = fakePdf.path
      ..yamlPath = '${testDir.path}/yaml.yaml';

    await isar.writeTxn(() async {
      await isar.submissionRecords.put(novoRegistro);
    });

    // O pump aguarda que os microtasks/streams emitam novos eventos na UI
    await tester.pumpAndSettle();

    // 4. Valida se a UI reagiu
    expect(find.text('Nenhum relatório preenchido.'), findsNothing);
    expect(find.text('Fenda do Teste'), findsWidgets);
    expect(find.text('01/01/2025'), findsWidgets);
    expect(find.text('1'), findsWidgets); // 1 Log Total
    expect(find.text('Fenda do Teste'), findsWidgets); // Via mais ativa

    // 5. Clica no item de histórico e verifica se o PDF foi aberto
    await tester.tap(find.text('Fenda do Teste').first);
    await tester.pumpAndSettle();

    expect(pdfAberto, isTrue);
    expect(caminhoPdfAberto, fakePdf.path);

    // Limpa
    await isar.close(deleteFromDisk: true);
  });
}
