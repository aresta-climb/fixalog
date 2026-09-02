import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/wizard/views/widgets/signature_modal.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Fluxo de Integração: Abertura e captura de assinatura sem crash de render box', (tester) async {
    Uint8List? signatureResult;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    signatureResult = await showDialog<Uint8List>(
                      context: context,
                      builder: (ctx) => const SignatureModal(),
                    );
                  },
                  child: const Text('ABRIR ASSINATURA'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Abre o diálogo de assinatura
    await tester.tap(find.text('ABRIR ASSINATURA'));
    await tester.pumpAndSettle();

    // 2. Valida que o modal abriu
    expect(find.text('ASSINATURA DIGITAL'), findsOneWidget);

    // 3. Realiza gestos no canvas de assinatura (não deve disparar exceção de hit test)
    final signatureFinder = find.byType(SignatureModal);
    expect(signatureFinder, findsOneWidget);

    final center = tester.getCenter(signatureFinder);
    await tester.dragFrom(center, const Offset(50, 50));
    await tester.pumpAndSettle();

    // 4. Salva a assinatura
    await tester.tap(find.text('SALVAR ASSINATURA'));
    await tester.pumpAndSettle();

    // Modal deve fechar sem crash
    expect(find.text('ASSINATURA DIGITAL'), findsNothing);
  });
}
