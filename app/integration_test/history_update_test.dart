import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fixalog/main.dart';
import 'package:fixalog/core/models/local/identity_record.dart';
import 'package:fixalog/core/models/local/submission_record.dart';
import 'package:fixalog/core/models/local/app_config_record.dart';
import 'package:fixalog/core/services/banco_dados_local.dart';
import 'package:fixalog/core/services/pdf_viewer_service.dart';
import 'package:open_filex/open_filex.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gera relatório simulado e verifica se o histórico atualiza', (tester) async {
    // Configura o SQLite em um diretório temporário para isolamento do teste
    final tempDir = await getTemporaryDirectory();
    final testDir = Directory('${tempDir.path}/test_history_update');
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
    await testDir.create();

    final banco = await BancoDadosLocal.abrirEmArquivo(testDir.path);

    // Preenche configurações iniciais (Termos de Uso e Identidade) para ir direto ao HomeScreen
    await banco.salvarConfiguracao(
      AppConfigRecord(id: 1, acceptedTermsVersion: 1),
    );
    await banco.salvarIdentidade(
      IdentityRecord()
        ..nome = 'Test User'
        ..clubeAssociacao = 'Clube Teste'
        ..dataRegistro = DateTime.now(),
    );

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
          bancoDadosLocalProvider.overrideWithValue(banco),
          pdfViewerServiceProvider.overrideWithValue(mockPdfViewerService),
        ],
        child: const FixalogApp(),
      ),
    );

    // Aguarda carregar tudo e renderizar a HomeScreen (Novo Protocolo)
    await tester.pumpAndSettle();

    // Navega até a aba Histórico
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();

    // Como o banco está vazio (não há relatórios gerados ainda)
    expect(find.text('Nenhum relatório preenchido.'), findsOneWidget);

    // 3. Simula a geração de um relatório persistindo no SQLite diretamente
    final fakePdf = File('${testDir.path}/pdf.pdf');
    await fakePdf.writeAsString('fake pdf');

    final novoRegistro = SubmissionRecord()
      ..idSessao = 'sessao-123'
      ..idProtocolo = 'proto-1'
      ..nomeProtocolo = 'Fenda do Teste'
      ..dataInclusao = DateTime(2025, 1, 1)
      ..hashAssinatura = 'abc123hash'
      ..pdfPath = fakePdf.path
      ..protobufPath = '${testDir.path}/laudo.epub';

    await banco.salvarSubmissao(novoRegistro);

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
    await banco.fechar();
  });
}
